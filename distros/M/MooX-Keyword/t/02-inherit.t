use Test::More;
use lib 't/lib';
use Inherit::Odea;
my $odea = Inherit::Odea->new();
is($odea->okay, 1);
is($odea->other, 2);
is($odea->works, undef);

$odea = Inherit::Odea->new(
	okay => 3,
	other => 4,
	works => 5,
);
is($odea->okay, 3);
is($odea->other, 4);
is($odea->works, 5);

done_testing();


