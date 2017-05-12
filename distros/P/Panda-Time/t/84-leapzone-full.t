use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use PDTest;

plan skip_all => 'rebuild Makefile with TEST_FULL=1 to enable real test coverage' unless Panda::Time->can('test_gmtime');

use_system_zones();
my $lzdir = leap_zones_dir();
plan skip_all => "you dont have leap zones in $lzdir" unless -d $lzdir;

my @dias;
# check past - unavailable, OS's timelocal cannot work with these dates
# check transitions
push @dias, [86399, "1910-01-01 00:00:00", "1970-01-01 00:00:00"];
push @dias, [3599, "1980-01-01 00:00:00", "1986-01-01 00:00:00"];
push @dias, [3599, "2000-01-01 00:00:00", "2006-01-01 00:00:00"];
push @dias, [3599, "2006-01-01 00:00:00", "2011-01-01 00:00:00"];
# check near future
push @dias, [3599, "2016-01-01 00:00:00", "2022-01-01 10:00:00"];
# check far future
#push @dias, [3599, "2060-01-01 00:00:00", "2066-01-01 10:00:00"]; # cannot check: OS has bugs with DST transitions in future in leap seconds zones

# leap moments
push @dias, [1, "1981-06-30 12:00:00", "1981-07-01 12:00:00"];
push @dias, [1, "1982-06-30 12:00:00", "1982-07-01 12:00:00"];
push @dias, [1, "1983-06-30 12:00:00", "1983-07-01 12:00:00"];
push @dias, [1, "1985-06-30 12:00:00", "1985-07-01 12:00:00"];
push @dias, [1, "1987-12-31 12:00:00", "1988-01-01 12:00:00"];
push @dias, [1, "1989-12-31 12:00:00", "1990-01-01 12:00:00"];
push @dias, [1, "1990-12-31 12:00:00", "1991-01-01 12:00:00"];
push @dias, [1, "1992-06-30 12:00:00", "1992-07-01 12:00:00"];
push @dias, [1, "1993-06-30 12:00:00", "1993-07-01 12:00:00"];
push @dias, [1, "1994-06-30 12:00:00", "1994-07-01 12:00:00"];
push @dias, [1, "1995-12-31 12:00:00", "1996-01-01 12:00:00"];
push @dias, [1, "1997-06-30 12:00:00", "1997-07-01 12:00:00"];
push @dias, [1, "1998-12-31 12:00:00", "1999-01-01 12:00:00"];
push @dias, [1, "2005-12-31 12:00:00", "2006-01-01 12:00:00"];
push @dias, [1, "2008-12-31 12:00:00", "2009-01-01 12:00:00"];
push @dias, [1, "2012-06-30 12:00:00", "2012-07-01 12:00:00"];

test_zone($_) for qw# right/UTC right/America/New_York right/Australia/Melbourne #;

sub test_zone {
    $ENV{TZ} = shift;
    tzset();
    POSIX::tzset();
    
    foreach my $dia (@dias) {
        my ($step, $from, $till) = @$dia;
        ok(Panda::Time::test_localtime($step, epoch_from($from), epoch_from($till)));
        ok(Panda::Time::test_timelocal($step, epoch_from($from), epoch_from($till)));
    }
    
    # random check - RAND_FLAG, DIA (+- from 1970), ITERS COUNT
    ok(Panda::Time::test_localtime(0, 1500000000, 5000000));
    ok(Panda::Time::test_localtime(0, 20000000000, 5000000));
    # random check - RAND_FLAG, DIA (1910+[0-DIA]), ITERS COUNT
    ok(Panda::Time::test_timelocal(0, 120, 1000000));
}

done_testing();
