package My::DB::Opa::Object;

use strict;

use base 'Rose::DB::Object';

use My::DB::Opa;

sub init_db { My::DB::Opa->new_or_cached }

1;
