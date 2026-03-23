use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use File::Spec::Functions;

sub get_gsl_config {
  my ($flags) = @_;
  no warnings 'exec';
  `gsl-config $flags`;
}

# Version check
chomp (my $version = get_gsl_config('--version') // '0');
my $new_enough = 0;
if (!$version) {
  $version = 'UNKNOWN VERSION';
} else {
  my $major = (split /\./,$version)[0];
  $new_enough= $major >= 2;
}
if (!$new_enough) {
  die "GSL modules: GSL version $version found, but need at least 2.0";
}

# the real stuff happens in the subdirs
sub get_gsl_libs {
  my $lib = ($ENV{GSL_LIBS} ||
	  get_gsl_config('--libs') ||
	  warn "\tno GSL link info (libgsl probably not available)\n");
  my $inc = ($ENV{GSL_INC} ||
	  get_gsl_config('--cflags') ||
	  warn "\tno GSL include info (libgsl probably not available)\n\n");
  chomp $lib; chomp $inc;
  ($inc,$lib);
}

# these will be used in the subdirs
my ($GSL_includes, $GSL_libs) = get_gsl_libs();

# create GENERATED subdir with *.pm files during 'make dist' (to make metacpan.org happy)
my $preop = '$(PERLRUNINST) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)';

my $package_name = "PDL::GSL";
(my $repo = $package_name) =~ s#::#-#g;
$repo = "PDLPorters/$repo";
WriteMakefile(
  NAME => $package_name,
  VERSION_FROM => 'lib/PDL/GSL.pm',
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  LICENSE=> "perl",
  MIN_PERL_VERSION => '5.016',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'PDL' => '2.096',
  },
  PREREQ_PM => {
    'PDL' => '2.096',
  },
  INC => join(' ', "-I".curdir(), $GSL_includes),
  LIBS => [$GSL_libs],
  dist => { COMPRESS => 'gzip', SUFFIX => 'gz', PREOP => $preop },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>"https://github.com/$repo/issues"},
      repository  => {
        url => "git://github.com/$repo.git",
        type => 'git',
        web => "https://github.com/$repo",
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
  clean => { FILES => join ' ', qw(MANIFEST.bak) },
);

my @pd_srcs;
sub MY::init_PM {
  package MY; # so that "SUPER" works right
  my ($self) = @_;
  $self->SUPER::init_PM;
  @pd_srcs = ::pdlpp_eumm_update_deep($self);
}
sub MY::postamble {
  ::pdlpp_postamble(@pd_srcs);
}
