# -*- perl -*-

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $conflictMsg = <<EOCM;
***
    This version of SQL::Statement conflicts with
    the version of module %s (%s) you have installed.

    It's strongly recommended that you update it after
    installing this version of SQL::Statement.
***
EOCM

my $selfConflictMsg = <<EOSCM;
***
    This version of SQL::Statement conflicts with
    the version of %s (%s) you have installed.

    It's strongly recommended that you carefully read
    the Changes file and test your application with
    this version before finally upgrading.

    See local::lib how to do it easily.
***
EOSCM

my %RUN_DEPS = (
    'Carp'            => 0,
    'Clone'           => '0.30',
    'Data::Dumper'    => 0,
    'Module::Runtime' => 0,
    'Params::Util'    => '1.00',
    'Scalar::Util'    => '1.0',
    'Text::Balanced'  => 0,
);
my %CONFIGURE_DEPS = (
    'ExtUtils::MakeMaker' => 0,
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Math::Complex'       => '1.56',
    'Math::Base::Convert' => 0,
    'Test::Deep'          => 0,
    'Test::More'          => '0.90',
    'Text::Soundex'       => '3.04',
);
my %CONFLICTS = (
    'SQL::Statement' => '1.20',
    'DBI'            => '1.611',
    'DBD::AnyData'   => '0.09',
    'DBD::CSV'       => '0.29',
);

WriteMakefile1(
    MIN_PERL_VERSION => '5.008',
    META_MERGE       => {
        'meta-spec' => {version => 2},
        resources   => {
            homepage      => 'https://metacpan.org/release/SQL-Statement',
            x_IRC         => "irc://irc.perl.org/#dbi",
            x_MailingList => "mailto:dbi-dev\@perl.org'",
            repository    => {
                url  => 'https://github.com/perl5-dbi/SQL-Statement.git',
                web  => 'https://github.com/perl5-dbi/SQL-Statement',
                type => 'git',
            },
            bugtracker => {
                web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Statement',
                mailto => 'sql-statement@rt.cpan.org',
            },
            license => 'http://dev.perl.org/licenses/',
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::CPAN::Changes'                 => 0,
                    'Test::CheckManifest'                 => 0,
                    'Module::CPANTS::Analyse'             => '0.96',
                    'Test::Kwalitee'                      => 0,
                    'Test::Pod'                           => 0,
                    'Test::Pod::Coverage'                 => 0,
                    'Test::Pod::Spelling::CommonMistakes' => 0,
                    'Test::Spelling'                      => 0,
                },
            },
            configure => {
                requires => {%CONFIGURE_DEPS},
            },
            build => {
                requires => {%BUILD_DEPS},
            },
            test => {
                requires  => {%TEST_DEPS},
                conflicts => {%CONFLICTS},
            },
            runtime => {
                recommends => {
                    'Math::Complex'       => '1.56',
                    'Text::Soundex'       => '3.04',
                    'Math::Base::Convert' => 0,
                },
                requires  => {%RUN_DEPS},
                conflicts => {%CONFLICTS},
            },
        },
    },
    NAME          => 'SQL::Statement',
    VERSION_FROM  => 'lib/SQL/Statement.pm',
    ABSTRACT_FROM => 'lib/SQL/Statement.pm',
    dist          => {
        'SUFFIX'       => ".gz",
        'DIST_DEFAULT' => 'manifest tardist',
        'COMPRESS'     => "gzip -9vf"
    },
    CONFLICTS      => \%CONFLICTS,
    PREREQ_PM      => \%RUN_DEPS,
    BUILD_REQUIRES => \%BUILD_DEPS,
    TEST_REQUIRES  => \%TEST_DEPS,
    LICENSE        => 'perl',
    AUTHOR         => 'Jeff Zucker <jeff@vpservices.com>, Jens Rehsack <rehsack@cpan.org>',
    test           => {TESTS => 't/*.t xt/*.t'},
);

sub CheckConflicts
{
    my %params    = @_;
    my %conflicts = %{$params{CONFLICTS}};
    my $found     = 0;

    while (my ($module, $version) = each(%conflicts))
    {
        undef $@;
        eval "require $module";
        next if $@;
        my $installed = eval "\$" . $module . "::VERSION";
        if ($installed le $version)
        {
            ++$found;
            my $msg     = $module eq $params{NAME} ? $selfConflictMsg : $conflictMsg;
            my $warning = sprintf($msg, $module, $installed);
            warn $warning;
        }
    }

    return !$found;
}

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

    # more or less taken from Moose' Makefile.PL
    if ($params{CONFLICTS})
    {
        my $ok = CheckConflicts(%params);
        exit(0) if ($params{PREREQ_FATAL} and not $ok);
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ }
          keys %ENV;
        unless ($cpan_smoker
            || $ENV{PERL_MM_USE_DEFAULT}
            || $ENV{SQL_STATEMENT_WARN_UPDATE})
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}
