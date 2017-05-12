use inc::Module::Install;

name 'POE-Component-Server-SimpleHTTP-PreFork';
author 'Apocalypse <APOCAL@cpan.org>';
license 'perl';
auto_license holder => 'Apocalypse, Chris Williams, Eriam Schaffter, Marlon Bailey and Philip Gwyn';
perl_version '5.006';
version_from 'lib/POE/Component/Server/SimpleHTTP/PreFork.pm';
abstract_from 'lib/POE/Component/Server/SimpleHTTP/PreFork.pm';
readme_from 'lib/POE/Component/Server/SimpleHTTP/PreFork.pm';

requires    'HTTP::Date'                         =>    0;
requires    'Carp'                               =>    0;
requires    'Sys::Hostname'                      =>    0;
requires    'POE'                                =>    '1.0000';
requires    'Storable'                           =>    0;
requires    'Socket'                             =>    0;
requires    'HTTP::Request'                      =>    0;
requires    'HTTP::Response'                     =>    0;
requires    'Moose'	                             =>    0.90;
requires    'MooseX::POE'                        =>    0.205;

requires    'POE::Component::Server::SimpleHTTP' =>    2.04;
requires    'IPC::Shareable'                     =>    0;

build_requires   'Test::More'                    =>    0.47;
build_requires	 'POE::Filter::HTTP::Parser'	   =>    1.06;
build_requires	 'Test::POE::Client::TCP'	       =>    0.10;
build_requires   'POE::Component::Client::HTTP'  =>    0.82;

auto_provides;
githubmeta;

# Thanks to Matt Trout for this tip
makemaker_args(dist => { PREOP => "$^X tools/git-log.pl > ./Changes" });

WriteAll();
