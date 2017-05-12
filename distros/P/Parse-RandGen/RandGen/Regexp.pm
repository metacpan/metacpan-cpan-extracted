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

package Parse::RandGen::Regexp;

require 5.006_001;
use Carp;
use Parse::RandGen qw($Debug);
use Data::Dumper; # FIX - debug only
use YAPE::Regex;
use strict;
use vars qw(@ISA %_Yterm $Debug);
@ISA = ('Parse::RandGen::Condition');

sub _newDerived {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $type = ref($self);
    my $elemRef = ref($self->element());
    ($elemRef eq "Regexp") or confess("%Error:  $type has an element that is not a Regexp reference (ref=\"$elemRef\")!");

    # Implement a RandGen::Rule to represent the complexities of the Regexp
    #   This is only used for pick()ing a matching value for the Regexp...
    my $yape = YAPE::Regex->new($self->element());
    $yape->parse();
    my $treeArray = $yape->{TREE};
    ($#{$treeArray} > 0) and die("Found a YAPE::Regex TREE with more than one entry!\n");
    (ref($$treeArray[0]) eq "YAPE::Regex::group") or die("Found a YAPE::Regex TREE, but its entry is not a group!\n");

    $self->{_rule} = Parse::RandGen::Rule->new();
    my $prod = Parse::RandGen::Production->new();
    $self->{_rule}->addProd($prod);
    my $cur = {
	rule => $self->{_rule},
	prod => $prod,
	on => { },
	off => { i=>1, m=>1, s=>1, x=>1 },
    };
    $Data::Dumper::Indent = 1 if $Debug;
    #print ("Parse::RandGen::Regexp::new():  Getting ready to parse the following Regexp ".$self->element().":\n", Data::Dumper->Dump([$yape])) if $Debug;
    $self->_parseRegexp($$treeArray[0], { rule=>$self->{_rule}, prod=>$prod } );
    #print ("Parse::RandGen::Regexp::new():  Finished parsing the following Regexp ".$self->element()." and now \$self->{_rule} is:\n", $self->{_rule}->dumpHeir(), "\n\n") if $Debug;
    #print ("Parse::RandGen::Regexp::new():  Finished parsing the following Regexp ".$self->element()." and now \$self->{_rule} is:\n", Data::Dumper->Dump([$self->{_rule}])) if $Debug;
}

sub dump {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $delimiter = "'";
    my $output = $self->element();
    $output =~ s/($delimiter)/\\$1/gs;  # First, escape the delimiter (compiled regex is devoid of a specific delimiter)
    $output = "m${delimiter}${output}${delimiter}";
    return $output;
}

sub pick {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my %args = ( match=>1, # Default is to pick matching data
		 captures=>{ },  # Captures that are being explicitly specified
		 @_ );
    my $vals = { };
    foreach my $cap (keys %{$args{captures}}) {
	my $ruleRef = $self->capture($cap)
	    or confess("%Error:  Regexp::pick():  Unknown capture field ($cap)!\n");
	$vals->{$ruleRef} = $args{captures}{$cap};
    }
    delete $args{captures};
    my $val = $self->{_rule}->pick(%args, vals=>$vals);
    if (0) {
	my $elem = $self->element();
	print ("Parse::RandGen::Regexp($elem)::pick(match=>$args{match}) with value of ", $self->dumpVal($val), "\n");
    }
    return($val);
}

sub numCaptures {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    return 0 unless defined($self->{_captureList});
    my @caps = @{$self->{_captureList}};
    return ($#caps + 1);
}

sub capture {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $capture = shift;
    defined($capture) and ($capture =~ m/^(\d+)|([a-z]\w*)$/i)
	or confess("%Error:  Capture identifier of \"".(defined($capture)?$capture:"[undef]")."\" is not valid!\n");
    my $num = $1;
    my $name = $2;

    if (defined($num)) {
	my $numCaptures = $self->numCaptures();
	($num >= 1) and ($num <= $numCaptures)
	    or confess("%Error:  Regexp::capture():  Capture number $num is invalid (only captures 1..$numCaptures exist for this Regexp)!\n");
	return $self->{_captureList}[$num-1];
    } else {
	defined($self->{_captureNames}) and defined($self->{_captureNames}{$name})
	    or confess("%Error:  Regexp::capture():  Cannot find named capture \"$name\"!\n");
	return $self->{_captureNames}{$name};
    }
}

sub nameCapture {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my %args = @_;  # "capture# => name" pairs
    $self->{_captureNames} = { } unless defined($self->{_captureNames});
    foreach my $capNum (keys %args) {
	defined($capNum) and ($capNum =~ m/\d+/)
	    or confess("%Error:  Regexp::nameCapture():  Capture number specified is invalid ($capNum)!\n");
	my $numCaptures = $self->numCaptures();
	($capNum >= 1) and ($capNum <= $numCaptures)
	    or confess("%Error:  Regexp::nameCapture():  Cannot name capture number $capNum (only captures 1..$numCaptures exist for this Regexp)!\n");

	my $ruleName = $args{$capNum};
	my $rule = $self->{_captureList}[$capNum];
	$rule->{_name} = $ruleName;  # Name the rule (does not get registered with the grammar - is that OK?)
	$self->{_captureNames}{$ruleName} = $rule; # For lookup within the Regexp object via "capture()" function
    }
}

# YAPE::Regex elements that are supported as CharClass objects
%_Yterm = (
	   "YAPE::Regex::class"    => sub{ my $y=shift; return ( $y->{NEG} . $y->{TEXT} ); },
	   "YAPE::Regex::slash"    => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::macro"    => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::oct"      => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::hex"      => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::utf8hex"  => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::ctrl"     => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::named"    => sub{ my $y=shift; return ($y->text()); },
	   "YAPE::Regex::any"      => sub{ my $y=shift; return ($y->text()); },
	   );

sub _parseRegexp {
    my $self = shift or confess ("%Error:  Cannot call without a valid object!");
    my $yIter = shift;              # YAPE::Regex object iterator
    my $curRef = shift or confess();  # Current position in Condition ($self) object
    my %cur = %$curRef;  # Make a local copy of current state

    my $yType = ref($yIter);
    if ($yType eq "YAPE::Regex::group") {
	foreach my $switch (split //, $yIter->{ON})  { delete $cur{off}{$switch}; $cur{on}{$switch} = 1; }
	foreach my $switch (split //, $yIter->{OFF}) { delete $cur{on}{$switch}; $cur{off}{$switch} = 1; }
    }

    if ( ($yType eq "YAPE::Regex::group")
	 || ($yType eq "YAPE::Regex::capture") ){
	defined($yIter->{NGREED}) or confess("$yType type does not have NGREED implemented!\n");
	defined($yIter->{QUANT}) or confess("$yType type does not have QUANT implemented!\n");

	my @yList = @{$yIter->{CONTENT}};
	foreach my $elemIter (@yList) {
	    my $elemType = ref($elemIter);
	    if ($elemType eq "YAPE::Regex::alt") {
		$cur{rule}->addProd($cur{prod} = Parse::RandGen::Production->new());
	    } elsif ( ($elemType eq "YAPE::Regex::group")
			|| ($elemType eq "YAPE::Regex::capture") ) {

		defined($elemIter->{NGREED}) or confess("$elemType type does not have NGREED implemented!\n");
		defined($elemIter->{QUANT}) or confess("$elemType type does not have QUANT implemented!\n");
		my $greedy = !$elemIter->{NGREED};
		my $quant = $elemIter->{QUANT};

		my $prod = Parse::RandGen::Production->new();
		my $rule = Parse::RandGen::Rule->new();
		$rule->addProd($prod);
		if ($elemType eq "YAPE::Regex::capture") {
		    $self->{_captureList} = [ ] unless ($self->{_captureList});
		    push(@{$self->{_captureList}}, $rule);
		}

		#print "Creating a subrule (elem=>$rule, quant=>$quant, greedy=>$greedy)\n" if $Debug;
		$cur{prod}->addCond(Parse::RandGen::Subrule->new($rule, quant=>$quant, greedy=>$greedy));

		my %next = %cur;
		$next{rule} = $rule;
		$next{prod} = $prod;
		$self->_parseRegexp($elemIter, \%next);
	    } else {
		$self->_parseRegexp($elemIter, \%cur);
	    }
	}
    } elsif ( ($yType eq "YAPE::Regex::whitespace")
	      || ($yType eq "YAPE::Regex::anchor")
	      || ($yType eq "YAPE::Regex::comment")
	      ){
	# Do nothing, simply ignore these objects
    } else {
	defined($yIter->{NGREED}) or confess("$yType type does not have NGREED implemented!\n");
	defined($yIter->{QUANT}) or confess("$yType type does not have QUANT implemented!\n");
	my $greedy = !$yIter->{NGREED};
	my $quant = $yIter->{QUANT};
	my @charClasses = ();

	if (($yType eq "YAPE::Regex::text") && $cur{off}{i} && !$quant) {
	    my $cond = Parse::RandGen::Literal->new($yIter->{TEXT}, greedy => $greedy);
	    $cur{prod}->addCond($cond);
	} elsif ($yType eq "YAPE::Regex::alt") {
	    confess("Not expecting a $yType here!\n");
	} else {
	    if ($yType eq "YAPE::Regex::text") {
		# Case-insensitive text
		my $text = $yIter->{TEXT};
		for (my $offset=0; $offset < length($text); $offset++) {
		    my $char = substr($text, $offset, 1);
		    my $nchar = lc($char);
		    $nchar = uc($char) unless ($nchar ne $char);
		    if (($nchar eq $char) || $cur{off}{i}) {
			#print ("Parse::RandGen::Regexp:  creating a case-sensitive CharClass for letter $offset of the literal \"$text\" ([$char])\n");
			push @charClasses, "$char";
		    } else {
			#print ("Parse::RandGen::Regexp:  creating a case-insenstive CharClass for letter $offset of the literal \"$text\" ([$char$nchar])\n");
			push @charClasses, "$char$nchar";
		    }
		}
	    } elsif (exists($_Yterm{$yType})) {
		@charClasses = ( &{$_Yterm{$yType}}($yIter) );
	    } else {
		confess("%Error:  YAPE type unknown or unsupported (\"$yType\")!");
	    }

	    foreach my $cclass (@charClasses) {
		my $on =  join('', sort(keys(%{$cur{on}})));
		my $off = join('', sort(keys(%{$cur{off}})));
		my $charClassRE;
		if ($yType eq "YAPE::Regex::any") {
		    $charClassRE = qr/(?$on-$off:$cclass)/;  # Cannot match the . character in [ ]
		} else {
		    #print "Parse::RandGen::Regexp: cclass is $cclass\n";
		    if (!$on && ($off eq "imsx")) {
			$charClassRE = qr/[$cclass]/;  # default
		    } else {
			$charClassRE = qr/(?$on-$off:[$cclass])/;
		    }
		    #print "Parse::RandGen::Regexp: cclass charClassRE is $charClassRE\n";
		}
		
		my $cond = Parse::RandGen::CharClass->new($charClassRE, quant=>$quant, greedy=>$greedy);
		$cur{prod}->addCond($cond);
	    }
	}
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen::Regexp - Regular expression Condition element.

=head1 DESCRIPTION

Regexp is a Condition element that matches the given compiled regular expression.  For picking random
data, the regular expression is parsed into its component Subrules, Literals, CharClasses, etc....
Therefore, the pick functionality for a regular expression is ultimately the same as the pick functionality
of a Rule (including the limitations w/r to greediness - see Rule).

Regexp is also useful as a standalone class.  It supports captures (named and indexed), which can be
referenced in a call to the pick() function to force the captures to match the specified data, while
leaving the rest of the data to be generated randomly.

=head1 METHODS

=over 4

=item new

Creates a new Regexp.  The first argument (required) is the regular expression element (e.g. qr/foo(bar|baz)+\d{1,10}/).
All other arguments are named pairs.

=item element

Returns the Regexp element (i.e. the compiled regular expression itself).

=item numCaptures

Returns the number of captures (e.g. $1, $2, ...$n) in the regular expression.

=item nameCapture

Give names to capture numbers for the regular expression.  The arguments to this
function are capture# => "name" pairs (e.g. nameCapture(1=>"directory", 2=>"file", 3=>"extension")).

=item capture

Returns the Rule object that represents the specified capture.  The capture can
be specified by number or by name (the name is set by the nameCapture() function).

=item pick

Randomly generate data (text) that matches (or does not) this regular expression.

Takes a "match" boolean argument that specifies whether to match the regular expression
or deliberately not match it.

Also takes a "captures" hash argument that has pairs of capture numbers (or names) and their
desired value.  This allows the generated data to have user-specified constraints
while allowing the rest of the regular expression to choose random data.  If "match" is
false, the user-specified "captures" values are still used (which may cause the data
to match even though it was not supposed to).

    Example:
        $re->pick(match=>1,
                  captures=>{ 1=>"http", 2=>"www", 3=>"yahoo", 4=>"com" });

=back

=head1 SEE ALSO

B<Parse::RandGen::Condition>,
B<Parse::RandGen::Subrule>,
B<Parse::RandGen::Literal>,
B<Parse::RandGen::CharClass>,
B<Parse::RandGen::Rule>,
B<Parse::RandGen::Production>, and
B<Parse::RandGen>

=head1 AUTHORS

Jeff Dutton

=cut
######################################################################
