package Parse::RecDescent::Topiary::Base;
use strict;
use warnings;

our $VERSION = 0.03;

=head1 NAME

Parse::RecDescent::Topiary::Base - Base class for autotree constructors

=head1 SYNOPSIS

  package MyTree::Rule1;
  use base 'Parse::RecDescent::Topiary::Base';

=head1 DESCRIPTION

This module provides a method C<new> to build hashref objects for autotree
classes. See L<Parse::RecDescent::Topiary> for details.

=head2 new

Basic hashref style object constructor. Takes a list of value pairs.

=head1 BUGS

Please report bugs to http://rt.cpan.org

=head1 AUTHOR

    Ivor Williams
    CPAN ID: IVORW
     
    ivorw@cpan.org
     

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Parse::RecDescent>, L<Parse::RecDescent::Topiary>.

=cut

sub new {
    my ( $pkg, %proto ) = @_;

    delete $proto{__RULE__};    #This information is already in the class name
    bless \%proto, $pkg;
}

1;

# The preceding line will help the module return a true value

