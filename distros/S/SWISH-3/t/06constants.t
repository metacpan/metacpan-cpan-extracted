use Test::More tests => 3;

use SWISH::3 qw( :constants );

is( SWISH_MIME,                 'MIME',          SWISH_MIME );
is( SWISH_PROP,                 'PropertyNames', SWISH_PROP );
is( scalar(SWISH_TOKEN_FIELDS), 5,               'SWISH_TOKEN_FIELDS' );
