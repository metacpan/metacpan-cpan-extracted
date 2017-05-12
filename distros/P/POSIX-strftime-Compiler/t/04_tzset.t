use strict;
use warnings;
use Test::More;
use POSIX qw//;
use Time::Local;
use POSIX::strftime::Compiler qw/strftime/;

eval {
    POSIX::tzset;
    die q!tzset is implemented on this ! . $^O  .q!. But Windows can't change tz inside script! if $^O =~ m/^(MSWin32|cygwin)$/i;
};
if ( $@ ) {
    plan skip_all => $@;
}

my @timezones = ( 
    ['Australia/Darwin','+0930','+0930','+0930','+0930',qr/A?CST/,qr/A?CST/,qr/A?CST/,qr/A?CST/ ],
    ['Asia/Tokyo', '+0900','+0900','+0900','+0900', 'JST','JST','JST','JST'],
    ['UTC', '+0000','+0000','+0000','+0000','UTC','UTC','UTC','UTC'],
    ['Europe/London', '+0000','+0100','+0100','+0000',qr/(GMT|WET)/,qr/(BST|WEST)/,qr/(BST|WEST)/,qr/(GMT|WET|)/],
    ['Europe/Paris', '+0100','+0200','+0200','+0100','CET','CEST','CEST','CET'],
    ['America/New_York','-0500', '-0400', '-0400', '-0500','EST','EDT','EDT','EST']
);

for my $timezones (@timezones) {
    my ($timezone, @tz) = @$timezones;
    local $ENV{TZ} = $timezone;
    POSIX::tzset;

    subtest "$timezone" => sub {
        my $i=0;
        for my $date ( ([10,1,2013], [10,5,2013], [15,8,2013], [15,11,2013]) ) {
            my ($day,$month,$year) = @$date;
            my $str = strftime('%z',localtime(timelocal(0, 45, 12, $day, $month - 1, $year)));
            is $str, $tz[$i];
            my $str2 = strftime('%Z',localtime(timelocal(0, 45, 12, $day, $month - 1, $year)));
            if ( ref $tz[$i+4] ) {
                like $str2, $tz[$i+4], "$timezone / $year-$month-$day => $str2";
            }
            else {
                is $str2, $tz[$i+4], "$timezone / $year-$month-$day => $str2";
            }

            my $str3 = POSIX::strftime::Compiler::_tzoffset(localtime(timelocal(0, 45, 12, $day, $month - 1, $year)));
            is $str3, $tz[$i];
            my $str4 = POSIX::strftime::Compiler::_tzname(localtime(timelocal(0, 45, 12, $day, $month - 1, $year)));
            if ( ref $tz[$i+4] ) {
                like $str4, $tz[$i+4], "$timezone / $year-$month-$day => $str4";
            }
            else {
                is $str4, $tz[$i+4], "$timezone / $year-$month-$day => $str4";
            }

            $i++;
        }
    };

}

done_testing();

