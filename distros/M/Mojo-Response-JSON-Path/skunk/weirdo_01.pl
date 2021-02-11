use Weirdo;
use Mojo::Util qw/dumper/;
use Scalar::Util;

$\ = "\n"; $, = "\t";

my $w = { foo => 'bar', baz => [ 1, 2, 3 ] };

print dumper $w->get('$.baz');

my $a = [ 1, 2, { a => 1, b => 2 } ];

print dumper $a->get('$.2.a');
