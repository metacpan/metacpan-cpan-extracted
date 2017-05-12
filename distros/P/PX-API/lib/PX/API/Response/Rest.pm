package PX::API::Response::Rest;
use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

use XML::Simple;

sub new {
	my $class = shift;
	my $args  = shift || {};

	$class = ref($class) || $class;
	my $self = bless {}, $class;
	$self->{'xs'} = XML::Simple->new(KeepRoot => 1, KeyAttr => []);
	return $self;
	}

sub parse {
	my $self = shift;
	my $xml  = shift;

	my $xs = $self->{'xs'};
	my $ref = $xs->XMLin($xml);
	return $ref;
	}

sub format { 'rest' }


1;
__END__

=head1 NAME

PX::API::Response::Rest - A C<PX::API::Response> plugin module.


=head1 DESCRIPTION

This plugin is loaded automagically by C<PX::API::Response> when
the 'rest' response format is returned from the Peekshows API.
L<XML::Simple> is used to parse the xml returned from the API call.


=head1 DEPENDENCIES

L<PX::API::Response>
L<XML::Simple>

=head1 SEE ALSO

L<PX::API>
L<http://www.peekshows.com>
L<http://services.peekshows.com>

=head1 AUTHOR

Anthony Decena  C<< <anthony@1bci.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Anthony Decena C<< <anthony@1bci.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
