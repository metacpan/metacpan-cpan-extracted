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

package RDF::Core::Schema;

use strict;

use RDF::Core::Constants qw(:rdf :rdfs);
require RDF::Core::NodeFactory;
require RDF::Core::Model;

use vars qw(@ISA);
@ISA = qw(RDF::Core::Model);

=pod 

=head1 NAME

RDF::Core::Schema - The RDF Schema access

=head1 SYNOPSIS

require RDF::Core::Schema;

my $schema = new RDF::Core::Schema();
$schema->getClasses;

=head1 DESCRIPTION

This module provides the basic interface (OO) for RDF Schema manipulation.

B<Interface>

=over

=item * new(Storage=>$storage, Factory => $factory)

Construct the object. $storage is the RDF::Core::Storage object that contains schema data. $factory may specify the RDF::Core::Factory to be used.  

=cut

sub new {
    my ($class, %params) = @_;
    #die "The Model must be an instance of RDF::Core::Model"
    #  unless $params{Model}->isa("RDF::Core::Model");
    $class = ref $class || $class;
    my $self = $class->SUPER::new(%params);
    $self->{_options}{_factory} = 
      $params{Factory} || new RDF::Core::NodeFactory;
    return $self;
}

sub factory {
    my $self = shift;
    return $self->{_options}{_factory};
}

# sub model {
#     my $self = shift;
#     return $self->{Model};
# }

sub _getResource {
    my ($self, $x) = @_;
    return (ref $x && $x->isa("RDF::Core::Resource")) ? $x :
      $self->factory->newResource($x);
}

=pod

=item * getClasses

Return all classes defined in the model.

=cut

sub getClasses {
    my $self = shift;
    my $ret = [];
    my $p = $self->factory->newResource(RDF_TYPE);
    my $o = $self->factory->newResource(RDFS_CLASS);
    my $enum = $self->getStmts(undef, $p, $o);
    my $stmt = $enum->getFirst;
    while ($stmt) {
	push @$ret, $stmt->getSubject;
	$stmt = $enum->getNext;
    }
    return $ret;
}

=pod 

=item * getSubClasses($class, $deep)

Get all subclasses of given $class. $class may be either URI string or
RDF::Core::Resource. If $deep is true, inheritance takes a deal.

=cut

sub doGetSubClasses {
    #$path is used to prevent a circular reference
    my ($self, $class, $deep, $ret, $path, $depth) = @_;

    #check circular ref in subclassing
    if ($$path{$class->getURI}) {
	my $u = $class->getURI;
	die "Circular reference in RDF scheme (sublassing of [$u])";
    }

    my $p = $self->factory->newResource(RDFS_SUBCLASS_OF);
    my $enum = $self->getStmts(undef, $p, $class);
    my $stmt = $enum->getFirst;
    while ($stmt) {
	my $s = $stmt->getSubject;
	unless (exists $$ret{$s->getURI}) {
	    $$ret{$s->getURI} = [$s, $depth];	      
	    #recursive processing
	    if ($deep) {
		$$path{$class->getURI}++;
		$self->doGetSubClasses($s, $deep, $ret, $path, $depth + 1);
		$$path{$class->getURI}--;
	    }
	}
	$stmt = $enum->getNext;
    }
}

sub getSubClasses {
    my ($self, $class, $deep) = @_;
    my $aux = {};
    my $c = $self->_getResource($class);
    $self->doGetSubClasses($c, $deep, $aux, {});
    return [map {$$aux{$_}[0]}
	    sort {$$aux{$a}[1] <=> $$aux{$b}[1]} keys %$aux];
}

=pod

=item * getAncestors($class, $deep)

Get all ancestors of a given $class. $class may be either URI string
or RDF::Core::Resource. If $deep is true, inheritance takes a deal.

=cut

sub doGetAncestors {
    #$path is used to prevent a circular reference
    #if $match is defined, method just searches for given resource
    #and return immediatelly after $match is found
    my ($self, $class, $deep, $ret, $path, $match, $depth) = @_;

    #check circular ref in subclassing
    if ($$path{$class->getURI}) {
	my $u = $class->getURI;
	die "Circular reference in RDF scheme (sublassing of [$u])";
    }

    my $p = $self->factory->newResource(RDFS_SUBCLASS_OF);
    my $enum = $self->getStmts($class, $p, undef);
    my $stmt = $enum->getFirst;
    while ($stmt) {
	my $o = $stmt->getObject;
	#functon mode
        return 1 if defined $match && $match->getURI eq $o->getURI;
	unless (exists $$ret{$o->getURI}) {
	    $$ret{$o->getURI} = [$o, $depth];
	    if ($deep || $match) {
		#recursive processing
		$$path{$class->getURI}++;
		return 1 if $self->doGetAncestors($o, $deep, $ret, 
						  $path, $match, $depth + 1);
		$$path{$class->getURI}--;
	    }
	}
	$stmt = $enum->getNext;
	
    }
    return 0;
}

sub getAncestors {
    my ($self, $class, $deep) = @_;
    my $aux = {};
    my $c = $self->_getResource($class);
    $self->doGetAncestors($c, $deep, $aux, {});
    return [map {$$aux{$_}[0]}
	    sort {$$aux{$a}[1] <=> $$aux{$b}[1]} keys %$aux];
}

=pod

=item * isSubClassOf($what, $whos)

Tells, whether $what is a subless of $whom. Both of parameters may be
either of RDF::Core::Resource or URI string.

=cut

sub isSubClassOf {
    my ($self, $what, $whos) = @_;
    my $c1 = $self->_getResource($what);
    my $c2 = $self->_getResource($whos);
    return $self->doGetAncestors($c1, 1, {}, {}, $c2);
}

=pod

=item * getSubProperties($property, $deep)

Get all subproperties of given $property. $property may be either URI
string or RDF::Core::Resource. If $deep is true, inheritance takes a deal.

=cut

sub doGetSubProperties {
    #$path is used to prevent a circular reference
    my ($self, $prop, $deep, $ret, $path, $depth) = @_;

    #check circular ref in subclassing
    if ($$path{$prop->getURI}) {
	my $u = $prop->getURI;
	die "Circular reference in RDF scheme (property subclassing of [$u])";
    }

    my $p = $self->factory->newResource(RDFS_SUBPROPERTY_OF);
    my $enum = $self->getStmts(undef, $p, $prop);
    my $stmt = $enum->getFirst;
    while ($stmt) {
	my $s = $stmt->getSubject;
	unless (exists $$ret{$s->getURI}) {
	    $$ret{$s->getURI} = [$s, $depth];
	    if ($deep) {
		#recursive processing
		$$path{$prop->getURI}++;
		$self->doGetSubProperties($s, $deep, $ret, $path, $depth + 1);
		$$path{$prop->getURI}--;
	    }
	}
	$stmt = $enum->getNext;
    }
}

sub getSubProperties {
    my ($self, $prop, $deep) = @_;
    my $aux = {};
    my $p = $self->_getResource($prop);
    $self->doGetSubProperties($p, $deep, $aux, {});
    return [map {$$aux{$_}[0]}
	    sort {$$aux{$a}[1] <=> $$aux{$b}[1]} keys %$aux];
}

=pod

=item * getAncestorProperties($property, $deep)

Get all ancestor properties of given $property. $property may be either URI string or RDF::Core::Resource. If $deep is true, inheritance takes a deal.

=cut

sub doGetAncestorProperties {
    #$path is used to prevent a circular reference
    #if $match is defined, method just searches for given resource
    #and return immediatelly after $match is found
    my ($self, $prop, $deep, $ret, $path, $match, $depth) = @_;

    #check circular ref in subclassing
    if ($$path{$prop->getURI}) {
	my $u = $prop->getURI;
	die "Circular reference in RDF scheme (property subclassing of [$u])";
    }

    my $p = $self->factory->newResource(RDFS_SUBPROPERTY_OF);
    my $enum = $self->getStmts($prop, $p, undef);
    my $stmt = $enum->getFirst;
    while ($stmt) {
	my $o = $stmt->getObject;
	return 1 if defined $match && $match->getURI eq $o->getURI;
	unless (exists $$ret{$o->getURI}) {
	    $$ret{$o->getURI} = [$o, $depth];
	    if ($deep || $match) {
		#recursive processing
		$$path{$prop->getURI}++;
		return 1 
		  if $self->doGetAncestorProperties($o, $deep, $ret, 
						    $path, $match, $depth + 1);
		$$path{$prop->getURI}--;
	    }
	}
	$stmt = $enum->getNext;
    }
    return 0;
}

sub getAncestorProperties {
    my ($self, $prop, $deep) = @_;
    my $aux = {};
    my $c = $self->_getResource($prop);
    $self->doGetAncestorProperties($c, $deep, $aux, {});
    return [map {$$aux{$_}[0]}
	    sort {$$aux{$a}[1] <=> $$aux{$b}[1]} keys %$aux];
}

=pod

=item * isSubClassOf($waht, $whos)

Tells, whether $what is a subless of $whom. Both of parameters may be
either of RDF::Core::Resource or URI string.

=cut

sub isSubPropertyOf {
    my ($self, $what, $whos) = @_;
    my $c1 = $self->_getResource($what);
    my $c2 = $self->_getResource($whos);
    return $self->doGetAncestorProperties($c1, 1, {}, {}, $c2);
}

=pod

=item getPropertiesOf($class, $deep)

Get all properties of given $class. No inheritance rules are applied,
since they are not defined in RDF Schema. $class may be either URI
string or RDF::Core::Resource. If $deep is true, inheritance takes a deal.

=cut

sub getPropertiesOf {
    my ($self, $class, $deep) = @_;

    my $c = $self->_getResource($class);
    my $classes = $deep ? $self->getAncestors($c, 1) : [];
    push @$classes, $c;

    my %ret;
    my $idx;
    my $p = $self->factory->newResource(RDFS_DOMAIN);
    foreach my $x (@$classes) {
	my $enum = $self->getStmts(undef, $p, $x);
	my $stmt = $enum->getFirst;
	while ($stmt) {
	    my $uri = $stmt->getSubject->getURI;
	    die "Duplicit property [$uri] for @{[$x->getURI]}" 
	      if exists $ret{$uri};
	    $ret{$uri} = [$idx++, $stmt->getSubject];
	    $stmt = $enum->getNext;
	}
    }

    return [map {$ret{$_}[1]} sort {$ret{$a}[0] <=> $ret{$b}[0]} keys %ret];
}

=pod 

=back

=cut
