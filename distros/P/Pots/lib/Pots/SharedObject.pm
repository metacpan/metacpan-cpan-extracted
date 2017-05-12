##########################################################################
#
# Module template
#
##########################################################################
package Pots::SharedObject;

##########################################################################
#
# Modules
#
##########################################################################
use threads;
use threads::shared;

use strict;

##########################################################################
#
# Global variables
#
##########################################################################
our $VERSION = "0.01";

##########################################################################
#
# Private methods
#
##########################################################################
sub DESTROY {
    my $self = shift;
    my $class = ref($self) || $self;

    return unless threads::shared::_refcnt($self) == 1;

    $self->destroy() if $self->can('destroy');
}

##########################################################################
#
# Public methods
#
##########################################################################

sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my %hself : shared = ();
    my $self = bless (\%hself, $class);

    return $self;
}

sub destroy {
}

1; #this line is important and will help the module return a true value
__END__

=head1 NAME

Pots::SharedObject - Perl ObjectThreads base class for thread shared objects

=head1 SYNOPSIS

package My::Shared::Class;

use base qw(Pots::SharedObject);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    return $self;
}

=head1 DESCRIPTION

C<Pots::SharedObject> is a base class for all Pots objects that need to be
shared between threads.

=head1 METHODS

=over

=item new ()

Standard method for creating a hash-based shared object. If you define your
own "new()" method, don't forget to call "$class->SUPER::new()" before.

=item destroy ()

This method is called when the shared object is being destroyed, that is
no other objects references it. It uses the standard Perl "DESTROY", so
you should not use it in your derived classes. Redefine "destroy()" and
put your cleanup code in it.

=back

=head1 ACKNOWLEDGMENTS

The DESTROY "trick" for shared objects was stolen from Mike Pomraning.
I found it in the "perl.ithreads" list: L<http://www.nntp.perl.org/group/perl.ithreads/766>

=head1 AUTHOR and COPYRIGHT

Remy Chibois E<lt>rchibois at free.frE<gt>

Copyright (c) 2004 Remy Chibois. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

