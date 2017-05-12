use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';
use Carp::Always 0.09;

use Muldis::Rosetta::Validator;

Muldis::Rosetta::Validator::main({
    'engine_name' => 'Muldis::Rosetta::Engine::Example',
    'process_config' => {},
});

1; # Magic true value required at end of a reusable file's code.
