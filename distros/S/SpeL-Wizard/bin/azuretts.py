#!/usr/bin/env python3

import os
import sys
import re
import configparser

# check loading of speech sdk
try:
    import azure.cognitiveservices.speech as speechsdk
except ImportError:
    print( "azuretts.py: Error - missing package. Run 'pip install azure-cognitiveservices-speech' to install Microsoft Azure Text-to-speech." )
    sys.exit(1)

#################################
# Process command line arguments
try:
    textfilename, audiofilename, regionenginevoice = sys.argv[1:4]
except ValueError:
    print( f"Usage: {sys.argv[0]} <input_text_file> <output_audio_file> <region:engine:voice>" )
    sys.exit(1)

# determine format from audiofilename
extension = re.sub( r'^.+\.([^\.]+)$', r'\1', audiofilename )
if ( extension == 'wav' ):
    audioformat = speechsdk.SpeechSynthesisOutputFormat.Riff16Khz16BitMonoPcm
elif ( extension == 'ogg' ):
    audioformat = speechsdk.SpeechSynthesisOutputFormat.Ogg16Khz16BitMonoOpus
elif ( extension == 'mp3' ):
    audioformat = speechsdk.SpeechSynthesisOutputFormat.Audio16Khz128KBitRateMonoMp3
else:
    print( f"azuretts.py: Error - unknown audioformat '{extension}'" )
    sys.exit(1)

# parse regionenginevoice
region, engine, voice = regionenginevoice.split( ':' )

#################
# read text file
try:
    with open( textfilename ) as textfile:
        text = textfile.read()
except FileNotFoundError:
    print( f"azuretts.py: Error - cannot open file {textfilename} for reading" )
    sys.exit(1)

#####################
# Setup azure reader

# read speech key
if os.getenv( 'AZURE_TTS_CONFIG' ) is not None:
    configfilename = os.environ['AZURE_TTS_CONFIG']
else:
    configfilename = os.path.join( os.path.expanduser("~"), '.azure', 'tts_config' )
if not os.access( configfilename, os.R_OK ):
    print( f"azuretts.py: Error - cannot read configuration file {configfilename}" )
    sys.exit(1)
parser = configparser.ConfigParser()
parser.read( configfilename )
try:
    tts_key    = parser['default']['tts_key'].strip( '\'"' )
    tts_region = parser['default']['tts_region'].strip( '\'"' )
except KeyError as k:
    print( f"azuretts.py: Error - cannot read desired keys in section 'default'\n" + k )
    sys.exit(1)

# create config object
speech_config = speechsdk.SpeechConfig( subscription = tts_key,
                                        region       = tts_region )
speech_config.speech_synthesis_voice_name = region + '-' + voice + engine
speech_config.set_speech_synthesis_output_format( audioformat )
audio_config = speechsdk.audio.AudioOutputConfig( filename = audiofilename )

# setup synthesizer
speech_synthesizer = speechsdk.SpeechSynthesizer( speech_config = speech_config,
                                                  audio_config  = audio_config )

######
# TTS
speech_synthesis_result = speech_synthesizer.speak_text_async(text).get()

if speech_synthesis_result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
    pass
elif speech_synthesis_result.reason == speechsdk.ResultReason.Canceled:
    cancellation_details = speech_synthesis_result.cancellation_details
    print("azuretts.py: Speech synthesis canceled: {}".format(cancellation_details.reason))
    if cancellation_details.reason == speechsdk.CancellationReason.Error:
        if cancellation_details.error_details:
            print("Error details: {}".format(cancellation_details.error_details))
            print("Did you set the speech resource key and region values?")

