package # hide from PAUSE
    TestSchema;

use strict;
use warnings;

use base qw/ DBIx::Class::Schema /;


__PACKAGE__->load_classes(qw/ Template /);



1;
