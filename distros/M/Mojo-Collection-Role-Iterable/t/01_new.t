use Test::More;
use Mojo::Collection;

my $c = Mojo::Collection->new->with_roles("+Iterable");

isa_ok($c, "Mojo::Collection");

done_testing()
