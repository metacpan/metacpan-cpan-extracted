use strict;
use warnings;
use OpenGuides::CGI;
use Test::More tests => 2;

my $output = OpenGuides::CGI->escape( "Test, Node, With, Commas?" );
unlike( $output, qr/\?/, "OpenGuides::CGI->escape escapes things" );
unlike( $output, qr/%2C/, "...but not commas" );
