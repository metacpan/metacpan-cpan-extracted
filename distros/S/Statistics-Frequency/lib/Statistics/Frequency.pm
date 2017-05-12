package Statistics::Frequency;

use strict;

use vars qw($VERSION);

$VERSION = '0.04';

sub elements {
    my $self = shift;
    exists $self->{data} ? keys %{$self->{data}} : wantarray ? () : undef;
}

sub frequency {
    my ($self, $e) = @_;
    exists $self->{data} ? $self->{data}->{$e} : 0;
}

sub add_data {
    my $self = shift;
    my $mod;  
    for my $data (@_) {
	my $ref = ref $data;
	if ($ref eq ref $self) {
	    for my $e ($data->elements) {
		$self->{data}->{$e} += $data->frequency($e);
		$mod++;
	    }
	} if ($ref eq 'HASH') {
	    for my $e (keys %{$data}) {
		$self->{data}->{$e} += $data->{$e};
		$mod++;
	    }
	} elsif ($ref eq 'ARRAY') {
	    $self->add_data(@$data);
	} else {
	    $self->{data}->{$data}++;
	    $mod++;
	}
    }
    if ($mod) {
	delete @{$self}{qw(sum min max)};
	$self->{update}->($self) if exists $self->{update};
    }
    return $self;
}

sub _set_update_callback {
    my ($self, $callback) = @_;
    $self->{update} = $callback;
}

sub remove_data {
    my $self = shift;
    my $mod;
    for my $data (@_) {
	my $ref = ref $data;
	if ($ref && $data->isa(ref $self)) {
	    for my $e ($data->elements) {
		$self->{data}->{$e} -= $data->frequency($e);
		$mod++;
	    }
	} if ($ref eq 'HASH') {
	    for my $e (keys %{$data}) {
		$self->{data}->{$e} -= $data->{$e};
		$mod++;
	    }
	} elsif ($ref eq 'ARRAY') {
	    for my $e (@{$data}) {
		$self->{data}->{$e}--;
		$mod++;
	    }
	} else {
	    $self->{data}->{$data}--;
	    $mod++;
	}
	for my $e ($self->elements) {
	    delete $self->{data}->{$e} if $self->{data}->{$e} <= 0;
	}
    }
    if ($mod) {
	delete @{$self}{qw(sum min max)};
	$self->{update}->($self) if exists $self->{update};
    }
    return $self;
}

sub remove_elements {
    my $self = shift;
    my $mod;
    for my $e (@_) {
	delete $self->{data}->{$e};
	$mod++;
    }
    if ($mod) {
	delete $self->{data} unless keys %{$self->{data}};
	delete @{$self}{qw(sum min max)};
	$self->{update}->($self) if exists $self->{update};
    }
    return $self;
}

sub clear_data {
    my $self = shift;
    delete $self->{data};
    delete @{$self}{qw(sum min max)};
    $self->{update}->($self) if exists $self->{update};
    return $self;
}

sub copy_data {
    my $self = shift;
    my $copy = (ref $self)->new;
    $copy->add_data($self->{data});
    return $copy;
}

sub frequencies {
    my $self = shift;
    exists $self->{data} ? %{$self->{data}} : ();
}

sub _frequencies_stats {
    my $self = shift;
    unless (exists $self->{sum}) {
	my $sum;
	my $min;
	my $max = $min =
	    exists $self->{data} ?
		$self->{data}->{each %{$self->{data}}} : undef;
	for my $f (values %{$self->{data}}) {
	    $sum += $f;
	    if ($f < $min) { $min = $f } elsif ($f > $max) { $max = $f }
	}
	$self->{sum} = $sum;
	$self->{min} = $min;
	$self->{max} = $max;
    }
}

sub frequencies_sum {
    my $self = shift;
    $self->_frequencies_stats unless exists $self->{sum};
    return $self->{sum};
}

sub frequencies_min {
    my $self = shift;
    $self->_frequencies_stats unless exists $self->{min};
    return $self->{min};
}

sub frequencies_max {
    my $self = shift;
    $self->_frequencies_stats unless exists $self->{max};
    return $self->{max};
}

sub proportional_frequencies {
    my $self = shift;
    my %prop = $self->frequencies;
    my $sum = $self->frequencies_sum;
    for my $e (keys %prop) { $prop{$e} /= $sum }
    return %prop;
}

sub proportional_frequency {
    my ($self, $e) = @_;
    my $freq  = $self->frequency($e);
    my $sum = $self->frequencies_sum;
    defined $freq && $sum ? $freq / $sum : undef;
}

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->add_data(@_);
    return $self;
}

1;
__END__
=head1 NAME

Statistics::Frequency - simple counting of elements

=head1 SYNOPSIS

    use Statistics::Frequency;

    my $f1  = Statistics::Frequency->new;

    $f1->add_data(  @data );
    $f1->add_data( \@data );
    $f1->add_data( \%data );

    my @list_of_different_elements   = $f1->elements;
    my $number_of_different_elements = $f1->elements;

    my $freq = $f1->frequency('x');

    my $f2a = Statistics::Frequency->new(  @data ); # a list
    my $f2b = Statistics::Frequency->new( \@data ); # an arrayref
    my $f2c = Statistics::Frequency->new( \%data ); # a hashref

    $f->remove_data(  @data );
    $f->remove_data( \@data );
    $f->remove_data( \%data );

    $f->remove_elements('y');

    $f->clear_data;

    my $g = $f->copy_data;

    my %freq = $f->frequencies;

    my $sum = $f->frequencies_sum;
    my $min = $f->frequencies_min;
    my $max = $f->frequencies_max;

    my %prop = $f->proportional_frequencies;

    my $prop = $f->proportional_frequency('z');

=head1 DESCRIPTION

Statistics::Frequency is a simple class for counting I<elements>,
in other words, their I<frequencies>.

Note that Statistics::Frequency is not similar to statistics modules
like, say, Statistics::Descriptive.  Statistics::Frequency doesn't
operate on numbers, it operates on I<elements>, which are basically
opaque strings.  Therefore there can't be, say, "an average" of the
elements.

The goal of Statistics::Frequency is simply to be provide container
for sets of elements and their respective frequencies.

=head2 new

    my $freq = Statistics::Frequency->new;
    my $freq = Statistics::Frequency->new(@data);
    my $freq = Statistics::Frequency->new(\@data);
    my $freq = Statistics::Frequency->new(\%data);

Create a new Statistics::Frequency object.  The object can be either
empty or a list of elements can be given.  See L</add_data> for details.

=head2 elements

    my @elements = $freq->elements;
    my $elements = $freq->elements;

=over 4

=item *

In array context, return the elements.

=item *

In scalar context, return the number of elements.

=back

=head2 frequency

    $f = $freq->frequency($element);

Return the frequency of an element.

=head2 add_data

    $freq->add_data(@data);
    $freq->add_data(\@data);
    $freq->add_data(\%data);

=over 4

=item *

If an element of the argument list is another frequency object, the
frequencies in the invocant object of the elements are increased by
the frequencies in the argument object.

=item *

If an element is an array reference, add_data() is called recursively
with the elements of the array behind the reference.

=item *

If an element is a hash reference, the keys are assumed to be elements
and the value are assumed to be their frequencies.

=item *

Otherwise an element is just an ordinary element and its frequency
is incremented by one.

=back

=head2 remove_data

    $freq->remove_data(@data);
    $freq->remove_data(\@data);
    $freq->remove_data(\%data);

Remove elements, arguments as with with add_data().

=head2 remove_elements

    $freq->remove_elements( @elements );

Remove elements and their respective frequencies.

=head2 clear_data

    $freq->clear_data;

Clear all the data in a frequency object.

=head2 copy_data

    my $copy = $freq->copy_data;

Create a copy of a frequency object.

=head2 frequencies

    my %freq = $freq->frequencies;

Return the frequencies as a hash, the elements as the keys and the
frequencies as the values.

=head2 frequencies_sum

    my $sum = $freq->frequencies_sum;

Return the sum of all the frequencies.

=head2 frequencies_min

    my $sum = $freq->frequencies_min;

Return the minimum of all the frequencies.

=head2 frequencies_max

    my $sum = $freq->frequencies_max;

Return the maximum of all the frequencies.

=head2 proportional_frequencies

    my %freq = $freq->proportional_frequencies;

Return the proportional frequencies as a hash, the elements as the
keys and the frequencies as the values.  Proportional meaning that
proportional frequencies total 1.0, in other words, each of the
frequencies of elements are divided by the sum of all the frequencies.

=head2 proportional_frequency

    my $f = $freq->proportional_frequency($element);

Return the proportional frequency of the element.

=head1 SEE ALSO

L<Statistics::Descriptive>, L<Statistics::Descriptive::Discrete>

=head1 AUTHOR

Jarkko Hietaniemi <jhi@iki.fi>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2015, Jarkko Hietaniemi <jhi@iki.fi>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.18.2.

=cut
