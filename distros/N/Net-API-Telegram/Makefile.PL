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

my %WriteMakefileArgs = (
    NAME                => 'Net::API::Telegram',
    VERSION_FROM        => 'lib/Net/API/Telegram.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT            => 'Implementation of Telegram API',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'constant'			    => 0,
        'parent'			    => 0,
        'strict'			    => 0,
        'Class::Struct'		    => '0.65',
        'Cwd'				    => '3.78',
        'Data::Dumper'		    => '2.174',
        'Data::UUID'		    => '1.224',
        'DateTime'			    => '1.51',
        'DateTime::TimeZone'    => '2.36',
        # 'Devel::Confess'	    => '0.009004',
        'Devel::StackTrace'	    => '2.04',
        'Encode'			    => '3.01',
        'Errno'				    => '1.30',
        'File::Basename'	    => '2.85',
        'File::Copy'		    => '2.34',
        'File::Map'			    => '0.66',
        'File::Temp'		    => '0.2309',
        'File::Spec'		    => '3.78',
        'File::Type'		    => '0.22',
        'HTTP::Daemon'		    => '6.06',
        'HTTP::Daemon::SSL'	    => '1.04',
        'HTTP::Headers'		    => '6.18',
        'HTTP::Request'		    => '6.18',
        'HTTP::Request::Common' => '6.18',
        'HTTP::Response'	    => '6.18',
        'HTTP::Status'		    => '6.18',
        'IO::File'			    => '1.41',
        'JSON'				    => '4.02',
        'LWP::UserAgent'	    => '6.39',
        'Module::Generic'       => 'v0.37.5',
        'Net::IP'			    => '1.26',
        # 'Nice::Try'			    => 'v0.1.3',
        'Number::Format'	    => '1.75',
        'POSIX'				    => '1.88',
        'Scalar::Util'		    => '1.54',
        'Time::HiRes'		    => '1.9760',
    },
    TEST_REQUIRES =>
    {
		'Test::More'    => 0,
		'Test::Pod'     => 0,
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 'v5.16.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Net-API-Telegram-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Net-API-Telegram.git',
                web         => 'https://gitlab.com/jackdeguest/Net-API-Telegram',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Net-API-Telegram/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
