#!/usr/bin/env perl

use 5.020;
use strict;
use warnings FATAL => 'all';
use constant {
    TRUE  => 1,
    FALSE => 0,
};

# These should be in Perl's installation already
use Config;
use ExtUtils::MakeMaker;
use Term::ReadKey;
use Term::ANSIColor;

my $line = '-' x 33 . ' ansi-encode ' . '-' x 33;
if (-e 'Makefile') {
    `make veryclean;reset`;
}

# ANSI Encode
my $banner = slurp_file('examples/banner.vt');
print $banner, colored(['green'], 'ok'), "\n";

WriteMakefile(
    NAME               => 'Term::ANSIEncode',
    AUTHOR             => q{Richard Kelsch <rich@rk-internet.com>},
    VERSION_FROM       => 'lib/Term/ANSIEncode.pm',
    ABSTRACT           => 'Markup Language for ANSI Encoding',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.020,                                      # 5.6 (5.006) is considered slow and unstable.  Upgrade
    CONFIGURE_REQUIRES => {
        'Config'              => '0',
        'ExtUtils::MakeMaker' => '6.00',
        'Term::ANSIColor'     => '0',
        'Term::ReadKey'       => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '1.00',
        'List::Util' => '1.20',
    },
    PREREQ_PRINT => TRUE,
    PREREW_FATAL => TRUE,
    PREREQ_PM    => {
        'charnames'         => '0',
        'List::Util'        => '1.20',
        'Term::ANSIColor'   => '0',
        'Term::ANSIScreen'  => '0',
        'Time::HiRes'       => '0',
        'Getopt::Long'      => '0',
        'Text::Wrap::Smart' => '0',
    },
    EXE_FILES => ['bin/ansi-encode'],
    dist      => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {
        FILES => '*gz *bak *old',
    },
);

print colored(['blue on_blue'],            $line),              "\n";
print colored(['bright_white on_magenta'], ' Building    -> '), colored(['bright_green'], '     make'), "\n";
print colored(['bright_white on_magenta'], ' Testing     -> '), colored(['bright_green'], '     make'), " test\n";
print colored(['bright_white on_magenta'], ' Installing  -> '), colored(['red'],          'sudo '),     colored(['bright_green'], 'make'), " install\n";
print colored(['bright_white on_magenta'], ' Cleaning Up -> '), colored(['bright_green'], '     make'), " veryclean\n";
print colored(['blue on_blue'],            $line),              "\n";

exit(0);

sub slurp_file {
    my $file = shift;
    return (
        do { local (@ARGV, $/) = $file; <> }
    );
} ## end sub slurp_file

__END__
  
=pod

Copyright (C) 2025 Richard Kelsch
All Rights Reserved

=cut
