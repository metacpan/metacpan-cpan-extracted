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
my $result = parse_with_anchors( $file, emit_environments => { foo => 'foo' } );

unlike_string $result, qr!\\LaTeX!,
    'A =for latex section should have disappeared';

like_string $result, qr!<p>HTML here</p>!,
    'A =for html section should be included literally';

like_string $result, qr!<div class="foo">\s*<p class="title">Title</p>!,
    'title passed is available';

like_string $result,
    qr!<div class="programlisting">\s*<pre><code>\s*\&quot;This text!,
    '=begin programlisting should use programlisting environment';

like_string $result, qr!\(backslashes\)\s*</code></pre>\s*</div>!,
    '... with end tag';

like_string $result,
    qr!<div class="tip">\s*<p class="title">Design P.+</p>\s*<p>This is a des!,
    'begin should add tag and optional title';

like_string $result, qr!>Design Principle of <code>Code</code> <em>fun</em></p!,
    '... with tags handled in title';
like_string $result, qr!parts.</p>\s*</div>!,
    '... and block ending';

done_testing;
