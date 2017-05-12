requires 'Class::Accessor::Lite';
requires 'Digest::MD5';
requires 'List::Util';
requires 'Scalar::Util';
requires 'Socket';
requires 'Time::HiRes';
requires 'parent';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'File::Which';
    requires 'Test::Builder::Module';
    requires 'Test::More', '0.98';
    requires 'Test::SharedFork';
    requires 'Test::TCP';
};
