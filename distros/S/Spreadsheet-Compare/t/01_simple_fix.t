#!/usr/bin/env perl

use Spreadsheet::Compare::Common test => 1;

lives_ok {
    require_ok('Spreadsheet::Compare');

    my %expect = (
        'fixed format'           => {qw/left 4 right 4 same 3 diff 1 miss 0 add 0 dup 0 limit 0/},
        'fixed format chunked 1' => {qw/left 4 right 4 same 3 diff 1 miss 0 add 0 dup 0 limit 0/},
        'fixed format chunked 2' => {qw/left 4 right 4 same 3 diff 1 miss 0 add 0 dup 0 limit 0/},
    );

    my %fetch_expect = (
        'fixed format'           => 1,
        'fixed format chunked 1' => 4,
        'fixed format chunked 2' => 4,
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

    my %fetches;
    $cmp->on(
        after_fetch => sub ( $c, $title ) {
            $fetches{$title}++;
        }
    );

    my $err = $cmp->run->exit_code;
    is( $err, 0, 'exit code 0' ) or diag Dump( $cmp->errors );

    is_deeply( $counters{"$stitle/$_"}, $expect{$_}, "'$_' result ok" ) for sort keys %expect;
    is( $fetches{"$stitle/$_"}, $fetch_expect{$_}, "'$_' fetches ok" )  for sort keys %fetch_expect;

}
'no dying tests';

done_testing();
