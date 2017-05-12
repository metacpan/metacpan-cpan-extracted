use 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

use Config;

BEGIN {
 local $@;
 eval { require File::Spec; 1 } or die 'OS unsupported';
}

my $cc;
for (@ARGV) {
 if (/^CC=(.*)/) {
  $cc = $1;
  last;
 }
}
if (defined $cc) {
 print "Forcing the use of $cc as the C compiler.\n";
} else {
 # Inspired from Module::Install::Can
 print "Checking for a valid C compiler in the PATH... ";
 my @ccs = ($Config{cc});
 unshift @ccs, $ENV{CC} if $ENV{CC};
CC:
 for my $c (@ccs) {
  for my $dir (split /$Config{path_sep}/, $ENV{PATH}) {
   my $abs = File::Spec->catfile($dir, $c);
   if (-x $abs or MM->maybe_command($abs)) {
    $cc = $c;
    print $cc, "\n";
    last CC;
   }
  }
 }
 print "none\n" unless defined $cc;
}

my @C;
push @C, 'Util.c' if defined $cc;

my @DEFINES;

sub is_little_endian {
 my $order = $Config{byteorder};
 return 0 unless $order;
 my $len = length $order;
 if ($len > 8) {
  $order = substr $order, 0, 8;
  $len   = 8;
 }
 return $order eq (join '', 1 .. $len);
}

my $unit = { bits => 8, size => 1 };
if (not is_little_endian()) {
 print "Forcing unit size of 8 on non-little-endian systems.\n";
} else {
 print "Checking unit size in bits... ";
 my $align = $Config{alignbytes} || 1;
 my @bits = (8, 16, 32, 64);
 for my $bits (@bits) {
  my $size = $Config{"u${bits}size"};
  next unless $size;
  $unit = { bits => $bits, size => $size } if $size && $size <= $align;
 }
 print $unit->{bits},
                " (actually $unit->{size} bytes for $align bytes alignment).\n";
}

{
 my $bits = $unit->{bits};
 push @DEFINES, '-DBV_UNIT="' . ($Config{"u${bits}type"} || "U$bits") . '"';
 push @DEFINES, "-DSVU_SIZE=$bits";
}

@DEFINES = (DEFINE => join ' ', @DEFINES) if @DEFINES;

my $dist = 'Scalar-Vec-Util';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my %PREREQ_PM = (
 'Exporter' => 0,
 'Carp'     => 0,
 'XSLoader' => 0,
 'base'     => 0,
);

my %BUILD_REQUIRES = (
 'Config'              => 0,
 'ExtUtils::MakeMaker' => 0,
 'File::Spec'          => 0,
 'Test::More'          => 0,
 %PREREQ_PM,
);

my %META = (
 configure_requires => {
  'Config'              => 0,
  'ExtUtils::MakeMaker' => 0,
  'File::Spec'          => 0,
 },
 build_requires => {
  %BUILD_REQUIRES,
 },
 dynamic_config => 1,
 resources => {
  bugtracker => "http://rt.cpan.org/Dist/Display.html?Name=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 PL_FILES         => {},
 C                => \@C,
 @DEFINES,
 BUILD_REQUIRES   => \%BUILD_REQUIRES,
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => '5.006',
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text -u $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt*"
 },
);

1;

package MY;

sub postamble {
 my $cv = join ' -coverage ', 'cover',
                            qw<statement branch condition path subroutine time>;
 <<POSTAMBLE;
cover test_cover:
	$cv -test
POSTAMBLE
}
