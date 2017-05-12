package Repository::Simple::Permission;

use strict;
use warnings;

our $VERSION = '0.06';

use Repository::Simple::Util;

our @CARP_NOT = qw( Repository::Simple::Util );

=head1 NAME

Repository::Simple::Permission - Defines the permission constants

=head1 SYNOPSIS

  # Automatically imports all permission constants
  use Repository::Simple::Permission;

  $repository->check_permission('/foo/bar', $READ);
  $repository->check_permission('/foo/bar', $ADD_NODE);
  $repository->check_permission('/foo/bar', $SET_PROPERTY);
  $repository->check_permission('/foo/bar', $REMOVE);

  # Just import some of them
  use Repository::Simple::Permission qw( $READ $SET_PROPERTY );

  $repository->check_permission('/foo/bar', $READ);
  $repository->check_permission('/foo/bar', $SET_PROPERTY);

  # Or use constants by full name
  use Repository::Simple::Permission qw

  $repository->check_permission('/foo/bar', 
      $Repository::Simple::Permission::READ);
  $repository->check_permission('/foo/bar', 
      $Repository::Simple::Permission::ADD_NODE);
  $repository->check_permission('/foo/bar', 
      $Repository::Simple::Permission::$SET_PROPERTY);
  $repository->check_permission('/foo/bar', 
      $Repository::Simple::Permission::REMOVE);

=head1 DESCRIPTION

This class defines the permission constants.

=cut

use Readonly;
require Exporter;

our @ISA = qw( Exporter );

our @EXPORT = qw( $ADD_NODE $SET_PROPERTY $READ $REMOVE );

Readonly our $ADD_NODE     => 'add_node';
Readonly our $SET_PROPERTY => 'set_property';
Readonly our $REMOVE       => 'remove';
Readonly our $READ         => 'read';

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
