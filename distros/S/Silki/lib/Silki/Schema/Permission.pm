package Silki::Schema::Permission;
{
  $Silki::Schema::Permission::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Schema;

use Fey::ORM::Table;
use MooseX::ClassAttribute;

has_policy 'Silki::Schema::Policy';

has_table( Silki::Schema->Schema()->table('Permission') );

for my $role (qw( Read Edit Delete Upload Invite Manage )) {
    class_has $role => (
        is      => 'ro',
        isa     => 'Silki::Schema::Permission',
        lazy    => 1,
        default => sub { __PACKAGE__->_CreateOrFindPermission($role) },
    );
}

sub _CreateOrFindPermission {
    my $class = shift;
    my $name  = shift;

    my $role = eval { $class->new( name => $name ) };

    $role ||= $class->insert( name => $name );

    return $role;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a permission

__END__
=pod

=head1 NAME

Silki::Schema::Permission - Represents a permission

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

