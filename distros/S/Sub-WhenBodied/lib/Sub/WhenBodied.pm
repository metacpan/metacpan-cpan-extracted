=head1 NAME

Sub::WhenBodied - delay action until subroutine acquires body

=head1 SYNOPSIS

	use Sub::WhenBodied qw(when_sub_bodied);

	when_sub_bodied($sub, sub { mutate_sub_foo($_[0], ...) });

=head1 DESCRIPTION

This module provides a facility to delay an action on a subroutine until
the subroutine's body (the code that will be run when the subroutine
is called) has been attached to the subroutine object.  This is mainly
useful in implementing subroutine attributes, where the implementation
needs to operate on the subroutine's body.

This facility is required due to an oddity of how Perl constructs
Perl-language subroutines.  A subroutine object is initially created
with no body, and then the body is later attached.  Prior to Perl 5.15.4,
attribute handlers are executed before the body is attached, so see it in
that intermediate state.  (From Perl 5.15.4 onwards, attribute handlers
are executed after the body is attached.)  It is otherwise unusual to
see the subroutine in that intermediate state.  If the implementation
of an attribute can only be completed after the body is attached, this
module is the way to schedule the implementation.

=cut

package Sub::WhenBodied;

{ use 5.008; }
use warnings;
use strict;

our $VERSION = "0.000";

use parent "Exporter";
our @EXPORT_OK = qw(when_sub_bodied);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 FUNCTIONS

=over

=item when_sub_bodied(SUB, ACTION)

I<SUB> must be a reference to a subroutine.  This function queues
a modification of the subroutine, to occur when the subroutine has
acquired a body.  I<ACTION> must be a reference to a function, which will
eventually be called, with one argument, a reference to the subroutine to
act on.  The subroutine passed to I<ACTION> is not necessarily the same
object as the original I<SUB>: some subroutine construction sequences
cause the partially-built subroutine to move from one object to another
part way through, and a pending action will move with it.

If this function is called when I<SUB> is in the half-constructed state,
with body not yet attached, then I<ACTION> is added to a per-subroutine
queue.  Shortly after a body is attached to I<SUB>, the queued actions
are performed.

If this function is called when I<SUB> already has a body, the action
will be performed immediately, or nearly so.  Actions are always
performed sequentially, in the order in which they were queued, so if
an action is requested while another action is already executing then
the newly-requested action will have to wait until the executing one
has finished.

If a subroutine with pending actions is replaced, in the same subroutine
object, by a new subroutine, then the queue of pending actions is
discarded.  This occurs in the case of a so-called "forward declaration",
such as "C<sub foo ($);>".  The declaration creates a subroutine with
no body, to influence compilation of calls to the subroutine, and it
is intended that the empty subroutine will later be replaced by a full
subroutine which has a body.

=back

=head1 BUGS

The code is an ugly hack.  Details of its behaviour may change in future
versions of this module, if better ways of achieving the desired effect
are found.

Before Perl 5.10, C<when_sub_bodied> has a particular problem with
redefining subroutines.  A subroutine redefinition, including if the
previous definition had no body (a pre-declaration), is the situation
that causes a partially-built subroutine to move from one subroutine
object to another.  On pre-5.10 Perls, it is impossible to locate the
destination object at the critical point in this process, and as a result
any pending actions are lost.

=head1 SEE ALSO

L<Attribute::Lexical>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011, 2013, 2015
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
