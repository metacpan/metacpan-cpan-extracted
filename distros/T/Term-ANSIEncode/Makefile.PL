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
use Term::ANSIColor;

my $line = '-' x 30 . ' Term::ANSIEncode ' . '-' x 30;
if (-e 'Makefile') {
    `make veryclean;reset`;
}

# ANSI Encode

my $lib     = 'lib/Term/ANSIEncode.pm';

{
	my $cy      = "\e[36m\e[40m";
	my $r       = "\e[31m\e[40m";
	my $w       = "\e[37m\e[40m";
	my $y       = "\e[33m\e[40m";
	my $g       = "\e[32m\e[40m";
	my $b       = "\e[34m\e[40m";
	my $bw      = "\e[97m\e[40m";
	my $rs      = "\e[0m";

	my $name = "\e[2;4H${cy}█████               ${r}      ██  ${y}█   █${g}  ██ ${b} █████$bw ███$rs";
	$name   .= "\e[3;4H${cy}  █                 ${r}     █  █ ${y}██  █${g} █   ${b}   █  $bw █  $rs";
	$name   .= "\e[4;4H${cy}  █ ███ ███  █   █  ${r}     █  █ ${y}█ █ █${g} █   ${b}   █  $bw █   █  █  ██   ██  ███  ███$rs"; 
	$name   .= "\e[5;4H${cy}  █ █   █  █ ██ ██  ${w}█ █$r  ████ ${y}█  ██${g}  ██ ${b}   █  $bw ██  ██ █ █  █ █  █ █  █ █  $rs";
	$name   .= "\e[6;4H${cy}  █ ██  ███  █ █ █  ${r}     █  █ ${y}█   █${g}    █${b}   █  $bw █   █ ██ █    █  █ █  █ ██ $rs";
	$name   .= "\e[7;4H${cy}  █ █   █  █ █   █  ${w}█ █$r  █  █ ${y}█   █${g}    █${b}   █  $bw █   █  █ █  █ █  █ █  █ █  $rs";
	$name   .= "\e[8;4H${cy}  █ ███ █  █ █   █  ${r}     █  █ ${y}█   █${g}  ██ ${b} █████$bw ███ █  █  ██   ██  ███  ███$rs";

	my $Version = get_version($lib);

	my $banner = "\e[2J\e[1;1H";
	$banner .= "\e[40m\e[93m ╔═════════════════════════════════════════════════════════════════════════════╗ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                                                                             ║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                                                                             ║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                                                                             ║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                                                                             ║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                                                                             ║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                                                                             ║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                                                                             ║ \e[0m\n";
	$banner .= "\e[40m\e[93m ╠═════════════════════════════════════════════════════════════════════════════╣ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                         \e[37mWritten By \e[92mRichard Kelsch                           \e[93m║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                      \e[37mCopyright © \e[92m2025 \e[37mRichard Kelsch                        \e[93m║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                            \e[37mAll Rights Reserved                              \e[93m║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                         \e[37mPerl Artistic License 2.0                           \e[93m║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║                               \e[37mVersion\e[92m $Version                                  \e[93m║ \e[0m\n";
	$banner .= "\e[40m\e[93m ║              \e[37mGitHub:  https://github.com/richcsst/ansi-encode               \e[93m║ \e[0m\n";
	$banner .= "\e[40m\e[93m ╚═════════════════════════════════════════════════════════════════════════════╝ \e[0m\n";

	print $banner, "\n";
	print $name, "\e[17;1H\n";
}

WriteMakefile(
    NAME               => 'Term::ANSIEncode',
    AUTHOR             => q{Richard Kelsch <rich@rk-internet.com>},
    VERSION_FROM       => $lib,
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
		'Test2::Require::AuthorTesting' => '0',
        'Test::More' => '1.00',
        'List::Util' => '1.20',
    },
    PREREQ_PRINT => TRUE,
    PREREQ_FATAL => FALSE,
    PREREQ_PM    => {
        'charnames'         => '0',
        'List::Util'        => '1.20',
        'Time::HiRes'       => '0',
        'Getopt::Long'      => '0',
        'Text::Wrap::Smart' => '0',
		'Text::Format'      => '0',
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

print colored(['blue on_blue'], $line . "\e[0K"), "\n";
print colored(['bright_white on_magenta'], ' Building    -> '), colored(['bright_green'], '      make'), "\n";
print colored(['bright_white on_magenta'], ' Testing     -> '), colored(['bright_green'], '      make'), " test\n";
print colored(['bright_white on_magenta'], ' Installing  -> '), colored(['red'],          ' sudo '),     colored(['bright_green'], 'make'), " install\n";
print colored(['bright_white on_magenta'], ' Cleaning Up -> '), colored(['bright_green'], '      make'), " veryclean\n";
print colored(['blue on_blue'], $line . "\e[0K"), "\n";

exit(0);

sub get_version {
    my $file = shift;

	open(my $FILE, '<', $file);
	my $line = <$FILE>;
	chomp($line);
	close($FILE);

	$line =~ /package Term::ANSIEncode (.+)/;
	my $version = $1;
	chop($version);
	return($version);
} ## end sub slurp_file

__END__
  
=pod

Copyright (C) 2025 Richard Kelsch
All Rights Reserved

=cut
