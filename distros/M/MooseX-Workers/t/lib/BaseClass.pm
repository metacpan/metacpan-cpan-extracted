package BaseClass;

use strict;
use warnings;
use Moose;

with qw(MooseX::Workers);

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;

	my %args = @_;

	$args{max_workers} = 20 unless exists $args{max_workers};

	return $class->$orig( %args );
};
	
1;
