package Myco::Entity::Meta::Query;

###############################################################################
# $Id: Query.pm,v 1.4 2006/02/24 15:03:14 sommerb Exp $
###############################################################################

=head1 NAME

Myco::Entity::Meta::Query - a Myco entity class

=over 4

=item Repository

$Revision: 1.4 $ $Date: 2006/02/24 15:03:14 $

=back

=head1 DESCRIPTION

A class to prepare and store Tangram Query objects used to generate lists.
Acts as a shell in the L<Myco::Entity::Meta|Myco::Entity::Meta> space to
inherit from L<Myco::QueryTemplate|Myco::QueryTemplate>.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;

##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw( Myco::QueryTemplate );
my $md = Myco::Entity::Meta->new( name => __PACKAGE__ );

##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class;

1;
__END__
