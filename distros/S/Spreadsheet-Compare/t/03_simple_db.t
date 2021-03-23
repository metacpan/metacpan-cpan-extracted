#!/usr/bin/env perl

use Spreadsheet::Compare::Common test => 1;

require_ok('Spreadsheet::Compare');

lives_ok {
    my %expect = (
        'default config'            => {qw/left 4 right 4 same 3 diff 1 miss 0 add 0 dup 0 limit 0/},
        'fail with changing column' => {qw/left 4 right 4 same 0 diff 4 miss 0 add 0 dup 0 limit 0/},
        'ignore column fix decimal' => {qw/left 4 right 4 same 2 diff 2 miss 0 add 0 dup 0 limit 0/},
        'individual limit'          => {qw/left 4 right 4 same 2 diff 2 miss 0 add 0 dup 0 limit 2/},
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
'no dying tests';

done_testing();
