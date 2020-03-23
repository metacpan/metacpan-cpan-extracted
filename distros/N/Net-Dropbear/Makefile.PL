use strict;
use warnings;

use 5.8.8;

use ExtUtils::MakeMaker 6.30;
use Config;

eval { build_dropbear() };
if ($@)
{
  warn "Unable to build dropbear: $@\n";
  warn "Aborted.\n";
  exit 0;    # tell cpan testers that this is not a failure
}

my $objs
    = qx[make -s -f printvar.mak -f dropbear/Makefile print-dropbearobjs print-LIBTOM_LIBS 2>/dev/null];
my $libs
    = qx[make -s -f printvar.mak -f dropbear/Makefile print-LIBS 2>/dev/null];

$objs = join " ", map {"dropbear/$_"} split( /\s+/xms, $objs );
$libs .= ' -lcrypt';

my %WriteMakefileArgs = (
  'ABSTRACT' => 'Use Dropbear SSH inside of perl',
  'AUTHOR' => 'Jon Gentle <atrodo@cpan.org>',
  'DISTNAME' => 'Net-Dropbear',
  'LICENSE' => 'artistic_2',
  'NAME' => 'Net::Dropbear',
  'MIN_PERL_VERSION' => '5.010000',
  'VERSION' => '0.13',

  test => { TESTS => "t/*.t" },
  INC => '-I. -Idropbear -Idropbear/libtomcrypt/src/headers',
  LDFROM => '$(OBJECT)' . " $objs",
  LIBS   => $libs,

  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '0'
  },
  'PREREQ_PM' => {
    'Child' => '0',
    'Moo' => '2.000',
    'Try::Tiny' => '0',
    'Types::Standard' => '0',
    'autodie' => '0'
  },
  'TEST_REQUIRES' => {
    'IO::Pty' => '0',
    'Test::More' => '0.96'
  },
);

my %FallbackPrereqs = (
  'BUILD_REQUIRES' => {
    'IO::Pty' => '0',
    'Test::More' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '0'
  },
  'PREREQ_PM' => {
    'Child' => '0',
    'Moo' => '2.000',
    'Try::Tiny' => '0',
    'Types::Standard' => '0',
    'autodie' => '0'
  },
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } )
{
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = {
    %{ $FallbackPrereqs{PREREQ_PM} },
    %{ $FallbackPrereqs{BUILD_REQUIRES} },
  };
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

sub run
{
  my ($cmd) = @_;
  warn "$cmd\n";
  my $ret = system($cmd);
  die "Error running $cmd ($!)\n"
      unless $ret == 0;
}

sub build_dropbear
{
  my $db_src = 'dropbear/';
  local $ENV{DESTDIR};    # do not let Perl module config leak through

  local $ENV{CFLAGS}   = $Config{cccdlflags} . ' ' . $Config{ccflags};
  local $ENV{LDFLAGS}  = $Config{ldflags} . ' ' . $Config{ccdlflags};
  local $ENV{CPPFLAGS} = $Config{cppflags};

  return
      if -e "$db_src/dropbear";

  run("cd $db_src && make distclean")
      if -f "$db_src/Makefile";

  run("cd $db_src && patch -N -i ../dropbear.patch")
      if !-f "$db_src/libdropbear.h";

  run("cd $db_src && ./configure");
  run("cd $db_src && make");
}

