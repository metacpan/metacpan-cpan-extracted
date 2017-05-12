use strict;
use Test::More tests => 4;

BEGIN {
    use_ok( 'Pod::Extract::URI' );
}

my $peu = Pod::Extract::URI->new(
    want_command   => 1,
    want_verbatim  => 0,
    want_textblock => 0,
);
my @uris = $peu->uris_from_file( 't/pod/blocks.pod' );
is_deeply( \@uris, [ 
    'ftp://www.example.com/command', 
    'ftp://www.example.com/command/intseq', 
    'http://www.example.com/command', 
    'http://www.example.com/command/intseq'
] );

$peu = Pod::Extract::URI->new(
    want_command   => 1,
    want_verbatim  => 0,
    want_textblock => 0,
    schemeless     => 1,
);
@uris = $peu->uris_from_file( 't/pod/blocks.pod' );
is_deeply( \@uris, [ 
    'ftp://www.example.com/command', 
    'ftp://www.example.com/command/intseq', 
    'http://www.example.com/command', 
    'http://www.example.com/command/intseq',
    'www.example.com/command', 
    'www.example.com/command/intseq'
] );

$peu = Pod::Extract::URI->new(
    want_command   => 1,
    want_verbatim  => 0,
    want_textblock => 0,
    L_only         => 1,
);
@uris = $peu->uris_from_file( 't/pod/blocks.pod' );
is_deeply( \@uris, [ 
    'ftp://www.example.com/command/intseq', 
    'http://www.example.com/command/intseq'
] );

