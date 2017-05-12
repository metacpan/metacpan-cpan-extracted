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

package RDF::Core::Constants;

use strict;

use vars qw(%EXPORT_TAGS @ISA @EXPORT_OK);
use Exporter;

@ISA = qw (Exporter);

########################################
# export stuff
my @XML_EXP = qw (XML_NS XMLA_LANG XMLA_BASE);

my @RDF_EXP = qw (RDF_NS RDF_RDF RDF_DESCRIPTION RDF_BAG RDF_ALT RDF_SEQ
		  RDF_LI RDF_TYPE RDF_OBJECT RDF_SUBJECT RDF_PREDICATE
		  RDF_STATEMENT RDF_PROPERTY RDF_LIST RDF_FIRST RDF_REST 
                  RDF_NIL RDFA_ABOUT RDFA_ABOUTEACH RDFA_ID RDFA_NODEID 
                  RDFA_BAGID RDFA_RESOURCE RDFA_PARSETYPE RDFA_TYPE 
                  RDFA_DATATYPE RDF_XMLLITERAL);


my @RDFS_EXP = qw(RDFS_NS RDFS_RESOURCE RDFS_CLASS RDFS_LITERAL RDFS_CONTAINER
		  RDFS_CONTAINER_MEMBER RDFS_IS_DEFINED_BY RDFS_MEMBER
		  RDFS_SUBCLASS_OF RDFS_SUBPROPERTY_OF RDFS_COMMENT RDFS_LABEL
		  RDFS_DOMAIN RDFS_RANGE RDFS_SEE_ALSO);

%EXPORT_TAGS = (xml => \@XML_EXP, 
		rdf => \@RDF_EXP, 
		rdfs => \@RDFS_EXP);

@EXPORT_OK = (@XML_EXP, @RDF_EXP, @RDFS_EXP);

########################################
# XML
use constant XML_NS  => 'http://www.w3.org/XML/1998/namespace';
use constant XMLA_LANG => XML_NS . 'lang';
use constant XMLA_BASE => XML_NS . 'base';

########################################
# RDF
use constant RDF_NS => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
use constant RDF_RDF         => RDF_NS . 'RDF';
use constant RDF_DESCRIPTION => RDF_NS . 'Description';
use constant RDF_BAG         => RDF_NS . 'Bag';
use constant RDF_ALT         => RDF_NS . 'Alt';
use constant RDF_SEQ         => RDF_NS . 'Seq';
use constant RDF_LI          => RDF_NS . 'li';
use constant RDF_TYPE        => RDF_NS . 'type';
use constant RDF_OBJECT      => RDF_NS . 'object';
use constant RDF_SUBJECT     => RDF_NS . 'subject';
use constant RDF_PREDICATE   => RDF_NS . 'predicate';
use constant RDF_STATEMENT   => RDF_NS . 'Statement';
use constant RDF_PROPERTY    => RDF_NS . 'Property';
use constant RDF_LIST        => RDF_NS . 'List';
use constant RDF_FIRST       => RDF_NS . 'first';
use constant RDF_REST        => RDF_NS . 'rest';
use constant RDF_NIL         => RDF_NS . 'nil';
use constant RDF_VALUE       => RDF_NS . 'value';
use constant RDF_XMLLITERAL  => RDF_NS . 'XMLLiteral';

########################################
# RDF attributes
use constant RDFA_ABOUT      => RDF_NS . 'about';
use constant RDFA_ABOUTEACH  => RDF_NS . 'aboutEach';
use constant RDFA_ID         => RDF_NS . 'ID';
use constant RDFA_NODEID     => RDF_NS . 'nodeID';
use constant RDFA_BAGID      => RDF_NS . 'bagID';
use constant RDFA_RESOURCE   => RDF_NS . 'resource';
use constant RDFA_PARSETYPE  => RDF_NS . 'parseType';
use constant RDFA_TYPE       => RDF_NS . 'type';
use constant RDFA_DATATYPE   => RDF_NS . 'datatype';

########################################
# RDFS
use constant RDFS_NS               => 'http://www.w3.org/2000/01/rdf-schema#';
use constant RDFS_RESOURCE         => RDFS_NS . 'Resource';
use constant RDFS_CLASS            => RDFS_NS . 'Class';
use constant RDFS_LITERAL          => RDFS_NS . 'Literal';
use constant RDFS_CONTAINER        => RDFS_NS . 'Container';
use constant RDFS_CONTAINER_MEMBER => RDFS_NS . 'ContainerMembershipProperty';

use constant RDFS_IS_DEFINED_BY    => RDFS_NS . 'isDefinedBy';
use constant RDFS_MEMBER           => RDFS_NS . 'member';
use constant RDFS_SUBCLASS_OF      => RDFS_NS . 'subClassOf';
use constant RDFS_SUBPROPERTY_OF   => RDFS_NS . 'subPropertyOf';
use constant RDFS_COMMENT          => RDFS_NS . 'comment';
use constant RDFS_LABEL            => RDFS_NS . 'label';
use constant RDFS_DOMAIN           => RDFS_NS . 'domain';
use constant RDFS_RANGE            => RDFS_NS . 'range';
use constant RDFS_SEE_ALSO         => RDFS_NS . 'seeAlso';

1;

__END__

=head1 NAME

RDF::Core::Constants - RDF constant definitions

=head1 SYNOPSIS

  use RDF::Core::Constants qw(:xml :rdf :rdfs);

=head1 DESCRIPTION

Three constant groups may be imported as well as particular symbols for any set listed bellow.

=over

=item * Generic XML constants

The import tag of B<:xml> imports: XML_NS XMLA_LANG XMLA_BASE

=item * RDF constants

The import tag of B<:rdf> imports: RDF_NS RDF_RDF RDF_DESCRIPTION RDF_BAG 
RDF_ALT RDF_SEQ RDF_LI RDF_TYPE RDF_OBJECT RDF_SUBJECT RDF_PREDICATE
RDF_STATEMENT RDF_PROPERTY RDFA_ABOUT RDFA_ABOUTEACH 
RDFA_ID RDFA_BAGID RDFA_RESOURCE RDFA_PARSETYPE RDFA_TYPE

=item * RDFS constants (RDF Schema)

The import tag of B<:rdfs> imports: RDFS_NS RDFS_RESOURCE RDFS_CLASS 
RDFS_LITERAL RDFS_CONTAINER RDFS_CONTAINER_MEMBER RDFS_IS_DEFINED_BY 
RDFS_MEMBER RDFS_SUBCLASS_OF RDFS_SUBPROPERTY_OF RDFS_COMMENT RDFS_LABEL
RDFS_DOMAIN RDFS_RANGE RDFS_SEE_ALSO

=back

=cut

