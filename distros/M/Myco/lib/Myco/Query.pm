package Myco::Query;

###############################################################################
# $Id: Query.pm,v 1.4 2006/02/27 22:55:55 sommerb Exp $
###############################################################################

=head1 NAME

Myco::Query - a Myco entity class

=head1 SYNOPSIS

  use Myco::Query;

  # Constructors, accessors, etc - see Myco::QueryTemplate for more.

=head1 DESCRIPTION

A class to prepare and store Tangram Query objects used to generate lists.
See L<Myco::QueryTemplate|Myco::QueryTemplate> for full info.

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
use base qw( Myco::Entity
             Myco::QueryTemplate );
my $md = Myco::Entity::Meta->new
  ( name => __PACKAGE__,
    tangram => { table => 'query', },
    ui => {
           displayname => sub { shift->get_name },
           list => {
                    layout => [ qw(__DISPLAYNAME__) ],
                   },
          },
  );

##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class;

1;
__END__
