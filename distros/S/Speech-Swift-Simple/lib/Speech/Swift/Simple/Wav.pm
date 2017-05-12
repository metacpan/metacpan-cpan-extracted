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

package Speech::Swift::Simple::Wav;

use 5.010000;
use strict;
use warnings;
use Carp;

require Speech::Swift;
require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '1.1';

sub new
{
	my ($_class, $_wav) = @_;
	my %values = ();

	$values{wav} = $_wav;

	return bless({%values}, $_class);
}
sub DESTROY
{
	my ($_self) = @_;

	if ($_self->{wav})
	{
		Speech::Swift::swift_waveform_close($_self->{wav});
	}

	1;
}
sub write
{
	my ($_self, $_filename) = @_;

	if (!$_self->{wav})
	{
		croak("Speech::Swift::Simple::Wav: invalid local wav object.");
	}
	if (length($_filename) <= 0)
	{
		croak("Speech::Swift::Simple::Wav: empty filename provided.");
	}

	#
	# write the waveform using the swift library directly
	#
	my $res = Speech::Swift::swift_waveform_save($_self->{wav}, $_filename, "riff");
	if (Speech::Swift::swift_failed($res))
	{
		croak("Speech::Swift::Simple::Wav: failed to write to $_filename: " . Speech::Swift::swift_strerror($res));
	}

	1;
}
sub buffer
{
	my ($_self) = @_;

	if (!$_self->{wav})
	{
		croak("Speech::Swift::Simple::Wav: invalid local wav object.");
	}

	#
	# get the audio data from the waveform
	#
	my @audio = Speech::Swift::swift_waveform_get_samples($_self->{wav});
	if (scalar(@audio) <= 0)
	{
		croak("Speech::Swift::Simple::Wav: failed to extract audio from waveform");
	}

	#
	# the audio is returned as an array of 16bit int's; return it as a packed binary chunk
	#
	return pack('v' . scalar(@audio), @audio);
}
sub get_channels
{
	my ($_self) = @_;

	if (!$_self->{wav})
	{
		croak("Speech::Swift::Simple::Wav: invalid local wav object.");
	}

	return Speech::Swift::swift_waveform_get_channels($_self->{wav});
}
sub set_channels
{
	my ($_self, $_channels) = @_;

	if (!$_self->{wav})
	{
		croak("Speech::Swift::Simple::Wav: invalid local wav object.");
	}
	if ( ($_channels != 1) && ($_channels != 2) )
	{
		croak("Speech::Swift::Simple::Wav: setting must be 1 or 2");
	}
	if ($_channels == Speech::Swift::swift_waveform_get_channels($_self->{wav}))
	{
		return 1;
	}

	my $res = Speech::Swift::swift_waveform_set_channels($_self->{wav}, $_channels);
	if (Speech::Swift::swift_failed($res))
	{
		croak("Speech::Swift::Simple::Wav: " . Speech::Swift::swift_strerror($res));
	}

	1;
}
sub get_sample_rate
{
	my ($_self) = @_;

	if (!$_self->{wav})
	{
		croak("Speech::Swift::Simple::Wav: invalid local wav object.");
	}

	return Speech::Swift::swift_waveform_get_sps($_self->{wav});
}
sub set_sample_rate
{
	my ($_self, $_sample_rate) = @_;

	if (!$_self->{wav})
	{
		croak("Speech::Swift::Simple::Wav: invalid local wav object.");
	}
	if ($_sample_rate == Speech::Swift::swift_waveform_get_sps($_self->{wav}))
	{
		return 1;
	}

	my $res = Speech::Swift::swift_waveform_resample($_self->{wav}, $_sample_rate);
	if (Speech::Swift::swift_failed($res))
	{
		croak("Speech::Swift::Simple::Wav: " . Speech::Swift::swift_strerror($res));
	}

	1;
}
sub get_encoding
{
	my ($_self) = @_;

	if (!$_self->{wav})
	{
		croak("Speech::Swift::Simple::Wav: invalid local wav object.");
	}

	my $encoding = Speech::Swift::swift_waveform_get_encoding($_self->{wav});

	if ($encoding eq "pcm16")
	{
		return Speech::Swift::AUDIO_ENCODING_PCM16;
	} elsif ($encoding eq "pcm8")
	{
		return Speech::Swift::AUDIO_ENCODING_PCM8;
	} elsif ($encoding eq "ulaw")
	{
		return Speech::Swift::AUDIO_ENCODING_ULAW;
	} elsif ($encoding eq "alaw")
	{
		return Speech::Swift::AUDIO_ENCODING_ALAW;
	}

	croak("Speech::Swift::Simple::Wav: invalid encoding type: $encoding");
}
sub set_encoding
{
	my ($_self, $_encoding) = @_;

	if (!$_self->{wav})
	{
		croak("Speech::Swift::Simple::Wav: invalid local wav object.");
	}
	
	my $e = 0;

	if ($_encoding == Speech::Swift::AUDIO_ENCODING_PCM16)
	{
		$e = "pcm16";
	} elsif ($_encoding == Speech::Swift::AUDIO_ENCODING_PCM8)
	{
		$e = "pcm8";
	} elsif ($_encoding == Speech::Swift::AUDIO_ENCODING_ULAW)
	{
		$e = "ulaw";
	} elsif ($_encoding == Speech::Swift::AUDIO_ENCODING_ALAW)
	{
		$e = "alaw";
	} else
	{
		croak("Speech::Swift::Simple::Wav: invalid encoding type: $_encoding");
	}

	my $res = Speech::Swift::swift_waveform_convert($_self->{wav}, $e);
	if (Speech::Swift::swift_failed($res))
	{
		croak("Speech::Swift::Simple::Wav: " . Speech::Swift::swift_strerror($res));
	}

	1;
}

1;
__END__

=head1 NAME

Speech::Swift::Simple::Wav - returned by Speech::Swift::Simple::generate() after TTS synthesis.

=head1 SYNOPSIS

#!/usr/bin/perl

use Speech::Swift::Simple;

my $s = new Speech::Swift::Simple;

$s->set_voice("Allison");

my $wav = $s->generate("My name is allison");

$wav->save("allison.wav");

=head1 DESCRIPTION

=over

=item write($filename)

Write the contents of the WAV file to the file name specified.

$filename is the name of the file to write to.

=over

$wav->write("output.wav");

=back

=item buffer()

Return the RAW audio contents of the WAV file. This returns the data without the WAV header.

=over

$data = $wav->buffer();

=back

=item get_channels()

Returns the number of channels in the WAV file (1 or 2 channel)

=over

$c = $wav->get_channels();

=back

=item set_channels($channels)

Sets the number of channels in the WAV file (1 or 2 channel)

=over

$wav->set_channels(2);

=back

=item get_sample_rate()

Returns the sample rate of the WAV file.

=over

$s = $wav->get_sample_rate();

=back

=item set_sample_rate($sample_rate)

Sets the sample rate of the WAV file. Sample rate is the sample rate: 8000, 16000, etc.

=over

$wav->set_sample_rate(16000);

=back

=item get_encoding()

Returns the encoding format of the WAV file. See the Speech::Swift::AUDIO_ENCODING constants.

=over

$e = $wav->get_encoding();

=back

=item set_encoding($encoding)

Sets the encoding format of the WAV file. See the Speech::Swift::AUDIO_ENCODING constants.

=over

$wav->set_encoding(Speech::Swift::AUDIO_ENCODING_PCM16);

=back

=back

=head1 DEPENDENCIES

Speech::Swift PERL Module

=head1 SEE ALSO

Ceptstral - http://cepstral.com/

Speech::Swift

Speech::Swift::Simple

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
