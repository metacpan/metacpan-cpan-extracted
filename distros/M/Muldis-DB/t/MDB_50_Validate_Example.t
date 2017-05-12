use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';

use Muldis::DB::Validator;

Muldis::DB::Validator::main({
    'engine_name' => 'Muldis::DB::Engine::Example',
    'dbms_config' => {},
});

1; # Magic true value required at end of a reusable file's code.
