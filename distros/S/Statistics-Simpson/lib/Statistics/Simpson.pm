package Statistics::Simpson;

use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.03';

use Statistics::Frequency 0.04;
@ISA = qw(Statistics::Frequency);

my $Napier = exp(1);

=head1 NAME

Statistics::Simpson - Simpson index

=head1 SYNOPSIS

The object-oriented interface:

    use Statistics::Simpson;

    # The constructor is inherited from Statistics::Frequency.

    my $pop = Statistics::Simpson->new(@data);
    my $pop = Statistics::Simpson->new(\@data);
    my $pop = Statistics::Simpson->new(\%data);
    my $pop = Statistics::Simpson->new($another);

    # The Simpson index and the Simpson evenness.

    print $pop->index, "\n";

    print $pop->evenness, "\n";

The "anonymous" interface where the population data is not a
Statistics::Frequency object but instead either an array reference,
in which case the array elements are the frequencies, or a hash
reference, in which keys the hash values are the frequencies.

    use Statistics::Simpson;

    print Statistics::Simpson::index([ data ]), "\n";

    print Statistics::Simpson::index({ data }), "\n";

    print Statistics::Simpson::evenness([ data ]), "\n";

    print Statistics::Simpson::evenness({ data }), "\n";

The rest of data manipulation interface inherited from Statistics::Frequency:

    $pop->add_data(@more_data);
    $pop->add_data(\@more_data);
    $pop->add_data(\%more_data);
    $pop->add_data($another);

    $pop->remove_data(@less_data);
    $pop->remove_data(\@less_data);
    $pop->remove_data(\%less_data);
    $pop->remove_data($another);

    $pop->copy_data($another);

    $pop->clear_data();

=head1 DESCRIPTION

Statistics::Simpson module can be used to compute the Simpson
index of data, which measures the variability of data.

The index() and evenness() interfaces are the only genuine interfaces
of this module, the constructor and the rest of the data manipulation
interface is inherited from Statistics::Frequency.

=head2 new

    my $pop = Statistics::Simpson->new(@data);
    my $pop = Statistics::Simpson->new(\@data);
    my $pop = Statistics::Simpson->new(\%data);
    my $pop = Statistics::Simpson->new($another);

Creates a new Simpson object from the initial data.

The data may be either a list, a reference to an array or a reference
to a hash.

=over 4

=item *

If the data is a list (or an array), the list elements are counted
to find out their frequencies.

=item *

If the data is a reference to an array, the array elements are counted
to find out their frequencies.

=item *

If the data is a reference to a hash, the hash keys are the data
elements and the hash values are the data frequencies.

=item *

If the data is another Statistics::Simpson object, its
frequencies are used.

=back

=head2 index

    $pop->index;

Return the Simpson index of the data.  The index is defined as

    $Simpson = 1 / sum($p{$e}**2)

where the $p{$e} is the proportional [0,1] frequency of the element $e.
The value of the index ranges from 1 (the population is dominated by
one kind) to the number of different elements (the population is
evenly divided).

The Simpson index is used in biology and ecology, especially when
talking about populations and biodiversity.

=head2 evenness

Evenness measures how similar the frequencies are.

    $Evenness = $Simpson / $NumberOfDifferentElements

When all the frequencies are equal, evenness is one.  Frequency
imbalance lowers the evenness value.

=head2 add_data

    $pop->add_data(@more_data);
    $pop->add_data(\@more_data);
    $pop->add_data(\%more_data);
    $pop->add_data($another);

Add more data to the object.  The arguments are as in new().

=head2 remove_data

    $pop->remove_data(@less_data);
    $pop->remove_data(\@less_data);
    $pop->remove_data(\%less_data);
    $pop->remove_data($another);

Remove data from the object.  The arguments are as in new().
The frequencies of data elements are gapped at zero.

=head2 copy_data

    $pop->clear_data($another);

Copy all data from another object.  The old data is discarded.

=head2 clear_data

    $pop->clear_data();

Remove all data from the object.

=head1 SEE ALSO

For another variability index see

L<Statistics::Shannon>

For the data manipulation interface see (though the whole
interface is documented here)

L<Statistics::Frequency>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2015, Jarkko Hietaniemi <jhi@iki.fi>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.18.2.

=cut

sub index {
    my ($self) = @_;
    my $simpson = 0;
    if (ref $self eq 'HASH') {
	$self = [ values %$self ];
    }
    if (ref $self eq 'ARRAY') {
	my $total;
	for my $e (@$self) {
	    $total += $e;
	}
	for my $e (@$self) {
	    my $prop = $e / $total;
	    next unless $prop;
	    $simpson += $prop * $prop;
	}
	$simpson = 1 / $simpson if $simpson;
    } else {
	if (!exists $self->{simpson} || !defined $self->{simpson}) {
	    my %prop = $self->proportional_frequencies;
	    for my $e (keys %prop) {
		next unless $prop{$e};
		$simpson += $prop{$e} * $prop{$e};
	    }
	    if ($simpson) {
		$simpson = 1 / $simpson;
		$self->{simpson} = $simpson;
		$self->_set_update_callback( sub { delete $_[0]->{simpson} } );
	    }
	}
	$simpson = $self->{simpson};
    }
    return $simpson;
}

sub evenness {
    my ($self) = @_;
    if (ref $self eq 'HASH') {
	$self = [ values %$self ];
    }
    my $a = ref $self eq 'ARRAY';
    my $S = $a ? @$self : $self->elements;
    my $i = $S ? ( $a ? Statistics::Simpson::index($self) : $self->index ) : undef;
    my $E = $S ? $i / $S : undef;
    return $E;
}

1;
