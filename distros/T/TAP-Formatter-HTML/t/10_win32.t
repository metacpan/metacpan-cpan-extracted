use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';
use FileTempTFH;

use URI::file;
use TAP::Harness;
use_ok( 'TAP::Formatter::HTML' );

if ($^O !~ /win32/i) {
    no warnings;
    $TAP::Formatter::HTML::FAKE_WIN32_URIS = 1;
}

my $tmp = FileTempTFH->new;
my $f   = TAP::Formatter::HTML
  ->new({ silent => 1,
	  css_uris => ['C:\\some\\path', 'file:///C:\\another\\path'],
	  js_uris => ['\\yet\\another\\path', 'file://and/another'],
	  force_inline_css => 0 })
  ->output_fh( $tmp );

my $h = TAP::Harness->new({ merge => 1, formatter => $f });

my @tests = ( 't/data/01_pass.pl' );
eval { $h->runtests( @tests ) };
my $e = $@ || '';
is( $e, '', 'no error on generate report with win32 CSS URI' );

is_deeply( $f->css_uris,
	   [ URI::file->new( 'C:\\some\\path', 'win32' ),
	     URI::file->new( 'C:\\another\\path', 'win32' ) ],
	   'win32 css_uris as expected (RT 37983)' );

is_deeply( $f->js_uris,
	   [ URI::file->new( '\\yet\\another\\path', 'win32' ),
	     URI::file->new( 'file://and/another', 'win32' ) ],
	   'win32 js_uris as expected (RT 37983)' );

