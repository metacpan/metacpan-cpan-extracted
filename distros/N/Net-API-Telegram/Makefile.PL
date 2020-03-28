use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Net::API::Telegram',
    VERSION_FROM        => 'lib/Net/API/Telegram.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT            => 'Implementation of Telegram API',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'Test::Simple' 		=> 0.44,
        'strict'			=> 0,
        'parent'			=> 0,
        'constant'			=> 0,
        'Module::Generic'	=> '0.11.6',
        'HTTP::Daemon'		=> '6.06',
        'HTTP::Daemon::SSL'	=> '1.04',
        'File::Temp'		=> '0.2309',
        'File::Spec'		=> '3.78',
        'File::Basename'	=> '2.85',
        'IO::File'			=> '1.41',
        'Data::UUID'		=> '1.224',
        'JSON'				=> '4.02',
        'Encode'			=> '3.01',
        'TryCatch'			=> '1.003002',
        'File::Map'			=> '0.66',
        'Class::Struct'		=> '0.65',
        'Devel::StackTrace'	=> '2.04',
        'Time::HiRes'		=> '1.9760',
        'DateTime'			=> '1.51',
        'DateTime::TimeZone' => '2.36',
        'POSIX'				=> '1.88',
        'Net::IP'			=> '1.26',
        'Errno'				=> '1.30',
        'LWP::UserAgent'	=> '6.39',
        'HTTP::Headers'		=> '6.18',
        'HTTP::Request'		=> '6.18',
        'HTTP::Request::Common' => '6.18',
        'HTTP::Response'	=> '6.18',
        'Devel::Confess'	=> '0.009004',
        'Data::Dumper'		=> '2.174',
        'Scalar::Util'		=> '1.54',
        'File::Copy'		=> '2.34',
        'Cwd'				=> '3.78',
        'File::Type'		=> '0.22',
        'Number::Format'	=> '1.75',
        'HTTP::Status'		=> '6.18',
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 5.6.0,
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        #resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Net-API-Telegram.git',
                web         => 'https://git.deguest.jp/jack/Net-API-Telegram',
                type        => 'git',
            },
        #    bugtracker => {
        #        web         => undef,
        #    },
        #},
    })),
);

WriteMakefile(%WriteMakefileArgs);
