package Myco::Entity::Meta::UI::List;

###############################################################################
# $Id: List.pm,v 1.6 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::Meta::UI::List - a Myco entity class

=head1 SYNOPSIS

  use Myco::Entity::Meta::UI::List;

=head1 DESCRIPTION

Used by the myco entity framework. Don't hack it unless you know what you're
doing :_)

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;


##############################################################################
# Inheritance
##############################################################################
use base qw(Class::Tangram);


### Object Schema Definition
our $schema =
  {
   fields =>
    {
      transient =>
      { inline_sep => {},
	layout => {},
	type => {},
      },
    }
  };
Class::Tangram::import_schema(__PACKAGE__);

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity::Meta::UI::List::Test|Myco::Entity::Meta::UI::List::Test>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
