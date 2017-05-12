package Speech::eSpeak;

# use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Speech::eSpeak ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	AUDIO_OUTPUT_PLAYBACK
	AUDIO_OUTPUT_RETRIEVAL
	AUDIO_OUTPUT_SYNCHRONOUS
	EE_BUFFER_FULL
	EE_INTERNAL_ERROR
	EE_OK
	N_SPEECH_PARAM
	POS_CHARACTER
	POS_SENTENCE
	POS_WORD
	espeakCAPITALS
	espeakCHARS_8BIT
	espeakCHARS_AUTO
	espeakCHARS_UTF8
	espeakCHARS_WCHAR
	espeakEMPHASIS
	espeakENDPAUSE
	espeakEVENT_LIST_TERMINATED
	espeakEVENT_WORD
	espeakEVENT_SENTENCE
	espeakEVENT_MARK
	espeakEVENT_PLAY
	espeakEVENT_END
	espeakEVENT_MSG_TERMINATED
	espeakEVENT_PHONEME
	espeakKEEP_NAMEDATA
	espeakLINELENGTH
	espeakPHONEMES
	espeakPITCH
	espeakPUNCTUATION
	espeakPUNCT_ALL
	espeakPUNCT_NONE
	espeakPUNCT_SOME
	espeakRANGE
	espeakRATE
	espeakSILENCE
	espeakSSML
	espeakVOLUME

				   espeak_Initialize
				   espeak_SetSynthCallback
				   espeak_SetUriCallback
				   espeak_Synth
				   espeak_Synth_Mark
				   espeak_Key
				   espeak_Char
				   espeak_SetParameter
				   espeak_GetParameter
				   espeak_SetPunctuationList
				   espeak_SetPhonemeTrace
				   espeak_CompileDictionary
				   espeak_ListVoices
				   espeak_SetVoiceByName
				   espeak_SetVoiceByProperties
				   espeak_GetCurrentVoice
				   espeak_Cancel
				   espeak_IsPlaying
				   espeak_Synchronize
				   espeak_Terminate
				   espeak_Info
	set_male_voice
	set_female_voice
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	AUDIO_OUTPUT_PLAYBACK
	AUDIO_OUTPUT_RETRIEVAL
	AUDIO_OUTPUT_SYNCHRONOUS
	Audio
	EE_BUFFER_FULL
	EE_INTERNAL_ERROR
	EE_OK
	End
	Mark
	N_SPEECH_PARAM
	POS_CHARACTER
	POS_SENTENCE
	POS_WORD
	Retrieval
	Start
	espeakCAPITALS
	espeakCHARS_8BIT
	espeakCHARS_AUTO
	espeakCHARS_UTF8
	espeakCHARS_WCHAR
	espeakEMPHASIS
	espeakENDPAUSE
	espeakEVENT_LIST_TERMINATED
        espeakEVENT_WORD
        espeakEVENT_SENTENCE
        espeakEVENT_MARK
        espeakEVENT_PLAY
        espeakEVENT_END
        espeakEVENT_MSG_TERMINATED
        espeakEVENT_PHONEME
	espeakKEEP_NAMEDATA
	espeakLINELENGTH
	espeakPHONEMES
	espeakPITCH
	espeakPUNCTUATION
	espeakPUNCT_ALL
	espeakPUNCT_NONE
	espeakPUNCT_SOME
	espeakRANGE
	espeakRATE
	espeakSILENCE
	espeakSSML
	espeakVOLUME
);

our $VERSION = '0.4';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Speech::eSpeak::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Speech::eSpeak', $VERSION);

# Preloaded methods go here.

sub new {
  my %args = @_;
  $args{datadir} ||= "/usr/share";

  espeak_Initialize(AUDIO_OUTPUT_PLAYBACK(), 0, $args{datadir}, 0);

  my $self = {};
  bless $self, __PACKAGE__;
  return $self;
}

sub DESTROY {
  espeak_Synchronize();
}

sub speak {
  my ($self, $text) = @_;

  if (defined $text) {
    espeak_Synth($text, do { use bytes; length($text) + 1 }, 0, POS_CHARACTER(), 0, espeakCHARS_AUTO() | espeakPHONEMES() | espeakENDPAUSE(), 0, 0);
  } else {
    carp('speaking text undefined!');
  }
}

sub stop {
  espeak_Cancel();
}

sub synchronize {
  espeak_Synchronize();
}

sub is_playing {
  return espeak_IsPlaying();
}

sub language {
  my ($self, $lang) = @_;

  if ($lang) {
    return espeak_SetVoiceByName($lang);
  } else {
    my $voice = espeak_GetCurrentVoice();
    return $voice->{identifier};
  }
}

sub pitch {
  my ($self, $pitch) = @_;

  if (defined $pitch) {
    espeak_SetParameter(espeakPITCH(), $pitch, 0);
  } else {
    espeak_GetParameter(espeakPITCH(), 1);
  }
}

sub range {
  my ($self, $range) = @_;
  if (defined $range) {
    espeak_SetParameter(espeakRANGE(), $range, 0);
  } else {
    espeak_GetParameter(espeakRANGE(), 1);
  }
}

sub rate {
  my ($self, $rate) = @_;
  if ($rate) {
    espeak_SetParameter(espeakRATE(), $rate, 0);
  } else {
    espeak_GetParameter(espeakRATE(), 1);
  }
}

sub volume {
  my ($self, $volume) = @_;
  if (defined $volume) {
    espeak_SetParameter(espeakVOLUME(), $volume, 0);
  } else {
    espeak_GetParameter(espeakVOLUME(), 1);
  }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Speech::eSpeak - Perl extension for eSpeak text to speech

=head1 SYNOPSIS

  use Speech::eSpeak;
  $speaker = Speech::eSpeak::new();
  $speaker->speak('hello world');

=head1 DESCRIPTION

eSpeak is a compact open source software speech synthesizer for English and other languages. It's written by Jonathan Duddington. You can find more information from L<http://espeak.sourceforge.net>. This package is direct binding for eSpeak, which is based on the API (version 6) of speak_lib.h.

=head2 EXPORT

None by default.

=head2 Exportable constants

  AUDIO_OUTPUT_PLAYBACK
  AUDIO_OUTPUT_RETRIEVAL
  AUDIO_OUTPUT_SYNCHRONOUS
  EE_BUFFER_FULL
  EE_INTERNAL_ERROR
  EE_OK
  N_SPEECH_PARAM
  POS_CHARACTER
  POS_SENTENCE
  POS_WORD
  espeakCAPITALS
  espeakCHARS_8BIT
  espeakCHARS_AUTO
  espeakCHARS_UTF8
  espeakCHARS_WCHAR
  espeakEMPHASIS
  espeakENDPAUSE
  espeakEVENT_LIST_TERMINATED
  espeakEVENT_WORD
  espeakEVENT_SENTENCE
  espeakEVENT_MARK
  espeakEVENT_PLAY
  espeakEVENT_END
  espeakEVENT_MSG_TERMINATED
  espeakEVENT_PHONEME
  espeakKEEP_NAMEDATA
  espeakLINELENGTH
  espeakPHONEMES
  espeakPITCH
  espeakPUNCTUATION
  espeakPUNCT_ALL
  espeakPUNCT_NONE
  espeakPUNCT_SOME
  espeakRANGE
  espeakRATE
  espeakSILENCE
  espeakSSML
  espeakVOLUME

=head1 FUNCTIONS(simplified)

=head2 new({ datadir => '/opt/espeak' })

Initialize speaker. Only one object should be created. Or unexpected error will occured.
Pass a hashref with key datadir pointing to a directory of where to find the
vendor specific '/espeak-data' data dir. Defaults to /usr/share.

=head2 speak($text)

Speak $text.

=head2 synchronize()

It won't return until all speech in the buffer finished.

=head2 stop()

Stop speaking.

=head2 is_playing()

Return whether the speak is playing. 1 for playing, 0 otherwise.

=head2 language($language)

If $language is specified, it is set as current language. Or current value is returned.

Return:

=over 4

=item

Current language if parameter $language is not specified.

=item

EE_OK: operation achieved

=item

EE_BUFFER_FULL: the command can not be buffered; you may try after a while to call the function again.

=item

EE_INTERNAL_ERROR.

=back

=head2 pitch($pitch)

If $pitch is specified, it is set as base pitch. Or current pitch is returned. The range of pitch is 0 to 100. 50 is normal.

=head2 range($range)

If $range is specified, it is set as pitch range. Or current range is returned. The value of range is from 0 to 100. 0 for monotone and 50 is normal.

=head2 rate($rate)

If $rage is specified, it is set as the speaking speed in word per minute. Or current rate is returned. 170 is the initial value.

=head2 volume($volume)

If $volume is specified, it is set as the volume. Or current volume is returned. The value is from 0 to 100. 0 for silence.

=head1 FUNCTIONS(standard)

=head2 espeak_SetSynthCallback($callback)

Not implemented yet.

=head2 espeak_SetUriCallback($callback)

Not implemented yet.

=head2 espeak_Synth($text, $size, $position, $position_type, $end_position, $flags, $unique_identifier, $user_data)

Synthesize speech for the specified text.

$text: The text to be spoken.

$size: Equal to (or greatrer than) the size of the text data, in bytes.  This is used in order to allocate internal storage space for the text.  This value is not used for AUDIO_OUTPUT_SYNCHRONOUS mode. In normal case, $size = length($text) + 1;

$position:  The position in the text where speaking starts. Zero indicates speak from the start of the text.

$position_type:  Determines whether "position" is a number of characters, words, or sentences. SEE L</"espeak_POSITION_TYPE">

$end_position:  If set, this gives a character position at which speaking will stop.  A value of zero indicates no end position.

$flags:  These may be OR'd together:

Type of character codes, one of:

=over 4

=item

espeakCHARS_UTF8     UTF8 encoding

=item

espeakCHARS_8BIT     The 8 bit ISO-8859 character set for the particular language.

=item

espeakCHARS_AUTO     8 bit or UTF8  (this is the default)

=item

espeakCHARS_WCHAR    Wide characters (wchar_t)

=back

espeakSSML   Elements within < > are treated as SSML elements, or if not recognised are ignored.

espeakPHONEMES  Text within [[ ]] is treated as phonemes codes (in espeak's Hirschenbaum encoding).

espeakENDPAUSE  If set then a sentence pause is added at the end of the text.  If not set then this pause is suppressed.

$unique_identifier: message identifier; helpful for identifying later data supplied to the callback.

$user_data: pointer which will be passed to the callback function.

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_BUFFER_FULL: the command can not be buffered; you may try after a while to call the function again.

=item

EE_INTERNAL_ERROR.

=back

=head2 espeak_Synth_Mark($text, $size, $index_mark, $end_position, $flags, $unique_identifier, $user_data)

Synthesize speech for the specified text. Similar to espeak_Synth() but the start position is specified by the name of a <mark> element in the text.

$index_mark:  The "name" attribute of a <mark> element within the text which specified the point at which synthesis starts.  UTF8 string.

For the other parameters, see espeak_Synth()

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_BUFFER_FULL: the command can not be buffered; you may try after a while to call the function again.

=item

EE_INTERNAL_ERROR.

=back

=head2 espeak_Key($key_name)

Speak the name of a keyboard key. Currently this just speaks the "key_name" as given

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_BUFFER_FULL: the command can not be buffered; you may try after a while to call the function again.

=item

EE_INTERNAL_ERROR.

=back

=head2 espeak_Char($character)

Speak the name of the given character

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_BUFFER_FULL: the command can not be buffered; you may try after a while to call the function again.

=item

EE_INTERNAL_ERROR.

=back

=head2 espeak_SetParameter($parameter, $value, $relative)

Sets the value of the specified parameter.

relative=0   Sets the absolute value of the parameter.

relative=1   Sets a relative value of the parameter.

parameter:

=over 4

=item

espeakRATE:    speaking speed in word per minute.

=item

espeakVOLUME:  volume in range 0-100    0=silence

=item

espeakPITCH:   base pitch, range 0-100.  50=normal

=item

espeakRANGE:   pitch range, range 0-100. 0-monotone, 50=normal

=item

espeakPUNCTUATION:  which punctuation characters to announce: value in espeak_PUNCT_TYPE (none, all, some), see espeak_GetParameter() to specify which characters are announced.

=item

espeakCAPITALS: announce capital letters by:

0=none,

1=sound icon,

2=spelling,

3 or higher, by raising pitch.  This values gives the amount in Hz by which the pitch of a word raised to indicate it has a capital letter.

=back

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_BUFFER_FULL: the command can not be buffered; you may try after a while to call the function again.

=item

EE_INTERNAL_ERROR.

=back

=head2 espeak_GetParameter($parameter, $current)

$current=0  Returns the default value of the specified parameter.

$current=1  Returns the current value of the specified parameter, as set by SetParameter()

Example:

  print 'rate: ', espeak_GetParameter(espeakRATE, 1), "\n";
  print 'volume: ', espeak_GetParameter(espeakVOLUME, 1), "\n";
  print 'pitch: ', espeak_GetParameter(espeakPITCH, 1), "\n";
  print 'range: ', espeak_GetParameter(espeakRANGE, 1), "\n";
  print 'punctuation: ', espeak_GetParameter(espeakPUNCTUATION, 1), "\n";
  print 'capitals: ', espeak_GetParameter(espeakCAPITALS, 1), "\n";
  espeak_SetParameter(espeakPITCH, 100, 0);
  espeak_SetParameter(espeakRANGE, 100, 0);

=head2 espeak_SetPunctuationList($punclist)

Specified a list of punctuation characters whose names are to be spoken when the value of the Punctuation parameter is set to "some".

$punctlist:  A list of character codes, terminated by a zero character.

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_BUFFER_FULL: the command can not be buffered; you may try after a while to call the function again.

=item

EE_INTERNAL_ERROR.

=back

=head2 espeak_SetPhonemeTrace($value, $stream)

Controls the output of phoneme symbols for the text

$value=0  No phoneme output (default)

$value=1  Output the translated phoneme symbols for the text

$value=2  as (1), but also output a trace of how the translation was done (matching rules and list entries)

$stream   output stream for the phoneme symbols (and trace).  If stream=NULL then it uses stdout.

=head2 espeak_CompileDictionary($path, $log)

Compile pronunciation dictionary for a language which corresponds to the currently selected voice.  The required voice should be selected before calling this function.

$path:  The directory which contains the language's '_rules' and '_list' files. 'path' should end with a path separator character ('/').

$log:   Stream for error reports and statistics information. If log=NULL then stderr will be used.

=head2 espeak_ListVoices($voice_spec)

Reads the voice files from espeak-data/voices and creates an array of espeak_VOICE pointers. The list is terminated by a NULL pointer

If voice_spec is NULL then all voices are listed.

If voice spec is give, then only the voices which are compatible with the voice_spec are listed, and they are listed in preference order.

Example:

  # list all voices
  my $voices = espeak_ListVoices('');
  foreach my $voice_spec (@{$voices}) {
    foreach (keys %{$voice_spec}) {
      print $voice_spec->{$_}, ' ';
    }
    print "\n";
  }

=head2 espeak_SetVoiceByName($name)

Searches for a voice with a matching "name" field.  Language is not considered. "name" is a UTF8 string. For example, "en" for English, "de" for German, "zhy" for Cantonese. It could be added a variant too. For example, "fr+f2" for female voice variant of French, "it+m4" for male voice variant of Italian.

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_BUFFER_FULL: the command can not be buffered; you may try after a while to call the function again.

=item

EE_INTERNAL_ERROR.

=back

Example:

  use Speech::eSpeak ':all';
  espeak_Initialize(AUDIO_OUTPUT_PLAYBACK, 0, '', 0);
  espeak_SetVoiceByName("de");
  my $synth_flags = espeakCHARS_AUTO | espeakPHONEMES | espeakENDPAUSE;
  my $text = 'Sprechen Sie Deutsch?';
  espeak_Synth($text, length($text) + 1, 0, POS_CHARACTER, 0, $synth_flags, 0, 0);
  espeak_Synchronize();

=head2 espeak_SetVoiceByProperties($voice_spec)

Example:

  my $spec = {name => "german",
              languages => "",
              identifier => "",
              gender => 2,
              age => 0,
              variant => 0
             };
  espeak_SetVoiceByProperties($spec);

=head2 espeak_GetCurrentVoice()

Returns the espeak_VOICE data for the currently selected voice.

This is not affected by temporary voice changes caused by SSML elements such as <voice> and <s>

Example:

  my $voice = espeak_GetCurrentVoice();
  print 'name: ', $voice->{name}, "\n";
  print 'languages: ', $voice->{languages}, "\n";
  print 'identifier: ', $voice->{identifier}, "\n";
  print 'gender: ', $voice->{gender}, "\n";
  print 'age: ', $voice->{age}, "\n";
  print 'variant: ', $voice->{variant}, "\n";

=head2 espeak_Cancel()

Stop immediately synthesis and audio output of the current text. When this function returns, the audio output is fully stopped and the synthesizer is ready to synthesize a new message.

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_INTERNAL_ERROR.

=back

=head2 epseak_IsPlaying()

Returns 1 if audio is played, 0 otherwise.

=head2 espeak_Synchronize()

This function returns when all data have been spoken.

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_INTERNAL_ERROR.

=back

=head2 espeak_Terminate()

The last function to be called.

Return:

=over 4

=item

EE_OK: operation achieved

=item

EE_INTERNAL_ERROR.

=back

=head2 espeak_Info()

Returns the version number string.

The parameter is for future use, and should be set to NULL.

=head1 TYPES

=head2 espeak_POSITION_TYPE

   typedef enum {
        POS_CHARACTER = 1,
        POS_WORD,
        POS_SENTENCE
   } espeak_POSITION_TYPE;

=head2 espeak_AUDIO_OUTPUT

   typedef enum {
        /* PLAYBACK mode: plays the audio data, supplies events to the calling program*/
        AUDIO_OUTPUT_PLAYBACK,

        /* RETRIEVAL mode: supplies audio data and events to the calling program */
        AUDIO_OUTPUT_RETRIEVAL,

        /* SYNCHRONOUS mode: as RETRIEVAL but doesn't return until synthesis is completed */
        AUDIO_OUTPUT_SYNCHRONOUS,

        /* Synchronous playback */
        AUDIO_OUTPUT_SYNCH_PLAYBACK

   } espeak_AUDIO_OUTPUT;

=head2 espeak_ERROR

   typedef enum {
        EE_OK=0,
        EE_INTERNAL_ERROR=-1,
        EE_BUFFER_FULL=1,
        EE_NOT_FOUND=2
   } espeak_ERROR;

=head2 espeak_PARAMETER

   typedef enum {
        espeakSILENCE=0, /* internal use */
        espeakRATE,
        espeakVOLUME,
        espeakPITCH,
        espeakRANGE,
        espeakPUNCTUATION,
        espeakCAPITALS,
        espeakEMPHASIS,   /* internal use */
        espeakLINELENGTH, /* internal use */
        espeakVOICETYPE,  // internal, 1=mbrola
        N_SPEECH_PARAM    /* last enum */
   } espeak_PARAMETER;

=head2 espeak_PUNCT_TYPE

   typedef enum {
        espeakPUNCT_NONE=0,
        espeakPUNCT_ALL=1,
        espeakPUNCT_SOME=2
   } espeak_PUNCT_TYPE;

=head2 espeak_VOICE

   typedef struct {
        char *name;            // a given name for this voice. UTF8 string.
        char *languages;       // list of pairs of (byte) priority + (string) language (and dialect qualifier)
        char *identifier;      // the filename for this voice within espeak-data/voices
        unsigned char gender;  // 0=none 1=male, 2=female,
        unsigned char age;     // 0=not specified, or age in years
        unsigned char variant; // only used when passed as a parameter to espeak_SetVoiceByProperties
        unsigned char xx1;     // for internal use
        int score;       // for internal use
        void *spare;     // for internal use
   } espeak_VOICE;

   Note: The espeak_VOICE structure is used for two purposes:
   1. To return the details of the available voices.
   2. As a parameter to  espeak_SetVoiceByProperties() in order to specify selection criteria.

=head1 EXAMPLE 1

  use strict;
  use Speech::eSpeak ':all';

  espeak_Initialize(AUDIO_OUTPUT_PLAYBACK, 0, '', 0);

  my $synth_flags = espeakCHARS_AUTO | espeakPHONEMES | espeakENDPAUSE;
  espeak_Synth('hello world', 12, 0, POS_CHARACTER, 0, $synth_flags, 0, 0);

  espeak_Cancel() if espeak_IsPlaying;

  my $text = 'hello <mark name="newstart"> world';
  espeak_Synth_Mark($text, length($text) + 1, 'newstart', 0, espeakSSML, 0, 0);

  print 'rate: ', espeak_GetParameter(espeakRATE, 1), "\n";
  print 'volume: ', espeak_GetParameter(espeakVOLUME, 1), "\n";
  print 'pitch: ', espeak_GetParameter(espeakPITCH, 1), "\n";
  print 'range: ', espeak_GetParameter(espeakRANGE, 1), "\n";
  print 'punctuation: ', espeak_GetParameter(espeakPUNCTUATION, 1), "\n";
  print 'capitals: ', espeak_GetParameter(espeakCAPITALS, 1), "\n";

  espeak_SetParameter(espeakPITCH, 100, 0);
  espeak_SetParameter(espeakRANGE, 100, 0);

  espeak_SetPhonemeTrace(2, \*STDOUT);

  espeak_Synchronize();

  print 'version: ', espeak_Info(0), "\n";

  espeak_Terminate();

=head1 EXAMPLE 2

  use strict;
  use Speech::eSpeak ':all';
  espeak_Initialize(AUDIO_OUTPUT_PLAYBACK, 0, '', 0);
  my $synth_flags = espeakCHARS_AUTO | espeakPHONEMES | espeakENDPAUSE;
  my $s = 'Hello Debbie';
  espeak_Synth($s, length($s) + 1, 0, POS_CHARACTER, 0, $synth_flags, 0, 0);
  # set a female variant voice of English.
  # We can specified the variant from 'm1' to 'm4', 'f1' to 'f4', 'croak' and 'wisper'.
  # There maybe new variants in future. Just refer to directory espeak-data/voices/!v/
  espeak_SetVoiceByName(en+f2);
  $s = 'Hello Cameron';
  espeak_Synth($s, length($s) + 1, 0, POS_CHARACTER, 0, $synth_flags, 0, 0);
  espeak_Synchronize();

=head1 EXAMPLE 3

  use strict;
  use Speech::eSpeak ':all';
  espeak_Initialize(AUDIO_OUTPUT_PLAYBACK, 0, '', 0);
  my $synth_flags = espeakCHARS_AUTO | espeakPHONEMES | espeakENDPAUSE;
  espeak_SetVoiceByName("zhy");
  my $s = 'ä½ å¥½';
  espeak_Synth($s, length($s) + 1, 0, POS_CHARACTER, 0, $synth_flags, 0, 0);
  my $spec = {name => "german",
	      gender => 2,
             };
  espeak_SetVoiceByProperties($spec);
  $s = 'Guten Tag!';
  espeak_Synth($s, length($s) + 1, 0, POS_CHARACTER, 0, $synth_flags, 0, 0);
  espeak_Synchronize();

=head1 EXAMPLE 4

  use Speech::eSpeak;

  $speaker = Speech::eSpeak::new();
  $speaker->speak('hello world');
  $speaker->pitch(100);
  $speaker->speak('hello world');
  $speaker->range(100);
  $speaker->speak('hello world');
  $speaker->synchronize();
  $speaker->rate($speaker->rate / 2);
  $speaker->speak('Do you mean I am too talky?');
  sleep(1);
  $speaker->stop() if ($speaker->is_playing);

=head1 SEE ALSO

eSpeak Documents, speak_lib.h, L<http://espeak.sourceforge.net>, L<eGuideDog::Festival>

=head1 AUTHOR

Cameron Wong, E<lt>hgneng at yahoo.com.cnE<gt>, L<http://www.eguidedog.net>

=head1 CONTRIBUTORS

Paulo Edgar Castro E<lt>pauloedgarcastro at gmail.comE<gt>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Speech::eSpeak

You can also look for information at:

L<http://search.cpan.org/dist/Speech-eSpeak>

=head1 ACKNOWLEDGEMENT

eSpeak TTS is designed by Jonathan Duddington. L<http://espeak.sourceforge.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2012 by Cameron Wong

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.


=cut
