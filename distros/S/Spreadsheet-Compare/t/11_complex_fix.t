#!/usr/bin/env perl

use Spreadsheet::Compare::Common test => 1;

lives_ok {
    require_ok('Spreadsheet::Compare');

    my %expect = (
        'Fix Big'       => {qw/left   854 right   854 same   851 diff 3 limit 0 miss 0 add 0 dup 0/},
        'Fix Big Limit' => {qw/left   854 right   854 same   851 diff 3 limit 2 miss 0 add 0 dup 0/},
        'Duplicates'    => {qw/left 15536 right 15536 same 15535 diff 1 limit 0 miss 0 add 0 dup 0/},
    );

    my $stitle = path($Script)->basename('.t');
    my $cfn    = "$Bin/cfg/$stitle.yml";

    my $cmp = Spreadsheet::Compare->new(
        config => $cfn,
        jobs   => 3,
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
