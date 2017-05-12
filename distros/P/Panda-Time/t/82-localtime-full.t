use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use PDTest;

plan skip_all => 'rebuild Makefile with TEST_FULL=1 to enable real test coverage' unless Panda::Time->can('test_gmtime');

use_system_zones();

my @dias;
# check past
push @dias, [39, "1879-01-01 00:00:00", "1881-01-01 00:00:00"];
# check transitions
push @dias, [299, "1980-01-01 00:00:00", "1986-01-01 00:00:00"];
push @dias, [299, "2000-01-01 00:00:00", "2006-01-01 00:00:00"];
push @dias, [59, "2000-01-01 00:00:00", "2001-01-01 00:00:00"];
# check near future
push @dias, [299, "2016-01-01 00:00:00", "2022-01-01 10:00:00"];
# check far future
push @dias, [299, "2060-01-01 00:00:00", "2066-01-01 10:00:00"];
push @dias, [59, "2066-01-01 00:00:00", "2067-01-01 10:00:00"];

# negative check
push @dias, [59, "-1000-01-01 12:34:56",  "-999-01-01 00:00:00"];

test_zone($_) for qw# Europe/Moscow America/New_York Australia/Melbourne #;

sub test_zone {
    $ENV{TZ} = shift;
    tzset();
    POSIX::tzset();
    
    foreach my $dia (@dias) {
        my ($step, $from, $till) = @$dia;
        ok(Panda::Time::test_localtime($step, epoch_from($from), epoch_from($till)));
    }
    
    # random check - RAND_FLAG, DIA (+- from 1970), ITERS COUNT
    ok(Panda::Time::test_localtime(0, 1500000000, 1000000));
    ok(Panda::Time::test_localtime(0, 20000000000, 1000000));
    
    for (my $i = 0; $i < 1000; $i++) {
        my $epoch = int rand(2**31);
        
        my @core = CORE::localtime($epoch);
        $core[5] += 1900;
        cmp_deeply([&localtime($epoch)], \@core);
    }
}

done_testing();