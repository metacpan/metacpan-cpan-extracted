package Net::IPAddress::Util::Collection;

use strict;
use warnings;
use 5.010;

require Net::IPAddress::Util;
require Net::IPAddress::Util::Collection::Tie;
require Net::IPAddress::Util::Range;

our $RADIX_THRESHOLD;

sub new {
    my $class    = ref($_[0]) ? ref(shift()) : shift;
    my @contents = @_;
    my @o;
    tie @o, 'Net::IPAddress::Util::Collection::Tie', \@contents;
    return bless \@o => $class;
}

sub sorted {
    my $self = shift;
    # In theory, a raw radix sort is O(N), which beats Perl's O(N log N) by
    # a fair margin. However, it _does_ discard duplicates, so ymmv.
    my $from = [ map { [ unpack('C32', $_->{ lower }->{ address } . $_->{ upper }->{ address }) ] } @$self ];
    my $to;
    for (my $i = 31; $i >= 0; $i--) {
        $to = [];
        for my $card (@$from) {
            push @{$to->[ $card->[ $i ] ]}, $card;
        }
        $from = [ map { @{$_ // []} } @$to ];
    }
    my @rv = map {
        my $n = $_;
        my $l = Net::IPAddress::Util->new([@{$n}[0 .. 15]]);
        my $r = Net::IPAddress::Util->new([@{$n}[16 .. 31]]);
        my $x = Net::IPAddress::Util::Range->new({ lower => $l, upper => $r });
        $x;
    } @$from;
    return $self->new(@rv);
}

sub compacted {
    my $self = shift;
    my @sorted = @{$self->sorted()};
    my @compacted;
    my $elem;
    while ($elem = shift @sorted) {
        if (scalar @sorted and $elem->{ upper } >= $sorted[0]->{ lower } - 1) {
            $elem = ref($elem)->new({ lower => $elem->{ lower }, upper => $sorted[0]->{ upper } });
            shift @sorted;
            redo;
        }
        else {
            push @compacted, $elem;
        }
    }
    return $self->new(@compacted);
}

sub tight {
    my $self = shift;
    my @tight;
    map { push @tight, @{$_->tight()} } @{$self->compacted()};
    return $self->new(@tight);
}

sub as_cidrs {
    my $self = shift;
    return map { $_->as_cidr() } grep { eval { $_->{ lower } } } @$self;
}

sub as_netmasks {
    my $self = shift;
    return map { $_->as_netmask() } grep { eval { $_->{ lower } } } @$self;
}

sub as_ranges {
    my $self = shift;
    return map { $_->as_string() } grep { eval { $_->{ lower } } } @$self;
}

1;

__END__

=head1 NAME

Net::IPAddress::Util::Collection - A collection of Net::IPAddress::Util::Range objects

=head1 VERSION

Version 3.027

=head1 SYNOPSIS

    use Net::IPAddress::Util::Collection;

    my $collection = Net::IPAddress::Util::Collection->new();

    while (<>) {
        last unless $_;
        push @$collection, $_;
    }

    print join ', ', $collection->tight()->as_ranges();

=head1 DESCRIPTION

=head1 CLASS METHODS

=head2 new

Create a new object.

=head1 OBJECT METHODS

=head2 sorted

Return a clone of this object, sorted ascendingly by IP address.

=head2 compacted

Return a clone of this object, sorted ascendingly by IP address, with
adjacent ranges combined together.

=head2 tight

Return a clone of this object, compacted and split into tight ranges. See
Net::IPAddress::Util::Range for an explanation of "tight" in this context.

=head2 as_ranges

Stringification for (x .. y) style ranges.

=head2 as_cidrs

Stringification for CIDR-style strings.

=head2 as_netmasks

Stringification for Netmask-style strings.

=head1 GLOBAL VARIABLES

=head2 $Net::IPAddress::Util::Collection::RADIX_THRESHOLD

If set to any defined value (including zero), collections with more than
$RADIX_THRESHOLD elements will be sorted using the radix sort algorithm,
which can be faster than Perl's native sort for large data sets. The default
value is C<undef()>.

=cut

