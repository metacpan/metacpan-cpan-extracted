use 5.008000;
use ExtUtils::MakeMaker;



WriteMakefile(
    NAME              => 'Ogg::Theora::LibTheora',
    VERSION_FROM      => 'lib/Ogg/Theora/LibTheora.pm',
    PREREQ_PM         => {Ogg::LibOgg => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ogg/Theora/LibTheora.pm', # retrieve abstract from module
       AUTHOR         => 'Vigith Maurice <vigith@cpan.org>') : ()),
    LIBS              => ['-logg -ltheora -ltheoraenc -ltheoradec', ],
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
  my @names = (qw(OC_BADHEADER OC_BADPACKET OC_CS_ITU_REC_470BG
		 OC_CS_ITU_REC_470M OC_CS_NSPACES OC_CS_UNSPECIFIED OC_DISABLED
		 OC_DUPFRAME OC_EINVAL OC_FAULT OC_IMPL OC_NEWPACKET
		 OC_NOTFORMAT OC_PF_420 OC_PF_422 OC_PF_444 OC_PF_RSVD
		 OC_VERSION TH_CS_ITU_REC_470BG TH_CS_ITU_REC_470M
		 TH_CS_NSPACES TH_CS_UNSPECIFIED TH_DECCTL_GET_PPLEVEL_MAX
		 TH_DECCTL_SET_GRANPOS TH_DECCTL_SET_PPLEVEL
		 TH_DECCTL_SET_STRIPE_CB TH_DECCTL_SET_TELEMETRY_BITS
		 TH_DECCTL_SET_TELEMETRY_MBMODE TH_DECCTL_SET_TELEMETRY_MV
		 TH_DECCTL_SET_TELEMETRY_QI TH_DUPFRAME TH_EBADHEADER
		 TH_EBADPACKET TH_EFAULT TH_EIMPL TH_EINVAL TH_ENCCTL_2PASS_IN
		 TH_ENCCTL_2PASS_OUT TH_ENCCTL_GET_SPLEVEL
		 TH_ENCCTL_GET_SPLEVEL_MAX TH_ENCCTL_SET_BITRATE
		 TH_ENCCTL_SET_DUP_COUNT TH_ENCCTL_SET_HUFFMAN_CODES
		 TH_ENCCTL_SET_KEYFRAME_FREQUENCY_FORCE TH_ENCCTL_SET_QUALITY
		 TH_ENCCTL_SET_QUANT_PARAMS TH_ENCCTL_SET_RATE_BUFFER
		 TH_ENCCTL_SET_RATE_FLAGS TH_ENCCTL_SET_SPLEVEL
		 TH_ENCCTL_SET_VP3_COMPATIBLE TH_ENOTFORMAT TH_EVERSION
		 TH_NDCT_TOKENS TH_NHUFFMAN_TABLES TH_PF_420 TH_PF_422
		 TH_PF_444 TH_PF_NFORMATS TH_PF_RSVD TH_RATECTL_CAP_OVERFLOW
		 TH_RATECTL_CAP_UNDERFLOW TH_RATECTL_DROP_FRAMES));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Ogg::Theora::LibTheora',
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
