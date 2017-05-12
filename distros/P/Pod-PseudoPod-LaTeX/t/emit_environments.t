#! perl

use strict;
use warnings;

use IO::String;
use File::Spec::Functions;

use Test::More tests => 4;

use_ok( 'Pod::PseudoPod::LaTeX' ) or exit;

my $fh     = IO::String->new();
my $parser = Pod::PseudoPod::LaTeX->new();
$parser->output_fh( $fh );
$parser->parse_file( catfile( qw( t test_file.pod ) ) );

$fh->setpos(0);
my $text  = join( '', <$fh> );

like( $text, qr/\\vspace\{3pt}\s*Hello, this is a sidebar/,
    'Emit formatting code when emit_environment option not set' );

unlike( $text, qr/\\(?:begin|end)\{A?sidebar}/,
    'No sidebar environemnt whatsoever when emit_environment option not set' );

$fh     = IO::String->new();
$parser = Pod::PseudoPod::LaTeX->new();
$parser->emit_environments( sidebar => 'Asidebar' );
$parser->output_fh( $fh );
$parser->parse_file( catfile( qw( t test_file.pod ) ) );

$fh->setpos(0);
$text  = join( '', <$fh> );

like( $text, qr/\\begin\{Asidebar}\s*Hello, this is a sidebar\s*\\end\{Asidebar}/,
    'Emit abstract \begin{foo} when emit_environment option is set' );
