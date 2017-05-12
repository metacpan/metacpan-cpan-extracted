#!/usr/local/bin/perl -w

# Copyright 2001, Paul Johnson (pjcj@cpan.org)

# This software is free.  It is licensed under the same terms as Perl itself.

# The latest version of this software should be available from my homepage:
# http://www.pjcj.net

require 5.004;

use strict;

use ExtUtils::MakeMaker;

$| = 1;

my $Version = "0.01";
my $Date    = "2nd August 2001";
my $Author  = 'pjcj@cpan.org';

my @perlbug = ("perlbug", "-a", $Author,
                          "-s", "Installation of Shell::Source $Version");

my $Perlbug = join " ", map { / / ? "'$_'" : $_ } @perlbug;


open M, "MANIFEST" or die "Cannot open MANIFEST: $!";
my @files    = map { split } <M>;
my @versions = grep { $_ ne "README" && $_ ne "Makefile.PL" } @files;
close M or die "Cannot close MANIFEST: $!";

$ExtUtils::MakeMaker::Verbose = 0;

WriteMakefile
(
  NAME     => "Shell::Source",
  VERSION  => $Version,
  DIR      => [],
  PM       => { map {($_ => '$(INST_LIBDIR)/' . $_)} grep { /\.pm/ } @files },
  dist     => { COMPRESS => "gzip --best --force" },
  clean    => { FILES => join " ",  map { "$_.version" } @versions },
  depend   => { distdir => "@files" },
  $] >= 5.005 ?
  (
      AUTHOR   => 'Paul Johnson (pjcj@cpan.org)',
      ABSTRACT => "Run programs and inherit environment changes",
  ) : (),
);

print <<EOM if 0;

--------------------------------------------------------------------------------

I like to have some idea of the distribution of this software.  To that end I
would be very grateful for mail from you.  This will be used only to satisfy my
curiosity and to help me make decisions which may involve changes to the
module.

If you can run perlbug you can send me a success report with "make ok".
Failure reports with "make nok" are also appreciated.

If you have any questions or comments, mailing list details are available in the
README file, or send mail to me directly.

EOM

sub MY::postamble
{
  qq[
SET_VERSION = \$(PERL) -pi.version \\
  -e 's/(^\\s*(?:our\\s+)?\\\$\$VERSION = ")\\d+\\.\\d+(";)/\$\${1}$Version\$\$2/;' \\
  -e 's/(Version )\\d+\\.\\d+( - ).*/\$\${1}$Version\$\${2}$Date/;' \\
  -e 's/(^\\s*use Shell::Source(?:::\\w+)*\\s+)\\d+\\.\\d+/\$\${1}$Version/;'

tags : @files
\t ptags @files

@versions : Makefile.PL
\t \$(SET_VERSION) @versions

README : Source.pm
\t TERMCAP= COLUMNS=80 pod2text Source.pm | \\
  \$(PERL) -n \\
  -e 'print if (/^NAME/ ... /^[A-Z ]+\$\$/) =~ /^\\d+\$\$/;' \\
  -e 'print if (/^DESCRIPTION/ ... /^[A-Z ]+\$\$/) =~ /^\\d+\$\$/;' \\
  > README

ppm : ppd pure_all
\t tar cf Shell-Source.tar blib
\t gzip --best --force Shell-Source.tar
\t \$(PERL) -pi.bak \\
  -e 's/(OS NAME=")[^"]*/\$\$1MSWin32/;' \\
  -e 's/(ARCHITECTURE NAME=")[^"]*/\$\$1MSWin32-x86-multi-thread/;' \\
  -e 's/(CODEBASE HREF=")[^"]*/\$\$1Shell-Source.tar.gz/;' \\
  Shell-Source.ppd

ok :
\t \@$Perlbug -okay  || echo "Please send your report manually to $Author"

nok :
\t \@$Perlbug -nokay || echo "Please send your report manually to $Author"
  ]
}
