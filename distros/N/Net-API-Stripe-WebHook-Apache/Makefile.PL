use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Net::API::Stripe::WebHook::Apache',
    VERSION_FROM        => 'lib/Net/API/Stripe/WebHook/Apache.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT            => 'A Stripe WebHook Implementation using Apache',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'constant'				=> 0,
        'parent'				=> 0,
        'strict'			    => 0,
        'Apache2::Const'        => '2.000010',
        'Devel::Confess'		=> '0.009004',
        'Net::API::REST'		=> '0.5.3',
        'Net::API::Stripe'      => 'v1.0.5',
        'Nice::Try'				=> 'v0.1.4',
    },
    TEST_REQUIRES =>
    {
		'Test::Mock::Apache2'	=> '0.05',
		'Test::More'            => 0,
		'Test::Pod'	            => 0,
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 5.6.0,
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Net-API-Stripe-WebHook-Apache.git',
                web         => 'https://git.deguest.jp/jack/Net-API-Stripe-WebHook-Apache',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-API-Stripe-WebHook-Apache',
                mailto		=> 'cpan-bug@deguest.jp',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
