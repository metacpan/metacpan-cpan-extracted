# -*- cperl -*-

use lib '../..'; # For running directly (to test)

package Parse::YALALR::Run;

use Parse::YALALR::Build;
use strict;
use vars qw($VERSION);

$VERSION = '0.02';

sub run_parser {
    my ($parser, $tok) = @_;
    my $error = $parser->{error};
    my $end = $parser->{end};

    my $get_tok;
    my $i;

    if (ref $tok eq 'CODE') {
	$get_tok = $tok;
    } else {
	$i = 0;
	$get_tok = sub { @{$tok->[$i++] || [$parser->{end}, undef]}; };
    }

    my ($next_tok, $next_val) = $get_tok->();
    print "Read token ", $parser->dump_sym($next_tok), "\n";

    my @state_stack = ($parser->{init_state});
    my @sym_stack;
    my @val_stack;

    my $state;
    my $recovery_state = 0;
    my $post_error_tok;
    my $post_error_val;
    my $using_post_error = 0;

    while (1) {
	$state = $state_stack[-1];

	print "\n";
	print "Syms: ", join(" ", map { $parser->dump_sym($_) } @sym_stack), "\n";
	print "Vals: ", join(" ", map { (defined) ? $_ : '<undef>' } @val_stack), "\n";
	print "States: ", join(" ", map { $_->{id}; } @state_stack ), " on ";
	print $parser->dump_sym($next_tok), ": ";

	my $action = $state->{actions}->[$next_tok];
	if ($recovery_state == 2) {
	    # If we can't use the next token, or the next token is the end
	    # token and the action is a shift (will this happen?), then
	    # eat tokens until we can do something. Or we run past the end.
	    if (!defined $action) {
		if ($next_tok == $end) {
                    print "Unable to recover from error by EOF\n";
                    return undef;
                }
		print "eat(".$parser->dump_sym($next_tok).")\n";
		($next_tok, $next_val) = $get_tok->();
		print "Read token ", $parser->dump_sym($next_tok), "\n";
		next;
	    } else {
		$recovery_state = 0;
		print "recover(".$parser->dump_sym($next_tok)."), ";
	    }
	}

        if (!defined $action) {
            print "ERROR!!!\n";

	    # Start recovering from error by popping states until one is
	    # reached that can do something on an error token
	    while (!defined $state->{actions}->[$error] && @state_stack > 0) {
		print "Popping state $state_stack[-1]->{id}\n";
		pop(@state_stack);
		pop(@sym_stack);
		pop(@val_stack);
		$state = $state_stack[-1];
	    }

	    if (defined $post_error_tok && $post_error_tok == $end) {
		print "Second attempt to error out at EOF, cannot catch\n";
		return undef;
	    }

	    # If we run out of states, it's an uncaught error
	    if (@state_stack == 0) {
		print "UNCAUGHT ERROR\n";
		return undef;
	    }

	    # Otherwise, pretend we saw an error token. We'll also enter an
	    # error recovering state where we keep consuming input until we
	    # can perform another action.
	    $post_error_tok = $next_tok;
	    $post_error_val = $next_val;
	    $next_tok = $error;
#	    $next_val = undef;
	    $next_val = '<error>';
	    $recovery_state = 1; # recovering, unused error

        } elsif (ref $action) {
	    # Reduce
	    print "reduce ", $parser->dump_rule($action->[0]), "\n";
#  	    print "  because ", ($parser->explain($state_stack[-1]{id},
#  						$next_tok,
#  						'reduce'))[1], "\n";

	    my $v1;
	    if (defined(my $code = $parser->{rule_code}->{$action->[0]})) {
                print "Executing code...";
#		@::v = @val_stack[-$action->[2] .. -1];
#                $v1 = eval($$code);
                $v1 = $code->(@val_stack[-$action->[2] .. -1]);
                print "value is $v1, $@\n";
	    } else {
	        $v1 = $val_stack[-$action->[2]];
            }
	    $#state_stack -= $action->[2];
	    $#sym_stack -= $action->[2];
	    $#val_stack -= $action->[2];
	    $state = $state_stack[-1];

	    if ($action->[1] == $parser->{startsym}) {
		print "Parse completed successfully.\n";
		print "Final value: $v1\n";
		return 1;
	    }

	    push(@sym_stack, $action->[1]);
	    push(@val_stack, $v1);
	    my $statenum = $state->{actions}->[$action->[1]];
	    push(@state_stack, $parser->{states}->[$statenum]);
	} else {
	    # shift
	    print "shift, goto state $parser->{states}->[$action]{id}\n";
#  	    print "  because ", ($parser->explain($state_stack[-1]{id},
#  						$next_tok,
#  						'shift'))[1], "\n";
#	    print "  and if it helps, state $state_stack[-1]{id} kernel is ",
#	      $parser->dump_kernel($state_stack[-1]), "\n";
	    push(@sym_stack, $next_tok);
	    push(@val_stack, $next_val);
	    push(@state_stack, $parser->{states}->[$action]);
	    if ($next_tok == $error) {
		$recovery_state = 2; # recovering, used error
		($next_tok, $next_val) = ($post_error_tok, $post_error_val);
	    } else {
		if ($next_tok == $end) {
                    print "Unable to recover from error by EOF\n";
                    return undef;
                }
		($next_tok, $next_val) = $get_tok->();
	    }
	    print "Read token ", $parser->dump_sym($next_tok), "\n";
	}
    }
}

sub new {
    my ($class, $parser, $tok, $callbacks) = @_;

    my $tokenizer = $tok;
    if (ref $tokenizer ne 'CODE') {
	my $i = 0;
	$tokenizer = sub { @{$tok->[$i++] || [$parser->{end}, undef]}; };
    }

    my $self = { parser => $parser,
                 callbacks => $callbacks,
                 states => [ $parser->{init_state} ],
                 symbols => [],
                 values => [],
                 tokenizer => $tokenizer,
                 recovery_state => 0,
                 using_post_error => 0,
                 next_tok => undef,
                 next_val => undef,
                 post_error_tok => undef,
                 post_error_val => undef,
                 init => 0,
             };
    bless $self, (ref $class || $class);
}

# Callbacks:
#  read(token)
#  discard(token)
#  recover(token)
#  error(token)
#  popstate(state,symbol,value)
#  fatal(message)
#  exec(code,value)
#  reduce(action)
#  done(action)
#  shift(action,token)
#
sub parse {
    my Parse::YALALR::Run $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};

    my $error = $parser->{error};
    my $end = $parser->{end};
    my $get_tok = $self->{tokenizer};

    my $state_stack = $self->{states};
    my $sym_stack = $self->{symbols};
    my $val_stack = $self->{values};

    while (1) {
	my $state = $state_stack->[-1];

        my ($next_tok, $next_val);

        if (!defined $self->{next_tok}) {
            ($self->{next_tok}, $self->{next_val}) = $get_tok->();
            return if !$self->{callbacks}->{read}->($self, $self->{next_tok});
        }

        ($next_tok, $next_val) = ($self->{next_tok}, $self->{next_val});

	my $action = $state->{actions}->[$next_tok];
        print "ACTION := ".(defined $action ? $action : "<undef>")."\n";
	if (!defined $action && $self->{recovery_state} == 1) {
	    # If we can't use the next token, or the next token is the end
	    # token and the action is a shift (will this happen?), then
	    # eat tokens until we can do something. Or we run past the end.
	    if (!defined $action) {
		if ($next_tok == $end) {
                    die "Unable to recover from error by EOF\n";
                }
                return if !$self->{callbacks}->{discard}->($self, $next_tok);
                undef $self->{next_tok};
		next;
	    } else {
		$self->{recovery_state} = 0;
                return if !$self->{callbacks}->{recover}->($self, $next_tok);
	    }
	}

        if (!defined $action) {
	    print "A\n";
            my $continue = $self->{callbacks}->{error}->($self, $next_tok);
	    print "B\n";

	    # Start recovering from error by popping states until one is
	    # reached that can do something on an error token
	    print "error action: ".($state->{actions}->[$error] || "<undef>")."\n";
	    print "sym stack: ".(0+@$sym_stack)."\n";
	    print "next tok: ".$parser->dump_sym($next_tok)."\n";

	    while (!defined $state->{actions}->[$error] && @$sym_stack > 0) {
		print "C\n";
                return if !$self->{callbacks}->{popstate}->($self,
                                                            $state_stack->[-1],
                                                            $sym_stack->[-1],
                                                            $val_stack->[-1]);
		print "D\n";
		pop(@$state_stack);
		pop(@$sym_stack);
		pop(@$val_stack);
		$state = $state_stack->[-1];
	    }

	    print "E\n";
	    if (defined $self->{post_error_tok}
                && $self->{post_error_tok} == $end)
            {
		print "F\n";
                $self->{callbacks}->{fatal}->($self, "second attempt to error out at EOF");
		return;
	    }

	    print "G\n";
	    # If we run out of symbols, it's an uncaught error
	    if (@$sym_stack == 0) {
                $self->{callbacks}->{fatal}->($self, "uncaught error");
		return;
	    }

	    print "H\n";
	    # Otherwise, pretend we saw an error token. We'll also enter an
	    # error recovering state where we keep consuming input until we
	    # can perform another action.
	    $self->{post_error_tok} = $next_tok;
	    $self->{post_error_val} = $next_val;
	    $next_tok = $error;
	    $next_val = '<error>';
	    $self->{recovery_state} = 1; # recovering, unused error
	    print "I\n";
            return if !$continue;

        } elsif (ref $action) {
	    # Reduce
	    my $v1;
	    if (defined(my $code = $parser->{rule_code}->{$action->[0]})) {
                $v1 = $code->(@$val_stack[-$action->[2] .. -1]);
                $self->{callbacks}->{exec}->($self, $code, $v1);
	    } else {
	        $v1 = $val_stack->[-$action->[2]];
                $self->{callbacks}->{exec}->($self, undef, $v1);
            }
            my $oldstate = $state_stack->[-1];
	    $#$state_stack -= $action->[2];
	    $#$sym_stack -= $action->[2];
	    $#$val_stack -= $action->[2];
	    $state = $state_stack->[-1];

	    if ($action->[1] == $parser->{startsym}) {
                $self->{callbacks}->{done}->($self, $action);
		return 1;
	    }

	    push(@$sym_stack, $action->[1]);
	    push(@$val_stack, $v1);
	    my $statenum = $state->{actions}->[$action->[1]];
	    push(@$state_stack, $parser->{states}->[$statenum]);
            return if !$self->{callbacks}->{reduce}->($self, $next_tok, $oldstate, $action, $v1, $statenum);
	} else {
	    # shift, goto state $parser->{states}->[$action]{id}
	    push(@$sym_stack, $next_tok);
	    push(@$val_stack, $next_val);
            my $tostate = $parser->{states}->[$action];
            my $oldstate = $state_stack->[-1];
	    push(@$state_stack, $tostate);

            my $continue =
              $self->{callbacks}->{shift}->($self, $oldstate, $next_tok, $tostate);

	    if ($next_tok == $error) {
		$self->{recovery_state} = 2; # recovering, used error
		($next_tok, $next_val) =
                  ($self->{post_error_tok}, $self->{post_error_val});
                return if !$self->{callbacks}->{recover}->($self, $action);

	    } else {
		if ($next_tok == $end) {
                    print "Unable to recover from error by EOF\n";
                    return undef;
                }
                undef $self->{next_tok};
	    }

            return if !$continue;
	}
    }
}

1;
__END__
package main;

my $testfile = shift(@test);
my $default_lang = shift(@test);
open(SAMPLE, $testfile) or die "open $testfile: $!";
$::t0 = time;
print "Start: time=$::t0\n";
my $raw = Parse::YALALR::Build->new($default_lang, \*SAMPLE);
my $parser = $raw->parser;
print "Done: time=".time."=t0+".(time-$::t0)."\n";
# print $raw;

my $kernel = $parser->{states}->[7];
$DB::single = 1;
my ($f, $ff) = $parser->explain_lookahead($kernel,
					  7,
					  $parser->{symmap}->get_index("<end>"),
					  undef, 'xml');
print $f;
print $ff, "\n";

__END__
#  print $raw->dump_NULLABLE();
#  print $raw->dump_FIRSTs();
#  print $raw->dump_parser();

$raw->build_table();
print $raw->stats();

my $xstate = $raw->expand_state($raw->{states}->[0]);
#print $raw->dump_expansion($xstate), "\n";

my @input = @test;
my $xx = 1;
my @toks = map { [ $parser->{symmap}->get_index($_), $xx++ ] } @input;
Parse::YALALR::Run::run_parser($raw, \@toks);
__END__
use Parse::YALALR::Generate::C;
my $generator = Parse::YALALR::Generate::C->new($raw);
$generator->generate_table();
open(OUT, ">o/1.c") or die;
$generator->write_all(\*OUT);
open(OUT, ">o/1.h") or die;
$generator->write_header(\*OUT);

=head1 NAME

Parse::YALALR - Yet Another LALR parser

=head1 SYNOPSIS

 From the command line:
 % yalalr [--lang=c] [--lang=perl] grammar.y

 In a program:
 use Parse::YALALR::Build;
 use Parse::YALALR::Run;

 open(GRAMMAR, "<expr.y") or die "open expr.y: $!";
 $builder = Parse::YALALR::Build->new("perl", \*GRAMMAR);
 $builder->build_table();
 $parser = $builder->{parser};
 @inputstream = ([number=>10], ["'+'"=> undef ], [number=>20]);
 $_->[0] = $parser->{symmap}->get_index($_->[0]) foreach (@inputstream);
 Parse::YALALR::Run::run_parser($parser, \@inputstream);

=head1 DESCRIPTION

Generates an LALR parser from an input grammar. Really just intended as a
companion to Parse::Vipar, but (sorta) works standalone. Does not yet
generate a standalone parser.

run_parser will also accept a CODE ref to use as a lexer. Every invocation
should return a pair (token, value). The above example is equivalent to

 $lexer = { my $i = 0; sub {
			     my ($t,$v)=@{$inputstream[$i++]};
			     ($parser->get_index($t), $v)
			   }
	  };
 Parse::YALALR::Run::run_parser($parser, $lexer);

=head1 AUTHOR

Steve Fink <steve@fink.com>

=head1 SEE ALSO

Parse::YALALR

=cut
