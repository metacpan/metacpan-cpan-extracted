##########################################################################
#
#	File:	Project/Gantt/Resource.pm
#
#	Author:	Alexander Westholm
#
#	Purpose: Data class representing a resource associated with a
#		task. Doesn't really have too much functionality at this
#		point. May contain more later.
#
#	Client: CPAN
#
#	CVS: $Id: Resource.pm,v 1.2 2004/08/02 06:14:41 awestholm Exp $
#
##########################################################################
package Project::Gantt::Resource;
use strict;
use warnings;
use vars qw[$AUTOLOAD];

##########################################################################
#
#	Method: new(%opts)
#
#	Purpose: Constructor. Takes as parameters the name, title, email
#		function, phone and url of a resource. Currently, the
#		name is really all that is used. That may change.
#
##########################################################################
sub new {
	my $class	= shift;
	my %opts	= @_;
	if(not $opts{name}){
		die "Resource must have a name!"
	}
	return bless \%opts, $class;
}

sub getName {my $me = shift; return $me->{name} }

# unused
sub resourceLink {
	my $me		= shift;
	my $link	= shift;
	$link = $me->{email} if $me->{email};
	$link = $me->{url} if not $link;
	return if not $link;
	return "<a href=\"mailto:$me->{email}\">$me->{name}</a>";
}

sub AUTOLOAD {
	my $me		= shift;
	my $data	= shift;
	my $instVar	= $AUTOLOAD;
	$instVar	=~ s/.*:://;
	$me->{$instVar}	= $data if defined $data;
	return $me->{instVar};
}

1;
