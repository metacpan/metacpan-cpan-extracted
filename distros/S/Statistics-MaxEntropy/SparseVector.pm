package Statistics::SparseVector;

##---------------------------------------------------------------------------##
##  Author:
##      Hugo WL ter Doest       terdoest@cs.utwente.nl
##  Description: module for sparse bitvectors
##               method names equal that of Bit::Vector
##
##---------------------------------------------------------------------------##
##  Copyright (C) 1998, 1999 Hugo WL ter Doest terdoest@cs.utwente.nl
##
##  This library is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This library  is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU Library General Public 
##  License along with this program; if not, write to the Free Software
##  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
##---------------------------------------------------------------------------##


use strict;
use vars qw($VERSION 
	    @ISA 
	    @EXPORT 
	    @EXPORT_OK);
use overload
'++'     =>    \&increment,
'='      =>    \&Clone,
'""'     =>    \&stringify;
require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.2';


# Preloaded methods go here.

# necessary for overloading ""
# in turn required by Data::Dumper that wants to stringify variables
sub stringify {
    my($self) = @_;

    return($self);
}


# create a new bitvector
# all bits are `off'
sub new {
    my($this, $n) = @_;

    # for calling $self->new($someth):
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->{N} = $n;
#    $self->{VECTOR} = {};
    return($self);
}


# create a copy of a bitvector and return it
sub Clone {
    my($self) = @_;

    my($new);

    $new = Statistics::SparseVector->new($self->{N});
    bless $new, ref($self);
    for (keys %{$self->{VECTOR}}) {
	$new->{VECTOR}{$_} = $self->{VECTOR}{$_};
    }
    return($new);
}


# is called right before Perl destroys a bitvector
# this happens automatically if a vector has zero references
sub DESTROY {
    my($self) = @_;
}


# creates a new vector from a bitstring
# checks for whitespace separators
sub new_vec {
    my($this, $n, $vector, $vectype) = @_;

    my($i,
       @ints,
       $int,
       $self,
       $sep);

    $sep = '';
    if ($vector =~ /\s+/) {
	$sep = '\s+';
    }
    @ints = split(/$sep/, $vector);
    if ($#ints+1 != $n) {
	die "inconsistent call to new_vec\n";
    }
    $self = $this->new($n);
    $i = 0;
    while (@ints) {
	$int = shift(@ints);
	if ($int > 0) {
	    $self->{VECTOR}{$i} = ($vectype eq "binary") ? 1 : $int;
	}
	$i++;
    }
    return($self);
}


# the value at position $col
sub weight {
    my($self, $col) = @_;

    return($self->{VECTOR}{$col});
}


# we assume a bit is `on' if its value is defined
sub bit_test {
    my($self, $i) = @_;

    return(defined($self->{VECTOR}{$i}));
}


# turning off a bit is making its value undefined
sub Bit_Off {
    my($self, $i) = @_;

    undef $self->{VECTOR}{$i};
}


# turns on a bit
sub Bit_On {
    my($self, $i) = @_;

    $self->{VECTOR}{$i} = 1;
}


# increment integer at position $i by one
sub Inc {
    my($self, $i) = @_;

    $self->{VECTOR}{$i}++;
}


# flips a bit, i.e. makes it undef if it is defined,
# and makes it defined if it is undefined
sub bit_flip {
    my($self, $i) = @_;

    if (defined($self->{VECTOR}{$i})) {
	undef $self->{VECTOR}{$i};
    }
    else {
	$self->{VECTOR}{$i} = 1;
    }
}


# increases the integer value of the bitvector by one
sub increment {
    my($self) = @_;

    my($carry, $i);

    $carry = 0;
    $i = 0;
    do {
	if (defined($self->{VECTOR}{$i})) {
	    undef $self->{VECTOR}{$i};
	    $carry = 1;
	}
	else {
	    $self->{VECTOR}{$i} = 1;
	    $carry = 0;
	}
	$i++;
    } until (($carry == 0) || ($i == $self->{N}));
}


# fills the set
sub Fill {
    my($self) = @_;

    my $i;

    for ($i = 0; $i < $self->{N}; $i++) {
	$self->{VECTOR}{$i} = 1;
    }
}


# clears the vector
sub Empty {
    my($self) = @_;
    
    undef $self->{VECTOR};
}


# returns a bitstring
sub to_Bin {
    my($self, $sep) = @_;

    my($s, $i);

    $s = "";
    for ($i = 0; $i < $self->{N}; $i++) {
	if (defined($self->{VECTOR}{$i})) {
	    $s = "1$sep" . $s;
	}
	else {
	    $s = "0$sep" . $s;
	}
    }
    return($s);
}


# returns a bitstring
sub to_Int {
    my($self) = @_;

    my($s, $i);

    $s = "";
    for ($i = 0; $i < $self->{N}; $i++) {
	if (defined($self->{VECTOR}{$i})) {
	    $s .= "$self->{VECTOR}{$i} ";
	}
	else {
	    $s .= "0 ";
	}
    }
    return($s);
}


# returns a comma-separated list of features that are on
sub to_Enum {
    my($self) = @_;

    return(join(',', keys(%{$self->{VECTOR}})));
}


# expects a comma-separated list of numbers
sub new_Enum {
    my($this, $n, $s) = @_;

    my($self);

    $self = $this->new($n);
    for (split(/,/,$s)) {
	$self->{VECTOR}{$_} = 1
    }
    return($self);
}


# returns the length of the vector
sub Size {
    my($self) = @_;

    return($self->{N});
}


# NOTA BENE: THIS ROUTINE HAS BUGS
# $len1 >= 0, $len2 >= 0, $vec2->Size() >= $off2 >= 0
# $vec1->Size() >= $off1 >= 0
# $vec1 may be undefined
# $len1 + $off1 < $vec->Size()
sub Interval_Substitute {
    my($vec2, $vec1, $off2, $len2, $off1, $len1) = @_;

    my($i,
       $oldvec2);

    # save  $vec2 in $oldvec2
    $oldvec2 = $vec2->Clone();
    # determine the new length for $vec2
    if ($off2 == $vec2->Size()) {
	# we are appending bits from source $vec1
	$vec2->{N} += $len1;
    }
    else {
	# we are inserting bits from $vec1
	$vec2->{N} += $len1 - $len2;
    }
    # target $vec2 changes only from $off2
    # copy the new bits from the source $vec1
    if (defined($vec1)) { # we have source bits
	for ($i = $off2; $i < $off2 + $len1; $i++) {
	    if (defined($vec1->{VECTOR}{$i - $off2 + $off1})) {
		$vec2->{VECTOR}{$i} = $vec1->{VECTOR}{$i - $off2 + $off1};
	    }
	    else {
		undef $vec2->{VECTOR}{$i};
	    }
	}
    }
    # append the rest of $oldvec2
    # index $i runs for $oldvec2, we correct for $vec2
    for ($i = $off2 + $len2; $i < $oldvec2->{N}; $i++) {
	if (defined($oldvec2->{VECTOR}{$i})) {
	    $vec2->{VECTOR}{$i-$len2+$len1} = $oldvec2->{VECTOR}{$i};
	}
	else {
	    undef $vec2->{VECTOR}{$i-$len2+$len1};
	}
    }
    undef $oldvec2;
#    print "$vec2->to_Bin()\n"
}


# removes a column from the vector
sub delete_column {
    my($self, $col) = @_;

    my($i);

    for ($i = 0; $i < $self->{N} - 1; $i++) {
	if ($i >= $col) {
	    $self->{VECTOR}{$i} = $self->{VECTOR}{$i + 1};
	}
    }
    undef $self->{VECTOR}{$self->{N}-1};
    $self->{N}--;
}


sub insert_column {
    my($self, $pos, $val) = @_;

    my($i);

    $self->{N}++;
    for ($i = $self->{N}-1; $i > $pos; $i--) {
	$self->{VECTOR}{$i} = $self->{VECTOR}{$i - 1};
    }
    $self->{VECTOR}{$pos} = $val;
}


# returns an array of indices of set bits
sub indices {
    my($self) = @_;

    return(grep(defined($self->{VECTOR}{$_}), keys(%{$self->{VECTOR}})));
#    return(keys(%{$self->{VECTOR}}));
}


# the sum of the values
sub Norm {
    my($self) = @_;

    my($n);

    $n = 0;
    for (values(%{$self->{VECTOR}})) {
	if (defined($_)) {
	    $n += $_;
	}
    }
    return($n);
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

Statistics::SparseVector - Perl5 extension for representing and
manipulating sparse binary and integer vectors

=head1 SYNOPSIS

 use Statistics::SparseVector;

 # methods that create new bitvectors
 $vec = Statistics::SparseVector->new($n);
 $vec2 = $vec1->Clone();
 $vec = Statistics::SparseVector->new_Enum($n, $s);
 $vec = Statistics::SparseVector->new_Bin($n, $s);
 $vec = Statistics::SparseVector->new_Int($n, $s);

 # miscellaneous
 $vec2->Substitute_Vector($vec1, $of22, $len2, $off1, $len1);
 $vec->insert_column($pos, $val);
 $vec->delete_column($pos);
 $vec->Size();
 $vec->to_Enum();
 $vec->to_Bin($sep);
 $vec->Fill();
 $vec->Empty();
 $vec->increment();
 $n = $vec->Norm();
 @list = $vec->indices();

 # manipulation on the bit level
 $vec->Bit_Off($i);
 $vec->Bit_On($i);
 $vec->Inc($i);
 $vec->bit_flip($i);
 $vec->bit_test($i);

 # overloaded operators
 # increment
 $vec++;
 # stringify
 "$vec"


=head1 DESCRIPTION

This module implements sparse bitvectors. Several methods for
manipulating bitvectors are implemented. 


=head2 Creation of bitvectors

=over 4

=item C<new>

 $vec = Statistics::BitVector->new($n);

A bitvector of length C<$n> is created. All bits are zero.

=item C<Clone>

 $clone = $vec->Clone();

A copy of C<$vec> is returned.

=item C<new_Enum>

 $vec = Statistics::BitVector->new_Enum($enumstring, $n);

A new vector of length C<$n> is created from the comma-separated list of in
C<$enumstring>.

=item C<new_Bin>

 $vec = Statistics::BitVector->new_Bin($n, $string);

A new vector of length C<$n> is created from bitstring C<$string>.

=item C<new_Int>

 $vec = Statistics::BitVector->new_Int($n, $intlist);

A new vector of length C<$n> is created from whitespace-separated list of
integers C<$intlist>.

=back


=head2 Vector-wide manipulation of vector elements

=over 4

=item C<Substitute_Vector>

 $vec2->Substitute_Vector($vec1, $off2, $len2, $off1, $len1);

C<$len2> contiguous bits in target vector C<$vec2> starting from C<$off2> are
replaced by C<$len1> contiguous bits from source vector C<$vec1> starting at bit
C<$off1>. If C<$off2> equals the length of C<$vec2> the bits from C<$vec1> are
appended. If C<$len1> is zero the C<$len2> bits from C<$vec2> are deleted.

=item C<delete_column>

 $vec->delete_column($i);

Delete position C<$i>, the other elements are shifted as necessary.

=item C<insert_column>

 $vec->insert_column($i, $val);

Insert a vector element at position C<$i> with value C<$val>.

=item C<Fill>

 $vec->Fill();

All bits of C<$vec> are set to one.

=item C<Empty>

 $vec->Empty();

All bits of C<$vec> are set to zero.

=item C<increment>

 $vec->increment(); $vec++;

The integer value of the bitvector is increased by one.

=item C<Bit_Off>

 $vec->Bit_Off($i);

Bit C<$i> is set to zero.

=item C<Bit_On>

 $vec->Bit_On($i);

Bit C<$i> is set to one.

=item C<Inc>

 $vec->Inc($i);

The integer at position C<$i> is increased by one.

=item C<bit_flip>

 $vec->bit_flip($i);

Bit C<$i> is flipped.

=item C<bit_test>

 $vec->bit_test($i);

Returns C<1> if bit C<$i> is one, C<0> otherwise.

=back


=head2 Miscellany

=over 4

=item C<Size>

 $n = $vec->Size();

Returns the size of the vector.

=item C<to_Enum>

 $enumstring = $vec->to_Enum();

Returns a comma-separated list of bits that are set.

=item C<indices>

Returns an array of indices of bits that are set.

=item C<to_Bin>

 $bitstring = $vec->to_Bin($sep);

Returns a string of bits separated by C<$sep>; bits should be read from
left to right

=item C<Norm>

Returns the number of set bits.

=back


=head2 Overloaded operators

=over 4

=item C<++>

 $vec++;

Same as method C<increment>.

=item Double quotes

 $string = "$vec";

C<Data::Dumper> wants to stringify vectors. Probably because
C<Statistics::SparseVector> is an overloaded package it expects double quotes to
be overloaded as well.


=back 


=head1 REMARKS ABOUT THE IMPLEMENTATION

=over 4

=item *

Internally sparse vectors are represented by hashes.

=item *

Only a few methods from Bit::Vector are implemented. Maybe new ones
will follow in the future.

=item *

Method C<Substitute_Vector> is not thorougly debugged.

=back



=head1 VERSION

Version 0.2.


=head1 AUTHOR

=begin roff

Hugo WL ter Doest, terdoest@cs.utwente.nl

=end roff

=begin latex

Hugo WL ter Doest, \texttt{terdoest\symbol{'100}cs.utwente.nl}

=end latex


=head1 SEE ALSO

L<perl(1)>, L<Statistics::MaxEntropy(3)>, 
L<Statistics::ME.wrapper.pl(3)>, L<Statistics::Candidates(3)>.


=head1 COPYRIGHT

=begin roff

Copyright (C) 1998, 1999 Hugo WL ter Doest, terdoest@cs.utwente.nl
Univ. of Twente, Dept. of Comp. Sc., Parlevink Research, Enschede,
The Netherlands.

=end roff

=begin latex

\copyright 1998, 1999 Hugo WL ter Doest,
\texttt{terdoest\symbol{'100}cs.utwente.nl} Univ. of Twente, Dept. of
Comp. Sc., Parlevink Research, Enschede, The Netherlands.

=end latex

C<Statistics::MaxEntropy> comes with ABSOLUTELY NO WARRANTY and may be copied
only under the terms of the GNU Library General Public License (version 2, or
later), which may be found in the distribution.

=cut
