#!/usr/local/bin/perl

use File::Basename;

chdir dirname ( $0 );

use lib qw(lib ../lib);

use Test::More tests => 4;

BEGIN
{
  use_ok ( 'IO::Scalar' );
  use_ok ( 'Test::File::Contents' );
  use_ok ( "Pod::XML" );
}

my $parser = new Pod::XML ();
my $xml = '';

# because Pod::XML automatically outputs to STDOUT
tie *STDOUT, 'IO::Scalar', \$xml;

$parser->parse_from_file ( "links.pod" );

untie *STDOUT;

file_contents_is ( 'links.pod.xml', $xml, 'XML generated correctly' );
