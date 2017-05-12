package MyTest::RDBO::Simple::Code;

use strict;

use Rose::DB::Object;
our @ISA = qw(Rose::DB::Object);

__PACKAGE__->meta->table('rose_db_object_test_codes');
__PACKAGE__->meta->columns(qw(code k1 k2 k3));
__PACKAGE__->meta->primary_key_columns([ 'k1', 'k2', 'k3' ]);
__PACKAGE__->meta->initialize;

1;