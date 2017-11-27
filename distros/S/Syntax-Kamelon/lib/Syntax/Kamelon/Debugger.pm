package Syntax::Kamelon::Debugger;

use 5.006;
use strict;
use warnings;
use Time::HiRes qw(time);
use base qw(Syntax::Kamelon);

my $VERSION = '0.15';

my %functions = (
	step => [\&StepPre, \&StepPost],
	timer => [\&TimerPre, \&TimerPost],
	watch => [\&WatchPre, \&WatchPost],
);

sub new {
	my $class = shift;
	my %args = (@_);
	
   my $self = $class->SUPER::new(%args);
	$self->{CURPOINT} = [1, 0];
	$self->{CURRULE} = '';
	$self->{DEBUGSTACK} = [];
	$self->{ELAPSED} = 0;
	$self->{LASTPATH} = "";
	$self->{LASTPOINT} = [];
	$self->{LINE} = 1;
	$self->{STARTIME} = '';
	$self->{STEPCALL} = sub {
		my ($text, $inf, $result) = @_;
		print "Line:   '$$text'\n";
		print "Result: $result\n";
		for (sort keys %$inf) {
			print "$_: '" , $inf->{$_}, "'\n"
		}
		print "\nPress a Enter to continue\n";
		my $key = <STDIN>;
	};
	$self->{TASKS} = [];
	$self->{WATCHINFO} = {};
	$self->{WATCHPOINT} = [];
	$self->{WATCHRESULT} = "";
   return $self;
}

sub CurRule {
	my $self = shift;
	return $self->{CURRULE};
}

sub DebugStackPull {
	my $self = shift;
	my $stack = $self->{DEBUGSTACK};
	my $i = pop @$stack;
	return @$i;
}

sub DebugStackPush {
	my $self = shift;
	my $stack = $self->{DEBUGSTACK};
	push @$stack, \@_;
}

sub GetStackImage {
	my $self = shift;
	my $stack = $self->{STACK};
	my @o = ();
	foreach my $item (@$stack) {
		my @i = ($item->[0]->{syntax}, $item->[1]);
		if (defined $item->[2]) {
			my $i2 = $item->[2];
			for (@$i2) { push @i, $_ }
		}
		push @o, \@i
	}
	return \@o
}

sub NewLine {
	my $self = shift;
	my $l = $self->{LINE};
	$l ++;
	$self->{LINE} = $l;
}

sub ParseContext {
	my ($self, $text, $callbacklist, $debuginfo) = @_;
	my $r = 0;
	my $num = 0;
	for (@$callbacklist) {
		my @i = @$_;
		my $inf = $debuginfo->[$num];
		$self->{CURRULE} = $inf->{path};
		$self->PreTask($$text, $inf);
		my $call = shift @i;
		$r = &$call($self, $text, @i);
		$self->PostTask($text, $inf, $r);
		$num ++;
		last if $r;
	}
	return $r;
}

sub ParseLine {
	my ($self, $text) = @_;
	while ($text ne '') {
		my $top = $self->{STACK}->[0];
		my ($hl, $context) = @$top;
		my $ctd = $hl->{contexts}->{$context};
		if ($text =~ s/^(\n)//) {
			if ($self->LineStart) {
				my $m = $ctd->{emptycontext};
				&$m;
			}
			$self->LineEndContext($ctd->{endcontext});
			$self->SnippetForce;
# 			my $attr = $ctd->{attribute};
# 			$self->SnippetParse($1, $attr);
			$self->SnippetForce;
			$self->{LINESEGMENT} = '';
			$self->NewLine;
		} else {
			my $callbacklist = $ctd->{callbacks};
			my $debuginfo = $ctd->{debug};
			my $result = $self->ParseContext(\$text, $callbacklist, $debuginfo);
			unless($result) {
				my $f = $ctd->{fallthroughcontext};
				if (defined($f)) {
					&$f;
				} else {
					if ($text =~ s/^([^\n])//) {
						my $attr = $self->{USEATTRIBSTACK}->[0];
						unless (defined $attr) {
							$attr = $ctd->{attribute};
						}
						$self->SnippetParse($1, $attr);
					}
				}
			}
		}
	}
}

sub ParseResult {
	my ($self, $text, $string, $context, $attr) = @_;
	if ($string  =~ s/\n$//) {
		$self->LogWarning($self->{CURRULE} ."Attempted to parse a newline in line " . $self->{LINE} . "\n");
	}
	return $self->SUPER::ParseResult($text, $string, $context, $attr)
}

sub ParseResultLookAhead {
	my ($self, $text, $string, $context, $attr) = @_;
	if ($string  =~ s/\n$//) {
		$self->LogWarning($self->{CURRULE} ."Attempted to parse a newline in line " . $self->{LINE} . "\n");
	}
	return $self->SUPER::ParseResultLookAhead($text, $string, $context, $attr)
}

sub PreTask {
	my ($self, $text, $rule) = @_;
	my $t = $self->{TASKS};
	foreach my $task (@$t) {
		my $call = $functions{$task}->[0];
		&$call($self, $text, $rule)
	}
	my $time = time;
	$self->DebugStackPush($text, $rule, $time);
}

sub PostTask {
	my $time = time;
	my ($self, $text, $rule, $result) = @_;
	my ($ptext, $prule, $ptime) = $self->DebugStackPull;
	$self->{ELAPSED} = $time - $ptime;
	if ($result) {
		$self->{PARSED} = substr($ptext, 0, length($ptext) - length($text));
	}
	my $t = $self->{TASKS};
	foreach my $task (@$t) {
		my $call = $functions{$task}->[1];
		&$call($self, $text, $prule, $result);
	}
}

sub Reset {
	my $self = shift;
	$self->SUPER::Reset;
	$self->{DEBUGSTACK} = [];
	$self->{ELAPSED} = 0;
	$self->{LASTPATH} = "";
	$self->{LINE} = 1;
	$self->{WATCHRESULT} = "";
	$self->{WATCHINFO} = {};
}

sub SetTasks {
	my $self = shift;
	my @tasks = ();
	while (@_) {
		my $t = shift;
		if ( $t =~ /^step|timer|watch$/) {
			push @tasks, $t
		} else {
			warn "invalid task $t";
		}
	}
	$self->{TASKS} = \@tasks; 
}

sub SetWatch {
	my $self = shift;
	my @point = ();
	while (@_) {
		my $t = shift;
		if ( $t =~ /^\d+$/) {
			push @point, $t
		} else {
			warn "Value should be a positive integer: $t";
		}
	}
	$self->{WATCHPOINT} = \@point;
}

sub StepPost {
	my $self = shift;
	my $call = $self->{STEPCALL};
	&$call(@_);
}

sub StepPre {
	my ($self, $text, $inf) = @_;
}

sub TimerPost {
	my ($self, $text, $inf, $result) = @_;
}

sub TimerPre {
	my ($self, $text, $inf) = @_;
}

sub WatchPosition {
	my ($self, $line, $pos) = @_;
	unless (defined $line) { $line = $self->{LINE} }
	unless (defined $pos) { $pos = $self->Column }
	my $wpoint = $self->{WATCHPOINT};
	if (@$wpoint == 2) {
		my ($wline, $wpos) = @$wpoint;
		if ($line < $wline) {
			return 0
		} elsif ($line == $wline) {
			if ($pos < $wpos) {
				return 0
			} elsif ($pos == $wpos) {
				return 1
			} else {
				return 2
			}
		} else {
			return 2
		}
	} else {
		warn "Watchpoint not properly set"
	}
}

sub WatchPost {
	my ($self, $text, $inf, $result) = @_;
	my $r = $self->WatchPosition($self->{LINE}, $self->Column);
	my $status = $self->{WATCHRESULT};
	my $path = $inf->{path};
	if (($r eq 2) and ($status eq '')) {
		$self->{WATCHINFO} = [ $inf, $self->{PARSED}, $self->GetStackImage ];
		if ($result) {
			$self->{WATCHRESULT} = "Matched";
		}
	} else {
		$self->{LASTPOINT} = [ $self->{LINE}, $self->Column ];
		$self->{LASTPATH} = $path;
	}
}

sub WatchPre {
	my ($self, $text, $inf) = @_;
# 	print "parsing ",  $inf->{path}, "\n";
	my $r = $self->WatchPosition($self->{LINE}, $self->Column);
	my $status = $self->{WATCHRESULT};
	if (($r eq 2) and ($status eq '')){
		my $lp = $self->{LASTPOINT};
		if ($self->WatchPosition(@$lp) < 2) {
			$self->{WATCHRESULT} = "Failed";
			$self->{WATCHINFO} = [ $inf, undef, $self->GetStackImage];
		}
	}
}

sub WatchResult {
	my $self = shift;
	return ($self->{WATCHRESULT}, $self->{WATCHINFO})
}

1;
__END__
