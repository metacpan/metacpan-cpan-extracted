use Test::More;

use Switch::Again qw/all/;

use Data::Dumper;
my $switch = switch(
	qr/(this)(used)(to)(be)(an)(email)/ => sub {
		shift;
		return join '-', @_;
	},
	qr/(a|b|c|d)/ => sub {
		return pop;
	},
	qr/^(34|37)/ => sub {
		return 'AMEX';
	},
	'default' => sub {
		return 'none';
	}
);

my $test = $switch->('341');
is($test, 'AMEX');
$test = $switch->('abc');
is($test, 'a');
$test = $switch->('thisusedtobeanemail');
is($test, 'this-used-to-be-an-email');
$test = $switch->('z');
is($test, 'none');

$switch = switch(
	sr('this', 'again') => sub {
		pop;
	},
	'default' => sub {
		return 'none';
	}
);

$test = $switch->('thisusedtobeanemail');
is($test, 'againusedtobeanemail');

done_testing();
