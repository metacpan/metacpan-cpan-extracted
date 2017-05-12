use inc::Module::Install;

name		'Net-Sieve';
all_from	'lib/Net/Sieve.pm';

requires 'Authen::SASL' => '2.11';
requires 'IO::Socket::INET6';
requires 'IO::Socket::SSL';
requires 'MIME::Base64';

auto_install;

tests('t/*.t');

WriteAll;

