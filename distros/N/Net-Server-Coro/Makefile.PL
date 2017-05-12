use inc::Module::Install;

name ('Net-Server-Coro');
author ('Alex Vandiver <alexmv@bestpractical.com>');
version_from ('lib/Net/Server/Coro.pm');
abstract_from('lib/Net/Server/Coro.pm');
license('MIT');

requires('Coro');
requires('AnyEvent');
requires('Net::Server' => 2.000);

recommends('Net::SSLeay');

sign;

&WriteAll;
