#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 11;
BEGIN { use_ok 'PHP::Strings', ':chunk_split' };

# Good inputs
{
    is( chunk_split('foo') => "foo\r\n", "Short string" );
    my $long = <<'EOF';
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
EOF
    $long =~ s/\n/\r\n/g;
    my $joined = 'a' x (3*76-3);
    is( chunk_split( $joined ) => $long, "Longish string" );

    $long =~ s/\r\n/\n/g;
    is( chunk_split( $joined, 76, "\n" ) => $long, "Longish string" );

    my $t = $joined;
    (my $s = $t) =~ s/(.{76})/$1\n/sg;
    $s .= "\n";
    is( $s => $long, "Regex from docs" );
    is( $t => $joined, "\$t unaffected" );

}

# Bad inputs
{
    eval { chunk_split( ) };
    like( $@, qr/^0 param/, "No arguments" );
    eval { chunk_split( undef ) };
    like( $@, qr/^Parameter #1.*undef.*scalar/, "Bad type for string" );
    eval { chunk_split( "Foo", undef ) };
    like( $@, qr/^Parameter #2.*undef.*scalar/, "Bad type for chunklen" );
    eval { chunk_split( "Foo", "Not a number" ) };
    like( $@, qr/^Parameter #2.*regex/, "Chunklen not a number" );
    eval { chunk_split( "Foo", 4, undef ) };
    like( $@, qr/^Parameter #3.*undef.*scalar/, "Bad type for end" );
}
