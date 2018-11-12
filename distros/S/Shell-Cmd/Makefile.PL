######################################################################
# Makefile.PL for Shell::Cmd
######################################################################

use strict;
use warnings;
use 5.008;
use ExtUtils::MakeMaker 6.30;

my %IsWin32 = map { $_ => 1 } qw( MSWin32 NetWare symbian );
my $IsWin32 = 1   if ($IsWin32{ $^O });
my $Pvers   = $];
my $ConvVers= $ExtUtils::MakeMaker::VERSION;

my %module_prereq = (
   'Capture::Tiny'            => '0',
   'Cwd'                      => '0',
   'IO::File'                 => '0',
   'Net::OpenSSH'             => '0',
   'Parallel::ForkManager'    => '0',
);

my %script_prereq = (
);

my %test_prereq = (
   'Test::Inter'              => '0',
   'Test::More'               => '0',
);

my %config_prereq = (
   'ExtUtils::MakeMaker'      => '6.30',
);

%module_prereq = (%module_prereq,%script_prereq);
my $EU_MM_V    = $ExtUtils::MakeMaker::VERSION;
$EU_MM_V       =~ s/_//g;
if ($EU_MM_V < 6.64) {
   %config_prereq = (%config_prereq,%test_prereq);
}

WriteMakefile(
   NAME             => "Shell::Cmd",
   VERSION          => "3.02",
   ABSTRACT         => "run shell commands with enhanced support",
   LICENSE          => "perl",
   ($EU_MM_V >= 6.48
    ? (MIN_PERL_VERSION => "5.008")
    : ()),
   AUTHOR           => "Sullivan Beck (sbeck\@cpan.org)",
   "dist"           => {COMPRESS=>"gzip",SUFFIX=>"gz"},
   PL_FILES         => {},
   PREREQ_PM        => \%module_prereq,
   ($EU_MM_V >= 6.52
    ? (CONFIGURE_REQUIRES => \%config_prereq)
    : ()),
   ($EU_MM_V >= 6.64
    ? (TEST_REQUIRES   => \%test_prereq)
    : ()),
   ($EU_MM_V > 6.45
    ? (META_ADD => {
          provides     => {
             'Shell::Cmd' => {
                file    => 'lib/Shell/Cmd.pm',
                version => '3.02',
             },

          },
       }
      )
    : ()),

   ($EU_MM_V > 6.46
    ? (META_MERGE => {
          'meta-spec'  => {
             version   => 2,
          },
          resources    => {
             repository => {
                type => 'git',
                web  => 'https://github.com/SBECK-github/Shell-Cmd',
                url  => 'git://github.com/SBECK-github/Shell-Cmd.git',
             },
          },
       }
      )
    : ()),




);
