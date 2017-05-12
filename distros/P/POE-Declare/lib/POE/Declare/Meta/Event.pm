package POE::Declare::Meta::Event;

=pod

=head1 NAME

POE::Declare::Meta::Event - Declares a named POE event

=head1 SYNOPSIS

  use POE::Declare;
  
  sub shutdown : Event {
      my $self = $_[SELF];
  
      # Shutdown our child first
      $self->child->post('shutdown');
  
      # Wait for the child to tell us it is finished
      return 1;
  }

=head1 DESCRIPTION

Taking advantage of the subroutine attribute feature of recent versions
of Perl, the C<Event> attribute is used to register a function/method as
an named event that can be targetted by POE.

In an Event, the non-default array constant SELF is used to retrieve
the current object (Since each objects are stored in the session heap,
SELF is actually just an alias for HEAP, but adds some clarity).

=cut

use 5.008007;
use strict;
use warnings;
use POE::Declare::Meta::Slot ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.59';
	@ISA     = 'POE::Declare::Meta::Slot';
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>

=head1 COPYRIGHT

Copyright 2006 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
