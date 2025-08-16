package Net::Respite::Base;

# Net::Respite::Base - base class for Respite related modules that can be used from a server or commandline

use strict;
use warnings;
use base 'Net::Respite::Common'; # Default _configs
use autouse 'Net::Respite::Validate' => qw(validate);
use Scalar::Util qw(blessed weaken);
use Time::HiRes ();
use Throw qw(throw);

our $max_recurse = 10;

sub SHARE {}

sub config {
    my ($self, $key, $def, $name) = @_;
    $name ||= (my $n = $self->base_class || ref($self) || $self || '') =~ /(\w+)$/ ? lc $1 : '';
    my $c = $self->_configs($name);
    return exists($self->{$key}) ? $self->{$key}
        : exists($c->{"${name}_service_${key}"}) ? $c->{"${name}_service_${key}"}
        : (ref($c->{"${name}_service"}) && exists $c->{"${name}_service"}->{$key}) ? $c->{"${name}_service"}->{$key}
        : exists($c->{"${name}_${key}"}) ? $c->{"${name}_${key}"}
        : (ref($c->{$name}) && exists $c->{$name}->{$key}) ? $c->{$name}->{$key}
        : ref($def) eq 'CODE' ? $def->($self) : $def;
}

###----------------------------------------------------------------###

sub run_method {
    my ($self, $meth, $args, $extra) = @_;
    my $meta = $self->api_meta || {};
    my $begin = $meta->{'log_prefix'} ? Time::HiRes::time() : undef;
    $meth =~ tr|/.-|___|;
    throw "Cannot call method", {class => ref($self), meth => $meth} if $self->_restrict($meth);
    my $code = $self->find_method($meth) || throw "Invalid Respite method", {class => ref($self), method => $meth};
    my $utf8 = $meta->{'utf8_encoded'};
    my $enc  = $utf8 && (!ref($utf8) || $utf8->{$meth});
    my $trp  = $self->{'transport'} || '';
    if ($enc) { # consistently handle args from json, form, or commandline
        _encode_utf8_recurse($args) if $trp eq 'json';
    } else {
        _decode_utf8_recurse($args) if $trp && $trp ne 'json';
    }
    my $resp = eval { $self->$code($args, $extra) } || do {
        my $resp = $@;
        $resp = eval { throw 'Trouble dispatching', {method => $meth, msg => $resp} } || $@ if !ref($resp) || !$resp->{'error'};
        warn $resp if $trp ne 'cmdline';
        $resp;
    };
    $self->log_request({
        method      => $meth,
        request     => $args,
        response    => $resp,
        api_ip      => $self->{'api_ip'},
        api_brand   => $self->{'api_brand'},
        remote_ip   => $self->{'remote_ip'},
        remote_user => $self->{'remote_user'},
        admin_user  => $self->{'admin_user'},
        caller      => $self->{'caller'},
        elapsed     => (Time::HiRes::time() - $begin),
    }) if $begin;
    _decode_utf8_recurse($resp) if ref($resp) eq 'HASH' && exists($resp->{'_utf8_encoded'}) ? delete($resp->{'_utf8_encoded'}) : $enc;
    return $resp;
}

sub _restrict {
    my ($class, $meth) = @_;
    return 0 if __PACKAGE__->SUPER::can($meth); # any of the inherited methods from Net::Respite::Base are not Respite methods
    return $meth =~ /^_/;
}

sub AUTOLOAD {
    my $self = shift;
    my $meth = $Net::Respite::Base::AUTOLOAD =~ /::(\w+)$/ ? $1 : throw "Invalid method", {method => $Net::Respite::Base::AUTOLOAD};
    throw "Self was not passed while looking up method", {method => $meth, trace => 1} if ! blessed $self;
    local $self->{'_autoload'}->{$meth} = ($self->{'_autoload'}->{$meth} || 0) + 1;
    throw "Recursive method lookup", {class => ref($self), method => $meth} if $self->{'_autoload'}->{$meth} > $max_recurse;
    my $code = $self->find_method($meth) || throw "Invalid Respite method during AUTOLOAD", {class => ref($self), method => $meth}, 1;
    return $self->$code(@_);
}

sub DESTROY {}

sub api_meta {
    my $self = shift;
    my $ref  = ref $self;
    no strict 'refs'; ## no critic
    return ${"${ref}::api_meta"} if ${"${ref}::api_meta"};
    return $self->{'api_meta'} ||= ($ref eq __PACKAGE__ ? throw "No api_meta defined", {class => $self, type => 'no_meta'} : {});
}

sub api_preload { shift->find_method; return 1 }

sub _encode_utf8_recurse {
    my $d = shift;
    if (UNIVERSAL::isa($d, 'HASH')) {
        for my $k (keys %$d) { my $v = $d->{$k}; (ref $v) ? _encode_utf8_recurse($v) : $v and utf8::is_utf8($v) and utf8::encode($d->{$k}) }
    } elsif (UNIVERSAL::isa($d, 'ARRAY')) {
        for my $v (@$d) { (ref $v) ? _encode_utf8_recurse($v) : $v and utf8::is_utf8($v) and utf8::encode($v) }
    }
}

sub _decode_utf8_recurse {
    my $d = shift;
    my $seen = shift || {};
    return if $seen->{$d}++;
    if (UNIVERSAL::isa($d, 'HASH')) {
        for my $k (keys %$d) { my $v = $d->{$k}; (ref $v) ? _decode_utf8_recurse($v, $seen) : $v and !utf8::is_utf8($v) and utf8::decode($d->{$k}) }
    } elsif (UNIVERSAL::isa($d, 'ARRAY')) {
        for my $v (@$d) { (ref $v) ? _decode_utf8_recurse($v, $seen) : $v and !utf8::is_utf8($v) and utf8::decode($v) }
    }
}

###----------------------------------------------------------------###

sub validate_args {
    my ($self, $args, $val_hash) = @_;
    my $sub = (caller(my $n = 1))[3];  $sub = (caller ++$n)[3] while $sub eq '(eval)' || $sub =~ /::validate_args$/;
    if (! $val_hash) {
        my $code = $self->can("${sub}__meta") or throw "Could not find meta information.", {method => $sub}, 1;
        my $meta = $code->($self);
        $val_hash = $meta->{'args'} || throw "Missing args in meta information", {method => $sub}, 1;
        if (my $ra = $meta->{'requires_admin'} and (eval { $self->api_meta->{'enforce_requires_admin'} } || do { my $e = $@; die $e if $e && (!ref($e) || $e->{'type'} ne 'no_meta'); 0 })) {
            $self->require_admin(ref($ra) eq 'CODE' ? $ra->($self, $sub, $args) : ref($ra) eq 'HASH' ? $ra : {$ra => 1, method => $sub});
        }
    }
    my $error_hash = validate($args || {}, $val_hash) || return 1;
    throw "Failed to validate args", {
        errors => $error_hash,
        type   => 'validation',
        ($args->{'_no_trace'} ? () : (trace => 1)),
    }, 1;
}

sub api_ip {      $_[0]->{'api_ip'}      || ($_[0]->{'base'} ? $_[0]->{'base'}->api_ip      : throw "Missing api_ip",0,1) }
sub api_brand {   $_[0]->{'api_brand'}   || ($_[0]->{'base'} ? $_[0]->{'base'}->api_brand   : ($_[0]->is_local && $ENV{'PROV'}) || throw "Missing api_brand",0,1) }
sub remote_ip {   $_[0]->{'remote_ip'}   || ($_[0]->{'base'} ? $_[0]->{'base'}->remote_ip   : throw "Missing remote_ip",0,1) }
sub remote_user { $_[0]->{'remote_user'} || ($_[0]->{'base'} ? $_[0]->{'base'}->remote_user : throw "Missing remote_user",0,1) }

sub admin_user {  $_[0]->{'admin_user'}  || ($_[0]->{'base'} ? $_[0]->{'base'}->admin_user  : throw "Not authenticated",0,1) }

sub transport {   $_[0]->{'transport'}   || ($_[0]->{'base'} ? $_[0]->{'base'}->transport   : '') }
sub is_server {  exists($_[0]->{'is_server'}) ? $_[0]->{'is_server'} : ($_[0]->{'base'} && $_[0]->{'base'}->is_server) }

sub is_authed { eval { shift->admin_user } ? 1 : 0 }

sub is_local { $_[0]->transport =~ /^(?:cmdline|gui)$/ ? 1 : 0 }
sub who { shift->remote_user }

sub base {
    my $self = shift;
    if (! $self->{'base'}) {
	throw "Could not find base when called_from_base",0,1 if $self->{'called_from_base'};
	my $class = $self->base_class || throw "Could not find a base_class when accessing base from direct source",0,1;
        return $self if ref($self) eq $class;
	(my $file = "$class.pm") =~ s|::|/|g;
	eval { require $file } || throw "Could not load base_class", {msg => $@, class => $class};
	$self->{'base'} = $class->new({$self->SHARE, map {$_ => $self->{$_}} qw(api_ip api_brand remote_ip remote_user admin_user is_server)});
    }
    return $self->{'base'};
}

sub base_class { shift->{'base_class'} }

###----------------------------------------------------------------###

sub find_method {
    my ($self, $meth, $opt) = @_;
    my $meta = $self->api_meta || {};

    my $cache = $meta->{'_cache'}->{ref($self)} ||= {%{ $meta->{'methods'} || {} }};
    if ($meth) {
        return $cache->{$meth} if exists $cache->{$meth};
        return $cache->{$meth} if exists $cache->{$meth};
        my $code;
        return $cache->{$meth} = $code if $code = $self->can($meth) and $code ne \&{__PACKAGE__."::$meth"};
        return $cache->{$meth} = $code if $code = $self->can("__$meth");
    } elsif (!$cache->{'--load--'}->{'builtin'}++) {
        no strict 'refs'; ## no critic
        my @search = ref($self);
        while (my $pkg = shift @search) {
            unshift @search, @{"${pkg}::ISA"} if $pkg ne __PACKAGE__;
            for my $meth (keys %{"${pkg}::"}) {
                next if ! defined &{"${pkg}::$meth"};
                next if ($pkg eq __PACKAGE__) ? $meth !~ /^__/ : defined &{__PACKAGE__."::$meth"};
                next if $pkg =~ /^_[a-z]/;
                next if $meth !~ /__meta$/ && $meth !~ /^__/ && !defined &{"${pkg}::${meth}__meta"};
                (my $name = $meth) =~ s/^__//;
                $cache->{$name} ||= "${pkg}::$meth";
            }
        }
    }

    foreach my $type ('namespaces', 'lib_dirs') {
        my $NS = $meta->{$type} || next;
        $NS = $cache->{'--load--'}->{'lib_dirs'} ||= $self->_load_lib_dir($NS) if $type eq 'lib_dirs';
        foreach my $ns (sort keys %$NS) {
            my $opt = $NS->{$ns};
            $opt = {match => $opt} if ref($opt) ne 'HASH';
            my $name = !$meth ? undef : ($meth !~ /^${ns}_*(\w+)$/) ? next : $opt->{'full_name'} ? $meth : $1;
            my $pkg = $opt->{'pkg'} || $opt->{'package'} || do { (my $pkg = $ns) =~ s/(?:_|\b)([a-z])/\u$1/g; $pkg };
            if (! $pkg->can('new')) {
                (my $file = "$pkg.pm") =~ s|::|/|g;
                if (! eval { require ($opt->{'file'} ||= $file) }) {
                    warn "Failed to load listed module $pkg ($opt->{'file'}): $@";
                    next;
                }
                $INC{$file} = $INC{$opt->{'file'}} if $opt->{'file'} ne $file;
            }

            # TODO - faster lookup if we know the method
            my $qr = $opt->{'match'} || 1;
            $qr = ($qr eq '1' || $qr eq '*') ? qr{.} : qr{^$qr} if $qr && !ref $qr;
            no strict 'refs'; ## no critic
            for my $meth (keys %{"${pkg}::"}) {
                next if ! defined &{"${pkg}::$meth"};
                next if ($pkg eq __PACKAGE__) ? $meth !~ /^__/ : defined &{__PACKAGE__."::$meth"};
                next if $meth =~ /^_[a-z]/;
                next if $qr && $meth !~ $qr;
                next if $meth !~ /__meta$/ && $meth !~ /^__/ && !defined &{"${pkg}::${meth}__meta"};
                (my $name = $meth) =~ s/^__//;
                $name = "${ns}_${name}" if !$opt->{'full_name'} && $name !~ /^\Q$ns\E_/;
                my $dt = $opt->{'dispatch_type'} || $meta->{'dispatch_type'} || 'new';
                $cache->{$name} ||= ($dt eq 'new') ? sub { my $base = shift; $pkg->new({base => $base, called_from_base => 1, $base->SHARE})->$meth(@_) }
                    : ($dt eq 'morph') ? sub {
                        my $base = shift;
                        my $prev = ref $base;
                        local $base->{'base'} = $base->{'base'} || $base; weaken($base->{'base'});
                        my $resp; my $ok = eval { bless $base, $pkg; $resp = $base->$meth(@_); 1 }; my $err = $@; bless $base, $prev; die $err if ! $ok; return $resp;
                      }
                    : ($dt eq 'cache') ? sub { my $base = shift; ($base->{$pkg} ||= do { my $s = $pkg->new({base => $base, $base->SHARE}); weaken $s->{'base'}; $s })->$meth(@_) }
                    : throw "Unknown dispatch_type", {dispatch_type => $dt}, 1;
            }
            if (($meta->{'allow_nested'} || $opt->{'allow_nested'}) && defined(&{"${pkg}::api_meta"}) && $pkg->can('find_method')) {
                my $c2 = $pkg->new({$self->SHARE})->find_method; # TODO - pass them in
                for my $meth (keys %$c2) {
                    next if $qr && $meth !~ $qr;
                    $name = (!$opt->{'full_name'} && $meth !~ /^\Q$ns\E_/) ? "${ns}_${meth}" : $meth;
                    $cache->{$name} = $c2->{$meth};
                }
            }
            return $cache->{$meth} if $meth && $cache->{$meth};
        }
    }

    return $cache->{$meth} = 0 if $meth;
    return $cache;
}

sub _load_lib_dir {
    my ($self, $NS) = @_;
    if ($NS eq '1') {
        throw "lib_dirs cannot be 1 when accessed from Net::Respite::Base directly" if ref($self) eq __PACKAGE__;
        (my $file = ref($self).".pm") =~ s|::|/|g;
        (my $dir = $INC{$file} || '') =~ s|\.pm$|| or throw "Could not determine library path location for lib_dirs", {file => $file};
        $NS = {$dir => {pkg_prefix => ref($self)}};
    }
    my %h;
    foreach my $dir (keys %$NS) {
        opendir my $dh, $dir or do { warn "Failed to opendir $dir: $!"; next };
        my $opt = $NS->{$dir};
        $opt = {match => $opt} if ref($opt) ne 'HASH';
        my $prefix = $opt->{'pkg_prefix'} ? "$opt->{'pkg_prefix'}::" : '';
        foreach my $sub (readdir $dh) {
            next if $sub !~ /^([a-zA-Z]\w*)\.pm$/; # TODO - possibly handle dirs
            my $pkg = $1;
            next if $opt->{'pkg_exclude'} && $pkg =~ $opt->{'pkg_exclude'};
            (my $name = $pkg) =~ s/(?: (?<=[a-z])(?=[A-Z]) | (?<=[A-Z])(?=[A-Z][a-z]) )/_/xg; # FooBar => Foo_Bar, RespiteUser => Respite_User
            $h{lc $name} = {%$opt, pkg => "$prefix$pkg", file => "$dir/$sub"};
        }
    }
    return \%h;
}

###----------------------------------------------------------------###

sub __methods__meta {
    my $class = ref($_[0]) || $_[0];
    return {
        desc => "Return a list of all known $class methods.  Optionally return all meta information as well",
        args => {
            meta   => {desc => 'If true, returns all meta information for the method instead of just the description'},
            method => {desc => 'If passed will be used to filter the available methods - can contain * as a wildcard'},
        },
        resp => {methods => 'hashref of available method/description pairs. Will return method/metainfo pairs if meta => 1 is passed.'},
    };
}

sub __methods {
    my ($self, $args) = @_;
    no strict 'refs'; ## no critic
    my $pkg  = ref($self) || $self;
    my %m;
    my $qr = !$args->{'method'} ? undef : do { (my $p = $args->{'method'}) =~ s/\*/.*/g; qr/^$p$/i };
    my $meths = $self->find_method(); # will load all
    foreach my $meth (keys %$meths) {
        next if $meth !~ /^(\w+)__meta$/;
        my $name = $1;
        next if $qr && $name !~ $qr;
        my $meta = eval { $self->$meth() } || do { (my $err = $@ || '') =~ s/ at \/.*//s; {desc => "Not documented".($err ? ": $err" : '')} };
        next if $ENV{'REQUEST_METHOD'} && $meta->{'no_listing'};
        $m{$name} = $args->{'meta'} ? $meta : $meta->{'no_listing'} ? "(Not listed in Web Respite) $meta->{'desc'}" : $meta->{'desc'};
        delete $meta->{'api_enum'};
    }
    return {methods => \%m};
}

sub __hello__meta {
    return {
        desc => 'Basic call to test connection',
        args => {test_auth => {validate_if => 'test_auth', enum => ['', 0, 1], desc => 'Optional - if passed it will require authentication'}},
        resp => {
            server_time => "Server epoch time",
            args        => "Echo of the passed in args",
            api_ip      => 'IP',
            api_brand   => 'Which brand is in use (if any)',
            admin_user  => 'Returned if test_auth is passed',
        },
    };
}

sub __hello {
    my ($self, $args) = @_;
    sleep $args->{'sleep'} if $args->{'sleep'};
    throw delete($args->{'fail'}), {args => $args} if $args->{'fail'};
    return {
        args        => $args,
        server_time => time(),
        api_ip      => $self->api_ip,
        api_brand   => eval { $self->api_brand } || undef,
        ($args->{'test_auth'} && $self->require_admin ? (
             admin_user => $self->admin_user,
             token => $self->{'new_token'},
        ) : ()),
    };
}

1;
