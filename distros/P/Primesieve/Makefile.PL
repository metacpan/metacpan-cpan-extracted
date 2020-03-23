use ExtUtils::MakeMaker;

sub have_pkgconfig ($)
{
  `pkg-config --exists $_[0]`;
  0+!$?;
}

sub pkgconfig ($)
{
  my $v = shift;
  my $cmd = "pkg-config --$v primesieve";
  my $r = `$cmd`;
  chomp $r;
#  $r = undef if $r eq "";
  die "pkg-config error running: `$cmd`: $!" unless defined $r;
  $r;
}

my ($libs,$cflags);

if (have_pkgconfig ("primesieve")) {
        $libs = pkgconfig "libs";
        $cflags = pkgconfig "cflags";
} else {
        $libs = "-lprimesieve";
        $cflags = "";
}

WriteMakefile(
    NAME              => 'Primesieve',
    VERSION_FROM      => 'lib/Primesieve.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Primesieve.pm', # retrieve abstract from module
    AUTHOR            => 'Stefan Traby <stefan@hello-penguin.com>',
    LICENSE           => 'perl',
    LIBS              => [$libs], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. $cflags", # e.g., '-I. -I/usr/include/other'
);
