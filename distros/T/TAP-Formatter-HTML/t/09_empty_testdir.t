use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';
use FileTempTFH;

use TAP::Harness;
use_ok( 'TAP::Formatter::HTML' );

my $tmp = FileTempTFH->new;
my $f = TAP::Formatter::HTML->new({ silent => 1 })->output_fh( $tmp )->force_inline_css(0);
my $h = TAP::Harness->new({ merge => 1, formatter => $f });

eval { $h->runtests( ) };
my $e = $@ || '';
is( $e, '', 'no error on empty test dir (RT 41411)' );
