#*********************************************************************
#*** ResourcePool::Resource
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Resource.pm,v 1.32 2013-04-16 10:14:44 mws Exp $
#*********************************************************************

package ResourcePool::Resource;

use strict;
use vars qw($VERSION);

$VERSION = "1.0107";

sub new($@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{PR} = $self;
	$self->{ARGUMENT} = shift;
	$self->{VALID} = 1;

	bless($self, $class);

	return $self;
}

sub close($) {
	return undef;
}

sub fail_close($) {
	warn "ResourcePool::Resource: closing failed Resource\n";
	return undef;
}

sub precheck($) {
	return $_[0]->{VALID};
}

sub postcheck($) {
	return $_[0]->{VALID};
}

sub get_plain_resource($) {
	return $_[0]->{PR};
}

### ### Private part starts here

sub _my_very_private_and_secret_test_hook($$) {
	$_[0]->{VALID} = $_[1];
}

1;
