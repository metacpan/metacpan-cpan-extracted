use Test::More;
use Test::Deep;
use Data::Dumper;
use lib '../lib';
use NG;

parse_excel(
    't/test.xls',
    sub {
        my ($excel) = @_;
        isa_ok $excel, 'Excel';
        my $i = 1;
        $excel->sheets->each(
            sub {
                my ($sheet) = @_;
                isa_ok $sheet, 'Excel::Sheet';
                $sheet->name('new sheet name'.$i++);
            }
        );
        is $excel->sheet(1)->get(2, 'B')->value, 'test', 'get value ok';
        $excel->sheet(1)->get( 2, 'B' )->border_left(2, 'solid', 0xff0000);
        is $excel->sheet(1)->get(2, 'B')->border_left, '2, solid, 0xff0000', 'set value ok';
    }
);

done_testing();
