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
            my( $t, $s ) = reverse split( m!/!, $title );
            is( $class, 'Spreadsheet::Compare::Reporter::XLSX', 'class' );
            like( $rfn, qr/$t\.xlsx$/, 'file name ok' );
            push @reports, [ $t, $rfn ];
        }
    );

    my $err = $cmp->run->exit_code;
    is( $err, 0, 'exit code 0' ) or diag Dump( $cmp->errors );

    is_deeply( $counters{"$stitle/$_"}, $expect{$_}, "'$_' result ok" ) for sort keys %expect;

    SKIP: {
        my $sr_installed = try { load 'Spreadsheet::Read'; 1 } catch { undef };
        skip "Spreadsheet::Read not installed" unless $sr_installed;

        my $spx_installed = try { load 'Spreadsheet::ParseXLSX'; 1 } catch { undef };
        skip "Spreadsheet::ParseXLSX not installed" unless $spx_installed;

        subtest "check $_->[0] report", \&_check_content, @$_ for @reports;
    }

}
'no dying tests';

done_testing();

sub _check_content ( $title, $rfn ) {
    my $ecfg = Load( data_section( 'main', $title ) );
    my $wb   = Spreadsheet::Read->new( $rfn, attr => 1 ) or diag $@;
    is( scalar( $wb->sheets ), $ecfg->{sheets}, "number of sheets" ) if $ecfg->{sheets};
    $ecfg->{last} //= {};
    for my $sheet ( keys $ecfg->{last}->%* ) {
        my( $c, $r ) = $ecfg->{last}{$sheet}->@*;
        is( $wb->sheet($sheet)->maxcol, $c, "$sheet number of columns" );
        is( $wb->sheet($sheet)->maxrow, $r, "$sheet number of rows" );
    }
    for my $entry ( $ecfg->{format}->@* ) {
        my $sheet = $entry->{sheet};
        for my $check ( $entry->{checks}->@* ) {
            for my $cell ( $check->{cells}->@* ) {
                my $cell_attr = $wb->sheet($sheet)->attr($cell);
                my( $r, $c ) = $wb->sheet($sheet)->cell2cr($cell);
                my $cell_val = $wb->sheet($sheet)->cell( $r, $c );
                for my $attr ( keys $check->{attr}->%* ) {
                    my $exp = $check->{attr}{$attr};
                    is( $cell_attr->{$attr}, $exp, "$attr of $cell is " . ( $exp // 'undef' ) );
                }
                for my $exp ( $check->{cont}->@* ) {
                    is( $cell_val, $exp, 'cell value' );
                }
            }
        }
    }
    return;
}

__DATA__

@@ csv_head_long
sheets: 4
last:
    Differences: [14, 5]
    Missing:     [14, 1]
    Additional:  [14, 1]
    Duplicates:  [14, 1]
format:
  - sheet: Differences
    checks:
      - cells: [H1, H2, H3, J1, J4, J5]
        attr: {bgcolor: '#ffff00'}
      - cells: [I1, I2, I3, J2, J3]
        attr: {bgcolor: ~}
      - cells: [H4, H5, I4, I5]
        attr: {bgcolor: '#c0c0c0'}
      - cells: [A2, A4, H2, J4]
        attr: {fgcolor: '#0000ff'}
      - cells: [A3, A5, H3, J5]
        attr: {fgcolor: '#ff0000'}
      - cells: [A1, H1]
        attr: {fgcolor: ~, bold : 1}

@@ csv_head_long_diff
sheets: 4
last:
    Differences: [14, 7]
    Missing:     [14, 1]
    Additional:  [14, 1]
    Duplicates:  [14, 1]
format:
  - sheet: Differences
    checks:
      - cells: [H1, H2, H3, H4, J1, J5, J6, J7]
        attr: {bgcolor: '#ffff00'}
      - cells: [I1, I2, I3, I4, J2, J3, J4]
        attr: {bgcolor: ~}
      - cells: [H5, H6, H7, I5, I6, I7]
        attr: {bgcolor: '#c0c0c0'}
      - cells: [A4, A7]
        attr: {fgcolor: '#008000'}
      - cells: [H4, J7]
        attr: {fgcolor: ~}

@@ csv_head_long_num
sheets: 4
last:
    Differences: [15, 7]
    Missing:     [15, 1]
    Additional:  [15, 1]
    Duplicates:  [15, 1]
format:
  - sheet: Differences
    checks:
      - cells: [I1, I2, I3, I4, K1, K5, K6, K7]
        attr: {bgcolor: '#ffff00'}
      - cells: [J1, J2, J3, J4, K2, K3, K4]
        attr: {bgcolor: ~}
      - cells: [I5, I6, I7, J5, J6, J7]
        attr: {bgcolor: '#c0c0c0'}
      - cells: [A4, A7]
        attr: {fgcolor: '#008000'}
      - cells: [I4, K7]
        attr: {fgcolor: ~}

@@ csv_head_long_max
sheets: 4
last:
    Differences: [22, 7]
    Missing:     [22, 1]
    Additional:  [22, 1]
    Duplicates:  [22, 1]
format:
  - sheet: Differences
    checks:
      - cells: [O1, O2, O3, O4, Q1, Q5, Q6, Q7]
        attr: {bgcolor: '#ffff00'}
      - cells: [P1, P2, P3, P4, Q2, Q3, Q4]
        attr: {bgcolor: ~}
      - cells: [I5, I6, I7, P5, P6, P7]
        attr: {bgcolor: '#c0c0c0'}
      - cells: [A4, A7]
        attr: {fgcolor: '#008000'}
      - cells: [O4, Q7]
        attr: {fgcolor: ~}
      - cells: [U1]
        cont: [KVN]
      - cells: [H1]
        cont: [Type]
      - cells: [H7]
        cont: [IGNORED]
