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

package RDF::Core::Model;

use strict;
require Exporter;

require RDF::Core::Resource;
use RDF::Core::Constants qw(:rdf);

use Carp;

sub new {
    my ($pkg,%options) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    $self->{_options} = \%options;
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
sub addStmt {
    my $self = shift;
    carp "No storage defined"
      unless exists $self->{_options}->{Storage} &&
	defined $self->{_options}->{Storage} &&
	  ref  $self->{_options}->{Storage};
     $self->{_options}->{Storage}->addStmt(@_);
}
sub removeStmt {
    my $self = shift;
    carp "No storage defined"
      unless exists $self->{_options}->{Storage} &&
	defined $self->{_options}->{Storage} &&
	  ref  $self->{_options}->{Storage};
     $self->{_options}->{Storage}->removeStmt(@_);
}
sub existsStmt {
    my $self = shift;
    carp "No storage defined"
      unless exists $self->{_options}->{Storage} &&
	defined $self->{_options}->{Storage} &&
	  ref  $self->{_options}->{Storage};
     $self->{_options}->{Storage}->existsStmt(@_);
}
sub getStmts {
    my $self = shift;
    carp "No storage defined"
      unless exists $self->{_options}->{Storage} &&
	defined $self->{_options}->{Storage} &&
	  ref  $self->{_options}->{Storage};
     $self->{_options}->{Storage}->getStmts(@_);
}
sub countStmts {
    my $self = shift;
    carp "No storage defined"
      unless exists $self->{_options}->{Storage} &&
	defined $self->{_options}->{Storage} &&
	  ref  $self->{_options}->{Storage};
     $self->{_options}->{Storage}->countStmts(@_);
}

sub getObjects {
    my ($self, $subj, $pred) = @_;
    $subj = new RDF::Core::Resource($subj)
      unless (ref $subj && $subj->isa("RDF::Core::Resource"));
    $pred = new RDF::Core::Resource($pred)
      unless (ref $pred && $pred->isa("RDF::Core::Resource"));
    my $enum = $self->getStmts($subj, $pred, undef);
    my $stmt = $enum->getFirst;
    my $ret = [];
    while ($stmt) {
	push @$ret, $stmt->getObject;
	$stmt = $enum->getNext;
    }
    return $ret;
}

sub _rdf_container_sort {
    my ($a, $b) = @_;
    my $aa = $1 if $a->getPredicate->getURI =~ /.*#_(\d+)/;
    my $bb = $1 if $b->getPredicate->getURI =~ /.*#_(\d+)/;
    return $aa <=> $bb;
}

sub getContainerObjects {
    my ($self, $cont) = @_;
    my $members = $self->getStmts($cont, undef, undef);
    my $member = $members->getFirst;
    my @arr;
    while ($member) {
	push @arr, $member unless $member->getPredicate->equals(RDF_TYPE);
	$member = $members->getNext;
    }
    
    return [map {$_->getObject} sort {_rdf_container_sort($a, $b)} @arr];
}

1;
__END__

=head1 NAME

RDF::Core::Model - RDF model

=head1 SYNOPSIS

  my $storage = new RDF::Core::Storage::Memory;
  my $model = new RDF::Core::Model (Storage => $storage);
  my $subject = new RDF::Core::Resource('http://www.gingerall.cz/employees/Jim');
  my $predicate = $subject->new('http://www.gingerall.cz/rdfns#name');
  my $object = new RDF::Core::Literal('Jim Brown');
  my $statement = new RDF::Core::Statement($subject, $predicate, $object);

  $model->addStmt($statement);

  print "Model contains ".$model->countStmts."statement(s).\n"

=head1 DESCRIPTION

Model provides interface to store RDF statements, ask about them and retrieve them back.

=head2 Interface

=over 4

=item * new(%options)

$options is a hash reference, available options are 

=over 4

=item * Storage 

a reference to a RDF::Core::Storage implementation

=back

=item * getOptions

=item * setOptions(\%options)

=item * addStmt($statement)

Add RDF::Core::Statement instance to Model, unless it already exists there.

=item * removeStmt($statement)

Remove statement from Model, if it's there.

=item * existsStmt($subject,$predicate,$object)

Check if statement exists, that matches given mask. Parameters can be undefined, every value matches undefined parameter.

=item * countStmts($subject,$predicate,$object)

Count matching statements.

=item * getStmts($subject,$predicate,$object)

Retrieve matching statements. Returns RDF::Core::Enumerator object.

=item * getObjects($subject, $predicate)

Return a reference to an array keeping all objects, that are values of
specified $predicate for given $subject.

=item * getContainerObjects($container)

Return a reference to an array keeping all objects, that are members
of the $container. Objects are sorted.


=back



=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Statement, RDF::Core::Storage, RDF::Core::Serializer, RDF::Core::Parser, RDF::Core::Enumerator

=cut
