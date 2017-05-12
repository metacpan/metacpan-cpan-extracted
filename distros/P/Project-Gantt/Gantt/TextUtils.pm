##########################################################################
#
#	File:	Project/Gantt/TextUtils.pm
#
#	Author:	Alexander Westholm
#
#	Purpose: Currently contains only one function, which truncates
#		a string to properly fit within a certain number of
#		pixels. In the future, may contain more miscellaneous
#		text manipulation routines.
#
#	Client:	CPAN
#
#	CVS: $Id: TextUtils.pm,v 1.3 2004/08/03 17:56:52 awestholm Exp $
#
########################################################################## 
package Project::Gantt::TextUtils;
use strict;
use warnings;
use Exporter ();
use vars qw[@EXPORT @ISA];

@ISA	= qw[Exporter];

@EXPORT	= qw[
	truncateStr
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
sub truncateStr {
	my @chars	= split //,shift;
	my $pixels	= shift;
	# avg of 6 pixels per char
	my $maxAllow	= int $pixels/6;

	# chop off characters that won't fit into box
	if(($#chars+1) > $maxAllow){
		@chars	= @chars[0..($maxAllow-3)];
		push @chars, ('. .');
	}
	return join('', @chars);
}

1;
