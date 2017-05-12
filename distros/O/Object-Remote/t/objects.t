use strictures 1;
use Test::More;
use Sys::Hostname qw(hostname);
use overload ();

use Object::Remote;

$ENV{PERL5LIB} = join(
  ':', ($ENV{PERL5LIB} ? $ENV{PERL5LIB} : ()), qw(lib t/lib)
);

my $connection = Object::Remote->connect('-');

my $ortestobj_j = ORTestObjects->new::on($connection, { name => 'John' });
my $ortestobj_k = ORTestObjects->new::on($connection, { name => 'Ken' });

is($ortestobj_k->takes_object($ortestobj_j), 1, 'Passed correct object back over the wire');

my $george = ORTestObjects->new::on($connection, { name => 'George'});
my $george_again = $george->give_back;
is($george->{remote}, $george_again->{remote}, 'objects appear to be the same');
is($george->name, $george_again->name, 'objects have the same name');

done_testing;
