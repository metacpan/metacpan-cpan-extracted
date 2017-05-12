#*********************************************************************
#*** ResourcePool::Resource::SOAP::Lite
#*** Copyright (c) 2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Lite.pm,v 1.5 2011-01-31 13:49:38 mws Exp $
#*********************************************************************
package ResourcePool::Resource::SOAP::Lite;

use vars qw($VERSION @ISA);
use strict;
use SOAP::Lite;
use ResourcePool::Resource;

$VERSION = "1.0103";
push @ISA, "ResourcePool::Resource";

sub new($$$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();
	my $proxyurl  = shift;

	my $soap;
	eval {
		$soap = SOAP::Lite->new();
		$soap->proxy($proxyurl);
		$self->{soaph} = $soap;
	};

	if (!$@) {
		bless($self, $class);
		return $self;
	} else {
		return undef;
	}
}

sub close($) {
}

sub precheck($) {
	return 1;
}

sub postcheck($) {
	return 1;
}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{soaph};
}

1;
