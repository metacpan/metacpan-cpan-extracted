package SWISH::Prog::Queue;
use strict;
use warnings;
use base qw( SWISH::Prog::Class );
use Carp;

our $VERSION = '0.75';

=pod

=head1 NAME

SWISH::Prog::Queue - simple in-memory FIFO queue class

=head1 SYNOPSIS

 use SWISH::Prog::Queue;
 my $queue = SWISH::Prog::Queue->new;
 
 $queue->put( 'foo' );
 $queue->size;          # returns number of items in queue (1)
 $queue->peek;          # returns 'foo' (next value for get())
 $queue->get;           # returns 'foo' locks it in queue (no one else can get it)
 $queue->remove('foo'); # returns 'foo' and removes it from queue
 $queue->clean;         # removes all completed items from queue

=head1 DESCRIPTION

SWISH::Prog::Queue is basically a Perl array, but it defines an API
that can be implemented using any kind of storage and logic you want.
One example would be a database that tracks items to be evaluated, or a flat
file list.

=head1 METHODS

See SWISH::Prog::Class.

=cut

=head2 init

Overrides base method.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{q} ||= [];
}

=head2 put( I<item> )

Add I<item> to the queue. Default is to push() it to end of queue.

=cut

sub put {
    my $self = shift;
    push( @{ $self->{q} }, @_ );
}

=head2 get

Returns the next item. Default is to shift() it from the front of the queue.

=cut

sub get {
    my $self = shift;
    $self->{locks} ||= {};
    my $v = shift( @{ $self->{q} } );
    if ( $self->{locks}->{$v}++ ) {
        return undef;
    }
    return $v;
}

=head2 remove( I<item> )

Removes I<item> from the queue (unlocks it).

=cut

sub remove {
    my $self = shift;
    my $v    = shift;
    return delete $self->{locks}->{$v};
}

=head2 clean

Removes all locked items from the queue.

=cut

sub clean {
    my $self = shift;
    delete $self->{locks};
}

=head2 peek

Returns the next item value, but leaves it on the stack.

=cut

sub peek {
    return $_[0]->{q}->[0];
}

=head2 size

Returns the number of items currently in the queue.

=cut

sub size {
    return scalar( @{ $_[0]->{q} } );
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
