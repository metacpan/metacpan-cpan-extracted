package OpusVL::AppKit::Schema::AppKitAuthDB::Result::ParameterDefault;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");


__PACKAGE__->table("parameter_defaults");


__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "parameter_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "data",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


__PACKAGE__->belongs_to(
  "parameter",
  "OpusVL::AppKit::Schema::AppKitAuthDB::Result::Parameter",
  { id => "parameter_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-24 12:44:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8VWohJjYOgC6d/pR4XcSiQ

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::ParameterDefault

=head1 VERSION

version 6

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::ParameterDefault

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1

=head2 parameter_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 data

  data_type: 'text'
  is_nullable: 1

=head1 RELATIONS

=head2 parameter

Type: belongs_to

Related object: L<OpusVL::AppKit::Schema::AppKitAuthDB::Result::Parameter>

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
