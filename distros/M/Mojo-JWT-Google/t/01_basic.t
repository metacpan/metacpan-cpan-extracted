use strict;
use warnings;
use Test2::V0;
use Mojo::JWT::Google;
use Mojo::Collection 'c';
use File::Basename 'dirname';
use FindBin;
use Cwd 'abs_path';
#my $grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer";

my $client_email = 'mysa@developer.gserviceaccount.com';
my $target = 'https://www.googleapis.com/oauth2/v4/token';


isa_ok my $jwt = Mojo::JWT::Google->new, ['Mojo::JWT::Google'], 'empty object creation';

# accessors
is $jwt->client_email, undef, 'not init';
is $jwt->client_email($client_email), $jwt, 'service_account set';
is $jwt->client_email, $client_email, 'service_account get';

is $jwt->scopes, [], 'no scopes';
is push( @{ $jwt->scopes }, '/a/scope'), 1, 'scopes add one scope';
is push( @{ $jwt->scopes }, '/b/scope'), 2, 'scopes add another';
is $jwt->scopes, ['/a/scope','/b/scope'], 'scopes get all';

is $jwt->target, 'https://www.googleapis.com/oauth2/v4/token', 'target get';
is $jwt->target('https://a/new/target'), $jwt, 'target set';
is $jwt->target, 'https://a/new/target', 'target get';

is $jwt->expires_in, 3600, 'expires in one hour by default';
is $jwt->expires_in(300), $jwt, 'set to 5 minutes';
is $jwt->expires_in, 300, 'right value';

is $jwt->issue_at, undef, 'unset by default';
is $jwt->issue_at('1429812717'), $jwt, 'issue_at set';
is $jwt->issue_at, '1429812717', 'issue_at get';

# basic claim work
for my $scopes ( c('/a/scope', '/b/scope'), [qw+ /a/scope /b/scope +] ){
  ok $jwt = Mojo::JWT::Google->new( client_email => $client_email,
                                 issue_at => '1429812717',
                                 scopes => $scopes), 'created a token for ' . ref($scopes) . ' as scopes';

  is $jwt->claims, { iss   => $client_email,
                            scope => '/a/scope /b/scope',
                            aud   => 'https://www.googleapis.com/oauth2/v4/token',
                            exp   => '1429816317',
                            iat   => '1429812717',
                          }, 'claims based on accessor settings';
}

is $jwt->user_as, undef, 'impersonate user undef by default';
is $jwt->user_as('riche@cpan.org'), $jwt, 'set user';
is $jwt->user_as, 'riche@cpan.org', 'get user';

is $jwt->claims, { iss   => $client_email,
                          scope => '/a/scope /b/scope',
                          aud   => 'https://www.googleapis.com/oauth2/v4/token',
                          exp   => '1429816317',
                          iat   => '1429812717',
                          sub   => 'riche@cpan.org',
                        }, 'claims based on accessor settings w impersonate';

# interop with Mojo::JWT

$jwt = Mojo::JWT::Google->new( client_email => $client_email,
                               scopes => c('/a/scope', '/b/scope'));



# we must set this
is $jwt->scopes(c->new('/a/scope')), $jwt, 'scopes add one scope';

my $claims = $jwt->claims;

# predefine
$jwt = Mojo::JWT::Google->new( scopes => c('/scope/a/', '/scope/b/'));

# predefine w json file
my $testdir = dirname ( abs_path( __FILE__ ) );


like dies {
  Mojo::JWT::Google->new( from_json => "$testdir/load0.json" ),
}, qr/Your JSON file import failed.*/, 'dies on file load failure';


$jwt = Mojo::JWT::Google->new( from_json => "$testdir/load1.json" );

is $jwt->secret, <<EOF, 'secret match';
-----BEGIN PRIVATE KEY-----
MIIC
k8KLWw6r/ERRBg==
-----END PRIVATE KEY-----
EOF

is $jwt->client_email, '9dvse@developer.gserviceaccount.com',
  'client email matches';

is $jwt->from_json, 0, 'requires parameter';
is $jwt->from_json('/foo/bar/baz/me'), 0, 'file must exist';
is $jwt->from_json( "$testdir/load3.json" ), 0, 'must have key defined';
is $jwt->from_json( "$testdir/load4.json" ), 0, 'must be for service account';


$jwt = Mojo::JWT::Google->new;
is $jwt->client_email('mysa@developer.gserviceaccount.com'), $jwt, 'sa set';
$jwt->expires('9999999999');

my $jwte = $jwt->encode;
my $jwtd = $jwt->decode($jwte);

done_testing;
