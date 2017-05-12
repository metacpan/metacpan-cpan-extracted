use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::OAuth2::Moosey::Client',
    AUTHOR              => q{Robin Clarke <robin@robinclarke.net>},
    VERSION_FROM        => 'lib/Net/OAuth2/Moosey/Client.pm',
    ABSTRACT_FROM       => 'lib/Net/OAuth2/Moosey/Client.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'HTTP::Message'			=> 0, # Includes HTTP::Request::..
	'JSON'				=> 0,
	'LWP::UserAgent'		=> 0,
	'Moose'				=> 0,
	'MooseX::Log::Log4perl'		=> 0,
	'MooseX::Types::URI'		=> 0,
	'Test::Mock::LWP::Dispatch'	=> 0,
	'Test::More'			=> 0,
	'Test::NoWarnings'		=> 0,
	'URI'				=> 0,
	'URI::Escape'			=> 0,
	'YAML'				=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-OAuth2-*' },
);
