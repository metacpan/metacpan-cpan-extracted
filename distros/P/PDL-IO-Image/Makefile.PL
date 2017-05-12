use strict;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use Alien::FreeImage;

my $package = [qw/Image.pd Image PDL::IO::Image/];
my %eumm_args = pdlpp_stdargs($package);

$eumm_args{INC} .= Alien::FreeImage->config('INC');
push @{$eumm_args{LIBS}}, Alien::FreeImage->config('LIBS');
push @{$eumm_args{TYPEMAPS}}, 'typemap';

WriteMakefile(
  %eumm_args,
  VERSION_FROM  => 'Image.pd',
  AUTHOR        => 'KMX <kmx@cpan.org>',
  ABSTRACT      => 'Load/save bitmap from/to PDL (via FreeImage library)',
  LICENSE       => 'perl',
  PREREQ_PM     => {
        'PDL' => '2.006',
        'Alien::FreeImage' => '0.011',
  },
  BUILD_REQUIRES => {
        'PDL' => '2.006',
        'Alien::FreeImage' => '0.011',
        'Test::Number::Delta' => '1.06',
        'Test::More' => 0,
        'File::Temp' => 0,
  },
  CONFIGURE_REQUIRES => {
        'PDL' => '2.006',
        'Alien::FreeImage' => '0.011',
  },
  META_MERGE   => {
      resources    => {
          repository   => 'https://github.com/kmx/pdl-io-image',
      },
  },
  dist => {
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : ()),
      PREOP => '$(MKPATH) $(DISTVNAME)/GENERATED'
               . ' && $(PERL) "-MPDL::PP qw[PDL::IO::Image PDL::IO::Image $(DISTVNAME)/GENERATED/Image]" Image.pd'
               . ' && $(RM_F) $(DISTVNAME)/GENERATED/*.xs'
               . ' && perldoc -u $(DISTVNAME)/GENERATED/Image.pm | pod2markdown > README.md'
               #. ' && pod2text $(DISTVNAME)/GENERATED/Image.pm > README'
  },
);

sub MY::postamble {
        pdlpp_postamble($package) . <<'END'

README.md:
	$(PERL) "-MPDL::PP qw/PDL::IO::Image PDL::IO::Image TMP/" Image.pd
	perldoc -u TMP.pm | pod2markdown > README.md
	$(RM_F) TMP.pm TMP.xs

END
}
