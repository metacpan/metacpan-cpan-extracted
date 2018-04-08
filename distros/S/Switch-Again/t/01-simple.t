use Test::More;

use Switch::Again qw/all/;

my $switch = switch(
	'a' => sub {
		return 1;
	},
	'b' => sub {
		return 2;
	},
	'c' => sub {
		return 3;
	},
	'default' => sub {
		return 4;
	}
);
my $val = $switch->('a');
is ($val, 1);
$val = $switch->('b');
is ($val, 2);
$val = $switch->('c');
is ($val, 3);
$val = $switch->('d');
is ($val, 4);

$val = switch('e', 
	'd' => sub {
		return 1;
	},
	'e' => sub {
		return 2;
	},
	'f' => sub {
		return 3;
	},
	'default' => sub {
		return 4;
	}
);

is ($val, 2);
$val = $switch->('b');
is ($val, 2);
$val = $switch->('c');
is ($val, 3);
$val = $switch->('d');
is ($val, 4);

done_testing();
