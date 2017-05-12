use if ! ( grep { $_ eq '.' } @INC ), qw[lib .];
use strict;
use inc::Module::Install;
print <<NOTICE;

\a--------------------------------------------------------------------------------
The hybrid part of this module has never really worked properly and has now been
superseded by POE::Component::Server::IRC.

The P10 part will eventually be supported by POE::Component::Server::IRC.

I am not actively supporting this module, so be warned.

have a nice day >:)
---------------------------------------------------------------------------------

NOTICE

name 'POE-Component-IRC-Service';
license 'perl';
author 'Chris Williams <chris@bingosnet.co.uk>';
auto_license holder => 'Chris Williams';
abstract 'A fully event driven IRC Services module';
version_from 'lib/POE/Component/IRC/Service.pm';
build_requires 'Test::More' => 0.47;
requires 'POE'    => 0.06_07;
auto_provides;
githubmeta;
WriteAll();
