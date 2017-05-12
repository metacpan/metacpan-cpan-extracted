use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Lujoyglamour',
    AUTHOR              => 'JJ Merelo <jj@merelo.net>',
    VERSION_FROM        => 'lib/Net/Lujoyglamour.pm',
    ABSTRACT_FROM       => 'lib/Net/Lujoyglamour.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
	'String::Random' => 0,
	'Regexp::Common' => 0,
	'CGI::Application' => 0,
	'DBIx::Class::Schema' => 0,
	'Exporter' => 0,
	'CGI::Application::Plugin::DBH' => 0,
	'CGI::Application::Plugin::DBIx::Class' => 0,
	'CGI::Application::Plugin::Redirect' => 0,
	'Test::WWW::Mechanize::CGIApp' => 0,
	'JSON' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Lujoyglamour-*' },
);
