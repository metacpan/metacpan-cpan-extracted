use strict;
use warnings FATAL => 'all';
use Test::More;

use Moment;

sub main_in_test {

    my $monday = Moment->new( dt => '1990-10-22 03:12:17' );
    my $tuesday = Moment->new( dt => '2010-11-02 04:26:12' );
    my $wednesday = Moment->new( dt => '2000-12-06 21:25:42' );
    my $thursday = Moment->new( dt => '2011-11-10 20:19:28' );
    my $friday = Moment->new( dt => '1992-01-10 20:10:25' );
    my $saturday = Moment->new( dt => '1995-01-07 17:48:43' );
    my $sunday = Moment->new( dt => '1995-11-19 18:59:37' );

    is( $monday->get_weekday_number( first_day => 'monday' ), 1, 'monday 1' );
    is( $tuesday->get_weekday_number( first_day => 'monday' ), 2, 'tuesday 2' );
    is( $wednesday->get_weekday_number( first_day => 'monday' ), 3, 'wednesday 3' );
    is( $thursday->get_weekday_number( first_day => 'monday' ), 4, 'thursday 4' );
    is( $friday->get_weekday_number( first_day => 'monday' ), 5, 'friday 5' );
    is( $saturday->get_weekday_number( first_day => 'monday' ), 6, 'saturday 6' );
    is( $sunday->get_weekday_number( first_day => 'monday' ), 7, 'sunday 7' );

    is( $tuesday->get_weekday_number( first_day => 'tuesday' ), 1, 'tuesday 1' );
    is( $wednesday->get_weekday_number( first_day => 'tuesday' ), 2, 'wednesday 2' );
    is( $thursday->get_weekday_number( first_day => 'tuesday' ), 3, 'thursday 3' );
    is( $friday->get_weekday_number( first_day => 'tuesday' ), 4, 'friday 4' );
    is( $saturday->get_weekday_number( first_day => 'tuesday' ), 5, 'saturday 5' );
    is( $sunday->get_weekday_number( first_day => 'tuesday' ), 6, 'sunday 6' );
    is( $monday->get_weekday_number( first_day => 'tuesday' ), 7, 'monday 7' );

    is( $wednesday->get_weekday_number( first_day => 'wednesday' ), 1, 'wednesday 1' );
    is( $thursday->get_weekday_number( first_day => 'wednesday' ), 2, 'thursday 2' );
    is( $friday->get_weekday_number( first_day => 'wednesday' ), 3, 'friday 3' );
    is( $saturday->get_weekday_number( first_day => 'wednesday' ), 4, 'saturday 4' );
    is( $sunday->get_weekday_number( first_day => 'wednesday' ), 5, 'sunday 5' );
    is( $monday->get_weekday_number( first_day => 'wednesday' ), 6, 'monday 6' );
    is( $tuesday->get_weekday_number( first_day => 'wednesday' ), 7, 'tuesday 7' );

    is( $thursday->get_weekday_number( first_day => 'thursday' ), 1, 'thursday 1' );
    is( $friday->get_weekday_number( first_day => 'thursday' ), 2, 'friday 2' );
    is( $saturday->get_weekday_number( first_day => 'thursday' ), 3, 'saturday 3' );
    is( $sunday->get_weekday_number( first_day => 'thursday' ), 4, 'sunday 4' );
    is( $monday->get_weekday_number( first_day => 'thursday' ), 5, 'monday 5' );
    is( $tuesday->get_weekday_number( first_day => 'thursday' ), 6, 'tuesday 6' );
    is( $wednesday->get_weekday_number( first_day => 'thursday' ), 7, 'wednesday 7' );

    is( $friday->get_weekday_number( first_day => 'friday' ), 1, 'friday 1' );
    is( $saturday->get_weekday_number( first_day => 'friday' ), 2, 'saturday 2' );
    is( $sunday->get_weekday_number( first_day => 'friday' ), 3, 'sunday 3' );
    is( $monday->get_weekday_number( first_day => 'friday' ), 4, 'monday 4' );
    is( $tuesday->get_weekday_number( first_day => 'friday' ), 5, 'tuesday 5' );
    is( $wednesday->get_weekday_number( first_day => 'friday' ), 6, 'wednesday 6' );
    is( $thursday->get_weekday_number( first_day => 'friday' ), 7, 'thursday 7' );

    is( $saturday->get_weekday_number( first_day => 'saturday' ), 1, 'saturday 1' );
    is( $sunday->get_weekday_number( first_day => 'saturday' ), 2, 'sunday 2' );
    is( $monday->get_weekday_number( first_day => 'saturday' ), 3, 'monday 3' );
    is( $tuesday->get_weekday_number( first_day => 'saturday' ), 4, 'tuesday 4' );
    is( $wednesday->get_weekday_number( first_day => 'saturday' ), 5, 'wednesday 5' );
    is( $thursday->get_weekday_number( first_day => 'saturday' ), 6, 'thursday 6' );
    is( $friday->get_weekday_number( first_day => 'saturday' ), 7, 'friday 7' );

    is( $sunday->get_weekday_number( first_day => 'sunday' ), 1, 'sunday 1' );
    is( $monday->get_weekday_number( first_day => 'sunday' ), 2, 'monday 2' );
    is( $tuesday->get_weekday_number( first_day => 'sunday' ), 3, 'tuesday 3' );
    is( $wednesday->get_weekday_number( first_day => 'sunday' ), 4, 'wednesday 4' );
    is( $thursday->get_weekday_number( first_day => 'sunday' ), 5, 'thursday 5' );
    is( $friday->get_weekday_number( first_day => 'sunday' ), 6, 'friday 6' );
    is( $saturday->get_weekday_number( first_day => 'sunday' ), 7, 'saturday 7' );

    done_testing();

}
main_in_test();
