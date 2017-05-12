use strict;

# cgi environment no defined in command line
no warnings 'uninitialized';

use Test::More tests => 8;

BEGIN { use_ok('Nes') };

use Cwd;
my $dir       = getcwd;
my $top       = nes_top_container->new('test.nhtml',$dir.'/t/');
my $container = nes_container->get_obj();
my $cookies   = nes_cookie->get_obj();
my $session   = nes_session->get_obj();
my $query     = nes_query->get_obj();  

ok( defined $top, 'nes_top_container returned something' );
ok( defined $container, 'nes_container returned something' );
ok( defined $cookies, 'nes_cookie returned something' );
ok( defined $session, 'nes_session returned something' );
ok( defined $query, 'query returned something' );

my $source = $container->get_out();
ok($source =~ /\{\: \$ test \:\}/, 'container source');

my %tags = ( test => 'the out' );
$container->set_tags(%tags);
$container->interpret();
my $output = $container->get_out();
ok($output =~ /the out/i, 'container out');
