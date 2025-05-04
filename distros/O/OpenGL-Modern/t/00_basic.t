use strict;
use warnings;
use Test::More;
use OpenGL::Modern;

for my $function ( qw(glClear ) ) {
    my $exported = 0;
    eval { OpenGL::Modern->import( $function ); $exported = 1 };
    ok( $exported, "Function $function gets exported upon request" );
}

done_testing;
