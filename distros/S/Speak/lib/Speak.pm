
=pod

=head1 NAME

Speak - Convert text to speech using Google's engine and play it on speakers

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: 1.02 $

=item Created

=item Modified

Fri 06 Sep 2026 08:30:00 AM PST

=back

=head1 SYNOPSIS

This module offers subroutines to convert text into speach and speak them.

=head2 DESCRIPTION

This module exports subroutines to process text to speach and speak them.

=head1 ROUTINES

The following routines are exported:

=cut

package Speak;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use base 'Exporter';

use Clipboard;

our $VERSION = '1.02';

{

  ## no critic (Modules::ProhibitMultiplePackages)
  package Speak::Logger;

  use strict;
  use warnings;
  use File::Basename;
  use POSIX qw(strftime);
  use IO::Handle;
  use Carp;

sub new ($class, %args) {
    my $self = {
      path        => $args{path} || '.',
      name        => $args{name} || 'speak',
      timestamped => $args{timestamped},
      append      => $args{append},
      handle      => undef,
    };

    my $mode    = $self->{append} ? '>>' : '>';
    my $logfile = File::Spec->catfile ($self->{path}, $self->{name} . '.log');

    # We try to open the logfile, but if it fails we just warn and carry on
    # effectively logging nowhere (or we could default to STDERR)
    ## no critic (InputOutput::RequireBriefOpen)
    if (open my $fh, $mode, $logfile) {
      $fh->autoflush (1);
      $self->{handle} = $fh;
    } else {
      carp "Could not open logfile $logfile: $!";
    }

    bless $self, $class;
    return $self;
  } ## end sub new

  sub log ($self, $msg, $nolinefeed = undef) {
    return unless defined $msg;

    if (defined $nolinefeed) {
      print $msg;
    } else {
      print "$msg\n";
    }

    if ($self->{handle}) {
      my $timestamp =
        $self->{timestamped}
        ? strftime ("%Y-%m-%d %H:%M:%S", localtime) . ": "
        : "";

      my $fh = $self->{handle};

      if (defined $nolinefeed) {
        print $fh $timestamp, $msg;
      } else {
        print $fh $timestamp, $msg, "\n";
      }
    }

    return;
  } ## end sub log

  sub DESTROY ($self) {
    close $self->{handle} if $self->{handle};
    return;
  }
}

sub _get_config ($file) {
  my %config;
  return %config unless -f $file;

  ## no critic (InputOutput::RequireBriefOpen)
  if (open my $fh, '<', $file) {
    while (my $line = <$fh>) {
      chomp $line;
      next if $line =~ /^\s*[#!]/ || $line =~ /^\s*$/;
      if ($line =~ /^\s*([^:=]+?)\s*[:=]\s*(.*?)\s*$/) {
        my $key = $1;
        my $val = $2;

        # Simple variable interpolation for $ENV
        $val =~ s/\$(\w+)/$ENV{$1} || "\$$1"/ge;
        $config{$key} = $val;
      } ## end if ($line =~ /^\s*([^:=]+?)\s*[:=]\s*(.*?)\s*$/)
    } ## end while (my $line = <$fh>)
    close $fh;
  } ## end if (open my $fh, '<', ...)
  return %config;
} ## end sub _get_config

use LWP::UserAgent;
use URI::Escape;
use File::Temp qw(tempfile);
use File::Path qw(rmtree);
use File::Basename;
use Carp;

our @EXPORT_OK = qw(speak);

sub _split_text ($text) {
  return unless defined $text;

  my @sentences;
  while (length $text) {
    if ($text =~ s/^(.{1,100}?(?:[.!?;]|$))//) {
      push @sentences, $1;
    } else {
      # Fallback: force-slice the first 100 characters if no punctuation is found within 100 chars
      push @sentences, substr($text, 0, 100, "");
    }
  }

  return @sentences;
} ## end sub _split_text ($text)

sub _fetch_mp3 ($ua, $text, $lang) {

  my $url =
      "https://translate.google.com/translate_tts?ie=UTF-8&tl=$lang&q="
    . uri_escape_utf8 ($text)
    . "&total=1&idx=0&client=tw-ob";

  my $response = $ua->get ($url);

  if ($response->is_success) {
    my $content = $response->content;
    if (length ($content) == 0) {
      carp "Fetch successful but content is empty";
      return;
    }

    # Check if we got HTML instead of MP3 (e.g. Captcha/Error)
    if ($content =~ /^\s*<(!DOCTYPE|html)/i) {
      carp
"Received HTML response instead of MP3 (likely CAPTCHA/Blocked) from URL: $url";
      return;
    }

    return $content;
  } else {
    carp "Failed to fetch TTS: " . $response->status_line;
    return;
  }
} ## end sub _fetch_mp3 ($$$)

sub _convert_mp3_to_wav ($mp3, $wav) {

  # Try ffmpeg
  if (system ("which ffmpeg >/dev/null 2>&1") == 0) {
    return system ("ffmpeg -y -v error -i \"$mp3\" \"$wav\"") == 0;
  }

  # Try mpg123
  if (system ("which mpg123 >/dev/null 2>&1") == 0) {
    return system ("mpg123 -q -w \"$wav\" \"$mp3\"") == 0;
  }

  # Try lame
  if (system ("which lame >/dev/null 2>&1") == 0) {
    return system ("lame --decode --quiet \"$mp3\" \"$wav\"") == 0;
  }

  # Fallback to sox (might fail if no mp3 handler)
  return system ("sox \"$mp3\" \"$wav\"") == 0;
} ## end sub _convert_mp3_to_wav ($$)

## no critic (Subroutines::ProhibitExcessComplexity)
sub speak ($msg, $log = undef, $lang = undef) {

=pod

=head2 speak($msg, $log, $lang)

Convert $msg to speech.

Parameters:

=for html <blockquote>

=over

=item $msg:

Message to speak. If $msg is defined and scalar then that is the message
to speak. If it is a file handle then the text will be read from that file.
Otherwise the text in the clipboard will be used.

=item $log

If provided, errors and messages will be logged to the logfile, otherwise to speak.log

=item $lang

Language code (e.g. 'en', 'en-gb', 'en-au'). Defaults to $ENV{SPEAK_LANG} or 'en'.

=back



=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item Nothing

=back

=for html </blockquote>

=cut

  $log = Speak::Logger->new (
    path        => '/var/log',
    name        => 'speak',
    timestamped => 'yes',
    append      => 1,
  ) unless $log;

  $msg = Clipboard->paste unless $msg;
  $msg = do {local $/; <$msg>} if ref $msg eq 'GLOB';

  # Sanitize escape sequences
  # 1. Remove bells (\a)
  $msg =~ s/(\\a|\a)//g;

  # 2. Convert other escapes to space
  # Literals: \n, \t, \r, \f, \b
  $msg =~ s/\\[ntrfb]/ /g;

  # 3. Convert actual control characters to space
  $msg =~ s/[\n\t\r\f\b]/ /g;

  # 4. Collapse multiple spaces
  $msg =~ s/\s+/ /g;
  $msg =~ s/^\s+|\s+$//g;

  my @mute_paths =
    ($ENV{SPEAK_MUTE}, $ENV{HOME} . "/.speak/shh", "/etc/speak/shh");

  foreach my $path (@mute_paths) {
    if ($path && -f $path) {
      $msg .= ' [silent shh]';
      $log->log ($msg);
      return;
    }
  } ## end foreach my $path (@mute_paths)

  $log->log ($msg);

  # New Implementation
  my $ua = LWP::UserAgent->new;
  $ua->agent ("Mozilla/5.0");

  # Determine language:
  # 1. Argument $lang
  # 2. Environment variable SPEAK_LANG
  # 3. Config file
  # 4. Default 'en'

  unless ($lang) {
    if ($ENV{SPEAK_LANG}) {
      $lang = $ENV{SPEAK_LANG};
    } else {
      my @config_paths =
        ($ENV{HOME} . "/.speak/speak.conf", "/etc/speak/speak.conf");

      foreach my $conf_file (@config_paths) {
        if (-f $conf_file) {
          my %conf = _get_config ($conf_file);
          if ($conf{language}) {
            $lang = $conf{language};
            last;
          }
        } ## end if (-f $conf_file)
      } ## end foreach my $conf_file (@config_paths)
    } ## end else [ if ($ENV{SPEAK_LANG}) ]

    $lang ||= 'en';
  } ## end unless ($lang)

  my @sentences = _split_text ($msg);
  my @mp3_files;

  foreach my $sentence (@sentences) {
    next unless $sentence =~ /\S/;

    my $mp3_data = _fetch_mp3 ($ua, $sentence, $lang);
    next unless $mp3_data;

    my ($fh, $filename) = tempfile (SUFFIX => '.mp3', UNLINK => 0);
    binmode $fh;
    print $fh $mp3_data;
    close $fh;

    push @mp3_files, $filename;
  } ## end foreach my $sentence (@sentences)

  if (@mp3_files) {

    # Combine or play sequentially
    # Using 'sox' to play directly or concatenate would be better,
    # but for compatibility with existing 'play' command:

    # Concatenate using sox if multiple files
    my $final_file;
    if (@mp3_files > 1) {
      my ($fh, $joined) = tempfile (SUFFIX => '.mp3', UNLINK => 0);
      close $fh;
      $final_file = $joined;

      # Using system sox to join.
      # Note: This requires sox with mp3 handler.
      my $cmd = "sox " . join (" ", @mp3_files) . " $final_file";
      system ($cmd);
    } else {
      $final_file = $mp3_files[0];
    }

    # Play it
    if (-f $final_file) {
      if ($ENV{DEBUG_SPEAK}) {
        print "File info for $final_file:\n";
        system ("ls -l $final_file");
        system ("file $final_file");
      }

      # Cross-platform playback logic
      my $os = $^O;

      if ($os eq 'darwin') {

        # macOS
        system ("afplay \"$final_file\"");
      } elsif ($os eq 'MSWin32' || $os eq 'cygwin') {

        # Windows / Cygwin
        # Use powershell for headless playback if available, or start
        # Note: 'start' might pop up a window.
        # Cygwin often has 'play' (sox) as well.

        # Try PowerShell first as it's cleaner
        my $win_path = $final_file;
        if ($os eq 'cygwin') {
          chomp ($win_path = `cygpath -w "$final_file"`);
        }

       # Use PowerShell to play audio hidden
       # System.Media.SoundPlayer only supports WAV, so convert MP3 -> WAV first
        my ($fh_wav, $wav_file) = tempfile (SUFFIX => '.wav', UNLINK => 0);
        close $fh_wav;

        # Convert to WAV using sox
        if (system ("sox \"$final_file\" \"$wav_file\"") == 0) {
          my $wav_win_path = $wav_file;
          if ($os eq 'cygwin') {
            chomp ($wav_win_path = `cygpath -w "$wav_file"`);
          }

          my $cmd_wav =
"powershell -c (New-Object Media.SoundPlayer '$wav_win_path').PlaySync()";
          if (system ($cmd_wav) != 0) {

            # Fallback
            system ("play -q \"$final_file\"");
          }
          unlink $wav_file;
        } else {

          # Conversion failed logic fallback
          my $cmd =
"powershell -c (New-Object Media.SoundPlayer '$win_path').PlaySync()";
          if (system ($cmd) != 0) {

            # Fallback to sox 'play' if powershell fails
            system ("play -q \"$final_file\"");
          }
        } ## end else [ if (system ("sox \"$final_file\" \"$wav_file\""...))]
      } else {

      # Linux / Unix
      # paplay often requires WAV if libsndfile lacks mp3 support (e.g. on Mars)
      # We convert to WAV to be safe.
        if (-x '/usr/bin/paplay' || -x '/bin/paplay') {
          my ($fh_wav, $wav_file) = tempfile (SUFFIX => '.wav', UNLINK => 0);
          close $fh_wav;

          # Convert to WAV
          if (_convert_mp3_to_wav ($final_file, $wav_file)) {
            system ("paplay \"$wav_file\"");
            unlink $wav_file;
          } else {

            # Conversion failed, try playing mp3 directly
            system ("paplay \"$final_file\"");
          }
        } else {
          system ("play -q $final_file");
        }
      } ## end else [ if ($os eq 'darwin') ]

      unlink $final_file;
    } ## end if (-f $final_file)
    ## end if (-f $final_file)
  } ## end if (@mp3_files)

  # Cleanup temp files
  unlink @mp3_files;

  return;
}    # speak

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

SPEAK_LANG: Language code (e.g. 'en', 'en-gb', 'en-au'). 
            See etc/speak.conf for available languages.
            Defaults to $ENV{SPEAK_LANG} or 'en'.

SPEAK_MUTE: If set to a true value, speech output is muted.
            Alternatively, if a file exists at $ENV{HOME}/.speak/shh
            or /etc/speak/shh, speech is muted.

            To silence Speak for while simply touch $ENV{HOME}/.speak/shh
            or /etc/speak/shh file. To unsilence Speak, remove the file.

=head2 Configuration File

Speak supports a configuration file located at $ENV{HOME}/.speak/speak.conf
or /etc/speak/speak.conf.

Format:
  language: en-gb
  # other options...

Supported keys:
  language - Default language code for speech generation.

=head1 DEPENDENCIES

=head2 Perl Modules

L<Clipboard|Clipboard>

L<LWP::UserAgent|LWP::UserAgent>

L<URI::Escape|URI::Escape>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@DeFaria.com>.

=head1 LICENSE AND COPYRIGHT

This Perl Module is freely available; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This Perl Module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License (L<http://www.gnu.org/copyleft/gpl.html>) for more
details.

You should have received a copy of the GNU General Public License
along with this Perl Module; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
reserved.

=cut
