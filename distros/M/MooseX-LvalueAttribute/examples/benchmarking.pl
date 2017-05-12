use strict;
use warnings;
no warnings 'once';
use Benchmark ':all';

{
	package Goose1;
	use Moose;
	use MooseX::LvalueAttribute 'lvalue';
	
	local $MooseX::LvalueAttribute::INLINE = 0;
	has eggs => (
		traits  => [ lvalue ],
		is      => 'rw',
		default => 0,
	);
}

{
	package Goose2;
	use Moose;
	use MooseX::LvalueAttribute 'lvalue';
	
	has eggs => (
		traits  => [ lvalue ],
		is      => 'rw',
		default => 0,
	);
}

{
	package Goose3;
	use Moose;
	
	has eggs => (
		is      => 'rw',
		default => 0,
	);
}

cmpthese(-3, {
	lv_standard => q{ my $goose = Goose1->new; $goose->eggs++ for 1..1000; die unless $goose->eggs == 1000 },
	lv_inlined  => q{ my $goose = Goose2->new; $goose->eggs++ for 1..1000; die unless $goose->eggs == 1000 },
	nonlv       => q{ my $goose = Goose3->new; $goose->eggs($goose->eggs + 1) for 1..1000; die unless $goose->eggs == 1000 },
});

# RESULTS - adding some inlining has sped things up, but it's still
# a lot slower than non-lvalue accessors

__END__
              Rate lv_standard  lv_inlined       nonlv
lv_standard 8.22/s          --        -73%        -95%
lv_inlined  30.4/s        270%          --        -82%
nonlv        170/s       1968%        460%          --
