use utf8;
package Statistics::Covid::Schema::Result::Version;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Statistics::Covid::Schema::Result::Version

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Version>

=cut

__PACKAGE__->table("Version");

=head1 ACCESSORS

=head2 authoremail

  data_type: 'varchar'
  default_value: 'andreashad2@gmail.com'
  is_nullable: 0
  size: 100

=head2 authorname

  data_type: 'varchar'
  default_value: 'Andreas Hadjiprocopis'
  is_nullable: 0
  size: 100

=head2 package

  data_type: 'varchar'
  default_value: 'Statistics::Covid'
  is_nullable: 0
  size: 100

=head2 version

  data_type: 'varchar'
  default_value: 0.21
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "authoremail",
  {
    data_type => "varchar",
    default_value => "andreashad2\@gmail.com",
    is_nullable => 0,
    size => 100,
  },
  "authorname",
  {
    data_type => "varchar",
    default_value => "Andreas Hadjiprocopis",
    is_nullable => 0,
    size => 100,
  },
  "package",
  {
    data_type => "varchar",
    default_value => "Statistics::Covid",
    is_nullable => 0,
    size => 100,
  },
  "version",
  {
    data_type => "varchar",
    default_value => 0.21,
    is_nullable => 0,
    size => 100,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</version>

=back

=cut

__PACKAGE__->set_primary_key("version");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-03-28 14:05:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:09659sCnWdk9tC1s4m/xSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
