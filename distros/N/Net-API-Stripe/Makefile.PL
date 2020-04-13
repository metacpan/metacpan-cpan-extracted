use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Net::API::Stripe',
    VERSION_FROM        => 'lib/Net/API/Stripe.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT            => 'An interface to the Stripe API',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'Test::Simple' => 0,
        'Test::Pod'	=> 0,
        'common::sense'			=> 0,
        'parent'				=> 0,
        'constant'				=> 0,
        'overload'				=> '1.30',
        'Module::Generic'		=> '0.11.6',
        'Encode'				=> '3.01',
        'IO::File'				=> '1.41',
        'Data::UUID'			=> '1.224',
        'Net::OAuth'			=> '0.28',
        'Crypt::OpenSSL::RSA'	=> '0.31',
        'Digest::MD5'			=> '2.55',
        'Data::Random'			=> '0.13',
        'HTTP::Cookies'			=> '6.04',
        'HTTP::Request'			=> '6.18',
        'LWP::UserAgent'		=> '6.39',
        'MIME::QuotedPrint'		=> '3.13',
        'MIME::Base64'			=> '3.15',
        'LWP::MediaTypes'		=> '6.04',
        'JSON'					=> '4.02',
        'Scalar::Util'			=> '1.54',
        'Data::Dumper'			=> '2.174',
        'URI::Query'			=> '0.16',
        'URI::Escape'			=> '3.31',
        'File::Basename'		=> '2.85',
        'File::Spec'			=> '3.78',
        'Cwd'					=> '3.78',
        'DateTime'				=> '1.51',
        'DateTime::TimeZone'	=> '2.36',
        'DateTime::Format::Strptime' => '1.76',
        'TryCatch'				=> '1.003002',
        'Want'					=> '0.29',
        'Digest::SHA'			=> '6.02',
        'Net::IP'				=> '1.26',
        'Devel::Confess'		=> '0.009004',
        'Number::Format'		=> '1.75',
        'Net::API::REST'		=> '0.5.3',
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 5.6.0,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-API-Stripe-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Net-API-Stripe.git',
                web         => 'https://git.deguest.jp/jack/Net-API-Stripe',
                type        => 'git',
            },
        #    bugtracker => {
        #        web         => undef,
        #    },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
