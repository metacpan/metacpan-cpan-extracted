use Test::More;
use Test::Mojo;
use strict;
use warnings;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is( 'This is t::MojoTestServer' );

$t->get_ok('/vars.php')->status_is(200,'vars.php no params ok');
my $content = $t->tx->res->body;
my ($server) = $content =~ /\$_SERVER = array *\((.*)\)\s*\$_ENV/s;
my @server = split /\n/, $server;

ok( (grep { /SERVER_PROTOCOL.*HTTP[^S]/ } @server ),
    '$_SERVER{SERVER_PROTOCOL}' );
ok( (grep { /REQUEST_METHOD.*GET/ } @server ), '$_SERVER{REQUEST_METHOD}' );
ok( (grep { /REQUEST_URI.*vars.php/ } @server), '$_SERVER{REQUEST_URI}' );

done_testing();
