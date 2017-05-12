requires 'perl', '5.008001';

on 'build' => sub {
    requires 'ExtUtils::ParseXS';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Warn';
};

on 'develop' => sub {
    recommends 'Devel::LeakTrace';
};
