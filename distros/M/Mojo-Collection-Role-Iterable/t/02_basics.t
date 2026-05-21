use Mojo::Collection;
use Test::More;

$\ = "\n"; $, = "\t"; binmode(STDOUT, ":utf8");

my @d = ([a, 1], [b, 1], [c, 2], [d, 2], [e, 2], [f, 3]);
my $i = 0;
my @p = map { [ $i++, $_->@* ] } @d;

my $c = Mojo::Collection->new(@d)->with_roles("+Iterable");

is_deeply($c->[0], [a, 1], "Explicit index");

# for ($c->collection->@*) { print $_->@* }
my $j = 0;
$c->reset;
while (my $item = $c->iterate) {
    is_deeply( [ $item->@* ], $d[$j++], sprintf "Iterate test %i", $j - 1);
}

is($c->idx, 5, "Index after iteration ok");

my $k = 0;
$c->each(sub { 
	     is_deeply( [ $_->@*, $c->idx  ], [ $d[$k++]->@*, $k - 1 ], sprintf "Each test %i", $k - 1);
	 });


$c->reset;

is_deeply($c->current, [a, 1], "Current");
is_deeply($c->prev, undef, "Prev");

$c++;
is_deeply($c->prev, [a, 1], "Increment");

$c->idx(3);
is_deeply($c->curr, [d, 2], "Index set");

$c->idx(5);
is_deeply($c->curr, [f, 3], "Index set to last");

is_deeply($c->next, undef, "Next when index set to last");

$c++;

is_deeply($c->curr, [f, 3], "Increment ignored when at last");

done_testing()
