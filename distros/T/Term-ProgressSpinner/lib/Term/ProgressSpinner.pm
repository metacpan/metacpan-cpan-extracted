package Term::ProgressSpinner; 
our $VERSION = '0.04';
use 5.006; use strict; use warnings;
use IO::Handle; use Term::ANSIColor; use Time::HiRes qw//;
use Term::Size::Any qw/chars/;
if ($^O eq 'MSWin32') { eval "use Win32::Console::ANSI; use Win32::Console;"; }
our (%SPINNERS, %PROGRESS, %VALIDATE);

BEGIN {
	%VALIDATE = (
		colours => { 
			map { 
				my $c = $_;
				(
					$c => 1, 
					"bright_${c}" => 1,
					(map { (
						"${c} on_${_}" => 1,
						"${c} on_bright_${_}" => 1,
						"bright_${c} on_${_}" => 1,
						"bright_${c} on_bright_${_}" => 1,
					) } qw/black red green yellow blue magenta cyan white/)
				)
			} qw/black red green yellow blue magenta cyan white/ 
		},
		msg_regex => qr/\{(total|progress|spinner|percents|percentage|percentages|percent|counter|elapsed|elapsed_second|estimate|estimate_second|start_epoch|start_epoch_second|epoch|epoch_second|per_second|last_advance_epoch|last_advance_epoch_second|last_elapsed|last_elapsed_second|elapsed|elapsed_second)\}/
	);
	%SPINNERS = (
		bar => {
			width => 3,
			index => [4, 2, 6], 
			chars => [
				"▁",
				"▂",
				"▃",
				"▄",
				"▅",
				"▆",
				"▇",
				"█"
			]
		},
		dots => {
			width => 1,
			index => [1],
			chars => [
				"⠋",
				"⠙",
				"⠹",
				"⠸",
				"⠼",
				"⠴",
				"⠦",
				"⠧",
				"⠇",
				"⠏"
			]
		},
		around => {
			width => 1,
			index => [1],
			chars => [
				"⢀⠀",
				"⡀⠀",
				"⠄⠀",
				"⢂⠀",
				"⡂⠀",
				"⠅⠀",
				"⢃⠀",
				"⡃⠀",
				"⠍⠀",
				"⢋⠀",
				"⡋⠀",
				"⠍⠁",
				"⢋⠁",
				"⡋⠁",
				"⠍⠉",
				"⠋⠉",
				"⠋⠉",
				"⠉⠙",
				"⠉⠙",
				"⠉⠩",
				"⠈⢙",
				"⠈⡙",
				"⢈⠩",
				"⡀⢙",
				"⠄⡙",
				"⢂⠩",
				"⡂⢘",
				"⠅⡘",
				"⢃⠨",
				"⡃⢐",
				"⠍⡐",
				"⢋⠠",
				"⡋⢀",
				"⠍⡁",
				"⢋⠁",
				"⡋⠁",
				"⠍⠉",
				"⠋⠉",
				"⠋⠉",
				"⠉⠙",
				"⠉⠙",
				"⠉⠩",
				"⠈⢙",
				"⠈⡙",
				"⠈⠩",
				"⠀⢙",
				"⠀⡙",
				"⠀⠩",
				"⠀⢘",
				"⠀⡘",
				"⠀⠨",
				"⠀⢐",
				"⠀⡐",
				"⠀⠠",
				"⠀⢀",
				"⠀⡀"
			]
		},
		pipe => {
			width => 1,
			index => [1],
			chars => [
				"┤",
				"┘",
				"┴",
				"└",
				"├",
				"┌",
				"┬",
				"┐"
			]
		},
		moon => {
			width => 1,
			index => [1],
			chars => [
				"🌑 ",
				"🌒 ",
				"🌓 ",
				"🌔 ",
				"🌕 ",
				"🌖 ",
				"🌗 ",
				"🌘 "
			]
		},
		circle => {
			width => 1,
			index => [1],
			chars => [
				"・",
				"◦",
				"●",
				"○",
				"◎",
				"◉",
				"⦿",
				"◉",
				"◎",
				"○",
				"◦",
				"・",
			]
		},
		color_circle => {
			width => 1,
			index => [1],
			chars => [
				"🔴",
				"🟠",
				"🟡",
				"🟢",
				"🔵",
				"🟣",
				"⚫️",
				"⚪️",
				"🟤"
			]
		},
		color_circles => {
			width => 3,
			index => [1, 4, 7],
			chars => [
				"🔴",
				"🟠",
				"🟡",
				"🟢",
				"🔵",
				"🟣",
				"⚫️",
				"⚪️",
				"🟤"
			]
		},
		color_square => {
			width => 1,
			index => [1],
			chars => [
				"🟥",
				"🟧",
				"🟨",
				"🟩",
				"🟦",
				"🟪",
				"⬛️",
				"⬜️",
				"🟫"
			]
		},
		color_squares => {
			width => 3,
			index => [1, 3, 6],
			chars => [
				"🟥",
				"🟧",
				"🟨",
				"🟩",
				"🟦",
				"🟪",
				"⬛️",
				"⬜️",
				"🟫"
			]
		},
		earth => {
			width => 1,
			index => [1],
			chars => [
				"🌎",
				"🌍",
				"🌏"
			]
		},
		circle_half => {
			width => 1,
			index => [1],
			chars => [
				'◐',
				'◓',
				'◑',
				'◒'
			]
		},
		clock => {
			width => 1,
			index => [1],
			chars => [
				"🕛 ",
				"🕐 ",
				"🕑 ",
				"🕒 ",
				"🕓 ",
				"🕔 ",
				"🕕 ",
				"🕖 ",
				"🕗 ",
				"🕘 ",
				"🕙 ",
				"🕚 "
			]
		},
		pong => {
			width => 1,
			index => [1],
			chars => [
				"▐⠂       ▌",
				"▐⠈       ▌",
				"▐ ⠂      ▌",
				"▐ ⠠      ▌",
				"▐  ⡀     ▌",
				"▐  ⠠     ▌",
				"▐   ⠂    ▌",
				"▐   ⠈    ▌",
				"▐    ⠂   ▌",
				"▐    ⠠   ▌",
				"▐     ⡀  ▌",
				"▐     ⠠  ▌",
				"▐      ⠂ ▌",
				"▐      ⠈ ▌",
				"▐       ⠂▌",
				"▐       ⠠▌",
				"▐       ⡀▌",
				"▐      ⠠ ▌",
				"▐      ⠂ ▌",
				"▐     ⠈  ▌",
				"▐     ⠂  ▌",
				"▐    ⠠   ▌",
				"▐    ⡀   ▌",
				"▐   ⠠    ▌",
				"▐   ⠂    ▌",
				"▐  ⠈     ▌",
				"▐  ⠂     ▌",
				"▐ ⠠      ▌",
				"▐ ⡀      ▌",
				"▐⠠       ▌"
			]
		},
		material => {
			width => 1,
			index => [1],
			chars => [
				"█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"██▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"███▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"████▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"██████▁▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"██████▁▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"███████▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"████████▁▁▁▁▁▁▁▁▁▁▁▁",
				"█████████▁▁▁▁▁▁▁▁▁▁▁",
				"█████████▁▁▁▁▁▁▁▁▁▁▁",
				"██████████▁▁▁▁▁▁▁▁▁▁",
				"███████████▁▁▁▁▁▁▁▁▁",
				"█████████████▁▁▁▁▁▁▁",
				"██████████████▁▁▁▁▁▁",
				"██████████████▁▁▁▁▁▁",
				"▁██████████████▁▁▁▁▁",
				"▁██████████████▁▁▁▁▁",
				"▁██████████████▁▁▁▁▁",
				"▁▁██████████████▁▁▁▁",
				"▁▁▁██████████████▁▁▁",
				"▁▁▁▁█████████████▁▁▁",
				"▁▁▁▁██████████████▁▁",
				"▁▁▁▁██████████████▁▁",
				"▁▁▁▁▁██████████████▁",
				"▁▁▁▁▁██████████████▁",
				"▁▁▁▁▁██████████████▁",
				"▁▁▁▁▁▁██████████████",
				"▁▁▁▁▁▁██████████████",
				"▁▁▁▁▁▁▁█████████████",
				"▁▁▁▁▁▁▁█████████████",
				"▁▁▁▁▁▁▁▁████████████",
				"▁▁▁▁▁▁▁▁████████████",
				"▁▁▁▁▁▁▁▁▁███████████",
				"▁▁▁▁▁▁▁▁▁███████████",
				"▁▁▁▁▁▁▁▁▁▁██████████",
				"▁▁▁▁▁▁▁▁▁▁██████████",
				"▁▁▁▁▁▁▁▁▁▁▁▁████████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁███████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁██████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█████",
				"█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁████",
				"██▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁███",
				"██▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁███",
				"███▁▁▁▁▁▁▁▁▁▁▁▁▁▁███",
				"████▁▁▁▁▁▁▁▁▁▁▁▁▁▁██",
				"█████▁▁▁▁▁▁▁▁▁▁▁▁▁▁█",
				"█████▁▁▁▁▁▁▁▁▁▁▁▁▁▁█",
				"██████▁▁▁▁▁▁▁▁▁▁▁▁▁█",
				"████████▁▁▁▁▁▁▁▁▁▁▁▁",
				"█████████▁▁▁▁▁▁▁▁▁▁▁",
				"█████████▁▁▁▁▁▁▁▁▁▁▁",
				"█████████▁▁▁▁▁▁▁▁▁▁▁",
				"█████████▁▁▁▁▁▁▁▁▁▁▁",
				"███████████▁▁▁▁▁▁▁▁▁",
				"████████████▁▁▁▁▁▁▁▁",
				"████████████▁▁▁▁▁▁▁▁",
				"██████████████▁▁▁▁▁▁",
				"██████████████▁▁▁▁▁▁",
				"▁██████████████▁▁▁▁▁",
				"▁██████████████▁▁▁▁▁",
				"▁▁▁█████████████▁▁▁▁",
				"▁▁▁▁▁████████████▁▁▁",
				"▁▁▁▁▁████████████▁▁▁",
				"▁▁▁▁▁▁███████████▁▁▁",
				"▁▁▁▁▁▁▁▁█████████▁▁▁",
				"▁▁▁▁▁▁▁▁█████████▁▁▁",
				"▁▁▁▁▁▁▁▁▁█████████▁▁",
				"▁▁▁▁▁▁▁▁▁█████████▁▁",
				"▁▁▁▁▁▁▁▁▁▁█████████▁",
				"▁▁▁▁▁▁▁▁▁▁▁████████▁",
				"▁▁▁▁▁▁▁▁▁▁▁████████▁",
				"▁▁▁▁▁▁▁▁▁▁▁▁███████▁",
				"▁▁▁▁▁▁▁▁▁▁▁▁███████▁",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁███████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁███████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁████",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁███",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁███",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁██",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁██",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁██",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁",
				"▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"

			]

		}
	);
	$SPINNERS{default} = $SPINNERS{bar};
	%PROGRESS = (
		bar => {
			chars =>  ['│', "█", '│']
		},
		equal => {
			chars =>  ['[', "=", ']']
		},
		arrow => {
			chars =>  ['│', "→", '│']
		},
		boxed_arrow => {
			chars =>  ['│', "⍈", '│']
		},
		lines => {
			chars =>  ['│', "≡", '│']
		},
		horizontal_lines => {
			chars =>  ['│', "▤", '│']
		},
		vertical_lines => {
			chars =>  ['│', "▥", '│']
		},
		hash => {
			chars =>  ['[', "#", ']']
		},
		triangle => {
			chars => ['│', '▶︎', '│' ]
		},
		den_triangle => {
			chars => ['│', '⏅', '│' ]
		},
		circle => {
			chars => ['│', 'Ⓞ', '│' ]
		},
		den_circle => {
			chars => ['│', '⏂', '│' ]
		},
		shekel => {
			chars => ['│', '₪', '│' ]
		},
		dots => {
			chars => ['│', '▒', '│' ]
		},
		square => {
			chars => ['│', '■', '│' ]
		},
		block => {
			chars => ["【", "=", "】"]
		}
	);
	$PROGRESS{default} = $PROGRESS{bar};
}

sub new {
	my ($pkg, %args) = (shift, ref $_[0] ? %{$_[0]} : @_);
	$args{$_} and ($VALIDATE{colours}{$args{$_}} or die "Invalid color for $_")
		for qw/text_color total_color counter_color percent_color percentage_color percentages_color percents_color spinner_color progress_color elapsed_color last_elapsed_color estimate_color last_advance_epoch_color start_epoch_color epoch_color/;
	return bless {
		text_color => 'white',
		total_color => 'white',
		counter_color => 'white',
		percent_color => 'white',
		percentage_color => 'white',
		percentages_color => 'white',
		percents_color => 'white',
		spinner_color => 'white',
		elapsed_color => 'white',
		start_epoch_color => 'white',
		last_elapsed_color => 'white',
		last_advance_epoch_color => 'white',
		estimate_color => 'white',
		epoch_color => 'white',
		per_second_color => 'white',
		spinner_options => $SPINNERS{ $args{spinner} || 'default' },
		progress_color => 'white',
		progress_width => 20,
		progress_options => $PROGRESS{ $args{progress} || 'default' },
		output => \*STDERR,
		progress_spinner_index => 0,
		progress_spinners => [],
		message => "{progress} {spinner} processed {percents} of {counter}/{total} {elapsed}/{estimate}",
		terminal_height => 0,
		terminal_line => 0,
		%args
	}, ref $pkg || $pkg;
}

sub progress_spinner_index {
	my ($self, $val) = @_;
	if (defined $val) {
		if (ref $val || $val !~ m/\d+/) {
			die 'progress_spinner_index should be a integer';
		}
		$self->{progress_spinner_index} = $val;
	}
	return $self->{progress_spinner_index};
}

sub terminal_height {
	my ($self, $val) = @_;
	if (defined $val) {
		if (ref $val || $val !~ m/\d+/) {
			die 'terminal_height should be a integer';
		}
		$self->{terminal_height} = $val;
	}
	return $self->{terminal_height};
}

sub terminal_line {
	my ($self, $val) = @_;
	if (defined $val) {
		if (ref $val || $val !~ m/\d+/) {
			die 'terminal_line should be a integer';
		}
		$self->{terminal_line} = $val;
	}
	return $self->{terminal_line};
}

sub progress_spinners {
	my ($self, $val) = @_;
	if (defined $val) {
		if (ref $val || "" ne 'ARRAY') {
			die 'progress_spinners should be a array';
		}
		$self->{progress_spinners} = $val;
	}
	return $self->{progress_spinners};
}

sub savepos {
	my $self = shift;
	my ($col, $rows) = $self->terminal_height ? (0, $self->terminal_height) : (Term::Size::Any::chars($self->output));
	my $x = '';
	if ($self->terminal_line) {
		$x = $self->terminal_line;
	} elsif ($^O eq 'MSWin32') {
		my $CONSOLE = Win32::Console->new(Win32::Console::STD_OUTPUT_HANDLE());
		($x) = $CONSOLE->Cursor();
	} else {
		system "stty cbreak </dev/tty >/dev/tty 2>&1";
		$self->output->print("\e[6n");
		$x .= getc STDIN for 0 .. 5;
		system "stty -cbreak </dev/tty >/dev/tty 2>&1";
		my($n, $m)=$x=~m/(\d+)\;(\d+)/;
		$x = $n;
		$self->clear();
	}
	if ($x == $rows) {
		$x--;
		for (@{ $self->progress_spinners }) {
			$_->{savepos} = $_->{savepos} - 1;
		}
	}
	$self->{savepos} = $x;
}

sub loadpos {
	my $self = shift;
	my $pos = $self->{savepos};
	$self->output->print("\e[$pos;1f");
}

sub start {
	my ($self, $total) = @_;
	$self->total($total) if $total;
	$self->start_epoch(Time::HiRes::time);
	$self->output->print("\e[?25l");
	$self->savepos;
	$self->output->print("\n");
	my $ps = $self->new(%{$self});
	push @{ $self->progress_spinners }, $ps;
	$self->progress_spinner_index($self->progress_spinner_index + 1);
	return $ps;
}
 
sub advance {
	my ($self, $ps, $prevent) = @_;
	if ($ps) {
		if ($ps->counter < $ps->total) {
			$ps->counter($ps->counter + 1);
			my $spinner = $ps->spinner;
			for (1 .. $spinner->{width}) {
				my $index = $spinner->{index}->[$_ - 1];
				$spinner->{index}->[$_ - 1] = ($index + 1) % scalar @{$spinner->{chars}};
			}
			select(undef, undef, undef, $ps->slowed) if $ps->slowed;
			$ps->draw() unless $prevent;
		} else {
			$self->finish($ps);
		}
	} else {
		for my $spinner (@{$self->progress_spinners}) {
			$self->advance($spinner, 1);
		}
		scalar @{$self->{progress_spinners}} ? $self->draw() : $self->finish;
	}
}

sub time_advance_elapsed {
	my ($self) = @_;
	my %time = ();
	$time{epoch} = Time::HiRes::time;
	$time{start_epoch} = $self->start_epoch;
	$time{last_advance_epoch} = $self->last_advance_epoch || $time{start_epoch};
	$time{last_elapsed} = $time{epoch} - $time{last_advance_epoch};
	$time{elapsed} = $time{epoch} - $time{start_epoch};
	for (qw/epoch start_epoch last_advance_epoch last_elapsed elapsed/) {
		$time{"${_}_second"} = int($time{$_});
	}
	$self->last_advance_epoch($time{epoch});
	return %time;
}

sub draw {
	my ($self, $ps) = @_;
	if ($ps) {
		$ps->loadpos;
		$ps->clear();
		my ($spinner, $progress, $available, %options) = ($ps->spinner, $ps->progress, $ps->progress_width, $ps->time_advance_elapsed);
		$options{total} = $ps->total;	
		$options{counter} = $ps->counter;
		$options{spinner} = color($ps->spinner_color);
		$options{spinner} .= $spinner->{chars}->[
			$spinner->{index}->[$_ - 1]
		] for (1 .. $spinner->{width});
		$options{spinner} .= color($ps->text_color);
		$options{percent} = int( ( $options{counter} / $options{total} ) * 100 );
		$options{percentage} = ($available / 100) * $options{percent};
		$options{estimate} = $options{percent} ? (($options{elapsed} / $options{percent}) * 100) - $options{elapsed} : 0; 
		$options{estimate_second} = int($options{estimate} + 0.5);
		$options{per_second} = $options{elapsed_seconds} ? 
			$options{counter} / int($options{elapsed_second})
			: 0;
		$options{progress} = sprintf("%s%s%s%s%s",
			color($ps->progress_color),
			$progress->{chars}->[0],
			( $progress->{chars}->[1] x int($options{percentage} + 0.5) ) . ( ' ' x int( ($available - $options{percentage}) + 0.5 ) ),
			$progress->{chars}->[2],
			color($ps->text_color)
		);
		$options{percentages} = $options{percentage} . '%';
		$options{percents} = $options{percent} . '%'; 
		$options{$_} = sprintf ("%s%s%s",
			color($ps->{$_ . "_color"}),
			$options{$_},
			color($ps->text_color)
		) for (qw/total percent percents percentage counter per_second/);
		for (qw/elapsed last_elapsed estimate last_advance_epoch start_epoch epoch/) {
			$options{$_} = sprintf ("%s%s%s",
				color($ps->{$_ . "_color"}),
				$options{$_},
				color($ps->text_color)
			);
			$options{"${_}_second"} = sprintf ("%s%s%s",
				color($ps->{$_ . "_color"}),
				$options{"${_}_second"},
				color($ps->text_color)
			);
		}
		my $message = $ps->message;
		$message =~ s/$VALIDATE{msg_regex}/$options{$1}/ig;
		$message .= color('reset') . "\n";
		$ps->output->print($message);
		return $ps->drawn(1);
	} else {
		for my $spinner (@{$self->progress_spinners}) {
			$self->draw($spinner);
		}
		return $self->drawn(1);
	}
}
 
sub finish {
	my ($self, $sp) = @_;
	if ($sp && scalar @{$self->progress_spinners}) {
		my $i = 0;
		for (@{ $self->progress_spinners }) {
			if ($sp->progress_spinner_index == $_->progress_spinner_index) {
				last;
			}
			$i++;
		}
		splice @{$self->progress_spinners}, $i, 1;

	} else {
		$self->output->print("\e[?25h"); 
		$self->finished(1);
	}	
	return 0;
}

sub finished { 
	if (defined $_[1]) {
		$_[0]->{finished} = $_[1];
	}
	$_[0]->{finished};
}

sub drawn {
	my ($self, $val) = @_;
	if (defined $val) {
		$self->{drawn} = $val;
	}
	return $self->{drawn};
}
 
sub clear {
	my ($self) = @_;
	$self->output->print("\r\e[2K");
	$self->drawn(0);
}

sub message {
	my ($self, $val) = @_;
	if (defined $val) {
		if (ref $val) {
			die 'message should be a string';
		}
		$self->{message} = $val;
	}
	return $self->{message};
}

sub output {
	my ($self, $val) = @_;
	if (defined $val) {
		$self->{output} = $val;
	}
	return $self->{output};
}

sub total {
	my ($self, $val) = @_;
	if (defined $val) {
		if ($val !~ m/\d+/) {
			die "total should be a integer";
		}
		$self->{total} = $val;
		$self->{counter} = 0;
	}
	return $self->{total};
}

sub slowed {
	my ($self, $val) = @_;
	if (defined $val) {
		if ($val !~ m/\d+(\.\d+)?/) {
			die "slowed should be a float";
		}
		$self->{slowed} = $val;
	}
	return $self->{slowed};
}

sub counter {
	my ($self, $val) = @_;
	if (defined $val) {
		if ($val !~ m/\d+/) {
			die "counter should be a integer";
		}
		$self->{counter} = $val;
	}
	return $self->{counter};
}

sub start_epoch {
	my ($self, $val) = @_;
	if (defined $val) {
		if ($val !~ m/\d+(\.\d+)?/) {
			die "start_epoch should be a epoch";
		}
		$self->{start_epoch} = $val;
	}
	return $self->{start_epoch};
}

sub last_advance_epoch {
	my ($self, $val) = @_;
	if (defined $val) {
		if ($val !~ m/\d+(\.\d+)?/) {
			die "last_advance_epoch should be a epoch";
		}
		$self->{last_advance_epoch} = $val;
	}
	return $self->{last_advance_epoch};
}

sub text_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{text_color} = $val;
	}
	return $self->{text_color};
}

sub spinner {
	my ($self, $spinner) = @_;
	$self->{spinner_options} = $SPINNERS{$spinner} or die "Invalid spinner $spinner" if $spinner;
	$self->{spinner_options};
}

sub spinner_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{spinner_color} = $val;
	}
	return $self->{spinner_color};
}

sub progress {
	my ($self, $progress) = @_;
	$self->{progress_options} = $PROGRESS{$progress} or die "Invalid progress $progress" if $progress;
	$self->{progress_options};
}

sub progress_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{progress_color} = $val;
	}
	return $self->{progress_color};
}

sub progress_width {
	my ($self, $val) = @_;
	if (defined $val) {
		$self->{progress_width} = $val;
	}
	return $self->{progress_width};
}

sub percent_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{percent_color} = $val;
	}
	return $self->{percent_color};
}

sub percents_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{percents_color} = $val;
	}
	return $self->{percents_color};
}

sub percentage_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{percentage_color} = $val;
	}
	return $self->{percentage_color};
}

sub percentages_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{percentages_color} = $val;
	}
	return $self->{percentages_color};
}

sub total_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{total_color} = $val;
	}
	return $self->{total_color};
}

sub counter_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{counter_color} = $val;
	}
	return $self->{counter_color};
}

sub elapsed_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{elapsed_color} = $val;
	}
	return $self->{elapsed_color};
}

sub last_elapsed_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{last_elapsed_color} = $val;
	}
	return $self->{last_elapsed_color};
}

sub estimate_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{estimate_elapsed_color} = $val;
	}
	return $self->{estimate_elapsed_color};
}

sub last_advance_epoch_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{last_advance_epoch_color} = $val;
	}
	return $self->{last_advance_epoch_color};
}

sub start_epoch_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{start_epoch_color} = $val;
	}
	return $self->{start_epoch_color};
}

sub epoch_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{epoch_color} = $val;
	}
	return $self->{epoch_color};
}

sub per_second_color {
	my ($self, $val) = @_;
	if (defined $val) {
		unless ($VALIDATE{colours}{$val}) {
			die "$val is not a valid color";
		}
		$self->{per_second_color} = $val;
	}
	return $self->{per_second_color};
}

sub sleep {
	select(undef, undef, undef, $_[1]);
}

1;

__END__; 

=encoding utf8
 
=head1 NAME

Term::ProgressSpinner - Terminal Progress bars!

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use Term::ProgressSpinner;
	my $ps = Term::ProgressSpinner->new();
	$ps->slowed(0.1);
	$ps->start(50);
	while ($ps->advance()) {}

	...

	my $s1 = $ps->start(20);
	my $s2 = $ps->start(10);
	my $s3 = $ps->start(50);
	my $s4 = $ps->start(30);

	while (!$ps->finished) {
		$ps->advance($s1) unless $s1->finished;
		$ps->advance($s2) unless $s2->finished;
		$ps->advance($s3) unless $s3->finished;
		$ps->advance($s4) unless $s4->finished;
	}

	...

	$s1 = $ps->start(20);
	$s2 = $ps->start(10);
	$s3 = $ps->start(50);
	$s4 = $ps->start(30);

	while ($ps->advance()) {}

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Term::ProgressSpinner Object.

	Term::ProgressSpinner->new(
		text_color => 'white',
		total_color => 'white',
		counter_color => 'white',
		percent_color => 'white',
		percentage_color => 'white',
		percents_color => 'white',
		spinner_color => 'white',
		elapsed_color => 'white',
		start_epoch_color => 'white',
		last_elapsed_color => 'white',
		last_advance_epoch_color => 'white',
		estimate_color => 'white',
		epoch_color => 'white',
		per_second_color => 'white',
		progress_color => 'white',
		spinner => 'bar',
		progress_width => 20,
		progress => 'bar',
		output => \*STDERR,
		progress_spinner_index => 0,
		progress_spinners => [],
		message => "{progress} {spinner} processed {percents} of {counter}/{total} {elapsed}/{estimate}",
		terminal_height => 0,
		terminal_line => 0,
	);

=head3 progress

The name of the progress bar that will be rendered. Currently the following options are valid:

=over

=item arrow

	│→→→→→→→→→→→→→→→→→  │

=item bar

	│█████████████████  │

=item block

	【================   】

=item boxed_arrow

	│⍈⍈⍈⍈⍈⍈⍈⍈⍈⍈⍈⍈⍈⍈⍈⍈⍈   │

=item circle

	│ⓄⓄⓄⓄⓄⓄⓄⓄⓄⓄⓄⓄⓄⓄⓄⓄⓄ   │

=item den_circle

	│⏂⏂⏂⏂⏂⏂⏂⏂⏂⏂⏂⏂⏂⏂⏂⏂⏂   │

=item den_triangle

	│⏅⏅⏅⏅⏅⏅⏅⏅⏅⏅⏅⏅⏅⏅⏅⏅⏅   │

=item dots

	│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   │

=item equal

	[=================   ]

=item hash

	[#################   ]

=item horizontal_lines

	│▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤   │

=item lines

	│≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡   │

=item shekel

	│₪₪₪₪₪₪₪₪₪₪₪₪₪₪₪₪₪   │

=item square

	│■■■■■■■■■■■■■■■■■   │

=item triangle

	│▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎▶︎   │

=back

You can also define your own custom progress bar.

	BEGIN {
		my %PROGRESS = %Term::ProgressSpinners::PROGRESS;
		$PROGRESS{custom} = {
			chars =>  ['[', "~", ']']
		};
	}

	...
	
	$ps->progress('custom');

=head3 progress_width

The width of the progress bar the default value is 20 characters.

	
=head3 spinner

The name of the spinner that will be rendered. Currently the following options are valid:

=over

=item around

	⠈⡙

=item bar

	▁▇▃

=item circle

	○

=item circle_half

	◓

=item clock

	🕘

=item color_circle

	🟢

=item color_cirlces

	🟢⚫️🔴

=item color_square

	🟩

=item color_squares

	🟩🟪🟫

=item dots

	⠙

=item earth

	🌎

=item material

	 ▁▁▁▁██████████████▁▁

=item moon 

	🌖

=item pipe

	┌

=item pong

	▐    ⠠   ▌

=back

You can also define your own custom spinner.

	BEGIN {
		my %SPINNERS = %Term::ProgressSpinners::SPINNERS;
		$SPINNERS{custom} = {
			width => 3,
			index => [1, 2, 3], 
			chars => [
				"▁",
				"▂",
				"▃",
				"▄",
				"▅",
				"▆",
				"▇",
				"█"
			]
		};
	}

	...
	
	$ps->spinner('custom');
		
=head3 output

The output handle to print the progress spinner to. The default is STDERR.

=head3 message

Configure how the progress spinner is drawn. 

	"{progress} {spinner} processed {percents} of {counter}/{total} {elapsed}/{estimate}",

This uses placeholders and currently the following options are available:

=over

=item progress

Draw the progress bar.

=item spinner

Draw The spinner.

=item counter

The current step count.

=item total

The total number of steps.

=item percent

The integer percent of the total that has completed.

=item percents

The formatted percent of the total that has completed.

=item percentage

The integer percentage between percent and the total.

=item percentages

The formatted percentage between percent and the total.

=item start_epoch

The epoch time when the progress spinner was started in milliseconds.

=item start_epoch_second

The epoch time when the progress spinner was started in seconds.

=item epoch

The current epoch time in milliseconds.

=item epoch_second

The current epoch time in seconds.

=item last_advance_epoch

The last advanced epoch set when advance was previously called in milliseconds.

=item last_advance_epoch

The last advanced epoch set when advance was previously called in seconds.

=item elapsed

The time that has elapsed since the start_epoch in milliseconds.

=item elapsed_second

The time that has elapsed since the start_epoch in seconds.

=item last_elapsed

The time that has elapsed since the last_advance_epoch in milliseconds.

=item last_elapsed_second

The time that has elapsed since the last_advance_epoch in seconds.

=item estimate

An estimate for when the progress bar will be complete in milliseconds.

=item estimate_second

An estimate for when the progress bar will be complete in seconds.

=item per_second

The number of advances per second.

=back

=head3 terminal_height

Specify The height of the current terminal, if not set then Term::Size::Any is used.

=head3 terminal_line

Specify the line number to render the progress spinner, if not set then the code attempts to detect the current terminal line number.

=head3 text_color

Specify the colour of the message text. See the COLORS section for valid options.

=head3 spinner_color

Specify the colour of the message spinner. See the COLORS section for valid options.

=head3 progress_color

Specify the colour of the message progress bar. See the COLORS section for valid options.

=head3 total_color

Specify the colour of the message total text. See the COLORS section for valid options.

=head3 counter_color

Specify the colour of the message counter text. See the COLORS section for valid options.

=head3 percent_color

Specify the colour of the message percent text. See the COLORS section for valid options.

=head3 percentage_color

Specify the colour of the message percentage text. See the COLORS section for valid options.

=head3 percentages_color

Specify the colour of the message percentages text. See the COLORS section for valid options.

=head3 percents_color

Specify the colour of the message percents text. See the COLORS section for valid options.

=head3 elapsed_color

Specify the colour of the message elapsed text. See the COLORS section for valid options.

=head3 start_epoch_color

Specify the colour of the message start epoch text. See the COLORS section for valid options.

=head3 last_elapsed_color

Specify the colour of the message last elapsed text. See the COLORS section for valid options.

=head3 last_advance_epoch_color

Specify the colour of the message last advance epoch text. See the COLORS section for valid options.

=head3 estimate_color

Specify the colour of the message estimate text. See the COLORS section for valid options.

=head3 epoch_color

Specify the colour of the message epoch text. See the COLORS section for valid options.

=head3 per_second_color

Specify the colour of the message per second text. See the COLORS section for valid options.

=head2 start

Initiate a new progress spinner.

	$ps->start(1000);

=head2 advance

Advance a step.

	$ps->advance.

=head2 draw

Draw the progress spinner.

	$ps->draw

=head2 finish

End the progress spinner.

	$ps->finish

=head2 drawn

Get or Set whether the progress spinner has been drawn already.

	$ps->drawn

=head2 progress_spinner_index

Get or Set the progress spinner index, this is usefull when rendering multiple progress spinners in parallel.

	$ps->progress_spinner_index($index);

=head2 progress_spinners

Get or Set the progress spinners ArrayRef. this is usefull when rendering multiple progress spinners in parallel.

	$ps->progess_spinners([Term::ProgressSpinner->new()->start(100)]);

=head2 savepos

Save the current terminal position for the progress spinner to be drawn.

	$ps->savepos;

=head2 loadpos

Load the progress spinner saved terminal position.

	$ps->loadpos;

=head2 clear

Remove the progress spinner.

	$ps->clear

=head2 terminal_height

Get or Set the current user defined terminal_height.

	$ps->terminal_height($height);

=head2 terminal_line

Get or Set the current user defined terminal_line.

	$ps->terminal_height($line);

=head2 message

Get or Set the progress spinner message string.

	$ps->message("{progress} {spinner} processed {percents} of {counter}/{total}");

=head2 output

Get or Set the output.

	$ps->output(*\STDERR);

=head2 total

Get or Set the total number of steps.

	$ps->total(1000);

=head2 slowed

Get or Set whether to intentionally slow down the progress bar.

	$ps->slowed(0.01);

=head2 counter

Get or Set the current counter step

	$ps->counter

=head2 start_epoch

Get or Set the start epoch.

=head2 last_advance_epoch

Get or Set the last advance epoch

=head2 text_color 

Get or Set the text color.

	$ps->text_color($color)

=head2 spinner

Get or set the spinner.

	$ps->spinner($spinner)

=head2 spinner_color

Get or Set the spinner color.

	$ps->spinner_color($color)

=head2 progress

Get or set the progress.

	$ps->progress($progress);

=head2 progress_color

Get or Set the progress color.

	$ps->progress_color($color)

=head2 progress_width

Get or Set the progress width.

	$ps->progress_width($width)

=head2 percent_color

Get or Set the percent color.

	$ps->percent_color($color)

=head2 percents_color

Get or Set the percents color.

	$ps->percents_color($color)

=head2 percentage_color

Get or Set the percentage color.

	$ps->percentage_color($color)

=head2 percentages_color

Get or Set the percentages color.

	$ps->percentages_color($color)

=head2 total_color

Get or Set the total color.

	$ps->total_color($color)

=head2 counter_color

Get or Set the counter color.

	$ps->counter_color($color)

=head2 elapsed_color

Get or Set the elapsed color.

	$ps->elapsed_color($color)

=head2 last_elapsed_color

Get or Set the last elapsed color.

	$ps->last_elapsed_color($color)

=head2 estimate_color

Get or Set the estimate color.

	$ps->estimate_color($color)

=head2 last_advance_epoch_color

Get or Set the last advance epoch color.

	$ps->last_advance_epoch_color($color)

=head2 start_epoch_color

Get or Set the start epoch color.

	$ps->start_epoch_color($color)

=head2 epoch_color

Get or Set the epoch color.

	$ps->epoch_color($color)

=head2 per_second_color

Get or Set the per second color.

	$ps->per_second_color($color)

=head2 sleep

Sleep the programe for milliseconds.

	$ps->sleep(0.05);

=head1 COLORS

The following are valid colours that can be specified for rendering the progress spinner.

	$ps->spinner_color('black on_bright_black');

=over

=item black

=item black on_blue

=item black on_bright_black

=item black on_bright_blue

=item black on_bright_cyan

=item black on_bright_green

=item black on_bright_magenta

=item black on_bright_red

=item black on_bright_white

=item black on_bright_yellow

=item black on_cyan

=item black on_green

=item black on_magenta

=item black on_red

=item black on_white

=item black on_yellow

=item blue

=item blue on_black

=item blue on_bright_black

=item blue on_bright_blue

=item blue on_bright_cyan

=item blue on_bright_green

=item blue on_bright_magenta

=item blue on_bright_red

=item blue on_bright_white

=item blue on_bright_yellow

=item blue on_cyan

=item blue on_green

=item blue on_magenta

=item blue on_red

=item blue on_white

=item blue on_yellow

=item bright_black

=item bright_black on_black

=item bright_black on_blue

=item bright_black on_bright_blue

=item bright_black on_bright_cyan

=item bright_black on_bright_green

=item bright_black on_bright_magenta

=item bright_black on_bright_red

=item bright_black on_bright_white

=item bright_black on_bright_yellow

=item bright_black on_cyan

=item bright_black on_green

=item bright_black on_magenta

=item bright_black on_red

=item bright_black on_white

=item bright_black on_yellow

=item bright_blue

=item bright_blue on_black

=item bright_blue on_blue

=item bright_blue on_bright_black

=item bright_blue on_bright_cyan

=item bright_blue on_bright_green

=item bright_blue on_bright_magenta

=item bright_blue on_bright_red

=item bright_blue on_bright_white

=item bright_blue on_bright_yellow

=item bright_blue on_cyan

=item bright_blue on_green

=item bright_blue on_magenta

=item bright_blue on_red

=item bright_blue on_white

=item bright_blue on_yellow

=item bright_cyan

=item bright_cyan on_black

=item bright_cyan on_blue

=item bright_cyan on_bright_black

=item bright_cyan on_bright_blue

=item bright_cyan on_bright_green

=item bright_cyan on_bright_magenta

=item bright_cyan on_bright_red

=item bright_cyan on_bright_white

=item bright_cyan on_bright_yellow

=item bright_cyan on_cyan

=item bright_cyan on_green

=item bright_cyan on_magenta

=item bright_cyan on_red

=item bright_cyan on_white

=item bright_cyan on_yellow

=item bright_green

=item bright_green on_black

=item bright_green on_blue

=item bright_green on_bright_black

=item bright_green on_bright_blue

=item bright_green on_bright_cyan

=item bright_green on_bright_magenta

=item bright_green on_bright_red

=item bright_green on_bright_white

=item bright_green on_bright_yellow

=item bright_green on_cyan

=item bright_green on_green

=item bright_green on_magenta

=item bright_green on_red

=item bright_green on_white

=item bright_green on_yellow

=item bright_magenta

=item bright_magenta on_black

=item bright_magenta on_blue

=item bright_magenta on_bright_black

=item bright_magenta on_bright_blue

=item bright_magenta on_bright_cyan

=item bright_magenta on_bright_green

=item bright_magenta on_bright_red

=item bright_magenta on_bright_white

=item bright_magenta on_bright_yellow

=item bright_magenta on_cyan

=item bright_magenta on_green

=item bright_magenta on_magenta

=item bright_magenta on_red

=item bright_magenta on_white

=item bright_magenta on_yellow

=item bright_red

=item bright_red on_black

=item bright_red on_blue

=item bright_red on_bright_black

=item bright_red on_bright_blue

=item bright_red on_bright_cyan

=item bright_red on_bright_green

=item bright_red on_bright_magenta

=item bright_red on_bright_white

=item bright_red on_bright_yellow

=item bright_red on_cyan

=item bright_red on_green

=item bright_red on_magenta

=item bright_red on_red

=item bright_red on_white

=item bright_red on_yellow

=item bright_white

=item bright_white on_black

=item bright_white on_blue

=item bright_white on_bright_black

=item bright_white on_bright_blue

=item bright_white on_bright_cyan

=item bright_white on_bright_green

=item bright_white on_bright_magenta

=item bright_white on_bright_red

=item bright_white on_bright_yellow

=item bright_white on_cyan

=item bright_white on_green

=item bright_white on_magenta

=item bright_white on_red

=item bright_white on_white

=item bright_white on_yellow

=item bright_yellow

=item bright_yellow on_black

=item bright_yellow on_blue

=item bright_yellow on_bright_black

=item bright_yellow on_bright_blue

=item bright_yellow on_bright_cyan

=item bright_yellow on_bright_green

=item bright_yellow on_bright_magenta

=item bright_yellow on_bright_red

=item bright_yellow on_bright_white

=item bright_yellow on_cyan

=item bright_yellow on_green

=item bright_yellow on_magenta

=item bright_yellow on_red

=item bright_yellow on_white

=item bright_yellow on_yellow

=item cyan

=item cyan on_black

=item cyan on_blue

=item cyan on_bright_black

=item cyan on_bright_blue

=item cyan on_bright_cyan

=item cyan on_bright_green

=item cyan on_bright_magenta

=item cyan on_bright_red

=item cyan on_bright_white

=item cyan on_bright_yellow

=item cyan on_green

=item cyan on_magenta

=item cyan on_red

=item cyan on_white

=item cyan on_yellow

=item green

=item green on_black

=item green on_blue

=item green on_bright_black

=item green on_bright_blue

=item green on_bright_cyan

=item green on_bright_green

=item green on_bright_magenta

=item green on_bright_red

=item green on_bright_white

=item green on_bright_yellow

=item green on_cyan

=item green on_magenta

=item green on_red

=item green on_white

=item green on_yellow

=item magenta

=item magenta on_black

=item magenta on_blue

=item magenta on_bright_black

=item magenta on_bright_blue

=item magenta on_bright_cyan

=item magenta on_bright_green

=item magenta on_bright_magenta

=item magenta on_bright_red

=item magenta on_bright_white

=item magenta on_bright_yellow

=item magenta on_cyan

=item magenta on_green

=item magenta on_red

=item magenta on_white

=item magenta on_yellow

=item red

=item red on_black

=item red on_blue

=item red on_bright_black

=item red on_bright_blue

=item red on_bright_cyan

=item red on_bright_green

=item red on_bright_magenta

=item red on_bright_red

=item red on_bright_white

=item red on_bright_yellow

=item red on_cyan

=item red on_green

=item red on_magenta

=item red on_white

=item red on_yellow

=item white

=item white on_black

=item white on_blue

=item white on_bright_black

=item white on_bright_blue

=item white on_bright_cyan

=item white on_bright_green

=item white on_bright_magenta

=item white on_bright_red

=item white on_bright_white

=item white on_bright_yellow

=item white on_cyan

=item white on_green

=item white on_magenta

=item white on_red

=item white on_yellow

=item yellow

=item yellow on_black

=item yellow on_blue

=item yellow on_bright_black

=item yellow on_bright_blue

=item yellow on_bright_cyan

=item yellow on_bright_green

=item yellow on_bright_magenta

=item yellow on_bright_red

=item yellow on_bright_white

=item yellow on_bright_yellow

=item yellow on_cyan

=item yellow on_green

=item yellow on_magenta

=item yellow on_red

=item yellow on_white

=back

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-term-progressspinner at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-ProgressSpinner>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::ProgressSpinner


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-ProgressSpinner>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Term-ProgressSpinner>

=item * Search CPAN

L<https://metacpan.org/release/Term-ProgressSpinner>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Term::ProgressSpinner
