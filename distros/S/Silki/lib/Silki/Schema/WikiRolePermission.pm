package Silki::Schema::WikiRolePermission;
{
  $Silki::Schema::WikiRolePermission::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Schema;

use Fey::ORM::Table;
use MooseX::ClassAttribute;

has_policy 'Silki::Schema::Policy';

has_table( Silki::Schema->Schema()->table('WikiRolePermission') );

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents the permission granted to a role in a specific wiki

__END__
=pod

=head1 NAME

Silki::Schema::WikiRolePermission - Represents the permission granted to a role in a specific wiki

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

