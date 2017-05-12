use strict;
use warnings;
use utf8;
use Test::More;
use Sub::Retry;

subtest 'simple' => sub {
    my $i = 0;
    my $ret = retry 10, 0, sub {
        die if $i++ != 5;
        return '4649';
    };
    is $ret, '4649';
};

subtest 'fail' => sub {
    my $i = 0;
    eval {
        retry 10, 0, sub {
            die "FAIL";
        };
    };
    like $@, qr/FAIL/;
    like $@, qr/\Q@{[ __FILE__ ]}/;
};

subtest 'context' => sub {
    subtest 'list' => sub {
        my @x = retry 10, 0, sub {
            wantarray ? (1,2,3) : 0721;
        };
        is join(',', @x), '1,2,3';
    };

    subtest 'scalar' => sub {
        my $x = retry 10, 0, sub {
            wantarray ? (1,2,3) : 0721;
        };
        is $x, 0721;
    };

    subtest 'void' => sub {
        my $ok;
        retry 10, 0, sub {
            $ok++ unless defined wantarray;
        };
        ok $ok, 'void context';
    };
};

subtest 'retry cond' => sub {
    subtest 'fail bad die' => sub {
        my $i;
        my $x = retry 10, 0, sub {
            $i++;
        }, sub { 1 };
        is $i, 10;
        ok !$x;
    };

    subtest 'success' => sub {
        my $x = retry 10, 0, sub {
            'ok';
        }, sub { $_[0] ne 'ok' ? 1 : 0 };
        is $x, 'ok';
    };

    subtest 'list context' => sub {
        my @x = retry 10, 0, sub {
            (1, 2, 3);
        }, sub { my @ret = @_; join(':', @ret) eq '1:2:3' ? 0 : 1 };
        is_deeply \@x, [qw/1 2 3/];
    }
};

subtest 'omit trailing sleep' => sub {
    no warnings 'redefine';

    my $count = 0;
    local *Sub::Retry::sleep = sub {
        $count++;
    };

    my $x = retry 10, 0, sub {}, sub { 1 };
    is $count, 9;
};

subtest 'current number' => sub {
    subtest 'list' => sub {
        my @numbers;
        my $i = 0;
        my @x = retry 10, 0, sub {
            push @numbers, shift;
            die if ++$i < 10;
        };
        is_deeply \@numbers, [1..10];
    };

    subtest 'scalar' => sub {
        my @numbers;
        my $i = 0;
        my $x = retry 10, 0, sub {
            push @numbers, shift;
            die if ++$i < 10;
        };
        is_deeply \@numbers, [1..10];
    };

    subtest 'void' => sub {
        my @numbers;
        my $i = 0;
        retry 10, 0, sub {
            push @numbers, shift;
            die if ++$i < 10;
        };
        is_deeply \@numbers, [1..10];
    };
};

done_testing;

