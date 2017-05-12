#!perl

use strict;
use warnings;
use Test::More;
use Stacktrace::Configurable;

use t004_l2;

my $trace = Stacktrace::Configurable->new;
my $res;

my $l1_line = __LINE__;
sub l1 {$res = $trace->get_trace->as_string}
sub l2;

delete $ENV{STACKTRACE_CONFIG};

{
    $trace->format='y%fx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
yt004_l2.pmx
yt/004-percent_f.tx
EOF

    is $res, $exp, '%s';
}

{
    $trace->format='y%3fx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
yt00...x
yt/0...x
EOF

    is $res, $exp, '%3s';
}

{
    $trace->format='y%-3fx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y....pmx
y...f.tx
EOF

    is $res, $exp, '%-3s';
}

{
    $trace->format='y%[basename]fx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
yt004_l2.pmx
y004-percent_f.tx
EOF

    is $res, $exp, '%[basename]s';
}

{
    $trace->format='y%[skip_prefix=t004, skip_prefix=t/004-]fx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y_l2.pmx
ypercent_f.tx
EOF

    is $res, $exp, '%[skip_prefix=t/t004, skip_prefix=004-]s';
}

{
    $trace->format='y%[skip_prefix=t004, basename, skip_prefix=t/004-]fx';
    l2; my $ln=__LINE__;

    my $exp=<<'EOF'; chomp $exp;
y_l2.pmx
y004-percent_f.tx
EOF

    is $res, $exp, '%[skip_prefix=t/t004, basename, skip_prefix=004-]s';
}

done_testing;
