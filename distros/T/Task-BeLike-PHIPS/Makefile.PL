use inc::Module::Install;

name         'Task-BeLike-PHIPS';
abstract     'My favourite and frequently used modules';
author       'Mark Phillips <phips@cpan.org>';
version_from 'lib/Task/BeLike/PHIPS.pm';
license      'perl';
githubmeta;

requires 'perl'                         => '5.010001';

requires 'Modern::Perl';
requires 'Devel::NYTProf';
requires 'DDP';
requires 'Module::Install';
requires 'Perl::Tidy';
requires 'Perl::Critic';
requires 'Perl6::Export::Attrs';
requires 'ExtUtils::MakeMaker';
requires 'Module::Install::GithubMeta';
requires 'Module::Starter::PBP';
requires 'App::FatPacker';

requires 'EV';
requires 'AnyEvent';

requires 'IO::Socket::SSL';
requires 'Mojolicious'                  => 4;
requires 'Plack';
requires 'WWW::Mechanize';
requires 'WWW::RobotRules';
requires 'WWW::UserAgent::Random';
requires 'LWP';
requires 'LWP::Protocol::https';
requires 'WebService::Amazon::Route53';

requires 'Term::ReadKey';
requires 'Term::ReadLine::Gnu';
requires 'Daemon::Control';
requires 'Proc::Daemon';
requires 'App::Ack';

requires 'YAML::XS';
requires 'PDL';
requires 'Time::Duration';

requires 'App::cpanoutdated';
requires 'Pod::Cpandoc';
requires 'Test::Pod';

requires 'DBIx::Connector';

WriteAll;
