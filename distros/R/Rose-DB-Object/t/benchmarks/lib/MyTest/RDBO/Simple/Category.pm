package MyTest::RDBO::Simple::Category;

use strict;

use Rose::DB::Object;
our @ISA = qw(Rose::DB::Object);

use Rose::DB::Object::Helpers
{
  insert_or_update => 'insert_or_update_std',
  insert_or_update_on_duplicate_key => 'insert_or_update',
};

__PACKAGE__->meta->table('rose_db_object_test_categories');
__PACKAGE__->meta->columns(qw(id name));
__PACKAGE__->meta->primary_key_columns([ 'id' ]);
__PACKAGE__->meta->initialize;

1;
