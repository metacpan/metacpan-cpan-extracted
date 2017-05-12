requires 'perl', '5.010001';

requires 'AnyEvent';
requires 'EV';
requires 'Export::Attrs';
requires 'List::Util', '1.33';
requires 'Scalar::Util';
requires 'Time::HiRes';
requires 'parent';
requires 'version', '0.77';

on configure => sub {
    requires 'Module::Build::Tiny', '0.039';
};

on test => sub {
    requires 'JSON::XS';
    requires 'Test::Exception';
    requires 'Test::Mock::Time', 'v0.1.5';
    requires 'Test::More', '0.96';
    recommends 'Sub::Util', '1.40';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
