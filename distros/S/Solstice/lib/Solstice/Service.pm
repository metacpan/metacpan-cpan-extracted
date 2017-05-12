package Solstice::Service;

# $Id: Service.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::Service - Superclass for all services.  A service provides request-lifecycle-long caching of information.

=head1 SYNOPSIS

  use base qw(Solstice::Service);

  sub new {
    my $obj = shift;
    return $obj->SUPER::new(@_);
  }

=head1 DESCRIPTION

Creates an API for subclasses to use to manage and make available global data. 

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);
our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

our $data_store = {};

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new()

Creates a new Solstice::Service object.

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_); 
    return $self;
}

=item setNamespace($str)

Sets the namespace on a per-object basis.

=cut

sub setNamespace {
    my $self = shift;
    $self->{'_namespace'} = shift;
}

=item getNamespace()

Return the current namespace

=cut

sub getNamespace {
    my $self = shift;
    return $self->{'_namespace'};
}

=item getValue($str)

Returns the entity tied to the given key, in this namespace. The 
namespace is defined as the name of the derived subclass 
with the pid of the apache thread.

=cut

sub getValue {
    my $self = shift;
    my $key = shift;
    return $self->_getDataStore()->{$self->_getKeyname($key)};
}

=item setValue($str, $str)

Will store the value entity, tied to the 
key in our namespace. The namespace is defined as the name of 
the derived subclass with the pid of the apache thread.

=cut

sub setValue {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->_getDataStore()->{$self->_getKeyname($key)} = $value;
}

=item get()

Alias for getValue().

=cut

sub get {
    my $self = shift;
    return $self->getValue(@_);
}

=item set()

Alias for setValue().

=cut

sub set {
    my $self = shift;
    return $self->setValue(@_);
}

=back

=head2 Private Methods

=over 4

=cut


=item _getDataStore()

Return the global datastore hashref.

=cut

sub _getDataStore {
    return $data_store;
}

=item _getClassName()

Returns the result of ref($self). This can be overridden in a subclass
to eliminate the ref(), by just returning a string containing the package
name. Be careful when overriding this method in superclasses!

=cut

sub _getClassName {
    my $self = shift;
    return ref($self);
}

=item _getKeyname()

Returns a generated string for use as a hash key in the object's datastore.

=cut

sub _getKeyname {
    my $self = shift;
    my $key  = shift || 'generic';
    return $$.':'.$self->_getClassName().':'.$key;
}

1;
__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
