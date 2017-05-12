package Myco::Query;

###############################################################################
# $Id: Query.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $
###############################################################################

=head1 NAME

Myco::Query - a Myco entity class

=head1 VERSION

=over 4

=item Release

0.01

=cut

our $VERSION = 0.01;

=item Repository

$Revision$ $Date$

=back

=head1 SYNOPSIS

  use Myco::Query;

  # Constructors. See Myco::Base::Entity for more.
  my $obj = Myco::Query->new;

  # Accessors.
  my $value = $obj->get_fooattrib;
  $obj->set_fooattrib($value);

  $obj->save;
  $obj->destroy;

=head1 DESCRIPTION

A class to prepare and store Tangram Query objects used to generate lists.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;
use CGI;


##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw( Myco::Base::Entity
             Myco::QueryTemplate );
my $md = Myco::Base::Entity::Meta->new
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
