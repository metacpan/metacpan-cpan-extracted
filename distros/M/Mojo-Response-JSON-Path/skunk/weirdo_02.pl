use Weirdo;
use Mojo::Util qw/dumper/;

$\ = "\n"; $, = "\t";

my $u = Weirdo->new({ foo => 'bar', baz => [ 1, 2, 3 ] });

print dumper $u->get('$.baz');

print dumper $u->{foo};

print dumper $u->get;

