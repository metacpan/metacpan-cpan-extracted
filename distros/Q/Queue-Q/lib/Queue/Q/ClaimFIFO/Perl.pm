package Queue::Q::ClaimFIFO::Perl;
use strict;
use warnings;

use Queue::Q::ClaimFIFO;
use parent 'Queue::Q::ClaimFIFO';

use Carp qw(croak);
use Scalar::Util qw(refaddr blessed);

# Note: items are generally Queue::Q::ClaimFIFO::Item's
use Queue::Q::ClaimFIFO::Item;

sub new {
    my $class = shift;
    my $self = bless {
        @_,
        queue => [],
        claimed => {},
    } => $class;
    return $self;
}

# enqueue_item($single_item)
sub enqueue_item {
    my $self = shift;
    my $item = shift;

    if (blessed($item) and $item->isa("Queue::Q::ClaimFIFO::Item")) {
        croak("Don't pass a Queue::Q::ClaimFIFO::Item object to enqueue_item: "
              . "Your data structure will be wrapped in one");
    }

    $item = Queue::Q::ClaimFIFO::Item->new(item_data => $item);
    push @{$self->{queue}}, $item;

    return $item;
}

# enqueue_items(@list_of_items)
sub enqueue_items {
    my $self = shift;

    my @items;
    for my $item (@_) {
        if (blessed($item) and $item->isa("Queue::Q::ClaimFIFO::Item")) {
            croak("Don't pass a Queue::Q::ClaimFIFO::Item object to enqueue_items: "
                  . "Your data structure will be wrapped in one");
        }
        push @items, Queue::Q::ClaimFIFO::Item->new(item_data => $item);
    }

    push @{$self->{queue}}, @items;
    return @items;
}

# my $item_or_undef = claim_item()
sub claim_item {
    my $self = shift;
    my $item = shift @{ $self->{queue} };
    return undef if not $item;
    $self->{claimed}{refaddr($item)} = $item;
    return $item;
}

# my (@items_or_undefs) = claim_items($n)
sub claim_items {
    my $self = shift;
    my $n = shift || 1;

    my @items = splice(@{ $self->{queue} }, 0, $n);

    my $cl = $self->{claimed};
    for (@items) {
        $cl->{refaddr($_)} = $_;
    }

    return @items;
}

# mark_item_as_done($item_previously_claimed)
sub mark_item_as_done {
    my $self = shift;
    my $item = shift;
    delete $self->{claimed}{refaddr($item)};
    return 1;
}

# mark_item_as_done(@items_previously_claimed)
sub mark_items_as_done {
    my $self = shift;

    foreach (@_) {
        next if not defined $_;
        delete $self->{claimed}{refaddr($_)};
    }

    return 1;
}

sub flush_queue {
    my $self = shift;
    @{ $self->{queue} }   = ();
    %{ $self->{claimed} } = ();
}

# my $nitems = queue_length()
sub queue_length {
    my $self = shift;
    return scalar( @{ $self->{queue} } );
}

# my $nclaimed_items = claimed_count()
sub claimed_count {
    my $self = shift;
    return scalar( keys %{ $self->{claimed} } );
}

1;
__END__

=head1 NAME

Queue::Q::ClaimFIFO::Perl - In-memory Perl implementation of the ClaimFIFO queue

=head1 SYNOPSIS

  use Queue::Q::ClaimFIFO::Perl;
  my $q = Queue::Q::ClaimFIFO::Perl->new;
  
  # producer:
  $q->enqueue_item([qw(my data structure)]); # rinse repeat...
  
  # consumer:
  my $item = $q->claim_item;
  my $data = $item->data;
  # work with data...
  $q->mark_item_as_done($item);
  
  # Implementation dependent. For example:
  # - Fetch claimed items older X
  # - Requeue or log&drop those timed-out items
  # TODO API missing

=head1 DESCRIPTION

Implements interface defined in L<Queue::Q::ClaimFIFO>:
a very simple in-memory implementation using a Perl array
as the queue and Perl hash for keeping track of claimed items.

=head1 METHODS

All methods of C<Queue::Q::ClaimFIFO>.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
