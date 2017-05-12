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

package RDF::Core;

use strict;

require Exporter;

our $VERSION = '0.51';

1;
__END__

=head1 NAME

RDF::Core - An object oriented Perl modules for handling tasks related to RDF.


=head1 DESCRIPTION

RDF::Core has these parts:

=over 4

=item * B<RDF::Core::Model>

Model provides interface to store RDF statements, ask about them and retrieve them back.

=item * B<RDF::Core::Constants>

Defines usefule constants for the RDF processing like namespaces etc.

=item * B<RDF::Core::Parser>

Generates statements from an RDF XML document.

=item * B<RDF::Core::Model::Parser>

Model::Parser is a simple interface object to a parser. It's purpose is to provide a prototype of object accomodating any other parser.

=item * B<RDF::Core::Serializer>

Serializes RDF Model into XML.

=item * B<RDF::Core::Model::Serializer>

Model::Serializer is an interface object for Serializer.

=item * B<RDF::Core::Storage>

An object for storing statements. There are several implementations of Storage - in memory, in a BerkeleyDB 1.x (DB_File) files and PostgreSQL database.

=item * B<RDF::Core::Enumerator>

Enumerator is a result set of statements retrieved from Model

=item * B<RDF::Core::Query>

An implementation of query language.

=item * B<RDF::Core::Schema>

The RDF Schema utilities.

=item * B<Basic elements>

RDF::Core::Statement, RDF::Core::Resource, RDF::Core::Literal, RDF::Core::Node

=back

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

perl(1).

=cut
