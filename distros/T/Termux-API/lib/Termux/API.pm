package Termux::API;
use strict;
use warnings;
use JSON;

our $VERSION = 0.03;

sub new {
	return bless( {
		j => JSON->new
	}, $_[0] );
}

sub command {
	my $command = qx($_[1]);
	return eval { $_[0]->{j}->decode($command) } || $command;
}

sub battery_status {
	$_[0]->command('termux-battery-status');
}

sub brightness {
	$_[0]->command("termux-brightness $_[1]");
}

sub camera_info {
	$_[0]->command('termux-camera-info');
}

sub clipboard_get {
	$_[0]->command('termux-clipboard-get');
}

sub clipboard_set {
	$_[0]->command("termux-clipboard-set $_[1]");
}

sub contact_list {
	$_[0]->command('termux-contact-list');
}

sub dialog {
	my ( $self, $type, %options ) = @_;
	my $command = sprintf( 'termux-dialog %s %s',
		$type,
		join( ' ', map( { $_ . ' "' . $options{$_} . '"'; } keys %options ) )
	);
	$_[0]->command($command);
}

sub download {
	$_[0]->command("termux-download $_[1]");
}

sub fingerprint {
	$_[0]->command('termux-fingerprint');
}

sub infrared_frequencies {
	$_[0]->command('termux-infrared-frequencies');
}

sub infrared_transmit {
	$_[0]->command("termux-infrared-transmit -f $_[1]");
}

sub location {
	my ( $self, $provide, $request ) = @_;
	$provide ||= 'gps';
	$request ||= 'once';
	$_[0]->command("termux-location -p $provide -r $request");
}

sub microphone {
	my ( $self, %options ) = @_;
	my $command = sprintf( 'termux-microphone-record %s',
		join( ' ', map( { $_ . ' "' . $options{$_} . '"'; } keys %options ) )
	);
	$_[0]->command($command);
}

sub notification {
	my ( $self, %options ) = @_;
	my $command = sprintf( 'termux-notification %s',
		join( ' ', map( { $_ . ' "' . $options{$_} . '"'; } keys %options ) )
	);
	$_[0]->command($command);
}

sub notification_remove {
	$_[0]->command("termux-notification-remove $_[1]");
}

sub sensor {
	my ( $self, %options ) = @_;
	$options{'-n'} = 1;
	my $command = sprintf( 'termux-sensor %s',
		join( ' ', map( { $_ . ' "' . $options{$_} . '"'; } keys %options ) )
	);
	$_[0]->command($command);
}

sub telephony_call {
	$_[0]->command("termux-telephony-call $_[1]");
}

sub telephony_cellinfo {
	$_[0]->command('termux-telephony-cellinfo');
}

sub telephony_device {
	$_[0]->command('termux-telephony-deviceinfo');
}

sub toast {
	my ( $self, $text, %options ) = @_;
	my $command = sprintf(
		'termux-toast %s "%s"',
		join( ' ', map( { $_ . ' "' . $options{$_} . '"'; } keys %options ) ),
		$text
	);
	$_[0]->command($command);
}

sub torch {
	$_[0]->command("termux-torch $_[1]");
}

sub tts_engines {
	$_[0]->command('termux-tts-engines');
}

sub tts_speak {
	my ( $self, $text, %options ) = @_;
	my $command = sprintf(
		'termux-tts-speak %s "%s"',
		join( ' ', map( { $_ . ' "' . $options{$_} . '"'; } keys %options ) ),
		$text
	);
	$_[0]->command($command);
}

sub vibrate {
	my ( $self, %options ) = @_;
	my $command = sprintf( 'termux-vibrate %s',
		join( ' ', map( { $_ . ' "' . $options{$_} . '"'; } keys %options ) )
	);
	$_[0]->command($command);
}

sub volume {
	my ( $self, $stream, $volume ) = @_;
	my $command = 'termux-volume';
	if ( $stream and $volume ) {
		$command = sprintf( '%s %s %s', $command, $stream, $volume );
	}
	$self->command($command);
}

sub wallpaper {
	my ( $self, %options ) = @_;
	my $command = sprintf( 'termux-wallpaper %s',
		join( ' ', map( { $_ . ' "' . $options{$_} . '"'; } keys %options ) )
	);
	$self->command($command);
}

sub wifi {
	$_[0]->command('termux-wifi-connectioninfo');
}

sub wifi_enable {
	my $enable = $_[1] ? 'true' : 'false';
	$_[0]->command("termux-wifi-enable $enable");
}

sub wifi_scan {
	$_[0]->command('termux-wifi-scaninfo');
}

sub audio_info {
	$_[0]->command('termux-audio-info');
}

sub elf_cleaner {
	my ($self, @files) = @_;
	$self->command(sprintf 'termux-elf-cleaner %s', join ' ', @files);
}

sub speech_to_text {
 	$_[0]->command(sprintf(
		'termux-speech-to-text %s',
		$_[1] ? '-p' : ''
	));
}

1;

__END__

=head1 NAME

Termux::API - Termux::API wrapper

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	pkg install make
	pkg install clang
	pkg install perl
	curl -L https://cpanmin.us | perl - App::cpanminus
	cpanm Termux::API;

	...

	use Termux::API;

	my $termux = Termux::API->new();

	$termux->toast('testing a toast');

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Termux::API::Tiny Object.

	my $termux = Termux::API::Tiny->new;

=head2 command

Initiate a termux api command

	$termux->command("termux-battery-status")

=head2 battery_status

Get the status of the device battery.

	$termux->battery_status

=head2 brightness

Set the display brightness. Note that this may not work if automatic brightness control is enabled.

	$termux->brightness

=head2 camera_info

Get information about device camera(s).

	$termux->camera_info

=head2 clipboard_get

Get the system clipboard text

	$termux->clipboard_get

=head2 clipboard_set

Set the system clipboard text.

	$termux->clipboard_set("copy some text")

=head2 contact_list

List all contacts

	$termux->contact_list

=head2 dialog

Show dialog widget for user input

	$termux->dialog("confirm", -i => "Hint text", -t => "Title text")

Options:

	confirm - Show confirmation dialog
		[-i hint] text hint (optional)
		[-t title] set title of dialog (optional)

	checkbox - Select multiple values using checkboxes
		[-v ",,,"] comma delim values to use (required)
		[-t title] set title of dialog (optional)

	counter - Pick a number in specified range
		[-r min,max,start] comma delim of (3) numbers to use (optional)
		[-t title] set title of dialog (optional)

	date - Pick a date
		[-t title] set title of dialog (optional)
		[-d "dd-MM-yyyy k:m:s"] SimpleDateFormat Pattern for date widget output (optional)

	radio - Pick a single value from radio buttons
		[-v ",,,"] comma delim values to use (required)
		[-t title] set title of dialog (optional)

	sheet - Pick a value from sliding bottom sheet
		[-v ",,,"] comma delim values to use (required)
		[-t title] set title of dialog (optional)

	spinner - Pick a single value from a dropdown spinner
		[-v ",,,"] comma delim values to use (required)
		[-t title] set title of dialog (optional)

	speech - Obtain speech using device microphone
		[-i hint] text hint (optional)
		[-t title] set title of dialog (optional)

	text - Input text (default if no widget specified)
		[-i hint] text hint (optional)
		[-m] multiple lines instead of single (optional)*
		[-n] enter input as numbers (optional)*
		[-p] enter input as password (optional)
		[-t title] set title of dialog (optional)
		* cannot use [-m] with [-n]

	time - Pick a time value
		[-t title] set title of dialog (optional)

=head2 download

Download a resource using the system download manager.

	$termux->download($url)

=head2 fingerprint

Use fingerprint sensor on device to check for authentication.

	$termux->fingerprint

=head2 infrared_frequencies

Query the infrared transmitter's supported carrier frequencies.

	$termux->infrared_frequencies

=head2 infrared_transmit

Transmit an infrared pattern.

	$termux->infrared_transmit($pattern)

=head2 location

Get the device location. You can optionally pass a provider (gps|network|passive) and a kind of request (once|last|updates).

	$termux->location($provider, $request)

=head2 microphone

Record using microphone on your device.

	$termux->sensor(-s => "gravity")

OPTIONS:

	-h, help           Show this help
	-a, all            Listen to all sensors (WARNING! may have battery impact)
	-c, cleanup        Perform cleanup (release sensor resources)
	-l, list           Show list of available sensors
	-s, sensors [,,,]  Sensors to listen to (can contain just partial name)
	-d, delay [ms]     Delay time in milliseconds before receiving new sensor update
	-n, limit [num]    Number of times to read sensor(s) (default: continuous) (min: 1)

=head2 notification

Display a system notification.

	$termux->notification(-i => 1, -t => "Title text", -c => "Content text")

OPTIONS:

	--action action          action to execute when pressing the notification
	--alert-once             do not alert when the notification is edited
	--button1 text           text to show on the first notification button
	--button1-action action  action to execute on the first notification button
	--button2 text           text to show on the second notification button
	--button2-action action  action to execute on the second notification button
	--button3 text           text to show on the third notification button
	--button3-action action  action to execute on the third notification button
	-c/--content content     content to show in the notification. Will take precedence over stdin.
	--group group            notification group (notifications with the same group are shown together)
	-h/--help                show this help
	--help-actions           show the help for actions
	-i/--id id               notification id (will overwrite any previous notification with the same id)
	--image-path path        absolute path to an image which will be shown in the notification
	--led-color rrggbb       color of the blinking led as RRGGBB (default: none)
	--led-off milliseconds   number of milliseconds for the LED to be off while it's flashing (default: 800)
	--led-on milliseconds    number of milliseconds for the LED to be on while it's flashing (default: 800)
	--on-delete action       action to execute when the the notification is cleared
	--ongoing                pin the notification
	--priority prio          notification priority (high/low/max/min/default)
	--sound                  play a sound with the notification
	-t/--title title         notification title to show
	--vibrate pattern        vibrate pattern, comma separated as in 500,1000,200
	--type type              notification style to use (default/media)

=head2 notification_remove

Remove a notification previously shown with "termux-notification -i"

	$termux->notification_remove(1)

=head2 sensor

Get information about types of sensors as well as live data.

	$termux->sensor(-s => "gravity")

Options:

	-h, help           Show this help
	-a, all            Listen to all sensors (WARNING! may have battery impact)
	-c, cleanup        Perform cleanup (release sensor resources)
	-l, list           Show list of available sensors
	-s, sensors [,,,]  Sensors to listen to (can contain just partial name)
	-d, delay [ms]     Delay time in milliseconds before receiving new sensor update
	-n, limit [num]    Number of times to read sensor(s) (default: continuous) (min: 1)

=head2 telephony_call

Call a telephony number.

	$termux->telephony_call($number)

=head2 telephony_cellinfo

Get information about all observed cell information from all radios on the device including the primary and neighboring cells.

	$termux->telephony_cellinfo

=head2 telephony_device

Get information about the telephony device.

	$termux->telephony_cellinfo

=head2 toast

Show text in a Toast (a transient popup).

	$termux->toast("Test a toast", %options)

Options:

	-h  show this help
	-b  set background color (default: gray)
	-c  set text color (default: white)
	-g  set position of toast: [top, middle, or bottom] (default: middle)
	-s  only show the toast for a short while

=head2 torch

Toggle LED Torch on device. Accepts either on (enable torch) or off (disable torch.

	$termux->torch('on')

=head2 tts_engines

Get information about the available text-to-speech (TTS) engines.

	$termux->tts_engines

=head2 tts_speak

Speak text with a system text-to-speech (TTS) engine. TODO

	$termux->tts_speak("Talk to me")

Options:

	-e engine    TTS engine to use (see termux-tts-engines)
	-l language  language to speak in (may be unsupported by the engine)
	-n region    region of language to speak in
	-v variant   variant of the language to speak in
	-p pitch     pitch to use in speech. 1.0 is the normal pitch, lower values lower the tone of the synthesized voice, greater values increase it.
	-r rate      speech rate to use. 1.0 is the normal speech rate, lower values slow down the speech (0.5 is half the normal speech rate) while greater values accelerates it (2.0 is twice the normal speech rate).
	-s stream    audio stream to use (default:NOTIFICATION), one of: ALARM, MUSIC, NOTIFICATION, RING, SYSTEM, VOICE_CALL

=head2 vibrate

Vibrate the device.

	$termux->vibrate

Options:

	-d duration  the duration to vibrate in ms (default:1000)
	-f           force vibration even in silent mode

=head2 volume

View or Change volume of specified audio stream

	$termux->volume

=head2 wallpaper

Change wallpaper on your device.

	$termux->wallpaper(%options)

Options:

	-f <file>  set wallpaper from file
	-u <url>   set wallpaper from url resource
	-l         set wallpaper for lockscreen (Nougat and later)

=head2 wifi

Get information about current Wi-Fi connection. This information include: SSID (AP name), BSSID (AP mac address), device IP and other.

	$termux->wifi

=head2 wifi_enable

Toggle Wi-Fi on or off

	$termux->wifi_enable(1)

=head2 wifi_scan

Retrieves last wifi scan information.

	$termux->wifi_scan

=head2 audio_info

Get information about audio capabilities.

	$termux->audio_info

=head2 elf_cleaner

Utility for Android ELF files to remove unused parts that the linker warns about.

	$termux->elf_cleaner(@files)

=head2 speech_to_text

Converts speech to text, sending partial matches to stdout.

	$termux->speech_to_text($show_progress)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-termux::api at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Termux-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Termux::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Termux-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Termux-API>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Termux-API>

=item * Search CPAN

L<https://metacpan.org/release/Termux-API>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
