package Project2::Gantt::TextUtils;

use Mojo::Base -strict,-signatures;

use Exporter ();
use vars qw[@EXPORT @ISA];

our $DATE = '2023-02-16'; # DATE
our $VERSION = '0.009';

@ISA	= qw[Exporter];

@EXPORT	= qw[
	truncate
];

##########################################################################
#
#	Function:	truncateStr
#
#	Purpose:	Given a string and an amount of pixels, either
#			returns the string unaltered, or chops some
#			characters off the end so that the string can
#			fit in that amount of pixels when written using
#			a 10 pt font.
#
##########################################################################
sub truncate($string, $pixels) {
	my @chars	= split //,$string;

	# avg of 6 pixels per char
	my $maxAllow	= int $pixels/6;

	# chop off characters that won't fit into box
	if(($#chars+1) > $maxAllow){
		@chars	= @chars[0..($maxAllow-3)];
		push @chars, ('...');
	}
	return join('', @chars);
}

1;
