use inc::Module::Install;

name('Net-IMAP-Server');
author('Alex Vandiver <alexmv@bestpractical.com>');
perl_version_from('lib/Net/IMAP/Server.pm');
version_from('lib/Net/IMAP/Server.pm');
abstract_from('lib/Net/IMAP/Server.pm');
repository('http://github.com/bestpractical/net-imap-server/');
license('perl');
readme_from('lib/Net/IMAP/Server.pm');
sign;

requires('AnyEvent');
requires('Class::Accessor');
requires('Coro');
requires('DateTime');
requires('DateTime::Format::Mail');
requires('DateTime::Format::Strptime' => 1.3000);
requires('Email::Address');
requires('Email::MIME' => 1.862);
requires('Email::MIME::ContentType');
requires('Email::Simple' => 1.999);
requires('Encode::IMAPUTF7');
requires('MIME::Base64' => 3.11);
requires('Net::SSLeay');
requires('Net::Server::Coro' => 0.6);
requires('Regexp::Common');
requires('Test::More');
requires('UNIVERSAL::require');

test_requires('IO::Socket::SSL');

WriteAll;
