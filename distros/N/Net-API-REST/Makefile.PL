use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Net::API::REST',
    VERSION_FROM        => 'lib/Net/API/REST.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT            => 'Implementation of RESTful API',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'common::sense'	=> 0,
        'curry'			=> '1.001000',
        'parent'		=> 0,
        'strict'		=> 0,
        'version'		=> 0,
		'Apache2::Connection'	=> 0,
		'Apache2::Const'		=> 0,
		'Apache2::Log'			=> 0,
		'Apache2::Reload'		=> 0,
		'Apache2::Request'		=> 0,
		'Apache2::RequestIO'	=> 0,
		'Apache2::RequestRec'	=> 0,
		'Apache2::RequestUtil'	=> 0,
		'Apache2::Response'		=> 0,
		'Apache2::ServerUtil'	=> 0,
		'Apache2::SubRequest'	=> 0,
		'APR::Base64'			=> 0,
		'APR::Pool'				=> 0,
		'APR::Request::Apache2'	=> 0,
		'APR::Request::Cookie'	=> 0,
		'APR::Socket'			=> 0,
		'APR::UUID'				=> 0,
		'Compress::Raw::Zlib'	=> '2.091',
		'Cookie::Baker'			=> 0,
		'Crypt::AuthEnc::GCM'	=> '0.064',
		'Crypt::KeyWrap'		=> '0.024',
		'Crypt::Mac::HMAC'		=> '0.064',
		'Crypt::Misc'			=> '0.064',
		'Crypt::PK::RSA'		=> '0.064',
		'Crypt::PK::ECC'		=> '0.064',
		'Crypt::PRNG'			=> '0.064',
		'DateTime'				=> 0,
		'Devel::Confess'		=> 0,
        'Encode'		        => '3.01',
		'HTTP::AcceptLanguage'	=> '0.02',
		'IO::File'				=> 0,
		'JSON'					=> 0,
		'MIME::Base64'			=> '3.15',
        'Module::Generic'       => 'v0.29.3',
		'Nice::Try'				=> 'v1.3.1',
		'Regexp::Common'		=> 0,
		'Scalar::Util'			=> 0,
		'URI'					=> 0,
		'URI::Escape'			=> '3.31',
		'URI::Query'			=> '0.16',
    },
    TEST_REQUIRES =>
    {
        'lib'                   => 0,
		'Test::Mock::Apache2'	=> '0.05',
		'Test::MockObject'		=> '1.20180705',
		'Test::More'            => 0,
		'Test::Pod'             => 0,
		'utf8'                  => 0,
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 5.6.0,
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'Net-API-REST-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Net-API-REST.git',
                web         => 'https://gitlab.com/jackdeguest/Net-API-REST',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Net-API-REST/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
