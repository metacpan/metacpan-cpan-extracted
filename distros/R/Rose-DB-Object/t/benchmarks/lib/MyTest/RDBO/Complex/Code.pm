package MyTest::RDBO::Complex::Code;

use strict;

use Rose::DB::Object;
our @ISA = qw(Rose::DB::Object);

__PACKAGE__->meta->table('rose_db_object_test_codes');

__PACKAGE__->meta->auto_initialize;

1;