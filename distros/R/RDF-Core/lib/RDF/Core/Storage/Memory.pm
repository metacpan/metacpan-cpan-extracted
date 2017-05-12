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

package RDF::Core::Storage::Memory;

use strict;
require Exporter;

our @ISA = qw(RDF::Core::Storage);

use Carp;
require RDF::Core::Storage;
require RDF::Core::Enumerator::Memory;
sub new {
    my ($pkg) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    #data
    $self->{_data} = {};
    #indexes - each element keeps an array of its statements
    $self->{_subjects} = {};
    $self->{_objects} = {};
    $self->{_predicates} = {};
    bless $self, $pkg;
}
sub addStmt {
    my ($self, $stmt) = @_;
    return 0 if $self->existsStmt($stmt->getSubject,$stmt->getPredicate,$stmt->getObject);
    my $clone = $stmt->clone;
    my $index = $self->_getCounter('statement');

    $self->{_subjects}->{$stmt->getSubject->getURI}=[]
      unless (exists $self->{_subjects}->{$stmt->getSubject->getURI});
    push(@{$self->{_subjects}->{$stmt->getSubject->getURI}},$index);
    $self->{_predicates}->{$stmt->getPredicate->getURI}=[]
      unless (exists $self->{_predicates}->{$stmt->getPredicate->getURI});
    push(@{$self->{_predicates}->{$stmt->getPredicate->getURI}},$index);
    $self->{_objects}->{$stmt->getObject->getLabel}=[]
      unless (exists $self->{_objects}->{$stmt->getObject->getLabel});
    push(@{$self->{_objects}->{$stmt->getObject->getLabel}},$index);

    $self->{_data}->{$index} = $clone;
    return 1;
}
sub removeStmt {
    my ($self, $stmt) = @_;
    return unless
      my $key = $self->_getKey($stmt);
    my $index;
    #remove from subjects index
    my $label = $stmt->getSubject->getLabel;
    my $lastIndex = @{$self->{_subjects}->{$label}} - 1;
    for (my $i = 0;$i <= $lastIndex; $i++) {
	if ($key eq $self->{_subjects}->{$label}->[$i]) {
	    $index = $i;
	    last;
	}
    }
    $self->{_subjects}->{$label}->[$index] = $self->{_subjects}->{$label}->[$lastIndex]
      unless $index == $lastIndex;
    delete $self->{_subjects}->{$label}->[$lastIndex];
    delete $self->{_subjects}->{$label}
      if $lastIndex == 0;

    #remove from predicates index
    $label = $stmt->getPredicate->getLabel;
    $lastIndex = @{$self->{_predicates}->{$label}} - 1;
    for (my $i = 0;$i <= $lastIndex;$i++) {
	if ($key eq $self->{_predicates}->{$label}->[$i]) {
	    $index = $i;
	    last;
	}
    }
    $self->{_predicates}->{$label}->[$index] = $self->{_predicates}->{$label}->[$lastIndex]
      unless $index == $lastIndex;
    delete $self->{_predicates}->{$label}->[$lastIndex];
    delete $self->{_predicates}->{$label}
      if $lastIndex == 0;

    #remove from objects index
    $label = $stmt->getObject->getLabel;
    $lastIndex = @{$self->{_objects}->{$label}} - 1;
    for (my $i = 0;$i <= $lastIndex;$i++) {
	if ($key eq $self->{_objects}->{$label}->[$i]) {
	    $index = $i;
	    last;
	}
    }
    $self->{_objects}->{$label}->[$index] = $self->{_objects}->{$label}->[$lastIndex]
      unless $index == $lastIndex;
    delete $self->{_objects}->{$label}->[$lastIndex];
    delete $self->{_objects}->{$label}
      if $lastIndex == 0;

    delete $self->{_data}->{$key};

}
sub existsStmt {
    my ($self, $subject, $predicate, $object) = @_;

    my $indexArray = $self->_getIndexArray($subject, $predicate, $object);
    foreach (@$indexArray) {
	if ((!defined $subject || $self->{_data}->{$_}->getSubject->getURI eq $subject->getURI) && 
	   (!defined $predicate || $self->{_data}->{$_}->getPredicate->getURI eq $predicate->getURI) && 
	   (!defined $object || (
			$self->{_data}->{$_}->getObject->isLiteral
				? ($object->equals($self->{_data}->{$_}->getObject))
				: $self->{_data}->{$_}->getObject->getLabel eq $object->getLabel
		))) {
	    return 1; #found statement
	}
    }
    return 0; #didn't find statement
}
sub getStmts {
    my ($self, $subject, $predicate, $object) = @_;
    my @data ;

    my @indexArray = @{$self->_getIndexArray($subject, $predicate, $object)};
    foreach (@indexArray) {
	if ((!defined $subject || $self->{_data}->{$_}->getSubject->getURI eq $subject->getURI) && 
	    (!defined $predicate || $self->{_data}->{$_}->getPredicate->getURI eq $predicate->getURI) && 
	    (!defined $object || (
			$self->{_data}->{$_}->getObject->isLiteral
				? ($object->equals($self->{_data}->{$_}->getObject))
				: $self->{_data}->{$_}->getObject->getLabel eq $object->getLabel
		))) {
	    push(@data,$self->{_data}->{$_});
	}
    }
    return RDF::Core::Enumerator::Memory->new(\@data) ;

}
sub countStmts {
    my ($self, $subject, $predicate, $object) = @_;

    my $count = 0;
    return $count = keys %{$self->{_data}}
      unless defined $subject || defined $predicate || defined $object;
    my @indexArray = @{$self->_getIndexArray($subject, $predicate, $object)};
    foreach (@indexArray) {
	if ((!defined $subject || $self->{_data}->{$_}->getSubject->getURI eq $subject->getURI) && 
	    (!defined $predicate || $self->{_data}->{$_}->getPredicate->getURI eq $predicate->getURI) && 
	    (!defined $object || (
			$self->{_data}->{$_}->getObject->isLiteral
				? ($object->equals($self->{_data}->{$_}->getObject))
				: $self->{_data}->{$_}->getObject->getLabel eq $object->getLabel
		))) {
	    $count++;
	}
    }
    return $count;

}
sub _getCounter {
    my ($self,$counterName) = @_;
    return $self->{'_'.$counterName} = ++$self->{'_'.$counterName} || 1;
}
sub _getKey {
    #Same as existsStmt, but returns key of statement and doesn't handle undef elements (takes $stmt as a parameter)
    my ($self, $stmt) = @_;

    my @indexArray = @{$self->_getIndexArray($stmt->getSubject, $stmt->getPredicate, $stmt->getObject)};
    foreach (@indexArray) {
 	if ($self->{_data}->{$_}->getSubject->getURI eq $stmt->getSubject->getURI && 
	    $self->{_data}->{$_}->getPredicate->getURI eq $stmt->getPredicate->getURI && 
	    ($self->{_data}->{$_}->getObject->isLiteral
				? ($stmt->getObject->equals($self->{_data}->{$_}->getObject))
				: $self->{_data}->{$_}->getObject->getLabel eq $stmt->getObject->getLabel)) {
 	    return $_;		#found statement
	}
    }
    return 0;			#didn't find statement
}
sub _getIndexArray {
    #find the smallest index to search statement
    my ($self, $subject, $predicate, $object) = @_;
    my $indexArray;
    my $found = 0;

    return [] #if didn't find the subject|predicate|object
      unless ((!defined $subject || exists $self->{_subjects}->{$subject->getURI})&&
	      (!defined $predicate || exists $self->{_predicates}->{$predicate->getURI}) &&
	      (!defined $object || exists $self->{_objects}->{$object->getLabel}));


    $indexArray = $self->{_subjects}->{$subject->getURI}
      if defined $subject;
    $indexArray = $self->{_predicates}->{$predicate->getURI}
      if defined $predicate && (!defined $indexArray || @$indexArray gt @{$self->{_predicates}->{$predicate->getURI}});
    $indexArray = $self->{_objects}->{$object->getLabel}
      if defined $object && (!defined $indexArray || @$indexArray gt @{$self->{_objects}->{$object->getLabel}});
    if (!defined $indexArray) {
	my @allData = keys %{$self->{_data}};
	$indexArray = \@allData; #\@{keys %{$self->{_data}}};
    }
    return $indexArray;
}
1;
__END__

=head1 NAME

RDF::Core::Storage::Memory - An in-memory implementation of RDF::Core::Storage

=head1 SYNOPSIS

  require RDF::Core::Storage::Memory;

  my $storage = new RDF::Core::Storage::Memory;
  my $model = new RDF::Core::Model (Storage => $storage);


=head1 DESCRIPTION



=head2 Interface

=over 4

=item * new

The constructor creates an empty storage in memory. It has no parameters.

=back

The rest of the interface is described in RDF::Core::Storage.


=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Storage, RDF::Core::Model, RDF::Core::Enumerator

=cut
