package POE::Component::Player::Xmms;

use warnings;
use strict;

use POE qw(Wheel::Run);
use Xmms;
use Xmms::Remote;

our $VERSION = '0.04';

@POE::Component::Player::Xmms::ISA = ("Xmms::Remote");

sub spawn {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new();

	my $args = shift || { };
	$args->{alias} ||= 'xmms';
	$args->{debug} ||= 0;
	
	POE::Session->create(
		args => [ $args ],
		object_states => [
			$self => [
				# internal
				'_start',
		        'signals',
                
				# Wheel::Run stuff
				'xmms_error',
				'xmms_closed',
				'xmms_stdin',
				'xmms_stdout',
				'xmms_stderr',
				
				# Xmms::Remote converted methods
				'playlist_clear',
				'playlist',
				'play',
				'get_playlist_length',
				'get_volume',
				'set_main_volume',
				'get_main_volume',
				'is_repeat',
				'is_shuffle',
				'get_info',
				'get_playlist_file',
				'get_playlist_time',
				'set_volume',
				'get_balance',
				'get_balancestr',
				'set_balance',
				'get_skin',
				'toggle_aot',
				'main_win_toggle',
				'pl_win_toggle',
				'eq_win_toggle',
				'prefs_win_toggle',
				'get_output_time',
				'get_output_timestr',
				'stop',
				'is_playing',
				'quit',
				'get_playlist_pos',
				'set_playlist_pos',
				'get_playlist_files',
				'get_version',
				'is_running',
				'show_prefs_box',
				'set_skin',
				'all_win_toggle',
				'get_playlist_titles',
				'get_playlist_title',
				'eject',
				'playlist_next',
				'playlist_prev',
				'pause',
				'toggle_shuffle',
				'toggle_repeat',
				'playlist_delete',
				'playlist_add',
				'playlist_add_url',
				'jump_to_time',
				'jump_to_timestr',
				'get_playlist_timestr',
				'is_main_win',
				'is_pl_win',
				'is_eq_win',
				'get_eq',
				'set_eq',
				'get_eq_preamp',
				'set_eq_preamp',
				'get_eq_band',
				'set_eq_band',
			],
		],
	);
	
	return $self;
}

sub _start {
	my ($kernel, $heap, $sender, $self, $args) = @_[KERNEL, HEAP, SENDER, OBJECT, ARG0];

    $kernel->alias_set($args->{alias});
	$kernel->sig(CHLD => 'signals');
    $heap->{reply} = $sender->ID;
	$heap->{args} = $args;
	$heap->{xargs} = $args->{xargs} || '';
	
	$kernel->post($heap->{reply} => 'xmms_started');
	
	return if ($kernel->call($_[SESSION] => 'is_running'));
	#print "spawning\n";

	$heap->{wheel} = POE::Wheel::Run->new(
		Program     => 'xmms',
		ProgramArgs => [$heap->{xargs}],     # Parameters for $program.
		#Priority    => +5,		      # Adjust priority.  May need to be root.
		#User        => getpwnam('nobody'), # Adjust UID. May need to be root.
		#Group       => getgrnam('nobody'), # Adjust GID. May need to be root.
		ErrorEvent  => 'xmms_error',	      # Event to emit on errors.
		CloseEvent  => 'xmms_closed',     # Child closed all output.
	
		StdinEvent  => 'xmms_stdin',  # Event to emit when stdin is flushed to child.
		StdoutEvent => 'xmms_stdout', # Event to emit with child stdout information.
		StderrEvent => 'xmms_stderr', # Event to emit with child stderr information.
	
		StderrFilter => POE::Filter::Line->new(),   # Child errors are lines.
		StdioFilter => POE::Filter::Line->new(),    # Or some other filter.
		   
		StderrDriver => POE::Driver::SysRW->new(),  # Same.
		StdioDriver	=> POE::Driver::SysRW->new(),
	);
	
}

sub signals {
    return 0;
}

sub xmms_error {
#	print "error ".$_[ARG0]."\n";
}

sub xmms_closed { 
	delete $_[HEAP]->{wheel};
	$_[KERNEL]->alias_remove($_[HEAP]->{args}->{alias});
}

sub xmms_stdin {
#	print "stdin: ".$_[ARG0]."\n";
}

sub xmms_stdout {
#	print "stdout: ".$_[ARG0]."\n";
}

sub xmms_stderr {
#	print "stderr: ".$_[ARG0]."\n";
}

sub playlist_clear {
	my $r = $_[OBJECT]->SUPER::playlist_clear(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub playlist {
	my $r = $_[OBJECT]->SUPER::playlist(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub play {
	my $r = $_[OBJECT]->SUPER::play(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub get_playlist_length {
	return $_[OBJECT]->SUPER::get_playlist_length(splice(@_,ARG0));
}

sub get_volume {
	return $_[OBJECT]->SUPER::get_volume(splice(@_,ARG0));
}

sub set_main_volume {
	my $r = $_[OBJECT]->SUPER::set_main_volume(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub get_main_volume {
	my $r = $_[OBJECT]->SUPER::get_main_volume(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub is_repeat {
	return $_[OBJECT]->SUPER::is_repeat(splice(@_,ARG0));
}

sub is_shuffle {
	return $_[OBJECT]->SUPER::is_shuffle(splice(@_,ARG0));
}

sub get_info {
	return $_[OBJECT]->SUPER::get_info(splice(@_,ARG0));
}

sub get_playlist_file {
	return $_[OBJECT]->SUPER::get_playlist_file(splice(@_,ARG0));
}

sub get_playlist_time {
	return $_[OBJECT]->SUPER::get_playlist_time(splice(@_,ARG0));
}

sub set_volume {
	my $r = $_[OBJECT]->SUPER::set_volume(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub get_balance {
	return $_[OBJECT]->SUPER::get_balance(splice(@_,ARG0));
}

sub get_balancestr {
	return $_[OBJECT]->SUPER::get_balancestr(splice(@_,ARG0));
}

sub set_balance {
	my $r = $_[OBJECT]->SUPER::set_balance(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub get_skin {
	return $_[OBJECT]->SUPER::get_skin(splice(@_,ARG0));
}

sub toggle_aot {
	return $_[OBJECT]->SUPER::toggle_aot(splice(@_,ARG0));
}

sub main_win_toggle {
	return $_[OBJECT]->SUPER::main_win_toggle(splice(@_,ARG0));
}

sub pl_win_toggle {
	return $_[OBJECT]->SUPER::pl_win_toggle(splice(@_,ARG0));
}

sub eq_win_toggle {
	return $_[OBJECT]->SUPER::eq_win_toggle(splice(@_,ARG0));
}

sub prefs_win_toggle {
	return $_[OBJECT]->SUPER::prefs_win_toggle(splice(@_,ARG0));
}

sub get_output_time {
	return $_[OBJECT]->SUPER::get_output_time(splice(@_,ARG0));
}

sub get_output_timestr {
	return $_[OBJECT]->SUPER::get_output_timestr(splice(@_,ARG0));
}

sub stop {
	my $r = $_[OBJECT]->SUPER::stop(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub is_playing {
	return $_[OBJECT]->SUPER::is_playing(splice(@_,ARG0));
}

sub quit {
	return $_[OBJECT]->SUPER::quit(splice(@_,ARG0));
}

# TODO test if client has this
sub get_playlist_pos {
	return $_[OBJECT]->SUPER::get_playlist_pos(splice(@_,ARG0));
}

sub set_playlist_pos {
	my $r = $_[OBJECT]->SUPER::set_playlist_pos(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub get_playlist_files {
	return $_[OBJECT]->SUPER::get_playlist_files(splice(@_,ARG0));
}

sub get_version {
	return $_[OBJECT]->SUPER::get_version(splice(@_,ARG0));
}

sub is_running {
	return $_[OBJECT]->SUPER::is_running(splice(@_,ARG0));
}

sub show_prefs_box {
	my $r = $_[OBJECT]->SUPER::show_prefs_box(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub set_skin {
	my $r = $_[OBJECT]->SUPER::set_skin(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub all_win_toggle {
	my $r = $_[OBJECT]->SUPER::all_win_toggle(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub get_playlist_titles {
	return $_[OBJECT]->SUPER::get_playlist_titles(splice(@_,ARG0));
}

sub get_playlist_title {
	return $_[OBJECT]->SUPER::get_playlist_title(splice(@_,ARG0));
}

sub eject {
	my $r = $_[OBJECT]->SUPER::eject(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub playlist_next {
	my $r = $_[OBJECT]->SUPER::playlist_next(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub playlist_prev {
	my $r = $_[OBJECT]->SUPER::playlist_prev(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub pause {
	my $r = $_[OBJECT]->SUPER::pause(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub toggle_shuffle {
	my $r = $_[OBJECT]->SUPER::toggle_shuffle(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub toggle_repeat {
	my $r = $_[OBJECT]->SUPER::toggle_repeat(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

# TODO test if client has this
sub playlist_delete {
	my $r = $_[OBJECT]->SUPER::playlist_delete(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub playlist_add {
	my $r = $_[OBJECT]->SUPER::playlist_add(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

# TODO test if client has this
sub playlist_add_url {
	my $r = $_[OBJECT]->SUPER::playlist_add_url(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub jump_to_timestr {
	my $r = $_[OBJECT]->SUPER::jump_to_timestr(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub jump_to_time {
	my $r = $_[OBJECT]->SUPER::jump_to_time(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub get_playlist_timestr {
	my $r = $_[OBJECT]->SUPER::get_playlist_timestr(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub is_main_win {
	return $_[OBJECT]->SUPER::is_main_win(splice(@_,ARG0));
}

sub is_pl_win {
	return $_[OBJECT]->SUPER::is_pl_win(splice(@_,ARG0));
}

sub is_eq_win {
	return $_[OBJECT]->SUPER::is_eq_win(splice(@_,ARG0));
}

sub get_eq {
	return $_[OBJECT]->SUPER::get_eq(splice(@_,ARG0));
}

sub set_eq {
	my $r = $_[OBJECT]->SUPER::set_eq(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub get_eq_preamp {
	return $_[OBJECT]->SUPER::get_eq_preamp(splice(@_,ARG0));
}

sub set_eq_preamp {
	my $r = $_[OBJECT]->SUPER::set_eq_preamp(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

sub get_eq_band {
	return $_[OBJECT]->SUPER::get_eq_band(splice(@_,ARG0));
}

sub set_eq_band {
	my $r = $_[OBJECT]->SUPER::set_eq_band(splice(@_,ARG0));
	Xmms::sleep(0.25);
	return $r;
}

1;

__END__

=head1 NAME

POE::Component::Player::Xmms - a wrapper for the C<Xmms> player

=head1 SYNOPSIS

	use POE qw(Component::Player::Xmms);

	POE::Component::Player::Xmms->spawn({ alias => 'xmms' });
	$kernel->post(xmms => play => 'test.mp3');

	POE::Kernel->run();

=head1 DESCRIPTION

This component is used to manipulate the C<Xmms> player from within a 
POE application.

=head1 METHODS

=head2 spawn

Used to initialise the system and create a module instance. 
The optional hash reference may contain any of the following keys:

=item alias

Indicates the name of a session to which events will be posted.  
Default: C<main>.

=item xargs

Allows for passing extra arguments to the underlying application.
(NOT used if already running)

=head1 EVENTS

=head2 Xmms::Remote events

The methods available to Xmms::Remote are dupicated as events, heres the list:

	playlist_clear,
	playlist,
	play,
	get_playlist_length,
	get_volume,
	set_main_volume,
	get_main_volume,
	is_repeat,
	is_shuffle,
	get_info,
	get_playlist_file,
	get_playlist_time,
	set_volume,
	get_balance,
	get_balancestr,
	set_balance,
	get_skin,
	toggle_aot,
	main_win_toggle,
	pl_win_toggle,
	eq_win_toggle,
	prefs_win_toggle,
	get_output_time,
	get_output_timestr,
	stop,
	is_playing,
	quit,
	get_playlist_pos,
	set_playlist_pos,
	get_playlist_files,
	get_version,
	is_running,
	show_prefs_box,
	set_skin,
	all_win_toggle,
	get_playlist_titles,
	get_playlist_title,
	eject,
	playlist_next,
	playlist_prev,
	pause,
	toggle_shuffle,
	toggle_repeat,
	playlist_delete,
	playlist_add,
	playlist_add_url,
	jump_to_timestr,
	jump_to_time,
	get_playlist_timestr,
	is_main_win,
	is_pl_win,
	is_eq_win,
	get_eq,
	set_eq,
	get_eq_preamp,
	set_eq_preamp,
	get_eq_band,
	set_eq_band


For now, just $kernel->call these to get the return values. 
I will document these and add event replys for everything later.

=head1 EVENTS

Events are fired at the session from which the I<spawn()> method 
as called from. Currently there is only one event fired.

=head2 xmms_started

This event is fired by the player's notification that it's ready.

=head1 AUTHOR

David Davis <xantus@cpan.org>

=head1 TODO

Better documentation on ALL events

Patches welcome :)

=head1 SEE ALSO

perl(1), L<Xmms::Remote>

