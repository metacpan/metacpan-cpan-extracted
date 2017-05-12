use strict;
use warnings;
use Benchmark qw(cmpthese);

{
	package Fast;
	use Moose;
	use MooseX::XSAccessor;
	has attr => (is => "rw", isa => "Any");
	__PACKAGE__->meta->make_immutable;
}

{
	package Slow;
	use Moose;
	has attr => (is => "rw", isa => "Any");
	__PACKAGE__->meta->make_immutable;
}

our $Fast = "Fast"->new(attr => 42);
our $Slow = "Slow"->new(attr => 42);

cmpthese(-1, {
	Fast => '$::Fast->attr',
	Slow => '$::Slow->attr',
});

__END__
          Rate Slow Fast
Slow  504123/s   -- -66%
Fast 1487682/s 195%   --
