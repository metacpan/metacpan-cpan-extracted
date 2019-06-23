package Perinci::Sub::GetArgs::Argv;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '0.842'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Data::Sah::Normalize qw(normalize_schema);
use Data::Sah::Util::Type qw(is_type is_simple);
use Getopt::Long::Negate::EN qw(negations_for_option);
use Getopt::Long::Util qw(parse_getopt_long_opt_spec);
use List::Util qw(first);
use Perinci::Sub::GetArgs::Array qw(get_args_from_array);
use Perinci::Sub::Util qw(err);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       gen_getopt_long_spec_from_meta
                       get_args_from_argv
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Get subroutine arguments from command line arguments (@ARGV)',
};

# retun ($success?, $errmsg, $res)
sub _parse_json {
    my $str = shift;

    state $json = do {
        require JSON::PP;
        JSON::PP->new->allow_nonref;
    };

    # to rid of those JSON::PP::Boolean objects which currently choke
    # Data::Sah-generated validator code. in the future Data::Sah can be
    # modified to handle those, or we use a fork of JSON::PP which doesn't
    # produce those in the first place (probably only when performance is
    # critical).
    state $cleanser = do {
        if (eval { require Data::Clean::FromJSON; 1 }) {
            Data::Clean::FromJSON->get_cleanser;
        } else {
            undef;
        }
    };

    my $res;
    eval { $res = $json->decode($str); $cleanser->clean_in_place($res) if $cleanser };
    my $e = $@;
    return (!$e, $e, $res);
}

sub _parse_yaml {
    no warnings 'once';

    state $yaml_xs_available = do {
        if (eval { require YAML::XS; 1 }) {
            1;
        } else {
            require YAML::Old;
            0;
        }
    };

    my $str = shift;

    #local $YAML::Syck::ImplicitTyping = 1;
    my $res;
    eval {
        if ($yaml_xs_available) {
            $res = YAML::XS::Load($str);
        } else {
            # YAML::Old is too strict, it requires "--- " header and newline
            # ending
            $str = "--- $str" unless $str =~ /\A--- /;
            $str .= "\n" unless $str =~ /\n\z/;
            $res = YAML::Old::Load($str);
        }
    };
    my $e = $@;
    return (!$e, $e, $res);
}

sub _arg2opt {
    my $opt = shift;
    $opt =~ s/[^A-Za-z0-9-]+/-/g; # foo.bar_baz becomes --foo-bar-baz
    $opt;
}

# this subroutine checks whether a schema mentions a coercion rule from simple
# types (e.g. 'str_comma_sep', etc).
sub _is_coercible_from_simple {
    my $nsch = shift;
    my $cset = $nsch->[1] or return 0;
    my $rules = $cset->{'x.perl.coerce_rules'} // $cset->{'x.coerce_rules'}
        or return 0;
    for my $rule (@$rules) {
        next unless $rule =~ /\A([^_]+)_/;
        return 1 if is_simple($1);
    }
    0;
}

sub _is_simple_or_coercible_from_simple {
    my $nsch = shift;
    is_simple($nsch) || _is_coercible_from_simple($nsch);
}

# this routine's job is to avoid using Data::Sah::Resolve unless it needs to, to
# reduce startup overhead
sub _is_simple_or_array_of_simple_or_hash_of_simple {
    my $nsch = shift;

    my $is_simple = 0;
    my $is_array_of_simple = 0;
    my $is_hash_of_simple = 0;
    my $eltype;

    my $type = $nsch->[0];
    my $cset = $nsch->[1];

    {
        # if not known as builtin type, then resolve it first
        unless (is_type($nsch)) {
            require Data::Sah::Resolve;
            my $res = Data::Sah::Resolve::resolve_schema(
                {merge_clause_sets => 0}, $nsch);
            $type = $res->[0];
            $cset = $res->[1][0] // {};
        }

        $is_simple = _is_simple_or_coercible_from_simple([$type, $cset]);
        last if $is_simple;

        if ($type eq 'array') {
            my $elnsch = $cset->{of} // $cset->{each_elem};
            last unless $elnsch;
            $elnsch = normalize_schema($elnsch);
            $eltype = $elnsch->[0];

            # if not known as builtin type, then resolve it first
            unless (is_type($elnsch)) {
                require Data::Sah::Resolve;
                my $res = Data::Sah::Resolve::resolve_schema(
                    {merge_clause_sets => 0}, $elnsch);
                $elnsch = [$res->[0], $res->[1][0] // {}]; # XXX we only take the first clause set
                $eltype = $res->[0];
            }

            $is_array_of_simple = _is_simple_or_coercible_from_simple($elnsch);
            last;
        }

        if ($type eq 'hash') {
            my $elnsch = $cset->{of} // $cset->{each_value} // $cset->{each_elem};
            last unless $elnsch;
            $elnsch = normalize_schema($elnsch);
            $eltype = $elnsch->[0];

            # if not known as builtin type, then resolve it first
            unless (is_type($elnsch)) {
                require Data::Sah::Resolve;
                my $res = Data::Sah::Resolve::resolve_schema(
                    {merge_clause_sets => 0}, $elnsch);
                $elnsch = [$res->[0], $res->[1][0] // {}]; # XXX we only take the first clause set
                $eltype = $res->[0];
            }

            $is_hash_of_simple = _is_simple_or_coercible_from_simple($elnsch);
            last;
        }
    }

    #{ no warnings 'uninitialized'; say "D:$nsch->[0]: is_simple=<$is_simple>, is_array_of_simple=<$is_array_of_simple>, is_hash_of_simple=<$is_hash_of_simple>, type=<$type>, eltype=<$eltype>" };
    ($is_simple, $is_array_of_simple, $is_hash_of_simple, $type, $cset, $eltype);
}

# return one or more triplets of Getopt::Long option spec, its parsed structure,
# and extra stuffs. we do this to avoid having to call
# parse_getopt_long_opt_spec().
sub _opt2ospec {
    my ($opt, $schema, $arg_spec) = @_;
    my ($is_simple, $is_array_of_simple, $is_hash_of_simple, $type, $cset, $eltype) =
        _is_simple_or_array_of_simple_or_hash_of_simple($schema);

    my (@opts, @types, @isaos, @ishos);

    if ($is_array_of_simple || $is_hash_of_simple) {
        my $singular_opt;
        if ($arg_spec && $arg_spec->{'x.name.is_plural'}) {
            if ($arg_spec->{'x.name.singular'}) {
                $singular_opt = _arg2opt($arg_spec->{'x.name.singular'});
            } else {
                require Lingua::EN::PluralToSingular;
                $singular_opt = Lingua::EN::PluralToSingular::to_singular($opt);
            }
        } else {
            $singular_opt = $opt;
        }
        push @opts , $singular_opt;
        push @types, $eltype;
        push @isaos, $is_array_of_simple ? 1:0;
        push @ishos, $is_hash_of_simple  ? 1:0;
    }

    if ($is_simple || !@opts) {
        push @opts , $opt;
        push @types, $type;
        push @isaos, 0;
        push @ishos, 0;
    }

    my @res;

    for my $i (0..$#opts) {
        my $opt   = $opts[$i];
        my $type  = $types[$i];
        my $isaos = $isaos[$i];
        my $ishos = $ishos[$i];

        if ($type eq 'bool') {
            if (length($opt) == 1 || $cset->{is}) {
                # single-letter option like -b doesn't get --nob.
                # [bool=>{is=>1}] also means it's a flag and should not get
                # --nofoo.
                push @res, ($opt, {opts=>[$opt]}), undef;
            } else {
                my @negs = negations_for_option($opt);
                push @res, $opt, {opts=>[$opt]}, {is_neg=>0, neg_opts=>\@negs};
                for (@negs) {
                    push @res, $_, {opts=>[$_]}, {is_neg=>1, pos_opts=>[$opt]};
                }
            }
        } elsif ($type eq 'buf') {
            push @res, (
                "$opt=s", {opts=>[$opt], desttype=>"", type=>"s"}, undef,
                "$opt-base64=s", {opts=>["$opt-base64"], desttype=>"", type=>"s"}, {is_base64=>1},
            );
        } else {
            my $t = ($type eq 'int' ? 's' : $type eq 'float' ? 's' : 's') .
                ($isaos ? '@' : $ishos ? '%' : '');
            push @res, ("$opt=$t", {opts=>[$opt], desttype=>"", type=>$t}, undef);
        }
    }

    @res;
}

sub _args2opts {
    my %args = @_;

    my $argprefix        = $args{argprefix};
    my $parent_args      = $args{parent_args};
    my $meta             = $args{meta};
    my $seen_opts        = $args{seen_opts};
    my $seen_common_opts = $args{seen_common_opts};
    my $seen_func_opts   = $args{seen_func_opts};
    my $rargs            = $args{rargs};
    my $go_spec          = $args{go_spec};
    my $specmeta         = $args{specmeta};

    my $args_prop = $meta->{args} // {};

    for my $arg (keys %$args_prop) {
        my $fqarg    = "$argprefix$arg";
        my $arg_spec = $args_prop->{$arg};
        next if grep { $_ eq 'hidden' || $_ eq 'hidden-cli' }
            @{ $arg_spec->{tags} // [] };
        my $sch      = $arg_spec->{schema} // ['any', {}];
        my ($is_simple, $is_array_of_simple, $is_hash_of_simple, $type, $cset, $eltype) =
            _is_simple_or_array_of_simple_or_hash_of_simple($sch);

        # XXX normalization of 'of' clause should've been handled by sah itself
        if ($type eq 'array' && $cset->{of}) {
            $cset->{of} = normalize_schema($cset->{of});
        }
        my $opt = _arg2opt($fqarg);
        if ($seen_opts->{$opt}) {
            my $i = 1;
            my $opt2;
            while (1) {
                $opt2 = "$opt-arg" . ($i > 1 ? $i : '');
                last unless $seen_opts->{$opt2};
                $i++;
            }
            $opt = $opt2;
        }

        my $stash = {};

        # why we use coderefs here? due to Getopt::Long's behavior. when
        # @ARGV=qw() and go_spec is ('foo=s' => \$opts{foo}) then %opts will
        # become (foo=>undef). but if go_spec is ('foo=s' => sub { $opts{foo} =
        # $_[1] }) then %opts will become (), which is what we prefer, so we can
        # later differentiate "unspecified" (exists($opts{foo}) == false) and
        # "specified as undef" (exists($opts{foo}) == true but
        # defined($opts{foo}) == false).

        my $handler = sub {
            my ($val, $val_set);

            # how many times have been called for this argument?
            my $num_called = ++$stash->{called}{$arg};

            # hashify rargs till the end of the handler scope if it happens to
            # be an array (this is the case when we want to fill values using
            # element_meta).
            my $rargs = do {
                if (ref($rargs) eq 'ARRAY') {
                    $rargs->[$num_called-1] //= {};
                    $rargs->[$num_called-1];
                } else {
                    $rargs;
                }
            };

            if ($is_simple) {
                $val_set = 1; $val = $_[1];
                $rargs->{$arg} = $val;
            } elsif ($is_array_of_simple) {
                $rargs->{$arg} //= [];
                $val_set = 1; $val = $_[1];
                push @{ $rargs->{$arg} }, $val;
            } elsif ($is_hash_of_simple) {
                $rargs->{$arg} //= {};
                $val_set = 1; $val = $_[2];
                $rargs->{$arg}{$_[1]} = $val;
            } else {
                {
                    my ($success, $e, $decoded);
                    ($success, $e, $decoded) = _parse_json($_[1]);
                    if ($success) {
                        $val_set = 1; $val = $decoded;
                        $rargs->{$arg} = $val;
                        last;
                    }
                    ($success, $e, $decoded) = _parse_yaml($_[1]);
                    if ($success) {
                        $val_set = 1; $val = $decoded;
                        $rargs->{$arg} = $val;
                        last;
                    }
                    die "Invalid YAML/JSON in arg '$fqarg'";
                }
            }
            if ($val_set && $arg_spec->{cmdline_on_getopt}) {
                $arg_spec->{cmdline_on_getopt}->(
                    arg=>$arg, fqarg=>$fqarg, value=>$val, args=>$rargs,
                    opt=>$opt,
                );
            }
        }; # handler

        my @triplets = _opt2ospec($opt, $sch, $arg_spec);
        my $aliases_processed;
        while (my ($ospec, $parsed, $extra) = splice @triplets, 0, 3) {
            $extra //= {};
            if ($extra->{is_neg}) {
                $go_spec->{$ospec} = sub { $handler->($_[0], 0) };
            } elsif (defined $extra->{is_neg}) {
                $go_spec->{$ospec} = sub { $handler->($_[0], 1) };
            } elsif ($extra->{is_base64}) {
                $go_spec->{$ospec} = sub {
                    require MIME::Base64;
                    my $decoded = MIME::Base64::decode($_[1]);
                    $handler->($_[0], $decoded);
                };
            } else {
                $go_spec->{$ospec} = $handler;
            }

            $specmeta->{$ospec} = {arg=>$arg, fqarg=>$fqarg, parsed=>$parsed, %$extra};
            for (@{ $parsed->{opts} }) {
                $seen_opts->{$_}++; $seen_func_opts->{$_} = $fqarg;
            }

            if ($parent_args->{per_arg_json} && !$is_simple) {
                my $jopt = "$opt-json";
                if ($seen_opts->{$jopt}) {
                    warn "Clash of option: $jopt, not added";
                } else {
                    my $jospec = "$jopt=s";
                    my $parsed = {type=>"s", opts=>[$jopt]};
                    $go_spec->{$jospec} = sub {
                        my ($success, $e, $decoded);
                        ($success, $e, $decoded) = _parse_json($_[1]);
                        if ($success) {
                            $rargs->{$arg} = $decoded;
                        } else {
                            die "Invalid JSON in option --$jopt: $_[1]: $e";
                        }
                    };
                    $specmeta->{$jospec} = {arg=>$arg, fqarg=>$fqarg, is_json=>1, parsed=>$parsed, %$extra};
                    $seen_opts->{$jopt}++; $seen_func_opts->{$jopt} = $fqarg;
                }
            }
            if ($parent_args->{per_arg_yaml} && !$is_simple) {
                my $yopt = "$opt-yaml";
                if ($seen_opts->{$yopt}) {
                    warn "Clash of option: $yopt, not added";
                } else {
                    my $yospec = "$yopt=s";
                    my $parsed = {type=>"s", opts=>[$yopt]};
                    $go_spec->{$yospec} = sub {
                        my ($success, $e, $decoded);
                        ($success, $e, $decoded) = _parse_yaml($_[1]);
                        if ($success) {
                            $rargs->{$arg} = $decoded;
                        } else {
                            die "Invalid YAML in option --$yopt: $_[1]: $e";
                        }
                    };
                    $specmeta->{$yospec} = {arg=>$arg, fqarg=>$fqarg, is_yaml=>1, parsed=>$parsed, %$extra};
                    $seen_opts->{$yopt}++; $seen_func_opts->{$yopt} = $fqarg;
                }
            }

            # parse argv_aliases
            if ($arg_spec->{cmdline_aliases} && !$aliases_processed++) {
                for my $al (keys %{$arg_spec->{cmdline_aliases}}) {
                    my $alspec = $arg_spec->{cmdline_aliases}{$al};
                    my $alsch = $alspec->{schema} //
                        $alspec->{is_flag} ? [bool=>{req=>1,is=>1}] : $sch;
                    my $altype = $alsch->[0];
                    my $alopt = _arg2opt("$argprefix$al");
                    if ($seen_opts->{$alopt}) {
                        warn "Clash of cmdline_alias option $al";
                        next;
                    }
                    my $alcode = $alspec->{code};
                    my $alospec;
                    my $parsed;
                    if ($alcode && $alsch->[0] eq 'bool') {
                        # bool --alias doesn't get --noalias if has code
                        $alospec = $alopt; # instead of "$alopt!"
                        $parsed = {opts=>[$alopt]};
                    } else {
                        ($alospec, $parsed) = _opt2ospec($alopt, $alsch);
                    }

                    if ($alcode) {
                        if ($alcode eq 'CODE') {
                            if ($parent_args->{ignore_converted_code}) {
                                $alcode = sub {};
                            } else {
                                return [
                                    501,
                                    join("",
                                         "Code in cmdline_aliases for arg $fqarg ",
                                         "got converted into string, probably ",
                                         "because of JSON/YAML transport"),
                                ];
                            }
                        }
                        # alias handler
                        $go_spec->{$alospec} = sub {

                            # do the same like in arg handler
                            my $num_called = ++$stash->{called}{$arg};
                            my $rargs = do {
                                if (ref($rargs) eq 'ARRAY') {
                                    $rargs->[$num_called-1] //= {};
                                    $rargs->[$num_called-1];
                                } else {
                                    $rargs;
                                }
                            };

                            $alcode->($rargs, $_[1]);
                        };
                    } else {
                        $go_spec->{$alospec} = $handler;
                    }
                    $specmeta->{$alospec} = {
                        alias     => $al,
                        is_alias  => 1,
                        alias_for => $ospec,
                        arg       => $arg,
                        fqarg     => $fqarg,
                        is_code   => $alcode ? 1:0,
                        parsed    => $parsed,
                        %$extra,
                    };
                    push @{$specmeta->{$ospec}{($alcode ? '':'non').'code_aliases'}},
                        $alospec;
                    $seen_opts->{$alopt}++; $seen_func_opts->{$alopt} = $fqarg;
                }
            } # cmdline_aliases

            # submetadata
            if ($arg_spec->{meta}) {
                $rargs->{$arg} = {};
                my $res = _args2opts(
                    %args,
                    argprefix => "$argprefix$arg\::",
                    meta      => $arg_spec->{meta},
                    rargs     => $rargs->{$arg},
                );
                return $res if $res;
            }

            # element submetadata
            if ($arg_spec->{element_meta}) {
                $rargs->{$arg} = [];
                my $res = _args2opts(
                    %args,
                    argprefix => "$argprefix$arg\::",
                    meta      => $arg_spec->{element_meta},
                    rargs     => $rargs->{$arg},
                );
                return $res if $res;
            }
        } # for ospec triplet

    } # for arg

    undef;
}

$SPEC{gen_getopt_long_spec_from_meta} = {
    v           => 1.1,
    summary     => 'Generate Getopt::Long spec from Rinci function metadata',
    description => <<'_',

This routine will produce a <pm:Getopt::Long> specification from Rinci function
metadata, as well as some more data structure in the result metadata to help
producing a command-line help/usage message.

Function arguments will be mapped to command-line options with the same name,
with non-alphanumeric characters changed to `-` (`-` is preferred over `_`
because it lets user avoid pressing Shift on popular keyboards). For example:
`file_size` becomes `file-size`, `file_size.max` becomes `file-size-max`. If
function argument option name clashes with command-line option or another
existing option, it will be renamed to `NAME-arg` (or `NAME-arg2` and so on).
For example: `help` will become `help-arg` (if `common_opts` contains `help`,
that is).

Each command-line alias (`cmdline_aliases` property) in the argument
specification will also be added as command-line option, except if it clashes
with an existing option, in which case this function will warn and skip adding
the alias. For more information about `cmdline_aliases`, see `Rinci::function`.

For arguments with type of `bool`, Getopt::Long will by default also
automatically recognize `--noNAME` or `--no-NAME` in addition to `--name`. So
this function will also check those names for clashes.

For arguments with type array of simple scalar, `--NAME` can be specified more
than once to append to the array.

If `per_arg_json` setting is active, and argument's schema is not a "required
simple scalar" (e.g. an array, or a nullable string), then `--NAME-json` will
also be added to let users input undef (through `--NAME-json null`) or a
non-scalar value (e.g. `--NAME-json '[1,2,3]'`). If this name conflicts with
another existing option, a warning will be displayed and the option will not be
added.

If `per_arg_yaml` setting is active, and argument's schema is not a "required
simple scalar" (e.g. an array, or a nullable string), then `--NAME-yaml` will
also be added to let users input undef (through `--NAME-yaml '~'`) or a
non-scalar value (e.g. `--NAME-yaml '[foo, bar]'`). If this name conflicts with
another existing option, a warning will be displayed and the option will not be
added. YAML can express a larger set of values, e.g. binary data, circular
references, etc.

Will produce a hash (Getopt::Long spec), with `func.specmeta`, `func.opts`,
`func.common_opts`, `func.func_opts` that contain extra information
(`func.specmeta` is a hash of getopt spec name and a hash of extra information
while `func.*opts` lists all used option names).

_
    args => {
        meta => {
            summary => 'Rinci function metadata',
            schema  => 'hash*',
            req     => 1,
        },
        meta_is_normalized => {
            schema => 'bool*',
        },
        args => {
            summary => 'Reference to hash which will store the result',
            schema  => 'hash*',
        },
        common_opts => {
            summary => 'Common options',
            description => <<'_',

A hash where the values are hashes containing these keys: `getopt` (Getopt::Long
option specification), `handler` (Getopt::Long handler). Will be passed to
`get_args_from_argv()`. Example:

    {
        help => {
            getopt  => 'help|h|?',
            handler => sub { ... },
            summary => 'Display help and exit',
        },
        version => {
            getopt  => 'version|v',
            handler => sub { ... },
            summary => 'Display version and exit',
        },
    }

_
            schema => ['hash*'],
        },
        per_arg_json => {
            summary => 'Whether to add --NAME-json for non-simple arguments',
            schema  => 'bool',
            default => 0,
            description => <<'_',

Will also interpret command-line arguments as JSON if assigned to function
arguments, if arguments' schema is not simple scalar.

_
        },
        per_arg_yaml => {
            summary => 'Whether to add --NAME-yaml for non-simple arguments',
            schema  => 'bool',
            default => 0,
            description => <<'_',

Will also interpret command-line arguments as YAML if assigned to function
arguments, if arguments' schema is not simple scalar.

_
        },
        ignore_converted_code => {
            summary => 'Whether to ignore coderefs converted to string',
            schema => 'bool',
            default => 0,
            description => <<'_',

Across network through JSON encoding, coderef in metadata (e.g. in
`cmdline_aliases` property) usually gets converted to string `CODE`. In some
cases, like for tab completion, this is pretty harmless so you can turn this
option on. For example, in the case of `cmdline_aliases`, the effect is just
that command-line aliases code are not getting executed, but this is usually
okay.

_
        },
    },
};
sub gen_getopt_long_spec_from_meta {
    my %fargs = @_;

    my $meta       = $fargs{meta} or return [400, "Please specify meta"];
    unless ($fargs{meta_is_normalized}) {
        require Perinci::Sub::Normalize;
        $meta = Perinci::Sub::Normalize::normalize_function_metadata($meta);
    }
    my $co           = $fargs{common_opts} // {};
    my $per_arg_yaml = $fargs{per_arg_yaml} // 0;
    my $per_arg_json = $fargs{per_arg_json} // 0;
    my $ignore_converted_code = $fargs{ignore_converted_code};
    my $rargs        = $fargs{args} // {};

    my %go_spec;
    my %specmeta; # key = option spec, val = hash of extra info
    my %seen_opts;
    my %seen_common_opts;
    my %seen_func_opts;

    for my $k (keys %$co) {
        my $v = $co->{$k};
        my $ospec   = $v->{getopt};
        my $handler = $v->{handler};
        my $res = parse_getopt_long_opt_spec($ospec)
            or return [400, "Can't parse common opt spec '$ospec'"];
        $go_spec{$ospec} = $handler;
        $specmeta{$ospec} = {common_opt=>$k, arg=>undef, parsed=>$res};
        for (@{ $res->{opts} }) {
            return [412, "Clash of common opt '$_'"] if $seen_opts{$_};
            $seen_opts{$_}++; $seen_common_opts{$_} = $ospec;
            if ($res->{is_neg}) {
                $seen_opts{"no$_"}++ ; $seen_common_opts{"no$_"}  = $ospec;
                $seen_opts{"no-$_"}++; $seen_common_opts{"no-$_"} = $ospec;
            }
        }
    }

    my $res = _args2opts(
        argprefix        => "",
        parent_args      => \%fargs,
        meta             => $meta,
        seen_opts        => \%seen_opts,
        seen_common_opts => \%seen_common_opts,
        seen_func_opts   => \%seen_func_opts,
        rargs            => $rargs,
        go_spec          => \%go_spec,
        specmeta         => \%specmeta,
    );
    return $res if $res;

    my $opts        = [sort(map {length($_)>1 ? "--$_":"-$_"} keys %seen_opts)];
    my $common_opts = [sort(map {length($_)>1 ? "--$_":"-$_"} keys %seen_common_opts)];
    my $func_opts   = [sort(map {length($_)>1 ? "--$_":"-$_"} keys %seen_func_opts)];
    my $opts_by_common = {};
    for my $k (keys %$co) {
        my $v = $co->{$k};
        my $ospec = $v->{getopt};
        my @opts;
        for (keys %seen_common_opts) {
            next unless $seen_common_opts{$_} eq $ospec;
            push @opts, (length($_)>1 ? "--$_":"-$_");
        }
        $opts_by_common->{$ospec} = [sort @opts];
    }

    my $opts_by_arg = {};
    for (keys %seen_func_opts) {
        my $fqarg = $seen_func_opts{$_};
        push @{ $opts_by_arg->{$fqarg} }, length($_)>1 ? "--$_":"-$_";
    }
    for (keys %$opts_by_arg) {
        $opts_by_arg->{$_} = [sort @{ $opts_by_arg->{$_} }];
    }

    [200, "OK", \%go_spec,
     {
         "func.specmeta"       => \%specmeta,
         "func.opts"           => $opts,
         "func.common_opts"    => $common_opts,
         "func.func_opts"      => $func_opts,
         "func.opts_by_arg"    => $opts_by_arg,
         "func.opts_by_common" => $opts_by_common,
     }];
}

$SPEC{get_args_from_argv} = {
    v => 1.1,
    summary => 'Get subroutine arguments (%args) from command-line arguments '.
        '(@ARGV)',
    description => <<'_',

Using information in Rinci function metadata's `args` property, parse command
line arguments `@argv` into hash `%args`, suitable for passing into subroutines.

Currently uses <pm:Getopt::Long>'s `GetOptions` to do the parsing.

As with GetOptions, this function modifies its `argv` argument, so you might
want to copy the original `argv` first (or pass a copy instead) if you want to
preserve the original.

See also: gen_getopt_long_spec_from_meta() which is the routine that generates
the specification.

_
    args => {
        argv => {
            schema => ['array*' => {
                of => 'str*',
            }],
            description => 'If not specified, defaults to @ARGV',
        },
        args => {
            summary => 'Specify input args, with some arguments preset',
            schema  => ['hash'],
        },
        meta => {
            schema => ['hash*' => {}],
            req => 1,
        },
        meta_is_normalized => {
            summary => 'Can be set to 1 if your metadata is normalized, '.
                'to avoid duplicate effort',
            schema => 'bool',
            default => 0,
        },
        strict => {
            schema => ['bool' => {default=>1}],
            summary => 'Strict mode',
            description => <<'_',

If set to 0, will still return parsed argv even if there are parsing errors
(reported by Getopt::Long). If set to 1 (the default), will die upon error.

Normally you would want to use strict mode, for more error checking. Setting off
strict is used by, for example, Perinci::Sub::Complete during completion where
the command-line might still be incomplete.

Should probably be named `ignore_errors`. :-)

_
        },
        per_arg_yaml => {
            schema => ['bool' => {default=>0}],
            summary => 'Whether to recognize --ARGNAME-yaml',
            description => <<'_',

This is useful for example if you want to specify a value which is not
expressible from the command-line, like 'undef'.

    % script.pl --name-yaml '~'

See also: per_arg_json. You should enable just one instead of turning on both.

_
        },
        per_arg_json => {
            schema => ['bool' => {default=>0}],
            summary => 'Whether to recognize --ARGNAME-json',
            description => <<'_',

This is useful for example if you want to specify a value which is not
expressible from the command-line, like 'undef'.

    % script.pl --name-json 'null'

But every other string will need to be quoted:

    % script.pl --name-json '"foo"'

See also: per_arg_yaml. You should enable just one instead of turning on both.

_
        },
        common_opts => {
            summary => 'Common options',
            description => <<'_',

A hash where the values are hashes containing these keys: `getopt` (Getopt::Long
option specification), `handler` (Getopt::Long handler). Will be passed to
`get_args_from_argv()`. Example:

    {
        help => {
            getopt  => 'help|h|?',
            handler => sub { ... },
            summary => 'Display help and exit',
        },
        version => {
            getopt  => 'version|v',
            handler => sub { ... },
            summary => 'Display version and exit',
        },
    }

_
            schema => ['hash*'],
        },
        allow_extra_elems => {
            schema => ['bool' => {default=>0}],
            summary => 'Allow extra/unassigned elements in argv',
            description => <<'_',

If set to 1, then if there are array elements unassigned to one of the
arguments, instead of generating an error, this function will just ignore them.

This option will be passed to Perinci::Sub::GetArgs::Array's allow_extra_elems.

_
        },
        on_missing_required_args => {
            schema => 'code',
            summary => 'Execute code when there is missing required args',
            description => <<'_',

This can be used to give a chance to supply argument value from other sources if
not specified by command-line options. Perinci::CmdLine, for example, uses this
hook to supply value from STDIN or file contents (if argument has `cmdline_src`
specification key set).

This hook will be called for each missing argument. It will be supplied hash
arguments: (arg => $the_missing_argument_name, args =>
$the_resulting_args_so_far, spec => $the_arg_spec).

The hook can return true if it succeeds in making the missing situation
resolved. In this case, this function will not report the argument as missing.

_
        },
        ignore_converted_code => {
            summary => 'Whether to ignore coderefs converted to string',
            schema => 'bool',
            default => 0,
            description => <<'_',

Across network through JSON encoding, coderef in metadata (e.g. in
`cmdline_aliases` property) usually gets converted to string `CODE`. In some
cases, like for tab completion, this is harmless so you can turn this option on.

_
        },
        ggls_res => {
            summary => 'Full result from gen_getopt_long_spec_from_meta()',
            schema  => 'array*', # XXX envres
            description => <<'_',

If you already call `gen_getopt_long_spec_from_meta()`, you can pass the _full_ enveloped result
here, to avoid calculating twice.

_
            tags => ['category:optimization'],
        },
    },
    result => {
        description => <<'_',

Error codes:

* 400 - Error in Getopt::Long option specification, e.g. in common_opts.

* 500 - failure in GetOptions, meaning argv is not valid according to metadata
  specification (only if 'strict' mode is enabled).

* 501 - coderef in cmdline_aliases got converted into a string, probably because
  the metadata was transported (e.g. through Riap::HTTP/Riap::Simple).

_
    },
};
sub get_args_from_argv {
    require Getopt::Long;

    my %fargs = @_;
    my $argv       = $fargs{argv} // \@ARGV;
    my $meta       = $fargs{meta} or return [400, "Please specify meta"];
    unless ($fargs{meta_is_normalized}) {
        require Perinci::Sub::Normalize;
        $meta = Perinci::Sub::Normalize::normalize_function_metadata($meta);
    }
    my $strict            = $fargs{strict} // 1;
    my $common_opts       = $fargs{common_opts} // {};
    my $per_arg_yaml      = $fargs{per_arg_yaml} // 0;
    my $per_arg_json      = $fargs{per_arg_json} // 0;
    my $allow_extra_elems = $fargs{allow_extra_elems} // 0;
    my $on_missing        = $fargs{on_missing_required_args};
    my $ignore_converted_code = $fargs{ignore_converted_code};
    #$log->tracef("-> get_args_from_argv(), argv=%s", $argv);

    # to store the resulting args
    my $rargs = $fargs{args} // {};

    # 1. first we generate Getopt::Long spec
    my $genres = $fargs{ggls_res} // gen_getopt_long_spec_from_meta(
        meta => $meta, meta_is_normalized => 1,
        args => $rargs,
        common_opts  => $common_opts,
        per_arg_json => $per_arg_json,
        per_arg_yaml => $per_arg_yaml,
        ignore_converted_code => $ignore_converted_code,
    );
    return err($genres->[0], "Can't generate Getopt::Long spec", $genres)
        if $genres->[0] != 200;
    my $go_spec = $genres->[2];

    # 2. then we run GetOptions to fill $rargs from command-line opts
    #$log->tracef("GetOptions spec: %s", \@go_spec);
    {
        local $SIG{__WARN__} = sub{} if !$strict;
        my $old_go_conf = Getopt::Long::Configure(
            $strict ? "no_pass_through" : "pass_through",
            "no_ignore_case", "permute", "no_getopt_compat", "gnu_compat", "bundling");
        my $res = Getopt::Long::GetOptionsFromArray($argv, %$go_spec);
        Getopt::Long::Configure($old_go_conf);
        unless ($res) {
            return [500, "GetOptions failed"] if $strict;
        }
    }

    # 3. then we try to fill $rargs from remaining command-line arguments (for
    # args which have 'pos' spec specified)

    my $args_prop = $meta->{args};

    if (@$argv) {
        my $res = get_args_from_array(
            array=>$argv, meta => $meta,
            meta_is_normalized => 1,
            allow_extra_elems => $allow_extra_elems,
        );
        if ($res->[0] != 200 && $strict) {
            return err(500, "Get args from array failed", $res);
        } elsif ($strict && $res->[0] != 200) {
            return err("Can't get args from argv", $res);
        } elsif ($res->[0] == 200) {
            my $pos_args = $res->[2];
            for my $name (keys %$pos_args) {
                my $arg_spec = $args_prop->{$name};
                my $val      = $pos_args->{$name};
                if (exists $rargs->{$name}) {
                    return [400, "You specified option --$name but also ".
                                "argument #".$arg_spec->{pos}] if $strict;
                }
                my ($is_simple, $is_array_of_simple, $is_hash_of_simple, $type, $cset, $eltype) =
                    _is_simple_or_array_of_simple_or_hash_of_simple($arg_spec->{schema});

                if (($arg_spec->{slurpy} // $arg_spec->{greedy}) && ref($val) eq 'ARRAY' &&
                        !$is_array_of_simple && !$is_hash_of_simple) {
                    my $i = 0;
                    for (@$val) {
                      TRY_PARSING_AS_JSON_YAML:
                        {
                            my ($success, $e, $decoded);
                            if ($per_arg_json) {
                                ($success, $e, $decoded) = _parse_json($_);
                                if ($success) {
                                    $_ = $decoded;
                                    last TRY_PARSING_AS_JSON_YAML;
                                } else {
                                    warn "Failed trying to parse argv #$i as JSON: $e";
                                }
                            }
                            if ($per_arg_yaml) {
                                ($success, $e, $decoded) = _parse_yaml($_);
                                if ($success) {
                                    $_ = $decoded;
                                    last TRY_PARSING_AS_JSON_YAML;
                                } else {
                                    warn "Failed trying to parse argv #$i as YAML: $e";
                                }
                            }
                        }
                        $i++;
                    }
                }
                if (!($arg_spec->{slurpy} // $arg_spec->{greedy}) && !$is_simple) {
                  TRY_PARSING_AS_JSON_YAML:
                    {
                        my ($success, $e, $decoded);
                        if ($per_arg_json) {
                            ($success, $e, $decoded) = _parse_json($val);
                            if ($success) {
                                $val = $decoded;
                                last TRY_PARSING_AS_JSON_YAML;
                            } else {
                                warn "Failed trying to parse argv #$arg_spec->{pos} as JSON: $e";
                            }
                        }
                        if ($per_arg_yaml) {
                            ($success, $e, $decoded) = _parse_yaml($val);
                            if ($success) {
                                $val = $decoded;
                                last TRY_PARSING_AS_JSON_YAML;
                            } else {
                                warn "Failed trying to parse argv #$arg_spec->{pos} as YAML: $e";
                            }
                        }
                    }
                }
                $rargs->{$name} = $val;
                # we still call cmdline_on_getopt for this
                if ($arg_spec->{cmdline_on_getopt}) {
                    if ($arg_spec->{slurpy} // $arg_spec->{greedy}) {
                        $arg_spec->{cmdline_on_getopt}->(
                            arg=>$name, fqarg=>$name, value=>$_, args=>$rargs,
                            opt=>undef, # this marks that value is retrieved from cmdline arg
                        ) for @$val;
                    } else {
                        $arg_spec->{cmdline_on_getopt}->(
                            arg=>$name, fqarg=>$name, value=>$val, args=>$rargs,
                            opt=>undef, # this marks that value is retrieved from cmdline arg
                        );
                    }
                }
            }
        }
    }

    # 4. check missing required args

    my %missing_args;
    for my $arg (keys %$args_prop) {
        my $arg_spec = $args_prop->{$arg};
        if (!exists($rargs->{$arg})) {
            next unless $arg_spec->{req};
            # give a chance to hook to set missing arg
            if ($on_missing) {
                next if $on_missing->(arg=>$arg, args=>$rargs, spec=>$arg_spec);
            }
            next if exists $rargs->{$arg};
            $missing_args{$arg} = 1;
        }
    }

    # 5. check 'deps', currently we only support 'arg' dep type
    {
        last unless $strict;

        for my $arg (keys %$args_prop) {
            my $arg_spec = $args_prop->{$arg};
            next unless exists $rargs->{$arg};
            next unless $arg_spec->{deps};
            my $dep_arg = $arg_spec->{deps}{arg};
            next unless $dep_arg;
            return [400, "You specify '$arg', but don't specify '$dep_arg' ".
                        "(upon which '$arg' depends)"]
                unless exists $rargs->{$dep_arg};
        }
    }

    #$log->tracef("<- get_args_from_argv(), args=%s, remaining argv=%s",
    #             $rargs, $argv);
    [200, "OK", $rargs, {
        "func.missing_args" => [sort keys %missing_args],
        "func.gen_getopt_long_spec_result" => $genres,
    }];
}

1;
# ABSTRACT: Get subroutine arguments from command line arguments (@ARGV)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::GetArgs::Argv - Get subroutine arguments from command line arguments (@ARGV)

=head1 VERSION

This document describes version 0.842 of Perinci::Sub::GetArgs::Argv (from Perl distribution Perinci-Sub-GetArgs-Argv), released on 2019-06-20.

=head1 SYNOPSIS

 use Perinci::Sub::GetArgs::Argv;

 my $res = get_args_from_argv(argv=>\@ARGV, meta=>$meta, ...);

=head1 DESCRIPTION

This module provides C<get_args_from_argv()>, which parses command line
arguments (C<@ARGV>) into subroutine arguments (C<%args>). This module is used
by L<Perinci::CmdLine>. For explanation on how command-line options are
processed, see Perinci::CmdLine's documentation.

=head1 FUNCTIONS


=head2 gen_getopt_long_spec_from_meta

Usage:

 gen_getopt_long_spec_from_meta(%args) -> [status, msg, payload, meta]

Generate Getopt::Long spec from Rinci function metadata.

This routine will produce a L<Getopt::Long> specification from Rinci function
metadata, as well as some more data structure in the result metadata to help
producing a command-line help/usage message.

Function arguments will be mapped to command-line options with the same name,
with non-alphanumeric characters changed to C<-> (C<-> is preferred over C<_>
because it lets user avoid pressing Shift on popular keyboards). For example:
C<file_size> becomes C<file-size>, C<file_size.max> becomes C<file-size-max>. If
function argument option name clashes with command-line option or another
existing option, it will be renamed to C<NAME-arg> (or C<NAME-arg2> and so on).
For example: C<help> will become C<help-arg> (if C<common_opts> contains C<help>,
that is).

Each command-line alias (C<cmdline_aliases> property) in the argument
specification will also be added as command-line option, except if it clashes
with an existing option, in which case this function will warn and skip adding
the alias. For more information about C<cmdline_aliases>, see C<Rinci::function>.

For arguments with type of C<bool>, Getopt::Long will by default also
automatically recognize C<--noNAME> or C<--no-NAME> in addition to C<--name>. So
this function will also check those names for clashes.

For arguments with type array of simple scalar, C<--NAME> can be specified more
than once to append to the array.

If C<per_arg_json> setting is active, and argument's schema is not a "required
simple scalar" (e.g. an array, or a nullable string), then C<--NAME-json> will
also be added to let users input undef (through C<--NAME-json null>) or a
non-scalar value (e.g. C<--NAME-json '[1,2,3]'>). If this name conflicts with
another existing option, a warning will be displayed and the option will not be
added.

If C<per_arg_yaml> setting is active, and argument's schema is not a "required
simple scalar" (e.g. an array, or a nullable string), then C<--NAME-yaml> will
also be added to let users input undef (through C<--NAME-yaml '~'>) or a
non-scalar value (e.g. C<--NAME-yaml '[foo, bar]'>). If this name conflicts with
another existing option, a warning will be displayed and the option will not be
added. YAML can express a larger set of values, e.g. binary data, circular
references, etc.

Will produce a hash (Getopt::Long spec), with C<func.specmeta>, C<func.opts>,
C<func.common_opts>, C<func.func_opts> that contain extra information
(C<func.specmeta> is a hash of getopt spec name and a hash of extra information
while C<func.*opts> lists all used option names).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args> => I<hash>

Reference to hash which will store the result.

=item * B<common_opts> => I<hash>

Common options.

A hash where the values are hashes containing these keys: C<getopt> (Getopt::Long
option specification), C<handler> (Getopt::Long handler). Will be passed to
C<get_args_from_argv()>. Example:

 {
     help => {
         getopt  => 'help|h|?',
         handler => sub { ... },
         summary => 'Display help and exit',
     },
     version => {
         getopt  => 'version|v',
         handler => sub { ... },
         summary => 'Display version and exit',
     },
 }

=item * B<ignore_converted_code> => I<bool> (default: 0)

Whether to ignore coderefs converted to string.

Across network through JSON encoding, coderef in metadata (e.g. in
C<cmdline_aliases> property) usually gets converted to string C<CODE>. In some
cases, like for tab completion, this is pretty harmless so you can turn this
option on. For example, in the case of C<cmdline_aliases>, the effect is just
that command-line aliases code are not getting executed, but this is usually
okay.

=item * B<meta>* => I<hash>

Rinci function metadata.

=item * B<meta_is_normalized> => I<bool>

=item * B<per_arg_json> => I<bool> (default: 0)

Whether to add --NAME-json for non-simple arguments.

Will also interpret command-line arguments as JSON if assigned to function
arguments, if arguments' schema is not simple scalar.

=item * B<per_arg_yaml> => I<bool> (default: 0)

Whether to add --NAME-yaml for non-simple arguments.

Will also interpret command-line arguments as YAML if assigned to function
arguments, if arguments' schema is not simple scalar.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_args_from_argv

Usage:

 get_args_from_argv(%args) -> [status, msg, payload, meta]

Get subroutine arguments (%args) from command-line arguments (@ARGV).

Using information in Rinci function metadata's C<args> property, parse command
line arguments C<@argv> into hash C<%args>, suitable for passing into subroutines.

Currently uses L<Getopt::Long>'s C<GetOptions> to do the parsing.

As with GetOptions, this function modifies its C<argv> argument, so you might
want to copy the original C<argv> first (or pass a copy instead) if you want to
preserve the original.

See also: gen_getopt_long_spec_from_meta() which is the routine that generates
the specification.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_extra_elems> => I<bool> (default: 0)

Allow extra/unassigned elements in argv.

If set to 1, then if there are array elements unassigned to one of the
arguments, instead of generating an error, this function will just ignore them.

This option will be passed to Perinci::Sub::GetArgs::Array's allow_extra_elems.

=item * B<args> => I<hash>

Specify input args, with some arguments preset.

=item * B<argv> => I<array[str]>

If not specified, defaults to @ARGV

=item * B<common_opts> => I<hash>

Common options.

A hash where the values are hashes containing these keys: C<getopt> (Getopt::Long
option specification), C<handler> (Getopt::Long handler). Will be passed to
C<get_args_from_argv()>. Example:

 {
     help => {
         getopt  => 'help|h|?',
         handler => sub { ... },
         summary => 'Display help and exit',
     },
     version => {
         getopt  => 'version|v',
         handler => sub { ... },
         summary => 'Display version and exit',
     },
 }

=item * B<ggls_res> => I<array>

Full result from gen_getopt_long_spec_from_meta().

If you already call C<gen_getopt_long_spec_from_meta()>, you can pass the I<full> enveloped result
here, to avoid calculating twice.

=item * B<ignore_converted_code> => I<bool> (default: 0)

Whether to ignore coderefs converted to string.

Across network through JSON encoding, coderef in metadata (e.g. in
C<cmdline_aliases> property) usually gets converted to string C<CODE>. In some
cases, like for tab completion, this is harmless so you can turn this option on.

=item * B<meta>* => I<hash>

=item * B<meta_is_normalized> => I<bool> (default: 0)

Can be set to 1 if your metadata is normalized, to avoid duplicate effort.

=item * B<on_missing_required_args> => I<code>

Execute code when there is missing required args.

This can be used to give a chance to supply argument value from other sources if
not specified by command-line options. Perinci::CmdLine, for example, uses this
hook to supply value from STDIN or file contents (if argument has C<cmdline_src>
specification key set).

This hook will be called for each missing argument. It will be supplied hash
arguments: (arg => $the_missing_argument_name, args =>
$the_resulting_args_so_far, spec => $the_arg_spec).

The hook can return true if it succeeds in making the missing situation
resolved. In this case, this function will not report the argument as missing.

=item * B<per_arg_json> => I<bool> (default: 0)

Whether to recognize --ARGNAME-json.

This is useful for example if you want to specify a value which is not
expressible from the command-line, like 'undef'.

 % script.pl --name-json 'null'

But every other string will need to be quoted:

 % script.pl --name-json '"foo"'

See also: per_arg_yaml. You should enable just one instead of turning on both.

=item * B<per_arg_yaml> => I<bool> (default: 0)

Whether to recognize --ARGNAME-yaml.

This is useful for example if you want to specify a value which is not
expressible from the command-line, like 'undef'.

 % script.pl --name-yaml '~'

See also: per_arg_json. You should enable just one instead of turning on both.

=item * B<strict> => I<bool> (default: 1)

Strict mode.

If set to 0, will still return parsed argv even if there are parsing errors
(reported by Getopt::Long). If set to 1 (the default), will die upon error.

Normally you would want to use strict mode, for more error checking. Setting off
strict is used by, for example, Perinci::Sub::Complete during completion where
the command-line might still be incomplete.

Should probably be named C<ignore_errors>. :-)

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


Error codes:

=over

=item * 400 - Error in Getopt::Long option specification, e.g. in common_opts.

=item * 500 - failure in GetOptions, meaning argv is not valid according to metadata
specification (only if 'strict' mode is enabled).

=item * 501 - coderef in cmdline_aliases got converted into a string, probably because
the metadata was transported (e.g. through Riap::HTTP/Riap::Simple).

=back

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-GetArgs-Argv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-GetArgs-Argv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-GetArgs-Argv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
