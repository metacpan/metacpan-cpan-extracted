use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::distsignature
{
    return <<'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

WriteMakefile(
    NAME                => 'Net::API::Stripe',
    AUTHOR              => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM        => 'lib/Net/API/Stripe.pm',
    ABSTRACT            => 'An interface to the Stripe API',
    PL_FILES            => {},
    PREREQ_PM           => {
        'common::sense' => 0,
        'constant'      => 0,
        'overload'      => 0,
        'parent'        => 0,
        'strict'        => 0,
        'vars'          => 0,
        'warnings'      => 0,
        'Data::Random'  => '0.13',
        'Data::UUID'    => '1.224',
        'DateTime'      => '1.51',
        'DateTime::Format::Strptime' => '1.76',
        'DateTime::TimeZone' => '2.36',
        'Devel::Confess' => '0.009004',
        'Digest::MD5'   => '2.55',
        'Digest::SHA'   => '6.02',
        'Encode'        => '3.01',
        'HTTP::Promise' => 'v0.3.1',
        'JSON'          => '4.02',
        'MIME::Base64'  => '3.15',
        'MIME::QuotedPrint' => '3.13',
        'Module::Generic'=> 'v0.32.5',
        'Net::IP'       => '1.26',
        'Nice::Try'     => 'v1.3.5',
        'Regexp::Common' => '2017060201',
        'Scalar::Util'  => '1.54',
        'URI::Escape'   => '3.31',
        'Want'          => '0.29',
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.6.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Net-API-Stripe-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url     => 'git@gitlab.com:jackdeguest/Net-API-Stripe.git',
                web     => 'https://gitlab.com/jackdeguest/Net-API-Stripe',
                type    => 'git',
            },
            bugtracker => {
                # web         => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-API-Stripe',
                web     => 'https://gitlab.com/jackdeguest/Net-API-Stripe/issues',
                mailto  => 'cpan-bug@deguest.jp',
            },
        },
    }) : ()),
);
