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

package RDF::Core::Enumerator::Postgres;

use strict;
require Exporter;

use Carp;
use DBI;

require RDF::Core::Resource;
require RDF::Core::Literal;
require RDF::Core::Statement;

our @ISA = qw(RDF::Core::Enumerator);

sub new {
    my ($class, %params) = @_;
    $class = ref $class || $class;
    my $self = { 
		cursor => $params{Cursor},
	       };
    bless $self, $class;
    return $self;
}

sub getFirst {
    my $self = shift;
    carp 'Warning: RDF::Core::Enumerator->getFirst() could not be implemented for database cursor. This method returns getNext.';
    return $self->getNext;
}

sub getNext {
    my $self = shift;
    my $rval;
    my @row = $self->{cursor}->fetchrow_array;
    if (@row) {
	my $subject = new RDF::Core::Resource($row[0],$row[1]);
	my $predicate = new RDF::Core::Resource($row[2],$row[3]);
	my $object;
	if ($row[4]) {
	    $object = new RDF::Core::Resource($row[4],$row[5]);
	} else {
	    $object = new RDF::Core::Literal($row[6], $row[7], $row[8]);
	};
	$rval = new RDF::Core::Statement($subject, $predicate, $object);
    }
    return $rval;
}

sub close {
    my $self = shift;
    $self->{cursor}->finish() if $self->{cursor};
}

sub DESTROY {
    my $self = shift;
    $self->close();
}

1;
__END__

=head1 NAME

RDF::Core::Enumerator::Postgres 

=head1 SYNOPSIS

 To be done

=head1 DESCRIPTION

To be done

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Storage, RDF::Core::Model

=cut
