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
        'common::sense'			=> 0,
        'constant'				=> 0,
        'overload'				=> '1.26',
        'parent'				=> 0,
        'Crypt::OpenSSL::RSA'	=> '0.31',
        'Cwd'					=> '3.75',
        'Data::Dumper'			=> '2.173',
        'Data::Random'			=> '0.13',
        'Data::UUID'			=> '1.224',
        'DateTime'				=> '1.51',
        'DateTime::Format::Strptime' => '1.76',
        'DateTime::TimeZone'	=> '2.36',
        'Devel::Confess'		=> '0.009004',
        'Digest::MD5'			=> '2.55',
        'Digest::SHA'			=> '6.02',
        'Encode'				=> '3.01',
        'File::Basename'		=> '2.85',
        'File::Spec'			=> '3.75',
        'HTTP::Cookies'			=> '6.04',
        'HTTP::Request'			=> '6.18',
        'IO::File'				=> '1.41',
        'JSON'					=> '4.02',
        'LWP::MediaTypes'		=> '6.04',
        'LWP::UserAgent'		=> '6.39',
        'MIME::Base64'			=> '3.15',
        'MIME::QuotedPrint'		=> '3.13',
        'Module::Generic'       => 'v0.12.13',
        'Net::IP'				=> '1.26',
        'Net::OAuth'			=> '0.28',
        'Nice::Try'				=> 'v0.1.4',
        'Scalar::Util'			=> '1.54',
        'URI::Escape'			=> '3.31',
        'URI::Query'			=> '0.16',
        'Want'					=> '0.29',
    },
    TEST_REQUIRES =>
    {
		'Test::More' => 0,
		'Test::Pod'	=> 0,
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
            bugtracker => {
                web         => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-API-Stripe',
                # web			=> 'https://git.deguest.jp/jack/Net-API-Stripe/issues',
                mailto		=> 'cpan-bug@deguest.jp',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
