package PX::API::Response::JSON;
use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

use JSON;

sub new {
	my $class = shift;
	my $args  = shift;

	$class = ref($class) || $class;
	my $self = bless {}, $class;

	$self->{'xs'} = JSON->new();
	return $self;
	}

sub parse {
	my $self = shift;
	my $json = shift;

	my $xs = $self->{'xs'};
	my $ref = $xs->jsonToObj($json);
	return $ref;
	}

sub format { 'json' }


1;
__END__

=head1 NAME

PX::API::Response::JSON - A C<PX::API::Response> plugin.


=head1 DESCRIPTION

This plugin is loaded automagically by C<PX::API::Response> when
the 'json' response format is returned from the Peekshows API.
L<JSON> is used to parse the json object returned from the API call.


=head1 DEPENDENCIES

L<JSON>

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

