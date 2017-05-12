use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# the package requires modern perl
require 5.005_03;

my $self = 0; # just to fake $self
my $version = ExtUtils::MM_Unix::parse_version($self, 'lib/PerlPoint/Converters.pm');

$ok=WriteMakefile(
    'NAME'	=> 'PerlPoint-Converters',
    'VERSION_FROM' => 'lib/PerlPoint/Converters.pm',
     PREREQ_PM     => {
                         PerlPoint::Parser => 0.40,
                         Getopt::ArgvFile => 1.01,
                      },
    dist           => {
                         COMPRESS => 'gzip -9',
                         SUFFIX   => 'tgz',
                      },
    depend         => { Makefile => '$(VERSION_FROM)' },

    EXE_FILES      => [
                         "pp2html", "pp2latex"
                      ],
    clean => {FILES => "t/*.htm .*.ppcache doc/.*.ppcache" .
                      " *.aux *.dvi *.tex *.ilg ppdoc.ps"
                      },
);

# Replace 'perl' in ./doc/Makefile with current perl version:
system("$^X -pi -e 's#^(PERL=)(\\S+)(.*)\$#\$1$^X\$3#' doc/Makefile");

# Fix packet version number in pp2html and pp2latex
# (... if I missed to do it manually :-)
fix_version( 'pp2html', $version);
fix_version( 'pp2latex', $version);

# Provide additional informations
warn <<EOM if $ok;

Welcome to the PerlPoint-Converters package, version $version!

The installation is well prepared now, and you 
might run "make test" and "make install".

Documentation is available in the ./doc subdirectory. 
Start a "make" there and then have a look into the 
./doc/PPDOC directory.

EOM

exit 0;

#----------------------------------------------------------------------
sub fix_version {
  my ($file, $version) = @_;

  rename $file, "$file.bak";

  open(D, "$file.bak") or die "cannot open $file.bak for reading: $!\n";
  open(W, ">$file") or die "cannot open $file for writing: $!\n";

  while(<D>){
    if (/^from PerlPoint::Converters Package/){
      print W "from PerlPoint::Converters Package $version\n";
      next;
    }

    print W $_;
  }
  close D;
  close W;
  unlink "$file.bak";
  if ($^O =~ /linux/i){
    system "chmod +x $file";
  }
}

