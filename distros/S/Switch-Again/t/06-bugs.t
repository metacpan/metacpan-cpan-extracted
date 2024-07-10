use Test::More;

use Switch::Again qw/all/;

my $val = switch 'e',
        sr('(search)', 'replace') => sub {
                return 1;
        },
        qr/(a|b|c|d|e)/ => sub {
                return 2;
        },
        sub { $_[0] == 1 } => sub {
                return 3;
        },
        'default' => sub {
                return 4;
        }
;

is($val, 2);

$val = switch 'search',
        sr('(search)', 'replace') => sub {
                return $_[1];
        },
        qr/(a|b|c|d|e)/ => sub {
                return 2;
        },
        sub { $_[0] == 1 } => sub {
                return 3;
        },
        'default' => sub {
                return 4;
        }
;

is($val, "replace");

$val = switch 0,
        sr('(search)', 'replace') => sub {
                return 1;
        },
        qr/(a|b|c|d|e)/ => sub {
                return 2;
        },
        sub { $_[0] == 1 } => sub {
                return 3;
        },
        'default' => sub {
                return 4;
        }
;

is($val, 4);

$val = switch 0,
        sr('(search)', 'replace') => sub {
                return 1;
        },
        qr/(a|b|c|d|e)/ => sub {
                return 2;
        },
        sub { $_[0] == 1 } => sub {
                return 3;
        },
	0 => sub {
		return 5;
	},
        'default' => sub {
                return 4;
        }
;

is($val, 5);

done_testing();
