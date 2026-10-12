package Term::Fabulous::Screenshot::Scenario;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

class Term::Fabulous::Screenshot::Scenario :strict(params) {
	use Carp qw(croak);
	use Encode qw(decode);
	use Feature::Compat::Try;
	use Text::KDL::XS qw(parse_kdl);
	use Time::Local qw(timegm);
	use Term::Fabulous::Screenshot::Input qw(key_bytes text_bytes mouse_bytes);

	# Virtual seconds between the start of the program's event loop and the
	# first step, and between the last step and the screenshot.
	use constant STARTUP_SECONDS => 0.5;
	use constant SETTLE_SECONDS  => 0.5;

	# Typed text is sent in pieces of this many characters, each a step of
	# its own, so no write exceeds what a terminal holds unread.
	use constant TYPED_CHARACTERS_PER_SEND => 256;

	use constant DEFAULT_COLUMNS => 80;
	use constant DEFAULT_ROWS    => 24;
	use constant DEFAULT_CLOCK   => '2026-06-01T09:41:00Z';

	field $name      :param :reader;
	field $script    :param :reader;
	field $arguments :param :reader = [];
	field $columns   :param :reader = DEFAULT_COLUMNS;
	field $rows      :param :reader = DEFAULT_ROWS;
	field $title     :param :reader = undef;
	field $epoch     :param :reader = _parse_clock(DEFAULT_CLOCK);

	# Lines a shell printed before the program started, shown above an
	# inline region.
	field $shell :param :reader = [];

	# The steps for the harness: { action => 'wait', seconds } and
	# { action => 'send', bytes } (hexadecimal).
	field $steps :param = [];

	ADJUST {
		croak "Term::Fabulous::Screenshot::Scenario: '$name' is not a valid screenshot name (lowercase letters, digits and dashes)" unless $name =~ /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/;
		croak "Term::Fabulous::Screenshot::Scenario: $name: the terminal size must be positive whole numbers, got ${columns}x$rows"
			unless $columns =~ /\A[1-9][0-9]*\z/ && $rows =~ /\A[1-9][0-9]*\z/;
		$title //= join ' ', 'perl', $script, map { _shell_word($_) } @$arguments;
	}

	# An argument as a shell would need it typed: quoted when it holds
	# anything but plain word characters.
	sub _shell_word ($argument) {
		return $argument if $argument =~ m{\A[\w\@%+=:,./-]+\z};
		return "'" . ( $argument =~ s/'/'\\''/gr ) . "'";
	}

	method harness_steps () {
		return [ { action => 'wait', seconds => STARTUP_SECONDS }, @$steps, { action => 'wait', seconds => SETTLE_SECONDS } ];
	}

	# Every screenshot of a scenario file. A 'defaults' node sets values
	# for all screenshots after it.
	sub from_file ( $class, $file ) {
		open my $handle, '<:raw', $file or croak "Term::Fabulous::Screenshot::Scenario: cannot read $file: $!";
		my $bytes = do { local $/; <$handle> };
		close $handle;
		my $source = decode( 'UTF-8', $bytes, Encode::FB_CROAK );
		return $class->from_string( $source, $file );
	}

	sub from_string ( $class, $source, $origin = 'the scenarios' ) {
		my $document;
		try {
			$document = parse_kdl($source);
		}
		catch ($error) {
			croak "Term::Fabulous::Screenshot::Scenario: $origin is not valid KDL: $error";
		}

		my ( %defaults, @scenarios, %seen );
		foreach my $node ( @{ $document->nodes } ) {
			if ( $node->name eq 'defaults' ) {
				_no_arguments( $node, $origin );
				%defaults = ( %defaults, _settings( $node, $origin, 'defaults' ) );
				next;
			}
			croak "Term::Fabulous::Screenshot::Scenario: $origin: unknown node '" . $node->name . "' (expected 'defaults' or 'screenshot')" unless $node->name eq 'screenshot';

			my $screenshot_name = _single_string( $node, $origin, 'screenshot' );
			croak "Term::Fabulous::Screenshot::Scenario: $origin: the screenshot '$screenshot_name' is defined twice" if $seen{$screenshot_name}++;
			my %settings = ( %defaults, _settings( $node, $origin, $screenshot_name ) );
			croak "Term::Fabulous::Screenshot::Scenario: $origin: the screenshot '$screenshot_name' has no script" unless defined $settings{script};
			push @scenarios, $class->new( name => $screenshot_name, %settings );
		}
		return @scenarios;
	}

	# The settings a 'screenshot' or 'defaults' node holds, ready for new().
	sub _settings ( $node, $origin, $context ) {
		my %settings;
		foreach my $setting ( @{ $node->children } ) {
			my $where = "$origin: $context: " . $setting->name;
			my $name  = $setting->name;
			if ( $name eq 'script' ) {
				$settings{script} = _single_string( $setting, $where, 'script' );
			}
			elsif ( $name eq 'args' ) {
				$settings{arguments} = [ map { _string_value( $_, $where ) } @{ $setting->args } ];
			}
			elsif ( $name eq 'size' ) {
				my @size = _numbers( $setting, $where, 2 );
				@settings{qw(columns rows)} = @size;
			}
			elsif ( $name eq 'title' ) {
				$settings{title} = _single_string( $setting, $where, 'title' );
			}
			elsif ( $name eq 'clock' ) {
				$settings{epoch} = _parse_clock( _single_string( $setting, $where, 'clock' ), $where );
			}
			elsif ( $name eq 'shell' ) {
				my @lines = map { _string_value( $_, $where ) } @{ $setting->args };
				croak "Term::Fabulous::Screenshot::Scenario: $where: give at least one line, and no properties" unless @lines && !@{ $setting->props };
				croak "Term::Fabulous::Screenshot::Scenario: $where: a line must not contain control characters" if grep { /[\x00-\x1f\x7f]/ } @lines;
				$settings{shell} = \@lines;
			}
			elsif ( $name eq 'steps' ) {
				$settings{steps} = [ map { _compile_step( $_, "$origin: $context: steps" ) } @{ $setting->children } ];
			}
			else {
				croak "Term::Fabulous::Screenshot::Scenario: $where: unknown setting (known: script, args, size, title, clock, shell, steps)";
			}
		}
		return %settings;
	}

	# One step of a 'steps' block as harness steps: every key, click and
	# move is a separate write, as from a real terminal.
	sub _compile_step ( $step, $origin ) {
		my $name          = $step->name;
		my $where         = "$origin: $name";
		my %props         = map { $_->[0] => $_->[1]->as_perl } @{ $step->props };
		my %allowed_props = ( click => ['button'], drag => ['button'], wheel => [qw(direction notches)] );
		my %is_allowed    = map       { $_ => 1 } @{ $allowed_props{$name} // [] };
		my @unknown       = sort grep { !$is_allowed{$_} } keys %props;
		croak "Term::Fabulous::Screenshot::Scenario: $where: unknown properties " . join( ', ', @unknown ) if @unknown;

		my $button = $props{button} // 'left';
		my $send   = sub (@chunks) {
			map { { action => 'send', bytes => unpack( 'H*', $_ ) } } @chunks;
		};
		my $sent = sub ($code) { $send->( _croak_from( $where, $code ) ) };

		if ( $name eq 'wait' ) {
			my ($seconds) = _numbers( $step, $where, 1 );
			return { action => 'wait', seconds => $seconds };
		}
		if ( $name eq 'type' ) {
			my $text = _single_string( $step, $where, 'type' );
			return $sent->(
				sub {
					map { text_bytes($_) } length $text ? unpack( '(a' . TYPED_CHARACTERS_PER_SEND . ')*', $text ) : ($text);
				}
			);
		}
		if ( $name eq 'key' ) {
			my @keys = map { _string_value( $_, $where ) } @{ $step->args };
			croak "Term::Fabulous::Screenshot::Scenario: $where: name at least one key" unless @keys;
			return $sent->(
				sub {
					map { key_bytes($_) } @keys;
				}
			);
		}
		if ( $name eq 'click' ) {
			my ( $x, $y ) = _numbers( $step, $where, 2 );
			return $sent->( sub { mouse_bytes( press => $x, $y, $button ), mouse_bytes( release => $x, $y, $button ) } );
		}
		if ( $name eq 'move' ) {
			my ( $x, $y ) = _numbers( $step, $where, 2 );
			return $sent->( sub { mouse_bytes( move => $x, $y ) } );
		}
		if ( $name eq 'drag' ) {
			my @numbers = _numbers( $step, $where );
			croak "Term::Fabulous::Screenshot::Scenario: $where: give two or more points (x y x y ...)" unless @numbers >= 4 && @numbers % 2 == 0;
			my @points = map { [ @numbers[ 2 * $_, 2 * $_ + 1 ] ] } 0 .. @numbers / 2 - 1;
			my $start  = shift @points;
			return $sent->(
				sub {
					mouse_bytes( press => @$start, $button ), ( map { mouse_bytes( drag => @$_, $button ) } @points ), mouse_bytes( release => @{ $points[-1] }, $button );
				}
			);
		}
		if ( $name eq 'wheel' ) {
			my $direction = $props{direction} // croak "Term::Fabulous::Screenshot::Scenario: $where: give direction=\"up\" or direction=\"down\"";
			my $notches   = $props{notches}   // 1;
			croak "Term::Fabulous::Screenshot::Scenario: $where: direction must be 'up' or 'down'" unless $direction eq 'up' || $direction eq 'down';
			croak "Term::Fabulous::Screenshot::Scenario: $where: notches must be a positive whole number" unless $notches =~ /\A[1-9][0-9]*\z/;
			my ( $x, $y ) = _numbers( $step, $where, 2 );
			return $sent->(
				sub {
					map { mouse_bytes( "wheel_$direction" => $x, $y ) } 1 .. $notches;
				}
			);
		}
		croak "Term::Fabulous::Screenshot::Scenario: $where: unknown step (known: wait, type, key, click, move, drag, wheel)";
	}

	# Runs $code and reports its error as one at $where.
	sub _croak_from ( $where, $code ) {
		my @result;
		try {
			@result = $code->();
		}
		catch ($error) {
			$error =~ s/ at \S+ line \d+\.?\n\z//;
			croak "Term::Fabulous::Screenshot::Scenario: $where: $error";
		}
		return @result;
	}

	sub _no_arguments ( $node, $origin ) {
		croak "Term::Fabulous::Screenshot::Scenario: $origin: '" . $node->name . "' takes no arguments" if @{ $node->args } || @{ $node->props };
		return;
	}

	sub _single_string ( $node, $where, $what ) {
		my @args = @{ $node->args };
		croak "Term::Fabulous::Screenshot::Scenario: $where: '$what' takes one string" unless @args == 1 && $args[0]->is_string;
		return $args[0]->as_string;
	}

	sub _string_value ( $value, $where ) {
		croak "Term::Fabulous::Screenshot::Scenario: $where: expected strings" unless $value->is_string;
		return $value->as_string;
	}

	# The node's arguments as non-negative numbers; exactly $count of them
	# when $count is given.
	sub _numbers ( $node, $where, $count = undef ) {
		my @args = @{ $node->args };
		croak "Term::Fabulous::Screenshot::Scenario: $where: expected $count number" . ( $count == 1 ? '' : 's' ) if defined $count && @args != $count;
		croak "Term::Fabulous::Screenshot::Scenario: $where: expected non-negative numbers" if grep { !$_->is_number || $_->as_number < 0 } @args;
		return map                                                                                  { $_->as_number } @args;
	}

	sub _parse_clock ( $text, $where = 'clock' ) {
		my ( $year, $month, $day, $hour, $minute, $second ) = $text =~ /\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)Z\z/
			or croak "Term::Fabulous::Screenshot::Scenario: $where: '$text' is not a UTC time like 2026-06-01T09:41:00Z";
		return timegm( $second, $minute, $hour, $day, $month - 1, $year );
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Scenario - What to run and do before a
screenshot is taken

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Scenario;

	my @scenarios = Term::Fabulous::Screenshot::Scenario->from_file('screenshots/screenshots.kdl');
	foreach my $scenario (@scenarios) {
		say $scenario->name, ': ', $scenario->script;
	}

=head1 DESCRIPTION

Maintainer tool, not installed. A scenario names a screenshot and says
how to take it: which program to run in a terminal of which size, and
which input to give it first. Scenarios are written in KDL, one
C<screenshot> node each; see L</THE SCENARIO FILE>. They are parsed
completely when they are read: an unknown setting, a key a terminal
cannot send or a malformed number dies with the screenshot's name
before any program runs.

=head1 THE SCENARIO FILE

	// Settings for all screenshots after this node.
	defaults {
		size 80 24
		clock "2026-06-01T09:41:00Z"
	}

	screenshot "login-form" {
		script "examples/cookbook/login-form.pl"
		size 60 14
		steps {
			type "ada"
			key "Tab"
			type "secret"
			key "Tab" "Space" "Enter"
		}
	}

=head2 Settings

=over

=item C<script "PATH">

The program to run, relative to the distribution's top directory.
Required.

=item C<args "ARG" ...>

Arguments for the program.

=item C<size COLUMNS ROWS>

The terminal size. Default: 80 24.

=item C<title "TEXT">

The window title. Default: C<perl>, the script and its arguments,
quoted as a shell needs them.

=item C<clock "YYYY-MM-DDTHH:MM:SSZ">

The time the program's clock starts at, in UTC. Every program runs with
C<TZ=UTC>. Default: C<2026-06-01T09:41:00Z>.

=item C<shell "LINE" ...>

For a program in inline mode (L<Term::Fabulous/INLINE MODE>): the lines
a shell printed before the program started, for example a prompt and the
command that started it. The terminal's cursor starts at the beginning
of the row below the last line, or on the last row of the terminal when
the lines fill it, and the terminal answers the program's cursor
position query (C<ESC [ 6 n>) with that position. The screenshot shows
the lines directly above the region the program drew into; lines the
program scrolled up out of the terminal are not shown. A line must fit
the terminal's width. A program that does not draw into an inline region
dies with a message, because a full-screen program would cover the
lines.

Without C<shell>, the cursor starts in the top-left corner, so an
inline region starts on the first row.

=item C<steps { ... }>

What happens before the screenshot, in order. The steps start half a
(virtual) second after the program's event loop started, and the screen
is captured half a second after the last step. Every input is written to
the terminal by itself and followed by 0.1 seconds for the program to
react.

=back

=head2 Steps

Cells count from 0, from the top-left corner of the terminal.

=over

=item C<wait SECONDS>

Lets the program run, in virtual time: timers fire and frames are drawn
as they would in that time.

=item C<type "TEXT">

Types the text.

=item C<key "NAME" ...>

Presses each key in turn; names as in
L<Term::Fabulous::Event::KeyPress/key_name>, such as C<Tab>, C<Enter>,
C<Ctrl+R> or C<F2> (see L<Term::Fabulous::Screenshot::Input/key_bytes>).

=item C<click X Y [button="left|middle|right"]>

Presses and releases a mouse button on a cell.

=item C<drag X1 Y1 X2 Y2 ... [button=...]>

Presses the button on the first cell, moves through the others with
the button held and releases it on the last.

=item C<move X Y>

Moves the pointer to a cell without a button held (hover).

=item C<wheel X Y direction="up|down" [notches=N]>

Turns the mouse wheel over a cell.

=back

=head1 CONSTRUCTORS

=head2 from_file, from_string

	my @scenarios = Term::Fabulous::Screenshot::Scenario->from_file($path);
	my @scenarios = Term::Fabulous::Screenshot::Scenario->from_string( $kdl, $origin );

All screenshots of a scenario file (UTF-8) or string. C<$origin> names
the source in error messages.

=head2 new

	Term::Fabulous::Screenshot::Scenario->new( name => 'form', script => 'examples/form.pl', steps => [ ... ] );

Takes C<name>, C<script>, C<arguments>, C<columns>, C<rows>, C<title>,
C<epoch>, C<shell> and C<steps> (harness steps; see
L<Term::Fabulous::Screenshot::Harness/CONFIGURATION>).

=head1 METHODS

=head2 name, script, arguments, columns, rows, title, epoch, shell

The settings.

=head2 harness_steps

The steps for L<Term::Fabulous::Screenshot::Runner/capture>, with the
start-up and settling waits added.

=cut
