use Test2::V0;

use Importer 'NewsExtractor::TextUtil' => 'parse_dateline_ymdhms';

my $answer = '2020-07-18T23:33:59+08:00';
my @problems = (
    '2020/7/18 23:33',
    '2020年7月18 23:33',
    '2020 年 7 月 18, 23:33',
    '發稿時間：2020/07/18 23:33',
);

for (@problems) {
    is(parse_dateline_ymdhms($_, '+08:00'), $answer);
}

done_testing;
