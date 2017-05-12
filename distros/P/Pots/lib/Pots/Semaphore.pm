##########################################################################
#
# Module template
#
##########################################################################
package Pots::Semaphore;

##########################################################################
#
# Modules
#
##########################################################################
use threads;
use threads::shared;

use strict;
use warnings;

##########################################################################
#
# Global variables
#
##########################################################################

##########################################################################
#
# Private methods
#
##########################################################################

##########################################################################
#
# Public methods
#
##########################################################################
sub new {
    my $class = shift;
    my $val : shared = @_ ? shift : 1;

    my %hself : shared = ();
    my $self = bless (\%hself, ref ($class) || $class);

    lock(%{$self});

    $self->{_sem} = \$val;

    return $self;
}

sub down {
    my $self = shift;

    my $ref = $self->{_sem};
    lock($$ref);

    my $inc = @_ ? shift : 1;
    cond_wait $$ref until $$ref >= $inc;
    $$ref -= $inc;
}

sub up {
    my $self = shift;

    my $ref = $self->{_sem};
    lock($$ref);

    my $inc = @_ ? shift : 1;
    ($$ref += $inc) > 0 and cond_broadcast $$ref;
}

1; #this line is important and will help the module return a true value
__END__

=head1 NAME

Pots::Semaphore - Perl ObjectThreads shared thread safe semaphore class

=head1 SYNOPSIS

    use threads;

    use Pots::Semaphore;

    my $s = Pots::Semaphore->new(0);

    sub thread_proc {
        print "Thread waiting for semaphore.\n";
        $s->down();
        print "Thread got semaphore.\n";
    }

    my $th = threads->new("thread_proc");
    sleep(5);

    $s->up();

=head1 DESCRIPTION

This class is a direct revamp of the standard Perl C<Thread::Semaphore>.
It only exists because, for a yet unknown reason, I was unable to store
standard C<Thread::Semaphore> objects in shared accessors.
Once this is worked out, this class will surely disappear.

=head1 METHODS

See C<Thread::Semaphore>.

=head1 AUTHOR and COPYRIGHT

Remy Chibois E<lt>rchibois at free.frE<gt>

Copyright (c) 2004 Remy Chibois. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
