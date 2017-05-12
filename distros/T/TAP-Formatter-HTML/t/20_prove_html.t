use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';
use FileTempTFH;

use App::Prove;

my $tmp = FileTempTFH->new;

# prove -P HTML=output:output.html,css_uri:http://www.spurkis.org/style.css,js_uri:jquery.js,js_uri:custom.js,force_inline_css:0,force_inline_js:0

my @args = (
	    '--norc', '-Q', '-P',
	    join( ',',
		  'HTML=outfile:' . $tmp->filename,
		  qw( css_uri:http://www.spurkis.org/style.css
		      css_uri:custom.css
		      js_uri:http://www.spurkis.org/jquery.js
		      js_uri:custom.js
	  	      force_inline_css:0
	  	      force_inline_js:0 ),
		),
	    't/data/01_pass.pl',
	   );

my $run;
my $app = App::Prove->new;

eval {
    $app->process_args( @args );
    $run = $app->run;
};
my $e = $@ || '';

ok( $run, 'app->run' );
is( $e, '', '... and no error' );

can_ok( 'App::Prove::Plugin::HTML', 'load' );
can_ok( 'TAP::Formatter::HTML', 'new' );
is( $app->formatter, 'TAP::Formatter::HTML', 'app->formatter' );

is( $ENV{TAP_FORMATTER_HTML_OUTFILE}, $tmp->filename, 'ENV: outfile' );
is( $ENV{TAP_FORMATTER_HTML_CSS_URIS}, 'http://www.spurkis.org/style.css:custom.css', 'ENV: css_uris' );
is( $ENV{TAP_FORMATTER_HTML_JS_URIS}, 'http://www.spurkis.org/jquery.js:custom.js', 'ENV: js_uris' );
is( $ENV{TAP_FORMATTER_HTML_FORCE_INLINE_CSS}, 0, 'ENV: force_inline_css' );
is( $ENV{TAP_FORMATTER_HTML_FORCE_INLINE_JS}, 0, 'ENV: force_inline_js' );


my $out = $tmp->get_all_output || '';
like( $out, qr|\A\s*<.+/html>\s*\Z|ms, 'HTML report output to file' );
like( $out, qr|style.css|,  'css_uri: style.css' );
like( $out, qr|custom.css|, 'css_uri: custom.css' );
like( $out, qr|jquery.js|,  'js_uri: jquery.css' );
like( $out, qr|custom.js|,  'js_uri: custom.css' );

