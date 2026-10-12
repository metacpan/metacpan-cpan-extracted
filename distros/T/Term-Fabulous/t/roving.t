use v5.32;
use warnings;

use Test2::V0;

use Term::Fabulous::Roving qw(roving_target);

# Entries 0 .. 5; 2 and 5 disabled.
my @ENABLED = ( 0, 1, 3, 4 );

subtest 'wrap' => sub {

	# [ current, key, target, what ]
	my @cases = (
		[ 1,     'Right', 3,     'a step skips a disabled entry' ],
		[ 3,     'Left',  1,     'in both directions' ],
		[ 1,     'Down',  3,     'Down steps forward' ],
		[ 3,     'Up',    1,     'Up back' ],
		[ 4,     'Right', 0,     'past the last enabled entry around to the first' ],
		[ 0,     'Left',  4,     'and the other way round' ],
		[ 3,     'Home',  0,     'Home: the first enabled entry' ],
		[ 1,     'End',   4,     'End: the last' ],
		[ undef, 'Right', 0,     'no current entry: forward to the first' ],
		[ undef, 'Left',  4,     'back to the last' ],
		[ 5,     'Right', 0,     'from a disabled entry as from none' ],
		[ 1,     'Tab',   undef, 'another key: undef' ],
		[ 1,     undef,   undef, 'no key: undef' ],
	);
	foreach my $case (@cases) {
		my ( $current, $key, $target, $what ) = @$case;
		is roving_target( \@ENABLED, $current, $key ), $target, $what;
	}
};

subtest 'clamp' => sub {
	is roving_target( \@ENABLED, 4, 'Down', policy => 'clamp', keys => 'vertical' ),            4, 'stops at the last';
	is roving_target( \@ENABLED, 0, 'Up', policy => 'clamp', keys => 'vertical' ),              0, 'and at the first';
	is roving_target( \@ENABLED, 1, 'Down', policy => 'clamp', keys => 'vertical' ),            3, 'and still skips disabled entries';
	is roving_target( \@ENABLED, 0, 'PageDown', policy => 'clamp', keys => 'list', page => 2 ), 3, 'PageDown moves a page of enabled entries';
	is roving_target( \@ENABLED, 1, 'PageDown', policy => 'clamp', keys => 'list', page => 9 ), 4, 'no further than the last';
	is roving_target( \@ENABLED, 4, 'PageUp', policy => 'clamp', keys => 'list', page => 9 ),   0, 'or the first';
};

subtest 'the keys of a kind' => sub {
	is roving_target( \@ENABLED, 1, 'Right', keys => 'vertical' ),      undef, 'vertical: no Left and Right';
	is roving_target( \@ENABLED, 1, 'PageDown' ),                       undef, 'arrows: no PageUp and PageDown';
	is roving_target( \@ENABLED, 1, 'Ctrl+PageDown', keys => 'pages' ), 3,     'pages: Ctrl+PageDown steps';
	is roving_target( \@ENABLED, 1, 'Home', keys => 'pages' ),          undef, 'and nothing else';
};

subtest 'nothing enabled, invalid options' => sub {
	is roving_target( [], 0, 'Right' ), undef, 'no enabled entry: undef';
	is roving_target( [], 0, 'Home' ),  undef, 'also for Home';
	like dies { roving_target( \@ENABLED, 0, 'Up', policy => 'bounce' ) },   qr/policy must be wrap or clamp, got 'bounce'/,                       'an unknown policy dies';
	like dies { roving_target( \@ENABLED, 0, 'Up', keys   => 'diagonal' ) }, qr/unknown keys 'diagonal' \(known: arrows, list, pages, vertical\)/, 'unknown keys die';
	like dies { roving_target( \@ENABLED, 0, 'Up', step   => 2 ) },          qr/roving_target does not take step/,                                 'unknown options die';
};

done_testing;
