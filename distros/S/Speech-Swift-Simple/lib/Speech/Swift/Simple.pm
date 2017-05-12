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

package Speech::Swift::Simple;

use 5.010000;
use strict;
use warnings;
use Carp;

use Speech::Swift;
require Speech::Swift::Simple::Wav;
require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '1.1';

sub new
{
	my ($_class, %_conf) = @_;
	my %values = ();

	#
	# create the params object
	#
	my $params = Speech::Swift::swift_params_new()
		or croak("failed to initialize Swift params.");

	if (defined($_conf{encoding}))
	{
		if ($_conf{encoding} == Speech::Swift::AUDIO_ENCODING_PCM16)
		{
			Speech::Swift::swift_params_set_string($params, "audio/encoding", "pcm16");
		} elsif ($_conf{encoding} == Speech::Swift::AUDIO_ENCODING_PCM8)
		{
			Speech::Swift::swift_params_set_string($params, "audio/encoding", "pcm8");
		} elsif ($_conf{encoding} == Speech::Swift::AUDIO_ENCODING_ULAW)
		{
			Speech::Swift::swift_params_set_string($params, "audio/encoding", "ulaw");
		} elsif ($_conf{encoding} == Speech::Swift::AUDIO_ENCODING_ALAW)
		{
			Speech::Swift::swift_params_set_string($params, "audio/encoding", "alaw");
		} else
		{
			croak("Speech::Swift::Simple: invalid encoding type: " . $_conf{encoding});
		}
	} else
	{
		Speech::Swift::swift_params_set_string($params, "audio/encoding", "pcm16");
	}
	if (defined($_conf{channels}))
	{
		if ( ($_conf{channels} == 1) || ($_conf{channels} == 2) )
		{
			Speech::Swift::swift_params_set_int($params, "audio/channels", $_conf{channels});
		} else
		{
			croak("Speech::Swift::Simple: channel setting must be 1 or 2");
		}
	} else
	{
		Speech::Swift::swift_params_set_int($params, "audio/channels", 1);
	}
	if (defined($_conf{deadair}))
	{
		if ( ($_conf{deadair} == 0) || ($_conf{deadair} == 1) )
		{
			Speech::Swift::swift_params_set_int($params, "audio/deadair", $_conf{deadair});
		} else
		{
			croak("Speech::Swift::Simple: deadair value must be 1 or 0");	
		}
	} else
	{
		Speech::Swift::swift_params_set_int($params, "audio/deadair", 0);
	}
	
	#
	# create the swift engine and port
	#
	my $engine = Speech::Swift::swift_engine_open($params)
		or croak("failed to initialize Swift engine.");

	my $port = Speech::Swift::swift_port_open($engine, $params)
		or croak("failed to initialize Swift port.");

	#
	# store the engine, params and port objects
	#
	$values{engine}	= $engine;
	$values{params} = $params;
	$values{port}	= $port;

	return bless({%values}, $_class);
}
sub DESTROY
{
	my ($_self) = @_;

	if ($_self->{port})
	{
		Speech::Swift::swift_port_close($_self->{port});
	}
	if ($_self->{engine})
	{
		Speech::Swift::swift_engine_close($_self->{engine});
	}
}
sub set_voice
{
	my ($_self, $_voice) = @_;

	if (!$_self->{port})
	{
		croak("invalid swift port defined");
	}

	#
	# lookup the voice
	#
	my $voice = Speech::Swift::swift_port_find_first_voice($_self->{port}, "speaker/name=" . $_voice, "");
	if (!$voice)
	{
		croak("unknown voice $_voice");
	} else
	{
		#
		# set the voice by name
		#
		my $res = Speech::Swift::swift_port_set_voice($_self->{port}, $voice);
		if (Speech::Swift::swift_failed($res))
		{
			croak("failed to set voice to $_voice");
		}

		$_self->{voice} = $voice;
	}

	1;
}
sub get_voices
{
	my ($_self) = @_;

	if (!$_self->{port})
	{
		croak("invalid swift port defined");
	}

	my $voices = ();

	#
	# get the first voice in the list
	#
	my $voice = Speech::Swift::swift_port_find_first_voice($_self->{port}, "", "");
	if ($voice)
	{
		#
		# go through each voice
		#
		while($voice)
		{
			#
			# get the attributes for this voice, and load it into a hash
			#
			my $name = Speech::Swift::swift_voice_get_attribute($voice, "name");

			$voices->{$name}->{id}			= Speech::Swift::swift_voice_get_attribute($voice, "id");
			$voices->{$name}->{name}		= Speech::Swift::swift_voice_get_attribute($voice, "name");
			$voices->{$name}->{path}		= Speech::Swift::swift_voice_get_attribute($voice, "path");
			$voices->{$name}->{version}		= Speech::Swift::swift_voice_get_attribute($voice, "version");
			$voices->{$name}->{buildstamp}		= Speech::Swift::swift_voice_get_attribute($voice, "buildstamp");
			$voices->{$name}->{sample_rate}		= Speech::Swift::swift_voice_get_attribute($voice, "sample-rate");
			$voices->{$name}->{license_key}		= Speech::Swift::swift_voice_get_attribute($voice, "license/key");
			$voices->{$name}->{language_tag}	= Speech::Swift::swift_voice_get_attribute($voice, "language/tag");
			$voices->{$name}->{language_name}	= Speech::Swift::swift_voice_get_attribute($voice, "language/name");
			$voices->{$name}->{language_version}	= Speech::Swift::swift_voice_get_attribute($voice, "language/version");
			$voices->{$name}->{lexicon_name}	= Speech::Swift::swift_voice_get_attribute($voice, "lexicon/name");
			$voices->{$name}->{lexicon_version}	= Speech::Swift::swift_voice_get_attribute($voice, "lexicon/version");
			$voices->{$name}->{speaker_name}	= Speech::Swift::swift_voice_get_attribute($voice, "speaker/name");
			$voices->{$name}->{speaker_gender}	= Speech::Swift::swift_voice_get_attribute($voice, "speaker/gender");
			$voices->{$name}->{speaker_age}		= Speech::Swift::swift_voice_get_attribute($voice, "speaker/age");

			#
			# get the next voice
			#
			$voice = Speech::Swift::swift_port_find_next_voice($_self->{port});
		}
	}

	return $voices;
}
sub generate
{
	my ($_self, $_text) = @_;

	if (!$_self->{port})
	{
		croak("invalid swift port defined");
	}

	#
	# create a new waveform
	#
	my $wav = Speech::Swift::swift_waveform_new()
		or croak("failed to create new waveform object");

	#
	# do the TTS generation, and get the waveform
	#
	$wav = Speech::Swift::swift_port_get_wave($_self->{port}, $_text)
		or croak("failed to generate wavefrom from text");

	return new Speech::Swift::Simple::Wav($wav);
}

1;
__END__

=head1 NAME

Speech::Swift::Simple - Simplified extension for Speech::Swift, a 
Perl extension for the Cepstral Text-to-Speech Engine (Swift)

=head1 SYNOPSIS

#!/usr/bin/perl

use Speech::Swift::Simple;

my $s = new Speech::Swift::Simple(channels => 1, encoding => Speech::Swift::AUDIO_ENCODING_PCM16);

$s->set_voice("Allison");

my $wav = $s->generate("My name is allison");

$wav->write("test.wav");

=head1 DESCRIPTION

=over     

=item new(...)

=over

=item C<encoding>

OPTIONAL: specify the encoding method to use for the output audio- see Speech::Swift
defaults to Speech::Swift::AUDIO_ENCODING_PCM16

=item C<channels>

OPTIONAL: specify the number of channels to use, either 1 or 2; defaults to 1.

=item C<deadair>

OPTIONAL: include deadair in audio output, either 1 or 0; defaults to 0;

=back

=item set_voice($voice_name)

Set the Cepstral voice to use for this Text-to-Speech generation.

$voice_name is the name of the voice to use.

=over

$s->set_voice("Allison");

=back

=item get_voices()

Returns a hash reference list of the currently available voices on the system.

=over

$voices = $s->get_voices();

=back

=item generate($text)

Generates audio for the given text, and returns a new Speech::Swift::Simple::Wav object with the audio.

$text is the text to synthesize.

See the Speech::Swift::Simple::Wav man page for more details.

=over

$wav = $s->generate("My name is allison");

=back

=back

=head1 DEPENDENCIES

Speech::Swift PERL Module

=head1 SEE ALSO

Cepstral - http://cepstral.com/

Speech::Swift

Speech::Swift::Simple::Wav

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
