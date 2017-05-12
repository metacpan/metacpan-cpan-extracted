# $Revision: #4 $$Date: 2005/08/31 $$Author: jd150722 $
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

package Parse::RandGen::Subrule;

require 5.006_001;
use Carp;
use Parse::RandGen qw($Debug);
use strict;
use vars qw(@ISA $Debug);
@ISA = ('Parse::RandGen::Condition');

sub _newDerived {  }   # Nothing to do

sub isSubrule { return 1; }
sub isTerminal { return 0; }
sub isQuantSupported { return 1; }

sub subrule {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $subrule = $self->element();
    if (ref($subrule)) {
	UNIVERSAL::isa($subrule, "Parse::RandGen::Rule") or confess("subrule() contains a reference ($subrule), but it is not a Rule!");
	return($subrule);
    } else {
	defined($self->grammar()) or confess ("%Error:  Parse::RandGen::Subrule::subrule() called, but the \"$subrule\" rule cannot be found, because grammar() is undef!");
	return($self->grammar()->rule($subrule));
    }
}

sub dump {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $subrule = $self->element();
    if (ref($subrule)) {
	return ($subrule->dumpHeir() . $self->quant());
    } else {
	# Named non-reference rule
	my $output = $subrule;
	if (defined($self->max()) && ($self->min() == $self->max())) {
	    $output .= "(" . $self->min() . ")" unless ($self->min() == 1);
	} else {
	    my $max = defined($self->max()) ? $self->max() : "";
	    $output .= "(" . $self->min() . ".." . $max . ")";
	}
	return $output;
    }
}

sub pick {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my %args = ( match=>1, # Default is to pick matching data
		 @_ );
    my $rule = $self->subrule();
    my $ruleName = $self->element();
    defined($rule) or confess("Subrule::pick():  $ruleName subrule cannot be found in the grammar!\n");

    my %result = $self->pickRepetitions(%args);
    my $matchCnt = $result{matchCnt};
    my $badOne = $result{badOne};

    my $val = "";
    for (my $i=0; $i<$matchCnt; $i++) {
	my $matchThis = (defined($badOne) && ($i==$badOne))?0:1;  # Only don't match for corrupted data
	my $specifiedVals = ($matchThis && ($i==($matchCnt-1))) ? $args{vals} : { }; # Only specify rules for last capture value
	$val .= $rule->pick(%args, match=>$matchThis, vals => $specifiedVals);
    }
    if ($Debug) {
	print("Parse::RandGen::Subrule::pick(match=>$args{match}, matchCnt=>$matchCnt, badOne=>".(defined($badOne)?$badOne:"undef")
	      .") on the rule \"".$rule->dumpHeir()."\" has a value of ".$self->dumpVal($val)."\n");
    }
    return ($val);
}

# Returns true (1) if this subrule contains any of the rules specified by the "vals" argument
sub containsVals {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my %args = ( vals => { },   # Hash of values of various hard-coded sub-rules (by name)
		 @_ );
    return $self->subrule()->containsVals(%args);
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen::Subrule - Subrule Condition element, that references a Rule object and a match quantifier

=head1 DESCRIPTION

Subrule is a non-terminal Condition element that references a Rule object and contains a match quantifier
(how many times the Rule must match for the Condition to be satisfied).

=head1 METHODS

=over 4

=item new

Creates a new Subrule.  The first argument (required) is the Rule that must be satisfied for the condition to
match (either a Rule object reference or the name of the rule).

All other arguments are named pairs.

The Subrule class supports the optional arguments "min" and "max", which represent the number of times that the subrule
must match for the condition to match.

The "quant" quantifier argument can also be used to specify "min" and "max".  The values are the familiar '+', '?',
or '*'  (also can be 's', '?', or 's?', respectively).

=item element, min, max

Returns the Condition's attribute of the same name.

=item subrule

Returns a reference to the Condition's Rule object.

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
