use strict;
use Test::More tests => 4;

BEGIN {
    use_ok( 'Pod::Extract::URI' );
}

my $peu = Pod::Extract::URI->new(
    want_command   => 0,
    want_verbatim  => 0,
    want_textblock => 1,
);
my @uris = $peu->uris_from_file( 't/pod/blocks.pod' );
is_deeply( \@uris, [ 
    'ftp://www.example.com/textblock', 
    'ftp://www.example.com/textblock/intseq', 
    'http://www.example.com/textblock', 
    'http://www.example.com/textblock/intseq'
] );

$peu = Pod::Extract::URI->new(
    want_command   => 0,
    want_verbatim  => 0,
    want_textblock => 1,
    schemeless     => 1,
);
@uris = $peu->uris_from_file( 't/pod/blocks.pod' );
is_deeply( \@uris, [ 
    'ftp://www.example.com/textblock', 
    'ftp://www.example.com/textblock/intseq', 
    'http://www.example.com/textblock', 
    'http://www.example.com/textblock/intseq',
    'www.example.com/textblock', 
    'www.example.com/textblock/intseq'
] );

$peu = Pod::Extract::URI->new(
    want_command   => 0,
    want_verbatim  => 0,
    want_textblock => 1,
    L_only         => 1,
);
@uris = $peu->uris_from_file( 't/pod/blocks.pod' );
is_deeply( \@uris, [ 
    'ftp://www.example.com/textblock/intseq', 
    'http://www.example.com/textblock/intseq'
] );

