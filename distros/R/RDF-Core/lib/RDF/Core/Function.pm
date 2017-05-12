# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the RDF::Core module
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 2001 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s):
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package RDF::Core::Function;

use strict;
require Exporter;

#require RDF::Core::Query;
use Carp;

use RDF::Core::Constants qw(:rdfs);


sub new {
    my ($pkg, %options) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    $self->{_options} = \%options;
    $self->{_functions} = {self=>\&self,
			   subclass=>\&subclass,
			   subproperty=>\&subproperty,
			   member=>\&member,
			  };
    bless $self, $pkg;
}
sub getOptions {
    my $self = shift;
    return $self->{_options};
}
sub getFunctions {
    my $self = shift;
    return $self->{_functions};
}
############################################################

sub self {
    my ($self, $subject, $params) = @_;
    my $retVal = [];
    my $predicates = [];
    $retVal = defined $subject ? [$subject] : [$params->[0]];
    return ($retVal,$predicates);
}
    
sub subclass {
    my ($self, $subject, $params) = @_;
    my $predicates = [];
    
    croak "Function subclass expects one parameter."
      unless @$params == 1;
    croak "Subject parameter not allowed for function subclass." if $subject;
    my @subClasses;
    my $pred = $self->getOptions->{Factory}->newResource(RDFS_SUBCLASS_OF);
    my $enum = $self->getOptions->{Schema}->getStmts(undef,$pred,$params->[0]);
    while (my $st = $enum->getNext) {
	push @subClasses, $st->getSubject;
	my @sub = $self->subclass(undef, [$st->getSubject]);
	push @subClasses, @{$sub[0]};
    }
    $enum->close;
    
    return (\@subClasses, $predicates);
}

sub subproperty {
    my ($self, $subject, $params) = @_;
    my $retVal= [];
    my $predicates = [];
    
    croak "Function subproperty expects one parameter."
      unless @$params == 1;
    my @subProperties;
    my $pred = $self->getOptions->{Factory}->newResource(RDFS_SUBPROPERTY_OF);
    my $enum = $self->getOptions->{Schema}->getStmts(undef,$pred,$params->[0]);
    while (my $st = $enum->getNext) {
	push @subProperties, $st->getSubject;
	my @sub = $self->subproperty(undef, [$st->getSubject]);
	push @subProperties, @{$sub[0]};
    }
    $enum->close;
    if ($subject) {
	unless ($subject->isLiteral) {
	    foreach my $property (@subProperties) {
		my $enum = $self->getOptions->{Data}->getStmts($subject, 
							       $property,
							       undef);
		while (my $st = $enum->getNext) {
		    push @$retVal, $st->getObject;
		    push @$predicates, $st->getPredicate;
		}
		$enum->close;
	    }
	}
    } else {
	$retVal = \@subProperties;
    }
    
    return ($retVal, $predicates);
}

sub member {
    my ($self, $subject, $params) = @_;
    my @retVal;
    my @predicates;
    my @members;
    my @sorted_members;
    
    if ($subject && !$subject->isLiteral) {
	my $enum = $self->getOptions->{Data}->
	  getStmts($subject,undef,undef);
	while (my $st = $enum->getNext) {
	    if ($st->getPredicate->getURI =~ /\#\_(\d+)$/) {
		push @members, [$st->getObject,$st->getPredicate,$1];
	    }
	}
	@sorted_members = sort { $a->[2] <=> $b->[2] } @members;
    }
    foreach (@sorted_members) {
	push @retVal, $_->[0];
	push @predicates, $_->[1];
    }
    return (\@retVal, \@predicates);
}




1;
__END__

=head1 NAME

RDF::Core::Function - a package of functions for query language.

=head1 DESCRIPTION

When there is a function found while evaluating query, its parameters are evaluated and passed to RDF::Core::Function apropriate piece of code. The code reference is obtained in a hash returned by getFunctions() call. Each function accepts RDF::Core::Literal or RDF::Core::Resource objects as paramaters and returns a tuple of arrays (array of two array references). The first references to an array of function results - Resource or Literal objects, the second one references to an array of predicates that could be used instead of the function. This is not always applicable, so the second array can be empty.
For example, a function call:

  someBag.member()

returns ([uri://uri-of-the-first-member,....],[rdf:_1,...]).

There is a special parameter - a subject parameter, which says that a function is at position of property. For example:

  subproperty(schema:SomeProperty)

has no subject parameter defined and returns property B<names> that are subproperties of given schema:SomeProperty.

  data:SomeObject.subproperty(schema:SomeProperty)

has subject parameter data:SomeObject and return B<values> of subproperties for subject.



=head2 Interface

=over 4

=item * new(%options)

Available options are:

=over 4

=item * Data

RDF::Core::Model object that contains data to be queried.

=item * Schema

RDF::Core::Model object that contains RDF schema.

=item * Factory

RDF::Core::NodeFactory object, that produces resource and literal objects.

=back

=item * getFunctions

Returns a hash reference where each key is a name of a functions and value is a reference to an implementation code.

=back

=head2 Functions implemented

=over 4

=item * subclass(X)

Not defined subject parameter:

Find all subclasses of X in Schema and return them if they have an instance in Data.

Defined subject parameter:

Result is not defined, dies.

=item * subproperty(X)

Not defined subject parameter:

Find all subproperties of X in Schema and return them if they occur in Data.

Defined subject parameter:

Find all subproperties of X in Schema and return their values for subject, if found.

=item * member()

Not defined subject parameter:

Result is not defined, dies.

Defined subject parameter:

Find all container members of subject.

=back

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Query

=cut


