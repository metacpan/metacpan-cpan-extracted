package Net::Respite::Client;

# Net::Respite::Client - Generic class for running remote services

use strict;
use warnings;
use base 'Net::Respite::Common'; # Default _configs
use IO::Socket::SSL ();
use Time::HiRes qw(sleep);
use Digest::MD5 qw(md5_hex);

BEGIN {
    if (! eval { require Throw }) {
        *Throw_::TO_JSON = sub { +{%{$_[0]}} };
        *Throw_::_str = sub { my ($s) = @_; my ($e,$p) = delete(@$s{qw(error _pretty)}); $e||="throw"; $e .= ': '.($p||$Throw::pretty?jsop():json())->encode($s) if %$s; "$e\n" };
        *throw = *Throw_::throw = sub { my ($m,$a,$l)=@_; $a=ref($m) ? $m : {%{$a||{}}, error => $m};
            do {my$i=$l||0;$i++while __PACKAGE__ eq caller$i; $a->{'trace'}=sprintf "%s at %s line %s\n",(caller$i)[3,1,2]} if $a->{'trace'}||$l; die bless $a, 'Throw_' };
         overload::OVERLOAD('Throw_', '""' => \&Throw_::_str, fallback => 1);
    } else { Throw->import('throw') }
}

sub service_name { $_[0]->{'service_name'} || $_[0]->{'service'} || throw "Missing service_name" }

sub run_method {
    my $self = shift;
    my $name   = $self->service_name;
    my $method = shift || throw "Missing $name service method", undef, 1;
    my $args   = shift || {};
    throw "Invalid $name service args", {method => $method, args => $args}, 1 if ref($args) ne 'HASH';
    local $args->{'_i'} = $self->{'remote_ip'}   || $ENV{'REMOTE_ADDR'} || (($ENV{'REALUSER'} || $ENV{'SUDO_USER'}) ? 'sudo' : 'cmdline');
    local $args->{'_w'} = $self->{'remote_user'} || $ENV{'REALUSER'} || $ENV{'SUDO_USER'} || $ENV{'REMOTE_USER'} || $ENV{'USER'} || (getpwuid($<))[0] || '-unknown-';
    local $args->{'_t'} = $self->{'token'} if !$args->{'_t'} && $self->{'token'};
    local $args->{'_c'} = do {my $i = my $c = 0; $c = [(caller $i++)[0..3]] while !$i || $c->[0]->isa(__PACKAGE__); join '; ', @$c} if ! $self->config(no_trace => undef, $name);
    local $self->{'flat'} = exists($args->{'_flat'}) ? delete($args->{'_flat'}) : $self->config(flat => undef, $name);
    return $self->_remote_call($method, $args) if $self->_needs_remote($method);
    return $self->_local_call( $method, $args);
}

sub _needs_remote {
    my ($self, $method) = @_;
    return $method !~ /(^local_|_local$)/;
}

sub _local_call {
    my ($self, $method, $args) = @_;
    my $name = $self->service_name;
    local $self->{'brand'} ||= $self->api_brand($name);
    my $hash = eval {
        my $code = $self->can("__$method") || throw "Invalid $name service method", {method => $method}, 1;
        return $code->($self, $args);
    } || (ref($@) eq 'HASH' && $@->{'error'} ? $@ : {error => "Trouble running $name service method", service => $name});
    return $self->_result({method => $method, args => $args, data => $hash, service => $name, url => 'local'});
}

sub config {
    my ($self, $key, $def, $name) = @_;
    $name ||= $self->service_name;
    my $c = $self->_configs($name);
    return exists($self->{$key}) ? $self->{$key}
        : exists($c->{"${name}_service_${key}"}) ? $c->{"${name}_service_${key}"}
        : (ref($c->{"${name}_service"}) && exists $c->{"${name}_service"}->{$key}) ? $c->{"${name}_service"}->{$key}
        : exists($c->{"${name}_${key}"}) ? $c->{"${name}_${key}"}
        : (ref($c->{$name}) && exists $c->{$name}->{$key}) ? $c->{$name}->{$key}
        : ref($def) eq 'CODE' ? $def->($self) : $def;
}

sub api_brand {
    my ($self, $name) = @_;
    $name ||= $self->service_name;
    return undef if $self->config(no_brand => undef, $name); ## no critic (ProhibitExplicitReturnUndef)
    $self->config(brand => sub { eval { config::provider() } || $self->_configs->{'provider'} || do { warn "Missing $name brand"; '-' } }, $name);
}

sub _remote_call {
    my ($self, $method, $args) = @_;
    my $begin  = Time::HiRes::time();
    my $name   = $self->service_name;
    my $brand  = $self->api_brand($name);
    my $val    = sub { my ($key, $def) = @_; $self->config($key, $def, $name) };
    my $no_ssl = $val->(no_ssl => undef);
    my $host   = $val->(host => sub {throw "Missing $name service host",undef,1});
    my $port   = $val->(port => ($no_ssl ? 80 : 443));
    my $path   = $val->(path => sub { $name =~ /^(\w+)_service/ ? $1 : $name });
    my $pass   = $val->(no_sign => undef) ? undef : $val->(pass => undef); # rely on the server to tell us if a password is necessary
    my $utf8   = exists($args->{'_utf8_encoded'}) ? delete($args->{'_utf8_encoded'}) : $val->(utf8_encoded => undef);
    my $enc    = $utf8 && (!ref($utf8) || $utf8->{$method});
    my $retry  = $val->(retry => undef);
    my $ns     = $val->(ns => undef);
    $method    = "${ns}_${method}" if $ns;
    my $url    = "/$path/$method".($brand ? "/$brand" : '');
    my $cookie = $val->(cookie => undef);

    my $req;
    local $SIG{'ALRM'} = sub { die "Timeout on $name\n" };
    my $old  = alarm($args->{'_timeout'} || $val->(timeout => 120)) || 0;
    my %head;
    my $hash = eval {
        _decode_utf8_recurse($args) if $enc;
        $req = eval { $self->json->encode($args) } || throw "Trouble encoding $name service json", {msg => $@}, 1;
        my $sign = defined($pass) ? do { my $t = int $begin; "X-Respite-Auth: ".($val->('md5_pass') ? md5_hex($pass) : md5_hex("$pass:$t:$url:".md5_hex($req)).":$t")."\r\n" } : '';
        $cookie = $cookie ? "Cookie: $cookie\r\n" : '';

        my $sock;
        my $i = 0;
        while (++$i) {
            # Note SSL verify may not work as expected on IO::Socket::SSL versions below v1.46
            $sock = $no_ssl ? IO::Socket::INET->new("$host:$port")
                            : IO::Socket::SSL->new(PeerAddr => $host, PeerPort => $port, SSL_verify_mode => $val->(ssl_verify_mode => 0));
            last if $sock || !$retry || (Time::HiRes::time() - $begin > 3);
            sleep 0.5;
        }
        if (!$sock) {
            throw "Could not connect to $name service", {
                host => $host, port => $port, url => $url,
                msg => (!$no_ssl && ($IO::Socket::SSL::SSL_ERROR || $!)), detail => "$@", ssl => !$no_ssl, tries => $i,
            };
        }

        my $out = "POST $url HTTP/1.0\r\n${cookie}${sign}Host: $host\r\nContent-length: ".length($req)."\r\nContent-type: application/json\r\n\r\n$req";
        warn "DEBUG_Respite: Connected to http".($no_ssl?'':'s')."://$host:$port/\n$out\n" if $ENV{'DEBUG_Respite'};
        print $sock $out;
        my ($len, $type, $line);
        throw "Got non-200 status from $name service", {status => $line, url => $url} if !($line = <$sock>) || $line !~ m{^HTTP/\S+ 200\b};
        while (defined($line = <$sock>)) {
            $line =~ s/\r?\n$// || throw "Failed to find line termination", {line => $line};
            last if $line eq "";
            my ($key, $val) = split /\s*:\s*/, $line, 2;
            $head{$key} = $head{$key} ? ref($head{$key}) ? [@{$head{$key}}, $val] : [$head{$key}, $val] : $val;
            $len = ($val =~ /^\d+$/) ? $val : throw "Invalid content length", {h => \%head} if lc($key) eq 'content-length';
        }
        throw "Failed to find content length in $name service response" if ! $len;
        throw "Content too large in $name service", {length => $len} if $len > 100_000_000;
        my $data = '';
        while (1) {
            read($sock, $data, $len, length $data) || throw "Failed to read bytes", {needed => $len, got => length($data)};
            last if length $data >= $len;
        }
        close $sock;
        alarm($old);

        throw "Invalid $name service json object string" if $data !~ /^\s*\{/;
        my $resp = eval { $self->json->decode($data) } || throw "Failed to decode $name service json response data", {msg => $@};
        _encode_utf8_recurse($resp) if $enc;
        $resp;
    } || do { alarm($old); {error => "Failed to get valid $name service response: $@"} };

    return $self->_result({
        service => $name,
        method  => $method,
        args    => $args,
        data    => $hash,
        headers => \%head,
        url     => $url, host => $host, port => $port,
        brand   => $brand,
        elapsed => sprintf('%.05f', Time::HiRes::time() - $begin),
        ($self->{'pretty'} ? (pretty => 1) : ()),
    });
}

sub _result {
    my ($self, $args) = @_;
    if ($self->{'flat'}) {
        my $data = $args->{'data'};
        throw {_service => $args->{'service'} || $self->service_name, %$data, ($args->{'pretty'} ? (_pretty => 1) : ())} if $data->{'error'};
        return $data;
    }
    return bless $args, $self->_result_class;
}

sub _result_class { shift->{'result_class'} || 'Net::Respite::Client::Result' }

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

sub AUTOLOAD {
    my $self = shift;
    my $args = shift || {};
    my $meth = $Net::Respite::Client::AUTOLOAD =~ /::(\w+)$/ ? $1 : throw "Invalid method\n";
    throw "Self was not passed while looking up method", {method => $meth, trace => 1} if ! ref $self;
    throw "Invalid ".$self->service_name." method \"$meth\"", {trace => 1} if !$self->_needs_remote($meth) && ! $self->can("__${meth}");
    my $code = sub { $_[0]->run_method($meth => $_[1]) };
    no strict 'refs'; ## no critic
    *{ref($self)."::$meth"} = $code if __PACKAGE__ ne ref($self);
    return $self->$code($args);
}

sub DESTROY {}

sub run_commandline {
    my $class = shift;
    my $args = ref($_[0]) ? shift : {@_};
    my $self = ref($class) ? $class : $class->new({%$args});
    require Net::Respite::CommandLine;
    Net::Respite::CommandLine->run({dispatch_factory => sub { $self }});
}

###----------------------------------------------------------------###

{
    package Net::Respite::Client::Result;
    use overload 'bool' => sub { ! shift->error }, '""' => \&as_string, fallback => 1;
    sub error     { shift->data->{'error'} }
    sub TO_JSON   { return {%{$_[0]}} }
    sub as_string {
        my $self = shift;
        if (my $err = $self->error) {
            my $data = $self->data;
            my $p    = defined($Net::Respite::Client::pretty) ? $Net::Respite::Client::pretty : $self->{'pretty'};
            local $data->{'error'};  delete $data->{'error'};
            return !scalar keys %$self ? $err : "$err: ".($p ? Net::Respite::Client::jsop():Net::Respite::Client::json())->encode({%$data});
        }
        return "Called $self->{'service'} service method $self->{'method'}";
    }
    sub data { shift->{'data'} ||= {} }
}

1;
