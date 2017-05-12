# $Revision: #3 $$Date: 2005/08/31 $$Author: jd150722 $
######################################################################
#
# This program is Copyright 2003-2005 by Jeff Dutton.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.
######################################################################

package Parse::RandGen::Literal;

require 5.006_001;
use Carp;
use Parse::RandGen qw($Debug);
use strict;
use vars qw(@ISA $ValidLiteralRE $Debug);
@ISA = ('Parse::RandGen::Condition');

# This regular expression defines whether a given regexp condition is valid (i.e. can be understood by the Condition module)
# To be valid, the regexp must 
$ValidLiteralRE = qr /
    ([\'\"])   # Match either a single- or double-quote delimiter
    (?: [^\\\1] | \\. )+    # In the middle of the regexp, match either <1> a character that is not a backslash or the delimiter or <2> a backslash followed by any character
    \1          # Match the original delimiter that was found
    /x;

sub _newDerived {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $type = ref($self);
    my $elemRef = ref($self->element());
    (!$elemRef)	or confess("%Error:  $type has an element is a reference (ref=\"$elemRef\") instead of a literal scalar!");
}

sub dump {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    return ("'" . $self->element() . "'");
}

sub pick {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my %args = ( match=>1, # Default is to pick matching data
		 @_ );
    my $val = $self->element();  # Reset to element before each attempt
    my $keepTrying = 10;
    my $length = length($self->element());
    confess "Literal length is 0!  This should never be!\n" unless ($length);

    my ($method, $char);
    while (!$args{match} && $keepTrying-- && ($val eq $self->element())) {
	$val = $self->element();  # Reset to element before each corruption attempt
	$method = int(rand(4));  # Method of corruption
	$char = int(rand($length));  # Which character

	if ($method == 0) {
	    # Try changing the case of first character
	    substr($val, $char, 1) = lc(substr($val, $char, 1));
	    substr($val, $char, 1) = uc(substr($val, $char, 1)) unless ($val ne $self->element());
	} elsif ($method == 1) {
	    # Randomly change the value of one of the characters
	    substr($val, $char, 1) = chr( (ord(substr($val, $char, 1)) + int(rand(256))) % 256 );
	} elsif ($method == 2) {
	    # Insert a random character into the literal
	    $char = int(rand($length+1));  # Where to insert character
	    substr($val, $char, 0) = int(rand(256)) # Insert random character
	} else {
	    # Remove a character
	    substr($val, $char, 1) = '';
	}
    }

    my $elem = $self->element();
    if ($Debug) {
	if ($args{match}) {
	    print ("Parse::RandGen::Literal($elem)::pick(match=>$args{match}) with value of ", $self->dumpVal($val), "\n");
	} else {
	    print ("Parse::RandGen::Literal($elem)::pick(match=>$args{match}, method=>$method, char=>$char) with value of ", $self->dumpVal($val), "\n");
	}
    }
    return ($val);
}

sub stripLiteral {
    my $lit = shift;
    $lit =~ s/([\'\"])(.+)\1/$2/;
    return ($lit);
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen::Literal - Literal terminal Condition element

=head1 DESCRIPTION

Literal is a terminal Condition element that matches the literal.
The only choice for picking a good Literal is the literal itself.

=head1 METHODS

=over 4

=item new

Creates a new Literal.  The first argument (required) is the literal element (e.g. "Hello Washington!").
All other arguments are named pairs.

=item element

Returns the Literal element (i.e. the literal itself).

=back

=head1 SEE ALSO

B<Parse::RandGen::Condition>,
B<Parse::RandGen::Rule>,
B<Parse::RandGen::Production>, and
B<Parse::RandGen>

=head1 AUTHORS

Jeff Dutton

=cut
######################################################################
