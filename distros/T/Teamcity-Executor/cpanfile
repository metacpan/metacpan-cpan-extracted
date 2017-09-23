requires 'perl', '5.020';

requires 'Moose';
requires 'autobox::Core';
requires 'HTTP::Tiny';
requires 'Cpanel::JSON::XS';
requires 'Future';
requires 'IO::Socket::SSL';
requires 'IO::Async::Loop';
requires 'IO::Async::Timer::Periodic';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Module::Build::Tiny';
    requires 'Version::Next';
    requires 'CPAN::Uploader';
};
