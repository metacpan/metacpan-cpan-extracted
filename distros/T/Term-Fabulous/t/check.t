use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Clay::XS ();
use Term::Fabulous::Check;

# Called by their full names: Test2::V0 exports a number and a string.
my %check = map { $_ => \&{"Term::Fabulous::Check::$_"} } qw(positive_integer non_negative_integer integer number string boolean glyph color cell_color);

# [ check, value, what it returns ]
my @accepted = (
	[ positive_integer     => '12',                        12 ],
	[ non_negative_integer => 0,                           0 ],
	[ integer              => '-3',                       -3 ],
	[ number               => '2.5',                       2.5 ],
	[ number               => -1e-3,                      -0.001 ],
	[ string               => '',                         '' ],
	[ string               => 42,                         42 ],
	[ boolean              => 'yes',                      1 ],
	[ boolean              => '',                         0 ],
	[ boolean              => undef,                      0 ],
	[ glyph                => "\x{2501}",                 "\x{2501}" ],
	[ glyph                => "e\x{301}",                 "e\x{301}" ],
	[ color                => '#ff8800',                  [ 255, 136, 0,   255 ] ],
	[ color                => [ 1, 2, 3, 4 ],             [ 1,   2,   3,   4 ] ],
	[ color                => { r => 1, g => 2, b => 3 }, [ 1,   2,   3,   255 ] ],
	[ color                => 'steelblue',                [ 70,  130, 180, 255 ] ],
	[ cell_color           => 0x102030,                   [ 16,  32,  48,  255 ] ],
	[ cell_color           => 'rgb(255, 0, 0)',           [ 255, 0,   0,   255 ] ],
);

# [ check, value, the expectation the message names ]
my @rejected = (
	[ positive_integer     => 0,          "a positive integer, got '0'" ],
	[ positive_integer     => '1.5',      "a positive integer, got '1.5'" ],
	[ non_negative_integer => -1,         "a non-negative integer, got '-1'" ],
	[ integer              => 'x',        "an integer, got 'x'" ],
	[ integer              => undef,      'an integer, got undef' ],
	[ number               => 'inf',      "a finite number, got 'inf'" ],
	[ number               => [],         'a finite number, got an ARRAY reference' ],
	[ string               => undef,      'a string, got undef' ],
	[ string               => {},         'a string, got a HASH reference' ],
	[ boolean              => [],         'a plain boolean value, got an ARRAY reference' ],
	[ glyph                => 'ab',       "a single character one column wide, got 'ab'" ],
	[ glyph                => "\x{65E5}", "a single character one column wide, got '\x{65E5}'" ],
	[ color                => 'nope',     "a color, got 'nope' (unrecognized color string 'nope')" ],
	[ color                => undef,      'a color, got undef' ],
	[ cell_color           => 0x1000000,  "a color, got '16777216' (a packed color is at most 0xFFFFFF)" ],
);

foreach my $case (@accepted) {
	my ( $name, $value, $expected ) = @$case;
	is $check{$name}->( 'My::Widget', property => $value ), $expected, "$name accepts " . ( defined $value ? "'$value'" : 'undef' );
}

foreach my $case (@rejected) {
	my ( $name, $value, $expected ) = @$case;
	like dies { $check{$name}->( 'My::Widget', property => $value ) }, qr/\AMy::Widget: property must be \Q$expected\E at /, "$name rejects " . ( defined $value ? "'$value'" : 'undef' );
}

subtest 'sizing' => sub {
	my $sizing = \&Term::Fabulous::Check::sizing;
	is $sizing->( 'My::Widget', width => 'fit(4, 30)' ),            Clay::XS::sizing_fit( 4, 30 ),  'a spec string';
	is $sizing->( 'My::Widget', width => 'percent(25)' ),           Clay::XS::sizing_percent(0.25), 'a percentage';
	is $sizing->( 'My::Widget', width => Clay::XS::sizing_grow() ), Clay::XS::sizing_grow(),        'a hash from Clay::XS is copied';
	like dies { $sizing->( 'My::Widget', width => 'wide' ) },         qr/\AMy::Widget: invalid width 'wide' \(expected grow, fit/, 'an unknown spec dies';
	like dies { $sizing->( 'My::Widget', width => 'fit(5, 2)' ) },    qr/width minimum 5 is greater than maximum 2/,               'a minimum above the maximum dies';
	like dies { $sizing->( 'My::Widget', width => 'percent(101)' ) }, qr/width percentage must be in 0\.\.100/,                    'a percentage above 100 dies';
	like dies { $sizing->( 'My::Widget', width => { kind => 1 } ) },  qr/\AMy::Widget: invalid width: /,                           'an invalid hash dies';
};

subtest 'one_of' => sub {
	my $one_of = \&Term::Fabulous::Check::one_of;
	is $one_of->( 'My::Widget', side => 'left', qw(top right bottom left) ), 'left', 'an allowed word is returned';
	like dies { $one_of->( 'My::Widget', side => 'middle', qw(top right bottom left) ) }, qr/\AMy::Widget: side must be one of bottom, left, right, top, got 'middle' at /,
		'the message lists the allowed words sorted';
	like dies { $one_of->( 'My::Widget', side => undef,   qw(top) ) }, qr/side must be one of top, got undef/,              'undef dies';
	like dies { $one_of->( 'My::Widget', side => ['top'], qw(top) ) }, qr/side must be one of top, got an ARRAY reference/, 'a reference dies';
};

subtest 'border_style' => sub {
	my $border_style = \&Term::Fabulous::Check::border_style;
	my $Style        = 'Term::Fabulous::Enum::BorderStyle';
	ref_is $border_style->( 'My::Widget', style => $Style->Round ), $Style->Round,  'an item';
	ref_is $border_style->( 'My::Widget', style => 'Double' ),      $Style->Double, 'a name';
	like dies { $border_style->( 'My::Widget', style => 'double' ) }, qr/\AMy::Widget: style must be a border style or its name, got 'double' \(known: Ascii, Blank, Block, /,
		'names are case sensitive; the message lists them';
	like dies { $border_style->( 'My::Widget', style => 'none' ) }, qr/style must be a border style or its name, got 'none'/, "'none' only where an option allows it";
	ref_is $border_style->( 'My::Widget', style => 'none', none => $Style->Hidden ), $Style->Hidden, "'none' means what the option says";
	is $border_style->( 'My::Widget', style => 'none', none => undef ), undef, 'also undef';
	like dies { $border_style->( 'My::Widget', style => 'Wavy', none => undef ) }, qr/style must be a border style, its name or 'none', got 'Wavy'/, "the message names 'none' then";
	ref_is $border_style->( 'My::Widget', style => 'Heavy', grid => 1 ), $Style->Heavy, 'a style with joints for a grid';
	like dies { $border_style->( 'My::Widget', style => 'Block', grid => 1 ) },
		qr/style must be a border style with joints or its name, got 'Block' \(known: Ascii, Dashed, Double, Heavy, Round, Solid\)/, 'a grid takes only styles with joints';
	like dies { $border_style->( 'My::Widget', style => undef ) }, qr/style must be a border style or its name, got undef/, 'undef dies';
	like dies { $border_style->( 'My::Widget', style => 'Round', joints => 1 ) }, qr/\ATerm::Fabulous::Check: border_style does not take joints/, 'an unknown option dies';
};

subtest 'value_format' => sub {
	my $value_format = \&Term::Fabulous::Check::value_format;
	my $code         = sub { "$_[0] dB" };
	is $value_format->( 'My::Widget', value_format => undef ),  undef,  'undef: the default format';
	is $value_format->( 'My::Widget', value_format => '%d%%' ), '%d%%', 'a sprintf format';
	ref_is $value_format->( 'My::Widget', value_format => $code ), $code, 'a code reference';
	like dies { $value_format->( 'My::Widget', value_format => [] ) }, qr/\AMy::Widget: value_format must be a sprintf format string or a code reference, got an ARRAY reference at /,
		'anything else dies';
};

subtest 'optional' => sub {
	my $optional = \&Term::Fabulous::Check::optional;
	is $optional->( $check{color}, 'My::Widget', accent => undef ),     undef,              'undef stays undef';
	is $optional->( $check{color}, 'My::Widget', accent => '#ff0000' ), [ 255, 0, 0, 255 ], 'a value is checked';
	like dies { $optional->( $check{color}, 'My::Widget', accent => 'nope' ) }, qr/\AMy::Widget: accent must be a color, got 'nope'/, 'and dies like the check';
	is $optional->( \&Term::Fabulous::Check::one_of, 'My::Widget', side => 'top', qw(top bottom) ), 'top', 'further arguments reach the check';
};

my $owner = bless {}, 'My::Widget';
like dies { $check{string}->( $owner, label => undef ) }, qr/\AMy::Widget: label must be a string/, 'an object owner is named by its class';

is [ map { Term::Fabulous::Check::describe($_) } undef, 'nope', 12, [], {}, \'x' ], [ 'undef', "'nope'", "'12'", 'an ARRAY reference', 'a HASH reference', 'a SCALAR reference' ],
	'describe names values as the messages do';

done_testing;
