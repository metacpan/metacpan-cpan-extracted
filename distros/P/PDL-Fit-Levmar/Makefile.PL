use strict;
use warnings;

use PDL::Core::Dev;
use ExtUtils::MakeMaker;
use Carp;
PDL::Core::Dev->import();

# Choose this to build *without* lapack
our $HAVE_LAPACK = 0;

# Choose this to build *with* lapack
# our $HAVE_LAPACK = 1;

# Developer must edit VERSION in both Levmar.pm and Func.pm

open my $fh, '>','have_lapack' or die "Can't open config file have_lapack for write.";
print $fh "\$HAVE_LAPACK=$HAVE_LAPACK;\n1\n";
close($fh);

my $levmarsrc = "./levmar-2.6";
my $lmpackage = ["levmar.pd", 'Levmar', 'PDL::Fit::Levmar'];

my %hash = pdlpp_stdargs($lmpackage);

#$hash{VERSION}  = $VERSION;
$hash{VERSION_FROM} = 'levmar.pd';
$hash{INC} .= " -I$levmarsrc";

# I spent a few hours trying to figure out how to automatically
# determine how to link lapack and blas. But I had no luck.

$hash{DEFINE} = ' -DHAVE_LAPACK ' if $HAVE_LAPACK;

if ( $HAVE_LAPACK ) {
    $hash{LIBS}  = $^O =~ /MSWin32/i ? 
        [ ' -L.. -lm  -llapack -lrefblas -LC:/strawberry/c/lib/gcc/x86_64-w64-mingw32/4.6.3/ -lgfortran ']  :
        [ ' -L/usr/lib/lapack -lm  -llapack -lblas '];
}
else {
    $hash{LIBS}  = $^O =~ /MSWin32/i ? 
        [ ' -L.. -lm  -LC:/strawberry/c/lib/gcc/x86_64-w64-mingw32/4.6.3/ -lgfortran ']  :
        [ ''];
}

# These are some other possibilities, eg if f2c (f77) was used to compile lapack
#' -lm  -llapack -lblas -lf2c ',
#	       ' -lm  -llapack -lblas -lF77 ', ' -lm  -llapack -lblas -lI77 ',
#	       ' -llapack -lcblas -lf77blas -latlas -lf2c ',
#               ' -llapack -lblas -latlas -lg2c  ' ];

$hash{DIR} = [ 'Func' ];

my @lm_base = qw(lm Axb misc lmlec lmblec lmbleic lmbc);
foreach my $f (@lm_base) {
    $hash{OBJECT} .= " $levmarsrc/$f\$(OBJ_EXT) ";
}

$hash{clean}{FILES} .= " " . $hash{OBJECT} .
		" *.o *.so have_lapack Levmar.html have_lapack ";

$hash{OPTIMIZE} = "-O3";  # from levmar src Makefile minus clang-incompat unroll-loops

$hash{PREREQ_PM} = { 
    'PDL' => 0,
    'File::Temp' => 0,
};

$hash{CONFIGURE_REQUIRES} = {
    'PDL' => '2.057', # allowed empty in $T()
    'ExtUtils::MakeMaker' => 0,
};

$hash{TEST_REQUIRES} = {
    'Test::More' => '0.88',
};

sub MY::postamble {
    my $s =  $levmarsrc;
    join('', map "$s/$_\$(OBJ_EXT): $s/$_.c $s/${_}_core.c $s/levmar.h $s/misc.h\n", @lm_base).
    "\nLevmar\$(OBJ_EXT) Levmar.pm: pdlperlfunc.c\n".
    pdlpp_postamble($lmpackage)
}

$hash{AUTHOR} = 'John Lapeyre <jlapeyre cpan.org>';
$hash{ABSTRACT} = 'Nonlinear fit and optimization routines for pdl';
$hash{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    bugtracker  => {web=>'https://github.com/jlapeyre/PDL-Fit-Levmar/issues'},
    repository  => {
       url => 'git://github.com/jlapeyre/PDL-Fit-Levmar.git',
       type => 'git',
       web => 'https://github.com/jlapeyre/PDL-Fit-Levmar',
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
};

WriteMakefile( %hash );

# makemaker does not use -o flag when making object
# files. So if I have a target ./dir/file.o, it
# does ./dir/file.c --> ./file.o, which is not what
# I want. This routine fixes it.
# I wonder if it will break build on another platform
package MY; # so that "SUPER" works right
sub c_o {
    my $inherited = shift->SUPER::c_o(@_);
    $inherited =~ s/\$\(DEFINE\)/\$\(DEFINE\) -o \$\*\$\(OBJ_EXT\)/g;
    $inherited;
}

# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;

=head1 OVERVIEW

This module is available on CPAN

=cut

EOF

if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open README, '>README.pod'              or die "Couldn't open README.pod";
  print README $POD_header;

  foreach my $mod  ('Levmar.pm', 'Func/Func.pm') {
      open MOD, $mod or die "Couldn't open main module";
      while (<MOD>)
      {
          if (/^=/../^=cut/)
          { print README; }
      }
      close(MOD);
  }
  close(README);
}


