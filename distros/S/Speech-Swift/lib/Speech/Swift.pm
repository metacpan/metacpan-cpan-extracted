# 
#  Speech::Swift - Swift Text-To-Speech for PERL
# 
#  Copyright (c) 2011, Mike Pultz <mike@mikepultz.com>.
#  All rights reserved.
# 
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
# 
#   #  Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
# 
#   #  Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in
#      the documentation and/or other materials provided with the
#      distribution.
# 
#   #  Neither the name of Mike Pultz nor the names of his contributors
#      may be used to endorse or promote products derived from this
#      software without specific prior written permission.
# 
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRIC
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
#  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
# 
#  @author      Mike Pultz <mike@mikepultz.com>
#  @copyright   2011 Mike Pultz <mike@mikepultz.com>
#  @license     http://www.opensource.org/licenses/bsd-license.php  BSD License
#  @version     SVN $id$
# 
#

package Speech::Swift;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '1.0';

use constant
{
	AUDIO_ENCODING_PCM16 	=> 1,
	AUDIO_ENCODING_PCM8 	=> 2,
	AUDIO_ENCODING_ULAW 	=> 3,
	AUDIO_ENCODING_ALAW 	=> 4
};

require XSLoader;   
XSLoader::load('Speech::Swift', $VERSION);

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Speech::Swift - Perl extension for the Cepstral Text-to-Speech Engine

=head1 SYNOPSIS

use Speech::Swift;

=head1 DESCRIPTION

=head2 ENGINE FUNCTIONS

=over

=item swift_engine_open($params)

opens a new swift engine instance. $params is a swift_params object returned by swift_params_new().

returns a new swift_engine instance.

$engine = swift_engine_open($params);

=item swift_engine_close($engine)

closes a swift engine instance. $engine is swift_engine instance returned by swift_engine_open()

swift_engine_close($engine);

=back

=head2 PORT FUNCTIONS

=over

=item swift_port_open($engine, $params)

opens a new swift port. $engine is swift_engine instance returned by swift_engine_open(). $params 
is a swift_params object returned by swift_params_new().

$port = swift_port_open($engine, $params);

=item swift_port_close($port)

closes a swift port. $port is a swift_port object opened by swift_port_open();

swift_port_close($port);

=item swift_port_language_encoding($port)

returns the current language encoding used by this port. $port is a swift_port object

$encoding = swift_port_language_encoding($port);

$encoding can be "pcm16", "pcm8", "ulaw" or "alaw"

=item swift_port_load_sfx($port, $sfx_file)

load a sound effects file to use on a port. $port is a swift_port object to load the sound effects on,
$sfx_file is the path to a sound effects file.

$res = swift_port_load_sfx($port, $sfx_file);

returns a swift_result object.

=item swift_port_get_wave(_port, _text)

=back

=head2 PARAMS FUNCTIONS

=over

=item swift_params_new()

creates and returns a new swift_params object.

$params = swift_params_new();

=item swift_params_set_string($params, $name, $value)

=item swift_params_set_int($params, $name, $value)

sets a parameter value on the params object. $params is a swift_params object. $name is the text name of the
param value to set. $value is either a string or int.

$name can be:

=over

=item C<audio/encoding>	- encoding type, can be "pcm16", "pcm8", "ulaw" or "alaw"

=item C<audio/channels>	- number of channels, can be 1 or 2

=item C<audio/deadair>	- strip dead air from the audio, 1 or 0

=back

=back

=head2 VOICE FUNCTIONS

=over

=item swift_port_set_voice($port, $voice)

sets a voice to use on a given port. $port is the swift_port to set the voice on. $voice
is the swift_voice object to assign to this port.

$res = swift_port_set_voice($port, $voice);

returns a swift_result object.

=item swift_port_set_voice_by_name($port, $voice_name)

sets a voice to use on a given port. $port is the swift_port to set the voice on. $voice_name 
is the name of a swift voice to assign to this port.

$voice = swift_port_set_voice_by_name($port, "Allison");

returns a swift_voice object.

=item swift_port_set_voice_from_dir($port, $dir)

sets a voice to use on a given port. $port is the swift_port to set the voice on. $dir 
is a directory that contains the voice to use.

$voice = swift_port_set_voice_from_dir($port, "/dir/to/voice");

returns a swift_voice object.

=item swift_port_get_current_voice($port)

returns a swift_voice object for the current voice assigned to port $port.

$voice = swift_port_get_current_voice($port);

=item swift_voice_get_attribute($voice, $name)

returns the value for the given attribute name, from the swift_voice object $voice.

$value = swift_voice_get_attribute($voice, "speaker/name");

attribute names can be one of the following:

=over

=item C<id>

=item C<name>

=item C<path>

=item C<version>

=item C<buildstamp>

=item C<sample-rate>

=item C<license/key>

=item C<language/tag>

=item C<language/name>

=item C<language/version>

=item C<lexicon/name>

=item C<lexicon/version>

=item C<speaker/name>

=item C<speaker/gender>

=item C<speaker/age>

=back

=item swift_port_find_first_voice($port, $search_criteria, $order_criteria)

finds the first available voice on the swift_port $port. $search_criteria and $order_criteria are
attribute names to limit the voice list. see swift_voice_get_attribute() for the list of available
attributes.

$voice = swift_port_find_first_voice($port, "speaker/gender=male", "speaker/name");

returns a swift_voice object.

=item swift_port_find_next_voice($port)

returns the next voice in the search list after a call to swift_port_find_first_voice(). $port is
a swift_port object.

$voice = swift_port_find_next_voice($port);

returns a swift_voice object.

=item swift_port_rewind_voices($port)

rewinds the search results after a call to swift_port_find_first_voice(). $port is swift_port object.

$voice = swift_port_rewind_voices($port);

returns a swift_voice object.

=back

=head2 WAVEFORM FUNCTIONS

=over

=item swift_waveform_new()

creates and returns a new waveform object.

$wave = swift_waveform_new();

returns a swift_waveform object.

=item swift_waveform_save($wave, $filename, $format)

saves a waveform to a file. $wave is a swift_waveform object. $filename is the file name to write the
waveform to. $format is the format of the format to save the wav as.

$res = swift_waveform_save($wave, "out.wav", "riff");

returns a swift_result object.

format can be one of:

=over

=item C<riff>   - Microsoft RIFF (WAV) file

=item C<snd>    - Sun/NeXT .au (SND) format.

=item C<raw>    - unheadered audio data, native byte order

=item C<le>     - unheadered audio data, little-endian (LSB first)

=item C<be>     - unheadered audio data, big-endian (MSB first)

=back

=item swift_waveform_get_sps($wave)

returns the sample rate of the given swift_waveform object $wave

$sample_rate = swift_waveform_get_sps($wave);

=item swift_waveform_get_encoding($wave)

returns the encoding of the given swift_waveform object $wave

$encoding = swift_waveform_get_encoding($wave);

$encoding can be one of can be "pcm16", "pcm8", "ulaw" or "alaw".

=item swift_waveform_get_channels($wave)

returns the channels setting for the given swift_waveform $wave

$channels = swift_waveform_get_channels($wave);

$channels will be 1 or 2.

=item swift_waveform_resample($wave, $new_sps)

resample the given swift_waveform object $wave, to the given sample rate $new_sps.

$res = swift_waveform_resample($wave, 8000);

returns a swift_result object.

=item swift_waveform_convert($wave, $encoding)

changes the encoding of the given swift_waveform object $wave, to the given encoding
type $encoding. $encoding can be one of can be "pcm16", "pcm8", "ulaw" or "alaw".

$res = swift_waveform_convert($wave, $encoding);

returns a swift_result object.

=item swift_waveform_set_channels($wave, $channels)

changes the given swift_waveform object $wave, to the number of channels specified
by $channels. $channels can be either 1 or 2.

$res = swift_waveform_set_channels($wave, $channels);

returns a swift_result object.

=item swift_waveform_get_samples($wave)

returns the raw audio samples for the given swift_waveform object $wave.

@samples = swift_waveform_get_samples($wave);

the raw audio is returned as a array of 16bit samples. the wav header isn't included.

=back

=head2 ERROR HANDLING

=over

=item swift_failed($result)

returns 1 or 0 if the given swift_result object is failed.

=item swift_strerror($result)

returns the error message for the given swift_result object

=back

=head1 DEPENDENCIES

Cepstral Text-to-Speech engine, libswift.so

=head1 SEE ALSO

Cepstral - http://cepstral.com/

=head1 AUTHOR

Mike Pultz <mike@mikepultz.com>

=head1 LICENCE AND COPYRIGHT
    
Copyright (c) 2011, Mike Pultz <mike@mikepultz.com>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See perlartistic.

=head1 DISCLAIMER OF WARRANTY
    
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
