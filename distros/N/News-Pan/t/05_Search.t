use Test::Simple 'no_plan';
use lib './lib';
use strict;
use warnings;
use News::Pan::Server;
use Cwd;

my $s = new News::Pan::Server({ abs_path => cwd().'/t/.pan/astraweb' });
ok($s);



$News::Pan::Server::Group::DEBUG = 1;


my $a = $s->group('comp.os.linux.development.apps');

$s->{DEBUG} = 1;

ok( $a->search_count, 'count '.$a->search_count );

for (@{$a->search_results}) {
   print STDERR "  [$_]\n";
}


#ok( $a->search_add_exact('Commercial tools for Linux developers'), 'added term');

ok( $a->search_add('to protect a file'), 'added term');

ok( $a->search_count, 'count '.$a->search_count );

ok($a->search_count == 1);





ok($a->search_reset,'search reset');

ok( $a->search_negative('to protect a file'), 'added term');

ok( $a->search_count, 'count '.$a->search_count );






#my $b = $s->group('alt.binaries.indian.mp3');
#my $c = $s->group('alt.binaries.sounds.mp3.celtic');




