package Queue::Q::NaiveFIFO::Perl;
use strict;
use warnings;

use Carp qw(croak);
use Queue::Q::NaiveFIFO;
use parent 'Queue::Q::NaiveFIFO';

sub new {
    my $class = shift;
    my $self = bless {
        @_,
        queue => [],
    } => $class;
    return $self;
}

sub enqueue_item {
    my $self = shift;
    push @{$self->{queue}}, shift;
}

sub enqueue_items {
    my $self = shift;
    push @{$self->{queue}}, @_;
}

sub claim_item {
    my $self = shift;
    return shift @{$self->{queue}};
}

sub claim_items {
    my $self = shift;
    my $n = shift || 1;
    my $q = $self->{queue};
    my @items = splice(@{$self->{queue}}, 0, $n);
    return @items;
}

sub flush_queue {
    my $self = shift;
    @{ $self->{queue} } = ();
}

sub queue_length {
    my $self = shift;
    return scalar(@{ $self->{queue} });
}

1;

__END__

=head1 NAME

Queue::Q::NaiveFIFO::Perl - In-memory Perl implementation of the NaiveFIFO queue

=head1 SYNOPSIS

  use Queue::Q::NaiveFIFO::Perl;
  my $q = Queue::Q::NaiveFIFO::Perl->new;
  $q->enqueue_item("foo");
  my $foo = $q->claim_item;

=head1 DESCRIPTION

Implements interface defined in L<Queue::Q::NaiveFIFO>:
a very simple in-memory implementation using a Perl array
as the queue.

=head1 METHODS

All methods of L<Queue::Q::NaiveFIFO> plus:

=head2 new

Constructor. Takes no parameters.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
