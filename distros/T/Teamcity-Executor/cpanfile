requires 'perl', '5.020';

requires 'Moose';
requires 'HTTP::Tiny';
requires 'Cpanel::JSON::XS';
requires 'Future';
requires 'IO::Socket::SSL';
requires 'IO::Async::Loop';
requires 'IO::Async::Timer::Periodic';
requires 'Try::Tiny::Retry';
requires 'Log::Any';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Module::Build::Tiny';
    requires 'Version::Next';
    requires 'CPAN::Uploader';
};
