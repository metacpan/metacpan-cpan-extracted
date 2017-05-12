use strict;
use warnings;
use Test::More;

use Statistics::Swoop;


{
    note "blank list";
    my @list = ();
    my $ss = Statistics::Swoop->new(\@list);

    is $ss->maximum, undef, 'maximum';
    is $ss->max,     undef, 'max';
    is $ss->minimum, undef, 'minimum';
    is $ss->min,     undef, 'min';
    is $ss->sum,     undef, 'sum';
    is $ss->average, undef, 'average';
    is $ss->avg,     undef, 'avg';
    is $ss->range,   undef, 'range';
}

{
    my @list = (0);
    note "1 element list: @list";
    my $ss = Statistics::Swoop->new(\@list);

    is $ss->maximum, 0, 'maximum';
    is $ss->max,     0, 'max';
    is $ss->minimum, 0, 'minimum';
    is $ss->min,     0, 'min';
    is $ss->sum,     0, 'sum';
    is $ss->average, 0, 'average';
    is $ss->avg,     0, 'avg';
    is $ss->range,   0, 'range';
}

{
    my @list = (1);
    note "1 element list: @list";
    my $ss = Statistics::Swoop->new(\@list);

    is $ss->maximum, 1, 'maximum';
    is $ss->max,     1, 'max';
    is $ss->minimum, 1, 'minimum';
    is $ss->min,     1, 'min';
    is $ss->sum,     1, 'sum';
    is $ss->average, 1, 'average';
    is $ss->avg,     1, 'avg';
    is $ss->range,   1, 'range';
}

{
    my @list = (1, 4);
    note "2 elements list: @list";
    my $ss = Statistics::Swoop->new(\@list);

    is $ss->maximum, 4,   'maximum';
    is $ss->max,     4,   'max';
    is $ss->minimum, 1,   'minimum';
    is $ss->min,     1,   'min';
    is $ss->sum,     5,   'sum';
    is $ss->average, 2.5, 'average';
    is $ss->avg,     2.5, 'avg';
    is $ss->range,   3,   'range';
}

{
    my @list = (5, 4);
    note "2 elements list: @list";
    my $ss = Statistics::Swoop->new(\@list);

    is $ss->max,   5,   'max';
    is $ss->min,   4,   'min';
    is $ss->sum,   9,   'sum';
    is $ss->avg,   4.5, 'avg';
    is $ss->range, 1,   'range';
}

{
    my @list = (2, 4, 1);
    note "3 elements list: @list";
    my $ss = Statistics::Swoop->new(\@list);

    is $ss->max,   4, 'max';
    is $ss->min,   1, 'min';
    is $ss->sum,   7, 'sum';
    is $ss->range, 3, 'range';
    like $ss->avg, qr/^2\.33\d+/, 'avg';
}

{
    my @list = (qw/1 2 3 4 5 6 7 8 9 10/);
    note "10 elements list: @list";
    my $ss = Statistics::Swoop->new(\@list);

    is $ss->max,   10,  'max';
    is $ss->min,   1,   'min';
    is $ss->sum,   55,  'sum';
    is $ss->avg,   5.5, 'avg';
    is $ss->range, 9,   'range';
}

done_testing;
