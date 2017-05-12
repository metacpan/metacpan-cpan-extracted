# $Revision: #5 $$Date: 2005/08/31 $$Author: jd150722 $
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

package Parse::RandGen::CharClass;

require 5.006_001;
use Carp;
use Parse::RandGen qw($Debug);
use strict;
use vars qw(@ISA $Debug);
@ISA = ('Parse::RandGen::Condition');

sub _newDerived {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $type = ref($self);
    my $elem = $self->element();
    (ref($elem) eq "Regexp") or confess("%Error:  CharClass element is not a regular expression (\"$elem\")!  Must be a regular expression!");
    ($elem =~ m/(\(\?[imsx]*-?[imsx]*\:)+((\[\^?.+\])|\.)/ ) or confess("%Error:  CharClass element is malformed (\"$elem\")!  Must be a regular expression matching a single character of a character class (e.g. (?-imsx:[^a-f\n]).");
    $self->_buildCharset();
}

sub isQuantSupported { return 1; }

sub dump {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    return ($self->element().$self->quant());
}

sub pick {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my %args = ( match=>1, # Default is to pick matching data
		 @_ );

    my %result = $self->pickRepetitions(%args);
    my $matchCnt = $result{matchCnt};
    my $badOne = $result{badOne};

    my $min; my $max;
    my $val = "";
    for (my $i=0; $i < $matchCnt; $i++) {
	if (defined($badOne) && ($i==$badOne)) {
	    $min = $self->{_charsetEndOffset};
	    $max = 256;
	} else {
	    $min = 0;
	    $max = $self->{_charsetEndOffset};
	}
	my $chrOffset = $min + int(rand($max-$min));
	$val .= substr($self->{_charset}, $chrOffset, 1);
    }
    my $elem = $self->element();
    if ($Debug) {
	print("Parse::RandGen::CharClass($elem)::pick(match=>$args{match}, matchCnt=>$matchCnt, badOne=>".(defined($badOne)?$badOne:"undef")
	      ." with value of ".$self->dumpVal($val)."\n");
    }
    return ($val);
}

sub _buildCharset {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $elem = $self->element();
    ($elem =~ /(\[\^?.+\])|\./) or confess("%Error:  CharClass element is malformed (\"$elem\")!  Must be a regular expression looking character class (e.g. [^a-f\n]).");

    my $reCharSet = qr/$elem/;
    my $strGood = "";
    my $strBad = "";
    foreach my $ord (0..255) {
	my $char = chr($ord);
	if ($char =~ $reCharSet) {
	    $strGood .= $char;
	} else {
	    $strBad .= $char;
	}
    }
    $self->{_charsetEndOffset} = length($strGood);
    $self->{_charset} = ($strGood . $strBad);
    my $len = length($self->{_charset});
    ($len == 256) or confess("Charset length is $len (all charsets should be 256 characters)!\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen::CharClass - Character class (i.e. [a-f0-9]) terminal Condition element.

=head1 DESCRIPTION

CharClass is a terminal Condition element that models a character class (e.g. [0-9a-fA-f], [^-\n\r], [AaBbCcDd], etc...).

Internally, the character class is broken down into a 256 character long string and an offset.
The offset is the first character that is outside of the character set.  All characters before
the offset are inside the set and all characters at or after the offset are outside the set.

The characters before and after the offset are in character ordinal order.  This ensures that separate
CharClass objects that have equivalent character classes will use the same 256 byte string (so Perl will
ref count the same memory, instead of duplicating it).

=head1 METHODS

=over 4

=item new

Creates a new CharClass.  The first argument (required) is the character class element (e.g. qr/[a-z0-9]/).
The character class element consists of a compiled regular expression that matches only one character.
All other arguments are named pairs.

The CharClass class supports the optional arguments "min" and "max", which represent the number of times that the subrule
must match for the condition to match.

The "quant" quantifier argument can also be used to specify "min" and "max".  The values are the familiar '+', '?',
or '*'  (also can be 's', '?', or 's?', respectively).

=item element, min, max

Returns the CharClass's attribute of the same name.

=back

=head1 SEE ALSO

B<Parse::RandGen::Condition>,
B<Parse::RandGen::Regexp>, and
B<Parse::RandGen>

=head1 AUTHORS

Jeff Dutton

=cut
######################################################################
