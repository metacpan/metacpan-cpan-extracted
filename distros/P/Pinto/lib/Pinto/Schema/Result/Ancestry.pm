use utf8;

package Pinto::Schema::Result::Ancestry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';


__PACKAGE__->table("ancestry");


__PACKAGE__->add_columns(
    "id",     { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "parent", { data_type => "integer", is_foreign_key    => 1, is_nullable => 0 },
    "child",  { data_type => "integer", is_foreign_key    => 1, is_nullable => 0 },
);


__PACKAGE__->set_primary_key("id");


__PACKAGE__->belongs_to(
    "child",
    "Pinto::Schema::Result::Revision",
    { id            => "child" },
    { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


__PACKAGE__->belongs_to(
    "parent",
    "Pinto::Schema::Result::Revision",
    { id            => "parent" },
    { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


with 'Pinto::Role::Schema::Result';

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-27 14:20:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NAFcD1cZ00q/UhZ15CEYUg

#-------------------------------------------------------------------------------

# ABSTRACT: Represents the relationship between revisions

#-----------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Schema::Result::Ancestry - Represents the relationship between revisions

=head1 VERSION

version 0.097

=head1 NAME

Pinto::Schema::Result::Ancestry

=head1 TABLE: C<ancestry>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 parent

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 child

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=head1 RELATIONS

=head2 child

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=head2 parent

Type: belongs_to

Related object: L<Pinto::Schema::Result::Revision>

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
