package Switchvox::API::Request;

use strict;
use warnings;
use HTTP::Request;
use XML::Simple;

use base 'HTTP::Request';

our $VERSION = '1.02';

sub new
{
	my ($class,%in)  = @_;
	warn "Missing hostname in call to constructor" unless defined $in{hostname};
	warn "Missing method in call to constructor" unless defined $in{method};

	#- Create new object
	my $self = new HTTP::Request;

	#- Add my variables to object
	$self->{_sv_hostname} 	= $in{hostname};
	$self->{_sv_method}		= $in{method};
	$self->{_sv_parameters} = $in{parameters} || [];
	bless $self, $class;

	$self->method('POST');
	$self->uri('https://' . $self->{_sv_hostname} . '/xml');
	$self->content_type('application/xml');

	#- Create the XML from a data structure
	my $xml_data = { 
		request => {
			method => $self->{_sv_method},
			parameters => $self->{_sv_parameters},
		}
	};
	my $xml = XML::Simple::XMLout($xml_data,KeyAttr => [], ContentKey => '_content', KeepRoot => 1);
	$self->content($xml);
	return $self;
}

1; #- Switchvox Rules!

__END__

=head1 NAME

Switchvox::API::Request - A request to the Switchvox Extend API.

=head1 SYNOPSIS

This class is used internally by the C<Switchvox::API> class and is a subclass
of L<HTTP::Request>.

=head1 AUTHOR

Written by David W. Podolsky <api at switchvox dot com>

Copyright (C) 2009 Digium, Inc

=head1 SEE ALSO

L<Switchvox::API::Request>,
L<Switchvox::API::Response>,
L<http://developers.digium.com/switchvox/>

=cut
