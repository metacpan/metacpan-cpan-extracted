requires 'parent';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Scalar::Util';
    requires 'Test::More', '0.98';
    requires 'Test::Requires';

    recommends 'JSON::PP';
};
