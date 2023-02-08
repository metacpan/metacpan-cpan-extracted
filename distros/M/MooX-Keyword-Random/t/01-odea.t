use Test::More;

{
	package Corrupt;
	use Moo;
	use MooX::Keyword extends => '+Random';

	random num => 10;

	random char => ['a'..'z'];

	random number => [ 'one', 'two', 'three', 'four' ];
	
	1;
}

my $c = Corrupt->new();
use Data::Dumper;
my $n = $c->num;
like($n, qr/0|1|2|3|4|5|6|7|8|9/, "random $n");
$n = $c->char;
like($n, qr/[a-z]/, "random $n");
$n = $c->number;
like($n, qr/one|two|three|four/, "random $n");

done_testing();

