# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Speech-eSpeak.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Speech::eSpeak') };


my $fail = 0;
foreach my $constname (qw(
	AUDIO_OUTPUT_PLAYBACK AUDIO_OUTPUT_RETRIEVAL AUDIO_OUTPUT_SYNCHRONOUS
	Audio EE_BUFFER_FULL EE_INTERNAL_ERROR EE_OK End Mark N_SPEECH_PARAM
	POS_CHARACTER POS_SENTENCE POS_WORD Retrieval Start espeakCAPITALS
	espeakCHARS_8BIT espeakCHARS_AUTO espeakCHARS_UTF8 espeakCHARS_WCHAR
	espeakEMPHASIS espeakENDPAUSE espeakEVENT_LIST_TERMINATED
	espeakKEEP_NAMEDATA espeakLINELENGTH espeakPHONEMES espeakPITCH
	espeakPUNCTUATION espeakPUNCT_ALL espeakPUNCT_NONE espeakPUNCT_SOME
	espeakRANGE espeakRATE espeakSILENCE espeakSSML espeakVOLUME)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Speech::eSpeak macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

