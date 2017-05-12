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

package Parse::RandGen::Rule;

require 5.006_001;
use Carp;
use Parse::RandGen qw($Debug);
use Data::Dumper;  # FIX - debug only
use strict;
use vars qw($Debug);

######################################################################
#### Creators

sub new {
    my $class = shift;
    my $self = {
	_name => undef,        # Name of the rule
	_grammar => undef,     # Reference to the parent Grammar object
	_productions => [ ],   # Productions for the rule
    };
    bless $self, ref($class)||$class;

    $self->{_name} = shift;
    !defined($self->{_name}) or ($self->{_name} =~ /^[a-z_]\w*$/i)
	or confess("The specified rule name must be exclusively alphanumeric characters (", $self->{_name}, ")!");
    return($self);
}

######################################################################
#### Methods

sub set {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my @args = @_;
    my $prodType = "Parse::RandGen::Production";
    
    my $numArgs = $#args + 1;

    ($numArgs) or confess("%Error:  Rule::set() called with no arguments!");

    ($numArgs % 2) and confess("%Error:  Rule::set() called with an odd number of arguments ($numArgs); arguments must be in named pairs!");
    while ($#args >= 0) {
	my ($arg, $val) = (shift(@args), shift(@args));
	if ($arg eq "prod") {
	    $self->addProd($val);
	} else {
	    # Unknown arguments become data members
	    $self->{$arg} = $val;
	}
    }
}

sub addProd {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my @args = @_;
    my $prodType = "Parse::RandGen::Production";
    
    foreach my $arg (@args) {
	my $prod;  # Production object
	my $type = ref($arg);
	if ($type && UNIVERSAL::isa($arg, $prodType)) {
	    $prod = $arg;
	} elsif ($type eq "ARRAY") {
	    # [ 'http://' host path(?) ]
	    $prod = Parse::RandGen::Production->new(@$arg);
	} else {
	    confess("%Error:  Passed a $type argument instead of a $prodType or ARRAY reference argument!");
	}
	defined($prod->{_rule}) and confess("%Error:  Adding a Production that already belongs to another Rule!");
	$prod->{_rule} = $self;
	push @{$self->{_productions}}, $prod;      # Add the production to the end of the _productions list
	$prod->{_number} = $#{$self->{_productions}};
    }
}

sub check {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    return "%Error:  Production has no Grammar object!" unless $self->grammar();
    my $grammarName = $self->grammar()->name();

    my $err = "";
    foreach my $prod (@{$self->{_productions}}) {
	$err .= $prod->check();
    }
    return $err;
}

sub dump {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $output = $self->name() . ":\n";
    my $firstProd = 1;
    foreach my $prod (@{$self->{_productions}}) {
	if ($firstProd) {
	    $output .= "\t\t  ";
	    $firstProd = 0;
	} else {
	    $output .= "\t\t| ";
	}
	$output .=  $prod->dump() . "\n";
    }
    $output .= "\n";
}

sub dumpHeir {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $name = defined($self->name()) ? ($self->name() . ":") : "";
    my $output = "($name  ";
    my $firstProd = 1;
    foreach my $prod (@{$self->{_productions}}) {
	if ($firstProd) {
	    $firstProd = 0;
	} else {
	    $output .= "  |  ";
	}
	$output .=  $prod->dumpHeir();
    }
    $output .= "  )";
}

sub pick {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my %args = ( match=>1,      # Default is to pick matching data
		 vals => { },   # Hash of values of various hard-coded sub-rules (by name)
		 @_ );

    # Return explicitly specified value (if specified by name or reference to $self)
    return $args{vals}{$self->name()} if (defined($self->name()) && defined($args{vals}{$self->name()}));
    return $args{vals}{$self} if defined($args{vals}{$self});

    my @prods;
    foreach my $prod ($self->productions()) {
	push(@prods, $prod) if $prod->containsVals(%args);
    }
    @prods = $self->productions() unless(@prods);  # If {vals} does not specify any production of this rule, pick from all productions

    my $prodNum = int(rand($#prods+1));
    return( $prods[$prodNum]->pick(%args) );
}

# Returns true (1) if this rule is or has any explicitly specified values in the "vals" argument
sub containsVals {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my %args = ( vals => { },   # Hash of values of various hard-coded sub-rules (by name)
		 @_ );

    # Return true if this rule is explicitly specified (if specified by name or reference to $self)
    return 1 if (defined($self->name()) && defined($args{vals}{$self->name()}));
    return 1 if defined($args{vals}{$self});

    foreach my $prod ($self->productions()) {
	return 1 if $prod->containsVals(%args);
    }
    return 0;
}

######################################################################
#### Accessors

sub name {
    my $self = shift or confess("%Error:  Cannot call name() without a valid object!");
    return $self->{_name};
}

sub grammar {
    my $self = shift or confess("%Error:  Cannot call grammar() without a valid object!");
    return $self->{_grammar};
}

sub productions {
    my $self = shift or confess("%Error:  Cannot call productions() without a valid object!");
    return (@{$self->{_productions}});
}

sub production {
    my $self = shift or confess("%Error:  Cannot call productions() without a valid object!");
    my $prodIdent = shift;
    defined($prodIdent) or confess("%Error:  Must specify either the name or the number of the production to be found!");
    my $isNumber = ($prodIdent !~ m/[^\d]/);
    foreach my $prod (@{$self->{_productions}}) {
	if ( ($isNumber && ($prod->{_number} == $prodIdent))
	     || (defined($prod->{_name}) && ($prod->{_name} eq $prodIdent)) ) {
	    return $prod;
	}
    }
    return undef;   # Not found
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen::Rule - Grammatical Rule object

=head1 DESCRIPTION

A Rule matches if any one of its Productions match the input text.
In BNF notation, the relationship of Rules and Productions is:

  rule1:         production1
               | production2
               | production3

For example:

  perlFuncCall:  /&?/ identifier '(' argument(s?) ')'
               | scalar '->' identifier '(' argument(s?) ')'

The two productions in this example could respectively match:

    "func()",  "func(x, y)",  or "&func(x)"
    "$obj->member()"

=head1 METHODS

=over 4

=item new

Creates a new Rule.  The Rule name is the only required argument.  Productions are optional.

    Parse::RandGen::Rule->new (
        name => "perlFuncCall",     # Rule name (optional if an anonymous rule)

        # "prod" specifies a new Production object on this Rule
        prod => [ name => "staticFuncCall",   # Production name is optional
                  cond => qr/&?/,                  # Regexp  Condition - 0 or 1 '&' characters
                  cond => "indentifier",           # Subrule Condition - exactly 1 "identifier" rule
                  cond => q{'('},                  # Literal Condition - single '(' character
                  cond => "argument(s?)",          # Subrule Condition - 0 or more "argument" rules
                  cond => q{')'}, ],               # Literal Condition - single ')' character
        prod => [ name => "objectFuncCall",   # Rule's second production
                  cond => "scalar",
                  cond => q{'->'},
                  cond => "indentifier",
                  cond => q{'('},
                  cond => "argument(s?)",
                  cond => q{')'}, ],
    );

=item name

Return the name of the Rule.

=item grammar

Returns a reference to the Grammar that the Rule belongs to.

=item pick

Randomly generate data (text) that matches (or does not) the rule.

Takes a "match" boolean argument that specifies whether to match the regular expression
or deliberately not match it.

Also takes a "vals" hash argument that has pairs of subrules (name or reference) and their
desired value.  This allows the generated data to have user-specified constraints
while allowing the rest of the rule to choose random data.  If "match" is
false, the user-specified "vals" are still used (which may cause the data
to match even though it was not supposed to).  If a user-specified value is
given, then productions that do not reference that rule are not chosen (unless
no productions reference the rule).

    Example:
        $re->pick(match=>0, vals=>{ file=>"Rule", extension=>"pm" });


=back

=head1 SEE ALSO

B<Parse::RandGen>,
B<Parse::RandGen::Grammar>,
B<Parse::RandGen::Production>, and
B<Parse::RandGen::Condition>

=head1 AUTHORS

Jeff Dutton

=cut
######################################################################
