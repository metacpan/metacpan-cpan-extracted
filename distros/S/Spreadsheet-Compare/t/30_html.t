#!/usr/bin/env perl

use Spreadsheet::Compare::Common
    test => 1,
    temp => 1;

lives_ok {
    require_ok('Spreadsheet::Compare');

    my %expect = (
        csv_head_long => {qw/left 1398 right 1398 same 1396 diff 2 limit 0 miss 0 add 0 dup 0/},
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

    my @reports;
    $cmp->on(
        report_finished => sub ( $c, $title, $class, $rfn ) {
            my($t, $s) = reverse split(m!/!, $title);
            is( $class, 'Spreadsheet::Compare::Reporter::HTML', 'class' );
            like( $rfn, qr/$t\.html$/, 'file name ok' );
            push @reports, [ $t, $rfn ];
        }
    );

    my $err = $cmp->run->exit_code;
    is( $err, 0, 'exit code 0' ) or diag Dump( $cmp->errors );

    is_deeply( $counters{"$stitle/$_"}, $expect{$_}, "'$_' result ok" ) for sort keys %expect;

    # TODO: (issue) test HTML
}
'no dying tests';

done_testing();
