package NoDefaults;

use strict;
use warnings;

use Parse::PlainConfig;
use Parse::PlainConfig::Constants;
use base qw(Parse::PlainConfig);
use vars qw(%_globals %_parameters %_prototypes);

%_globals = (
    comment          => ';',
    'delimiter'      => ' ',
    'list delimiter' => ':',
    'hash delimiter' => '@',
    'subindentation' => 4,
    );

%_parameters = (
    'admin email' => PPC_SCALAR,
    'db'          => PPC_HASH,
    'hosts'       => PPC_ARRAY,
    'note'        => PPC_HDOC,
    'nodefault'   => PPC_SCALAR,
    );

%_prototypes = (
    'declare acl' => PPC_ARRAY,
    'declare foo' => PPC_SCALAR
    );

1;

