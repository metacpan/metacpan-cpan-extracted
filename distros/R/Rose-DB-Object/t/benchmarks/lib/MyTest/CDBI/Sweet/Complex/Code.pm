package MyTest::CDBI::Sweet::Complex::Code;

use strict;

use base 'MyTest::CDBI::Sweet::Base';

__PACKAGE__->table('rose_db_object_test_codes');
__PACKAGE__->columns(Primary => 'k1', 'k2', 'k3');
__PACKAGE__->columns(Essential => qw(code k1 k2 k3));

1;