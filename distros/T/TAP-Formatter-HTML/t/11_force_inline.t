use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More tests => 8;
use FileTempTFH;

use TAP::Harness;
use TAP::Parser::Aggregator;
use_ok( 'TAP::Formatter::HTML' );

my @tests = ( 't/data/01_pass.pl' );
my $tmp = FileTempTFH->new;
my $f = TAP::Formatter::HTML->new({ silent => 1 })->output_fh( $tmp )->force_inline_css(1)->force_inline_js(1);
my $h = TAP::Harness->new({ merge => 1, formatter => $f });

$h->runtests(@tests);

my $html = $tmp->get_all_output;

ok( $html =~ qr|01_pass|, 'html contains file 1' );
ok( $html =~ qr|jQuery JavaScript Library v\d+.\d+.\d+|, 'html contains jQuery src' );
ok( $html =~ qr|default javascript for report|, 'html contains default js' );
ok( $html =~ qr|default stylesheet for report body|, 'html contains default css body' );
ok( $html =~ qr|default stylesheet for report page layout|, 'html contains default css page' );

ok( $html !~ qr|href=".+/TAP/Formatter/HTML/default_report\.css"|, 'html does not contain links to css files' );
ok( $html !~ qr|src=".+/TAP/Formatter/HTML/jquery-1\.4\.2\.min\.js"|, 'html does not contain links to js files' );
