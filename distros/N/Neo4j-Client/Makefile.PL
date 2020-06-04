use v5.10;
use ExtUtils::MakeMaker;
use ExtUtils::CChecker;
use Try::Tiny;
use File::Temp qw/tempfile tempdir/;
use Config;
use File::Find;
use File::Spec;
use File::Copy;
use Cwd qw/realpath/;
use IPC::Run qw/run/;
use Carp qw/carp croak/;
use strict;


# Windoze alert
if ($^O =~ /MSWin/) {
  say "This package will not install in Windows natively.";
  say "Try installing under Cygwin or MSys.";
  exit 0;
}

my $libdir = File::Spec->catdir(qw/build src lib/);
my @try_incdirs = ("", qw{/usr/include /usr/local/opt/openssl/include});
my @try_libdirs = ("", qw{/usr/lib /usr/local/opt/openssl/lib});
opendir my $src, $libdir;
my @files = grep /\.[ch]$/, readdir $src;
if (! defined find_openssl(\@try_incdirs,\@try_libdirs)->[1]) { # remove openssl files
  @files = grep !/openssl/, @files;
}
# stage the libneo4client source+headers
copy (File::Spec->catfile($libdir,$_), File::Spec->curdir) for @files;

# config.h will be in the curdir - hack the staged files
for (@files) {
  system "$^X -i -ne 's{\.\./\.\./config\.h}{config\.h};print;' $_";
  croak $! unless !$?;
}

my @src_files = grep /\.c$/, @files;
my @o_files = map { s/\.c/\.o/;$_ } @src_files;
my $LDDLFLAGS = $Config{lddlflags};

WriteMakefile(
  NAME => 'Neo4j::Client',
  MIN_PERL_VERSION => '5.010',
  META_MERGE => {
    resources => {
      repository => {
	url => 'https://github.com/majensen/neoclient',
	web => 'https://github.com/majensen/neoclient',
	type => 'git'
       },
      bugtracker => {
	web => 'https://github.com/majensen/neoclient/issues',
      }
     },
  },
  ABSTRACT => 'Build and use the libneo4j-client library',
  AUTHOR => ['Mark A. Jensen (majensen -at- cpan -dot- org)'],
  VERSION_FROM => 'lib/Neo4j/Client.pm',
  LICENSE => 'apache_2_0',
  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'Test::Exception' => 0,
    'File::ShareDir' => 0,
    'Pod::Usage' => 0,
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::CChecker' => 0,
    'Try::Tiny' => 0,
    'IPC::Run' => 0
    },
  OBJECT => join(' ',@o_files),
  LDDLFLAGS => $LDDLFLAGS,
  LDFROM => join(' ', @o_files),
  LINKTYPE => 'dynamic',
  linkext => { LINKTYPE => 'dynamic' },
  test => {TESTS => 't/*.t'},
  CONFIGURE => \&_configure, # CCFLAGS and LIBS generated here
  PM => {
    'lib/Neo4j/Client.pm' => '$(INST_LIB)/Neo4j/Client.pm',
    'lib/Neo4j/ClientLocal.pm' => '$(INST_LIB)/Neo4j/ClientLocal.pm',
    'build/src/lib/neo4j-client.h' => '$(INST_ARCHLIB)/auto/Neo4j/Client/neo4j-client.h',
    "blib/arch/auto/Neo4j/Client/Client.a" => "\$(INST_ARCHLIB)/auto/Neo4j/Client/libClient.a",
    'bin/neoclient.pl' => '$(INST_SCRIPT)/neoclient.pl',
  },
  C => [grep /\.c$/, @src_files],
  H => [(grep /\.h$/, @src_files),'config.h'],
  realclean => { FILES => ['a.out','config.h', 'build/config.h',@files,'lib/Neo4j/ClientTLS.pm'] },
 );


sub _configure {
  my ($in,$out,$err);
  
  # Find openssl or exclude TLS support
  my $ssl_flags = find_openssl(\@try_incdirs, \@try_libdirs);
  say STDERR "Building without TLS - openssl not found" unless $ssl_flags;
  my ($tls_cc, $tls_ld, $tls_libd, $have_pc) = @$ssl_flags;
  my  $TLS = (defined $tls_ld ? '--with-tls' : '--without-tls');
  my  $WITH_LIBS = (defined $tls_libd ? "--with-libs=$tls_libd" : '');
  my @configure_opts = ($TLS,$WITH_LIBS || ());
  say "Running configure";
  chdir 'build';
  my @env;
  if (!$have_pc) {
    # libneo4j-client configure kludge - if no pkg-config,
    # must set both OPENSSL_LIBS and OPENSSL_CFLAGS to non-empty strings
    # for the ssl check to succeed
    my $ll = join(' ', ($tls_libd ? "-L$tls_libd":()), "$tls_ld ");
    @env = ('env',"OPENSSL_CFLAGS='$tls_cc '",
	    "OPENSSL_LIBS='$ll'");
  }
  my $rc = run [@env,'./configure',@configure_opts], \$in,\$out,\$err;
  if (!$rc) {
    croak "configure failed with this output:\n$err";
  }
  else {
    # kludge away the VERSION define
    open my $f, "config.h" or croak "build/config.h: $!";
    my @lines = <$f>;
    close($f);
    open $f, ">", File::Spec->catfile('..','config.h'); # create in the toplevel dir
    for (@lines) {
      next if /#define VERSION/;
      print $f $_;
    }
    close($f);
  }

  # Review config.log for threading info and cflags
  open my $lf, "config.log" or croak "Where's the config.log?";
  my @log = <$lf>;
  my %pthread = map { chomp;my @a = split /=/; $a[1]=~s/'//g; @a } grep /PTHREAD_(?:CFLAGS|LIBS)/,@log;
  if (%pthread) {
    ($pthread{PTHREAD_CFLAGS} =~ /-pthread/) && do {
      # put -pthread in linker flags, or CBuilder won't see it for some reason
      $pthread{PTHREAD_CFLAGS} =~ s/-pthread//;
      $pthread{PTHREAD_LIBS} = join(' ',$pthread{PTHREAD_LIBS},'-pthread');
    };
  }
  my ($cflags) = grep /^CFLAGS=/,@log;
  $cflags =~ s/^CFLAGS='//; $cflags =~ s/'\s*$//;
  $cflags =~ s/\s+-W[a-zA-Z-_=]*//g;
  chdir '..';
  my $CCFLAGS = join(' ', $tls_cc, $pthread{PTHREAD_CFLAGS}, $cflags);
  my $LIBS = join(' ', $tls_ld, $pthread{PTHREAD_LIBS});
  _neo4j_client_local($CCFLAGS, $LIBS);
  $LIBS =~ s/-pthread//;
  return {
    CCFLAGS => $CCFLAGS,
    LIBS => $LIBS
   };
}

sub _neo4j_client_local {
  my ($ccflags,$libs) = @_;
  my $local =<<LCL;
package Neo4j::ClientLocal;

\$Neo4j::Client::LOCAL_CCFLAGS='$ccflags';

\$Neo4j::Client::LOCAL_LIBS='$libs';
1;
LCL
  open my $f,">",File::Spec->catfile(qw/lib Neo4j ClientLocal.pm/) or croak $!;
  print $f $local;
  close $f;
  return 1;
}

sub Lperl {
  # archlib
  my $lib = '';
  find( sub {
	  /libperl/ && ($lib = $File::Find::name);
	}, $Config{archlib});
  my $dir =[File::Spec->splitpath($lib)]->[1];
  $dir =~ s/\/$//;
  return "-L$dir";
}

sub find_openssl {
  my ($try_incdirs, $try_libdirs) = @_;
  state $ssl_flags;
  return $ssl_flags if ($ssl_flags);
  say "Finding openssl";
  my ($in,$out,$err);
  my $pkg_config = 1;
  try {
    if (run([qw/pkg-config --variable=libdir openssl/],\$in,\$out,\$err)) {
      print $out;
      chomp $out;
      push @{$try_libdirs}, $out;
    }
    if (run([qw/pkg-config --variable=includedir openssl/],\$in,\$out,\$err)) {
      print $out;
      chomp $out;
      push @{$try_incdirs}, $out;
    }
  } catch {
    $pkg_config = undef;
    say STDERR "(note: no pkg-config)\n";
  };
    
  my $cc = ExtUtils::CChecker->new( quiet => 1);
  my ($inc_found, $lib_found);
  $cc->push_extra_linker_flags('-lssl');
  $cc->push_extra_linker_flags('-lcrypto');
  my $tryc =<<'TRY';
#include <openssl/crypto.h>
int main() {
  printf("SSL Version: %s\n", OpenSSL_version(0));
  return 0;
}
TRY
  my $libd;
  open(OLDERR,">&",\*STDERR);
  close(STDERR);
  for my $incdir (@$try_incdirs) {
    $cc->push_extra_compiler_flags("-I$incdir") if $incdir;
    if (eval { $cc->try_compile( source => $tryc ) }) {
      $inc_found = 1;
      last;
    }
    $cc->pop_extra_compiler_flags if $incdir;
  }

  unless ($inc_found) {
    open(STDERR, ">&OLDERR");
    return $ssl_flags = [undef,undef,undef, $pkg_config];
  }
  
  for my $libdir (@$try_libdirs) {
    $libdir = realpath $libdir if $libdir;
    $cc->unshift_extra_linker_flags( "-L".$libdir ) if $libdir;
    if ($cc->try_compile_run( source => $tryc )) {
      $lib_found=1;
      $libd = $libdir;
      $libd =~ s/lib$//;
      last;
    }
    $cc->shift_extra_linker_flags if $libdir
  }
  if ($lib_found) {
    open(STDERR, ">&OLDERR");
    return $ssl_flags = [join( ' ', @{$cc->extra_compiler_flags}),
	    join( ' ', @{$cc->extra_linker_flags}),
	   $libd, $pkg_config];
  }
  open(STDERR, ">&OLDERR");  
  return $ssl_flags = [undef,undef,undef,$pkg_config];
}

# monkey patches for ExtUtils::CChecker

sub ExtUtils::CChecker::try_compile {
  my $self = shift;
  my %args = @_;
  return unless $args{source};
  my $dir = tempdir( CLEANUP => 1);
  my ($fh, $fn) = tempfile('',DIR=>$dir,SUFFIX => '.c',UNLINK=>1) or die $!;
  print $fh $args{source};
  close($fh);
  $args{source} = $fn;
  try {
    return $self->compile(%args);
  } catch {
    return 0;
  };
}

sub ExtUtils::CChecker::unshift_extra_linker_flags {
  my $self = shift;
  unshift @{$self->{extra_linker_flags}},@_;
}

sub ExtUtils::CChecker::shift_extra_linker_flags {
  my $self = shift;
  shift @{$self->{extra_linker_flags}};
}

sub ExtUtils::CChecker::pop_extra_compiler_flags {
  my $self = shift;
  pop @{$self->{extra_compiler_flags}};
}

sub ExtUtils::CChecker::pop_include_dirs {
  my $self = shift;
  pop @{$self->{include_dirs}};
}

package MY;
# heads-up : real <TAB>s in FRAG below
sub postamble {
  return <<'FRAG';
h_to_blib : pm_to_blib config.h
	$(MKPATH) blib/arch/auto/Neo4j/Client/include/
	$(CP) build/src/lib/*.h blib/arch/auto/Neo4j/Client/include/
	$(CP) config.h blib/arch/auto/Neo4j/Client/include/
	$(NOECHO) $(TOUCH) h_to_blib
FRAG
}

sub top_targets {
  my $orig = shift->SUPER::top_targets(@_);
  $orig =~ s/linkext/linkext h_to_blib/;
  return $orig;
}
