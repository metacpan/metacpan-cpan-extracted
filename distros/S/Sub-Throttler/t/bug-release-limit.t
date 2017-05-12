use strict;
use warnings;
use utf8;
use open qw( :std :utf8 );
use Test::More;
use Test::Exception;

use Sub::Throttler qw( :ALL );
use Sub::Throttler::Limit;

use EV;

my @Result;

my @t;
sub func {
    my $done = &throttle_me || return;
    my @p = @_;
    push @t, EV::timer 0.01, 0, sub {
        push @Result, $p[0];
        $done->();
    };
    return;
}


# Sub::Throttler::Limit didn't call flush() after releasing resources if amount
# of used resources was lower than ->limit

my $Timeout;
push @t, EV::timer 3, 0, sub { $Timeout = 1 };

throttle_add(Sub::Throttler::Limit->new(limit => 3), sub {
    my ($type, $name, @params) = @_;
    return { $name => 2 };
});

@Result = ();
func(10);
func(20);
is_deeply \@Result, [];
EV::run EV::RUN_ONCE until @Result;
is_deeply \@Result, [10];
EV::run EV::RUN_ONCE until 2==@Result || $Timeout;
is_deeply \@Result, [10,20],
    'Sub::Throttler::Limit call flush() after releasing resources';


done_testing();
