package Proxy::Impersonate::Cert;
use v5.10; use strict; use warnings;
use Carp ();
use Fcntl qw(O_CREAT O_WRONLY O_EXCL);
use Net::SSLeay ();

BEGIN { Net::SSLeay::initialize() }

# A single persisted self-signed server cert, presented for every host. Under
# the WebKit set_tls_errors_policy(IGNORE) trust model (see the design's
# post-spike revision), WebKit accepts it regardless of host, so no CA and no
# per-host minting are needed.

sub new {
    my ($class, %o) = @_;
    my $dir = $o{cert_dir} or Carp::croak('Cert: cert_dir required');
    -d $dir or mkdir $dir, 0700 or Carp::croak("Cert: mkdir $dir: $!");
    my $self = bless { dir => $dir }, $class;
    $self->_load_or_generate;
    my $ctx = Net::SSLeay::CTX_new() or Carp::croak('Cert: CTX_new failed');
    my $ok = eval { $self->apply_to_ctx($ctx); 1 };
    my $err = $@;
    Net::SSLeay::CTX_free($ctx);
    Carp::croak($err) unless $ok;
    return $self;
}

sub cert_path { "$_[0]{dir}/cert.pem" }
sub key_path  { "$_[0]{dir}/key.pem" }
sub cert      { $_[0]{cert} }
sub key       { $_[0]{key} }

sub _gen_key {
    my $rsa = Net::SSLeay::RSA_generate_key(2048, 0x10001);
    my $pk  = Net::SSLeay::EVP_PKEY_new();
    Net::SSLeay::EVP_PKEY_assign_RSA($pk, $rsa);
    return $pk;
}

sub _mk_self_signed {
    my ($cn, $pkey, $san) = @_;
    my $x = Net::SSLeay::X509_new();
    Net::SSLeay::X509_set_version($x, 2);
    Net::SSLeay::ASN1_INTEGER_set(Net::SSLeay::X509_get_serialNumber($x), (int(rand(2**31)) | 1));
    Net::SSLeay::X509_gmtime_adj(Net::SSLeay::X509_get_notBefore($x), -3600);
    Net::SSLeay::X509_gmtime_adj(Net::SSLeay::X509_get_notAfter($x), 60*60*24*3650);
    Net::SSLeay::X509_set_pubkey($x, $pkey);
    Net::SSLeay::X509_NAME_add_entry_by_txt(
        Net::SSLeay::X509_get_subject_name($x), 'CN', &Net::SSLeay::MBSTRING_UTF8, $cn, -1, 0);
    Net::SSLeay::X509_set_issuer_name($x, Net::SSLeay::X509_get_subject_name($x));   # self
    Net::SSLeay::P_X509_add_extensions($x, $x,
        &Net::SSLeay::NID_basic_constraints => 'CA:FALSE',
        &Net::SSLeay::NID_subject_alt_name  => $san,
        &Net::SSLeay::NID_key_usage         => 'digitalSignature,keyEncipherment',
        &Net::SSLeay::NID_ext_key_usage     => 'serverAuth');
    Net::SSLeay::X509_sign($x, $pkey, Net::SSLeay::EVP_sha256());
    return $x;
}

sub _load_or_generate {
    my ($self) = @_;
    my ($cf, $kf) = ($self->cert_path, $self->key_path);
    if (-e $cf || -l $cf || -e $kf || -l $kf) {
        Carp::croak('Cert: incomplete certificate/key pair') unless -r $cf && -r $kf;
        # Adopting a key we did not write is the interesting case: cert_dir is a
        # 0700 File::Temp dir by default, but the option exists precisely so a
        # caller can persist the cert somewhere of their choosing -- and a
        # shared location is where this goes wrong. A key that is group- or
        # world-accessible, or owned by somebody else, means whoever put it
        # there can impersonate this proxy to the browser it fronts (which is
        # configured to accept its certificate). Refuse rather than adopt it.
        # Symlink-safe: lstat, so a symlink to a 0600 file is judged on the
        # LINK, and O_NOFOLLOW-equivalent semantics apply to the check.
        my @st = lstat $kf;
        if (@st) {
            my ($mode, $uid) = @st[2, 4];
            Carp::croak("Cert: refusing to use $kf -- it is a symlink")
                if -l _;
            Carp::croak("Cert: refusing to use $kf -- not a regular file") unless -f _;
            Carp::croak(sprintf 'Cert: refusing to use %s -- mode %04o is accessible '
                              . 'beyond its owner (want 0600)', $kf, $mode & 07777)
                if $mode & 077;
            Carp::croak("Cert: refusing to use $kf -- it is owned by uid $uid, not $<")
                if $uid != $<;
        }
        my $bc = Net::SSLeay::BIO_new_file($cf, 'r') or Carp::croak("Cert: read $cf failed");
        $self->{cert} = Net::SSLeay::PEM_read_bio_X509($bc);
        Net::SSLeay::BIO_free($bc);
        Carp::croak("Cert: invalid certificate in $cf") unless $self->{cert};
        my $bk = Net::SSLeay::BIO_new_file($kf, 'r') or Carp::croak("Cert: read $kf failed");
        $self->{key} = Net::SSLeay::PEM_read_bio_PrivateKey($bk);
        Net::SSLeay::BIO_free($bk);
        Carp::croak("Cert: invalid private key in $kf") unless $self->{key};
        return;
    }
    my $key  = _gen_key();
    my $cert = _mk_self_signed('Proxy::Impersonate', $key, 'DNS:localhost');
    $self->{key} = $key; $self->{cert} = $cert;
    _spew($cf, Net::SSLeay::PEM_get_string_X509($cert), 0644);
    _spew($kf, Net::SSLeay::PEM_get_string_PrivateKey($key), 0600);
}

# Use the validated in-memory pair for every handshake.
sub apply_to_ctx {
    my ($self, $ctx) = @_;
    Net::SSLeay::CTX_use_certificate($ctx, $self->{cert})
        && Net::SSLeay::CTX_use_PrivateKey($ctx, $self->{key})
        && Net::SSLeay::CTX_check_private_key($ctx)
        or Carp::croak('Cert: invalid or mismatched certificate/key pair');
}

sub _spew {
    my ($path, $data, $mode) = @_;
    $mode //= 0644;
    # create at the target mode so the private key never exists world-readable
    # in an open->chmod window
    sysopen(my $fh, $path, O_CREAT | O_WRONLY | O_EXCL, $mode)
        or Carp::croak("Cert: write $path: $!");
    my $ok = print $fh $data;
    $ok = close($fh) && $ok;
    if (!$ok) {
        my $err = $!;
        unlink $path;
        Carp::croak("Cert: write $path: $err");
    }
}

sub DESTROY {
    my ($self) = @_;
    Net::SSLeay::X509_free($self->{cert})     if $self->{cert};
    Net::SSLeay::EVP_PKEY_free($self->{key})  if $self->{key};   # frees the assigned RSA too
}

1;

__END__

=head1 NAME

Proxy::Impersonate::Cert - the self-signed cert the proxy terminates TLS with

=head1 DESCRIPTION

Generates (once) and persists a self-signed CA-ish certificate under the
proxy's C<cert_dir>, and installs it into an OpenSSL context. Used by
L<Proxy::Impersonate::Connection>. You do not normally touch it directly.

Because the proxy MITMs the client's TLS, the client must be told to accept
this certificate -- L<EV::WebKit> does that with
C<set_tls_errors_policy('ignore')>, which is only reasonable because the
browser-to-proxy hop is loopback. See L<Proxy::Impersonate/TRUST MODEL>.

=cut
