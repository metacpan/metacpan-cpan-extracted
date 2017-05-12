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

package Parse::RandGen::Grammar;

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
    my $self = {
	_name => undef,   # Name of the grammar
	_rules => { },    # Rules of the grammar
	_examples => { }, # Examples for various rules in the grammar
        #@_,
    };
    bless $self, ref($class)||$class;

    $self->{_name} = shift or confess("%Error:  Cannot call new without a name for the new grammer (only required argument)!");
    return($self);
}

######################################################################
#### Methods

# Add Rules to the Grammar
sub addRule {
    my $expType = "Parse::RandGen::Rule";
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $rule = shift or confess("%Error:  addRule takes a required $expType object!");
    confess("%Error:  Passed a ".ref($rule)." argument instead of a $expType reference argument!") unless (ref($rule) eq $expType);
    confess("%Error:  Overwriting the existing rule for ", $rule->name(), "!") if exists($self->{_rules}{$rule->name()});
    confess("%Error:  Passed a Rule that already belongs to a different Grammar object!\n") if (defined($rule->grammar()) && ($rule->grammar() != $self));
    $self->{_rules}{$rule->name()} = $rule;    # Save the rule in the _rule hash
    $rule->{_grammar} = $self;                 # Set the rule's grammar to self
}

# Add examples for a particular Rule to the Grammar
sub addExamples {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $ruleName = shift or confess("%Error:  Cannot call without a rule name!");
    (ref($ruleName) eq "") or confess("%Error:  Argument given for a rule name is actually a ".ref($ruleName)." reference!");
    ($self->rule($ruleName)) or confess("%Error:  Cannot find the $ruleName rule on this grammar!");
    my @examples = @_;

    if (!defined($self->{_examples}{$ruleName})) {
	$self->{_examples}{$ruleName} = [ ];   # List of examples for the given rule
    }
    my $exList = $self->{_examples}{$ruleName};
    foreach my $example (@examples) {
	(ref($example) eq "HASH") or confess("%Error:  Example argument should be a HASH reference with \"stat\" and \"val\" entries, but is actually a ".ref($example)." reference!");
	(defined($example->{stat}) && defined($example->{val})) or confess("%Error:  Example hash does not contain both \"stat\" and \"val\" entries!");
	push @$exList, $example;
    }
}

# Check the Grammar for completeness/errors
sub check {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $grammarName = $self->name();

    my $err = "";
    foreach my $ruleName (keys %{$self->{_rules}}) {
	my $rule = $self->rule($ruleName);
	$err .= $rule->check();
    }
    return $err;
}

# Dump the Grammar
sub dump {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $output = "";
    if ($Debug) {
	my $d = Data::Dumper->new([$self]);
	$d->Terse(1);
	$output .= $self->name() . " = " . $d->Dump();
    } else {
	$output .= "#" . $self->name() . " Grammar specification:\n";
	#$output .= "<autotree>\n";
	my @ruleNames = sort keys %{$self->{_rules}};
	foreach my $ruleName (@ruleNames) {
	    $output .= $self->rule($ruleName)->dump();
	}
	$output .= "#  No rules defined...\n" if ($#ruleNames < 0);
    }
    return $output;
}

######################################################################
#### Accessors

sub name {
    my $self = shift or confess("%Error:  Cannot call name() without a valid object!");
    return $self->{_name};
}

sub rule {        # Access the named rule (no side effects:  undef is returned if the rule is not found)
    my $self = shift or confess("%Error:  Cannot call rule() without a valid object!");
    my $name = shift or confess("%Error:  Cannot call rule() without the name of the Rule to find!");
    if (exists($self->{_rules}{$name}) && !defined($self->{_rules}{$name})) { die "Grammar has a rule \"$name\", which references an undefined Rule object!\n"; }
    my $rule = $self->{_rules}{$name} if exists($self->{_rules}{$name});
    return $rule;
}

sub defineRule {  # Access the named rule (if it does not exist, create the rule)
    my $self = shift or confess("%Error:  Cannot call defineRule() without a valid object!");
    my $name = shift or confess("%Error:  Cannot call defineRule() without the name of the Rule to find!");
    exists($self->{_rules}{$name}) and not defined($self->{_rules}{$name}) and die ($self->name() . " Grammar has a rule \"$name\", which references an undefined Rule object!\n");
    exists($self->{_rules}{$name}) and confess($self->name() . "Grammar already has a definition for the \"$name\" rule!\n");
    if (!exists($self->{_rules}{$name})) {
	$self->addRule(Parse::RandGen::Rule->new($name));
    }
    my $rule = $self->{_rules}{$name} or die "%Error:  Failed to create the \"$name\" rule!";
    return $rule;
}

sub ruleNames {
    my $self = shift or confess("%Error:  Cannot call rules() without a valid object!");
    return (sort keys %{$self->{_rules}});
}

sub examples {
    my $self = shift or confess("%Error:  Cannot call without a valid object!");
    my $ruleName = shift or confess("%Error:  Cannot call without a rule name!");
    ($self->rule($ruleName)) or confess("%Error:  Cannot find the $ruleName rule on this grammar!");
    my @examples = ( );

    if (defined($self->{_examples}{$ruleName})) {
	@examples = @{$self->{_examples}{$ruleName}};
    }

    return @examples;
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen::Grammar - Module for defining a language/protocol grammar

=head1 DESCRIPTION

The purpose of this module is to build a grammar description that can
then be used to build:

(1) a parser using Parse::RecDescent

(2) a stimulus generator that creates valid (and interesting invalid)
tests of the grammar.

Be aware of the greediness of the underlying parsing mechanism (RecDescent).
See Parse::RandGen::Production for examples on how greediness can affect
errors in grammars.

=head1 METHODS

=over 4

=item new

Creates a new grammar.  The grammar name is the only required argument.

=item name

Return the name of the grammar.

=item rule

Access an existing Rule object by name.  Returns undef if the Rule is not found.

=item defineRule

Define a Rule if not already defined and return a reference to the Rule.

=item dump

Returns a dump of the Grammar object in Parse::RecDescent grammar format.

=back

=head1 SEE ALSO

B<Parse::RandGen::Rule> and
B<Parse::RandGen::Production>

=head1 AUTHORS

Jeff Dutton

=cut
######################################################################
