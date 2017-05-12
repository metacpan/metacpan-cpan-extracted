#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Template::AsGraph' );
	use_ok( 'Template::AsGraph::Context' );
}

diag( "Testing Template::AsGraph $Template::AsGraph::VERSION, Perl $], $^X" );

can_ok('Template::AsGraph', 'graph');
can_ok('Template::AsGraph::Context', 'process');

my $m = Template::AsGraph::Context->new();
isa_ok($m, 'Template::Context');
