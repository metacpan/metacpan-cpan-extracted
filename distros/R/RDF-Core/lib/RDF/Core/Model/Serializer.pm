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

package RDF::Core::Model::Serializer;

use strict;
require Exporter;

use Carp;
require RDF::Core::Serializer;

use constant RDF_NS => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

sub new {
    my ($pkg,%options) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    $self->{_options} = \%options;
    $self->{_prefix} = '';
    $self->{_subjects} = undef;
    $self->{_namespaces} = undef;
    bless $self, $pkg;
}
sub setOptions {
    my ($self,$options) = @_;
    $self->{_options} = $options;
}
sub getOptions {
    my $self = shift;
    return $self->{_options};
}
sub serialize {
    my $self = shift;
    if (@_ > 0) {
	#get options if passed
	$self->{_options} = $_[0];
    }
    my $serializer = new RDF::Core::Serializer
      (getSubjects => 
       #once you iterate through statements, store both subjects and namespaces
       $self->getOptions->{getSubjects} ||
       sub {
	   my $subjects = {};
	   my $namespaces = {};
	   if (defined $self->{_subjects}) {
	       $subjects = $self->{_subjects};
	       $self->{_subjects} = undef; #We won't call this second time anyway
	   } else {
	       my $enumerator = $self->getOptions->{Model}->
		 getStmts(undef,undef,undef);
	       my $statement = $enumerator->getNext;
	       $namespaces->{+RDF_NS} = 'rdf';
	       while (defined $statement) {
		   $subjects->{$statement->getSubject->getURI}=
		     [$statement->getSubject,0,0];
		   $namespaces->{$statement->getPredicate->getNamespace} = 
		     $self->_makePrefix
		       unless exists $namespaces->{$statement->getPredicate->
						   getNamespace} ;
		   $statement = $enumerator->getNext;
	       }
	       $enumerator->close;
	       $self->{_namespaces} = $namespaces;
	   }
	   return $subjects;
       },
       getNamespaces => 
       #once you iterate through statements, store both subjects and namespaces
       $self->getOptions->{getNamespaces} ||
       sub {
	   my $subjects = {};
	   my $namespaces = {};
	   if (defined $self->{_namespaces}) {
	       $namespaces = $self->{_namespaces};
	       $self->{_namespaces} = undef; #We won't call this second time anyway
	   } else {
	       my $enumerator = $self->getOptions->{Model}->
		 getStmts(undef,undef,undef);
	       my $statement = $enumerator->getNext;
	       $namespaces->{+RDF_NS} = 'rdf';
	       while (defined $statement) {
		   $subjects->{$statement->getSubject->getURI}=
		     [$statement->getSubject,0,0];
		   $namespaces->{$statement->getPredicate->getNamespace} = 
		     $self->_makePrefix
		     unless exists $namespaces->{$statement->getPredicate->
						 getNamespace} ;
		   $statement = $enumerator->getNext;
	       }
	       $enumerator->close;
	       $self->{_subjects} = $subjects;
	   }
	   return $namespaces;
       },
       getStatements => 
       $self->getOptions->{getStatements} ||
       sub {
	   my ($subject, $predicate, $object) = @_;
	   my $enumerator = $self->getOptions->{Model}->
	     getStmts($subject,$predicate,$object);
	   return $enumerator;
       },
       countStatements => 
       $self->getOptions->{countStatements} ||
       sub {
	   my ($subject, $predicate, $object) = @_;
	   return $self->getOptions->{Model}->
	     countStmts($subject,$predicate,$object);
       },
       existsStatement => 
       $self->getOptions->{existsStatement} ||
       sub {
	   my ($subject, $predicate, $object) = @_;
	   return $self->getOptions->{Model}->
	     existsStmt($subject,$predicate,$object);
       },
       Output => $self->getOptions->{Output},
       BaseURI => $self->getOptions->{BaseURI},
      );
    $serializer->serialize;
}
sub _makePrefix {
    my $self = shift;
    $self->{_prefix} ||= 'a';
    return $self->{_prefix}++;
}
1;
__END__

=head1 NAME

  RDF::Core::Model::Serializer - interface between model and RDF::Core::Serializer

=head1 SYNOPSIS

  require RDF::Core::Model::Serializer;

  my $xml = '';
  my $serializer = new RDF::Core::Model::Serializer(Model=>$model,
                                                    Output=>\$xml,
                                                    BaseURI => 'URI://BASE/',
                                                   );
  $serializer->serialize;
  print "$xml\n";



=head1 DESCRIPTION

A Model::Serializer object sets handlers for serializer, connecting the serializer with a specific model. 

=head2 Interface

=over 4

=item * new(%options)

Available options are:

=over 4

=item * Model

A reference to RDF::Core::Model object - the RDF model I want to serialize.

=item * Output, BaseURI

See RDF::Core::Serializer options

=item * getSubjects, getNamespaces, getStatements, countStatements, existsStatement

While the module provides defaults for each handler, you can override any of them. See RDF::Core::Serializer for details.

=back

=item * getOptions

=item * setOptions(\%options)

=item * serialize

=back

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Serializer, RDF::Core::Model

=cut





