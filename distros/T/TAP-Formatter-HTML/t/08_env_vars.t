use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';
use FileTempTFH;

use TAP::Harness;
use_ok( 'TAP::Formatter::HTML' );

my $tmp = FileTempTFH->new;
$ENV{TAP_FORMATTER_HTML_OUTFILE}          = "$tmp";
$ENV{TAP_FORMATTER_HTML_FORCE_INLINE_CSS} = "0";
$ENV{TAP_FORMATTER_HTML_CSS_URIS}         = "/foo/bar.css:/bar/baz.css";
$ENV{TAP_FORMATTER_HTML_JS_URIS}          = "/foo/bar.js:/bar/baz.js";
$ENV{TAP_FORMATTER_HTML_TEMPLATE}         = "/foo/bar/baz.tt";

my $f = TAP::Formatter::HTML->new({ really_quiet => 1 });

isnt( $f->output_fh, $f->stdout, 'TAP_FORMATTER_HTML_OUTFILE sets output_fh' );
is( $f->force_inline_css, 0, 'TAP_FORMATTER_HTML_FORCE_INLINE_CSS' );
is( $f->template, '/foo/bar/baz.tt', 'TAP_FORMATTER_HTML_TEMPLATE' );
is_deeply( $f->css_uris,
	   [qw( /foo/bar.css /bar/baz.css )],
	   'TAP_FORMATTER_HTML_CSS_URIS' );
is_deeply( $f->js_uris,
	   [qw( /foo/bar.js /bar/baz.js )],
	   'TAP_FORMATTER_HTML_JS_URIS' );


# Test #2 - make sure OUTFILE works...
delete @ENV{qw(TAP_FORMATTER_HTML_CSS_URIS
	       TAP_FORMATTER_HTML_JS_URIS
	       TAP_FORMATTER_HTML_TEMPLATE)};

my $h = TAP::Harness->new({ merge => 1, verbosity => -3, formatter_class => 'TAP::Formatter::HTML' });

$h->runtests( 't/data/01_pass.pl' );
my $html = $tmp->get_all_output;

ok( $html, 'TAP_FORMATTER_HTML_OUTFILE generates file' );
like( $html, qr|01_pass|, 'file contains expected output' );
