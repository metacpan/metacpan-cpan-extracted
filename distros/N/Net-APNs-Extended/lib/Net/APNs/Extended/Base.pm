package Net::APNs::Extended::Base;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.14';

use parent 'Class::Accessor::Lite';

use JSON::XS;
use Carp qw(croak);
use File::Temp qw(tempfile);
use Socket qw(PF_INET SOCK_STREAM MSG_DONTWAIT inet_aton pack_sockaddr_in);
use Net::SSLeay ();
use Errno qw(EAGAIN EWOULDBLOCK EINTR);
use Time::HiRes ();

__PACKAGE__->mk_accessors(qw[
    host_production
    host_sandbox
    is_sandbox
    port
    password
    cert_file
    cert
    cert_type
    key_file
    key
    key_type
    read_timeout
    write_timeout
    json
]);

my %default = (
    cert_type     => Net::SSLeay::FILETYPE_PEM(),
    key_type      => Net::SSLeay::FILETYPE_PEM(),
    read_timeout  => 3,
    write_timeout => undef,
);

sub new {
    my ($class, %args) = @_;
    croak "`cert_file` or `cert` must be specify"
        unless exists $args{cert_file} or exists $args{cert};
    croak "specifying both `cert_file` and `cert` is not allowed"
        if exists $args{cert_file} and exists $args{cert};
    croak "specifying both `key_file` and `key` is not allowed"
        if exists $args{key_file} and exists $args{key};

    Net::SSLeay::load_error_strings();
    Net::SSLeay::SSLeay_add_ssl_algorithms();
    Net::SSLeay::randomize();

    $args{json} ||= JSON::XS->new->utf8;
    bless { %default, %args }, $class;
}

sub hostname {
    my $self = shift;
    $self->is_sandbox ? $self->host_sandbox : $self->host_production;
}

sub _connect {
    my $self = shift;
    my $connection = $self->{_connection} || [];
    my ($sock, $ctx, $ssl) = @$connection;
    return $connection if $sock && $ctx && $ssl;

    $self->disconnect;

    $sock = $self->_create_socket;
    $ctx  = $self->_create_ctx;
    $ssl  = $self->_create_ssl($sock, $ctx);

    $self->{_connection} = [$sock, $ctx, $ssl];
}

sub _create_socket {
    my $self = shift;
    socket(my $sock, PF_INET, SOCK_STREAM, 0) or die "can't create socket: $!";
    my $sock_addr = do {
        my $iaddr = inet_aton($self->hostname)
            or die sprintf "can't create iaddr from %s", $self->hostname;
        pack_sockaddr_in $self->port, $iaddr or die "can't create sock_addr: $!";
    };
    CORE::connect($sock, $sock_addr) or die "can't connect socket: $!";
    my $old_out = select($sock); $| = 1; select($old_out); # autoflush

    return $sock;
}

sub _create_ctx {
    my $self = shift;
    my $ctx = Net::SSLeay::CTX_new() or _die_if_ssl_error("can't create SSL_CTX: $!");
    Net::SSLeay::CTX_set_options($ctx, Net::SSLeay::OP_ALL());
    _die_if_ssl_error("ctx options: $!");

    my $pw = $self->password;
    Net::SSLeay::CTX_set_default_passwd_cb($ctx, ref $pw ? $pw : sub { $pw });

    $self->_set_certificate($ctx);

    return $ctx;
}

sub _create_ssl {
    my ($self, $sock, $ctx) = @_;
    my $ssl = Net::SSLeay::new($ctx);
    Net::SSLeay::set_fd($ssl, fileno $sock);
    Net::SSLeay::connect($ssl) or _die_if_ssl_error("failed ssl connect: $!");

    return $ssl;
}

sub _set_certificate {
    my ($self, $ctx) = @_;
    my ($cert_guard, $key_guard);
    my $cert_file = $self->cert_file;
    ($cert_guard, $cert_file) = _tmpfile($self->cert) unless defined $cert_file;
    Net::SSLeay::CTX_use_certificate_file($ctx, $cert_file, $self->cert_type);
    _die_if_ssl_error("certificate: $!");

    my $key_file;
    if (exists $self->{key_file} or exists $self->{key}) {
        $key_file = $self->key_file;
        ($key_guard, $key_file) = _tmpfile($self->key) unless defined $key_file;
    }
    else {
        $key_file = $cert_file;
    }
    Net::SSLeay::CTX_use_RSAPrivateKey_file($ctx, $key_file, $self->key_type);
    _die_if_ssl_error("private key: $!");
}

sub disconnect {
    my $self = shift;
    my $connection = $self->{_connection} || [];
    return 1 unless @$connection;

    my ($sock, $ctx, $ssl) = @$connection;
    if ($sock) {
        unless (defined CORE::shutdown($sock, 1)) {
            die "can't shutdown socket: $!";
        }
    }
    if ($ssl) {
        Net::SSLeay::free($ssl);
        _die_if_ssl_error("failed ssl free: $!");
    }
    if ($ctx) {
        Net::SSLeay::CTX_free($ctx);
        _die_if_ssl_error("failed ctx free: $!");
    }
    if ($sock) {
        close $sock or die "can't close socket: $!";
    }

    delete $self->{_connection};

    return 1;
}

sub _send {
    my $self = shift;
    my $data = \$_[0];
    my ($sock, $ctx, $ssl) = @{$self->_connect};

    return unless $self->_do_select($sock, 'write', $self->write_timeout);

    Net::SSLeay::ssl_write_all($ssl, $data) or _die_if_ssl_error("ssl_write_all error: $!");
    return 1;
}

sub _read {
    my $self = shift;
    my ($sock, $ctx, $ssl) = @{$self->_connect};

    return unless $self->_do_select($sock, 'read', $self->read_timeout);

    my $data = Net::SSLeay::ssl_read_all($ssl) or _die_if_ssl_error("ssl_read_all error: $!");
    return $data;
}

sub _do_select {
    my ($self, $sock, $act, $timeout) = @_;

    my $begin_time = Time::HiRes::time();

    vec(my $bits = '', fileno($sock), 1) = 1;
    while (1) {
        my $nfound;
        if ($act eq 'read') {
            $nfound = select my $rout = $bits, undef, undef, $timeout;
        }
        else {
            $nfound = select undef, my $wout = $bits, undef, $timeout;
        }
        return unless $nfound; # timeout

        # returned error
        if ($nfound == -1) {
            if ($! == EINTR) {
                # can retry
                $timeout -= (Time::HiRes::time() - $begin_time) if defined $timeout;
                next;
            }
            else {
                # other error
                $self->disconnect;
                return;
            }
        }

        last;
    }

    return 1;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect;
}

sub _tmpfile {
    my $fh = File::Temp->new(
        TEMPLATE => "napnseXXXXXXXXXXX",
        TMPDIR   => 1,
        EXLOCK   => 0,
    );
    syswrite $fh, $_[0];
    close $fh;

    return $fh, $fh->filename;
}

sub _die_if_ssl_error {
    my ($msg) = @_;
    my $err = Net::SSLeay::print_errs("SSL error: $msg");
    croak $err if $err;
}

1;
__END__
