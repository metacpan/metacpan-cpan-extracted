package MyTest::DBIC::Schema;

use strict;

use base 'DBIx::Class::Schema';

# Load MyTest::DBIC::Schema::*
__PACKAGE__->load_classes(map { ("Simple::$_", "Complex::$_") } 
                          qw(Category Code CodeName Product));

our $DB; # set in bench.pl

1;
