use inc::Module::Install;

name            'Net-Hiveminder';
all_from        'lib/Net/Hiveminder.pm';

requires        'DateTime';
requires        'Moose';
requires        'Net::Jifty' => '0.06';
requires        'Number::RecordLocator';

feature 'commandline tool' => (
    -default => 1,
    recommends('Term::Encoding'),
);

feature 'comment on tasks' => (
    -default => 1,
    recommends('Email::Simple'),
    recommends('Email::Simple::Creator'),
);


install_script "bin/hm";
install_script "bin/hm-$_"
    for qw/braindump create done sync todo/;

recursive_author_tests 'xt';

auto_install;
sign;
WriteAll;


