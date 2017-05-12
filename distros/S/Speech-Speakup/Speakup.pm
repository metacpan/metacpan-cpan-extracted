# Speakup::Speakup.pm
#########################################################################
#        This Perl module is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

package Speech::Speakup;
$VERSION = '1.05';   # 
my $stupid_bloody_warning = $VERSION;  # circumvent -w warning
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(speakup_get speakup_set synth_get synth_set);
%EXPORT_TAGS = (ALL => [@EXPORT,@EXPORT_OK]);

no strict; no warnings;

$Speech::Speakup::Message = undef;
$Speech::Speakup::SpDir   = undef;
foreach ('/sys/accessibility/speakup','/proc/speakup') {
    if (-d $_) { $SpDir = $_; }
}
# if (!$SpDir) { die ; }  # results in 100% failure for CPAN-testers :-(
# eval 'require Speech::Speakup';
#  sets $@ to  "Can't locate ..." if Speech::Speakup is not installed
#  sets $@ to  "Compilation failed ..." if $SpDir is not present

#  /usr/lib/i386-linux-gnu/espeak-data/

use open ':locale';  # the open pragma was introduced in 5.8.6

sub speakup_get { get($SpDir,   @_); }
sub speakup_set { set($SpDir,   @_); }
sub synth_get   { get(synthdir(),@_); }
sub synth_set   { set(synthdir(),@_); }

sub set { my ($dir, $param, $value) = @_;
	if (! $param) {  # return a list of all settable params
		if (! opendir(D,$dir)) {
			$Message = "can't opendir $dir: ";
			return undef;
		}
		my @l = sort grep
		  { (!/^\./) && (-f "$dir/$_") && is_w("$dir/$_") } readdir(D);
		closedir D;
		$Message = undef;
		return @l;
	}
	if (! open(F, '>', "$dir/$param")) {
		$Message = "can't open $dir/$param: $!";
		return undef;
	} else {
		print F "$value\n"; close F;
		$Message = undef;
		return 1;
	}
}

sub get { my ($dir, $param) = @_; 
	if (! $param) {  # return a list of all gettable params
		if (! opendir(D,$dir)) {
			$Message = "can't opendir $dir: ";
			return undef;
		}
		my @l = sort grep
		  { (!/^\./) && (-f "$dir/$_") && is_r("$dir/$_") } readdir(D);
		closedir D;
		$Message = undef;
		return @l;
	}
	if (! open(F, '<', "$dir/$param")) {
		$Message = "can't open $dir/$param: $!";
		return undef;
	} else {
		my @lines = (<F>); close F;
		$Message = undef;
		# 1.03 keymap is 65 lines long ! the others are only one line.
		if (1 < @lines) { return join('', @lines);
		} else { my $value = $lines[0]; $value =~ s/\s+$//; return $value;
		}
	}
}

sub synthdir {
	my $sd = get($SpDir,'synth');
	if (! $sd) { warn "can't find the synth directory\n"; return ''; }
	my $d = "$SpDir/$sd";
	if (! -e $d) { warn "synth directory $d does not exist\n"; return ''; }
	if (! -d $d) { warn "synth directory $d is not a directory\n"; return ''; }
	return $d;
}

sub is_w {
	# because -w as root reports yes regardless of file permissions
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	  $atime,$mtime,$ctime,$blksize,$blocks) = stat($_[0]);
	return $mode & 2;
}
sub is_r {
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	  $atime,$mtime,$ctime,$blksize,$blocks) = stat($_[0]);
	return $mode & 4;
}

sub enter_speakup_silent {   # 1.62
	# echo 7 > /sys/accessibility/speakup/silent  if it exists
	if (!$SpeakUpSilentFile) { return 0; }
	if ($IsSpeakUpSilent) {
		warn "enter_speakup_silent but already IsSpeakUpSilent\r\n"; return 1 ;
	}
	if (open(S, '>', $SpeakUpSilentFile)) { print S "7\n"; close S; }
	$IsSpeakUpSilent = 1;
	return 1;
}
sub leave_speakup_silent {   # 1.62
	# echo 4 > /sys/accessibility/speakup/silent  if it exists
	if (!$SpeakUpSilentFile) { return 0; }
	if (!$IsSpeakUpSilent) {
		warn "leave_speakup_silent but not IsSpeakUpSilent\r\n"; return 1 ;
	}
	if (open(S, '>', $SpeakUpSilentFile)) { print S "4\n"; close S; }
	$IsSpeakUpSilent = 0;
	return 1;
}

sub which {
	my $f;
	foreach $d (split(":",$ENV{'PATH'})) {$f="$d/$_[0]"; return $f if -x $f;}
}
%SpeakMode = ();
sub END {
	if ($Eflite_FH) { print $Eflite_FH "s\nq { }\n"; close $Eflite_FH;
	} elsif ($Espeak_PID) { kill SIGHUP, $Espeak_PID; wait;
	}
}

1;

__END__

=pod

=head1 NAME

Speech::Speakup - a module to interface with the Speakup screen-reader

=head1 SYNOPSIS

 use Speech::Speakup;
 my @speakup_parameters = Speech::Speakup::speakup_get();
 my @synth_parameters   = Speech::Speakup::synth_get();
 print "speakup_parameters are @speakup_parameters\n";
 print "synth_parameters   are @synth_parameters\n";
 Speech::Speakup::speakup_set('silent', 7);  # impose silence
 Speech::Speakup::speakup_set('silent', 4);  # restore speech
 Speech::Speakup::synth_set('punct', 2);  # change the punctuation-level

=head1 DESCRIPTION

I<Speakup> is a screen-reader that runs on I<Linux>
as a module within the kernel.
A screen-reader allows blind or visually-impaired people
to hear text as it appears on the screen,
and to review text already displayed anywhere on the screen.
I<Speakup> will only run on the I<linux> consoles,
but is powerful and ergonomic, and can run during the boot process.
The other important screen-reader is I<yasr>,
which runs in user-space and is very portable, but has less features.

There are parameters you can get and set at the screen-reader level
by using the routines I<speakup_get> and I<speakup_set>.

One of those parameters is the particular voice synthesiser engine
that I<speakup> will use;
this synthesiser has its own parameters, 
parameters that I<speakup> will use when invoking it,
and which you can get and set
by using the routines I<synth_get> and I<synth_set>.

The synthesiser can be a hardware device, on a serial line or USB,
or it can be software.
The most common software synth for I<Linux> is I<espeak>,
and I<flite> is also important.

There are also some files in I</proc> or I</sys> determining
things such as how the various punctuation parameters are to be pronounced.
These can not be edited in situ.
You should use the I<speakupconf> utility
(in debian it's in the I<speakup-tools> package)
to save an aside-copy, then edit that, then reload:

 speakupconf save
 vi ~/.speakup/i18n/characters
 speakupconf load

This is Speech::Speakup version 1.05

=head1 SUBROUTINES

All these routines set the variable B<$Speech::Speakup::Message>
to an appropriate error message if they fail.

=over 3

=item I<speakup_get>() or I<speakup_get>($param);

When called without arguments, I<speakup_get> returns a list
of the readable I<speakup> parameters.

When called with one of those parameters as an argument,
I<speakup_get> returns the current value of that parameter,
or I<undef> if the get fails.

Most parameters are only one line long,
and are returned without any terminating new-line.
The (read-only) I<keymap> and I<version> parameters are longer;
they are returned as a scalar text string containing embedded new-lines.

=item I<speakup_set>() or I<speakup_set>($param, $value);

When called without arguments, I<speakup_set> returns a list
of the writeable I<speakup> parameters.

When called with $parameter,$value as arguments,
I<speakup_set> sets the value of that parameter.
It returns success or failure.

=item I<synth_get>() or I<synth_get>($param);

When called without arguments, I<synth_get> returns a list
of the readable synthesiser parameters.

When called with one of those parameters as an argument,
I<synth_get> returns the current value of that parameter,
or I<undef> if the get fails.

=item I<synth_set>() or I<synth_set>($param, $value);

When called without arguments, I<synth_set> returns a list
of the writeable synthesiser parameters.

When called with $parameter,$value as arguments,
I<synth_set> sets the value of that parameter.
It returns success or failure.

=back

=head1 SPEAKUP_SET PARAMETERS

The parameters I<key_echo> and I<no_interrupt> are boolean: 0 or 1.

The important I<silent> parameter is a bitmap.
B<7> means immediate silence flushing all pending text;
B<5> speaks the pending text and then goes silent;
then B<4> restores speech.

The I<punc_some>, I<punc_most> and I<punc_all> parameters
are strings containing lists of punctuation characters.
The I<reading_punc> parameter can then be set to B<0>, B<1>, B<2> or B<3>
in order to select which punctuation characters are
pronounced when reading (for example with Keypad-8),
and the I<punc_level> parameter can be set likewise
to select which punctuation characters are
pronounced when the computer writes them to the screen.
B<1> selects I<punc_some>,
B<2> selects I<punc_most>,
B<3> selects I<punc_all>, and
B<0> supresses pronounciation of any punctuation.
For reading prose, you'll probably prefer B<1>,
and for a programming languange probably B<3>.

The speakup parameter I<synth> is a string,
which must exist as a subdirectory of the speakup parameter directory.

The parameter I<synth_direct> is not a parameter,
it is a direct input to the synthesiser;
use this if your application needs to say something.
It imposes a length-limit of 250 bytes.
The I<synth_direct> input bypasses I<speakup>,
and works even if the I<silent> parameter is set to B<7>.
Its punctuation-level ignores the settings of I<punc_level> or I<reading_punc>,
and is controled by the synth I<punct> parameter, see below.

The authoritative documentation of these parameters is the source code,
in the file I<drivers/staging/speakup/kobjects.c>

=head1 SYNTH_SET PARAMETERS

The I<punct> and I<tone> parameters may be  set to B<0>, B<1> or B<2>.

The I<punct> parameter controls the punctuation-level
applied to the I<synth_direct> input.
When I<punct> is B<0> or B<2>, then B<# $ % & * + / = @> are pronounced,
and when I<punct> is B<1> all punctuation seems to be pronounced.

The important I<vol>, I<pitch>, I<freq> and I<rate> parameters
are B<0> to B<9>, default B<5>.

I<freq> controls the expressiveness of the voice
(the amount by which its frequency varies during speech),
whereas I<pitch> adjusts between a low voice and a high voice.

=head1 EXPORT_OK SUBROUTINES

No routines are exported by default,
but they are exported under the I<ALL> tag,
so if you want to import them all you should:

 import Speech::Speakup qw(:ALL);

=head1 PACKAGE VARIABLES

=over 3

=item I<$Speech::Speakup::Message>

Whenever a subroutine call fails,
the $Message variable is set with an appropriate error message.
If the call succeeds it is set to I<undef>.

=item I<$Speech::Speakup::SpDir>

The $SpDir variable is set to the the speakup-directory,
which can be in I</proc> but is usually in I</sys/accesibility>.

=back

=head1 EXAMPLES

A simple example in the I<examples/> subdirectory
is already a useful application:

=over 3

=item speakup_params

I<speakup_params> lists, and then allows you to modify,
all the I<speakup> and I<synth> parameters.
It uses the I<Term::Clui> module to provide the user-interface.

=back

=head1 DEPENDENCIES

It requires only Exporter, which is core Perl.

The example I<speakup_params> requires also the CPAN module I<Term::Clui>

=head1 AUTHOR

Peter J Billam www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://linux-speakup.org
 http://linux-speakup.org/spkguide.txt
 http://speech.braille.uwo.ca/mailman/listinfo/speakup
 http://people.debian.org/~sthibault/espeakup
 aptitude install espeakup speakup-tools
 aptitude install flite eflite
 http://search.cpan.org/perldoc?Speech::Speakup
 /sys/accessibility/speakup/ or /proc/speakup/

 http://espeak.sourceforge.net
 aptitude install espeak
 perldoc Speech::eSpeak
 http://search.cpan.org/perldoc?Speech::eSpeak
 http://linux-speakup.org/distros.html
 http://the-brannons.com/tarch/
 http://search.cpan.org/perldoc?Term::Clui
 http://www.pjb.com.au/
 http://www.pjb.com.au/blin/free/speakup_params
 espeakup(1)
 emacspeak(1)
 espeak(1)
 perl(1)

There should soon be an equivalent Python3 module
with the same calling interface, at
http://cpansearch.perl.org/src/PJB/Speech-Speakup-1.05/py/SpeechSpeakup.py

=cut
