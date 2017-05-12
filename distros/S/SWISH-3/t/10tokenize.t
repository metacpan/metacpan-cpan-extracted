use Test::More tests => 6;

use SWISH::3 qw( :constants );

ok( my $s3 = SWISH::3->new, "new s3" );
ok( my $tokens = $s3->tokenize(
        "now is the time, ain't it? or when else might it be!",
        SWISH::3::MetaName->new('foo'), 'bar'
    ),
    "wordlist"
);

ok( $tokens->isa('SWISH::3::TokenIterator'), 'isa TokenIterator' );

#$s3->describe($tokens);

while ( my $token = $tokens->next ) {

    #$s3->describe($token);

    my $word = $token->value;
    if ( $word eq 'now' ) {
        is( $token->pos, 1, "now position" );
    }
    if ( $word eq 'time' ) {
        is( $token->pos, 4, "time position" );
    }
    if ( $word eq 'be' ) {
        is( $token->pos, 12, "be position" );
    }

    $s3->debug and diag( '=' x 60 );
    for my $w (SWISH_TOKEN_FIELDS) {

        my $val = $token->$w;
        if ( $w eq 'meta' ) {
            $val = $val->name;
        }

        $s3->debug and diag( sprintf( "%15s: %s\n", $w, $val ) );

    }
}

