use Mojo::Base -strict;

use Digest::SHA qw(sha256_hex);
use Mojo::File  qw(curfile tempfile);
use Mojo::UserAgent;
use Mojo::UserAgent::Role::AWSSignature4;
use Test::More;
use Time::Piece;
use lib curfile->dirname->sibling('lib')->to_string;

my $fixed_time   = Time::Piece->strptime('20240301T120000Z', '%Y%m%dT%H%M%SZ');
my $empty_hash   = sha256_hex('');
my $curfile_hash = sha256_hex(curfile->slurp);

{    # signed payload with debug and expires header
  no warnings 'redefine';
  local *Mojo::UserAgent::Role::AWSSignature4::time = sub {$fixed_time};

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $ua      = Mojo::UserAgent->with_roles('+AWSSignature4')->new;
  my $awssig4 = {
    service    => 's3',
    region     => 'us-east-1',
    access_key => 'AKIDEXAMPLE',
    secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
    expires    => 900,
    debug      => 1,
    content    => curfile->to_string,
  };
  my $tx = $ua->build_tx(GET => 'https://example.com/my/path?b=2&a=1' => awssig4 => $awssig4);

  is $tx->req->headers->host,                           'example.com',      'host header set';
  is $tx->req->headers->header('X-Amz-Date'),           '20240301T120000Z', 'date header';
  is $tx->req->headers->header('X-Amz-Expires'),        900,                'expires header set';
  is $tx->req->headers->header('X-Amz-Content-Sha256'), $curfile_hash,      'hashed empty payload';

  # reset authorization for recompute
  my $tx_authorization = $tx->req->headers->authorization;
  $tx->req->headers->remove('Authorization');

  my $aws = $ua->new({%$awssig4, _tx => $tx});

  like $aws->canonical_request, qr/^GET\n\/my\/path\n/,                 'canonical request starts with method and path';
  like $aws->canonical_request, qr/x-amz-content-sha256:$curfile_hash/, 'canonical request has payload hash';
  is $aws->credential_scope, '20240301/us-east-1/s3/aws4_request', 'credential scope';
  is $aws->signed_header_list, 'accept-encoding;host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-expires',
    'signed headers list';
  is $tx_authorization, $aws->authorization, 'authorization matches recomputed';
  like join('', @warnings), qr/CR:/,  'canonical request warnings emitted';
  like join('', @warnings), qr/STS:/, 'string to sign warnings emitted';

  $aws->signed_qstring;
  like $tx->req->url->query->to_string, qr/X-Amz-Signature=/, 'signature added to query';
}

{    # unsigned payload with file content and zero expires
  no warnings 'redefine';
  local *Mojo::UserAgent::Role::AWSSignature4::time = sub {$fixed_time};

  my $ua   = Mojo::UserAgent->with_roles('+AWSSignature4')->new;
  my $file = tempfile;
  $file->spurt('payload body');

  my $awssig4 = {
    service          => 'sqs',
    region           => 'eu-west-1',
    access_key       => 'AK2',
    secret_key       => 'SECRET2',
    unsigned_payload => 1,
    content          => "$file",
    expires          => 0,
  };
  my $tx = $ua->build_tx(PUT => '/upload' => awssig4 => $awssig4);

  is $tx->req->headers->host,                           'localhost',        'host defaults to localhost';
  is $tx->req->headers->header('X-Amz-Expires'),        undef,              'expires omitted when zero';
  is $tx->req->headers->header('X-Amz-Content-Sha256'), 'UNSIGNED-PAYLOAD', 'unsigned payload hash';
  is $tx->req->body,                                    'payload body',     'content file attached';

  my $aws = $ua->new({%$awssig4, _tx => $tx});

  is $aws->hashed_payload,      'UNSIGNED-PAYLOAD', 'hashed_payload respects unsigned';
  is length($aws->signing_key), 32,                 'signing key length';
  like $aws->canonical_request, qr/^PUT\n\/upload\n/, 'canonical request path for unsigned payload';
}

done_testing;
