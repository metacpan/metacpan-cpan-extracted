package Pinwheel::Context;

use strict;
use warnings;


our %context;


sub get
{
    my $key = @_ ? shift : '*' . caller();
    $context{$key} ||= {};
    return $context{$key};
}

sub set
{
    my $key = (@_ & 1) ? shift : '*' . caller();
    my %values = @_;
    $context{$key} = \%values;
}

sub reset
{
    %context = ();
}


=head1 NAME

Context - request-local storage

=head1 SYNOPSIS

    $ctx = Pinwheel::Context::get();
    $ctx = Pinwheel::Context::get('template');

    Pinwheel::Context::set(x => 'foo', y => 'bar', z => 42);
    Pinwheel::Context::set('template', foo => 'bar', baz => 'bal');

    Pinwheel::Context::reset();

=head1 DESCRIPTION

This module provides storage that can be completely emptied with a call to
C<reset()>.  It is used by L<Controller> to provide request-local storage for
modules, and as the mechanism for sharing data between controllers and views.

Contexts are hashes (C<get> returns a reference to a hash).  Multiple contexts
are supported by use of the optional NAMESPACE argument.  Whenever NAMESPACE
is omitted, it defaults to a value generated from the caller's package.

=head1 ROUTINES

=over 4

=item C<get()> or C<get(NAMESPACE)>

Retrieves a context hash.

Examples:

    my $ctx = Pinwheel::Context::get();
    return $ctx->{action};

or

    my $ctx = Pinwheel::Context::get('template');
    return $ctx->{pagetitle};

=item C<set(VALUES)> or C<set(NAMESPACE, VALUES)>

Set one or more values in the context.  The appropriate context is emptied,
then filled with the given VALUES.

Examples:

    Pinwheel::Context::set(x => 1, y => 42);

or

    Pinwheel::Context::set('template', date => $date, message => $msg);
    Pinwheel::Context::set('template', schedule => $schedule);
    # 'date' and 'message' are now gone

=item C<reset()>

Clears all the context information in all namespaces.

=back

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut


1;
