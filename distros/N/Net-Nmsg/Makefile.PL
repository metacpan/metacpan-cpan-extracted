use 5.004_04;
use ExtUtils::MakeMaker;
use DynaLoader;
use File::Spec;

use strict;
use warnings;

sub find_lib {
  die "lib name required" unless @_;
  my @locs = DynaLoader::dl_findfile('-l' . shift);
  @locs ? $locs[0] : '';
}

my %options = (
  LIBS   => ['-lnmsg -lpcap'],
  INC    => '-I.',
  OBJECT => '$(O_FILES)',
);

for my $l (qw( pcap nmsg )) {
  my $p = find_lib($l);
  if ($p) {
    my @p = File::Spec->splitdir($p);
    pop @p;
    my $libdir = File::Spec->catdir(@p);
    pop @p;
    my $incdir = File::Spec->catdir(@p, 'include');
    my $f = File::Spec->catdir($incdir, "$l.h");
    $options{INC} .= " -I$incdir" if -f $f;
    $options{LIBS}[0] = "-L$libdir $options{LIBS}[0]";
    next;
  }
  my $dirs = join("\n    ", @DynaLoader::dl_library_path);
  warn <<__FAIL and exit;
The $l(3) library was not found in the following directories:

    $dirs

If it is installed but in an odd location, consider setting
the LD_LIBRARY_PATH environment variable to the lib dir.
__FAIL
}

my @test_for = qw( pcap_set_snaplen pcap_set_promisc );
my %missing;
for my $f (@test_for) {
  my @locs = DynaLoader::dl_findfile('-lpcap');
  if (@locs) {
    my $lref = DynaLoader::dl_load_file($locs[0]);
    for my $f (@test_for) {
      my $sym = DynaLoader::dl_find_symbol($lref, $f);
      ++$missing{$f} unless $sym;
    }
  }
}

if (%missing) {
  $options{DEFINE} ||= '';
  $options{DEFINE} = join(' ', $options{DEFINE}, "-DLIMITED_PCAP");
}

WriteMakefile(
  NAME          => 'Net::Nmsg',
  VERSION_FROM  => 'lib/Net/Nmsg.pm',
  ABSTRACT_FROM => 'lib/Net/Nmsg.pm',
  AUTHOR        => 'Matt Sisk <sisk@cert.org>',
  PREREQ_PM => {
    'Math::Int64'       => '0.51',
    'NetAddr::IP::Util' => 0,
  },
  %options
);
