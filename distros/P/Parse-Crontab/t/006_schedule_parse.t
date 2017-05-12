use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Parse::Crontab::Schedule;

my $schedule = Parse::Crontab::Schedule->parse('*/1 22 * * 5-7');
isa_ok $schedule, 'Parse::Crontab::Schedule';

subtest day_of_week_match => sub {
    ok $schedule->day_of_week->match(0);
    ok !$schedule->day_of_week->match(4);
};

subtest match => sub {
    ok  $schedule->match(day => 9,  month => 6, year => 2013, hour => 22, minute => 0);
    ok !$schedule->match(day => 9,  month => 6, year => 2013, hour => 21, minute => 0);
    ok !$schedule->match(day => 11, month => 6, year => 2013, hour => 22, minute => 0);
};

subtest normal_match => sub {
    my $schedule = Parse::Crontab::Schedule->parse('*/1 12 10 11 *');

    ok  $schedule->match(day => 10, month => 11, hour => 12, minute => 0);
    ok  $schedule->match(day => 10, month => 11, hour => 12, minute => 4);

    ok !$schedule->match(day => 10, month => 11, hour => 13, minute => 4);
    ok !$schedule->match(day => 11, month => 11, hour => 12, minute => 4);
};

throws_ok {
    Parse::Crontab::Schedule->parse('* 12 10 11 *');
} qr/Specifying '\*'/;

done_testing;
