use strict;
use warnings FATAL => 'all';
use Test::More;

use Moment;

sub main_in_test {

    my $m1 = Moment->new( dt => '2014-11-24 00:00:00');
    ok($m1->is_monday(), 'is_monday()');
    ok(!$m1->is_tuesday(), 'not is_tuesday()');
    is($m1->get_weekday_name(), 'monday', 'get_weekday_name() monday');

    my $m2 = Moment->new( dt => '2014-11-25 00:00:00');
    ok($m2->is_tuesday(), 'is_tuesday()');
    ok(!$m2->is_wednesday(), 'not is_wednesday()');
    is($m2->get_weekday_name(), 'tuesday', 'get_weekday_name() tuesday');

    my $m3 = Moment->new( dt => '2014-11-26 00:00:00');
    ok($m3->is_wednesday(), 'is_wednesday()');
    ok(!$m3->is_thursday(), 'not is_thursday()');
    is($m3->get_weekday_name(), 'wednesday', 'get_weekday_name() thursday');

    my $m4 = Moment->new( dt => '2014-11-27 00:00:00');
    ok($m4->is_thursday(), 'is_thursday()');
    ok(!$m4->is_friday(), 'not is_friday()');
    is($m4->get_weekday_name(), 'thursday', 'get_weekday_name() thursday');

    my $m5 = Moment->new( dt => '2014-11-28 00:00:00');
    ok($m5->is_friday(), 'is_friday()');
    ok(!$m5->is_saturday(), 'not is_saturday()');
    is($m5->get_weekday_name(), 'friday', 'get_weekday_name() friday');

    my $m6 = Moment->new( dt => '2014-11-29 00:00:00');
    ok($m6->is_saturday(), 'is_saturday()');
    ok(!$m6->is_sunday(), 'not is_sunday()');
    is($m6->get_weekday_name(), 'saturday', 'get_weekday_name() saturday');

    my $m7 = Moment->new( dt => '2014-11-30 00:00:00');
    ok($m7->is_sunday(), 'is_sunday()');
    ok(!$m7->is_monday(), 'not is_monday()');
    is($m7->get_weekday_name(), 'sunday', 'get_weekday_name() sunday');

    done_testing;

}
main_in_test();
