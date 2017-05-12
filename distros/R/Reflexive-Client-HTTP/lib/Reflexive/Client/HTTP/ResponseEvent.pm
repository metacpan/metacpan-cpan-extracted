package Reflexive::Client::HTTP::ResponseEvent;
BEGIN {
  $Reflexive::Client::HTTP::ResponseEvent::AUTHORITY = 'cpan:GETTY';
}
{
  $Reflexive::Client::HTTP::ResponseEvent::VERSION = '0.007';
}
# ABSTRACT: A response event of a call with Reflexive::Client::HTTP

use Moose;
extends 'Reflex::Event';


has request => (
	is       => 'ro',
	isa      => 'HTTP::Request',
	required => 1,
);


has response => (
	is       => 'ro',
	isa      => 'HTTP::Response',
	required => 1,
);


has args => (
	is       => 'ro',
	isa      => 'ArrayRef',
	predicate => 'has_args',
);

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;
__END__
=pod

=head1 NAME

Reflexive::Client::HTTP::ResponseEvent - A response event of a call with Reflexive::Client::HTTP

=head1 VERSION

version 0.007

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 request

L<HTTP::Request> object of the event.

=head2 response

L<HTTP::Response> object of the given L</request>.

=head2 args

If arguments are given to the L<Reflexive::Client::HTTP/request> call, then
you can find them in this attribute. If no arguments are given L</has_args>
gives back false and the attribute will be undefined and no ArrayRef.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

