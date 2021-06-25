use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';

use File::Slurp;
use File::Spec::Functions;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse_with_anchors( $file );

unlike_string $result, qr/<div class="foo">/,
    'No sidebar environment whatsoever when emit_environment option not set';

$result = parse_with_anchors( $file, emit_environments => { foo => 'foo' } );
like_string $result, qr/<div class="foo">/,
    'Sidebar environment should be present with emit_environment option set';

$result = parse_with_anchors( $file,
    emit_environments => { sidebar => 'Asidebar' }
);

like_string $result,
    qr!<div class="Asidebar">\s*<p>Hello, this is a sidebar</p>\s*</div>!,
    'Emit abstract div with "foo" class when emit_environment option is set';

done_testing;
