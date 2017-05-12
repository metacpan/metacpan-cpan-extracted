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

package Parse::RandGen::Condition;

require 5.006_001;
use Carp;
use Data::Dumper;
use Parse::RandGen qw($Debug);
use strict;
use vars qw($Debug);

######################################################################
#### Creators

sub new {
    my $class = shift;
    my $element = shift;
    defined($element) or confess("%Error:  Parse::RandGen::Condition::new() requires the a defined element argument as the first argument!\n");

    my $self = {
	_element => $element,    # The element for the condition that must match
	_min => undef,           # The minimum number of times that the element must match for the condition to be true
	_max => undef,           # The maximum (inclusive) number of times that the element must match for the condition to be true
	_greedy => undef,        # By default, conditions are greedy (for pick()ing only, for parsing all conditions are greedy)
	_production => undef,    # The "parent" production that this belongs to...
    };
    my $type = ref($class)||$class;
    ($type eq "Parse::RandGen::Condition") and confess "%Error:  Cannot call Parse::RandGen::Condition::new() directly!  It is an abstract class!";
    bless $self, $type;

    # Optional named arguments can be passed.  Any unknown named arguments are turned into object data members.
    my %args = (
	# Optional
	min => 1,        # Min quantity
	max => 1,        # Max quantity
	quant => undef,  # Quantifier:  [ + * ? ]
        greedy => 1,
	@_,  # Arguments can override defaults or create new attributes in the object
    );
    if (defined($args{quant})) {
	my $quant = $args{quant};
	($args{min}, $args{max}) = (1, undef) if (($quant eq '+') || ($quant eq 's'));
	($args{min}, $args{max}) = (0, undef) if (($quant eq '*') || ($quant eq 's?'));
	($args{min}, $args{max}) = (0, 1)     if ($quant eq '?');
	if ($quant =~ m/\{(\d+)(,(\d*))?\}/) {  # Support {n} , {n,} , and {n,m} formats
	    $args{min} = $1;
	    if (defined($2)) {
		$args{max} = $3;           # {n,} is (n,undef); {n,m} is (n,m)
	    } else {
		$args{max} = $args{min};   # {n} is (n,n)
	    }
	}
	defined($args{min}) or confess("%Error:  quant value of $quant is not understood!\n");
    }
    $self->{_min} = $args{min}; delete $args{min};
    $self->{_max} = $args{max}; delete $args{max};
    $self->{_greedy} = $args{greedy}; delete $args{greedy};
    delete $args{quant};

    my ($min, $max) = ($self->min(), (defined($self->max()) ? $self->max() : "undef"));
    ($self->isQuantSupported() or $self->once()) or confess "%Error:  new $type being created with a specified quantifier (min=$min and max=$max are not supported)!";

    $self->_newDerived(\%args);   # Derived class can pull out args that are custom/specific...

    # Delete named arguments, and copy any other values into the object (user-defined fields)
    foreach my $userDefField (sort keys %args) {
	$self->{$userDefField} = $args{$userDefField};
    }

    return($self);
}

######################################################################
#### Methods

#sub dump {  }         # Abstract Method

sub dumpVal {
    my $self = shift or confess "%Error:  Cannot call dumpVal() without a valid object!";
    my $val = shift;
    $val = "" unless defined($val);
    my $d = Data::Dumper->new([$val])->Terse(1)->Indent(0)->Useqq(1);
    return($d->Dump());
}

sub pickRepetitions {
    my $self = shift or confess "%Error:  Cannot call pickRepetitions without a valid object!";
    my %args = @_;

    my ($corruptCnt, $corruptData) = (0, 0);
    if (!$args{match} && !$self->zeroOrMore()) {
	if (int(rand(2))) {
	    $corruptData = 1;
	} else {
	    $corruptCnt = 1;
	}
    }

    my ($minCnt, $maxCnt);
    if ($corruptCnt) {
        if ((int(rand(2)) || !$self->max()) && $self->min()) {
            # Choose less than the minimum count (too few)
            ($minCnt, $maxCnt) = (0, $self->min()-1);
        } else {
            # Choose more than the maximum count (too many)
            ($minCnt, $maxCnt) = ($self->max()+1, $self->max()+4);
        }
    } else {
        $minCnt = $self->min() || ($self->containsVals(%args) ? 1 : 0);  # containsVals can only be true for SubRule
        $maxCnt = $self->max() || ($minCnt + (1<<int(rand(5))));
    }

    my $matchCnt = $minCnt + int(rand($maxCnt-$minCnt+1));
    my $badOne = $corruptData ? int(rand($matchCnt)) : undef;

    return ( matchCnt => $matchCnt, badOne => $badOne );
}

#sub pick { }          # Abstract Method

######################################################################
#### Accessors

sub element {
    my $self = shift or confess "%Error:  Cannot call element() without a valid object!";
    return $self->{_element};
}

sub subrule { return undef; }  # Default
sub isSubrule { return 0; }    # Default
sub isTerminal { return 1; }   # Default
sub isQuantSupported { return 0; }   # Default (Regexp and Literal classes dont support)
sub containsVals { return 0; } # Default (only Subrule supports)

sub min {
    my $self = shift or confess "%Error:  Cannot call min() without a valid object!";
    return $self->{_min};
}

sub max {
    my $self = shift or confess "%Error:  Cannot call max() without a valid object!";
    return $self->{_max};
}

sub once {  # Returns true if the Condition must match exactly once
    my $self = shift or confess "%Error:  Cannot call once() without a valid object!";
    return (defined($self->max()) && ($self->min() == 1) && ($self->max() == 1));
}

sub zeroOrMore {  # Returns true if the Condition can match 0 or more times
    my $self = shift or confess "%Error:  Cannot call once() without a valid object!";
    return (!$self->min() && !defined($self->max()));
}

sub quant {
    my $self = shift or confess "%Error:  Cannot call once() without a valid object!";
    my $ngreedy = $self->isGreedy() ? "" : "?";
    my $quant = "";
    my @minmax = ($self->min(), $self->max());
    my $arrayEq = sub { return (($_[0] == $_[2]) && ( (!defined($_[1]) && !defined($_[3]))
						      || ( (defined($_[1]) && defined($_[3]))
							   && ($_[1] == $_[3])) ) ); };
    if (&$arrayEq(@minmax, 0, undef)) {
	$quant = "*" . $ngreedy;
    } elsif (&$arrayEq(@minmax, 1, undef)) {
	$quant = "+" . $ngreedy;
    } elsif (&$arrayEq(@minmax, 0, 1)) {
	$quant = "?";
    } elsif (&$arrayEq(@minmax, 1, 1)) {
	$quant = "";   # Print nothing if the quantifier is {1}
    } else {
	my $min = $self->min();
	my $max = defined($self->max()) ? $self->max() : "";
	if ($max && ($self->min() == $self->max())) {
	    $quant = "{$max}";
	} else {
	    $quant = "{$min,$max}";
	}
    }
    return $quant;
}

sub isGreedy {   # Almost everything is greedy
    my $self = shift or confess "%Error:  Cannot call once() without a valid object!";
    return ($self->{_greedy});
}

sub production {  # Production that this Condition belongs to
    my $self = shift or confess "%Error:  Cannot call production() without a valid object!";
    return $self->{_production};
}

sub rule {
    my $self = shift or confess "%Error:  Cannot call rule() without a valid object!";
    my $rule = $self->production()->rule() if defined($self->production());
    return $rule;
}

sub grammar {
    my $self = shift or confess "%Error:  Cannot call grammar() without a valid object!";
    my $grammar = $self->rule()->grammar() if defined($self->rule());
    return $grammar;
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen::Condition - Base class for condition elements that contain an element (regex, subrule, literal) and a match quantifier

=head1 DESCRIPTION

There are several specific Condition classes:  Subrule, Literal, CharClass, and Regexp.  Literals and CharClass's are terminal Conditions.

=head1 METHODS

=over 4

=item new

This method cannot be called directly from the Condition class (it must be called on a specific derived Condition class).
The first argument (required) is the condition element.  The required element type depends on the specific Condition
class being constructed.

All other arguments are named pairs.  

Some classes (Subrule and CharClass) support the optional arguments "min" and "max", which represent the number of times that the subrule
must match for the condition to match.

The "quant" quantifier argument can also be used in place of "min" and "max".  The values are the familiar '+', '?',
or '*'  (also can be 's', '?', or 's?', respectively).

Any unknown named arguments are treated as user-defined fields.  They are stored in the Condition hash ($cond->{}).

  Parse::RandGen::Literal->new("Don't mess with Texas!");
  Parse::RandGen::Regexp->new(qr/Hello( World)?/,  userDefinedField => $example );
  Parse::RandGen::Subrule->new("match_rule", quant=>'+' );    # This indirect reference to the "match_rule" rule requires a Grammar for lookup.
  Parse::RandGen::Subrule->new($myRuleObjRef, min=>2, max=>3 );

=item pick

Returns random data for the Condition.  Takes an optional named pair argument "match" that specifies whether the data
chosen should match the Condition element or not.

  $conditionObject->pick( match=>1 );

=item element, min, max

Returns the Condition's attribute of the same name.

=item isSubrule

Returns true if the given Condition is a Subrule.

=item isTerminal

Returns true if the given Condition is a terminal (CharClass or Literal).

=item subrule

Returns a reference to the Condition's Rule object (or undef if !isSubrule()).

=item production

Returns the Parse::RandGen::Production object that this Condition belongs to.

=item rule

Returns the Parse::RandGen::Rule object that this Condition's Production belongs to (returns production()->rule()).

=item grammar

Returns the Parse::RandGen::Grammar object that this production belongs to (returns production()->rule()->grammar()).

=back

=head1 SEE ALSO

B<Parse::RandGen>,
B<Parse::RandGen::Rule>,
B<Parse::RandGen::Production>,
B<Parse::Literal>,
B<Parse::Regexp>,
B<Parse::Subrule>, and
B<Parse::CharClass>

=head1 AUTHORS

Jeff Dutton

=cut
######################################################################
