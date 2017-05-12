requires 'perl', '5.008001';

requires 'HTTP::Request';
requires 'Class::Tiny';
requires 'AWS::Signature4';
requires 'LWP::UserAgent';
requires 'Path::Tiny', '0.056';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Mock::Quick';
    requires 'Test::Exception';
    requires 'Test::Deep';
};

on 'develop' => sub {
    requires 'Module::Build::Tiny';
    requires 'Minilla';
    requires 'Version::Next';
};
