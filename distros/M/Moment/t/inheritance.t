use strict;
use warnings FATAL => 'all';

package My::Moment;

use base 'Moment';

sub get_d {
    my ($self) = @_;

    my $d = sprintf(
        "%04d-%02d-%02d",
        $self->get_year(),
        $self->get_month(),
        $self->get_day(),
    );

    return $d;
}

1;

package main;

use Test::More;

sub main_in_test {

    my $m = My::Moment->new(
        dt => '2000-01-01 01:02:03',
    );

    is(ref($m), 'My::Moment', 'ref eq My::Moment');
    is($m->get_dt(), '2000-01-01 01:02:03', 'get_dt()');
    is($m->get_d(), '2000-01-01', 'get_d()');

    # plus()
    my $m_plus = $m->plus( day => 2 );
    is(ref($m_plus), 'My::Moment', 'after plus() ref eq My::Moment');
    is($m_plus->get_dt(), '2000-01-03 01:02:03', 'get_dt()');
    is($m_plus->get_d(), '2000-01-03', 'get_d()');

    # minus()
    my $m_minus = $m->minus( second => 3 );
    is(ref($m_minus), 'My::Moment', 'after minus() ref eq My::Moment');
    is($m_minus->get_dt(), '2000-01-01 01:02:00', 'get_dt()');
    is($m_minus->get_d(), '2000-01-01', 'get_d()');

    # get_month_start()
    my $m_month_start = $m->get_month_start();
    is(ref($m_month_start), 'My::Moment', 'after get_month_start() ref eq My::Moment');
    is($m_month_start->get_dt(), '2000-01-01 00:00:00', 'get_dt()');
    is($m_month_start->get_d(), '2000-01-01', 'get_d()');

    # get_month_end():
    my $m_month_end = $m->get_month_end();
    is(ref($m_month_end), 'My::Moment', 'after get_month_end() ref eq My::Moment');
    is($m_month_end->get_dt(), '2000-01-31 23:59:59', 'get_dt()');
    is($m_month_end->get_d(), '2000-01-31', 'get_d()');

    # now();
    my $now = My::Moment->now();
    is(ref($now), 'My::Moment', 'after get_month_end() ref eq My::Moment');

    done_testing;

}
main_in_test();
