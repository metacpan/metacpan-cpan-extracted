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

package Parse::RandGen::Production;

require 5.006_001;
use Carp;
use Parse::RandGen qw($Debug);
use strict;
use vars qw($Debug);

######################################################################
#### Creators

sub new {
    my $class = shift;
    my $self = {
	_conditions => [ ],      # Ordered list of Conditions that must be satisfied for the production to be true
	_action => undef,        # Action to take if the production is satisfied
	_rule => undef,          # The Rule that this Production belongs to
	_name => undef,          # The name of the Production (most are anonymous, but Productions can be named if they need to be accessed later)
	_number => undef,        # The number of the Production in the Rule (which production is this 0...X)
	#@_,
    };
    bless $self, ref($class)||$class;

    # Optional named arguments can be passed.  Any unknown named arguments are turned into object data members.
    my @args = @_;  # Arguments can override defaults or create new attributes in the object
    my $numArgs = $#args + 1;
    if ($numArgs == 1) {
	$self->addCond(shift(@args));
    } elsif ($numArgs) {
	($numArgs % 2) and confess("%Error:  new Production called with an odd number of arguments ($numArgs); arguments must be in named pairs (or a single Condition argument)!");
	$self->set(@args);
    }

    my $rule = $self->{_rule};
    (!defined($self->{_rule}) || UNIVERSAL::isa($rule, "Parse::RandGen::Rule"))
	or confess("%Error:  new Production was passed an unknown \"rule\" argument \"$rule\"!\n");

    return($self);
}

######################################################################
#### Methods

sub set {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my @args = @_;
    
    my $numArgs = $#args + 1;
    ($numArgs) or confess("%Error:  Production::set() called with no arguments!");
    ($numArgs % 2) and confess("%Error:  Production::set() called with an odd number of arguments ($numArgs); arguments must be in named pairs!");
    while ($#args >= 0) {
	my ($arg, $val) = (shift(@args), shift(@args));
	if ($arg eq "cond") {
	    $self->addCond($val);
	} elsif ($arg eq "action") {
	    $self->{_action} = $val;
	} elsif ($arg eq "rule") {
	    UNIVERSAL::isa($val, "Parse::RandGen::Rule") or confess("%Error:  Production::set() called with a bad \"rule\" argument ($val)!");
	    $self->{_rule} = $val;
	} else {
	    # Unknown arguments become data members
	    $self->{$arg} = $val;
	}
    }
}

sub addCond {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my @args = @_;
    
    while ($#args >= 0) {
	my $val = shift(@args);
	defined($val) or confess("%Error:  Production::addCond():  condition is undefined!");
	my $element = $val;
	my $cond = undef;
	my $valRef = ref($val);
	if ($valRef) {
	    if ($valRef eq "Regexp") {
		# Regular expression
		$cond = Parse::RandGen::Regexp->new($element);
	    } else {
		(UNIVERSAL::isa($val, "Parse::RandGen::Condition"))
		    or confess("%Error:  The Production condition is a reference (ref=\"$valRef\"), but not a supported type!");
		$cond = $val;
	    }
	} elsif ($val =~ m/^\s* (\w+) (?: \( (.*?) \) )? \s*$/x) {  # subrule(subargs)
	    my ($min, $max) = (1, 1);
	    $element = $1;
	    my $subargs = $2;
	    if (defined($subargs) && $subargs) {
		if    ($subargs eq "?" )                   { $min = 0; $max = 1; }        # ?
		elsif ($subargs =~ m/^(s|\+)$/ )           { $min = 1; $max = undef; }    # s  or +
		elsif ($subargs =~ m/^((s\?)|\*)$/ )       { $min = 0; $max = undef; }    # s? or *
		elsif ($subargs =~ /(\d+)(?:\.\.(\d+))?/ ) { $min = $1; $max = ($2 || $min); }  # 2..3 or ..4 or 5..
		else {
		    confess("%Error:  The Production condition \"${val}\" has decoded to be a subrule, but the subargs are not understood (${subargs})!");
		}
	    }
	    $cond = Parse::RandGen::Subrule->new($element, min=>$min, max=>$max);
	} elsif ($element =~ $Parse::RandGen::Literal::ValidLiteralRE) {
	    # Must be a literal surrounded by single or double quotes
	    $element = Parse::RandGen::Literal::stripLiteral($element);
	    $cond = Parse::RandGen::Literal->new($element);
	} else {
	    confess("%Error:  The Production condition \"${val}\" has decoded to be a literal, but it doesn't look good!");
	}
	
	$cond->{_production} = $self;
	push @{$self->{_conditions}}, $cond;
    }
}

sub check {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    return "%Error:  Production has no RandGen object!\n" unless $self->grammar();
    my $grammarName = $self->grammar()->name();

    my $err = "";
    foreach my $cond (@{$self->{_conditions}}) {
	next unless $cond->isSubrule();
	my $subrule = $cond->subrule();     # Will be undef if there is a problem
	my $subruleName = $cond->element();
	next unless defined($subruleName);  # Anonymous subrule
	my $rule = $self->grammar()->rule($subruleName);
	next if (defined($rule) && ($rule == $subrule));     # Everything is OK!
	my $ruleName = $self->rule()->name();   # The name of the rule that this production belongs to...
	$err .= "%Error:  The \"${ruleName}\" rule references the subrule \"${subruleName}\", which is not defined in the \"${grammarName}\" grammar!\n" unless (defined($subrule));
    }
    return $err;
}

sub dump {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $output = "";
    foreach my $cond (@{$self->{_conditions}}) {
	$output .= "  " if $output;
	$output .= $cond->dump();
    }
    $output .= $self->_dumpParseFunction();
    return $output;
}

sub dumpHeir {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $output = "";
    foreach my $cond (@{$self->{_conditions}}) {
	$output .= "  " if $output;
	$output .= $cond->dump();
    }
    return $output;
}

sub pick {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my %args = ( match=>1,      # Default is to pick matching data
		 vals => { },   # Hash of values of various hard-coded sub-rules (by name)
		 @_ );
    my @conds = $self->conditions();
    my $badCond;
    my $val = "";

    if (!$args{match}) {
	my @badConds;
	foreach my $cond (@conds) {
	    next if ($cond->isQuantSupported() && $cond->zeroOrMore()); # Cannot corrupt
	    push(@badConds, $cond);
	}
	my $i = int(rand($#badConds+1));
	$badCond = $badConds[$i];
    }

    for (my $i=0; $i <= $#conds; $i++) {
	$val .= $conds[$i]->pick(%args, match=>($args{match} || ((defined($badCond) && ($badCond==$conds[$i]))?0:1)) );
    }

    return( $val );
}

# Returns true (1) if this production contains any of the rules specified by the "vals" argument
sub containsVals {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my %args = ( vals => { },   # Hash of values of various hard-coded sub-rules (by name)
		 @_ );
    foreach my $cond ($self->conditions()) {
	return 1 if $cond->containsVals(%args);
    }
    return 0;
}

######################################################################
#### Accessors

sub action {
    my $self = shift or confess("%Error:  Cannot call name() without a valid object!");
    return $self->{_action};
}

sub rule {  # Rule that this Production belongs to
    my $self = shift or confess("%Error:  Cannot call rule() without a valid object!");
    return $self->{_rule};
}

sub name {  # Name of the Production (optional)
    my $self = shift or confess("%Error:  Cannot call rule() without a valid object!");
    return $self->{_name};
}

sub number {  # Production number on its Rule (required if defined(rule()))
    my $self = shift or confess("%Error:  Cannot call rule() without a valid object!");
    return $self->{_number};
}

sub grammar {
    my $self = shift or confess("%Error:  Cannot call grammar() without a valid object!");
    my $grammar = $self->rule()->grammar() if defined($self->rule());
    return $grammar;
}

sub conditions {
    my $self = shift or confess("%Error:  Cannot call conditions() without a valid object!");
    return (@{$self->{_conditions}});
}

######################################################################
#### Private Functions

sub _dumpParseFunction {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $output = "\n\t\t\t   {\t";
    my $indent = "\n\t\t\t\t";

    if (defined($self->{_action})) {
	$output .= $self->{_action} . " }";
	return $output;
    }
    # Determine whether this is a single terminal production or not
    my @conds = @{$self->{_conditions}};
    my $ind = 1;  # Index 0 is the rule name
    $output .= 'my $val=""; my $obj={val=>undef,offset=>$itempos[1]{offset}{from},len=>0,rules=>{}};';
    foreach my $cond (@conds) {
	$output .= $indent;
	my $sName = $cond->isSubrule() ? $cond->subrule()->name() : "";   # Name of subrule, if subrule...
	my $sKeep =  $sName ? $cond->subrule()->{keep}||"" : "";   # Keep this subrule?
	my $sParse = $sName ? $cond->subrule()->{parse}||"" : "";  # Parse this subrule (preserve heirarchy beneath it)
	if ($cond->once()) {
	    #$output .= "if (ref(\$item[$ind])) { \$val.=\$item[$ind]->{val}; } else { \$val.=\$item[$ind]; }";
	    if ($sName) {
		$output .= "\$val.=\$item[$ind]->{val};";
		if ($sKeep eq "once") {
		    $output .= " \$obj->{rules}{$sName}=\$item[$ind];";
		} elsif ($sKeep eq "all") {
		    $output .= " \$obj->{rules}{$sName}||=[]; push(\@{\$obj->{rules}{$sName}}, \$item[$ind]);";
		}
		if (!$sParse) { # Not adding a new level of parse, so flatten rules
		    $output .= "${indent}foreach my \$j (keys \%{\$item[$ind]->{rules}}) {"
			      ."${indent}\tmy \$o=\$item[$ind]->{rules}{\$j};"
			      ."${indent}\tif (ref(\$o) eq \"ARRAY\") { \$obj->{rules}{\$j}||=[]; push(\@{\$obj->{rules}{\$j}}, \$o); }"
			      ."${indent}\telse { \$obj->{rules}{\$j}=\$o; } }";
		}
	    } else {
		$output .= "\$val.=\$item[$ind];";
	    }
	} else {
	    #$output .= "foreach my \$i (\@{\$item[$ind]}) { if(ref(\$i)){ \$val.=\$i->{val}; } else { \$val.=\$i; }";
	    if ($sName) {
		$output .= "foreach my \$i (\@{\$item[$ind]}) { \$val.=\$i->{val};";
		if ($sKeep eq "once") {
		    $output .= " \$obj->{rules}{$sName}=\$i;";
		} elsif ($sKeep eq "all") {
		    $output .= " \$obj->{rules}{$sName} ||= []; push(\@{\$obj->{rules}{$sName}}, \$i);";
		}
		if (!$sParse) { # Not adding a new level of parse, so flatten rules
		    $output .= "${indent}\tforeach my \$j (keys \%{\$i->{rules}}) {"
			      ."${indent}\t\tmy \$o=\$i->{rules}{\$j};"
			      ."${indent}\t\tif (ref(\$o) eq \"ARRAY\") { \$obj->{rules}{\$j}||=[]; push(\@{\$obj->{rules}{\$j}}, \$o); }"
			      ."${indent}\t\telse { \$obj->{rules}{\$j}=\$o; } }";
		}
		$output .= " }";
	    } else {
		$output .= "foreach my \$i (\@{\$item[$ind]}) { \$val.=\$i; }";
	    }
	}
	$ind++;
    }
    #$output .= " print(\$item[0],\" [\",\$itempos[1]{offset}{from},\"..\${thisoffset}]\\n\");";
    (defined($self->rule()) and $self->rule()->name()) or confess("%Error:  _dumpParseFunction():  Rule is not defined or the Rule is anonymous (no name)!");
    my $ruleName = $self->rule()->name();
    my $prodNum = $self->number();
    ($self->grammar()->rule($ruleName) == $self->rule()) or confess("%Error:  Internal error!  Cannot find our Rule \"$ruleName\" on our RandGen!");
    #$output .= " \$thisparser->{local}{grammar}->rule(\"$ruleName\")->production($prodNum);";
    $output .= $indent.'$obj->{val}=$val; $obj->{len}=length($val);';
    $output .= ' $return=$obj; }';
    return $output;
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen::Production - Conditions for rule to match (and the action to take if it does)

=head1 DESCRIPTION

A Production defines a set of Conditions that must be satisfied for
a Rule to match input text.  The Production consists of an ordered list
of Conditions (subrules, literals, and regexps) that must sequentially
match for the Production to match.

A rule matches if any one of its Productions match the input text.
In BNF notation, the relationship of Rules and Productions is:

  rule1:         production1
               | production2
               | production3

For example:

  perlFuncCall:  /&?/ identifier '(' argument(s?) ')'
               | scalar '->' identifier '(' argument(s?) ')'

The two Productions in this example could respectively match:

    "func()",  "func(x, y)",  or "&func(x)"
    "$obj->member()"

The first Production in this example is a list of:

    Parse::RandGen::Production->new(
        cond => qr/&?/,         # Regexp  Condition - 0 or 1 '&' characters
        cond => "indentifier",  # Subrule Condition - exactly 1 "identifier" rule
        cond => q{'('},         # Literal Condition - single '(' character
        cond => "argument(s?)", # Subrule Condition - 0 or more "argument" rules
        cond => ')',            # Literal Condition - single ')' character
    );

Be aware of the greediness of the underlying parsing mechanism.  If a production consists of
subsequent conditions, such that the earlier ones can satisfy later ones, then they must
be combined into one condition represented by a regular expression.  Regular expressions
can manage the greediness of their matching in order to get the desired effect.

    identifier:        /\w*/  /\d/    # The second condition can be met by the first

=head1 METHODS

=over 4

=item new

Creates a new Production.  The arguments are all named pairs.  The only required pair is "cond" => condition.
The Production can be named with the "name" argument (accessed by the name() accessor).

Any unknown named arguments are treated as user-defined fields.  They are stored in the Condition hash ($cond->{}).

  Parse::RandGen::Production->new( name => 'request',
                                   cond => q{'Request:'},
                                   cond => qr/(\s*\w+\s*[,$]+)/ );

=item rule

Returns the Parse::RandGen::Rule object that this Production belongs to.

=item grammar

Returns the Parse::RandGen::Grammar object that this Production belongs to (returns rule()->grammar()).

=item check

Checks the Production to verify that all subrules can be found in the RandGen.

=item conditions

Returns a list with the Production's Conditions.

=back

=head1 SEE ALSO

B<Parse::RandGen>,
B<Parse::RandGen::Rule>, and
B<Parse::RandGen::Condition>

=head1 AUTHORS

Jeff Dutton

=cut
######################################################################
