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
my $result = parse( $file );

unlike_string $result, qr/\\(?:begin|end)\{A?sidebar}/,
    'No sidebar environment whatsoever when emit_environment option not set';

$result = parse( $file, emit_environments => { sidebar => 'Asidebar' } );

like_string $result,
    qr/\\begin\{Asidebar}\{\s*Hello, this is a sidebar\s*}\\end\{Asidebar}/,
    'Emit abstract \begin\{foo} when emit_environment option is set';

done_testing;
