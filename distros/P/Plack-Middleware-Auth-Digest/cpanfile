requires 'Digest::HMAC_SHA1';
requires 'Digest::MD5';
requires 'MIME::Base64';
requires 'Plack::Middleware';
requires 'Plack::Util::Accessor';
requires 'Test::Builder::Module';
requires 'parent';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.039';
};

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'LWP::UserAgent';
    requires 'Plack::Builder';
    requires 'Plack::Test';
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
