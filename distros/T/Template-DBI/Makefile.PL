# -*- perl -*-

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile1(
                MIN_PERL_VERSION => '5.008',
                META_MERGE       => {
                                resources => {
                                               repository  => 'svn://svn.tt2.org/tt/Template-DBI/trunk/',
                                               MailingList => 'mailto:templates@template-toolkit.org',
                                               license     => 'http://dev.perl.org/licenses/',
                                             },
                                recommends => {
                                                'threads::variable::reap' => 0.05,
                                                'SQL::Statement'          => 1.28,
                                                'MLDBM'                   => 0,
                                              },
                              },
                NAME         => 'Template::DBI',
                VERSION_FROM => 'lib/Template/Plugin/DBI.pm',
                ABSTRACT     => 'Template interface to the DBI module',
                dist         => {
                          'SUFFIX'       => ".gz",
                          'DIST_DEFAULT' => 'manifest tardist',
                          'COMPRESS'     => "gzip -9vf"
                        },
                PREREQ_PM => {
                               'Template' => 2.22,
                               'DBI'      => 1.612,
                             },
                LICENSE        => 'perl',
                BUILD_REQUIRES => {
                                    'SQL::Statement' => 1.28,
                                    'MLDBM'          => 0,
                                  },
                AUTHOR => 'Andy Wardley <abw@wardley.org>, Jens Rehsack <rehsack@cpan.org>',
              );

my $conflictMsg = <<EOCM;
***
    This version of Template::DBI conflicts with the version of
    module %s (%s) you have installed.

    It's strongly recommended that you update it after
    installing this version of Template::DBI.
***
EOCM

sub CheckConflicts
{
    my %params    = @_;
    my %conflicts = %{ $params{CONFLICTS} };
    my $found     = 0;

    while ( my ( $module, $version ) = each(%conflicts) )
    {
        undef $@;
        eval "require $module";
        next if $@;
        my $installed = eval "\$" . $module . "::VERSION";
        if ( $installed le $version )
        {
            ++$found;
            my $warning = sprintf( $conflictMsg, $module, $installed );
            warn $warning;
        }
    }

    return !$found;
}

sub WriteMakefile1
{    #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if ( exists( $params{EXTRA_META} ) );
    die "License not specified"    if ( !exists( $params{LICENSE} ) );
    if ( $params{BUILD_REQUIRES} and ( $eumm_version < 6.5503 ) )
    {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if ( $eumm_version < 6.52 );
    delete $params{MIN_PERL_VERSION}   if ( $eumm_version < 6.48 );
    delete $params{META_MERGE}         if ( $eumm_version < 6.46 );
    delete $params{META_ADD}           if ( $eumm_version < 6.46 );
    delete $params{LICENSE}            if ( $eumm_version < 6.31 );
    delete $params{AUTHOR}             if ( $] < 5.005 );
    delete $params{ABSTRACT_FROM}      if ( $] < 5.005 );
    delete $params{BINARY_LOCATION}    if ( $] < 5.005 );

    # more or less taken from Moose' Makefile.PL
    if ( $params{CONFLICTS} )
    {
        my $ok = CheckConflicts(%params);
        exit(0) if ( $params{PREREQ_FATAL} and not $ok );
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ } keys %ENV;
        unless ( $cpan_smoker || $ENV{PERL_MM_USE_DEFAULT} )
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}
