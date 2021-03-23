#!/usr/bin/env perl

use Spreadsheet::Compare::Common test => 1;

lives_ok {
    require_ok('Spreadsheet::Compare');

    my %expect = (
        'csv_med_dup auto'      => {qw/left   629 right   629 same   153 diff 476  limit 334 miss 0 add 0 dup 6/},
        'csv_med_dup no header' => {qw/left   629 right   629 same   153 diff 476  limit 334 miss 0 add 0 dup 6/},
        'csv_med_dup chunked'   => {qw/left   629 right   629 same   153 diff 476  limit 334 miss 0 add 0 dup 6/},
        'csv_mixid'             => {qw/left   880 right   880 same   515 diff 365  limit 361 miss 0 add 0 dup 0/},
        'csv_mixid sorted'      => {qw/left   880 right   880 same   515 diff 365  limit 361 miss 0 add 0 dup 0/},
        'csv_mixid limit'       => {qw/left   200 right   200 same    67 diff 133  limit 133 miss 0 add 0 dup 0/},
        'csv_mixid chunked'     => {qw/left   880 right   880 same   515 diff 365  limit 361 miss 0 add 0 dup 0/},
        'csv_desep_no_convert'  => {qw/left   789 right   789 same   438 diff 351  limit 298 miss 0 add 0 dup 0/},
        'csv_desep_convert'     => {qw/left   789 right   789 same   438 diff 351  limit 298 miss 0 add 0 dup 0/},
    );

    my $stitle = path($Script)->basename('.t');
    my $cfn    = "$Bin/cfg/$stitle.yml";

    my $cmp = Spreadsheet::Compare->new(
        config => $cfn,
        jobs   => 4,
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
'no dying tests';

done_testing();
