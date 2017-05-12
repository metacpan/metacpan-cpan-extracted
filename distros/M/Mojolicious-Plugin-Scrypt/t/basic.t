use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Scrypt';

get '/crypt' => sub {
    my $c = shift;
    my ( $p, $s ) = map { $c->param($_) } qw/p s/;
    my $encoded = $c->scrypt( $p, $s );
    $c->render( text => $encoded );
};

get '/verify' => sub {
    my $c = shift;
    my ( $p, $e ) = map { $c->param($_) } qw/p e/;
    my $ok = $c->scrypt_verify( $p, $e );

    $c->render( text => ( $ok ? 'Pass' : 'Fail' ) );
};

my $t    = Test::Mojo->new();
my @data = <DATA>;

for (@data) {
    chomp;
    my ( $encoded, $password, $salt ) = split / /;

    $t->get_ok( "/crypt" => form => { p => $password, s => $salt } )->status_is(200)
      ->content_is($encoded);
    $t->get_ok( "/crypt" => form => { p => $password } )->status_is(200)->content_isnt($encoded);
    $t->get_ok( "/verify" => form => { p => $password, e => $encoded } )->status_is(200)
      ->content_is('Pass');
}

my $password = 'my_secret_password';
my $salt     = 'my_salt_is_salt';
my $encoded  = app->scrypt( $password, $salt );

ok app->scrypt_verify( $password, $encoded ), 'accept ok';
ok !app->scrypt_verify( 'bad_password', $encoded ), 'deny ok';

my $encoded2 = app->scrypt( $password, $salt );
is $encoded, $encoded2, 'recrypt ok';

done_testing();

__DATA__
SCRYPT:16384:8:1:c2FsdA==:JHfDKDacPOCli1rF3hqxW86FKicFOooYhkW0VR6ic1c= mypassword salt
SCRYPT:16384:8:1:c29tZXNhbHQ=:SSgnxopQoS2unX9D6YbQqik3BsxywBnKU/bPhD0cX/8= mypassword.$ somesalt
SCRYPT:16384:8:1:c29tZXNhbHQ=:YyAUyxTfHoDztEt2rZaWtUumxu0O8ALaIve68DeYlLI= mypass.<>%$laws()~ somesalt
SCRYPT:16384:8:1:bXlzb21lc2FsdHNvbWVzYWx0c29tZXNhbHRTb2x0:rxlVIcKdsb0YENb26gRchgetjY4bnCDUjwALn4AWp3w= mypassword mysomesaltsomesaltsomesaltSolt
