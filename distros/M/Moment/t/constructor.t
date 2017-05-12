use strict;
use warnings FATAL => 'all';
use Test::More;

use Moment;

sub check__new__dt {
    my $dt = '2014-11-27 03:31:23';
    my $moment = Moment->new( dt => $dt );

    is( $moment->get_dt(), $dt, 'dt' );
}

sub check__new__fields {
    my $moment = Moment->new(
        year => 2012,
        month => 11,
        day => 4,

        hour => 12,
        minute => 55,
        second => 0,
    );

    is( $moment->get_dt(), '2012-11-04 12:55:00', 'fields' );
}

sub check__new__timestamp {
    my $moment = Moment->new(
        timestamp => 0,
    );

    is( $moment->get_dt(), '1970-01-01 00:00:00', 'timestamp' );
}

sub new__without__params {

    my $moment;
    eval {
        $moment = Moment->new();
    };

    ok(!!$@, 'new() dies');
}

sub new__not_all_params {

    my $moment;
    eval {
        $moment = Moment->new(
            # no year
            month => 11,
            day => 4,

            hour => 12,
            minute => 55,
            second => 0,
        );
    };

    ok(!!$@, 'new() dies without all params');
}

sub new__fileds_and_dt {
    my $moment;

    eval {
        $moment = Moment->new(
            year => 2012,
            month => 11,
            day => 4,

            hour => 12,
            minute => 55,
            second => 0,

            dt => '2014-11-27 03:31:23',
        );
    };

    ok(!!$@, 'new() dies with fields and dt');
}

sub new__dt_and_timestamp {
    my $moment;

    eval {
        $moment = Moment->new(
            dt => '2014-11-27 03:31:23',
            timestamp => 0,
        );
    };

    ok(!!$@, 'new() dies with dt and timestamp');
}

sub main_in_test {

    check__new__dt();
    check__new__fields();
    check__new__timestamp();

    new__without__params();
    new__not_all_params();
    new__fileds_and_dt();
    new__dt_and_timestamp();

    done_testing;

}
main_in_test();
