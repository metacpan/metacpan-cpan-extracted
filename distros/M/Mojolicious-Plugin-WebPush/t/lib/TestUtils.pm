package TestUtils;

use Mojo::Promise;
use Exporter 'import';
use MIME::Base64 qw(encode_base64url);
use Crypt::PK::ECC;

our @EXPORT_OK = qw(webpush_config $ENDPOINT %userdb $SUB $PUBKEY_B64);

our $ENDPOINT = '/api/savesubs';
our %userdb;
our $SUB = 'mailto:admin@example.com';
my $T_PRIVATE_PEM = <<EOF;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIPeN1iAipHbt8+/KZ2NIF8NeN24jqAmnMLFZEMocY8RboAoGCCqGSM49
AwEHoUQDQgAEEJwJZq/GN8jJbo1GGpyU70hmP2hbWAUpQFKDByKB81yldJ9GTklB
M5xqEwuPM7VuQcyiLDhvovthPIXx+gsQRQ==
-----END EC PRIVATE KEY-----
EOF
our $PUBKEY_B64 = encode_base64url(
  Crypt::PK::ECC->new(\$T_PRIVATE_PEM)->export_key_raw('public')
);

sub webpush_config {
  +{
    save_endpoint => $ENDPOINT,
    subs_session2user_p => \&subs_session2user_p,
    subs_create_p => \&subs_create_p,
    subs_read_p => \&subs_read_p,
    subs_delete_p => \&subs_delete_p,
    ecc_private_key => \$T_PRIVATE_PEM,
    claim_sub => $SUB,
  };
}

sub subs_session2user_p {
  my($c, $session) = @_;
  my $user_id = $session->{user_id}
    or return Mojo::Promise->reject("Session not logged in");
  Mojo::Promise->resolve($user_id);
}

sub subs_create_p {
  my ($c, $user_id, $subs_info) = @_;
  $userdb{$user_id} = $subs_info;
  Mojo::Promise->resolve(1);
}

sub subs_read_p {
  my ($c, $user_id) = @_;
  return Mojo::Promise->reject("Not found: '$user_id'") if !$userdb{$user_id};
  Mojo::Promise->resolve($userdb{$user_id});
}

sub subs_delete_p {
  my ($c, $user_id) = @_;
  return Mojo::Promise->reject("Not found: '$user_id'") if !$userdb{$user_id};
  Mojo::Promise->resolve(delete $userdb{$user_id});
}

1;
