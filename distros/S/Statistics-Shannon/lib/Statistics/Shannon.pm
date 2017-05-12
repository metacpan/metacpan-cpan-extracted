package Statistics::Shannon;

use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.05';

use Statistics::Frequency 0.04;
@ISA = qw(Statistics::Frequency);

my $Napier = exp(1);

=head1 NAME

Statistics::Shannon - Shannon index

=head1 SYNOPSIS

The object-oriented interface:

    use Statistics::Shannon;

    # The constructor is inherited from Statistics::Frequency.

    my $pop = Statistics::Shannon->new(@data);
    my $pop = Statistics::Shannon->new(\@data);
    my $pop = Statistics::Shannon->new(\%data);
    my $pop = Statistics::Shannon->new($another);

    # The Shannon index and the Shannon evenness.
    # The default base uses natural logarithm.

    print $pop->index, "\n";
    print $pop->index($base), "\n";

    print $pop->evenness, "\n";
    print $pop->evenness($base), "\n";

The "anonymous" interface where the population data is not a
Statistics::Frequency object but instead either an array reference,
in which case the array elements are the frequencies, or a hash
reference, in which keys the hash values are the frequencies.

    use Statistics::Shannon;

    print Statistics::Shannon::index([ data ]), "\n";
    print Statistics::Shannon::index([ data ], $base), "\n";

    print Statistics::Shannon::index({ data }), "\n";
    print Statistics::Shannon::index({ data }, $base), "\n";

    print Statistics::Shannon::evenness([ data ]), "\n";
    print Statistics::Shannon::evenness([ data ], $base), "\n";

    print Statistics::Shannon::evenness({ data }), "\n";
    print Statistics::Shannon::evenness({ data }, $base), "\n";

The rest of data manipulation interface inherited from
Statistics::Frequency, see L<Statistics::Frequency>.

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

Statistics::Shannon module can be used to compute the Shannon
index of data, which is a variability measure of data.

The index() and evenness() interfaces are the only genuine interfaces
of this module, the constructor and the rest of the data manipulation
interface is inherited from Statistics::Frequency.

The Shannon index is also known as Shannon-Wiener index and
as Shannon-Weaver index, especially when applied to biology
and ecology and when talking about populations and biodiversity.

=head2 new

    my $pop = Statistics::Shannon->new(@data);
    my $pop = Statistics::Shannon->new(\@data);
    my $pop = Statistics::Shannon->new(\%data);
    my $pop = Statistics::Shannon->new($another);

Creates a new Shannon object from the initial data.

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

If the data is another Statistics::Shannon object, its
frequencies are used.

=back

=head2 index

    $pop->index;
    $pop->index($base);

Return the Shannon index of the data.  The index is
defined as

    $Shannon = -sum($p{$e}*log($p{$e})

where the $p{$e} is the proportional [0,1] frequency of the element $e.
The log() is the natural logarithm: if you want to use some other base,
specify the base.

=head2 evenness

Evenness measures how similar the frequencies are.

    $Evenness = $Shannon / log($NumberOfDifferentElements)

When all the frequencies are equal, evenness is one.  Frequency
imbalance increases the evenness value.

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

=head1 ERRORS

The optional base given to index() and evenness() must naturally
be greater than one.  If not, an error like

    index: base cannot be <= 1.0

will be thrown.

=head1 SEE ALSO

Claude Elwood Shannon is known as the father of information theory:
L<http://www-gap.dcs.st-and.ac.uk/~history/Mathematicians/Shannon.html>
and L<http://www.bell-labs.com/news/2001/february/26/1.html>

For another variability index see

L<Statistics::Simpson>

For the data manipulation interface see (though the whole
interface is documented here)

L<Statistics::Frequency>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2016, Jarkko Hietaniemi <jhi@iki.fi>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.18.2.

=cut

sub index {
    my ($self, $base) = @_;
    if (@_ == 2 && $base <= 1.0) {
	require Carp;
	Carp::croak("index: base cannot be <= 1.0");
    }
    $base ||= $Napier;
    my $shannon = 0;
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
	    $shannon += $prop * log($prop);
	}
	$shannon = -$shannon;
    } else {
	if (!exists $self->{shannon} || !defined $self->{shannon}->{$base}) {
	    my %prop = $self->proportional_frequencies;
	    for my $e (keys %prop) {
		next unless $prop{$e};
		$shannon += $prop{$e} * log($prop{$e});
	    }
	    if (defined $shannon) {
		$shannon = -$shannon;
		$self->{shannon}->{$base} = $shannon;
		$self->_set_update_callback( sub { delete $_[0]->{shannon}->{$base} if exists $_[0]->{shannon} } );
	    }
	}
	$shannon = $self->{shannon}->{$base};
    }
    return @_ == 2 ? $shannon / log($base) : $shannon;
}

sub evenness {
    my ($self, $base) = @_;
    if (@_ == 2 && $base <= 1.0) {
	require Carp;
	Carp::croak("evenness: base cannot be <= 1.0");
    }
    if (ref $self eq 'HASH') {
	$self = [ values %$self ];
    }
    my $a = ref $self eq 'ARRAY';
    my $S = $a ? @$self : $self->elements;
    my $i = $S > 1 ? ( $a ? Statistics::Shannon::index($self) : $self->index ) : undef;
    my $E = $S > 1 ? ( @_ == 2 ? $i * log($base) / log($S) : $i / log($S) ) : undef;
    return defined $E && @_ == 2 ? $E / log($base) : $E;
}

1;
