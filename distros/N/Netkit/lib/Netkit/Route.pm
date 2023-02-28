package Route;

use strict;
use warnings;

sub new {
	my $class = shift;
	
	my %params = @_;

	my $self = bless {
		dst => $params{dst},
		via => $params{via},
		dev => $params{dev},
	}, $class;

	return $self;
}

sub dump {
	my $class = shift;
	
	print "ip route add $class->{dst} ";
	
	print "via $class->{via} " if(defined $class->{via});
	print "dev $class->{dev} " if(defined $class->{dev});
	
	print "\n";
}

1;
