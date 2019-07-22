package Perinci::Access::Schemeless;

our $DATE = '2019-07-21'; # DATE
our $VERSION = '0.891'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
use Log::ger;

use parent qw(Perinci::Access::Base);

use List::Util qw(first);
use Perinci::Object;
use Perinci::Sub::Normalize qw(normalize_function_metadata);
use Perinci::Sub::Util qw(err);
use Scalar::Util qw(blessed);
use Module::Path::More qw(module_path);
use Package::Util::Lite qw(package_exists);
use Tie::Cache;
use URI::Split qw(uri_split uri_join);

our $re_perl_package =
    qr/\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9][A-Za-z_0-9]*)*\z/;

sub new {
    require Class::Inspector;

    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # build a list of supported actions for each type of entity
    my %typeacts = (
        package  => [],
        function => [],
        variable => [],
    ); # key = type, val = [[ACTION, META], ...]

    my @comacts;
    for my $meth (@{Class::Inspector->methods(ref $self)}) {
        next unless $meth =~ /^actionmeta_(.+)/;
        my $act = $1;
        my $meta = $self->$meth();
        $self->{_actionmetas}{$act} = $meta;
        for my $type (@{$meta->{applies_to}}) {
            if ($type eq '*') {
                push @comacts, [$act, $meta];
            } else {
                push @{$typeacts{$type}}, [$act, $meta];
            }
        }
    }
    for my $type (keys %typeacts) {
        $typeacts{$type} = { map {$_->[0] => $_->[1]}
                                 @{$typeacts{$type}}, @comacts };
    }
    $self->{_typeacts} = \%typeacts;

    $self->{cache_size}              //= 100; # for caching metadata & code
    #$self->{use_tx}                  //= 0;
    $self->{wrap}                    //= 1;
    #$self->{custom_tx_manager}       //= undef;
    $self->{load}                    //= 1;
    $self->{normalize_metadata}      //= 1;
    #$self->{after_load}
    #$self->{allow_paths}
    #$self->{deny_paths}
    #$self->{allow_schemes}
    #$self->{deny_schemes}
    #$self->{package_prefix}
    $self->{debug}                   //= $ENV{PERINCI_ACCESS_SCHEMELESS_DEBUG} // 0;
    $self->{accept_argv}             //= 1;

    if ($self->{cache_size} > 0) {
        my %metacache;
        tie %metacache, 'Tie::Cache', $self->{cache_size};
        $self->{_meta_cache} = \%metacache;
        my %codecache;
        tie %codecache, 'Tie::Cache', $self->{cache_size};
        $self->{_code_cache} = \%codecache;
    }

    $self;
}

# for older Perinci::Access::Base 0.28-, to remove later
sub _init {}

# if paths=/a/b, will match /a/b as well as /a/b/c
sub __match_paths {
    my ($path, $paths) = @_;

    my $pathslash = $path =~ m!/\z! ? $path : "$path/";

    for (ref($paths) eq 'ARRAY' ? @$paths : $paths) {
        if (ref($_) eq 'Regexp') {
            return 1 if $path =~ $_;
        } else {
            if (m!/\z!) {
                return 1 if $_ eq $pathslash || index($pathslash, $_) == 0;
            } else {
                my $p = "$_/";
                return 1 if $p eq $path || index($pathslash, $p) == 0;
            }
        }
    }
    0;
}

# if paths=/a/b, will match /a/b as well as /a/b/c AS WELL AS /a and /. only
# suitable for 'list' action, e.g. allow_path is '/a/b' but we can do 'list /'
# and 'list /a' too (but not 'list /c').
sub __match_paths2 {
    my ($path, $paths) = @_;

    my $pathslash = $path =~ m!/\z! ? $path : "$path/";

    for (ref($paths) eq 'ARRAY' ? @$paths : $paths) {
        if (ref($_) eq 'Regexp') {
            # we can't match a regex against a string, so we just pass here
            return 1;
        } else {
            if (m!/\z!) {
                return 1 if $_ eq $pathslash || index($_, $pathslash) == 0 ||
                    index($pathslash, $_) == 0;
            } else {
                my $p = "$_/";
                return 1 if $p eq $path || index($p, $pathslash) == 0 ||
                    index($pathslash, $p) == 0 ;
            }
        }
    }
    0;
}

sub _parse_uri {
    my ($self, $req) = @_;

    my $path = $req->{-uri_path};
    if (defined $self->{allow_paths}) {
        my $allow;
        if ($self->{_actionmetas}{$req->{action}}{allow_request_parent_path}) {
            $allow = __match_paths2($path, $self->{allow_paths});
        } else {
            $allow = __match_paths($path, $self->{allow_paths});
        }
        return err(403, "Forbidden uri path (does not match allow_paths)")
            unless $allow;
    }
    if (defined($self->{deny_paths}) &&
            __match_paths($path, $self->{deny_paths})) {
        return err(403, "Forbidden uri path (matches deny_paths)");
    }

    my $sch = $req->{-uri_scheme} // "";
    if (defined($self->{allow_schemes}) && !($sch ~~ $self->{allow_schemes})) {
        return err(501,
                   "Unsupported uri scheme (does not match allow_schemes)");
    }
    if (defined($self->{deny_schemes}) && ($sch ~~ $self->{deny_schemes})) {
        return err(501, "Unsupported uri scheme (matches deny_schemes)");
    }

    my ($dir, $leaf, $perl_package);
    if ($path =~ m!(.*)/(.*)!) {
        $dir  = $1;
        $leaf = $2;
    } else {
        $dir  = $path;
        $leaf = '';
    }
    for ($perl_package) {
        $_ = $dir;
        s!^/+!!;
        s!/+!::!g;
        if (defined $self->{package_prefix}) {
            $_ = $self->{package_prefix} . (length($_) ? "::":"") . $_;
        }
    }
    return err(400, "Invalid perl package name: $perl_package")
        if $perl_package && $perl_package !~ $re_perl_package;

    my $type;
    if (length $leaf) {
        if ($leaf =~ /^[%\@\$]/) {
            $type = 'variable';
        } else {
            $type = 'function';
        }
    } else {
        $type = 'package';
        # make sure path ends in /, to ease processing
        $req->{-uri_path} .= "/" unless $path =~ m!/\z!;
    }

    $req->{-uri_dir}      = $dir;
    $req->{-uri_leaf}     = $leaf;
    $req->{-perl_package} = $perl_package;
    $req->{-type}         = $type;

    #$log->tracef("TMP: req=%s", $req);
    return;
}

# key = module_p, val = error resp or undef if successful
my %loadcache;
tie %loadcache, 'Tie::Cache', 200;

sub _load_module {
    my ($self, $req) = @_;

    my $pkg = $req->{-perl_package};

    # skip there is no module to load
    return if !$pkg;

    # if we are instructed not to load any module, we just check via existence
    # of packages
    unless ($self->{load}) {
        return if package_exists($pkg);
        return err(500, "Package $pkg does not exist");
    }

    my $module_p = $pkg;
    $module_p =~ s!::!/!g;
    $module_p .= ".pm";

    # module has been required before and successfully loaded
    return if $INC{$module_p};

    # module has been required before and failed
    return err(500, "Module $pkg has failed to load previously" .
                   $loadcache{$module_p} ?
                       ": $loadcache{$module_p}[0] - $loadcache{$module_p}[1]" :
                           "")
        if exists($INC{$module_p});

    # use cache result (for caching errors, or packages like 'main' and 'CORE'
    # where no modules for such packages exist)
    return $loadcache{$module_p} if exists $loadcache{$module_p};

    # load and cache negative result
    my $res;
    {
        my $fullpath = module_path(module=>$pkg, find_pmc=>0, find_prefix=>1);

        # when the module path does not exist, but the package does, we can
        # ignore this error. for example: main, CORE, etc.
        my $pkg_exists = package_exists($pkg);

        if (!$fullpath) {
            last if $pkg_exists;
            $res = [404, "Can't find module or prefix path for package $pkg"];
            last;
        } elsif ($fullpath !~ /\.pm$/) {
            last if $pkg_exists;
            $res = [405, "Can only find a prefix path for package $pkg"];
            last;
        }
        eval { require $module_p };
        if ($@) {
            $res = [500, "Can't load module $pkg (probably compile error): $@"];
            last;
        }
        # load is successful
        if ($self->{after_load}) {
            eval { $self->{after_load}($self, module=>$pkg) };
            log_error("after_load for package $pkg dies: $@") if $@;
        }
    }
    $loadcache{$module_p} = $res;
    return $res;
}

sub __inject_entity_v_date {
    no strict 'refs';

    my ($req, $meta) = @_;

    my $pkg = $req->{-perl_package};
    unless (defined $meta->{entity_v}) {
        my $ver = ${"$pkg\::VERSION"};
        if (defined $ver) {
            $meta->{entity_v} = $ver;
        }
    }
    unless (defined $meta->{entity_date}) {
        my $date = ${"$pkg\::DATE"};
        if (defined $date) {
            $meta->{entity_date} = $date;
        }
    }
}

sub get_meta {
    no strict 'refs';

    my ($self, $req) = @_;

    my $pkg  = $req->{-perl_package};
    my $leaf = $req->{-uri_leaf};
    my $type = $req->{-type};
    if (!length($pkg)) {
        if (length $leaf) {
            # 404 for all non-subpackage entity directly under /
            return [404, "No metadata for ::$leaf (".
                (package_exists($pkg) ? "package '$pkg' exists, perhaps you mentioned '$pkg' somewhere without actually loading the module, or perhaps '$leaf' is a typo?" :
                     "package '$pkg' doesn't exist, perhaps '$pkg' or '$leaf' is a typo?").
                    ")"
            ];
        } else {
            # empty metadata for root (/)
            $req->{-meta} = {v=>1.1};
            return;
        }
    }

    my $name = "$pkg\::$leaf";
    if ($self->{_meta_cache}{$name}) {
        $req->{-meta} = $self->{_meta_cache}{$name};
        $req->{-orig_meta} = $self->{_orig_meta_cache}{$name}
            if $self->{_orig_meta_cache}{$name};
        return;
    }

    my $res = $self->_load_module($req);
    # missing module (but existing prefix) is okay for package, we construct an
    # empty package metadata for it
    return $res if $res && !($type eq 'package' && $res->[0] == 405);

    my $meta;
    my $metas = \%{"$pkg\::SPEC"};
    $meta = $metas->{ $leaf || ":package" };

    if (!$meta && $type eq 'package') {
        $meta = {v=>1.1};
    }

    return err(404,
               join("",
                    "No metadata for $name (package '$pkg' exists, ",
                    "perhaps you mentioned '$pkg' ",
                    "somewhere without actually loading the module, or ",
                    "perhaps '$leaf' is a typo?)",
                )) unless $meta;

    if ($res) {
        if ($res->[0] == 405) {
            $meta = {v=>1.1}; # empty package metadata for dir
        } elsif ($res->[0] != 200) {
            return $res;
        }
    }

    # normalize has only been implemented for function
    if ($type eq 'function' && $self->{normalize_metadata}) {
        eval { $meta = normalize_function_metadata($meta) };
        if ($@) {
            return [500, "Can't normalize function metadata: $@"];
        }

        $meta->{args} //= {};
        $meta->{_orig_args_as} = $meta->{args_as};
        $meta->{args_as} = 'hash';
        $meta->{_orig_result_naked} = $meta->{result_naked};
        $meta->{result_naked} = 0;
        my $sfp = $self->{set_function_properties};
        if ($sfp) {
            for (keys %$sfp) {
                $meta->{"_orig_$_"} = $meta->{$_};
                $meta->{$_} = $sfp->{$_};
            }
        }
    }

    __inject_entity_v_date($req, $meta);

    if ($self->{cache_size} > 0) {
        $self->{_meta_cache}{$name} = $meta;
    }

    $req->{-meta} = $meta;
    return;
}

sub get_code {
    my ($self, $req) = @_;

    # because we're lazy, we assume here that type is already function. it
    # should be okay since get_code() is only called by action_call().

    my $name = $req->{-perl_package} . "::" . $req->{-uri_leaf};
    if ($self->{_code_cache}{$name}) {
        $req->{-code} = $self->{_code_cache}{$name};
        return;
    }

    my $res = $self->_load_module($req);
    return $res if $res;

    return err(404, "Can't find function $req->{-uri_leaf} in ".
                   "module $req->{-perl_package}")
        unless defined &{$name};

    # we get our own meta and not use get_meta() because we want to get the
    # original metadata
    my $meta;
    {
        no strict 'refs';
        my $metas = \%{"$req->{-perl_package}::SPEC"};
        $meta = $metas->{ $req->{-uri_leaf} || ":package" };
    }

    return err(404, "Can't find function metadata $req->{-uri_leaf} in ".
                   "module $req->{-perl_package}")
        unless $meta;

    my $code;
  GET_CODE:
    {
        # we don't need to wrap
        if (!$self->{wrap} ||
                $meta->{"x.perinci.sub.wrapper.logs"} &&
                    (first {$_->{validate_args}}
                         @{ $meta->{"x.perinci.sub.wrapper.logs"} })
            ) {
            $code = \&{$name};
            last GET_CODE;
        }

        require Perinci::Sub::Wrapper;
        my $sfp = $self->{set_function_properties};

        my $wrapres = Perinci::Sub::Wrapper::wrap_sub(
            sub_name=>$name, meta=>$meta,
            convert=>{args_as=>'hash', result_naked=>0,
                      ($sfp ? %$sfp : ())
                  });
        return err(500, "Can't wrap function", $wrapres)
            unless $wrapres->[0] == 200;
        $code = $wrapres->[2]{sub};

        if ($self->{cache_size} > 0) {
            $self->{_code_cache}{$name} = $code;
            # also put wrapper-generated meta in the cache, so further meta
            # request can use this. the metadata from wrapper contains wrapper
            # logs (x.perinci.sub.wrapper.logs) which can be helpful hint for
            # some uses.
            my $newmeta = $wrapres->[2]{meta};
            $newmeta->{_orig_result_naked} = $meta->{result_naked};
            $newmeta->{_orig_args_as}      = $meta->{args_as};
            if ($sfp) {
                for (keys %$sfp) {
                    $newmeta->{"_orig_$_"} = $meta->{$_};
                }
            }
            __inject_entity_v_date($req, $newmeta);
            $self->{_meta_cache}{$name} = $newmeta;
        }
    }

    $req->{-code} = $code;
    return;
}

sub request {
    no strict 'refs';

    my ($self, $action, $uri, $extra) = @_;

    return err(400, "Please specify URI") unless $uri;

    my $req = { action=>$action, uri=>$uri, %{$extra // {}} };
    my $res = $self->check_request($req);
    return $res if $res;

    return err(501, "Action '$action' not implemented")
        unless $self->can("actionmeta_$action");

    my $am = $self->${\("actionmeta_$action")};

    $res = $self->_parse_uri($req);
    return $res if $res;

    return err(501, "Action '$action' not implemented for ".
                   "'$req->{-type}' entity")
        unless $am->{applies_to}[0] eq '*' ||
            $req->{-type} ~~ @{ $am->{applies_to} };

    my $meth = "action_$action";
    # check transaction

    $res = $self->$meth($req);
    if ($self->{debug}) {
        $res->[3] //= {};
        $res->[3]{debug} = {
            req => $req,
        };
    }
    $res;
}

sub parse_url {
    my ($self, $uri) = @_;
    die "Please specify url" unless $uri;
    my ($sch, $auth, $path) = uri_split($uri);
    return {
        # to mark that we are schemeless
        proto=>'',
        path=>$path,
    };
}

sub actionmeta_info { +{
    applies_to => ['*'],
    summary    => "Get general information on code entity",
    needs_meta => 0,
    needs_code => 0,
} }

sub action_info {
    my ($self, $req) = @_;

    my $mres = $self->get_meta($req);
    return $mres if $mres;

    my $res = {
        uri  => $req->{uri},
        type => $req->{-type},
    };

    [200, "OK (info action)", $res];
}

sub actionmeta_actions { +{
    applies_to => ['*'],
    summary    => "List available actions for code entity",
    needs_meta => 0,
    needs_code => 0,
} }

sub action_actions {
    my ($self, $req) = @_;

    my $mres = $self->get_meta($req);
    return $mres if $mres;

    my @res;
    for my $k (sort keys %{ $self->{_typeacts}{$req->{-type}} }) {
        my $v = $self->{_typeacts}{$req->{-type}}{$k};
        if ($req->{detail}) {
            push @res, {name=>$k, summary=>$v->{summary}};
        } else {
            push @res, $k;
        }
    }
    [200, "OK (actions action)", \@res];
}

sub actionmeta_list { +{
    applies_to => ['package'],
    summary    => "List code entities inside this package code entity",
    # this means, even if allow_path is '/a/b', we allow request on '/a' or '/'.
    allow_request_parent_path => 1,
} }

sub action_list {
    require Module::List;

    my ($self, $req) = @_;
    my $detail = $req->{detail};
    my $f_type = $req->{type} || "";

    my @res;

    my $filter_path = sub {
        my $path = shift;
        if (defined($self->{allow_paths}) &&
                !__match_paths2($path, $self->{allow_paths})) {
            return 0;
        }
        if (defined($self->{deny_paths}) &&
                __match_paths2($path, $self->{deny_paths})) {
            return 0;
        }
        1;
    };

    my %mem;

    # get submodules
    unless ($f_type && $f_type ne 'package') {
        my $lres = Module::List::list_modules(
            $req->{-perl_package} ? "$req->{-perl_package}\::" : "",
            {list_modules=>1, list_prefixes=>1});
        my $dir = $req->{-uri_dir};
        for my $m (sort keys %$lres) {
            $m =~ s!::$!!;
            $m =~ s!.+::!!;
            my $path = "$dir/$m/";
            next unless $filter_path->($path);
            next if $mem{$path}++;
            if ($detail) {
                push @res, {uri=>"$m/", type=>"package"};
            } else {
                push @res, "$m/";
            }
        }
    }

    my $res = $self->_load_module($req);
    return $res if $res && $res->[0] != 405;

    # get all entities from this module
    no strict 'refs';
    my $spec = \%{"$req->{-perl_package}\::SPEC"};
    my $dir = $req->{-uri_dir};
    for my $e (sort keys %$spec) {
        next if $e =~ /^:/;
        my $path = "$dir/$e";
        next unless $filter_path->($path);
        next if $mem{$path}++;
        my $t = $e =~ /^[%\@\$]/ ? 'variable' : 'function';
        next if $f_type && $f_type ne $t;
        if ($detail) {
            push @res, {
                uri=>$e, type=>$t,
            };
        } else {
            push @res, $e;
        }
    }

    [200, "OK (list action)", \@res];
}

sub actionmeta_meta { +{
    applies_to => ['*'],
    summary    => "Get metadata",
} }

sub action_meta {
    my ($self, $req) = @_;

    my $res = $self->get_meta($req);
    return $res if $res;

    [200, "OK (meta action)", $req->{-meta}];
}

sub actionmeta_call { +{
    applies_to => ['function'],
    summary    => "Call function",
} }

sub action_call {
    require UUID::Random;

    my ($self, $req) = @_;

    my $res;

    my $tm; # = does client mention tx_id?
    if (defined $req->{tx_id}) {
        $res = $self->_pre_tx_action($req);
        return $res if $res;
        $tm = $self->{_tx_manager};
        $tm->{_tx_id} = $req->{tx_id};
    }

    $res = $self->get_meta($req);
    return $res if $res;
    $res = $self->get_code($req);
    return $res if $res;

    my %args;

    # try to convert from argv if given argv
    if (exists($req->{argv}) && $self->{accept_argv}) {
        require Perinci::Sub::GetArgs::Argv;
        $res = Perinci::Sub::GetArgs::Argv::get_args_from_argv(
            argv => [@{ $req->{argv} }],
            meta => $req->{-meta},
        );
        return err(400, "Can't parse argv", $res) unless $res->[0] == 200;
        %args = %{ $res->[2] };
    } else {
        %args = %{ $req->{args} // {} };
    }

    my $risub = risub($req->{-meta});

    if ($req->{dry_run}) {
        return err(412, "Function does not support dry run")
            unless $risub->can_dry_run;
        if ($risub->feature('dry_run')) {
            $args{-dry_run} = 1;
        } else {
            $args{-dry_run} = 1;
            $args{-tx_action} = 'check_state';
            $args{-tx_action_id} = UUID::Random::generate();
            undef $tm;
        }
    }

    if ($risub->feature('progress')) {
        require Progress::Any;
        $args{-progress} = Progress::Any->get_indicator();
    }

    if ($tm) {
        $res = $tm->action(
            f => "$req->{-perl_package}::$req->{-uri_leaf}", args=>\%args,
            confirm => $req->{confirm},
        );
        $tm->{_tx_id} = undef if $tm;
    } else {
        $args{-confirm} = 1 if $req->{confirm};
        eval { $res = $req->{-code}->(%args) };
        my $eval_err = $@;
        if ($eval_err) {
            $res = err(500, "Function died: $eval_err");
        }
    }

    # add hint that result is binary
    if (defined $res->[2]) {
        if ($req->{-meta}{result} && $req->{-meta}{result}{schema} &&
                $req->{-meta}{result}{schema}[0] eq 'buf') {
            $res->[3]{'x.hint.result_binary'} = 1;
        }
    }

    $res;
}

sub actionmeta_complete_arg_val { +{
    applies_to => ['function'],
    summary    => "Complete function's argument value"
} }

sub action_complete_arg_val {
    require Perinci::Sub::Complete;

    my ($self, $req) = @_;
    my $arg = $req->{arg} or return err(400, "Please specify arg");
    my $word = $req->{word} // "";
    my $ci = $req->{ci};

    my $res = $self->get_meta($req);
    return $res if $res;
    [200, "OK (complete_arg_val action)",
     Perinci::Sub::Complete::complete_arg_val(meta=>$req->{-meta}, word=>$word,
                                              arg=>$arg, ci=>$ci) // []];
}

sub actionmeta_complete_arg_elem { +{
    applies_to => ['function'],
    summary    => "Complete function's argument element value"
} }

sub action_complete_arg_elem {
    require Perinci::Sub::Complete;

    my ($self, $req) = @_;
    my $arg = $req->{arg} or return err(400, "Please specify arg");
    defined(my $index = $req->{index})
        or return err(400, "Please specify index");
    my $word = $req->{word} // "";
    my $ci = $req->{ci};

    my $res = $self->get_meta($req);
    return $res if $res;
    [200, "OK (complete_arg_elem action)",
     Perinci::Sub::Complete::complete_arg_elem(
         meta=>$req->{-meta}, word=>$word, arg=>$arg, ci=>$ci, index=>$index,
     ) // []];
}

sub actionmeta_child_metas { +{
    applies_to => ['package'],
    summary    => "Get metadata of all child entities",
} }

sub action_child_metas {
    my ($self, $req) = @_;

    my $res = $self->action_list($req);
    return $res unless $res->[0] == 200;
    my $ents = $res->[2];

    my %res;
    my %om;
    my $base = uri_join(
        $req->{-uri_scheme}, $req->{-uri_auth}, $req->{-uri_dir});

    for my $ent (@$ents) {
        $res = $self->request(meta => "$base/$ent");
        # ignore failed request
        next unless $res->[0] == 200;
        $res{$ent} = $res->[2];
    }
    [200, "OK (child_metas action)", \%res];
}

sub actionmeta_get { +{
    applies_to => ['variable'],
    summary    => "Get value of variable",
} }

sub action_get {
    no strict 'refs';

    my ($self, $req) = @_;
    local $req->{-uri_leaf} = $req->{-uri_leaf};

    # extract prefix
    $req->{-uri_leaf} =~ s/^([%\@\$])//
        or return err(500, "BUG: Unknown variable prefix");
    my $prefix = $1;
    my $name = $req->{-perl_package} . "::" . $req->{-uri_leaf};
    my $res =
        $prefix eq '$' ? ${$name} :
            $prefix eq '@' ? \@{$name} :
                $prefix eq '%' ? \%{$name} :
                    undef;
    [200, "OK (get action)", $res];
}

sub _pre_tx_action {
    my ($self, $req) = @_;

    return err(501, "Transaction not supported by server")
        unless $self->{use_tx};

    # instantiate custom tx manager, per request if necessary
    if (ref($self->{custom_tx_manager}) eq 'CODE') {
        eval {
            $self->{_tx_manager} = $self->{custom_tx_manager}->($self);
            die $self->{_tx_manager} unless blessed($self->{_tx_manager});
        };
        return err(500, "Can't initialize custom tx manager: ".
                       "$self->{_tx_manager}: $@") if $@;
    } elsif (!blessed($self->{_tx_manager})) {
        my $tm_cl = $self->{custom_tx_manager} // "Perinci::Tx::Manager";
        my $tm_cl_p = $tm_cl; $tm_cl_p =~ s!::!/!g; $tm_cl_p .= ".pm";
        eval {
            require $tm_cl_p;
            $self->{_tx_manager} = $tm_cl->new(pa => $self);
            die $self->{_tx_manager} unless blessed($self->{_tx_manager});
        };
        return err(500, "Can't initialize tx manager ($tm_cl): $@") if $@;
        # we just want to force newer version, we currently can't specify this
        # in Makefile.PL because peritm's tests use us. this might be rectified
        # in the future.
        if ($tm_cl eq 'Perinci::Tx::Manager') {
            $Perinci::Tx::Manager::VERSION >= 0.29
                or die "Your Perinci::Tx::Manager is too old, ".
                    "please install v0.29 or later";
        }
    }

    return;
}

sub actionmeta_begin_tx { +{
    applies_to => ['*'],
    summary    => "Start a new transaction",
} }

sub action_begin_tx {
    my ($self, $req) = @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->begin(
        tx_id   => $req->{tx_id},
        summary => $req->{summary},
    );
}

sub actionmeta_commit_tx { +{
    applies_to => ['*'],
    summary    => "Commit a transaction",
} }

sub action_commit_tx {
    my ($self, $req) = @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->commit(
        tx_id  => $req->{tx_id},
    );
}

sub actionmeta_savepoint_tx { +{
    applies_to => ['*'],
    summary    => "Create a savepoint in a transaction",
} }

sub action_savepoint_tx {
    my ($self, $req) = @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->savepoint(
        tx_id => $req->{tx_id},
        sp    => $req->{tx_spid},
    );
}

sub actionmeta_release_tx_savepoint { +{
    applies_to => ['*'],
    summary    => "Release a transaction savepoint",
} }

sub action_release_tx_savepoint {
    my ($self, $req) =\ @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->release_savepoint(
        tx_id => $req->{tx_id},
        sp    => $req->{tx_spid},
    );
}

sub actionmeta_rollback_tx { +{
    applies_to => ['*'],
    summary    => "Rollback a transaction (optionally to a savepoint)",
} }

sub action_rollback_tx {
    my ($self, $req) = @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->rollback(
        tx_id => $req->{tx_id},
        sp    => $req->{tx_spid},
    );
}

sub actionmeta_list_txs { +{
    applies_to => ['*'],
    summary    => "List transactions",
} }

sub action_list_txs {
    my ($self, $req) = @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->list(
        detail    => $req->{detail},
        tx_status => $req->{tx_status},
        tx_id     => $req->{tx_id},
    );
}

sub actionmeta_undo { +{
    applies_to => ['*'],
    summary    => "Undo a committed transaction",
} }

sub action_undo {
    my ($self, $req) = @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->undo(
        tx_id   => $req->{tx_id},
        confirm => $req->{confirm},
    );
}

sub actionmeta_redo { +{
    applies_to => ['*'],
    summary    => "Redo an undone committed transaction",
} }

sub action_redo {
    my ($self, $req) = @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->redo(
        tx_id   => $req->{tx_id},
        confirm => $req->{confirm},
    );
}

sub actionmeta_discard_tx { +{
    applies_to => ['*'],
    summary    => "Discard (forget) a committed transaction",
} }

sub action_discard_tx {
    my ($self, $req) = @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->discard(
        tx_id => $req->{tx_id},
    );
}

sub actionmeta_discard_all_txs { +{
    applies_to => ['*'],
    summary    => "Discard (forget) all committed transactions",
} }

sub action_discard_all_txs {
    my ($self, $req) = @_;
    my $res = $self->_pre_tx_action($req);
    return $res if $res;

    $self->{_tx_manager}->discard_all(
        # XXX select client
    );
}

1;
# ABSTRACT: Base class for Perinci::Access::Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Access::Schemeless - Base class for Perinci::Access::Perl

=head1 VERSION

This document describes version 0.891 of Perinci::Access::Schemeless (from Perl distribution Perinci-Access-Perl), released on 2019-07-21.

=head1 DESCRIPTION

This class is the base class for L<Perinci::Access::Perl>, and by default acts
like Perinci::Access::Perl (e.g. given uri C</Foo/Bar/baz> it will refer to
function C<baz> in Perl package C<Foo::Bar>; it also looks for Rinci metadata in
C<%SPEC> package variables by default). But this class is designed to be
flexible: you can override aspects of it so it can map uri to different Perl
packages (e.g. using option like C<package_prefix>), you can retrieve Rinci
metadata from a database or whatever, etc.

Supported features:

=over

=item * Basic Riap actions

These include C<info>, C<actions>, C<meta>, C<list>, and C<call> actions.

=item * Transaction/undo

According to L<Rinci::Transaction>.

=item * Function wrapping

Wrapping is used to convert argument passing style, produce result envelope, add
argument validation, as well as numerous other functionalities. See
L<Perinci::Sub::Wrapper> for more details on wrapping. The default behavior will
call wrapped functions.

=item * Custom location of metadata

By default, metadata are assumed to be stored embedded in Perl source code in
C<%SPEC> package variables (with keys matching function names, C<$variable>
names, or C<:package> for the package metadata itself).

You can override C<get_meta()> to provide custom behavior. For example, you can
store metadata in separate file or database.

=item * Custom code entity tree

By default, tree are formed by traversing Perl packages and their contents, for
example if a C<list> action is requested on uri C</Foo/Bar/> then the contents
of package C<Foo::Bar> and its subpackages will be traversed for the entities.

You can override C<action_list()> to provide custom behavior. For example, you
can lookup from the database.

=item * Progress indicator

Functions can express that they do progress updating through the C<features>
property in its metadata:

 features => {
     progress => 1,
     ...
 }

For these functions, this class will pass a special argument C<-progress>
containing L<Progress::Any> object. Functions can update progress using this
object.

=back

=head2 How request is processed

User calls C<< $pa->request($action => $uri, \%extras) >>. Internally, the
method creates a hash C<$req> which contains Riap request keys as well as
internal information about the Riap request (the latter will be prefixed with
dash C<->). Initially it will contain C<action> and C<uri> and the C<%extras>
keys from the request() arguments sent by the user.

Internal C<_parse_uri()> method will be called to parse C<uri> into C<-uri_dir>
(the "dir" part), C<-uri_leaf> (the "basename" part), and C<-perl_package>.
Forbidden or invalid paths will cause this method to return an enveloped error
response and the request to stop. For example, if C<uri> is C</Foo/Bar/> then
C<-uri_dir> is C</Foo/Bar/> and C<-uri_leaf> is an empty string. If C<uri> is
C</Foo/Bar/baz> then C<-uri_dir> is C</Foo/Bar/> while C<-uri_leaf> is C<baz>.
C<-uri_dir> will be used for the C<list> action. In both cases, C<-perl_package>
will be set to C<Foo::Bar>.

The code entity type is then determined currently using a few simple heuristic
rules: if C<-uri_leaf> is empty string, type is C<package>. If C<-uri_leaf>
begins with C<[$%@]>, type is C<variable>. Otherwise, type is C<function>.
C<-type> will be set.

After this, the appropriate C<action_ACTION()> method will be called. For
example if action is C<meta> then C<action_meta()> method will be called, with
C<$req> as the argument. This will in turn, depending on the action, either call
C<get_meta()> (for example if action is C<meta>) or C<get_code()> (for example
if action is C<call>), also with C<$req> as the argument. C<get_meta()> and
C<get_code()> should return nothing on success, and set either C<-meta> (a
defhash containing Rinci metadata) or C<-code> (a coderef), respectively. On
error, they must return an enveloped error response.

C<get_meta()> or C<get_code()> might call C<_load_module()> to load Perl modules
if the C<load> attribute is set to true.

=for Pod::Coverage ^(actionmeta_.+|action_.+|get_(meta|code))$

=head1 ADDED RESULT METADATA

This class might add the following property/attribute in result metadata:

=head2 x.hint.result_binary => bool

If result's schema type is C<buf>, then this class will set this attribute to
true, to give hints to result formatters.

=head1 METHODS

=head2 PKG->new(%attrs) => OBJ

Instantiate object. Known attributes:

=over 4

=item * load => BOOL (default: 1)

Whether to load Perl modules that are requested.

=item * after_load => CODE

If set, code will be executed the first time Perl module is successfully loaded.

=item * wrap => BOOL (default: 1)

If set to false, then wil use original subroutine and metadata instead of
wrapped ones, for example if you are very concerned about performance (do not
want to add another eval {} and subroutine call introduced by wrapping) or do
not need the functionality provided by the wrapper (e.g. your function already
validates its arguments, accepts arguments as hash, and returns enveloped
result).

Wrapping is implemented inside C<get_code()>.

=item * set_function_properties => HASH

If set, will be passed to L<Perinci::Sub::Wrapper> wrap_sub()'s C<convert>
argument when wrapping subroutines. Some applications of this include: changing
C<default_lang> of metadata.

This is only relevant if you enable C<wrap>.

=item * cache_size => INT (default: 100)

Specify cache size (in number of items), for caching metadata and wrapping
result. Setting this to 0 disables caching.

Caching is implemented inside C<get_meta()> and C<get_code()> so you might want
to implement your own caching if you override those.

=item * allow_paths => REGEX|STR|ARRAY

If defined, only requests with C<uri> matching specified path will be allowed.
Can be a string (e.g. C</spanel/api/>) or regex (e.g. C<< qr{^/[^/]+/api/} >>)
or an array of those.

=item * deny_paths => REGEX|STR|ARRAY

If defined, requests with C<uri> matching specified path will be denied. Like
C<allow_paths>, value can be a string (e.g. C</spanel/api/>) or regex (e.g. C<<
qr{^/[^/]+/api/} >>) or an array of those.

=item * allow_schemes => REGEX|STR|ARRAY

By default this class does not care about schemes, it only looks at the uri
path. You can use this option to limit allowed schemes.

=item * deny_schemes => REGEX|STR|ARRAY

By default this class does not care about schemes, it only looks at the uri
path. You can use this option to specify forbidden schemes.

=item * use_tx => BOOL (default: 0)

Whether to allow transaction requests from client. Since this can cause the
server to store transaction/undo data, this must be explicitly allowed.

You need to install L<Perinci::Tx::Manager> for transaction support (unless you
are using another transaction manager).

=item * custom_tx_manager => STR|CODE

Can be set to a string (class name) or a code that is expected to return a
transaction manager class.

By default, L<Perinci::Tx::Manager> is instantiated and maintained (not
reinstantiated on every request), but if C<custom_tx_manager> is a coderef, it
will be called on each request to get transaction manager. This can be used to
instantiate Perinci::Tx::Manager in a custom way, e.g. specifying per-user
transaction data directory and limits, which needs to be done on a per-request
basis.

=item * accept_argv => BOOL (default: 1)

From version 0.64, C<argv> key is accepted by the C<call> action and will be
converted to C<args>. This server-side conversion from C<argv> to <args> can
handle coderefs in C<cmdline_aliases> (and probably other things too) compared
when doing conversion at the client-side.

This option allows disabling this behavior.

=back

=head2 $pa->request($action => $server_url, \%extra) => $res

Process Riap request and return enveloped result. $server_url will be used as
the Riap request key 'uri', as there is no server in this case.

=head2 $pa->parse_url($server_url) => HASH

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Access-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Riap>, L<Rinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
