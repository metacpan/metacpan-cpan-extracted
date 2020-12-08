#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2015, 2020 Steve Hay.  All rights reserved.
#
# LICENCE
#   This script is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Config qw(%Config);
use ExtUtils::MakeMaker 6.64;
use ExtUtils::MakeMaker qw(WriteMakefile);

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    unless ($Config{useperlio}) {
        die "OS unsupported: This module requires a perlio-enabled perl.\n";
    }
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    WriteMakefile(
        NAME          => 'PerlIO::via::QuotedPrint',
        ABSTRACT_FROM => 'lib/PerlIO/via/QuotedPrint.pm',
        AUTHOR        => 'Elizabeth Mattijsen <liz@dijkmat.nl>, Steve Hay <shay@cpan.org>',
        LICENSE       => 'perl_5',
        VERSION_FROM  => 'lib/PerlIO/via/QuotedPrint.pm',

        META_MERGE => {
            'meta-spec' => {
                version => 2
            },

            resources => {
                repository => {
                    type => 'git',
                    web  => 'https://github.com/steve-m-hay/PerlIO-via-QuotedPrint'
                }
            },

            optional_features => {
                changestest => {
                    description => 'Changes testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::CPAN::Changes' => '0'
                            }
                        }
                    }
                },

                critictest => {
                    description => 'Perl::Critic testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Perl::Critic' => '0'
                            }
                        }
                    }
                },

                podtest => {
                    description => 'POD testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Pod' => '1.00'
                            }
                        }
                    }
                },

                podcoveragetest => {
                    description => 'POD coverage testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Pod::Coverage' => '0.08'
                            }
                        }
                    }
                }
            }
        },

        MIN_PERL_VERSION => '5.008001',

        CONFIGURE_REQUIRES => {
            'Config'              => '0',
            'ExtUtils::MakeMaker' => '6.64',
            'perl'                => '5.008001',
            'strict'              => '0',
            'warnings'            => '0'
        },

        TEST_REQUIRES => {
            'Test::More' => '0'
        },

        PREREQ_PM => {
            'MIME::QuotedPrint' => '0',
            'strict'            => '0'
        },

        INSTALLDIRS => ($] < 5.011 ? 'perl' : 'site'),

        dist => {
            PREOP   => 'find $(DISTVNAME) -type d -print|xargs chmod 0755 && ' .
                       'find $(DISTVNAME) -type f -print|xargs chmod 0644',
            TO_UNIX => 'find $(DISTVNAME) -type f -print|xargs dos2unix'
        }
    );
}

#===============================================================================
