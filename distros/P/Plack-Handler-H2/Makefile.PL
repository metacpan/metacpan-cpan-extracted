use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Determine C++ compiler
my $CXX = $ENV{CXX} || $Config{cxx} || 'g++';

# C++ compiler flags
my $CCFLAGS = join( ' ',
  $Config{ccflags},
  '-std=c++17',
  '-Wall',
  '-Wextra',
  '-O2',
  '-fPIC',
  '-g'
);

# Linker flags
my $LIBS = '-lnghttp2 -levent -levent_openssl -levent_pthreads -lssl -lcrypto -lpthread';

# Include directories - add Perl's CORE directory
my $INC = join(' ',
  '-I.',
  '-I./lib/Plack/Handler',
  "-I$Config{archlib}/CORE",
);

WriteMakefile(
  NAME             => 'Plack::Handler::H2',
  VERSION_FROM     => 'lib/Plack/Handler/H2.pm',
  ABSTRACT         => 'HTTP/2 server handler for Plack',
  AUTHOR           => 'Rawley Fowler <rawley@molluscsoftware.com>',
  LICENSE          => 'bsd',
  MIN_PERL_VERSION => '5.024',

  PREREQ_PM => {
    'Plack'    => '1.0',
    'File::Temp' => '0.22',
    'XSLoader' => 0,
  },

  TEST_REQUIRES => {
    'Test::More' => '0.98',
  },

  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
  },

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
  },

  # List all object files that need to be linked
  OBJECT  => 'lib/Plack/Handler/H2$(OBJ_EXT) lib/Plack/Handler/plack_handler_h2$(OBJ_EXT)',
  
  LIBS    => [$LIBS],
  INC     => $INC,
  
  # Use C++ compiler
  CC      => $CXX,
  LD      => $CXX,
  XSOPT   => '-C++',
  CCFLAGS => $CCFLAGS,

  # XS files - XS generates .c files from .xs
  XS => {
    'lib/Plack/Handler/H2.xs' => 'lib/Plack/Handler/H2.c',
  },

  # Additional C/C++ source files
  C => [
    'lib/Plack/Handler/H2.c',
    'lib/Plack/Handler/plack_handler_h2.cc',
  ],

  # Header files
  H => [
    'lib/Plack/Handler/plack_handler_h2.h',
  ],

  clean => {
    FILES => 'lib/Plack/Handler/H2.c lib/Plack/Handler/*.o lib/Plack/Handler/*.so lib/Plack/Handler/*.bs test.c test.out H2.o plack_handler_h2.o H2.c H2.bs H2.so',
  },

  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources   => {
      repository => {
        type => 'git',
        url  => 'https://github.com/rawleyfowler/perl-Plack-Handler-H2.git',
        web  => 'https://github.com/rawleyfowler/perl-Plack-Handler-H2',
      },
      bugtracker => {
        web => 'https://github.com/rawleyfowler/perl-Plack-Handler-H2/issues',
      },
    },
  },

  dist => {
    COMPRESS => 'gzip -9f',
    SUFFIX   => 'gz'
  },

  NO_META => 0,
);

# Override the c_o method to ensure C++ compilation
package MY;

sub c_o {
  my $inherited = shift->SUPER::c_o(@_);
  
  # Add rules for compiling .cc files with C++ compiler
  $inherited .= <<'MAKE_FRAG';

.cc.o:
	$(CXX) -c $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(PERLTYPE) $(MPOLLOPT) $(DEFINE_VERSION) $(XS_DEFINE_VERSION) -o $@ $<

.cc$(OBJ_EXT):
	$(CXX) -c $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(PERLTYPE) $(MPOLLOPT) $(DEFINE_VERSION) $(XS_DEFINE_VERSION) -o $@ $<

MAKE_FRAG

  return $inherited;
}

# Add custom postamble for additional dependencies
sub postamble {
  return <<'MAKE_FRAG';

# Ensure C++ implementation is compiled in the correct location
lib/Plack/Handler/plack_handler_h2$(OBJ_EXT): lib/Plack/Handler/plack_handler_h2.cc lib/Plack/Handler/plack_handler_h2.h
	$(CXX) -c $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(PERLTYPE) $(MPOLLOPT) $(DEFINE_VERSION) $(XS_DEFINE_VERSION) -o lib/Plack/Handler/plack_handler_h2$(OBJ_EXT) lib/Plack/Handler/plack_handler_h2.cc

# XS-generated C file should compile in the correct location
lib/Plack/Handler/H2$(OBJ_EXT): lib/Plack/Handler/H2.c lib/Plack/Handler/plack_handler_h2.h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) lib/Plack/Handler/H2.c -o lib/Plack/Handler/H2$(OBJ_EXT)

# XS-generated C file depends on XS and header
lib/Plack/Handler/H2.c: lib/Plack/Handler/H2.xs lib/Plack/Handler/plack_handler_h2.h
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) lib/Plack/Handler/H2.xs > lib/Plack/Handler/H2.c

MAKE_FRAG
}

package main;

# Print helpful information
unless ( $ENV{AUTOMATED_TESTING} ) {
  print "\n";
  print "=" x 70 . "\n";
  print "Plack::Handler::H2 - HTTP/2 Server Handler for Plack\n";
  print "=" x 70 . "\n";
  print "\nRequired system libraries:\n";
  print "  - nghttp2 (HTTP/2 C library)\n";
  print "  - libevent2 (Event notification library)\n";
  print "  - OpenSSL (TLS/SSL library)\n";
  print "\nInstallation commands:\n";
  print "  Debian/Ubuntu: sudo apt-get install libnghttp2-dev libevent-dev libssl-dev\n";
  print "  CentOS/RHEL:   sudo yum install nghttp2-devel libevent-devel openssl-devel\n";
  print "  macOS:         brew install nghttp2 libevent openssl\n";
  print "\n";
  print "=" x 70 . "\n\n";
}

1;
