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
        'Alien::FreeImage' => '1.000',
        'Test::Number::Delta' => '1.06',
        'Test::More' => 0,
        'File::Temp' => 0,
  },
  CONFIGURE_REQUIRES => {
        'PDL' => '2.006',
        'Alien::FreeImage' => '1.000',
  },
  META_MERGE   => {
      resources    => {
          repository   => 'https://github.com/kmx/pdl-io-image',
          bugtracker   => 'https://github.com/kmx/pdl-io-image/issues',
      },
  },
  dist => {
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : (TARFLAGS => '--owner=0 --group=0 -cf')),
      PREOP => '$(MKPATH) $(DISTVNAME)/GENERATED'
               . ' && $(PERL) "-MPDL::PP qw[PDL::IO::Image PDL::IO::Image $(DISTVNAME)/GENERATED/Image]" Image.pd'
               . ' && $(RM_F) $(DISTVNAME)/GENERATED/*.xs'
               . ' && perldoc -u $(DISTVNAME)/GENERATED/Image.pm | pod2markdown > README.md'
  },
);

sub MY::postamble {
        my $postamble = pdlpp_postamble($package);
        #hack: https://sourceforge.net/p/pdl/bugs/437/
        $postamble =~ s/-e '.*?PDL::Doc::add_module.*?'/-e "exit if \$\$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(q{PDL::IO::Image}); }; "/s if $^O eq 'MSWin32';
        return $postamble;
}
