use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

plan skip_all => 'rebuild Makefile with TEST_FULL=1 to enable real test coverage' unless Panda::Time->can('test_gmtime');

use_system_zones();

# this OS have bugs in localtime/timelocal implementations which prevent them from working correctly with listed time zones
# in our time periods
my %buggy_zones = map {$_ => 1} qw#
    America/Anchorage Australia/Lord_Howe America/Scoresbysund America/Nome Asia/Choibalsan Asia/Ust-Nera Asia/Tehran posix/Iran posix/Asia/Tehran Iran 
#;

my @dias;
# check past
push @dias, [3599, "1980-01-01 00:00:00", "1986-01-01 00:00:00"];
# check transitions
push @dias, [3599, "2000-01-01 00:00:00", "2006-01-01 00:00:00"];
# check near future
push @dias, [3599, "2016-01-01 00:00:00", "2022-01-01 10:00:00"];
# check far future
push @dias, [3599, "2060-01-01 00:00:00", "2066-01-01 10:00:00"];

foreach my $zone (available_zones()) {
    next if $buggy_zones{$zone};
    $ENV{TZ} = $zone;
    tzset();
    POSIX::tzset();
    say "CHECKING $zone" unless $ENV{HARNESS_ACTIVE};
    
    foreach my $fname (qw/test_localtime test_timelocal/) {
        no strict 'refs';
        say "  CHECKING $fname" unless $ENV{HARNESS_ACTIVE};
        my $func = \&{"Panda::Time::$fname"};
        foreach my $dia (@dias) {
            my ($step, $from, $till) = @$dia;
            my $from_epoch = epoch_from($from);
            my $till_epoch = epoch_from($till);
            next if $zone =~ /^right/ and $till_epoch > 2100000000; # skip testing future in leap second zones (OS has bugs)
            my $ok = $func->($step, $from_epoch, $till_epoch);
            ok($ok);
        }
    }
}

done_testing();
