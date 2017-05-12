use Test::More tests => 4;
use strict;
use warnings;

my $file = 't/pod/blocks.pod';
open FILE, $file or die "Can't read $file";
my $filehandle = \*FILE;

use Pod::Extract::URI;

# Get a list of URIs from a file
my @uris = Pod::Extract::URI->uris_from_file( $file );
is( scalar @uris, 10 );

# Or filehandle
@uris = Pod::Extract::URI->uris_from_filehandle( $filehandle );
is( scalar @uris, 10 );

# Or the full OO
my $parser = Pod::Extract::URI->new();
$parser->parse_from_file( $file );
@uris = $parser->uris();
is( scalar @uris, 10 );
my %uri_details = $parser->uri_details();
is( scalar keys %uri_details, 10 );
