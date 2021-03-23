#!/usr/bin/env perl

use Spreadsheet::Compare::Common
    test => 1,
    temp => 1;

lives_ok {
    require_ok('Spreadsheet::Compare');

    my %expect = (
        'csv_med_dup auto'      => {qw/left   629 right   629 same   153 diff 476  limit 334 miss 0 add 0 dup 6/},
        'csv_med_dup no header' => {qw/left   629 right   629 same   153 diff 476  limit 334 miss 0 add 0 dup 6/},
        'csv_med_dup chunked'   => {qw/left   629 right   629 same   153 diff 476  limit 334 miss 0 add 0 dup 6/},
        'csv_mixid'             => {qw/left   880 right   880 same   515 diff 365  limit 361 miss 0 add 0 dup 0/},
        'csv_mixid sorted'      => {qw/left   880 right   880 same   515 diff 365  limit 361 miss 0 add 0 dup 0/},
        'csv_mixid limit'       => {qw/left   200 right   200 same    58 diff 142  limit 142 miss 0 add 0 dup 0/},
        'csv_mixid chunked'     => {qw/left   880 right   880 same   515 diff 365  limit 361 miss 0 add 0 dup 0/},
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
            my( $t, $s ) = reverse split( m!/!, $title );
            $counters{$t} = $counter;
        }
    );

    my $err = $cmp->run->exit_code;
    is( $err, 0, 'exit code 0' ) or diag Dump( $cmp->errors );

    is_deeply( $counters{$_}, $expect{$_}, "'$_' result ok" ) for sort keys %expect;

    my $sfn = path( $ENV{SC_TMPD}, "${stitle}.html" );
    ok( $sfn->exists, "summary file >>$sfn<< exists" );

}
'no dying tests';

done_testing();
