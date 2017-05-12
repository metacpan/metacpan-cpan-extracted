requires 'Crypt::JWT' => '>= 0.018';
requires 'IO::Socket::SSL' => '>= 2.038';
requires 'JSON';
requires 'Moo';
requires 'Protocol::HTTP2' => '>= 1.08';
requires 'URI';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'File::Basename';
    requires 'File::Spec';
};
