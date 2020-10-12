package Term::ProgressSpinner; 
our $VERSION = '0.02';
use 5.006; use strict; use warnings;
use IO::Handle; use Term::ANSIColor; use Time::HiRes qw//;
our (%SPINNERS, %PROGRESS, %VALIDATE);

BEGIN {
	%VALIDATE = (
		colours => { map { $_ => 1 } qw/black red green yellow blue magenta cyan white/ },
		msg_regex => qr/\{(total|progress|spinner|percents|percentage|percent|counter|elapsed|elapsed_second|estimate|estimate_second|start_epoch|start_epoch_second|epoch|epoch_second|per_second|last_advance_epoch|last_advance_epoch_second|last_elapsed|last_elapsed_second|elapsed|elapsed_second)\}/
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
	my ($pkg, %args) = @_;
	$args{$_} and ($VALIDATE{colours}{$args{$_}} or die "Invalid color for $_")
		for qw/text_color total_color counter_color percent_color percentage_color percents_color spinner_color progress_color elapsed_color last_elapsed_color estimate_color last_advance_epoch_color start_epoch_color epoch_color/;

	return bless {
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
		spinner_options => $SPINNERS{ $args{spinner} || 'default' },
		progress_color => 'white',
		progress_width => 20,
		progress_options => $PROGRESS{ $args{progress} || 'default' },
		output => \*STDERR,
		spinner_index => 0,
		message => "{progress} {spinner} processed {percents} of {counter}/{total} {elapsed}/{estimate}",
		%args
	}, $pkg;
}

#TODO refactor everything to make context aware
sub savepos {
	my $self = shift;
	my $x='';
	system "stty cbreak </dev/tty >/dev/tty 2>&1";
	$self->output->print("\e[6n");
	$x .= getc STDIN for 0 .. 5;
	system "stty -cbreak </dev/tty >/dev/tty 2>&1";
	my($n, $m)=$x=~m/(\d+)\;(\d+)/;
	$self->clear();
	$self->{savepos} = $n;
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
	$self->advance();
}
 
sub advance {
	my ($self) = @_;
	if ($self->counter < $self->total) {
		$self->counter($self->counter + 1);
		my $spinner = $self->spinner;
		for (1 .. $spinner->{width}) {
			my $index = $spinner->{index}->[$_ - 1];
			$spinner->{index}->[$_ - 1] = ($index + 1) % scalar @{$spinner->{chars}};
		}
		select(undef, undef, undef, $self->slowed) if $self->slowed;
		$self->draw();
	} else {
		$self->finish();
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
	my ($self) = @_;
	$self->loadpos;
	$self->clear();
	my ($spinner, $progress, $available, %options) = ($self->spinner, $self->progress, $self->progress_width, $self->time_advance_elapsed);
	$options{total} = $self->total;	
	$options{counter} = $self->counter;
	$options{spinner} = color($self->spinner_color);
	$options{spinner} .= $spinner->{chars}->[
		$spinner->{index}->[$_ - 1]
	] for (1 .. $spinner->{width});
	$options{spinner} .= color($self->text_color);
	$options{percent} = int( ( $options{counter} / $options{total} ) * 100 );
	$options{percentage} = ($available / 100) * $options{percent};
	$options{estimate} = (($options{elapsed} / $options{percent}) * 100) - $options{elapsed}; 
	$options{estimate_second} = int($options{estimate} + 0.5);
	$options{per_second} = $options{elapsed_seconds} ? 
		$options{counter} / int($options{elapsed_second})
		: 0;
	$options{progress} = sprintf("%s%s%s%s%s",
		color($self->progress_color),
		$progress->{chars}->[0],
		( $progress->{chars}->[1] x int($options{percentage} + 0.5) ) . ( ' ' x int( ($available - $options{percentage}) + 0.5 ) ),
		$progress->{chars}->[2],
		color($self->text_color)
	);
	$options{percents} = $options{percent} . '%'; 
	$options{$_} = sprintf ("%s %s %s",
		color($self->{$_ . "_color"}),
		$options{$_},
		color($self->text_color)
	) for (qw/total percent percents percentage counter per_second/);
	for (qw/elapsed last_elapsed estimate last_advance_epoch start_epoch epoch/) {
		$options{$_} = sprintf ("%s %s %s",
			color($self->{$_ . "_color"}),
			$options{$_},
			color($self->text_color)
		);
		$options{"${_}_second"} = sprintf ("%s%s%s",
			color($self->{$_ . "_color"}),
			$options{"${_}_second"},
			color($self->text_color)
		);
	}
	my $message = $self->message;
	$message =~ s/$VALIDATE{msg_regex}/$options{$1}/ig;
	$message .= color('reset') . "\n";
	$self->output->print($message);
	return $self->drawn(1);
}
 
sub finish {
	my ($self) = @_;
	$self->finished(1);
	$self->output->print("\e[?25h"); 
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
 
=head1 NAME

Term::ProgressSpinner - Terminal Progress bars!

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use Term::ProgressSpinner;
	my $ps = Term::ProgressSpinner->new();
	$ps->slowed(0.1);
	$ps->start(50);
	while ($ps->advance()) {}

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Term::ProgressSpinner Object.

	Term::ProgressSpinner->new(
		text_color => 'red',
                total_color => 'white',
                counter_color => 'white',
                percent_color => 'white',
                percentage_color => 'white',
                percents_color => 'white',
                spinner_color => 'blue',
		spinner => 'moon',
                progress_color => 'yellow',
                progress_width => 20,
                progress => 'equals',
                output => \*STDERR,
                spinner_index => 0,
                message => "{progress} {spinner} processed {percents} of {counter}/{total} {elapsed}/{estimate}"
	);

=cut

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

=head2 clear

Remove the progress spinner.

	$ps->clear

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

=head2 total_color

Get or Set the total color.

	$ps->total_color($color)

=head2 counter_color

Get or Set the counter color.

	$ps->counter_color($color)

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
