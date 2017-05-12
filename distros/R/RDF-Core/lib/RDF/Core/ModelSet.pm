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

package RDF::Core::ModelSet;

use strict;
require Exporter;


use Carp;

sub new {
    my $pkg = shift;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    bless $self, $pkg;
}
sub addModel {
    my ($self, $label, $model) = @_;
    $self->{_models}->{$label} = $model;
}
sub removeModel {
    my ($self, $label) = @_;
    delete $self->{_models}->{$label};
}
sub existsStmt {
    my ($self) = shift;
    my $retval = 0;
    foreach my $label (keys $self->{_models}) {
	if ($self->{_models}->{$label}->existsStmt @_) {
	    $retval = 1;
	    last;
	}
    }
}
sub getStmts {
    my $self = shift;
    #TODO: union of enumerators or duplicate values?
}
1;
__END__

=head1 NAME

RDF::Core::ModelSet - RDF model set

=head1 SYNOPSIS

To be done

=head1 DESCRIPTION

To be done

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Statement, RDF::Core::Storage, RDF::Core::Serializer, RDF::Core::Parser, RDF::Core::Enumerator

=cut
