# Test strict mode, including also re-naming sql_interp at the same time.

use strict;
use warnings;
use Test::More 'no_plan';
use SQL::Interp
    'sql_interp'        => { -as => 'sql_interp_insecure' },
    'sql_interp_strict' => { -as => 'sql_interp' };

eval { sql_interp('WHERE x=', 5) };
like($@,qr/failed sql_interp_strict/,"basic strict mode test");

eval {
    my ($sql) = sql_interp_insecure('WHERE x=', 5);
    is( $sql,
        'WHERE x= 5',
        'sql_interp can be renamed at the same time as sql_interp_strict is being renamed to sql_interp'
    );
};
unlike($@,qr/failed sql_interp_strict/,"basic strict mode test");


