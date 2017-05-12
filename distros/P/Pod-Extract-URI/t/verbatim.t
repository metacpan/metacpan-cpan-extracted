use strict;
use Test::More tests => 3;

BEGIN {
    use_ok( 'Pod::Extract::URI' );
}

my $peu = Pod::Extract::URI->new(
    want_command   => 0,
    want_verbatim  => 1,
    want_textblock => 0,
);
my @uris = $peu->uris_from_file( 't/pod/blocks.pod' );
is_deeply( \@uris, [ 
    'ftp://www.example.com/verbatim', 
    'http://www.example.com/verbatim', 
] );

$peu = Pod::Extract::URI->new(
    want_command   => 0,
    want_verbatim  => 1,
    want_textblock => 0,
    schemeless     => 1,
);
@uris = $peu->uris_from_file( 't/pod/blocks.pod' );
is_deeply( \@uris, [ 
    'ftp://www.example.com/verbatim', 
    'http://www.example.com/verbatim', 
    'www.example.com/verbatim', 
] );
