package Statistics::RVector;

use strict;
use warnings;
use Carp ();

require Exporter;

our @ISA = qw(Exporter);

use Math::Complex;

our $VERSION = 0.1;
our @EXPORT = qw(rv);
our @EXPORT_OK = qw(rv);
our %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = [@EXPORT_OK];

use overload 
    '@{}' => 'as_array',
    '""' => 'to_string',
    '+' => 'vectoradd',
    '*' => 'vectormult',
    '-' => 'vectorsub',
    '/' => 'vectordiv',
    '**' => 'vectorpower';

=head1 NAME

Statistics::RVector - Mathematical/statistical vector implementation mimicking that of R stats

=head1 DESCRIPTION

The RVector class is a perl implementation of the base R stats language mathematical 
vector to enable better statistical/numerical/mathematical analysis of data in Perl.
This implementation is still very beta, but should work sufficiently for vector 
arithmetic (+,-,*,/,**), as well as calculating sum(), mean(), var(), and sd(), which 
are the sum of the values, the mean of the values, the variance of the sample, and 
the standard deviation of the sample..

=head1 SYNOPSIS

	use Statistics::RVector;
	my $x = rv(10.4, 5.6, 3.1, 6.4, 21.7);
	my $y = Statistics::RVector->new($vector1,0,$vector1);
	my $v = 2 * $x + $y + 1

=head1 EXPORT

Exports the function rv() by default, which is a shortened form of 
Statistics::RVector->new().

=head1 TODO

* Handle non-numerical and/or invalid (i.e. division by zero) cases in all 
functions.

* Add support for naming of entries in the vector.

* Lots of other things that I still don't understand about R that I'm sure other people
will want to use.

=head1 METHODS

=head2 VECTOR CREATION 

=head3 Statistics::RVector->new() / rv()

Creates a new RVector object.  For example, syntax of rv(10,17,24) would create a 
vector containing 3 entries of 10, 17, and 24 in that order.

=cut

sub new {
    my ($class, @entries) = @_;
    my $vector = {
        vals => [],
        names => [],
        namemap => {},
    };
    bless $vector, $class;
    foreach my $entry (@entries) {
        $vector->add_value($entry);
    }
    return $vector;
}

sub rv {
    my (@entries) = @_;
    return Statistics::RVector->new(@entries);
}

=head3 $vector->add_value($val,[$name])

Adds a new entry to the vector in question, including an (optional) name to be added
to the name table to fetch the value

=cut

sub add_value {
    my ($self, $value, $name) = @_;
    if (defined $name && $self->{namemap}->{$name}) {
        # Already exists... do we warn and rename, or bail?
        # Fix name?
    }
    if (ref($value) && ref($value) eq ref($self)) {
        # Another vector to concatenate.  Recursively call on all values.
        for (my $i = 0; $i < $value->length(); $i++) {
            $self->add_value($value->[$i],$value->name($i));
        }
    } else {
        push(@{$self->{vals}},$value);
        push(@{$self->{names}},defined $name ? $name : undef);
        $self->{namemap}->{$name} = scalar(@{$self->{vals}}) - 1 if $name;
    }
}

=head3 $vector->name($index)

Returns the name of a given index in the vector, if given.

=cut

sub name {
    my ($self, $i) = @_;
    return $self->{names}->[$i];
}

=head2 VECTOR MODIFICATION/DUPLICATION OPERATIONS

Below are functions which allow for modification and/or duplication of a vector.
These operations will result in either a modification to the existing vector, or 
the return of a new vector altogether.

=head3 $vector->clone()

Returns an exact copy of the original vector in different memory.
Allows for modification without affecting the original vector.

=cut

sub clone {
    my ($self) = @_;
    my $return = rv();
    for (my $i = 0; $i < $self->length(); $i++) {
        $return->add_value($self->[$i],$self->name($i));
    }
    return $return;
}

=head3 $vector->extend($len)

Extends the length of the given vector to length $len, filling all new values with 
repeated values from the existing array in the same offsets.

For example, an rv(1,2,3) that is extended to 8 will then be rv(1,2,3,1,2,3,1,2).

=cut

sub extend {
    my ($self, $newlen) = @_;
    my $prevsize = scalar(@{$self->{vals}});
    my $nextspot = 0;
    for (my $i = $prevsize; $i < $newlen; $i++) {
        $self->add_value($self->{vals}->[$nextspot]);
        $nextspot++;
    }
    return 1;
}

=head2 VECTOR INSPECTION OPERATIONS

Below are the various operations that you can perform on a single vector object.
They will return in most cases numerical values unless otherwise specified.  They
do not in any way change the vector, nor create any new vectors.

=cut

=head3 $vector->length()

Returns the integer length of the vector.

=cut

sub length {
    my ($self) = @_;
    return scalar(@{$self->{vals}});
}

=head3 $vector->range()

Returns a vector holding the largest and smallest values in the specified vector.

=cut

sub range {
    my ($self) = @_;
    return rv(undef,undef) unless $self->length();
    my ($min,$max) = ($self->[0],$self->[0]);
    for (my $i = 1; $i < $self->length(); $i++) {
        $min = $self->[$i] if $self->[$i] < $min;
        $max = $self->[$i] if $self->[$i] > $max;
    }
    return rv($min,$max);
}

=head3 $vector->max()

Returns the maximum value in the vector.

=cut

sub max {
    my ($self) = @_;
    my $range = $self->range();
    return $range->[1];
}

=head3 $vector->min()

Returns the minimum value in the vector.

=cut

sub min {
    my ($self) = @_;
    my $range = $self->range();
    return $range->[0];
}

=head3 $vector->sum()

Returns the arithmetic sum of all entries in the vector.

=cut

sub sum {
    my ($self) = @_;
    my $ret = 0;
    for (my $i = 0; $i < $self->length(); $i++) {
        $ret += $self->[$i];
    }
    return $ret;
}

=head3 $vector->prod()

Returns the arithmetic product of all the entries in the vector.

=cut

sub prod {
    my ($self) = @_;
    return unless $self->length();
    my $ret = $self->[0];
    for (my $i = 1; $i < $self->length(); $i++) {
        $ret *= $self->[$i];
    }
    return $ret;
}

=head3 $vector->mean()

Returns the arithmetic mean of the vector values.

=cut

sub mean {
    my ($self) = @_;
    return unless $self->length();
    return $self->sum() / $self->length();
}

=head3 $vector->var()

Returns the sample variance of the vector values.

=cut

sub var {
    my ($self) = @_;
    my $top = ($self - $self->mean()) ** 2;
    return $top->mean();
}

=head3 $vector->sd()

Returns the sample standard deviation of the vector values.

=cut

sub sd {
    my ($self) = @_;
    return sqrt($self->var());
}

=head2 DEREFERENCING/ARITHMETIC OVERLOADS

=head3 as_array($vector)

Returns an array reference to the values in the vector.

=cut

sub as_array {
    my ($self) = @_;
    return $self->{vals};
}

=head3 to_string($vector)

Returns a pretty-printed string of the vector values

=cut

sub to_string {
    my ($self) = @_;
    my $string = sprintf('rv(%s)',join(', ',@{$self->{vals}}));
    return $string;
}

=head3 vectoradd($val1,$val2,$switch)

=head3 vectorsub($val1,$val2,$switch)

=head3 vectormult($val1,$val2,$switch)

=head3 vectordiv($val1,$val2,$switch)

=head3 vectorpower($val1,$val2,$switch)

These are the functions called by the overloaded mathematical operators when interacting 
with an RVector object.  These represent +, -, *, /, and ** respectively.  They take in 
two objects to perform the arithmetic operations on and a value for whether the value 
order has actually been switched, since the RVector object should always come first.
$switch is only relevant to subtraction, division, and power.

=cut

sub vectoradd {
    my ($val1, $val2, $switch) = @_;
    my $return = rv();
    ($val1,$val2) = get_proper_operands($val1,$val2,$switch);
    # Do the arithmentic
    for (my $i = 0; $i < $val1->length(); $i++) {
        # TODO: NaN check?!
        $return->add_value($val1->[$i] + $val2->[$i]);
    }
    return $return;
}

sub vectorsub {
    my ($val1, $val2, $switch) = @_;
    my $return = rv();
    ($val1,$val2) = get_proper_operands($val1,$val2,$switch);
    # Do the arithmentic
    for (my $i = 0; $i < $val1->length(); $i++) {
        # TODO: NaN check?!
        $return->add_value($val1->[$i] - $val2->[$i]);
    }
    return $return;
}

sub vectormult {
    my ($val1, $val2, $switch) = @_;
    my $return = rv();
    ($val1,$val2) = get_proper_operands($val1,$val2,$switch);
    # Now run through the entries doing multiplication
    for (my $i = 0; $i < $val1->length(); $i++) {
        # TODO: NaN check?!
        $return->add_value($val1->[$i] * $val2->[$i]); 
    }
    return $return;
}

sub vectordiv {
    my ($val1, $val2, $switch) = @_;
    my $return = rv();
    my ($top,$bottom) = get_proper_operands($val1,$val2,$switch);
    # Now run through the entries doing division, where appropriate
    for (my $i = 0; $i < $top->length(); $i++) {
        # TODO: NaN check?!
        if (defined $bottom->[$i] && $bottom->[$i] != 0) {
            $return->add_value($top->[$i] / $bottom->[$i]);
        } else {
            $return->add_value(undef);
        }
    }
    return $return;
}

sub vectorpower {
    my ($val1, $val2, $switch) = @_;
    my $return = rv();
    ($val1,$val2) = get_proper_operands($val1,$val2,$switch);
    # Do the arithmentic
    for (my $i = 0; $i < $val1->length(); $i++) {
        # TODO: NaN check?!
        $return->add_value($val1->[$i] ** $val2->[$i]);
    }
    return $return;
}

sub get_proper_operands {
    my ($val1, $val2, $switch) = @_;
    my $rlen = $val1->length();
    # Make both vectors the same size.
    if (ref($val1) eq ref($val2)) {
        # Both are vectors
        my $seclen = $val2->length();
        if ($seclen > $rlen) {
            $val1 = $val1->clone();
            $val1->extend($seclen);
            $rlen = $seclen;
        } else {
            $val2 = $val2->clone();
            $val2->extend($rlen);
        }
    } else {
        $val2 = rv($val2);
        $val2->extend($rlen);
    }
    if ($switch) {
        return ($val2,$val1);
    } else {
        return ($val1,$val2);
    }
}

=head1 AUTHOR

Josh Ballard E<lt>josh@oofle.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010 Josh Ballard.  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

For more information about RVector, see http://code.oofle.com/ and follow 
the link to RVector.  For more information about the R Stats programming 
language, see http://r-project.org/.

=cut

1;
__END__

