package RoleUtils;
use Carp;
use Role::Tiny;

=head1 DESCRIPTION

This module provides a subroutine for Role::Tiny introspection

=cut

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/get_required_methods/;

sub get_required_methods {
    my ($role) = @_;
    my $info = $Role::Tiny::INFO{ $role } or Carp::croak "$role is not a role";
    my $required  = $info->{ requires }  // [];
    my $modifiers = $info->{ modifiers } // [];
    return (@$required, map { $_->[1] } @$modifiers);
}

1;
