package Term::ReadLine::Zoid;

use strict;
use vars '$AUTOLOAD';
use Term::ReadLine::Zoid::Base;
#use encoding 'utf8';
no warnings; # undef == '' down here

our @ISA = qw/Term::ReadLine::Zoid::Base Term::ReadLine::Stub/; # explicitly not use'ing T:RL::Stub
our $VERSION = '0.07';

sub import { # terrible hack - Term::ReadLine in perl 5.6.x is defective
	return unless (caller())[0] eq 'Term::ReadLine' and $] < 5.008 ;
	*Term::ReadLine::Stub::new = sub {
		shift;
		my $self = bless {}, 'Term::ReadLine::Zoid';
		return $self->_init(@_);
	};
}

sub new {
	my $self = bless {}, shift(@_);
	return $self->_init(@_);
}

our $_current;
our %_config  = (
	minline		=> 0,
	autohistory	=> 1,
	autoenv		=> 1,
	autolist	=> 1,
	automultiline	=> 1,
	PS2		=> '> ',
	comment_begin	=> '#',
	maxcomplete	=> 'pager',
	default_mode	=> 'insert',
);
our %_keymaps = (
	insert => {
		return	=> 'accept_line',
		ctrl_O	=> 'operate_and_get_next',
		ctrl_D	=> 'delete_char_or_eof',
		ctrl_C	=> 'return_empty_string',
		escape	=> 'switch_mode_command',
		ctrl_R	=> 'switch_mode_isearch',
		ctrl__	=> 'switch_mode_fbrowse',
		right	=> 'forward_char',
		ctrl_F	=> 'forward_char',
		left	=> 'backward_char',
		ctrl_B	=> 'backward_char',
		home	=> 'beginning_of_line',
		ctrl_A	=> 'beginning_of_line',
		end	=> 'end_of_line',
		ctrl_E	=> 'end_of_line',
		up	=> 'previous_history',
		page_up	=> 'previous_history',
		ctrl_P	=> 'previous_history',
		down	=> 'next_history',
		page_down => 'next_history',
		ctrl_N	=> 'next_history',
		delete	=> 'delete_char',
		backspace => 'backward_delete_char',
		ctrl_U	=> 'unix_line_discard',
		ctrl_K	=> 'kill_line',
		ctrl_W	=> 'unix_word_rubout',
		tab	=> 'complete',
		ctrl_V	=> 'quoted_insert',
		insert	=> 'overwrite_mode',
		ctrl_L	=> 'clear_screen',
		_default => 'self_insert',
	},
	multiline => {
		return	=> 'insert_line',
		up	=> 'backward_line',
		down	=> 'forward_line',
		page_up => 'page_up',
		page_down => 'page_down',
		_isa	=> 'insert',
	},
	command => { _use => 'Term::ReadLine::Zoid::ViCommand'  },
	emacs   => { _use => 'Term::ReadLine::Zoid::Emacs'      },
	emacs_multiline => { _use => 'Term::ReadLine::Zoid::Emacs' },
	fbrowse => { _use => 'Term::ReadLine::Zoid::FileBrowse' },
	isearch => { _use => 'Term::ReadLine::Zoid::ISearch'    },
);

sub _init {
	my ($self, $name, $in, $out) = @_;

	%$self = (
		appname   => $name,
		IN        => $in  || *STDIN{IO},
		OUT       => $out || *STDOUT{IO},
		history   => [],
		hist_cnt  => 1,
		class     => ref($self), # we might be overloaded
		undostack => [],
	%$self );

	$$self{config}{$_}  ||= $_config{$_}  for keys %_config ;
	$$self{keymaps}{$_} ||= $_keymaps{$_} for keys %_keymaps;
	eval "sub switch_mode_$_;" for keys %{$$self{keymaps}}; # if we declare, we can()

	# rcfiles
	my ($rcfile) = grep {-e $_ && -r _} 
		"$ENV{HOME}/.perl_rl_zoid_rc",
		"$ENV{HOME}/.zoid/perl_rl_zoid_rc",
		"/etc/perl_rl_zoid_rc";
	if ($rcfile) {
		local $_current = $self;
		do $rcfile;
	}

	# PERL_RL
	if (exists $ENV{PERL_RL}) {
		my ($which, @config) = split /\s+/, $ENV{PERL_RL};
		if (UNIVERSAL::isa($self, "Term::ReadLine::$which")) {
			for (@config) {
				/(\w+)=(.*)/ or next;
				$$self{config}{$1} = $2;
			}
		}
	}

	$self->switch_mode();
	return $self;
}

sub AUTOLOAD {
	$AUTOLOAD =~ s/.*:://;
	return if $AUTOLOAD eq 'DESTROY';
	my $self = shift;
	if ($AUTOLOAD =~ /^switch_mode_(.*)/) {
		$self->switch_mode($1, @_);
	}
	elsif ($$self{class} ne __PACKAGE__) {
		my $sub = $$self{class}.'::'.$AUTOLOAD;
		$self->$sub(@_);
	}
	else {
		my (undef, $f, $l) = caller;
		die "$AUTOLOAD: no such method at $f line $l\n"
	}
}

# ############ #
# ReadLine api #
# ############ #

sub ReadLine { return 'Term::ReadLine::Zoid' }

sub readline {
	my ($self, $prompt, $preput) = @_;
	$self->reset();
	$self->switch_mode();
	$$self{prompt} = defined($prompt) ? $prompt : $$self{appname}.' !> ';
	$$self{lines}  = [ split /\n/, $preput ] if defined $preput;
	my $title = $$self{config}{title} || $$self{appname};
	$self->title($title);
	$self->new_line();
	if ($$self{prev_hist_p}) {
		$self->set_history( delete $$self{prev_hist_p} );
	}
	$self->loop();
	return $self->_return();
}

sub _return { # also used by continue
	my $self = shift;
	bless $self, $$self{class}; # rebless default class
	print { $$self{OUT} } "\n";
	return undef unless defined $$self{_loop}; # exit application
	return '' unless length $$self{_loop}; # return empty string
	my $string = join("\n", @{$$self{lines}}) || '';
	$self->AddHistory($string) if $$self{config}{autohistory};
	return '' if $$self{config}{comment_begin}
		and ! grep {$_ !~ /^\s*\Q$$self{config}{comment_begin}\E/} @{$$self{lines}};
	$string =~ s/\\\n//ge if $$self{config}{automultiline};
	#print STDERR "string: $string\n";
	return $string;
}

sub addhistory {
	my ($self, $line) = @_;
	return unless defined $$self{config}{minline};
	return unless length $line and length($line) > $$self{config}{minline};
	unshift @{$$self{history}}, $line;
	$$self{hist_cnt}++;
}
*AddHistory = \&addhistory; # T:RL:Gnu compat

sub IN { $_[0]{IN} }

sub OUT { $_[0]{OUT} }

sub MinLine {
	my ($self, $minl) = @_;
	my $old_minl = $$self{config}{minline};
	$$self{config}{minline} = $minl;
	return $old_minl;
}

sub Attribs { $_[0]{config} }

sub Features { {
	( map {($_ => 1)} qw/appname minline attribs 
		addhistory addHistory getHistory getHistory TermSize/ ),
	( map {($_ => $_[0]{config}{$_})}
		qw/autohistory autoenv automultiline/ ),
} }

# ############ #
# Extended api #
# ############ #

sub GetHistory {
	return wantarray 
		? ( reverse @{$_[0]{history}} )
		: [ reverse @{$_[0]{history}} ] ;
}

sub SetHistory {
	my $self = shift;
	$self->{history} = ref($_[0])
		? [ reverse @{$_[0]} ]
		: [ reverse @_       ] ;
}

# TermSize in Base

sub continue { # user typed \n but app says we ain't done
	my $self = shift;
	shift @{$$self{history}} if $$self{history}[0] eq join "\n", @{$$self{lines}};
	$$self{_buffer}++; # previous _return printed a \n
	$self->switch_mode( $$self{mode} ); # switch into last mode
	$self->insert_line();
	$self->loop();
	return $self->_return();
}

sub current {
	return $_current if $_current;
	my (undef, $f, $l) = caller;
	die "No current Term::ReadLine::Zoid object at $f line $l";
}

sub bindkey {
	my ($self, $key, $sub, $mode) = @_;
	$mode ||= $$self{config}{default_mode};
	$$self{keymaps}{$mode} ||= {};
	$key = 'meta_'.uc($1) if $key =~ /^[mM]-(.)$/;
	$key = 'ctrl_'.uc($1) if $key =~ /^(?:\^|[cC]-)(.)$/;
	$sub =~ tr/-/_/ unless ref $sub;
	$$self{keymaps}{$mode}{$key} = $sub;
}

# ######### #
# Render Fu #
# ######### #

sub draw {
	my $self  = shift;
	my @pos   = @{$$self{pos}};   # force copy
	my @lines = @{$$self{lines}}; # idem
#	use Data::Dumper; print STDERR Dumper \@lines, \@pos;

	$pos[0] = length $lines[ $pos[1] ]
		if $pos[0] > length $lines[ $pos[1] ];

	# replace the non printables
	for (0 .. $#lines) {
		if ($_ == $pos[1]) {
			my $start = substr $lines[$_], 0, $pos[0], '';
			my $n = ( $start =~ s{([^[:print:]])}{
				my $ord = ord $1;
				($ord < 32) ? '^'.(chr $ord + 64) : '^?'
			}ge );
			$pos[0] += $n;
			$lines[$_] = $start . $lines[$_];
		}
		$lines[$_] =~ s{([^[:print:]\e])}{
			my $ord = ord $1;
			($ord < 32) ? '^'.(chr $ord + 64) : '^?'
		}ge;
	}

	# format PS1
	my $prompt = ref($$self{prompt}) ? ${$$self{prompt}} : $$self{prompt};
	$prompt =~ s/(!!)|!/$1?'!':$$self{hist_cnt}/eg;

	# format PS2 ... thank carl0s if you like to set nu
	my $len = length scalar @lines;
	my $nu_form = (defined $ENV{CLICOLOR} and ! $ENV{CLICOLOR})
		? "  %${len}u " : "  \e[33m%${len}u\e[0m " ;
	if (@lines > 1) {
		my $ps2 = ref($$self{config}{PS2}) ? ${$$self{config}{PS2}} : $$self{config}{PS2};
		if ($$self{config}{nu}) { # line numbering
			$lines[$_] = sprintf($nu_form, $_ + 1) . $ps2 . $lines[$_]
				for 1 .. $#lines;
			$pos[0] += $self->print_length($ps2) + $len + 3 if $pos[1];
		}
		else {
			$lines[$_] = $ps2 . $lines[$_] for 1 .. $#lines;
			$pos[0] += $self->print_length($ps2) if $pos[1];
		}
	}

	# include PS1
	my @prompt = split /\n/, $prompt, -1;
	if (@prompt) {
		$prompt[-1] = sprintf($nu_form, 1) . $prompt[-1] if $$self{config}{nu};
		$pos[0] += $self->print_length($prompt[-1]) unless $pos[1];
		$pos[1] += $#prompt;
		$lines[0] = pop(@prompt) . $lines[0];
		unshift @lines, @prompt if @prompt;
	}

	# format RPS1
	if (my $rprompt = $$self{config}{RPS1}) {
		$rprompt = $$rprompt if ref $rprompt;
		my $l = $self->print_length($lines[0]);
		if ($rprompt and $l < $$self{term_size}[0]) {
			$rprompt = substr $rprompt, - $$self{term_size}[0] + $l - 1;
			my $w = $$self{term_size}[0] - $l - $self->print_length($rprompt) - 1;
			$lines[0] .= (' 'x$w) . $rprompt;
		}
	}

	$self->print(\@lines, \@pos);
}

*redraw_current_line = \&draw;

# ############ #
# Internal api #
# ############ #

sub switch_mode { 
	my ($self, $mode, @args) = @_;
	$mode ||= $$self{config}{default_mode};
	unless ($$self{keymaps}{$mode}) {
		warn "$mode: no such keymap\n\n";
		$mode = 'insert'; # hardcoded fallback
	}
	$$self{mode} = $mode;
	if (my $class = delete $$self{keymaps}{$mode}{_use}) { # bootstrap
		eval "use $class";
		if ($@) {
			$$self{keymaps}{$mode}{_use} = $class; # put it back
			die $@;
		}
		bless $self, $class;
		$$self{keymaps}{$mode} = {
			%{ $$self{keymaps}{$mode} },
			%{ $self->keymap($mode)   }
		} if UNIVERSAL::can($class, 'keymap');
		$$self{keymaps}{$mode}{_class} ||= $class;
	}
	else {
		my $class = $$self{keymaps}{$mode}{_class} || $$self{class};
		#print STDERR "class: $class\n";
		bless $self, $class;
	}

	if (exists $$self{keymaps}{$mode}{_on_switch}) {
		my $sub = $$self{keymaps}{$mode}{_on_switch};
		return ref($sub) ? $sub->($self, @args) : $self->$sub(@args) ;
	}
}

sub reset { # should this go in Base ?
	my $self = shift;
	$$self{lines} = [''];
	$$self{pos}  = [0, 0];
	$$self{_buffer} = 0;
	$$self{replace} = 0;
	$$self{hist_p} = undef;
	$$self{undostack} = [];
	$$self{scroll_pos} = 0;
}

sub save {
	my $self = shift;
	my %save = (
		pos    => [ @{$$self{pos}}   ],
		lines  => [ @{$$self{lines}} ],
		prompt => $$self{prompt},
	);
	return \%save;
}

sub restore {
	my ($self, $save) = @_;
	$$self{pos}    = [ @{$$save{pos}} ];
	$$self{lines}  = [ @{$$save{lines}} ];
	$$self{prompt} = $$save{prompt};
}

sub substring { # buffer is undef is copy, end is undef is insert
	my ($self, $buffer, $start, $end) = @_;

	($start, $end) = sort {$$a[1] <=> $$b[1] or $$a[0] <=> $$b[0]} ($start, $end) if $end;
	my ($pre, $post) = _split($start || $$self{pos}, [ @{$$self{lines}} ]); # force copy of lines
	my $re = [''];
	if ($end) {
		$$end[0] = $$end[0] - $$start[0] if $$end[1] == $$start[1];
		$$end[1] = $$end[1] - $$start[1];
		($re, $post) = _split($end, $post);
	}
	return join "\n", @$re unless defined $buffer;

	$buffer = [split /\n/, $buffer, -1] if ! ref $buffer;
	$buffer = [''] unless @$buffer;
	$$pre[-1] .= shift @$buffer;
	push @$pre, @$buffer;
	$$self{pos} = [ length($$pre[-1]), $#$pre ];
	$$pre[-1] .= shift @$post;
	$$self{lines} = [ @$pre, @$post ];

	return join "\n", @$re;
}

sub _split {
	my ($pos, $buf, $nbuf) = (@_, []);
	push @$nbuf, splice @$buf, 0, $$pos[1] if $$pos[1];
	push @$nbuf, substr($$buf[0], 0, $$pos[0], '') || '';
	return ($nbuf, $buf);
}

# ############ #
# Key routines #
# ############ #

sub previous_history {
	my $self = shift;
	if (not defined $$self{hist_p}) {
		return $self->bell unless scalar @{$$self{history}};
		$$self{_hist_save} = $self->save();
		$self->set_history(0);
	}
	elsif ($$self{hist_p} < $#{$$self{history}}) {
		$self->set_history( ++$$self{hist_p} );
	}
	else { return $self->bell }
	return 1;
}

sub next_history {
	my $self = shift;
	return $self->bell unless defined $$self{hist_p};
	if ($$self{hist_p} == 0) {
		$$self{hist_p} = undef;
		$self->restore($$self{_hist_save});
	}
	else { $self->set_history( --$$self{hist_p} ) }
	return 1;
}

sub set_history {
	my $self = shift;
	my $hist_p = shift;
	return $self->bell if $hist_p < 0 or $$self{hist_p} > $#{$$self{history}};
	$$self{hist_p} = $hist_p;
	$$self{lines} = [ split /\n/, $$self{history}[$hist_p] ];
	$$self{pos} = [ length($$self{lines}[-1]), $#{$$self{lines}} ];
	# posix says {pos} should be [0, 0], i disagree
}

sub self_insert {
	my ($self, $chr) = (@_);

	# force pos on end of line
	$$self{pos}[0] = length $$self{lines}[ $$self{pos}[1] ]
		if $$self{pos}[0] > length $$self{lines}[ $$self{pos}[1] ];

	substr $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0], $$self{replace}, $chr;
	$$self{pos}[0] += length $chr;
}

sub accept_line {
	my $self = shift;
	if ( 
		$$self{config}{automultiline} and scalar @{$$self{lines}}
		and ! grep /\\\\$|(?<!\\)$/, @{$$self{lines}}
	) {  #print STDERR "funky auto multiline :)\n";
		push @{$$self{lines}}, '';
		$$self{pos} = [0, $#{$$self{lines}}];
	}
	else { $$self{_loop} = 0 }
}

*return = \&accept_line;

sub operate_and_get_next {
	my $self = shift;
	$$self{prev_hist_p} = $$self{hist_p};
	$$self{_loop} = 0;
}

sub return_eof_maybe {
	length( join "\n", @{$_[0]{lines}} )
		? ( $_[0]->bell )
		: ( $_[0]{_loop} = undef ) ;
}

sub return_eof { $_[0]{_loop} = undef }

sub return_empty_string { $_[0]{_loop} = '' }

sub delete_char {
	my $self = shift;

	if ($$self{pos}[0] >= length $$self{lines}[ $$self{pos}[1] ]) {
		$$self{pos}[0] = length $$self{lines}[ $$self{pos}[1] ]; # force pos on end of line
		return $self->bell unless $$self{pos}[1] < @{$$self{lines}};
		$$self{lines}[ $$self{pos}[1] ] .= $$self{lines}[ $$self{pos}[1] + 1 ]; # append next line
		splice @{$$self{lines}}, $$self{pos}[1] + 1, 1; # kill next line
	}
	else { substr $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0], 1, '' }
	return 1;
}

sub delete_char_or_eof {
	my $self = shift;
	if (
		$$self{pos}[1] == $#{$$self{lines}}
		and ! length $$self{lines}[-1]
	) { $$self{_loop} = $$self{pos}[1] ? 0 : undef }
	else { $self->delete_char() }
}

sub backward_delete_char {
	$_[0]->backward_char();
	$_[0]->delete_char() unless $_[0]{replace};
}

sub unix_line_discard {
	$_[0]{killbuf} = join "\n", @{$_[0]{lines}};
	@{$_[0]}{'lines', 'pos'} = ([''], [0, 0])
}

sub possible_completions {
	my $self = shift;
	$self->complete(undef, 'PREVIEW');
}

sub complete {
	my ($self, undef, $preview) = @_;

	# check !autolist stuff
	if ($$self{completions} && @{$$self{completions}}) {
		$self->output( @{$$self{completions}} );
		delete $$self{completions};
		return;
	}

	# get the right function
	my $func = exists($$self{config}{completion_function}) 
		? $$self{config}{completion_function}
		: $readline::rl_completion_function ;
	return unless $func;
	unless (ref $func) {
		no strict;
		$func = *{$func}{CODE};
		return unless ref $func; # how does this work ?
	}

	# generate the arguments
	my $buffer = join "\n", @{$$self{lines}};
	my $end = $self->pos2off($$self{pos});
	my $word = substr $buffer, 0, $end;
	$word =~ s/^.*\s//s; # only leave /\S*$/
	my $lw = length $word;

	# get the completions and output
	my @compl = $func->($word, $buffer, $end - $lw); # word, line, start
	my $meta = ref($compl[0]) ? shift(@compl) : {} ; # hash constitutes an undocumented feature
	$self->output( $$meta{message} ) if $$meta{message};

	return $self->bell unless @compl;
	if ($compl[0] eq $compl[-1]) { @compl = ($compl[0]) } # 1 item or list with only duplicates
	else { @compl = $self->longest_match(@compl) } # returns $compl, @compl

	# format completion
	my $compl = shift @compl;
	$compl = $$meta{prefix} . $compl;
	$compl .= $$meta{postfix} unless @compl;
	unless ($$meta{quoted}) {
		if ($$meta{quote}) {
			if (ref $$meta{quote}) { $compl = $$meta{quote}->($compl) } # should be code ref
			else { # plain quote
				$compl =~ s#\\\\|(?<=[^\\])($$meta{quote})#$1?"\\$1":'\\\\'#ge if $$meta{quote};
				$compl .= $$meta{quote} if !@compl and $compl =~ /\w$/; # arbitrary cruft
			}
		}
		else { $compl =~ s#\\\\|(?<!\\)(\s)#$1?"\\$1":'\\\\'#eg } # escape whitespaces
		$compl .= ' ' if !@compl and $compl =~ /\w$/; # arbitrary cruft
	}

	# display completions
	if (@compl) {
		if ($$self{config}{autolist} || $preview) {
			$self->output( @compl );
			return if $preview;
		}
		else { $$self{completions} = \@compl }
	}

	# update buffer
	push @{$$self{undostack}}, $self->save() if length $compl;
#	print STDERR ">>$buffer<< end $end off: ".($end - $lw)." l: $lw c: $compl\n";
	my $start = $$meta{start} || $end - $lw;
	substr $buffer,  $start, $end - $start, $compl;
	$$self{lines} = [ split /\n/, $buffer ];
	$$self{pos}[0] -= $lw - length($compl); # for the moment completions can't contains \n
}

sub longest_match { # cut doubles and find longest match
	my ($self, @compl) = @_;

	@compl = sort @compl;
	my $match = $compl[0];
	while (length $match and $compl[-1] !~ /^\Q$match\E/) { chop $match } # due to sort only one diff

	my $prev = '';
	return ($match, grep {
		if ($_ eq $prev) { 0 }
		else { $prev = $_; 1 }
	} @compl);
}

sub overwrite_mode {
	my $b = $_[0]{replace};
	$_[0]->switch_mode(); # for command mode
	$_[0]{replace} = $b ? 0 : 1;
}

sub forward_char { # including cnt for vi mode
	my ($self, undef, $cnt) = @_;
	for (1 .. $cnt||1) {
		if ($$self{pos}[0] >= length $$self{lines}[ $$self{pos}[1] ]) {
			return $self->bell unless $$self{pos}[1] < $#{$$self{lines}};
			$$self{pos} = [0, ++$$self{pos}[1]];
		}
		else { $$self{pos}[0]++ }
	}
	return 1;
}

sub backward_char { # including cnt for vi mode
	my ($self, undef, $cnt) = @_;
#	print STDERR "going $cnt left, pos $$self{pos}[0]\n";
	for (1 .. $cnt||1) {
		if ($$self{pos}[0] == 0) {
			return $self->bell if $$self{pos}[1] == 0;
			$$self{pos}[1]--;
			$$self{pos}[0] = length $$self{lines}[ $$self{pos}[1] ];
		}
		elsif ($$self{pos}[0] >= length $$self{lines}[ $$self{pos}[1] ]) {
			$$self{pos}[0] = length($$self{lines}[ $$self{pos}[1] ]) - 1;
		}
		else { $$self{pos}[0]-- }
	}
	return 1;
}

sub beginning_of_line { $_[0]{pos}[0] = 0; return 1 }

sub end_of_line { $_[0]{pos}[0] = length $_[0]{lines}[ $_[0]{pos}[1] ]; return 1 }

sub quoted_insert {
	my $self = shift;
	$self->self_insert($self->read_key);
}

sub unix_word_rubout {
	my $self = shift;
	$$self{pos}[0] = length $$self{lines}[ $$self{pos}[1] ]
		if $$self{pos}[0] > length $$self{lines}[ $$self{pos}[1] ];
	my $pre = substr $$self{lines}[ $$self{pos}[1] ], 0, $$self{pos}[0], '';
	$pre =~ s/\S*\s*$//;
	$$self{pos}[0] = length $pre;
	$$self{lines}[ $$self{pos}[1] ] = $pre . $$self{lines}[ $$self{pos}[1] ];
}

sub kill_line {
	my $self = shift;
	$$self{lines}[ $$self{pos}[1] ] = substr $$self{lines}[ $$self{pos}[1] ], 0, $$self{pos}[0];
}

sub insert_line {
	my $self = shift;
	my $l = length $$self{lines}[ $$self{pos}[1] ];
	my $end = substr $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0], $l, '';
	$$self{pos} = [0, $$self{pos}[1] + 1];
	splice @{$$self{lines}}, $$self{pos}[1], 0, $end || '';
}

sub backward_line {
	my $self = shift;
	return 0 unless $$self{pos}[1] > 0;
	$$self{pos}[1]--;
	return 1;
}

sub forward_line {
	my $self = shift;
	return 0 unless $$self{pos}[1] < $#{$$self{lines}};
	$$self{pos}[1]++;
	return 1;
}

sub page_up {
	my $self = shift;
	my (undef, $higth) = $self->TermSize();
	$$self{pos}[1] -= $higth;
	$$self{pos}[1] = 0 if $$self{pos}[1] < 0;
}


sub page_down {
	my $self = shift;
	my (undef, $higth) = $self->TermSize();
	$$self{pos}[1] += $higth;
	$$self{pos}[1] = $#{$$self{lines}} if $$self{pos}[1] > $#{$$self{lines}};
}

1;

__END__

=head1 NAME

Term::ReadLine::Zoid - another ReadLine package

=head1 SYNOPSIS

	# In your app:
	use Term::ReadLine;
	my $term = Term::ReadLine->new("my app");
	
	my $prompt = "eval: ";
	my $OUT = $term->OUT || \*STDOUT;
	while ( defined ($_ = $term->readline($prompt)) ) {
		# Think while (<STDIN>) {}
		my $res = eval($_);
		warn $@ if $@;
		print $OUT $res, "\n" unless $@;
	}
	
	# In some rc file
	export PERL_RL=Zoid

=head1 DESCRIPTION

This package provides a set of modules that form an interactive input buffer
written in plain perl with minimal dependencies. It features almost all
key-bindings described in the posix spec for the sh(1) utility with some extensions like
multiline editing; this includes a vi-command mode with a save-buffer
(for copy-pasting) and an undo-stack.

Historically this code was part of the Zoidberg shell, but this implementation
is complete independent from zoid and uses the  L<Term::ReadLine> interface, so it
can be used with other perl programs.

( The documentation sometimes referes to 'the application', this is the program
using the ReadLine module for input. )

=head1 ENVIRONMENT

The L<Term::ReadLine> interface module uses the C<PERL_RL> variable
to decide which module to load; so if you want to use this module for all
your perl applications, try something like:

	export PERL_RL=Zoid

=head1 KEY MAPPING

The function name is given between parenthesis, these can be used for
privat key maps.

=head2 Default keymap

The default key mapping is as follows:

=over 4

=item escape, ^[  (I<switch_mode_command>)

Place the line editor in command mode, see L<Term::ReadLine::Zoid::ViCommand>.

=item ^C  (I<return_empty_string>)

End editing and return an empty string.

=item ^D  (I<delete_char_or_eof>)

For a single line buffer ends editing and returns C<undef>
if the line is empty, else it deletes a char.
For a multiline buffer, ends editing and returns the lines
to the application if the cursor is on the last line and this line
is empty, else it deletes a char.

Note that the I<delete_char_or_eof> function does what I<delete_char>
should do to be compatible with GNU readline lib.

=item delete  (I<delete_char>)

=item backspace, ^H, ^?  (I<backward_delete_char>)

Delete and backspace kill the current or previous character.
The key '^?' is by default considered a backspace because most modern
keyboards use this key for the "backspace" key and an escape sequence
for the "delete" key.
Of course '^H' is also considered a backspace.

=item tab, ^I  (I<complete>)

Try to complete the bigword on left of the cursor.

There is no default completion included in this package, so unless you define a custom
expansion it doesn't do anything. See the L</completion_function> option.

Uses the PAGER environment variable to find a suitable pager when there are
more completions to be shown then would fit on the screen.

See also the L</autolist> and L</maxcomplete> options.

=item return, ^J  (I<accept_line>)

End editing and return the edit line to the application unless the newline is escaped.

If _all_ lines in the buffer end with a single '\', the newline is considered escaped
you can continue typing on the next line. This behaviour can be a bit unexpected
because this module has multiline support which historic readline implementations
have not, historically the escaping of a newline is done by the application not by the library.
The surpress this behaviour, and let the application do it's thing, disable the "automultiline"
option.

To enter the real multiline editing mode, press 'escape m',
see L<Term::ReadLine::Zoid::MultiLine>.

=item ^O  (I<operate_and_get_next>)

Return the current buffer to the application but remember where we are in history.
This can be used to quickly (re-)execute series of commands from history.

=item ^K  (I<kill_line>)

Delete from cursor to the end of the line.

=item ^L  (I<clear_screen>)

Clear entire screen. In contrast with other readline libraries, the prompt
will remain at the bottom of the screen.

=item ^R  (I<switch_mode_isearch>)

Enter incremental search mode, see L<Term::ReadLine::Zoid::ISearch>.

=item ^U  (I<unix_line_discard>)

This is also known as the "kill" char. It deletes all characters on the edit line
and puts them in the save buffer. You can paste them back in later with 'escape-p'.

=item ^V  (I<quoted_insert>)

Insert next key literally, ignoring any key-bindings.

WARNING: control or escape chars in the editline can cause unexpected results

=item ^W  (I<unix_word_rubout>)

Delete the word before the cursor.

=item insert  (I<overwrite_mode>)

Toggle replace bit.

=item home, ^A  (I<beginning_of_line>)

Move cursor to the begin of the edit line.

=item end, ^E  (I<end_of_line>)

Move cursor to the end of the edit line.

=item left, ^B  (I<backward_char>)

=item right, ^F  (I<forward_char>)

These keys can be used to move the cursor in the edit line.

=item up, page_up, ^P  (I<previous_history>)

=item down, page_down, ^N  (I<next_history>)

These keys are used to rotate the history.

=back

=head2 Multi-line keymap

The following keys are different in mutline mode, the others
fall back to the default behaviour.

=over 4

=item return (I<insert_line>)

Insert a newline at the current cursor position.

=item up (I<backward_line>)

Move the cursor one line up.

=item down (I<forward_line>)

Move the cursor one line down.

=item page_up (I<page_up>)

Move the cursor one screen down, or to the bottom of the buffer.

=item page_down (I<page_down>)

Move the cursor one screen up, or to the top of the buffer.

=back

=head2 Unmapped functions

=over 4

=item I<return_eof>

End editing and return C<undef>.

=item I<return_eof_maybe>

End editing and return C<undef> if the buffer is completely empty.

=item I<possible_completions>

Like I<complete> but only shows the completions without
actually doing them.

=item I<redraw_current_line>

Redraw the current line. This is done all the time automaticly 
so you'll almost never need to call this one explicitly.

=back

=head1 ATTRIBS

The hash with options can be accessed with the L</Attribs> method.
These can be modified from the rc-file (see L</FILES>) or can be set
from the C<PERL_RL> environment variable. For example to disable the
L</autolist> feature you can set C<PERL_RL='Zoid autolist=0'> before
you start the application.

( Also they can be altered interactively using the mini-buffer of 
the command mode, see L<Term::ReadLine::Zoid::ViCommand>. )

=over 4

=item autohistory

If enabled lines are added to the history automaticly,
subject to L</MinLine>. By default enabled.

=item autoenv

If enabled the environment variables C<COLUMNS> and C<LINES>
are kept up to date. By default enabled.

=item autolist

If set completions are listed directly when a completion fails,
if not set you need to press "tab" twice to see a list of possible completions.
By default enabled.

=item automultiline

See L</return> for a description. By default enabled.

=item beat

This option can contain a CODE reference.
It is called on the heartbeat event.

=item bell

This option can contain a CODE reference.
The default is C<print "\cG">, which makes the terminal ring a bell.

=item comment_begin

This option can be set to a string, if the edit line starts with this string the line
is regarded to be a comment and is not returned to the application, but it will appear
in the history if 'autohistory' is also set. Defaults to "#".

When there are multiple lines in the buffer they all need to start with the comment
string for the buffer to be regarded as a comment.

=item completion_function

This option can contain either a code ref or the name of a function to perform
completion. For compatibility with Term::ReadLine::Perl the global scalar
C<$readline::rl_completion_function> will be checked if this option
isn't defined.

The function will get the following arguments: C<$word>, C<$buffer>, C<$start>.
Where C<$word> is the word before the cursor, while C<$buffer> is the complete text
on the command line; C<$start> is the offset of C<$word> in C<$buffer>. 

The function should return a list of possible completions of C<$word>.
The completion list is checked for double entries.

There is B<no> default.

FIXME tell about the meta fields for advanced completion

=item default_mode

Specifies the mode the buffer starts in when you do a C<readline()>, also other
modes return to this mode if you exit them.
The default is 'insert' which is the single-line insert mode.
If you always want to edit in multiline mode set this option to 'multiline'.

=item maxcomplete

Maximum number of completions to be displayed, when the number of completions
is bigger the user is asked before displaying them. If set to zero completions
are always displayed.

If this option is set to the string 'pager' the user is asked when the number of
completions is to big to fit on screen and a pager would be used.

=item minline

This option controls which lines are included in the history, lines
shorter then this number are ignored. When set to "0" all lines are included in the
history, when set to C<undef> all lines are ignored.
Defaults to "0".

=item PS2

This option can contain the prompt to be used for extra buffer lines.
It defaults to C<< "> " >>.

Although the "PS1" prompt (as specified as an argument to the C<readline()> method)
can contain newlines, the PS2 prompt can't.

=item RPS1

This option can contain a string that will be shown on the right side of the screen.
This is known as the "right prompt" and the idea is stolen from zsh(1).

=item title

Used to set the terminal title, defaults to the appname.

=item low_latency

Changes the escape sequences are read from input.
If true delays evalution of the escape key till the next char is known.
By default disabled.

=back

=head1 FILES

This module reads a rc-file on intialisation, either F<$HOME/.perl_rl_zoid_rc>,
F<$HOME/.zoid/perl_rl_zoid_rc> or F</etc/perl_rl_zoid_rc>.
The rc-file is a perl script with access to the Term::ReadLine::Zoid object through
the method C<current()>.
If you want to have different behaviour for different applications,
try to check for C<< $rl->{appname} >>.

	# in for example ~/.perl_rl_zoid_rc
	my $rl = Term::ReadLine::Zoid->current();
	
	# set low latency
	$rl->Attribs()->{low_latency} = 1;
	
	# alias control-space to escape
	$rl->bindchr( chr(0), 'escape' );
	
	# create an ad hoc macro
	$rl->bindkey('^P', sub { $rl->press('mplayer -vo sdl ') } );

=head1 METHODS

=head2 ReadLine api

Functions specified by the L<Term::ReadLine> documentation.

=over 4

=item C<new($appname, $IN, $OUT)>

Simple constructor. Arguments are the application name (used for default prompt
and title string) and optional filehandles for input and output.

=item C<ReadLine()>

Returns the name of the current ReadLine module actually used.

=item C<readline($prompt, $preput)>

Returns a string entered by the user. 
The final newline is stripped, though the string might contain newlines elsewhere.

The prompt only supports the escape "!" for the history number
of the current line, use "!!" for a literal "!".
All other escapes you need to parse yourself, before supplying
the prompt.
The prompt defaults to C<< "$appname !> " >>.

If you want to do more with your prompt see L<Env::PS1>.

C<$preput> can be used to set some text on the edit line allready.

=item C<addhistory($line)>

=item C<AddHistory($line)>

Add a command to the history (subject to the L</minline> option).

If L</autohistory> is set this method will be called automaticly by L</readline>.

=item C<IN()>

Returns the filehandle used for input.

=item C<OUT()>

Returns the filehandle used for output.

=item C<MinLine($value)>

Sets L</minline> option to C<$value> and returns old value.

=item C<findConsole()>

TODO - what uses does this have ?

=item C<Attribs()>

Returns a reference to the options hash.

=item C<Features()>

Returns a reference to a hash with names of implemented features.

Be aware that the naming scheme is quite arbitrary, this module
uses the same names as Term::ReadLine::Gnu for common features.

=back

=head2 Extended api

=over 4

=item C<SetHistory(@hist)>

=item C<GetHistory()>

Simple acces to the history arry, the "set" function supports both a list
and a reference, the "get" function uses "wantarray".
Not sure which behaviour is compatible with T:RL::Gnu.

=item C<TermSize()>

Returns number of columns and lines on the terminal.

=item C<continue()>

This method can be called to continue the previous C<readline()> call.
Can be used to build a custom auto-mulitline feature.

=item C<current()>

Returns the current T:RL::Zoid object, for use in rc files, see L</FILES>.

=item C<bindkey($key, $sub, $map)>

Bind a CODE reference to a key, the function gets called when the key is typed with
the key name as an argument. The C<$map> argument is optional and can be either
"default", "command", "isearch" or "multiline".

If C<$sub> is not a reference it is considered an alias;
these aliases are not recursive.

For alphanumeric characters the name is the character itself, special characters have
long speaking names and control characters are prefixed with a '^'.

Binding combination with the meta- or alt-key is not supported (see L</NOTES>).

=back

=head2 Private api

Methods for use in overload classes.

I<Avoid using these methods from the application.>

=over 4

=item C<switch_mode($mode)>

Switch to input mode C<$mode>; changes the key map and
reblesses the object if the C<_on_switch> key returns a class name.

=item C<reset()>

Reset all temporary attributes.

=item C<save()>

Returns a ref with a copy of some temporary attributes.
Can be used to switch between multiple edit lines in combination with L</restore>.

=item C<restore($save)>

Restores saved attributes.

=item C<set_history($int)>

Sets history entry C<$int> in the buffer.

=item C<longest_match(@completion)>

Returns the longest match among the completions followed by the completions
itself. Used for completion functions.

=back

=head1 DEVELOPMENT

FIXME minimum subroutines new mode-class

FIXME how to set up a keymap

FIXME how to add a keymap/mode

=head1 NOTES

With most modern keymappings the combination of the meta key (alt) with a letter
is identical with an escape character followed by that letter.

Some functioality may in time be moved to the ::Base package.

=head1 TODO

UTF8 support, or general charset support, would be nice but at the moment
I lack the means to test these things. If anyone has ideas or suggestions about this
please contact me.

=head1 BUGS

Line wrap doesn't always displays the last character on the line right, no functional bug though.

If the buffer size exceeds the screen size some bugs appear in the rendering.

Please mail the author if you find any other bugs.

=head1 AUTHOR

Jaap Karssenberg || Pardus [Larus] E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2004 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Term::ReadLine::Zoid::ViCommand>,
L<Term::ReadLine::Zoid::MultiLine>,
L<Term::ReadLine::Zoid::ISearch>,
L<Term::ReadLine::Zoid::FileBrowse>,
L<Term::ReadLine::Zoid::Base>,
L<Term::ReadLine>,
L<Env::PS1>,
L<Zoidberg>

=cut

