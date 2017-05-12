use Test::Core;

BEGIN {
	package XXX;
	sub xxx { 1 }
	$INC{'XXX.pm'} = __FILE__;
};

BEGIN {
	package YYY;
	our @ISA = 'XXX';
	sub yyy { 2 }
	$INC{'YYY.pm'} = __FILE__;
};

*UNIVERSAL::DOES = \&UNIVERSAL::isa
	unless exists(&UNIVERSAL::DOES);

my $return = object_ok(
	sub { bless [], 'YYY' },
	'$y',
	isa   => 'YYY',
	does  => [qw/ XXX YYY /],
	can   => [qw/ xxx /],
	api   => [qw/ xxx yyy /],
	clean => 1,
	more  => sub {
        my $object = shift;
        is $object->xxx => 1;
        is $object->yyy => 2;
	},
);

isa_ok($return, 'YYY', '$return');

done_testing;
