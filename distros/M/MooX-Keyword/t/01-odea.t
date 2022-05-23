use Test::More;
use lib 't/lib';
use Odea;
my $odea = Odea->new();
is($odea->okay, 1);
is($odea->other, 2);

$odea = Odea->new(
	okay => 3,
	other => 4
);
is($odea->okay, 3);
is($odea->other, 4);

done_testing();


