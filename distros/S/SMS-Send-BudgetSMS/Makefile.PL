use strict;
use warnings;

use ExtUtils::MakeMaker;
use FindBin;

use lib "$FindBin::Bin/lib";

WriteMakefile(
    NAME            => 'SMS::Send::BudgetSMS',
    VERSION_FROM    => 'lib/SMS/Send/BudgetSMS.pm',
    AUTHOR          => 'Lari Taskula <lari.taskula@hypernova.fi>',
    ABSTRACT        => 'SMS::Send driver for BudgetSMS',
    PREREQ_PM       => {
        "Number::Phone::Normalize" => "0.220",
        "LWP::UserAgent"           => "5.837",
        "SMS::Send"                => "1.06",
    },
    TEST_REQUIRES   => {
        "Test::More"          => "0.88",
    },
    META_MERGE      => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/Hypernova-Oy/SMS-Send-BudgetSMS/issues'
            },
            homepage => 'https://github.com/Hypernova-Oy/SMS-Send-BudgetSMS',
            repository => {
                type => 'git',
                url  => 'https://github.com/Hypernova-Oy/SMS-Send-BudgetSMS.git',
                web  => 'https://github.com/Hypernova-Oy/SMS-Send-BudgetSMS',
            },
        },
    },
    test => { TESTS => 't/*.t' },
);
