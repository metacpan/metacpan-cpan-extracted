# Common Rose::DB::Object-derived base class
package My::Object;
use strict;
use My::DB;
use base 'Rose::DB::Object';
sub init_db { My::DB->new }
1;
