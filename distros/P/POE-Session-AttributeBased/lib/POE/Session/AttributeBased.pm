package POE::Session::AttributeBased;
use 5.008000;
use Attribute::Handlers;
require POE::Session;    # for the offset constants

use warnings;
use strict;

=head1 NAME

POE::Session::AttributeBased - POE::Session syntax sweetener

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    #!perl

    package Foo;

    use Test::More tests => 7;

    use POE;
    use base 'POE::Session::AttributeBased';

    sub _start : State {
	my $k : KERNEL;
	my $h : HEAP;

	ok( 1, "in _start" );

	$k->yield( tick => 5 );
    }

    sub tick : State {
	my $k     : KERNEL;
	my $count : ARG0;

	ok( 1, "in tick" );
	return 0 unless $count;

	$k->yield( tick => $count - 1 );
	return 1;
    }

    POE::Session->create(
	Foo->inline_states(),
    );

    POE::Kernel->run();
    exit;

=head1 ABSTRACT

A simple attribute handler mixin that makes POE state easier to keep track of.

=head1 DESCRIPTION

Provides an attribute handler that does some bookkeeping for state
handlers.  There have been a few of these classes for POE.  This
is probably the most minimal.  It supports only the inline attribute syntax.
but that seems sufficient for cranking up a POE session.

=head1 FUNCTIONS

=head2 State

The state hander attribute.  Never called directly.

=cut

my %State;

sub State : ATTR(CODE) {
    my ( $package, $symbol, $code, $attribute, $data ) = @_;

    $State{$package}{ *{$symbol}{NAME} } = $code;
}

=head2 Offset

POE::Session argument offset handler.
This use of the DB module to get extra info from caller might be risky.

=cut

sub Offset {
    my $ref       = $_[2];
    my $attribute = $_[3];

    package DB;
    my @x = caller(5);
    $$ref = $DB::args[ POE::Session->$attribute() ];
}

=head2 OBJECT
=cut
sub OBJECT       : ATTR(SCALAR) { Offset @_; }

=head2 SESSION
=cut

sub SESSION      : ATTR(SCALAR) { Offset @_; }

=head2 KERNEL
=cut
sub KERNEL       : ATTR(SCALAR) { Offset @_; }

=head2 HEAP
=cut
sub HEAP         : ATTR(SCALAR) { Offset @_; }

=head2 STATE
=cut
sub STATE        : ATTR(SCALAR) { Offset @_; }

=head2 SENDER
=cut
sub SENDER       : ATTR(SCALAR) { Offset @_; }

=head2 CALLER_FILE
=cut
sub CALLER_FILE  : ATTR(SCALAR) { Offset @_; }

=head2 CALLER_LINE
=cut

sub CALLER_LINE  : ATTR(SCALAR) { Offset @_; }

=head2 CALLER_STATE
=cut

sub CALLER_STATE : ATTR(SCALAR) { Offset @_; }

=head2 ARG0
=cut

sub ARG0         : ATTR(SCALAR) { Offset @_; }

=head2 ARG1
=cut

sub ARG1         : ATTR(SCALAR) { Offset @_; }

=head2 ARG2
=cut

sub ARG2         : ATTR(SCALAR) { Offset @_; }

=head2 ARG3
=cut

sub ARG3         : ATTR(SCALAR) { Offset @_; }

=head2 ARG4
=cut

sub ARG4         : ATTR(SCALAR) { Offset @_; }

=head2 ARG5
=cut

sub ARG5         : ATTR(SCALAR) { Offset @_; }

=head2 ARG6
=cut

sub ARG6         : ATTR(SCALAR) { Offset @_; }

=head2 ARG7
=cut

sub ARG7         : ATTR(SCALAR) { Offset @_; }

=head2 ARG8
=cut

sub ARG8         : ATTR(SCALAR) { Offset @_; }

=head2 ARG9
=cut

sub ARG9         : ATTR(SCALAR) { Offset @_; }

=head2 inline_states

Returns the list of states in a format that is usable by POE::Session->create.
Can also specify what to return as the hash key so that it is useful in
packages like POE::Component::Server::TCP where the state list has a 
different tag.

=cut

sub inline_states {
    my $tag = $_[1] || 'inline_states';

    return ( $tag => $State{ ( caller() )[0] } );
}

=head1 AUTHOR

Chris Fedde, C<< <cfedde at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-attr at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Session-AttributeBased>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Session::AttributeBased

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Session-AttributeBased>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Session-AttributeBased>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Session-AttributeBased>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Session-AttributeBased>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Chris Fedde, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of POE::Session::AttributeBased
