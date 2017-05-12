use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Ogg::Vorbis::LibVorbis',
    VERSION_FROM      => 'lib/Ogg/Vorbis/LibVorbis.pm', # finds $VERSION
    PREREQ_PM         => {Ogg::LibOgg => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ogg/Vorbis/LibVorbis.pm', # retrieve abstract from module
       AUTHOR         => 'Vigith Maurice <vigith@cpan.org>') : ()),
    LIBS              => ['-logg -lvorbis -lvorbisenc -lvorbisfile', ],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I/usr/lib/include -I/opt/local/include -I/usr/lib',
);

eval { require Ogg::LibOgg };
if ($@) {
  die "Oops, we require Ogg::LibOgg!! $@"
}

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(INITSET NOTOPEN OPENED OV_EBADHEADER OV_EBADLINK
		 OV_EBADPACKET OV_ECTL_IBLOCK_GET OV_ECTL_IBLOCK_SET
		 OV_ECTL_LOWPASS_GET OV_ECTL_LOWPASS_SET
		 OV_ECTL_RATEMANAGE2_GET OV_ECTL_RATEMANAGE2_SET
		 OV_ECTL_RATEMANAGE_AVG OV_ECTL_RATEMANAGE_GET
		 OV_ECTL_RATEMANAGE_HARD OV_ECTL_RATEMANAGE_SET OV_EFAULT
		 OV_EIMPL OV_EINVAL OV_ENOSEEK OV_ENOTAUDIO OV_ENOTVORBIS
		 OV_EOF OV_EREAD OV_EVERSION OV_FALSE OV_HOLE PARTOPEN
		 STREAMSET));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Ogg::Vorbis::LibVorbis',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
