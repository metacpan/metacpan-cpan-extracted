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

package RDF::Core::Enumerator;

use strict;
require Exporter;

use Carp;

sub new {
    carp "Pure virtual function call.";
}
1;
__END__

=head1 NAME

RDF::Core::Enumerator - an object that provides access to a set of statements

=head1 SYNOPSIS

  #print content of a model
  my $enumerator = $model->getStmts;
  my $statement = $enumerator->getFirst;
  while (defined $statement) {
    print $statement->getLabel."\n";
    $statement = $enumerator->getNext
  }
  $enumerator->close;


=head1 DESCRIPTION

A set of statements (such as returned by $model-E<gt>getStmts) is represented by some descendant of RDF::Core::Enumerator. Statements can be accessed by calling getNext method repeatedly until it returns undef, which means there are no more statements to get.


=head2 Interface

=over 4

=item * new

Constructors differ for different implementations of Enumerator, see RDF::Core::Enumerator::Memory, RDF::Core::Enumerator::DB_File, RDF::Core::Enumerator::Postgres

=item * getFirst

Returns first statement in Enumerator, resets all preceding getNext calls. Returns undef if there is no statement.

=item * getNext

Returns next statement or undef if there are no more statements.

=item * close

Releases memory, disk, database cursor or whatever it used to provide the data.

=back


=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

 RDF::Core::Enumerator::Memory, RDF::Core::Enumerator::DB_File, RDF::Core::Enumerator::Postgres

=cut
