# use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Speech::eSpeak',
    VERSION_FROM      => 'lib/Speech/eSpeak.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Speech/eSpeak.pm', # retrieve abstract from module
       AUTHOR         => 'Cameron Wong<hgneng@yahoo.com.cn>') : ()),
    LIBS              => ['-lespeak'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(AUDIO_OUTPUT_PLAYBACK AUDIO_OUTPUT_RETRIEVAL
		 AUDIO_OUTPUT_SYNCHRONOUS Audio EE_BUFFER_FULL
		 EE_INTERNAL_ERROR EE_OK End Mark N_SPEECH_PARAM POS_CHARACTER
		 POS_SENTENCE POS_WORD Retrieval Start espeakCAPITALS
		 espeakCHARS_8BIT espeakCHARS_AUTO espeakCHARS_UTF8
		 espeakCHARS_WCHAR espeakEMPHASIS espeakENDPAUSE
		 espeakEVENT_LIST_TERMINATED espeakKEEP_NAMEDATA
		 espeakLINELENGTH espeakPHONEMES espeakPITCH espeakPUNCTUATION
		 espeakPUNCT_ALL espeakPUNCT_NONE espeakPUNCT_SOME espeakRANGE
		 espeakRATE espeakSILENCE espeakSSML espeakVOLUME));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Speech::eSpeak',
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
