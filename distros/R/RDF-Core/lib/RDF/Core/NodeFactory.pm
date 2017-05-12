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

package RDF::Core::NodeFactory;

use strict;
require Exporter;

require RDF::Core::Resource;
require RDF::Core::Literal;
use Carp;
use URI;

sub new {
    my ($pkg,%options) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    if (@_ > 0) {
	$self->{_options} = \%options;
    }
    $self->{_options}->{BaseURI} ||= 'uri:';
    bless $self, $pkg;
}
sub setOptions {
    my ($self, $options) = @_;
    $self->{_options} = $options;
}
sub getOptions {
    return $_[0]->{_options};
}
sub newLiteral {
    my ($self, $value, $lang, $datatype) = @_;
    return new RDF::Core::Literal ($value, $lang, $datatype);
}
sub newResource {
    my $self = shift;
    my $resource;
    if (@_ gt 1) {
	#more then one parameters is interpreted as ($namespace,$localValue) 
	#pair, unless both of them are undef
	my ($namespace,$localValue) = @_;

	return $self->newResource
	  if !defined $namespace && !defined $localValue;

	if (!defined $namespace) {
	    croak "Resource's namespace must be defined"
	}
	$localValue = ''
	  unless defined $localValue;
	my $absoluteURI = new_abs URI($namespace, $self->getOptions->{BaseURI});
	$resource = new RDF::Core::Resource($absoluteURI->as_string, $localValue);
    } else {
	#one parameter is URI or bNode label
	my ($URI) = @_;
	if (defined $URI) {
	    if ($URI !~ /^_:/ && defined $self->getOptions->{BaseURI}) {
		my $absoluteURI = new_abs URI($URI, $self->getOptions->{BaseURI});
		$resource = new RDF::Core::Resource($absoluteURI->as_string);
	    } else {
		$resource = new RDF::Core::Resource($URI);
	    }
	} else {
	    #no parameter or parameter undef - generate bNode label
	    $resource = new RDF::Core::Resource($self->_generateURI);
	}
    }
    return $resource;
}
sub _generateURI {
    my $self = shift;
    $self->getOptions->{GenPrefix} = '_:a'
      unless defined $self->getOptions->{GenPrefix};
    $self->getOptions->{GenCounter} = 0
      unless defined $self->getOptions->{GenCounter};
    my $bNode = $self->getOptions->{GenPrefix}.
      $self->getOptions->{GenCounter}++;
    return $bNode
}
1;
__END__

=head1 NAME

RDF::Core::NodeFactory - produces literals and resources, generates labels for anonymous resources

=head1 SYNOPSIS

  require RDF::Core::NodeFactory;
  my $factory = new RDF::Core::NodeFactory(BaseURI=>'http://www.foo.org/');
  my $resource = $factory->newResource('http://www.foo.org/pages');

  #get the same uri:
  my $absolutizedResource = $factory->newResource('/pages');

  #anonymous resource
  my $generatedResource = $factory->newResource;

=head1 DESCRIPTION

NodeFactory generates RDF graph nodes - literals and resources. The resources' URIs are expanded against base uri (BaseURI option) to their absolute forms using URI module. NodeFactory can generate unique 'anonymous' resources.

=head2 Interface

=over 4

=item * new(%options)

Available options are:

=over 4

=item * BaseURI

When NodeFactory generates a resource from relative URI, BaseURI is used to obtain absolute URI. BaseURI must be absolute. Default value is 'uri:'.

=item * GenPrefix, GenCounter

Is used to generate bNode label (an anonymous resource). Default values are '_:a' for GenPrefix and 0 for GenCounter. Resulting label is concatenation of GenPrefix and GenCounter.

=back

=item * getOptions

=item * setOptions(\%options)

=item * newLiteral($value)

=item * newResource($namespace, $localValue)

=item * newResource($uri)

=item * newResource

=back


=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

URI, RDF::Core::Resource, RDF::Core::Literal

=cut
