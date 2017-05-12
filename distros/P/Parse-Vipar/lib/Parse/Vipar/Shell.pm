# -*- cperl -*-

package Parse::Vipar::Shell;

use Tk::FBox;
use Parse::Vipar::Console;
use Parse::YALALR::Run;
use Parse::Vipar::Common;
use Parse::YALALR::Common;
use Parse::Vipar::ViparText qw(makestart makeend find_parent foreach_tag);

BEGIN { *{__PACKAGE__."::new"} = \&Parse::Vipar::subnew; }

use strict;

sub layout {
    my $self = shift;
    my ($info, $win) = @_;

    $self->{win} = $win;
    $self->{info} = $info;

    ########## STATUS ###########
    $info->{status_l} = $info->{shell_f}->Label(-text => "Enter command and press <Enter>")
        ->pack(-fill => 'x', -side => 'bottom');

    ######## CONSOLE ##########
    $info->{f1} = $info->{shell_f}->Frame()->pack(-side => 'bottom',
						  -fill => 'both',
						  -expand => 1);
    $info->{shell_t} =
        $info->{f1}->Scrolled('Console',
			      -scrollbars => 'e',
			      -width => PANEWIDTH * 2.5,
			      -command => sub { $self->execute(shift()) })
	  ->pack(-side => 'left', -fill => 'both', -expand => 1);

    my $t = $self->{_t} = $info->{shell_t};

    my $vipar = $self->{parent};
    $t->tagInvisibleLink('sym', sub {
			     foreach ($t->curTagNames()) {
				 next unless /sym_(\d+)/;
				 $vipar->select_symbols($1);
			     }
			 });

    $t->tagInvisibleLink('rule', sub {
			     foreach ($t->curTagNames()) {
				 next unless /rule_(\d+)/;
				 $vipar->select_rule($1);
			     }
			 });

    $t->tagInvisibleLink('state', sub {
			     foreach ($t->curTagNames()) {
				 next unless /state_(\d+)/;
				 $vipar->select_state($1);
			     }
			 });

    ######### BUTTON MENU ############
    my $buttons = $info->{actions_f} = $info->{f1}->Frame()
        ->pack(-fill => 'y');

    my %listen;

    my @button_info =
        ( [ 'Step' =>
            'step', have_file => 'normal', no_file => 'disabled' ],
          [ 'Next Action' =>
            'na', have_file => 'normal', no_file => 'disabled' ],
          [ 'Next Reduce' =>
            'nr', have_file => 'normal', no_file => 'disabled' ],
          [ 'Next Input' =>
            'ni', have_file => 'normal', no_file => 'disabled' ],
          [ 'Restart' =>
            'restart' ],
          [ 'Stop' =>
            'stop', have_file => 'normal', no_file => 'disabled' ],
          [ 'End Run' =>
            'end', have_file => 'normal', no_file => 'disabled' ],
        );

    foreach (@button_info) {
        my ($name, $action, %transitions) = @$_;
        my $b = $buttons->Button(-text => $name,
                                 -command => sub { $t->userinput($action) })
            ->pack(-side => 'top', -fill => 'x');
        while (my ($event, $state) = each %transitions) {
            push @{$listen{$event}}, sub { $b->configure(-state => $state) };
        }
    }

    $self->{listen} = \%listen;

    ######### MENU ############
    my $menubar = $info->{menu_m} = $info->{shell_f}->Menu(-type => 'menubar');
    $win->configure(-menu => $menubar);

    # Stolen from example code menus.pl
    my $modifier = 'Meta';	# Unix
    if ($^O eq 'MSWin32') {
	$modifier = 'Control';
    } elsif ($^O eq 'MacOS') {  # one of these days
	$modifier = 'Command';
    }

    my $m_file = $menubar->cascade(-label => '~File', -tearoff => 0);
    $m_file->command(-label => 'Load ~Parser...',
                     -command => sub {
                         $self->fileDialog("load parser %s",
                                           ["YACC files", '*.y'])
                     });
    $m_file->command(-label => 'Load ~Input...',
                     -command => sub { $self->fileDialog("load %s") });
    $m_file->command(-label => 'Exit', -command => \&Tk::exit);

    # Setup lookahead explanations

    $self->setup_why() if $vipar->{builder}->{why};
    $self->setup();
}

sub setup_why {
    my ($self) = @_;
    my $t = $self->{_t};
    my $vipar = $self->{parent};

    $t->map->{pre}->{lookahead} = sub {
	my ($xmltag) = @_;
	if (exists $xmltag->{state}) {
	    my $tag = $t->makeTag('lookahead',
				  state => $xmltag->{state},
				  item => $xmltag->{item},
				  token => $xmltag->{token});
	    $xmltag->{body} = [ makestart('lookahead'),
				@{$xmltag->{body}}, ' ',
				makestart($tag),
				'(why)',
				makeend('lookahead', $tag) ];
	    $t->tagLink($tag);
	} else {
	    $xmltag->{body} = [	makestart('lookahead'),
				@{$xmltag->{body}},
				makeend('lookahead') ];
	}
    };

    $t->tagBind('lookahead', '<1>', sub {
		    my %info = $t->getNumericalAttrs('lookahead');
		    $vipar->why_lookahead(@info{'state','item','token'});
		});

    my $parser = $self->{parent}->{parser};
    $t->map->{pre}->{FIRST} = sub {
	my ($xmltag) = @_;
	my ($token, $symbol) = @$xmltag{'token','symbol'};
	my @tags = ("FIRST",
		    "FIRST_symbol_${symbol}_token${token}");
	$xmltag->{body} = [ @{$xmltag->{body}}, ' ',
			    makestart(@tags),
			    '(why)',
			    makeend(@tags) ];
	$t->tagLink($tags[1], sub { $t->userinput("why is token ".$parser->dump_sym($token)." in FIRST(".$parser->dump_sym($symbol).")"); });
    };

    $t->map->{pre}->{nullable} = sub {
	my ($xmltag) = @_;
	my $symbol = $xmltag->{symbol};
	my @tags = ("nullable",
		    "nullable_$symbol");
	$xmltag->{body} = [ @{$xmltag->{body}}, ' ',
			    makestart(@tags),
			    '(why)',
			    makeend(@tags) ];
	$t->tagLink($tags[1], sub { $t->userinput("why is symbol ".$parser->dump_sym($symbol)." nullable"); });
    };
}

sub announce {
    my ($self, $event) = @_;
    foreach my $cb (@{ $self->{listen}->{$event} }) {
        if (!ref $cb) {
            $self->$cb($event, @_[2..$#_]);
        } elsif (ref $cb eq 'ARRAY') {
            $cb->[0]->(@$cb[1..$#$cb]);
        } else {
            &$cb;
        }
    }
}

sub restart {
    my ($self) = @_;
    $self->report_cmd("RESTART");
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my $ptree = $vipar->{parsetree};

    $ptree->{_t}->delete('all');
    if (!defined $self->{current_file}) {
        $self->log("INTERNAL ERROR: No file currently open!");
        return;
    }
    $self->load_file($self->{current_file});
}

sub stop {
    my ($self) = @_;
    $self->report_cmd("STOP");
    $self->{stopped} = 1;
}

sub end {
    my ($self) = @_;
    $self->report_cmd("END");
    $self->{stopped} = 1;
    $self->announce('no_file');
}

sub log {
    my ($self, $xml, $whycmd) = @_;
    chomp($xml);
    my $t = $self->{_t};
    $t->output($xml);

    if ($whycmd) {
        my $tag = "why-".++$self->{whys};
        $t->output(" ");
        $t->output("(why)", $tag);
        $t->tagLink($tag, sub { $whycmd->($self) });
    }

    $t->output("\n");
}

sub why_read {
    my ($self, $tokenname) = @_;
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    $self->report_cmd("WHY READ $tokenname");
    $self->log("seemed like a good thing to do at the time");
}

sub log_read {
    my ($self, $token) = @_;
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my $tokenname = $parser->dump_sym($token);
    $self->set_lookahead($token);
    $self->log("read input <sym id=$token>token $E{$tokenname}</sym>");
}

sub why_nullable {
    my ($self, $symname) = @_;
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my $builder = $vipar->{builder};
    my $sym = $parser->{symmap}->get_index($symname)
        or do { $self->log("Unknown symbol $E{$symname}"); return; };
    $self->report_cmd("WHY IS $symname NULLABLE");
    my $xmlsym = $parser->dump_sym($sym, 'xml');
    my ($binary, $xml) =
        $builder->explain_nullable($sym, 'xml');
    $self->log("$xmlsym is nullable because\n$xml");
}

sub why_FIRST {
    my ($self, $tokenname, $symname) = @_;
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my $builder = $vipar->{builder};
    my $sym = $parser->{symmap}->get_index($symname)
        or do { $self->log("Unknown symbol $E{$symname}"); return; };
    my $token = $parser->{symmap}->get_index($tokenname)
        or do { $self->log("Unknown symbol $E{$tokenname}"); return; };
    $self->report_cmd("WHY IS $tokenname IN FIRST($symname)");
    my $xmlsym = $parser->dump_sym($sym, 'xml');
    my $xmltok = $parser->dump_sym($token, 'xml');
    my ($binary, $xml) =
        $builder->explain_FIRST($token, $sym, 'xml');
    $self->log("$xmltok is in FIRST($xmlsym) because\n$xml");
}

sub why_shift {
    my ($self, $symname, $state0) = @_;
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my $builder = $vipar->{builder};
    my $sym = $parser->{symmap}->get_index($symname)
        or do { $self->log("Unknown symbol $E{$symname}"); return; };
    $self->report_cmd("WHY SHIFT $symname IN STATE $state0");
    my $kernel0 = $parser->{states}->[$state0];
    my $actions = $kernel0->{actions};
    my $state1 = $actions->[$sym];
    my $xmlsym = $parser->dump_sym($sym, 'xml');
    my ($binary, $xml) =
        $builder->explain_shift($kernel0, $sym, $state1, $actions, 'xml');
    $xml = "shift $xmlsym because ".$parser->dump_kernel($kernel0, 'briefxml').$xml;
    $self->log($xml);
}

sub log_shift {
    my ($self, $sym, $kernel0, $kernel1) = @_;
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my $symname = $parser->dump_sym($sym);
    my ($state0, $state1) = ($kernel0->{id}, $kernel1->{id});
    $self->set_lookahead(undef);
    my $whycmd;
    $whycmd = sub { shift()->{_t}->userinput("ws\@$state0 $symname") }
      if $vipar->{builder}->{why};
    $self->log("<state id=$state0>state $state0</state>: "
	       ."shift <sym id=$sym>token $E{$symname}</sym>, "
	       ."goto <state id=$state1>state $state1</state>",
	       $whycmd);
    $self->set_state($state1);
}

sub why_reduce {
    my ($self, $tokenname, $state0) = @_;
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my $builder = $vipar->{builder};
    my $token = $parser->{symmap}->get_index($tokenname);
    my $kernel0 = $parser->{states}->[$state0];
    my $actions = $kernel0->{actions};
    my $action = $actions->[$token];
    my ($rule, $lhs, $sz_rhs) = @$action;

    print "why_reduce($tokenname, $state0)\n";

    $self->report_cmd("WHY REDUCE ON $tokenname IN STATE $kernel0->{id}");
    my ($binary, $xml) =
      $builder->explain_reduce($kernel0, $token, $action, $actions, 'xml');
    my ($state, $index, $symbol, $ultimate_kitem) = @$binary;
    my $tag = $self->{_t}->makeTag('lookahead',
				   state => $state0,
				   item => $index,
				   token => $symbol);
    $vipar->data->{$tag} = $binary;
    print "UKI=$ultimate_kitem\n";
    my $full = "reduced $E{$parser->dump_rule($rule, '<-', 'brief')} ";
    $full .= "because $E{$parser->dump_kernel($kernel0)}\n";
    $full .= $xml;
    $self->log($full);
}

sub log_reduce {
    my ($self, $token, $kernel0, $state1, $action) = @_;
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my ($rule, $lhs, $sz_rhs) = @$action;
    my $lhsname = $parser->dump_sym($lhs);
    my $tokenname = $parser->dump_sym($token);
    my $state0 = $kernel0->{id};
    my $whycmd;
    $whycmd = sub { shift()->{_t}->userinput("wr\@$state0 on $tokenname") }
      if $vipar->{builder}->{why};
    $self->log("reduce <rule id=$rule>$E{$parser->dump_rule($rule, '<-', 'brief')}</rule>, goto <state id=$state1>state $state1</state>", $whycmd);
    $self->set_state($state1);
}

sub why_lookahead {
    my ($self, $tokenname, $state, $item) = @_;
    my $vipar = $self->{parent};
    my $builder = $vipar->{builder};
    my $parser = $vipar->{parser};
    my $token = $parser->{symmap}->get_index($tokenname);
    my $kernel = $parser->{states}->[$state];

    $self->report_cmd("WHY LOOKAHEAD TOKEN $tokenname IN STATE $state ITEM $item");

    my $tag = "lookahead_state${state}_item${item}_token$token";
    print "LOOKING UP tag $tag\n";
    my $binary = $vipar->data->{$tag};
    my $ultimate_kitem;

    if (defined $binary) {
	print "BINARY=$binary\n";
	$ultimate_kitem = $binary->[3];
	print "READ UKI=$ultimate_kitem\n";
    }

    my (undef, $xml) =
      $builder->explain_lookahead($kernel, $item, $token, $ultimate_kitem, 'xml');
    $self->log($xml);
}

sub execute {
    my ($self, $command) = @_;
    print "Executing $command\n";

    if (lc $command eq 's' || lc $command eq 'step') {
        $self->step();
    } elsif ($command =~ /^eval /i) {
	local $::vipar = $self->{parent};
	my $value = eval substr($command, 5);
	$value = "(undef)" if !defined $value;
	$self->log($value);
    } elsif (lc $command eq 'na' || lc $command eq 'next action') {
        $self->next_action();
    } elsif ($command =~ /^(?:next reduce(?:to\s+)?|nr)\s*(.+)?/i ) {
        my $symbol = $1;
        $self->next_reduce($symbol);
    } elsif ($command =~ /^(?:next input|ni)\s*(.+)?/i ) {
        my $token = $1;
        $self->next_read($token);
    } elsif ($command =~ /^(?:why shift|ws)\s*(.+)?/i ) {
        my $rest = $1;
        if ($rest =~ /\@(\d+) (\S+)/) {
            $self->why_shift($2, $1);
        } elsif ($rest =~ /(\S+) in (state\s+)?(\d+)/) {
            $self->why_shift($1, $3);
        } else {
	    $self->why_shift($rest, $self->{currentState});
        }
    } elsif ($command =~ /^(?:why reduce|wr)\s*(.+)?/i ) {
        my $rest = $1;
        if ($rest =~ /\@(\d+) on (\S+)/) {
	    print "rest=$rest, grabbed \$1=$1 \$2=$2\n";
            $self->why_reduce($2, $1);
        } else {
            my ($state) = $rest =~ /state (\d+)/i;
            my ($lookahead) = $rest =~ /on (\S+)/i;
	    $state = $self->{currentState} if !defined $state;
            if (!defined $state || !defined $lookahead) {
                $self->log("Error: bad params to WHY REDUCE command");
            } else {
                $self->why_reduce($lookahead, $state);
            }
        }
    } elsif ($command =~ /^(?:why input|wi)\s*(\S+)/i ) {
        $self->why_read($1);
    } elsif ($command =~ /^(?:open)\s+\"(.*)\"/i ) {
        $self->load_file($1);
    } elsif ($command =~ /^restart/i ) {
        $self->restart();
    } elsif ($command =~ /^stop/i ) {
        $self->stop();
    } elsif ($command =~ /^stop/i ) {
        $self->end();
    } elsif ($command =~ /^load parser (\"?)(.*)\1$/i ) {
        $self->load_parser($2);
    } elsif ($command =~ /^load (\"?)(.*)\1$/i ) {
        $self->load_file($2);
    } elsif ($command =~ /^why lookahead (.*)/) {
	my $rest = $1;
	my ($state, $token, $item);
	($state) = $rest =~ /state\s+(\d+)/;
	$state = $self->{currentState} if (!defined $state);
	($token) = $rest =~ /token\s+(\S+)/;
	($item) = $rest =~ /item (\d+)/;
	$self->why_lookahead($token, $state, $item);
    } elsif ($command =~ /^why (is )?(symbol )?(\S+) nullable/) {
	my $symbol = $3;
	$self->why_nullable($symbol);
    } elsif ($command =~ /^why (is )?(token )?(\S+) in FIRST\((.*?)\)/) {
	my ($token, $symbol) = ($3, $4);
	$self->why_FIRST($token, $symbol);
    } elsif (lc $command eq 'exit') {
	Tk::exit(0);
    } else {
        $self->log("Error: unknown command");
    }
}

sub status {
    my ($self, $msg) = @_;
    my $status = $self->{info}->{status_l};
    $status->configure(-text => $msg);
}

sub report_cmd {
    my ($self, $command) = @_;
    $self->{_t}->rewrite($command);
}

sub step {
    my ($self) = @_;

    my $shift_cb = $self->{callbacks}->{shift};
    local $self->{callbacks}->{shift} = sub { $shift_cb->(@_); 0; };
    my $reduce_cb = $self->{callbacks}->{reduce};
    local $self->{callbacks}->{reduce} = sub { $reduce_cb->(@_); 0; };
    my $read_cb = $self->{callbacks}->{read};
    local $self->{callbacks}->{read} = sub { $read_cb->(@_); 0; };

    $self->report_cmd("STEP");
    $self->go();
}

sub next_read {
    my ($self, $token) = @_;

    my $toknum;

    if (defined $token) {
        $toknum = $self->{parent}->{parser}->{symmap}->get_index($token, 1);
        if (!defined $toknum) {
            $self->log("Token $E{$token} unknown");
            return;
        }
    }

    # Continue if TOKEN given and the token read in is not TOKEN
    my $read_cb = $self->{callbacks}->{read};
    local $self->{callbacks}->{read} =
        sub { $read_cb->(@_); defined $toknum && $toknum != $_[1]; };

    $self->report_cmd("NEXT INPUT".(defined $token ? " $token" : ""));
    $self->go();
}

sub next_action {
    my ($self) = @_;

    my $shift_cb = $self->{callbacks}->{shift};
    local $self->{callbacks}->{shift} = sub { $shift_cb->(@_); 0; };
    my $reduce_cb = $self->{callbacks}->{reduce};
    local $self->{callbacks}->{reduce} = sub { $reduce_cb->(@_); 0; };

    $self->report_cmd("NEXT ACTION");
    $self->go();
}

sub next_reduce {
    my ($self, $symname) = @_;

    my $symnum;
    $symnum = $self->{parent}->{parser}->{symmap}->get_index($symname)
        if defined $symname;

    my $reduce_cb = $self->{callbacks}->{reduce};
    local $self->{callbacks}->{reduce} =
        sub {
            $reduce_cb->(@_);
            defined $symnum && $symnum != $_[3]->[1];
        };

    $self->report_cmd("NEXT REDUCE".(defined $symname ? " TO $symname" : ""));
    $self->go();
}

sub fileDialog {
    my ($self, $action, @types) = @_;
    push @types, ["All files", '*'];
    my $filename = $self->{win}->getOpenFile(-filetypes => \@types);
    return if !defined $filename || $filename eq '';
    $self->{_t}->userinput(sprintf($action, '"'.$filename.'"'));
}

sub load_parser {
    my ($self, $filename) = @_;
    $self->report_cmd("LOAD PARSER \"$filename\"");
    $self->log("Unimplemented");
}

sub load_file {
    my ($self, $filename) = @_;
    if (!open(FILE, $filename)) {
        $self->log("Error opening $E{$filename}: $!");
        return;
    }

    $self->report_cmd("LOAD \"$filename\"");
    $self->{current_file} = $filename;

    my @data = grep(!/^$/, <FILE>);
    close FILE;
    chomp(@data);

    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};

    my @tokens = eval {
        map { my ($t, $v) = split(/\s+/, $_, 2);
              [ $parser->{symmap}->get_index($t), $v ] } @data;
    };

    if ($@) {
        $self->log("Unknown token found in $E{$filename}: $@");
        $self->announce(no_file => $filename);
    } else {
        $self->log("$E{$filename} loaded");
        $self->{runner} =
          Parse::YALALR::Run->new($parser, \@tokens, $self->{callbacks});
        $self->announce(have_file => $filename);
	$self->set_state(0);
    }
}

sub _set_prompt {
    my $self = shift;
    my ($state, $la) = ($self->{currentState}, $self->{currentLA});
    my $prompt = '';
    $prompt .= "<state id=$state>$E{\"State $state\"}</state>"
      if defined $state;
    if (defined $la) {
	$prompt .= " " if $prompt;
	$prompt .= "<sym id=$la>".$self->{parent}->{parser}->dump_sym($la, 'xml')."</sym>";
    }
    $prompt .= $E{'> '};

    $self->{_t}->setprompt($prompt);
}

sub set_state {
    my ($self, $state) = @_;
    $self->{currentState} = $state;
    $self->_set_prompt();
}

sub set_lookahead {
    my ($self, $token) = @_;
    $self->{currentLA} = $token;
    $self->_set_prompt();
}

sub setup {
    my ($self) = @_;
    my $vipar = $self->{parent};
    my $parser = $vipar->{parser};
    my $ptree = $vipar->{parsetree};

    my %callbacks =
        ( 'read' => sub {
            my ($runner, $token) = @_;
            $self->log_read($token);
	    $self->{_t}->update();
	    !$self->{stopped};
          },
          discard => sub {
              $self->log("Discarded $E{$parser->dump_sym($_[1])}"); 1;
          },
          recover => sub {
              $self->log("Recovered on $E{$parser->dump_sym($_[1])}"); 1;
          },
          error => sub {
              $self->log("Error on $E{$parser->dump_sym($_[1])}"); 1;
          },
          popstate => sub {
              $self->log("Popping symbol $E{$parser->dump_sym($_[2])}"); 1;
          },
          fatal => sub {
              $self->log("FATAL: $E{$_[1]}"); 1;
          },
          'exec' => sub {
	      my $val = $_[2];
	      $val = '<undef>' if !defined $val;
              $self->log("Executed, val=$E{$val}"); 1;
          },
          done => sub {
              $self->end();
          },
          reduce => sub {
              my ($runner, $token, $oldstate, $action, $value, $newstate) = @_;
              my $lhs = $action->[1];
              $ptree->reduce($action->[2], $parser->dump_sym($lhs), $value);
              $vipar->select_state($newstate);
              $self->log_reduce($token, $oldstate, $newstate, $action);
	      $self->{_t}->update();
              !$self->{stopped};
          },
          'shift' => sub {
              my ($runner, $state, $sym, $tostate) = @_;
              $ptree->push($parser->dump_sym($sym));
              $vipar->select_state($tostate->{id});
              $self->log_shift($sym, $state, $tostate);
              1;
          },
        );

    $self->{callbacks} = \%callbacks;
    $self->announce('no_file');

    print "Filling vipar: $vipar\n";
    print "Filling file: $vipar->{datafile}\n";
    $self->{_t}->userinput("load \"$vipar->{datafile}\"")
      if defined $vipar->{datafile};
}

sub go {
    my $self = shift;
    $self->{runner}->parse();
    $self->{stopped} = 0;
}

sub run {
    my ($self, $cmd) = @_;
    $self->{_t}->userinput($cmd);
}

1;
