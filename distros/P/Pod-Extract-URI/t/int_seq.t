use strict;
use warnings;
use Test::More tests => 2;
use Pod::Extract::URI;

my @uris = Pod::Extract::URI->uris_from_file( 't/pod/int_seq.pod' );
is_deeply( \@uris, [ 
    'http://www.example.com',
    'http://www.example.com?foo=bar&blat=baz'
] );

my $peu = Pod::Extract::URI->new( L_only => 1 );
@uris = $peu->uris_from_file( 't/pod/int_seq.pod' );
is_deeply( \@uris, [
    'http://www.example.com?foo=bar&blat=baz'
] );
