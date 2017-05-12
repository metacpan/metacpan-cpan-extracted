package Statistics::TopK;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.02';
$VERSION = eval $VERSION;

use constant _K      => 0;
use constant _COUNTS => 1;
use constant _ELEMS  => 2;
use constant _SIZE   => 3;
use constant _INDEX  => 4;

sub new {
    my ($class, $k) = @_;

    croak 'expecting a positive integer'
        unless defined $k and $k =~ /^\d+$/ and $k > 0;

    my $self = [
        $k,  # _K
        {},  # _COUNTS
        [],  # _ELEMS
        0,   # _SIZE
        0,   # _INDEX
    ];

    # Pre-extend the internal data structures, just in case $k is large.
    keys %{ $self->[_COUNTS] } = $k;
    $#{ $self->[_ELEMS] } = $k - 1;

    return bless $self, $class;
}

sub add {
    my ($self, $elem) = @_;

    # Increment the element's counter if it is currently being counted.
    if (exists $self->[_COUNTS]{$elem}) {
        return $self->[_COUNTS]{$elem} += 1;
    }

    # Add the element if it's not being counted and there are free slots.
    if ($self->[_SIZE] < $self->[_K]) {
        $self->[_ELEMS][ $self->[_SIZE]++ ] = $elem;
        return $self->[_COUNTS]{$elem} = 1;
    }

    # Decrement one of the currently counted elements.
    my $index = $self->[_INDEX];
    my $prev  = $self->[_ELEMS][$index];
    my $count = $self->[_COUNTS]{$prev} -= 1;

    # Advance the counter.
    $self->[_INDEX] = ++$self->[_INDEX] % $self->[_K];

    # If the count of the decremented element reaches 0, replace it with the
    # current element.
    if (0 == $count) {
        delete $self->[_COUNTS]{$prev};

        $self->[_ELEMS][$index] = $elem;

        return $self->[_COUNTS]{$elem} = 1;
    }

    # This element is not currently being counted.
    return 0;
}

sub top {
    return keys %{$_[0]->[_COUNTS]};
}

sub counts {
    return %{$_[0]->[_COUNTS]};
}


1;

__END__

=head1 NAME

Statistics::TopK - Implementation of the top-k streaming algorithm

=head1 SYNOPSIS

    use Statistics::TopK;

    my $counter = Statistics::TopK->new(10);
    while (my $val = <STDIN>) {
        chomp $val;
        $counter->add($val);
    }
    my @top = $counter->top;
    my %counts = $counter->counts;

=head1 DESCRIPTION

The C<Statistics::TopK> module implements the top-k streaming algorithm,
also know as the "heavy hitters" algorithm. It is designed to process
data streams and probabilistally calculate the C<k> most frequent items
while using limited memory.

A typical example would be to determine the top 10 IP addresses listed in an
access log. A simple solution would be to hash each IP address to a counter
and then sort the resulting hash by the counter size. But the hash could
theoretically require over 4 billion keys.

The top-k algorithm only requires storage space proportional to the number
of items of interest. It accomplishes this by sacrificing precision, as
it is only a probabilistic counter.

=head1 METHODS

=head2 new

    $counter = Statistics::TopK->new($k)

Creates a new C<Statistics::TopK> object which is prepared to count the top
C<$k> elements.

=head2 add

    $count = $counter->add($element)

Count the given C<$element> and return its approximate count (if any) in the
C<Statistics::TopK> object.

Note that adding an element does not guarantee it will be counted yet,
as the algorithm is probabilistic, and the occurrence of the current element
might only be used decrease the count of one of the current top elements.

=head2 top

    @top = $counter->top()

Returns a list of the top-k counted elements.

=head2 counts

    %counts = $counter->counts()

Returns a hash of the top-k counted elements and their counts.

=head1 SEE ALSO

http://en.wikipedia.org/wiki/Streaming_algorithm#Heavy_hitters

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Statistics-TopK>. I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::TopK

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/statistics-topk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-TopK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-TopK>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Statistics-TopK>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-TopK/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
