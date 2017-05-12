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

package RDF::Core::Literal;

use strict;

require Exporter;

our @ISA = qw(RDF::Core::Node);

use Carp;
require RDF::Core::Node;


sub new {
    my ($pkg, $value, $lang, $datatype)=@_;
    $pkg = ref $pkg || $pkg;
    my $self={};

    $self->{_value} = defined $value ? $value : '';
#    $self->{_lang} = $lang;
#    $self->{_datatype} = $datatype;
    $self->{_lang} = defined $lang ? $lang : '';
    $self->{_datatype} = defined $datatype ? $datatype : '';
    bless $self,$pkg;
}
sub getValue {
    return $_[0]->{_value};
}
sub getLang {
    return $_[0]->{_lang};
}
sub getDatatype {
    return $_[0]->{_datatype};
}
sub equals {
    my ($self, $node) = @_;
    $node = new RDF::Core::Literal($node) 
      unless ref $node && $node->isa("RDF::Core::Node");
    return $node->isLiteral 
      && ($node->getValue eq $self->getValue)
	&& (!$node->getLang && !$self->getLang 
	    || uc($node->getLang) eq uc($self->getLang))
	  && (!$node->getDatatype && !$self->getDatatype 
	      || $node->getDatatype eq $self->getDatatype);
}
#Override inherited method
sub getLabel {
    return $_[0]->getValue;
}
sub clone {
    my $self = shift;
    return $self->new($self->{_value}, $self->{_lang}, $self->{_datatype});
}
1;
__END__

=head1 NAME

RDF::Core::Literal - a literal value for RDF statement

=head1 SYNOPSIS

  require RDF::Core::Literal;
  my $literal=new RDF::Core::Literal("Jim Brown");
  print $literal->getValue()."\n";


=head1 DESCRIPTION

Is inherited from RDF::Core::Node, you can specify it's language and datatype URI.

=head2 Interface

=over 4

=item * new($value)

=item * new($value, $language)

=item * new($value, $language, $datatype)

=item * getValue()

=item * getLang()

=item * getDatatype()

=item * equals($other)

See L<http://www.w3.org/TR/rdf-concepts/#section-Literal-Equality> for details on literal equality.

=back


=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

perl(1).

=cut
