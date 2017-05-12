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

package RDF::Core::Resource;

use strict;

require Exporter;


our @ISA = qw(RDF::Core::Node);

use Carp;
require RDF::Core::Node;

sub new {
    my $pkg = shift;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    my $namespace;
    my $localValue;
    bless $self,$pkg;
    if (@_ gt 1) {
	#more then one parameters is interpreted as ($namespace,$localValue) pair
	($namespace,$localValue) = @_;
	croak "Resource's namespace must be defined"
	  unless defined $namespace;
	$localValue = ''
	  unless defined $localValue;
    } else {
	#one parameter is URI
	my ($URI) = @_;
	croak "Resource's URI must be defined"
	  unless defined $URI;
	$self->_resolveURI($URI,\$namespace,\$localValue);
    }
    $self->{_namespace} = $namespace;
    $self->{_localValue} = $localValue;
    $self->{_uri} = $namespace.$localValue;

    return $self;
}
sub getNamespace {
    return $_[0]->{_namespace};
}
sub getLocalValue {
    return $_[0]->{_localValue};
}
sub getURI {
    return $_[0]->{_uri};
}
#Override inherited method
sub getLabel {
    return $_[0]->getURI;
}
sub clone {
    my $self = shift;
    return $self->new($self->{_namespace}, $self->{_localValue});
}

sub equals {
    my ($self, $other) = @_;
    $other = new RDF::Core::Resource($other) 
      unless ref $other && $other->isa("RDF::Core::Node");
    return !$self->isLiteral && $self->getURI eq $other->getURI;
}

sub _resolveURI {
    my ($self,$URI,$ns,$lv)=@_;
    if ($URI=~/(^.*[\/#:])([a-zA-Z_][^\/#:]*$)/) {
	$$ns = $1;
	$$lv = $2;
    } else {
	$$ns = $URI;
	$$lv = '';
    }
}

1;
__END__


=head1 NAME

RDF::Core::Resource - a resource for RDF statement

=head1 SYNOPSIS

  require RDF::Core::Resource;
  my $resource=new RDF::Core::Resource("http://www.gingerall.cz/employees#","Jim");
  print $resource->getURI()."\n";


=head1 DESCRIPTION

Is inherited from RDF::Core::Node

It just knows it's URI. If it's created with two parameters (namespace and local value), it remembers the settings. Else it makes its own guess what namespace is.

=head2 Interface

=over 4

=item * new($URI)

=item * new($namespace,$localValue)

=item * getURI

=item * getNamespace

=item * getLocalValue

=item * equals($other)

=back


=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

perl(1).

=cut
