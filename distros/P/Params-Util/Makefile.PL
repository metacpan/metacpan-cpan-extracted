#!perl

use strict;
use warnings;

use 5.008;

BEGIN
{
    unless (grep { $_ eq "." } @INC)
    {
        use lib ".";
    }
}

use inc::latest 'Capture::Tiny';
use inc::latest 'Config::AutoConf';

unless (-f "META.yml")
{
    if (inc::latest->can("write"))
    {
        inc::latest->write("inc");
        for my $mod (inc::latest->loaded_modules)
        {
            inc::latest->bundle_module($mod, "inc");
        }
    }
    eval <<EOEC;
use Devel::PPPort;
Devel::PPPort::WriteFile("ppport.h");
EOEC
}

use ExtUtils::MakeMaker;

use lib 'inc';
use Config::AutoConf::ParamsUtil ();

Config::AutoConf::ParamsUtil->_set_argv(@ARGV);    # XXX hack because we cannot construct for global use
my $loadable_xs = Config::AutoConf::ParamsUtil->check_paramsutil_prerequisites();

# Should we build the XS version?
my %RUN_DEPS = (
    'Scalar::Util' => $loadable_xs ? '1.18' : '1.10',
    'XSLoader'     => "0.22",
);
my %BUNDLE_CONFIGURE_DEPS = (
    'inc::latest'      => '0.500',
    'Config::AutoConf' => '0.315',
);
my %CONFIGURE_DEPS = (
    'Carp'                => 0,
    'ExtUtils::MakeMaker' => 0,
    'File::Basename'      => 0,
    'File::Copy'          => 0,
    'File::Path'          => 0,
    'File::Spec'          => 0,
    'IPC::Cmd'            => 0,
    'parent'              => 0,
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Storable'   => 0,
    'Test::More' => 0.96,
);
my @XS_FILES = ($loadable_xs ? qw(Util.xs) : ());

WriteMakefile1(
    META_MERGE => {
        'meta-spec' => {version => 2},
        resources   => {
            homepage   => 'https://metacpan.org/release/Params-Util',
            repository => {
                url  => 'https://github.com/perl5-utils/Params-Util.git',
                web  => 'https://github.com/perl5-utils/Params-Util',
                type => 'git',
            },
            bugtracker => {
                web    => 'https://rt.cpan.org/Dist/Display.html?Name=Params-Util',
                mailto => 'bug-Params-Util@rt.cpan.org',
            },
            license => 'perl',
        },
        prereqs => {
            develop => {
                requires => {
                    %BUNDLE_CONFIGURE_DEPS,
                    'Test::CPAN::Changes'                 => 0,
                    'Test::CheckManifest'                 => 0,
                    'Module::CPANTS::Analyse'             => '0.96',
                    'Test::Kwalitee'                      => 0,
                    'Test::Perl::Critic'                  => 0,
                    'Test::PerlTidy'                      => 0,
                    'Test::Pod'                           => 0,
                    'Test::Pod::Coverage'                 => 0,
                    'Test::Pod::Spelling::CommonMistakes' => 0,
                    'Test::Spelling'                      => 0,
                },
            },
            configure => {
                requires   => {%CONFIGURE_DEPS},
                recommends => {'Config::AutoConf' => '0.315'}
            },
            test => {
                requires => {%TEST_DEPS},
                requires => {'Test::LeakTrace' => 0}
            },
            runtime => {requires => {%RUN_DEPS}},
        },
    },
    NAME               => 'Params::Util',
    ABSTRACT           => 'Simple, compact and correct param-checking functions',
    VERSION_FROM       => 'lib/Params/Util.pm',
    AUTHOR             => ['Adam Kennedy <adamk@cpan.org>', 'Jens Rehsack <rehsack@cpan.org>'],
    LICENSE            => 'perl',
    CONFIGURE_REQUIRES => \%CONFIGURE_DEPS,
    PREREQ_PM          => \%RUN_DEPS,
    TEST_REQUIRES      => \%TEST_DEPS,
    XS                 => {map { (my $tgt = $_) =~ s/\.xs$/\.c/; $_ => $tgt; } @XS_FILES},
    MAGICXS            => 1,
    depend             => {'$(FIRST_MAKEFILE)' => '$(VERSION_FROM)'},
    test               => {TESTS               => join(' ', 't/pp/*.t', ($loadable_xs ? 't/xs/*.t' : ()), 'xt/*.t')},
    # Otherwise 'cxinc' isn't defined
    ($] < 5.012 ? (DEFINE => '-DPERL_EXT') : (),),
);

sub WriteMakefile1
{    # originally written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if (exists($params{EXTRA_META}));
    die "License not specified"    if (!exists($params{LICENSE}));
    $params{TEST_REQUIRES}
      and $eumm_version < 6.6303
      and $params{BUILD_REQUIRES} = {%{$params{BUILD_REQUIRES} || {}}, %{delete $params{TEST_REQUIRES}}};
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{BUILD_REQUIRES}
      and $eumm_version < 6.5503
      and $params{PREREQ_PM} = {%{$params{PREREQ_PM} || {}}, %{delete $params{BUILD_REQUIRES}}};
    ref $params{AUTHOR}
      and "ARRAY" eq ref $params{AUTHOR}
      and $eumm_version < 6.5702
      and $params{AUTHOR} = join(", ", @{$params{AUTHOR}});
    delete $params{CONFIGURE_REQUIRES}    if ($eumm_version < 6.52);
    delete $params{MIN_PERL_VERSION}      if ($eumm_version < 6.48);
    delete $params{META_MERGE}            if ($eumm_version < 6.46);
    delete $params{META_ADD}{prereqs}     if ($eumm_version < 6.58);
    delete $params{META_ADD}{'meta-spec'} if ($eumm_version < 6.58);
    delete $params{META_ADD}              if ($eumm_version < 6.46);
    delete $params{LICENSE}               if ($eumm_version < 6.31);
    delete $params{AUTHOR}                if ($] < 5.005);
    delete $params{ABSTRACT_FROM}         if ($] < 5.005);
    delete $params{BINARY_LOCATION}       if ($] < 5.005);

    # more or less taken from SQL::Statement's Makefile.PL
    if ($params{CONFLICTS})
    {
        my $ok          = 1;
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ } keys %ENV;
        unless ($cpan_smoker || $ENV{PERL_MM_USE_DEFAULT})
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}
# my @clean = (
# 	# 'test.c',
# 	'*.old'
# );
# if ( $make_xs ) {
# 	push @clean, @tests;
# }
#
# WriteMakefile(
# 	# We created our own META.yml
# 	# NO_META            => 1,
# 	NAME               => 'Params::Util',
# 	ABSTRACT           => 'Simple, compact and correct param-checking functions',
# 	VERSION_FROM       => 'lib/Params/Util.pm',
# 	AUTHOR             => 'Adam Kennedy <adamk@cpan.org>',
# 	LICENSE            => 'perl',
# 	DEFINE             => '-DPERL_EXT',
# 	MIN_PERL_VERSION   => '5.00503',
# 	CONFIGURE_REQUIRES => {
# 		'ExtUtils::MakeMaker' => '6.52',
# 		'ExtUtils::CBuilder'  => '0.27',
# 	},
# 	PREREQ_PM => {
# 		'Scalar::Util' => $make_xs ? '1.18' : '1.10',
# 	},
# 	BUILD_REQUIRES => {
# 		'ExtUtils::MakeMaker' => '6.52',
# 		'Test::More'          => '0.42',
# 		'File::Spec'          => '0.80',
# 	},
#
# 	# Special stuff
# 	CONFIGURE     => sub {
# 		my $hash = $_[1];
# 		unless ( $make_xs ) {
# 			$hash->{XS} = {};
# 			$hash->{C}  = [];
# 		}
# 		return $hash;
# 	},
# 	clean => {
# 		FILES => join( ' ', @clean ),
# 	},
# );
