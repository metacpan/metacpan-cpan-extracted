use utf8;
package Rapi::Blog::DB;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-12-11 18:57:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:05j7K183HeaNPpBZ0cSOyw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
