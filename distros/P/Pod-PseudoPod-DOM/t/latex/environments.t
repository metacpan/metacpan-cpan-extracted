use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::LaTeX';

use File::Slurp;
use File::Spec::Functions;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse( $file, emit_environments => { foo => 'foo' } );

like_string $result, qr!\\LaTeX!,
    '\LaTeX in a =for latex section remains intact';

like_string $result, qr!\\begin\{foo}\[Title\]!, 'title passed is available';

like_string $result, qr!\\begin\{CodeListing}!,
    '=begin programlisting should use programlisting environment';

like_string $result, qr!\\end\{CodeListing}!, '... with end tag';

like_string $result, qr!\\begin\{tip}\[Design Principle.+]\{\nThis is a design!,
    'begin should add tag and optional title';

like_string $result, qr!\[Design Principle of \\texttt\{Code}.+]!,
    '... with code tag handled in title';
like_string $result, qr!}\\end\{tip}!,
    '... and end block';

like_string $result, qr!^\\pagebreak$!m,
    '=for latex should produce literal command';

done_testing;
