use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';
use FileTempTFH;

use TAP::Harness;
use TAP::Parser::Aggregator;
use_ok( 'TAP::Formatter::HTML' );

my $tmp = FileTempTFH->new;
my $f = TAP::Formatter::HTML->new({ silent => 1 })->output_fh( $tmp )->force_inline_css(0);
my $h = TAP::Harness->new({ merge => 1, formatter => $f });
my $a = TAP::Parser::Aggregator->new;

$a->start;
$h->aggregate_tests( $a, 't/data/01_pass.pl' );
$h->aggregate_tests( $a, 't/data/02_fail.pl' );
$a->stop;
$f->summary( $a );

my $html = $tmp->get_all_output;

ok( $html =~ qr|01_pass|, 'html contains file 1' );
ok( $html =~ qr|02_fail|, 'html contains file 2' );
like( $html, qr|<td class="file">2 files</td>|, '2 files processed' );
