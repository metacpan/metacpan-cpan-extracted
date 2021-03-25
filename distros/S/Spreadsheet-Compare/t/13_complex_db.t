#!/usr/bin/env perl

use Spreadsheet::Compare::Common test => 1;

lives_ok {
    require_ok('Spreadsheet::Compare');

    SKIP: {

        skip "SPREADSHEET_COMPARE_TEST_ALL not set " unless $ENV{SPREADSHEET_COMPARE_TEST_ALL};

        my $ds_installed = try {
            load 'DBD::SQLite';
            1
        }
        catch { undef };
        skip "DBD::SQLite not installed" unless $ds_installed;

        my %expect = (
            'csv_med_dup auto'   => {qw/left 629 right 629 same 153 diff 476 limit 334 miss 0 add 0 dup 6/},
            'csv_med_dup sorted' => {qw/left 629 right 629 same 153 diff 476 limit 334 miss 0 add 0 dup 6/},
            'csv_mixid'          => {qw/left 880 right 880 same 515 diff 365 limit 361 miss 0 add 0 dup 0/},
            'csv_mixid sorted'   => {qw/left 880 right 880 same 515 diff 365 limit 361 miss 0 add 0 dup 0/},
            'csv_mixid limit'    => {qw/left 200 right 200 same 67 diff 133 limit 133 miss 0 add 0 dup 0/},
        );

        my $stitle = path($Script)->basename('.t');
        my $cfn    = "cfg/$stitle.yml";

        my $cmp = Spreadsheet::Compare->new(
            config => "$Bin/$cfn",
            jobs   => 2,
        );

        my %counters;
        $cmp->on(
            final_counters => sub ( $c, $title, $counter ) {
                $counters{$title} = $counter;
            }
        );

        my %fetches;
        $cmp->on(
            after_fetch => sub ( $c, $title ) {
                $fetches{$title}++;
            }
        );

        my $err = $cmp->run->exit_code;
        is( $err, 0, 'exit code 0' ) or diag Dump( $cmp->errors );

        is_deeply( $counters{"$stitle/$_"}, $expect{$_}, "'$_' result ok" ) for sort keys %expect;

        is( $fetches{"$stitle/csv_mixid"},        1, 'one fetch only' );
        is( $fetches{"$stitle/csv_mixid sorted"}, 9, 'multiple fetches' );
    }
}
'no dying tests';

done_testing();
