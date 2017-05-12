#! perl

use strict;
use warnings;

use IO::String;
use File::Spec::Functions;

use Test::More tests => 5;

use_ok( 'Pod::PseudoPod::LaTeX' ) or exit;

my $fh     = IO::String->new();
my $parser = Pod::PseudoPod::LaTeX->new();
$parser->accept_target("foo");
$parser->emit_environments( 'foo' => 'foo' );
$parser->output_fh( $fh );
$parser->parse_file( catfile( qw( t test_file.pod ) ) );


$fh->setpos(0);
my $text = join( '', <$fh> );

like( $text, qr/\\LaTeX/,
    '\LaTeX in a =for latex section remains intact' );

like( $text, qr/\\begin\{foo}\{Title}/, "title is passed is available" );

like $text, qr/\\begin\{figure}/, "figure gets rendered";

## would like to support B<> and some other in the caption, but other time
like $text, qr/\\caption\{Figure Title}/, "figure caption is rendered";
