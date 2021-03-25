#!/usr/bin/env perl

use Spreadsheet::Compare::Common test => 1;

lives_ok {
    require_ok('Spreadsheet::Compare');

    SKIP: {

        skip "SPREADSHEET_COMPARE_TEST_ALL not set " unless $ENV{SPREADSHEET_COMPARE_TEST_ALL};

        my $sr_installed = try { load 'Spreadsheet::Read'; 1 } catch { undef };
        skip "Spreadsheet::Read not installed" unless $sr_installed;

        my %expect = (
            'ODS format'  => {qw/left 4 right 4 same 3 diff 1 miss 0 add 0 dup 0 limit 0/},
            'XLSX format' => {qw/left 4 right 4 same 3 diff 1 miss 0 add 0 dup 0 limit 0/},
        );

        my $stitle = path($Script)->basename('.t');
        my $cfn    = "$Bin/cfg/$stitle.yml";

        my $cmp = Spreadsheet::Compare->new(
            config => $cfn,
        );

        my %counters;
        $cmp->on(
            final_counters => sub ( $c, $title, $counter ) {
                $counters{$title} = $counter;
            }
        );

        my $err = $cmp->run->exit_code;
        is( $err, 0, 'exit code 0' ) or diag Dump( $cmp->errors );

        is_deeply( $counters{"$stitle/$_"}, $expect{$_}, "'$_' result ok" ) for sort keys %expect;

    }

}
'no dying tests';

done_testing();
