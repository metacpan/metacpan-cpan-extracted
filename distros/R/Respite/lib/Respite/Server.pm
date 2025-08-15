package Respite::Server;

# Respite::Server - generic Respite based Respite server

use strict;
use warnings;
our @ISA;
use base 'Respite::Common'; # Default _configs
use Digest::MD5 qw(md5_hex);
use Throw qw(throw);
use Time::HiRes qw(sleep);

sub server_name {      $_[0]->{'server_name'}      ||= ($0 =~ m|/(\w+)$|x) ? $1 : throw 'Missing server_name' }
sub revision {         $_[0]->{'revision'}         ||= eval { $_[0]->dispatch_class->_revision } || '-' }
sub max_request_size { $_[0]->{'max_request_size'} || 2_000_000 }
sub api_meta { shift->{'api_meta'} }
sub dispatch_class { shift->{'dispatch_class'} }

###----------------------------------------------------------------###

sub new {
    my $class = shift;
    my $self = bless ref($_[0]) ? shift : {@_}, $class;
    %$self = (%$_, %$self) if $_ = $self->new_args;
    return $self if $self->{'non_daemon'} || ($ENV{'MOD_PERL'} && ! $self->{'force_daemon'});
    require Net::Server;
    require Net::Server::HTTP;
    unshift @ISA, qw(Net::Server::HTTP) if !$self->isa(qw(Net::Server::HTTP));;
    throw 'We need a more recent Net::Server revision', {v => $Net::Server::VERSION} if $Net::Server::VERSION < 2.007;
    $self->json; # vivify before fork
    my $server = $class->SUPER::new(%$self, %{ $self->server_args });
    @$server{keys %$self} = values %$self; # TODO - avoid duplicates
    $self->dispatch_factory('preload') if !$ENV{'NO_PRELOAD'}; # void call will load necessary classes

    return $server;
}

sub new_args {}

sub config {
    my ($self, $key, $def, $name) = @_;
    $name ||= $self->server_name;
    my $c = $self->_configs($name);
    return exists($self->{$key}) ? $self->{$key}
        : exists($c->{"${name}_${key}"}) ? $c->{"${name}_${key}"}
        : (ref($c->{$name}) && exists $c->{$name}->{$key}) ? $c->{$name}->{$key}
        : ref($def) eq 'CODE' ? $def->($self) : $def;
}

sub dispatch_factory {
    my ($self, $preload) = @_;
    return $self->{'dispatch_factory'} ||= do {
        my $meta = $self->api_meta || $self->dispatch_class || throw "Missing one of api_meta or dispatch_class";
        if (!ref $meta) {
            (my $file = "$meta.pm") =~ s|::|/|g;
            throw "Failed to load dispatch class", {class => $meta, file => $file, msg => $@} if !$meta->can('new') && !eval { require $file };
            throw "Specified class does not have a run_method method", {class => $meta} if ! $meta->can('run_method');
            sub { $meta->new(@_) };
        } else {
            require Respite::Base;
            Respite::Base->new({api_meta => $meta})->api_preload if $preload;
            sub { Respite::Base->new({%{shift()}, api_meta => $meta}) };
        }
    };
}

###----------------------------------------------------------------###
# request handling and method dispatching

# mod_perl handler - used via apache conf
# <Location /foo/>
#   SetHandler modperl
#   PerlResponseHandler FooServer
# </Location>
# sub handler { __PACKAGE__->modperlhandler(@_) }
sub modperlhandler {
    my $class = shift;
    my $r = shift || throw "Missing apache request during ${class}::modperlhandler", {trace => 1};
    my $self = $class->new({apache_req => $r, non_daemon => 1});
    my %env = %ENV;
    if (eval { $self->modperl_init($r); $r->subprocess_env(); 1 }) {
        $self->cgihandler();
    } else {
        warn my $err = $self->json->encode({error => "$@", type => 'mod_perl_header'});
        $self->send_response($err);
    }
    %ENV = %env;
    return 0; # OK - TODO - we actually may want a 403 for digest errors
}

my $modperl_init;
sub modperl_init {
    return if $modperl_init;
    $modperl_init = 1;
    require Apache2::RequestRec;
    require Apache2::RequestIO;
    require APR::Table;
}

# normal cgi-bin or Net::Server::HTTP handler
# Net::Server::HTTP app => \&cgihandler
# cgi-bin/server  App::cgihandler() or App->new->cgihandler or App->cgihandler
sub cgihandler {
    my $self = shift;
    $self = ($self || __PACKAGE__)->new({%{shift() || {}}, non_daemon => 1}) if ! $self || ! ref($self);
    local $self->{'transport'};
    local $self->{'extra_headers'};
    local $self->{'cgi_obj'};

    my $req_sum;
    my $args = eval {
        my $r = $self->{'apache_req'};
        my $req;
        if ($ENV{'CONTENT_TYPE'} && $ENV{'CONTENT_TYPE'} =~ /\bjson\b/) {
            throw 'JSON data may not be submitted via GET' if !$ENV{'REQUEST_METHOD'} || $ENV{'REQUEST_METHOD'} eq 'GET' || $ENV{'REQUEST_METHOD'} eq 'HEAD';
            my $len = $ENV{'CONTENT_LENGTH'} || throw "Missing CONTENT_LENGTH on $ENV{'REQUEST_METHOD'} request", {len => $ENV{'CONTENT_LENGTH'}};
            throw "Too large a $ENV{'REQUEST_METHOD'} request found", {length => $len, max => $self->max_request_size} if $len > $self->max_request_size;
            my $size = 0;
            while (1) {
                $r ? $r->read($req, $len - $size, $size) : read(STDIN, $req, $len - $size, $size);
                throw "Failed to read bytes", {needed => $len, got => $size} if length($req) == $size;
                last if ($size = length $req) >= $len;
            }
            throw "Failed to read entire $ENV{'REQUEST_METHOD'} request", {length => $len, actual => length($req)} if length($req) != $len;
        } else {
            my $args = $self->parse_form($r);
            $req = delete $args->{'POSTDATA'}; # CGI.pm - non-form POST
            if (!$req) { # get
                $self->{'transport'} = 'form';
                $args = Data::URIEncode::flat_to_complex($args) || {} if !$self->{'no_data_uriencode'} && (eval { require Data::URIEncode } || ((grep {$_ =~ /[:.]/} keys %$args) && throw "Failed to load Data::URIEncode", {msg => $@}));
                return $args;
            }
            throw "Found other args in addition to POSTDATA", {args => $args} if scalar keys %$args;
        }
        $self->{'transport'} = 'json';
        throw "Content data did not look like JSON hash", {head => substr($req, 0, 10)."...", content_type => $ENV{'CONTENT_TYPE'}} if $req !~ /^\{/;
        $req_sum = md5_hex($req);
        return eval { $self->json->decode($req) }
            || throw 'Trouble unencoding json', {ip => $ENV{'REMOTE_ADDR'}, msg => $@, head => substr($req, 0, 10)."..."};
    };
    if (! $args) {
        my $err = $self->json->encode({error => "$@", type => 'cgihandler'});
        warn $err;
        return $self->send_response($err);
    }
    $ENV{'PATH_INFO'} ||= '';

    my ($old_out, $out_ref) = $self->{'warn_on_stdout'} ? do { open my $fh, ">", \(my $str =""); (select($fh), \$str) } : ();
    local $self->{'_warn_info'};
    my $ref = eval { $self->_do_request($args, $req_sum, \%ENV) };
    if (! $ref) {
        $ref = $@;
        $ref = eval { throw 'Trouble dispatching', {path => $ENV{'PATH_INFO'}, msg => $ref} } || $@ if !ref($ref) || !$ref->{'error'};
        local @$ref{keys %$_} = values %$_ if $_ = $self->{'_warn_info'};
        warn $ref;
    }
    if ($old_out) {
        select $old_out;
        warn "--- INVALID STDOUT ---\n$$out_ref\n" if $$out_ref;
    }

    if (ref($ref) eq 'ARRAY' && @$ref == 3 && $ref->[0] =~ /^\d+$/) {
        return $ref if $self->{'is_psgi'};
        require Net::Server::PSGI;
        $self->Net::Server::PSGI::print_psgi_headers($ref->[0], $ref->[1]);
        $self->Net::Server::PSGI::print_psgi_body($ref->[2]);
        return 1;
    }

    $self->{'extra_headers'} = delete $ref->{'_extra_headers'} if $ref->{'_extra_headers'};
    my $out = eval { $self->json->encode($ref) } || do { warn "Trouble encoding json: $@"; "{'error':'Trouble encoding json - check server logs for details'}" };
    return $self->send_response($out);
}

sub _do_request {
    my ($self, $args, $req_sum, $env) = @_;
    my ($method, $brand, $extra) = $self->_map_request($args, $env);
    my $ver = $self->verify_sig($args, $req_sum, $env, $method, $brand);

    $self->{'_warn_info'} = {caller => {who => $args->{'_w'}, source => $args->{'_c'}, method => $method, brand => $brand, ip => $env->{'REMOTE_ADDR'}}};
    local $env->{'REMOTE_USER'};
    my $disp = $self->dispatch_factory->({
        %{ $extra || {} },
        is_server   => $self->server_name,
        ($env->{'HTTP_X_FORWARDED_FOR'}
         ? (api_ip  => $env->{'HTTP_X_FORWARDED_FOR'}, is_proxy => $env->{'REMOTE_ADDR'})
         : (api_ip  => $env->{'REMOTE_ADDR'})),
        api_auth    => $ver,
        api_brand   => $brand,
        api_method  => $method,
        remote_user => delete($args->{'_w'}),
        remote_ip   => delete($args->{'_i'}),
        token       => delete($args->{'_t'}) || do { my $k = $self->config('admin_cookie_key'); $k ? $self->parse_cookies->{$k} : '' },
        caller      => delete($args->{'_c'}),
        dbh_cache   => $self->_dbh_cache,
        transport   => $self->{'transport'},
    });
    $disp->server_init($method, $args, $self) if $disp->can('server_init');

    local $0 = "$0 ".$self->server_name." $method - $env->{'REMOTE_ADDR'}";
    return $disp->run_method($method, $args) if !$disp->can('server_post_request');

    my $ref;
    my $ok = eval { $ref = $disp->run_method($method, $args); 1 };
    my $err = $@;
    $disp->server_post_request($method, $args, $ok, $ref, $err);
    return $ref if $ok;
    die $err;
}

sub _map_request {
    my ($self, $args, $env) = @_;
    my $no_brand = $self->_no_brand;
    my ($meth, $brand) = ((!$no_brand || $no_brand < 0) && $env->{'PATH_INFO'} =~ m|^/+(.+)/([^/]+)$|) ? ($1, $2)
                       : ($env->{'PATH_INFO'} =~ m|^/+(.+)$|) ? ($1, $no_brand ? undef : throw "Failed to find brand with method", {uri => "/$1"})
                       : throw "Failed to find method in URI", {uri => $env->{'PATH_INFO'}};
    delete @$args{qw(_p _b)}; # legacy brand and password passing
    return ($meth, $brand);
}

sub _dbh_cache { {} } # intentionally not persistent

sub cgi_obj {
    my ($self, $r) = @_;
    return $self->{'cgi_obj'} ||= do {
        eval { CGI::initialize_globals() } or warn "Failed to initialize globals: $@" if $INC{'CGI.pm'}; # CGI.pm caches query parameters
        eval { $self->{'is_psgi'} ? require CGI::PSGI : require CGI } || throw 'Cannot load CGI library during a non-JSON request', {msg => $@, type => $ENV{'CONTENT_TYPE'}};
        local $CGI::POST_MAX = $self->max_request_size;
        my $q = $self->{'is_psgi'} ? CGI::PSGI->new($self->{'is_psgi'}) : CGI->new($r || $self->{'apache_req'} || ());
    };
}

sub parse_form {
    my ($self, $r) = @_;
    my $q = $self->cgi_obj($r);
    return {map {my @v = $q->param($_); $_ => (@v <= 1 ? $v[0] : \@v)} $q->param};
}

sub parse_cookies {
    my ($self, $r) = @_;
    my $env = $self->{'is_psgi'} || \%ENV;
    return {} if !$env->{'HTTP_COOKIE'};
    my $q = $self->cgi_obj($r);
    return {map {my @v = $q->cookie($_); $_ => (@v <= 1 ? $v[0] : \@v)} $q->cookie};
}

sub content_type { shift->{'content_type'} ||= 'application/json' }

sub send_response {
    my ($self, $str) = @_;
    $str =~ s/\s*$/\r\n/ if $self->content_type =~ m{^(?:text/|application/json$)};
    my @extra = $self->{'extra_headers'} ? @{ $self->{'extra_headers'} } : ();
    if ($self->{'is_psgi'}) {
        return [200, [(map {$_->[0], $_->[1]} @extra), 'Content-type' => $self->content_type, 'Content-length' => length($str)], [$str]];
    } elsif (my $r = $self->{'apache_req'} || eval { $ENV{'MOD_PERL'} && Apache2::RequestUtil->request }) {
        $r->headers_out->set($_->[0] => $_->[1]) for @extra;
        $r->headers_out->set('Content-length', length($str));
        $r->content_type($self->content_type);
        $r->print($str);
    } elsif (my $c = $self->{'server'}->{'client'}) { # accelerate output header generation under Net::Server
        my $ri = $self->{'request_info'};
        my $out = "HTTP/1.0 200 OK\015\012";
        foreach my $row (@{ $self->http_base_headers }, @extra, ['Content-length', length($str)], ['Content-type', $self->content_type]) {
            $out .= "$row->[0]: $row->[1]\015\012";
            push @{ $ri->{'response_headers'} }, $row;
        }
        $ri->{'response_header_size'} += length $out;
        $ri->{'http_version'} = '1.0';
        $ri->{'response_status'} = 200;
        $ri->{'headers_sent'} = 1;
        $ri->{'response_size'} = length $str;
        $c->print("$out\015\012$str");
    } else {
        # Otherwise, this is a normal CGI process.
        # XXX - Do we need to also convert "Status" header for the special NPH format?
        print "HTTP/1.0 200 OK\r\n" if ($ENV{SCRIPT_FILENAME} // "") =~ m{/nph-[^/]+($|\s)};
        for my $h (@extra) {
            print "$h->[0]: $h->[1]\r\n";
        }
        print "Content-Type: ".$self->content_type."\r\nContent-Length: ".length($str)."\r\nContent-Type: ".$self->content_type."\r\n\r\n",$str;
    }
    return 1;
}

sub _no_brand { shift->config(no_brand => undef) }

sub verify_sig {
    my ($self, $args, $req_sum, $env, $meth, $brand) = @_;
    my ($ip, $sig, $script, $path_info, $qs, $auth) = @$env{qw(REMOTE_ADDR HTTP_X_RESPITE_AUTH SCRIPT_NAME PATH_INFO QUERY_STRING HTTP_AUTHORIZATION)};
    my $uri = $script || throw "Missing script";
    $uri .= $path_info if $path_info;
    $uri .= "?$qs" if $qs;

    my ($type, $user, $exception);
    if ($auth) {
        throw "Cannot pass both Authorization and X-Respite-Auth", {authorization => $auth, x_respite_auth => $sig, uri => $uri, ip => $ip} if $sig;
        if ($auth =~ s/^Basic \s+ (\S+)$/$1/x) {
            $type = 'basic';
            require MIME::Base64;
            ($user, $sig) = split /:/, MIME::Base64::decode_base64($auth), 2;
            $exception = Throw->new("Basic authentication not allowed", {user => $user}) if ! $self->allow_auth_basic($brand, $user);
        } elsif ($auth =~ s/^Digest \s+//x) {
            $type = 'digest';
            $sig->{'method'} = $ENV{'REQUEST_METHOD'};
            $sig->{$1} = (defined($3) && length($3)) ? $3 : $2 while $auth =~ s/^ (\w+) = (?: "([^\"]+)" | ([^\s\",]+)) (?:\s*$|,\s*) //gxs;
            $user = $sig->{'username'};
        } elsif ($auth =~ s/^RespiteAuth \s+//x) {
            $type = 'signed';
            $sig = $auth;
        } else {
            $exception = Throw->new("Unknown auth type", {authorization => $auth, uri => $uri, ip => $ip, authtype => 'unknown'});
        }
    } else {
        my $allow_md5 = $self->allow_auth_md5_pass($brand);
        $sig ||= $args->{'x_respite_auth'} if $allow_md5;
        $type = !$sig ? 'none' : ($sig !~ /^[a-f0-z]{32}$/) ? 'signed' : $allow_md5 ? 'md5_pass' : throw 'Auth type md5_pass not allowed';
    }
    my $pass = $self->get_api_pass($brand || '', $ip, $sig, $type, $user, $exception) || [];
    $pass = ref($pass) ? undef : [$pass] if ref($pass) ne 'ARRAY';
    return {authorization_not_required => 1, ip => $ip, brand => $brand, authtype => $type, exception => $exception} if $pass && !@$pass;
    die $exception if defined $exception;
    throw "Missing client authorization", {server_name => $self->server_name, ip => $ip, brand => $brand, authtype => $type, uri => $uri} if !$sig && $type && $type ne 'none';

    if ($pass) {
        for my $i (0 .. $#$pass) {
            next if ($type eq 'basic') ? $pass->[$i] ne $sig
                : ($type eq 'md5_pass') ? md5_hex($pass->[$i]) ne $sig
                : ($type eq 'signed') ? do { my ($_sum, $time) = split /:/, $sig, 2; md5_hex("$pass->[$i]:$time:$uri:$req_sum") ne $_sum }
                : ($type eq 'digest') ? (eval { $self->verify_digest($sig||={}, $pass->[$i], $uri, $req_sum, $meth, $brand, $ip) } ? 0 : do { $sig->{'verify'} = $@; 1 })
                : 1;
            return {authtype => $type, ip => $ip, brand => $brand, meth => $meth, i => $i, ($self->{'verify_sig_return_pass'} ? (pass => $pass->[$i]) : ()), ($type eq 'digest'?(digest=>$sig):())};
        }
    }
    throw "Invalid client authorization", {($type eq 'digest'?(digest=>$sig):()), server_name => $self->server_name, ip => $ip, brand => $brand, authtype => $type, uri => $uri};
}

my %cidr;
sub get_api_pass {
    my ($self, $brand, $ip, $sig, $type, $user, $except) = @_;
    my $ref = $self->config(pass => undef);
    return $ref if ! ref($ref) || ref($ref) eq 'ARRAY';
    if (exists $ref->{$ip}) {
        return $ref->{$ip} if ref($ref->{$ip}) ne 'HASH';
        return $ref->{$ip}->{$brand} if exists $ref->{$ip}->{$brand};
        return $ref->{$ip}->{'~default~'} if exists $ref->{$ip}->{'~default~'};
        return $ref->{$ip}->{'-default'} if exists $ref->{$ip}->{'-default'};
    } elsif (exists $ref->{$brand}) {
        return $ref->{$brand} if ref($ref->{$brand}) ne 'HASH';
        return $ref->{$brand}->{$ip} if exists $ref->{$brand}->{$ip};
        return $ref->{$brand}->{'~default~'} if exists $ref->{$brand}->{'~default~'};
        return $ref->{$brand}->{'-default'} if exists $ref->{$brand}->{'-default'};
    } elsif (my $c = $ref->{'~cidr~'} || $ref->{'-cidr'}) {
        my $n = _aton($ip);
        foreach my $cidr (keys %$c) {
            my $range = $cidr{$cidr} ||= _cidr($cidr);
            next if $n < $range->[0] || $n > $range->[1];
            my $ref = $c->{$cidr};
            if (ref($ref) eq 'HASH') {
                return $ref->{$brand} if exists $ref->{$brand};
                return $ref->{'~default~'} if exists $ref->{'~default~'};
                return $ref->{'-default'} if exists $ref->{'-default'};
            }
            return $ref;
        }
    }

    return $ref->{'~default~'} if exists $ref->{'~default~'};
    return $ref->{'-default'} if exists $ref->{'-default'};
    throw "Not authorized - Could not find brand/ip match in pass configuration", {brand => $brand, ip => $ip, service => $self->server_name};
}
sub _aton { my $ip  = shift; return unpack "N", pack "C4", split /\./, $ip }
sub _cidr { (my $c = shift) =~ s/\s+//; my ($ip, $base) = split /\//, $c; my $i = _aton($ip); $i &= 2**32 - 2**(32-$base) if !$_[0]; return [$i, $i+2**(32-$base)-1] }

sub allow_auth_md5_pass { shift->config(allow_auth_md5_pass => undef) }
sub allow_auth_basic { shift->config(allow_auth_basic => undef) }
sub allow_auth_qop_auth { shift->config(allow_auth_qop_auth => undef) }
sub digest_realm { shift->config(realm => sub { my $name = shift->server_name; return $name =~ /^(\w+)_server/ ? $1 : $name }) }

sub verify_digest {
    my ($self, $digest, $pass, $uri, $req_sum, $meth, $brand, $ip) = @_;
    my $d = sub { my ($key, $opt) = @_; my $val = $digest->{$key}; $opt ? ($val='') : throw "Digest directive $key was missing" if !defined($val) || !length($val); $val };
    throw "Missing or invalid digest username" if $brand && $d->('username') ne $brand;
    throw "Missing or invalid digest realm", {realm => $self->digest_realm} if $d->('realm') ne $self->digest_realm;
    throw "Digest URI did not match", {digest => $d->('uri'), actual => $uri} if $uri ne $d->('uri');
    my $ha1 = md5_hex($d->('username') .':'. $d->('realm').":$pass");
    $ha1 = md5_hex("$ha1:".$d->('nonce').':'.$d->('cnonce')) if lc($d->('algorithm',1)) eq 'md5-sess';
    my $ha2 = md5_hex($d->('method').":$uri".(($d->('qop',1) eq 'auth-int') ? ":$req_sum" : $self->allow_auth_qop_auth($brand) ? '' : throw 'Digest qop auth not allowed'));
    my $sum = md5_hex("$ha1:".$d->('nonce').($d->('qop',1) ? ':'.$d->('nc').':'.$d->('cnonce').':'.$d->('qop') : '').":$ha2");
    throw 'Digest did not validate' if $sum ne $d->('response');
    return 1;
}

###----------------------------------------------------------------###
# Net::Server::HTTP bits

sub server_args {
    my $self = shift;
    my $name = $self->server_name;
    my $val  = sub { my ($key, $def) = @_; $self->config($key, $def, $name) };
    my $path = $val->(path => ($name =~ /^(\w+)_server/ ? $1 : $name));
    my $host = $val->(host => '*');
    my $port = $val->(port => 443);
    my $ssl  = !$val->(no_ssl => undef);
    my $ad   = $val->(auto_doc => ''); $ad = ($name =~ /^(\w+)_server/ ? $1 : $name).'_doc' if $ad && $ad eq '1';
    my $is_dev = eval { defined(&config::is_dev) && config::is_dev() };
    my $use_dev_port = $is_dev && $ssl && !$val->(no_dev_port => '');
    my $res  = $val->(cgi_bin => undef);
    my $app  = !$res ? \&cgihandler : ($res ne 1) ? $res : 'cgi-bin/'.($name =~ /^(\w+)_server/ ? $1 : $name);
    $app = $self->rootdir_server ."/$app" if !ref($app) && $app !~ /^\//;
    my $st   = $val->(server_type => 'PreFork');
    return {
        server_type => ref($st) ? $st : [$st],
        enable_dispatch => 1,
        ipv => 4,
        app => [[(map{$_ => $app} ref($path) ? @$path : $path),
                 ($ad ? ($ad => \&cgidoc) : ()),
                 '' => \&http_not_found]],
        port => [
            {port => $port, host => $host, ($ssl ? (proto => 'SSL') : ())},
            ($use_dev_port ? {port => ($port == 443 ? 80 : $port-1), host => $host} : ()), # allow for dev to telnet to a non-ssl
        ],
        serialize       => ($is_dev && $ssl) ? 'flock' : 'none', # can only do if hard coded to ipv4 and host resolves to one ip
        access_log_file => $val->(access_log_file => "/var/log/${name}/${name}.access_log"),
        log_file        => $val->(log_file => "/var/log/${name}/${name}.error_log"),
        pid_file        => $val->(pid_file => "/var/run/${name}.pid"),
        user            => $val->(user     => 'readonly'),
        group           => $val->(group    => 'cvs'),
     };
}

sub rootdir_server { shift->config(rootdir_server => $config::config{'rootdir_server'} || sub { require FindBin; $FindBin::RealBin }) }
sub SSL_base_domain { 'example.com' }
sub SSL_cert_file { shift->config(ssl_cert => sub { shift->rootdir_server .shift->SSL_base_domain().'.crt' }) }
sub SSL_key_file  { shift->config(ssl_key  => sub { shift->rootdir_server .shift->SSL_base_domain().'.key' }) }

sub post_bind {
    my $self = shift;
    $0 = $self->server_name;
    $self->SUPER::post_bind(@_);
}

sub child_init_hook { $0 = shift->server_name ." - waiting" } # prefork server

sub run_client_connection {
    my $self = shift;
    $0 = $self->server_name . " - connected";
    $self->SUPER::run_client_connection(@_);
    $_->($self) for @{ $self->{'post_client_callbacks'} || [] };
}

sub server_revision {
    my $self = shift;
    return $self->{'server_revision'} ||= $self->server_name.'/'.$self->revision.($self->{'nshv'} ? ' '.$self->SUPER::server_revision : '');
}

sub http_not_found { shift->send_status(404, "Not found", "<h1>Not Found</h1>") }

sub post_process_request_hook { $0 = shift->server_name ." - post_request" }

sub default_values { {background => 1, setsid => 1} }

###----------------------------------------------------------------###
# Net::Server::HTTP daemonization bits

sub run_server { shift->SUPER::run(@_) }

sub run { throw "Use either run_server or run_commandline for clarity" }

sub run_commandline {
    my $class = shift;
    my $sub = $ARGV[0] && $class->can("__$ARGV[0]") ? "__$ARGV[0]" : undef;
    shift(@ARGV) if $sub;

    if ($ENV{'BOUND_SOCKETS'}) { # HUP
        my $self = ref($class) ? $class : $class->new(@_);
        $self->run_server; # will exit
        warn "Failed to re-initialize server during HUP\n";
        exit 1;
    } elsif ($sub) { # commandline server service
        local $ENV{'NO_PRELOAD'} = 1 if $sub !~ /^__(?:start|restart|reload)$/;
        my $self = ref($class) ? $class : $class->new(@_);
        $self->$sub();
    } elsif ($ENV{'PLACK_ENV'}) {
        return $class->psgi_app(@_);
    } elsif (!@ARGV) {
        throw "$0 help|start|restart|reload|stop|status|tail_error|tail_access|ps|(or any Respite commands)";
    } else {
        my $args = ref($_[0]) ? shift : {@_};
        my $self = ref($class) ? $class : $class->new({%$args, non_daemon => 1});
        require Respite::CommandLine;
        Respite::CommandLine->run({dispatch_factory => $self->dispatch_factory});
    }

    exit 0;
}

sub psgi_app {
    my ($class, $args) = @_;
    require IO::Socket; require Net::Server; require Net::Server::PreFork;
    sub {
        local *ENV = my $env = shift;
        return $class->cgihandler({%{$args||{}}, non_daemon => 1, is_psgi => $env});
    };
}

sub _get_pid { # taken from Net::Server::Daemonize::check_pid_file - but modified
    my $self = shift;
    my $pid_file = $self->{'server'}->{'pid_file'};
    return if ! -e $pid_file; # no pid_file = return success
    return if -z $pid_file; # empty pid_file = return success
    open my $fh, '<', $pid_file or throw "Could not open existing pid_file", {file => $pid_file, msg => $!};
    my $line = <$fh>;
    close $fh;
    return ($line =~ /^(\d{1,10})$/) ? $1 : throw "Could not find pid in existing pid_file", {line => $line};
}

sub _ok {
    my ($ok, $msg) = @_;
    warn "$msg\e[60G[". ($ok ? "\e[1;32m  OK  " : "\e[1;31mFAILED")  ."\e[0;39m]\n";
}

sub __status {
    my $self = shift;
    my $pid  = $self->_get_pid;
    return _ok(0, "Process is not running - no pid") if ! $pid;
    return _ok(1, "Process appears to be running under pid $pid") if kill 0, $pid;
    return _ok(0, "Process does not appear to be running - last pid: $pid");
}

sub __start {
    my $self = shift;
    my $pid  = $self->_get_pid;
    if ($pid && kill(0, $pid)) {
        _ok(0, "Starting - pid already exists");
        throw "Process appears to already be running under pid $pid ... aborting";
    }

    my $pid_file = $self->{'server'}->{'pid_file'};
    if (-e $pid_file) {
        unlink $pid_file or throw "Failed to unlink pid file", {file => $pid_file, msg => $!};
    }

    require Net::Server::Daemonize;
    if (! Net::Server::Daemonize::safe_fork()) {
        # child
        $self->run_server(); # will exit
        _ok(0, "Server run failed - check log");
        exit 1;
    }

    sleep 1;
    $pid  = $self->_get_pid;
    if (!$pid || ! kill 0, $pid) {
        _ok(0, "Starting - new pid not started - check log for details");
        warn "Log file: $self->{'server'}->{'log_file'}\n";
        exit 1;
    }

    # could attempt connection to test for open success

    _ok(1, "Started server");

}

sub __stop {
    my $self = shift;
    my $pid  = $self->_get_pid;
    my $name = $self->server_name;
    if (!$pid) {
        return _ok(1, "Already Stopped $name");
    } elsif (! kill 0, $pid) {
        warn "Cannot kill 0 $pid while stopping: $!\n";
        return _ok(0, "Failed to stop $name");
    }
    if (! (kill(15, $pid) || kill(9, $pid))) {
        warn "Failed to kill TERM or KILL pid $pid while stopping\n";
        return _ok(0, "Failed to stop $name");
    }
    for (1 .. 25) {
        return _ok(1, "Stopped $name") if !kill 0, $pid;
        sleep 0.2;
        require POSIX;
        1 while waitpid(-1, POSIX::WNOHANG()) > 0; # handle rare non-setsid uses of run and _stop
    }

    _ok(0, "Stopping - pid still running");
    exit 1;
}

sub __restart {
    my $self = shift;
    $self->__stop;
    $self->__start;
}

sub __reload {
    my $self = shift;
    my $pid  = $self->_get_pid;
    if (!$pid) {
        _ok(1, "Process appears to be stopped already - attempting start");
        return $self->__start;
    } elsif (! kill 0, $pid) {
        _ok(1, "Process appears to be stopped (kill 0) - attempting start");
        return $self->__start;
    }
    if (! kill 1, $pid) {
        _ok(0, "Reload failed: $!");
        exit 1;
    }

    sleep 1;

    if (kill 0, $pid) {
        _ok(1, "Reloaded server");
    } else {
        _ok(0, "Sent HUP - but server is gone away - attempting start");
        $self->__start;
    }
}

sub __size_access { shift->__size_error('access_log_file') }

sub __size_error {
    my ($self, $file) = @_;
    $file = $self->{'server'}->{$file || 'log_file'} || throw "No log_file to size";
    return -s $file;
}

sub __tail_access { shift->__tail_error(shift(), 'access_log_file') }

sub __tail_error {
    my ($self, $how, $file) = @_;
    $how  = quotemeta($how || shift(@ARGV) || 'f');
    $file = quotemeta($self->{'server'}->{$file || 'log_file'} || throw "No log_file to tail");
    my $cmd  = "tail -$how $file";
    warn "$cmd\n";
    exec $cmd if $how eq 'f';
    warn `$cmd` || "No error log\n";
}

sub __ps {
    my $name = shift->server_name;
    my $out = join '', grep {$_ =~ $name && $_ !~ /\b(?:$$|watch|ps)\b/} `ps auwx`;
    warn $out || "No processes found\n";
}

###----------------------------------------------------------------###

sub cgidoc_brand {
    my $self = shift;
    return $self->config(no_brand => 0) ? undef : $self->config(brand => sub { eval { config::provider() } || $self->_configs->{'provider'} || do { warn "Missing brand"; '-' } });
}

sub cgidoc {
    my $self = shift;
    eval { CGI::initialize_globals() } or warn "Failed to initialize globals: $@" if $INC{'CGI.pm'}; # CGI.pm caches query parameters

    my $name = $self->server_name;
    my $disp = $self->dispatch_factory->({
        is_server   => "$name/doc",
        api_ip      => $ENV{'REMOTE_ADDR'},
        api_brand   => $self->cgidoc_brand,
        remote_ip   => $ENV{'REMOTE_ADDR'},
        remote_user => '-auto-doc-',
        # token and remote_user will be updated by auto_doc_class if it is based on App::_Admin
        dbh_cache => {},
        transport => 'form-doc',
    });

    my $class = $self->config(auto_doc_class => 'Respite::AutoDoc');
    (my $file = "$class.pm") =~ s|::|/|g;
    require $file;
    $class->new({
        service => (($name =~ /^(\w+)_server/) ? $1 : $name),
        server  => $self,
        api_obj => $disp,
    })->navigate;
}

###----------------------------------------------------------------###

1;
