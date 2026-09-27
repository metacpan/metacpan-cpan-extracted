package Plack::Handler::Feersum::SS;

use strict;
use warnings;
our $VERSION = '0.06';
use base 'Plack::Handler::Feersum';
use Feersum;
use Server::Starter 'server_ports';
use Carp qw'croak carp';
use Symbol 'geniosym';
use Fcntl qw'F_GETFL F_SETFL O_NONBLOCK';
use constant MAX_PRE_FORK => $ENV{FEERSUM_MAX_PRE_FORK} || 1000;

my @SETTINGS = (
    [keepalive      => 'set_keepalive'],
    [reverse_proxy  => 'set_reverse_proxy'],
    [proxy_protocol => 'set_proxy_protocol'],
    [psgix_io       => 'set_psgix_io'],
    map +[$_ => $_], qw/read_timeout header_timeout write_timeout linger_timeout
        max_connection_reqs read_priority write_priority max_accept_per_loop
        max_connections max_read_buf max_body_len max_uri_len wbuf_low_water
        max_h2_concurrent_streams max_h2_conn_body/,
);

my @UNSUPPORTED = qw/daemonize hot_restart pid_file reuseport backlog/;

my %KNOWN = map +($_ => 1), (map $_->[0], @SETTINGS), qw/
    accept_priority tls tls_cert_file tls_key_file h2 sni
    pre_fork graceful_timeout after_fork max_requests_per_worker startup_timeout
    preload_app access_log user group quiet verbose
    host port listen socket server_ready running app app_file
/;

sub run {
    my $self = shift;
    for my $opt (@UNSUPPORTED) {
        croak "$opt is not supported under Server::Starter" if $self->{$opt};
    }
    return $self->SUPER::run(@_);
}

sub _prepare {
    my $self = shift;
    $self->_normalize_options;

    my %ports = %{server_ports()};
    croak "no listen ports from Server::Starter" unless %ports;

    my $f = $self->{endjinn} = Feersum->endjinn;
    my $tls = delete $self->{tls};
    croak "tls option requires Feersum compiled with TLS support"
        if $tls && !($f->can('has_tls') && $f->has_tls);

    # before use_socket: each accept watcher captures accept_priority at creation
    $self->_set_option($f, accept_priority => 'accept_priority');

    my (@socks, @names);
    for my $name (sort keys %ports) {
        my $fd = $ports{$name};
        open(my $sock = geniosym, '<&=', $fd) or croak "fdopen fd=$fd: $!";
        my $flags = fcntl($sock, F_GETFL, 0) or croak "fcntl F_GETFL: $!";
        fcntl($sock, F_SETFL, $flags | O_NONBLOCK) or croak "fcntl F_SETFL: $!";
        $self->{quiet} or warn "Feersum [$$]: listening on $name fd=$fd\n";
        $f->use_socket($sock);
        push @socks, $sock;
        push @names, $name;
    }
    @$self{qw/sock _socks listen/} = ($socks[0], \@socks, \@names);

    $self->_set_option($f, @$_) for @SETTINGS;

    if ($tls) {
        for my $cfg ($tls, @{ $self->{sni} || [] }) {
            $f->set_tls(listener => $_, %$cfg) for 0 .. $#socks;
        }
        # pre_fork respawns re-apply TLS from here after unlisten() drops it
        $self->{_tls_config} = $tls;
        $self->{quiet} or warn "Feersum [$$]: TLS enabled on "
            . scalar(@socks) . " listener(s)\n";
    }

    my ($name) = (grep(/^(?:.+?:|)[0-9]+$/, @names), @names);
    $self->{server_ready}->({
        server_software => 'Feersum',
        ($tls ? (proto => 'https') : ()),
        $name =~ m/^(?:(.+?):|)([0-9]+)$/
            ? (host => $1 // 0, port => $2)
            : (host => 'unix/', port => $name),
    }) if $self->{server_ready};
    return;
}

sub _normalize_options {
    my $self = shift;
    delete $self->{quiet} if delete $self->{verbose};
    if (my $opts = delete $self->{options}) {
        croak "options must be a hash reference" unless ref $opts eq 'HASH';
        @$self{keys %$opts} = values %$opts;
    }
    carp "Unknown option '$_' ignored"
        for sort grep { !/^_/ && !$KNOWN{$_} } keys %$self;

    if (my $n = $self->{pre_fork}) {
        croak "pre_fork must be a positive integer" if $n !~ /^\d+$/ || $n < 1;
        croak "pre_fork=$n exceeds maximum of " . MAX_PRE_FORK if $n > MAX_PRE_FORK;
    }
    for my $opt (qw/accept_priority read_priority write_priority/) {
        my $v = $self->{$opt};
        croak "$opt must be an integer between -2 and 2"
            if defined $v && !($v =~ /^-?\d+$/ && $v >= -2 && $v <= 2);
    }
    my $v = $self->{max_accept_per_loop};
    croak "max_accept_per_loop must be a positive integer"
        if defined $v && !($v =~ /^\d+$/ && $v > 0);
    $v = $self->{max_connections};
    croak "max_connections must be a non-negative integer"
        if defined $v && $v !~ /^\d+$/;
    for my $opt (qw/after_fork access_log/) {
        croak "$opt must be a code reference"
            if defined $self->{$opt} && ref $self->{$opt} ne 'CODE';
    }
    croak "user/group need a Feersum::Runner that drops privileges (Feersum 1.507+)"
        if (defined $self->{user} || defined $self->{group}) && !$self->can('_drop_privs');

    my ($cert, $key) = delete @$self{qw/tls_cert_file tls_key_file/};
    if (!$self->{tls}) {
        croak "tls_cert_file requires tls_key_file" if $cert && !$key;
        croak "tls_key_file requires tls_cert_file" if $key && !$cert;
        $self->{tls} = { cert_file => $cert, key_file => $key } if $cert;
    }
    my $h2 = delete $self->{h2};
    my $tls = $self->{tls};
    if (!$tls) {
        croak "h2 requires TLS (provide tls_cert_file and tls_key_file, or a tls hash)" if $h2;
        croak "sni requires TLS (provide tls_cert_file and tls_key_file, or a tls hash)"
            if $self->{sni};
        return;
    }
    croak "tls must be a hash reference" unless ref $tls eq 'HASH';
    $tls->{h2} = 1 if $h2;
    my $sni = $self->{sni};
    croak "sni must be an array of hash references"
        if $sni && (ref $sni ne 'ARRAY' || grep { ref($_) ne 'HASH' } @$sni);
    for my $cfg ($tls, @{ $sni || [] }) {
        for my $k (qw/cert_file key_file/) {
            croak "tls requires $k" unless $cfg->{$k};
            -f $cfg->{$k} && -r _
                or croak "tls $k '$cfg->{$k}': not found or not readable";
        }
    }
    return;
}

sub _set_option {
    my ($self, $f, $opt, $meth) = @_;
    my $v = delete $self->{$opt};
    return unless defined $v;
    return $f->$meth($v) if $f->can($meth);
    carp "Feersum $Feersum::VERSION has no $meth(); '$opt' ignored";
    return;
}

1;
