#
# transform parsed PHP statements
#
package PHP::Decode::Transformer;

use strict;
use warnings;
use Carp 'croak';
use PHP::Decode::Array qw(is_int_index);
use PHP::Decode::Parser qw(:all);
use PHP::Decode::Func;

our $VERSION = '0.301';

# avoid 'Deep recursion' warnings for depth > 100
#
no warnings 'recursion';

# In php-5.3 old superglobal names were still available and mapped to new names:
# $HTTP_SERVER_VARS 	$_SERVER
# $HTTP_GET_VARS 	$_GET
# $HTTP_POST_VARS 	$_POST
# $HTTP_POST_FILES 	$_FILES
# $HTTP_SESSION_VARS 	$_SESSION
# $HTTP_ENV_VARS 	$_ENV
# $HTTP_COOKIE_VARS 	$_COOKIE
#
my @superglobal_old = ('$HTTP_SERVER_VARS', '$HTTP_GET_VARS', '$HTTP_POST_VARS', '$HTTP_POST_FILES', '$HTTP_SESSION_VARS', '$HTTP_ENV_VARS', '$HTTP_COOKIE_VARS');
my %superglobal = map { $_ => 1 } ('$GLOBALS', '$_SERVER', '$_GET', '$_POST', '$_FILES', '$_COOKIE', '$_SESSION', '$_REQUEST', '$_ENV', @superglobal_old);

my $histidx = 0;

# Context:
# - $ctx->{defines}:        map of constants & user-defined values
# - $ctx->{globals}:        map of defined global & superglobal variables
# - $ctx->{varmap}:         map of defined local variables (points to $ctx->{globals} on toplevel)
# - $ctx->{varmap}{global}: map of 'global $var' declarations in scope (renames $var to '$GLOBALS$var')
# - $ctx->{varmap}{static}: map of 'static $var' declarations for functions & methods
# - $ctx->{varmap}{ref}:    map of $var = &$var2 references in scope
# - $ctx->{varmap}{fun}:    map of registered functions
# - $ctx->{varmap}{class}:  map of registered classes
# - $ctx->{varmap}{inst}:   map of #inst -> $var references in scope (renames obj->var to '$inst$var')
# - $ctx->{varhist}:        tracks variable assignments to insert on block level
# - $ctx->{infunction}:     function/method name if in function (lowercase)
# - $ctx->{class_scope}:    class name exists only if in classfunc/method-call (lowercase)
# - $ctx->{namespace}:      namespace or '' if default namespace
# - $ctx->{incall}:         in function/method calls (with resolved arguments)
# - $ctx->{tainted}:        incomplete variables in context
# - $ctx->{skipundef}:      skip conditions like empty($x) for undefined $x, so that no block is dropped
#
# Note: {static}{<func|class::func>} & {inst}{<class>} entries are always lowercase.
#
# supported {simplify} flags: {expr => 1, elem => 1, stmt => 1, call => 1, arr => 1}
# supported {skip} flags: {call => 1, loop => 1, null => 1, stdout => 1, treat_empty_str_like_empty_array => 1}
# supported {with} flags: {getenv => {}, optimize_block_vars => 1, invalidate_tainted_vars => 1, translate => 1}
#
sub new {
	my ($class, %args) = @_;
	my %varmap;
	my $parser = $args{parser} or croak __PACKAGE__ . " expects parser";

	my $self = bless {
		toplevel => 1, # append STDOUT after eval
		defines => {},
		globals => \%varmap,
		varmap => \%varmap,
		varhist => {},
		infunction => 0,
		incall => 0,
		namespace => '',
		tainted => 0,
		skipundef => 0,
		max_loop => 10000,
		simplify => {expr => 1, elem => 1, stmt => 1, call => 1, arr => 1},
		skip => {},
		with => {},
		warn => sub { },
		superglobal => \%superglobal,
		%args, # might override preceding keys
	}, $class;

	$self->{max_loop_const} = $self->{max_loop};
	$self->{max_loop_while} = 10 * $self->{max_loop};
	$self->{max_repeat} = $self->{max_loop};

	$self->{varmap}{inst} = {} unless exists $self->{varmap}{inst};
	$self->{varmap}{fun} = {} unless exists $self->{varmap}{fun};
	$self->{varmap}{class} = {} unless exists $self->{varmap}{class};
	$self->{varmap}{static} = {} unless exists $self->{varmap}{static};
	$self->{varmap}{stdout} = { buf => [] } unless exists $self->{varmap}{stdout};

	$self->_setup_env($self->{with}{getenv}) if exists $self->{with}{getenv} && $self->{toplevel};

	return $self;
}

# The default is to reference the global and local varmaps from parent.
#
sub subctx {
	my ($ctx, %args) = @_;

	$args{globals} = $ctx->{globals} unless exists $args{globals};
	$args{varmap} = $ctx->{varmap} unless exists $args{varmap};
	$args{parser} = $ctx->{parser} unless exists $args{parser};

	my $ctx2 = PHP::Decode::Transformer->new(
		toplevel => 0,
		defines => $ctx->{defines},
		infunction => $ctx->{infunction},
		incall => $ctx->{incall},
		namespace => $ctx->{namespace},
		tainted => $ctx->{tainted},
		skipundef => $ctx->{skipundef},
		max_loop => $ctx->{max_loop},
		simplify => $ctx->{simplify},
		skip => $ctx->{skip},
		with => $ctx->{with},
		warn => $ctx->{warn},
		exists $ctx->{log} ? (log => $ctx->{log}) : (),
		exists $ctx->{class_scope} ? (class_scope => $ctx->{class_scope}) : (),
		%args);

	return $ctx2;
}

# Create a clone of current context with a shallow copy of varmap & globals map
#
# This is used for speculative execution when a if- or loop-condition could
# not be resolved.
#
sub clone {
	my ($ctx) = @_;
	my %varmap = %{$ctx->{varmap}};
	my $globals = $ctx->{infunction} ? {%{$ctx->{globals}}} : \%varmap;

	return $ctx->subctx(globals => $globals, varmap => \%varmap, varhist => {}, skipundef => 1);
}

# used for function simplifications
#
sub simplification_ctx {
	my ($ctx, %args) = @_;

	$args{globals} = {};
	$args{varmap} = {};
	$args{varhist} = {};
	$args{skipundef} = 1; # skip undefined variables
	$args{tainted} = 1; # don't assume #null for undefined vars

	# allow to reference global functions and classes, when
	# a function or class is simplified.
	#
	# create shallow copies, so that no new functions are
	# created for parent ctx.
	#
	if (exists $ctx->{globals}{fun}) {
		if (exists $ctx->{varmap}{fun}) {
			$args{globals}{fun} = {%{$ctx->{globals}{fun}}, %{$ctx->{varmap}{fun}}};
		} else {
			$args{globals}{fun} = {%{$ctx->{globals}{fun}}};
		}
	}
	if (exists $ctx->{globals}{class}) {
		if (exists $ctx->{varmap}{class}) {
			$args{globals}{class} = {%{$ctx->{globals}{class}}, %{$ctx->{varmap}{class}}};
		} else {
			$args{globals}{class} = {%{$ctx->{globals}{class}}};
		}
	}
	# keep global statements active when functions are simplified
	#
	if (exists $ctx->{varmap}{global}) {
		$args{varmap}{global} = {%{$ctx->{varmap}{global}}};
	}
	return $ctx->subctx(%args);
}

# used for function calls (local vars can be used even if caller is tainted)
#
sub subscope_ctx {
	my ($ctx, %args) = @_;
	my $varmap = $args{varmap} or croak __PACKAGE__ . " expects varmap";

	$args{parent} = $ctx; # keep reference to parent scope

	# copy globals and pass new varmap
	# add instance var context to local varmap.
	#
	if (exists $ctx->{varmap}{'$this'}) {
		$args{varmap}{'$this'} = $ctx->{varmap}{'$this'};
	}
	if (exists $ctx->{varmap}{inst}) {
		$args{varmap}{inst} = $ctx->{varmap}{inst};
	}
	if (exists $ctx->{varmap}{fun}) {
		$args{varmap}{fun} = $ctx->{varmap}{fun};
	}
	if (exists $ctx->{varmap}{class}) {
		$args{varmap}{class} = $ctx->{varmap}{class};
	}
	if (exists $ctx->{varmap}{static}) {
		$args{varmap}{static} = $ctx->{varmap}{static};
	}
	return $ctx->subctx(%args);
}

sub _setup_env {
	my ($ctx, $env) = @_;
	my $parser = $ctx->{parser};
	my $arr = $parser->newarr();

	foreach my $key (keys %$env) {
		my $k = $parser->setstr($key);
		my $v = $parser->setstr($env->{$key});
		$arr->set($k, $v);
	}
	$ctx->{globals}{'$_ENV'} = $arr->{name};
	my $arr2 = $arr->copy();
	$ctx->{globals}{'$_SERVER'} = $arr2->{name};

	# superglobal arrays are currently created on the fly
	#
	if (0) {
		foreach my $var (keys %{$ctx->{superglobal}}) {
			unless (exists ($ctx->{globals}{$var})) {
				$arr = $parser->newarr();
				$ctx->{globals}{$var} = $arr->{name};
			}
		}
	}
}

sub cmd_getenv {
	my ($ctx, $cmd, $args) = @_;
	my $parser = $ctx->{parser};

	if (exists $ctx->{with}{getenv} && (scalar @$args == 1)) {
		my $s = $parser->get_strval($$args[0]);
		if (defined $s) {
			# on some platforms getenv is case-independant, $_ENV/$_SERVER is not
			# https://php.net/manual/en/function.getenv.php
			#
			if (exists $ctx->{globals}{'$_ENV'}) {
				my $arr = $parser->{strmap}{$ctx->{globals}{'$_ENV'}};
				my $idxstr = $$args[0];
				if ($s ne uc($s)) {
					$idxstr = $parser->setstr(uc($s));
				}
				my $arrval = $arr->get($idxstr);
				if (defined $arrval) {
					return $arrval;
				}
			}
			return $parser->setstr('');
		}
	}
	return;
}

sub cmd_ob_start {
	my ($ctx, $cmd, $args) = @_;
	my $parser = $ctx->{parser};

	# https://php.net/manual/en/function.ob-start.php
	# buffer output until ob_end_flush()/ob_end_clean() is called.
	# read output buffer via ob_get_contents().
	#
	# TODO: ob_start stacking
	#
	if (scalar @$args >= 1) {
		# string handler ( string $buffer [, int $phase ] )
		#
		my $handler = $$args[0];
		my $name = $parser->get_strval($$args[0]);
		if (exists $ctx->{globals} && exists $ctx->{globals}{stdout} && defined $name) {
		    unless ($ctx->{infunction}) {
			$ctx->{log}->($ctx, 'cmd', $cmd, "(handler: $name)") if $ctx->{log};

			my $fun = $ctx->getfun($name);
		        if (defined $fun) {
				my ($_name, $a, $b, $p) = @{$parser->{strmap}->{$fun}};
				my $f = $parser->setfun(undef, $a, $b);
				my $v = '$ob_'.$name;
				$ctx->{globals}{stdout}{handler} = $v; # handler variable
				$ctx->{globals}{stdout}{ob} = [];

				# note: returns handler assignment instead of bool here
				#
				my $e = $parser->setexpr('=', $v, $f);
				#my $e = $parser->setcall('ob_start', [$f]);
				return $e;
				#return $parser->setnum(1);
			} else {
				return $parser->setnum(0);
			}
		    }
		}
	} else {
		if (exists $ctx->{globals} && exists $ctx->{globals}{stdout}) {
	            unless ($ctx->{infunction}) {
			$ctx->{log}->($ctx, 'cmd', $cmd, "()") if $ctx->{log};
			$ctx->{globals}{stdout}{handler} = '#null';
			$ctx->{globals}{stdout}{ob} = [];
			return $parser->setnum(1);
		    }
		}
	}
	return;
}

sub cmd_ob_end_flush {
	my ($ctx, $cmd, $args) = @_;
	my $parser = $ctx->{parser};

	if (exists $ctx->{globals} && exists $ctx->{globals}{stdout}) {
		if (exists $ctx->{globals}{stdout}{handler}) {
		    unless ($ctx->{infunction}) {
			my @r;
			my $handler = $ctx->{globals}{stdout}{handler};
			my @ob = @{$ctx->{globals}{stdout}{ob}};
			delete $ctx->{globals}{stdout}{handler};
			delete $ctx->{globals}{stdout}{ob};
			$ctx->{log}->($ctx, 'cmd', $cmd, "(handler: $handler) [%s]", join(' ', @ob)) if $ctx->{log};
			merge_str_list(\@ob, $parser);
			while (my $s = shift @ob) {
				if (is_strval($s) && ($handler ne '#null')) {
					my $h = $parser->setcall($handler, [$s]);
					my $k = $ctx->exec_statement($h);

					if (defined $k) {
						push(@r, $h);
					}
				} else {
					push(@{$ctx->{globals}{stdout}{buf}}, $s);
				}
			}
			if (@r) {
				# note: returns handler call instead of bool here
				#
				return _flat_block_or_single($parser, \@r);
			}
			return $parser->setnum(1);
		    }
		} else {
		    unless ($ctx->{infunction}) {
			return $parser->setnum(0);
		    }
		}
	}
	return;
}

sub cmd_ob_end_clean {
	my ($ctx, $cmd, $args) = @_;
	my $parser = $ctx->{parser};

	if (exists $ctx->{globals} && exists $ctx->{globals}{stdout}) {
		if (exists $ctx->{globals}{stdout}{handler}) {
		    unless ($ctx->{infunction}) {
			delete $ctx->{globals}{stdout}{handler};
			delete $ctx->{globals}{stdout}{ob};
			return $parser->setnum(1);
		    }
		} else {
		    unless ($ctx->{infunction}) {
			return $parser->setnum(0);
		    }
		}
	}
	return;
}


sub register_funcs {
	my ($list, $ctx, $parser) = @_;

	foreach my $k (@$list) {
		if (($k =~ /^#stmt\d+$/) && ($parser->{strmap}{$k}[0] eq 'namespace')) {
			my ($arg, $block) = @{$parser->{strmap}->{$k}}[1..2];
			$ctx->{namespace} = $arg; # always use case in-sensitive later
		} elsif ($k =~ /^#fun\d+$/) {
			my ($f, $a, $b, $p) = @{$parser->{strmap}->{$k}};
			if (defined $f) {
				$ctx->registerfun($f, $k);
			}
		} elsif ($k =~ /^#class\d+$/) {
			my ($c, $b, $p) = @{$parser->{strmap}->{$k}};
			my ($type, $arglist) = @{$parser->{strmap}->{$b}};

			foreach my $a (@$arglist) {
				if ($a =~ /^#fun\d+$/) {
					my $f = $parser->{strmap}->{$a}->[0];
					if (defined $f) {
						my $name = defined $c ? $c : 'class@anonymous';
						my $ctx2 = $ctx->subctx(class_scope => lc($name), infunction => 0);
						$ctx2->registerfun($f, $a);
					}
				}
			}
			if (defined $c) {
				$ctx->registerclass($c, $k);
			}
		}
	}
	return;
}

sub _move_funcs_to_start {
	my ($parser, $stmt) = @_;
	my @funcs = ();
	my @code = ();
	my @block = ();
	
	if (is_block($stmt)) {
		my ($type, $a) = @{$parser->{strmap}{$stmt}};

		foreach my $k (@$a) {
			if (($k =~ /^#stmt\d+$/) && ($parser->{strmap}{$k}[0] eq 'namespace')) {
				push(@block, @funcs);
				push(@block, @code);
				push(@block, $k);
				@funcs = ();
				@code = ();
			} elsif ($k =~ /^#(fun|class)\d+$/) {
				push(@funcs, $k);
			} else {
				push(@code, $k);
			}
		}
		push(@block, @funcs);
		push(@block, @code);
		if (scalar @block == 1) {
			return $block[0];
		}
		my $s = $parser->setblk('flat', [@block]);
		return $s;
	}
	return $stmt;
}

sub parse_eval {
	my ($ctx, $arg) = @_;
	my $parser = $ctx->{parser};

	my $s = $parser->get_strval($arg);
	if (defined $s) {
		$ctx->{log}->($ctx, 'eval', $arg, "%s", $parser->shortstr($s, 400)) if $ctx->{log};

		$parser->{strmap}->{'__FILE__'} = $s if $ctx->{toplevel}; # for fopen('__FILE__')

		# (1) tokenize input file
		#
		my $quote = $parser->tokenize_line($s, $ctx->{quote});
		if (defined $quote) {
			# some lines are cut at the end
			$ctx->{warn}->($ctx, 'eval', $arg, "tokenize bad quote %s, line: [%s]", $quote, $parser->shortstr($s, 200));
		}
		my $tok = $parser->{tok};

		#$ctx->{log}->($ctx, 'eval', $arg, "tokens: %s", $parser->shortstr(join(' ', @$tok), 200)) if $ctx->{log};
		$ctx->{log}->($ctx, 'eval', $arg, "tokens: %s", join(' ', @$tok)) if $ctx->{log};

		# (2) parse tokens to statements
		#
		my $out = $parser->read_code($tok);

		if ($parser->{debug}) {
			my $line = $parser->format_stmt($out, {format => 1});
			$parser->{debug}->('eval', "$arg: parsed line: %s", $line) if $parser->{debug};
		}
		return $out; # empty block if token list is empty
	}
	return;
}

sub exec_eval {
	my ($ctx, $arg) = @_;
	my $parser = $ctx->{parser};

	if (defined $arg) {
		my @funcs = ();
		my @code = ();

		$ctx->{tainted} = 0;

		# rearrange tokens
		#
		my $out = _move_funcs_to_start($parser, $arg);
		if (is_block($out)) {
			my ($type, $a) = @{$parser->{strmap}->{$out}};
			@funcs = @$a;
		} else {
			@funcs = ($out);
		}

		# (3) exec statements
		#
		register_funcs(\@funcs, $ctx, $parser);
		$ctx->{log}->($ctx, 'eval', $arg, "parsed: $out") if $ctx->{log};
		my $in_block = is_block($out) ? 0 : 1;
		my $stmt = $ctx->exec_statement($out, $in_block);

		$ctx->{log}->($ctx, 'eval', $arg, "statement: $stmt") if $ctx->{log};

		# (4) insert remaining assignments at front of block
		#
		$stmt = $ctx->insert_assignments($stmt);

		# (5) flush output buffer
		#
		if ($ctx->{toplevel} && exists $ctx->{varmap}{stdout}) {
			if (exists $ctx->{varmap}{stdout}{handler}) {
				# call handler at the end of the request
				# see: https://www.php.net/manual/en/function.ob-start.php
				#
				my $e = $parser->setcall('ob_end_flush', []);
				my $k = $ctx->exec_statement($e);

				my @seq = ();
				$parser->flatten_block($stmt, \@seq);
				$stmt = $parser->setblk('flat', [@seq, $k]);
			}
		}

		# (6) log stdout
		#
		if ($ctx->{toplevel} && exists $ctx->{varmap}{stdout}) {
			if (@{$ctx->{varmap}{stdout}{buf}}) {
				my @stdout = @{$ctx->{varmap}{stdout}{buf}};
				my $v = '$STDOUT';
				my $k;
				merge_str_list(\@stdout, $parser);
				while (my $s = shift @stdout) {
					if (defined $k) {
						$k = $parser->setexpr('.', $k, $s);
					} else {
						$k = $s;
					}
				}
				unless (exists $ctx->{skip}{stdout}) {
					my $e = $parser->setexpr('=', $v, $k);
					my @seq = ();
					$parser->flatten_block($stmt, \@seq);
					$stmt = $parser->setblk('flat', [@seq, $e]);
				}
			}
		}

		# (7) flatten block if necessary
		#
		if (is_block($stmt)) {
			my ($type, $a) = @{$parser->{strmap}->{$stmt}};
			if ($type ne 'flat') {
				my @seq = ();
				$parser->flatten_block($stmt, \@seq);
				if (scalar @seq > 1) {
					$stmt = $parser->setblk('flat', [@seq]);
				} elsif (scalar @seq > 0) {
					$stmt = $seq[0];
				}
			}
		}
		my $outlist;
		$outlist = join(' ', @{$ctx->{varmap}{stdout}{buf}}) if (exists $ctx->{varmap}{stdout} && scalar @{$ctx->{varmap}{stdout}{buf}});
		$ctx->{log}->($ctx, 'eval', $arg, "got: $stmt%s", defined $outlist ? ' ('.$outlist.')' : '') if $ctx->{log};
		return $stmt;
	} elsif (is_null($arg)) { # might be return from nested eval
		$ctx->{log}->($ctx, 'eval', $arg, "got null") if $ctx->{log};
		return $arg; # stray null statements are removed by flatten_block()
	}
	return;
}

# check if elem without recursive subreferences
#
sub is_flat_elem {
	my ($s, $parser) = @_;
	
	if ($s =~ /^#elem\d+$/) {
		my ($v, $i) = @{$parser->{strmap}->{$s}};
		if (defined $v) {
			if (!is_variable($v)) {
				return 0;
			}
		}
		if (defined $i) {
			if (!is_strval($i)) {
				return 0;
			}
		}
		return 1;
	}
	return 0;
}

# check if elem is anonymous function call, and return it
#
sub _anon_func_call {
	my ($parser, $s) = @_;

	if ($s =~ /^#call\d+$/) {
		my ($f, $a) = @{$parser->{strmap}->{$s}};
		if ($f =~ /^#fun\d+$/) {
			my ($fn, $fa, $fb, $fp) = @{$parser->{strmap}->{$f}};
			if (!defined $fn) {
				return $f;
			}
		}
	}
	return;
}

# check if expression in block contains a local variable
#
sub contains_local_var {
	my ($ctx, $info) = @_;

	foreach my $var (keys %{$info->{vars}}) {
		next if $ctx->is_superglobal($var);
		next if $ctx->is_global_var($var);

		return 1;
	}
	return 0;
}

# if expression in block contains an unresolvable variable, then return it
#
sub unresolvable_var {
	my ($ctx, $info) = @_;

	foreach my $var (keys %{$info->{vars}}) {
		next if $ctx->is_superglobal($var);

		my $val = $ctx->getvar($var, 1);
		if (!defined $val) {
			return $var;
		} elsif ($val eq '#unresolved') {
			return $var;
		}
	}
	return;
}

# if expression in block contains an unresolvable local or instance variable, then return it
#
sub unresolvable_local_var {
	my ($ctx, $info) = @_;

	foreach my $var (keys %{$info->{vars}}) {
		next if $ctx->is_superglobal($var);
		next if $ctx->is_global_var($var);

		my $val = $ctx->getvar($var, 1);
		if (!defined $val) {
			return $var;
		} elsif ($val eq '#unresolved') {
			return $var;
		}
	}
	return;
}

# return new list where consecutive strings are merged
# (keeps constants intact)
#
sub merge_str_list {
	my ($seq, $parser) = @_;
	my @list = ();

	while (my $s = shift @$seq) {
		if (is_strval($s) && !is_const($s)) {
			my $i;
			for ($i=0; $i < scalar @$seq; $i++) {
				last unless (is_strval($seq->[$i]) && !is_const($seq->[$i]));
			}
			if ($i > 0) {
				my @list = ($s, splice(@$seq, 0, $i));
				my $str = join('', map { $parser->{strmap}->{$_} } @list);
				$s = $parser->setstr($str);
			} elsif ($s =~ /^#(const|num)\d+$/) {
				my $str = $parser->{strmap}->{$s};
				$s = $parser->setstr($str);
			} elsif (is_null($s)) {
				$s = $parser->setstr('');
			}
		}
		push(@list, $s);
	}
	@$seq = @list;
	return;
}

# return flat block or single statement
#
sub _flat_block_or_single {
	my ($parser, $seq) = @_;

	if (scalar @$seq == 1) {
		return $seq->[0];
	}
	return $parser->setblk('flat', [@$seq]);
}

# convert flat block or statement to code block
#
sub _to_code_block {
	my ($parser, $s) = @_;

	if (is_block($s)) {
		my ($type, $a) = @{$parser->{strmap}->{$s}};
		if ($type ne 'std') {
			my @seq = ();
			$parser->flatten_block($s, \@seq);
			$s = $parser->setblk('std', [@seq]);
		}
	} else {
		$s = $parser->setblk('std', [$s]);
	}
	return $s;
}

# convert statements to anon function call without parameters
# (if not already anon function)
#
sub _to_anon_func_call {
	my ($parser, $s) = @_;

	unless (_anon_func_call($parser, $s)) {
		$s = _to_code_block($parser, $s);
		my $f = $parser->setfun(undef, [], $s);
		$s = $parser->setcall($f, []);
	}
	return $s;
}

# get first block elem or elem itself 
#
sub _first_statement {
	my ($parser, $s) = @_;

	if (is_block($s)) {
		my ($type, $a) = @{$parser->{strmap}->{$s}};
		if (scalar @$a > 0) {
			return $a->[0];
		}
	}
	return $s;
}

# if the final element of a block is a #stmt matching pattern, then return this #stmt
#
sub _final_break {
	my ($parser, $s, $pattern) = @_;

	if (is_block($s)) {
		my ($type, $a) = @{$parser->{strmap}->{$s}};
		if (scalar @$a > 0) {
			return &_final_break($parser, $a->[-1], $pattern);
		}
	} 
	if ($s =~ /^#stmt\d+$/) {
		my $cmd = $parser->{strmap}->{$s}->[0];
		if ($cmd =~ /^$pattern$/) {
			return $s;
		}
	}
	return;
}

# if the a block contains functions, then return function list
#
sub _contained_functions {
	my ($parser, $s) = @_;

	if (is_block($s)) {
		my ($type, $a) = @{$parser->{strmap}->{$s}};
		my @list = ();
		foreach my $stmt (@$a) {
			my $sublist = &_contained_functions($parser, $stmt);
			if (scalar @$sublist > 0) {
				push(@list, @$sublist);
			}
		}
		return \@list;
	} 
	if ($s =~ /^#fun\d+$/) {
		return [$s];
	}
	return [];
}

# if a block contains calls with resolved params, then return call list
#
sub _contained_resolved_calls {
	my ($parser, $s) = @_;

	if (is_block($s)) {
		my ($type, $a) = @{$parser->{strmap}->{$s}};
		my @list = ();
		foreach my $stmt (@$a) {
			my $sublist = &_contained_resolved_calls($parser, $stmt);
			if (scalar @$sublist > 0) {
				push(@list, @$sublist);
			}
		}
		return \@list;
	} 
	if ($s =~ /^#call\d+$/) {
		my ($name, $args) = @{$parser->{strmap}->{$s}};
		foreach my $p (@$args) {
			unless (is_strval($p) || is_array($p)) {
				return [];
			}
		}
		return [$s];
	}
	return [];
}

sub _get_echo_arglist {
	my ($parser, $s) = @_;

	if ($s =~ /^#stmt\d+$/) {
		my $cmd = $parser->{strmap}->{$s}->[0];
		my $arglist = $parser->{strmap}->{$s}->[1];
		if ($cmd eq 'echo') {
			my $all_str = 1;

			foreach my $p (@$arglist) {
				$all_str = 0 if !is_strval($p);
			}
			return ($arglist, $all_str);
		}
	}
	return;
}

# if a unresolved #stmt or #call matching pattern remains in a function, return this element
#
sub _skipped_call {
	my ($parser, $s, $pattern, $info) = @_;

	foreach my $call (keys %{$info->{calls}}) {
		next if ($info->{calls}{$call}) eq 'return'; # allow skipped call in return?

		my $name = $call;
		if ($name !~ /^(ob_start|exit|die|__halt_compiler)$/i) { # allow skipped exit-like calls
			if ($name !~ /^(error_reporting)$/i) { # allow skipped calls without side effects
				if ($name =~ /^$pattern$/) {
					return $call;
				}
			}
		}
	}
	foreach my $stmt (keys %{$info->{stmts}}) {
		my $cmd = $parser->{strmap}->{$stmt}->[0];
		if ($cmd eq 'echo') {
			# 'echo' is kept inline for non-string argument
			#
			my $arglist = $parser->{strmap}->{$stmt}->[1];
			if ((scalar @$arglist > 1) || !is_strval($arglist->[0])) {
				if ($cmd =~ /^$pattern$/) {
					return $stmt;
				}
			}
		} elsif ($cmd ne 'global') { # 'global $var' is always executed
			if ($cmd =~ /^$pattern$/) {
				return $stmt;
			}
		}
	}
	return;
}

# collect info about unresolved calls and assignments in a function call
# - $info->{unresolved} = names of unresolvable calls and assignments
# - $info->{global_assigns} = global variables with resolved assignments
# - $info->{local_assigns} = local variables with resolved assignments
#
sub get_unresolved_info {
	my ($ctx, $cmd, $stmt) = @_;
	my $parser = $ctx->{parser};

	my $info = {vars => {}, calls => {}, stmts => {}, assigns => {}, noassigns => {}, resolved => {$cmd => 1}, unresolved => {}, global_assigns => {}, local_assigns => {}};
	$parser->stmt_info($stmt, $info);

	foreach my $call (keys %{$info->{calls}}) {
	        my $fun = $ctx->getfun($call);

		$call = lc($call);

		if (defined $fun) {
			my ($name, $a, $b, $p) = @{$parser->{strmap}->{$fun}};

			# check if function was already visited
			#
			if (!exists $info->{resolved}{$call}) {
				my $subinfo = $ctx->get_unresolved_info($call, $b);

				$info->{global_assigns} = {%{$info->{global_assigns}}, %{$subinfo->{global_assigns}}};
				$info->{unresolved} = {%{$info->{unresolved}}, %{$subinfo->{unresolved}}};
				$info->{resolved} = {%{$info->{resolved}}, %{$subinfo->{resolved}}};
				$info->{resolved}{$call} = 1;
			}
		} elsif (my $f = PHP::Decode::Func::get_php_func($call)) {
			if (PHP::Decode::Func::func_may_call_callbacks($call)) {
				my $skip = 0;
				if ($call eq 'array_filter') {
					my @list = keys %{$info->{callargs}{$call}};
					if ((scalar @list == 1) && ($list[0] eq '1')) {
						# one-arg array_filter has no callable
						$ctx->{log}->($ctx, 'exec', $stmt, "get_unresolved_info $cmd: skip 1-arg $call") if $ctx->{log};
						$skip = 1;
					}
				}
				unless ($skip) {
					$info->{unresolved}{$call} = 1;
				}
			}
			# func without side-effects on vars here
		} else {
			$info->{unresolved}{$call} = 1;
		}
	}
	foreach my $var (keys %{$info->{assigns}}) {
		if ($var =~ /^#elem\d+$/) {
			my $elemlist = _get_elemlist($parser, $var);
			my ($v, $i) = @{$parser->{strmap}->{$elemlist->[0]}};

			my $g = $parser->globalvar_to_var($v, $i);
			if (defined $g) {
				$info->{global_assigns}{$g} = 1;
			} elsif ($ctx->is_superglobal($v)) {
				$info->{global_assigns}{$var} = 1;
			} elsif (is_variable($v)) {
				my ($g) = global_split($v);
				if (defined $g) {
					# access on global array-var
					$info->{global_assigns}{$g} = 1;
				} else {
					$info->{local_assigns}{$v} = 1;
				}
			} else {
				$info->{unresolved}{$var} = 1;
			}
		} elsif (is_variable($var)) {
			my ($g) = global_split($var);
			if (defined $g) {
				$info->{global_assigns}{$g} = 1;
				next;
			}
			if ($ctx->is_superglobal($var)) {
				$info->{global_assigns}{$var} = 1;
				next;
			}
			$info->{local_assigns}{$var} = 1;
		} elsif ($var =~ /^#obj\d+$/) {
			$info->{local_assigns}{$var} = 1;
		} else {
			$info->{unresolved}{$var} = 1;
		}
	}
	return $info;
}

# if a function returns just a single #call with same signature, then return this #call
#
sub _is_wrapped_call {
	my ($parser, $s) = @_;

	unless ($s =~ /^#fun\d+$/) {
		return;
	}
	my ($f, $a, $b, $p) = @{$parser->{strmap}->{$s}};
	$s = $parser->flatten_block_if_single($b);

	if ($s =~ /^#stmt\d+$/) {
		my $cmd = $parser->{strmap}->{$s}->[0];
		if (lc($cmd) eq 'return') {
			my $val = $parser->{strmap}->{$s}->[1];
			if ($val =~ /^#call\d+$/) {
				my ($name, $arglist) = @{$parser->{strmap}->{$val}};

				# eval might create local vars
				if (is_symbol($name) && (lc($name) ne 'eval') && (scalar @$arglist == scalar @$a)) {
					my $i = 0;
					my $arg_match = 1;
					foreach my $k (@$arglist) {
						if ($k ne $a->[$i]) {
							$arg_match = 0;
						}
						$i++;
					}
					if ($arg_match) {
						return $name;
					}
				}
			}
		}
	}
	return;
}

# check if a variable should be marked as #unresolved based on right-hand-side of assignment
#
sub is_unresolved_assignment {
	my ($ctx, $rhs) = @_;
	my $parser = $ctx->{parser};

	if ($rhs =~ /^#expr\d+$/) {
		my ($op, $v1, $v2) = @{$parser->{strmap}->{$rhs}};

		if (($op eq '=') && defined $v2) {
			# check for: $a = $b = 1;
			return $ctx->is_unresolved_assignment($v2);
		}

		# expressions should already have been resolved
		# (such assignments would lead to recursions like $a = expr:[$a + 1])
		#
		return 1;
	}
	my $info = {vars => {}, calls => {}, stmts => {}};
	$parser->stmt_info($rhs, $info);

	if (my $c = _skipped_call($parser, $rhs, '(.*)', $info)) {
		# never replace content when the rhs contains
		# an unresolved #call
		#
		return 1;
	} elsif (!is_variable($rhs) && !is_flat_elem($rhs, $parser) && $ctx->unresolvable_var($info)) {
		# don't replace content when the rhs contains
		# a unresolved variable.
		# Make an exception for single variables and simple #elems.
		# 
		return 1;
	} elsif (is_variable($rhs)) {
		# forward unresolved state to lhs
		#
		my $val = $ctx->getvar($rhs, 1);
		if (defined $val && ($val eq '#unresolved')) {
			return 1;
		}
	}
	return 0;
}

# check if this is pre/post increment expr
#
sub _is_increment_op {
	my ($parser, $stmt) = @_;

	if ($stmt =~ /^#expr\d+$/) {
		my ($op, $v1, $v2) = @{$parser->{strmap}->{$stmt}};
		return ($op eq '++') || ($op eq '--');
	}
	return;
}

# return varable if statement is assignment
#
sub _var_assignment {
	my ($parser, $stmt) = @_;

	if ($stmt =~ /^#expr\d+$/) {
		my ($op, $v1, $v2) = @{$parser->{strmap}->{$stmt}};

		if (($op eq '=') && defined $v2) {
			return ($v1, $v2);
		}
	}
	return;
}

sub get_indexed_array_var {
	my ($ctx, $var) = @_;
	my $parser = $ctx->{parser};

	if ($var =~ /^#elem\d+$/) {
		my ($v, $i) = @{$parser->{strmap}->{$var}};

		my $val = $ctx->getvar($v, 1);
		if (defined $val && is_array($val)) {
			return ($v, $val);
		}
	}
	return;
}

# optimize loop variable assignments
# 1) add block of new instructions from last loop iteration
# 2) merge assignments to same variable or echo-statements
#    (just for strval/array values).
#
sub optimize_loop_var_list {
	my ($ctx, $type, $stmt, $list, $res) = @_;
	my $parser = $ctx->{parser};
	my $changed = 0;

ELEM:	for (my $i = 0; $i < scalar @$res; $i++) {
		my $elem = $res->[$i];

		# merge previous array assignment with new one
		#
		my ($v, $lhs) = _var_assignment($parser, $elem);
		if (defined $v) {
			# optimize only trailing var assignments to strval or array
			#
			for (my $j = scalar @$list; $j > 0; $j--) {
				my $prev = $list->[$j-1];
				my ($vp, $lhsp) = _var_assignment($parser, $prev);
				if (!defined $vp) {
					if (is_strval($prev) || is_array($prev)) {
						next; # allow plain values as statement
					} elsif (!_get_echo_arglist($parser, $prev)) {
						push(@$list, $elem);
						next ELEM; # other statements than echo or assign
					} else {
						next;
					}
				}
				#$ctx->{log}->($ctx, $type, $stmt, "optimize loop: $v: $prev $vp $lhsp") if $ctx->{log};
				unless (is_strval($lhsp) || is_array($lhsp)) {
					push(@$list, $elem);
					next ELEM; # unresolved assignment
				}
				# substitute: multiple var assignment -> single assigment
				#
				if (is_variable($v) && ($v eq $vp)) {
					$ctx->{log}->($ctx, $type, $stmt, "optimize loop: $v [$prev -> $elem]") if $ctx->{log};
					splice(@$list, $j-1, 1); # remove $prev from list
					$changed = 1;
					push(@$list, $elem);
					next ELEM;
				}

				# substitute: multiple array assignment -> single assigment
				#
				my ($va, $a) = $ctx->get_indexed_array_var($v);
				if (defined $va) {
					if ($va eq $vp) {
						my $k = $parser->setexpr('=', $va, $a);
						$ctx->{log}->($ctx, $type, $stmt, "optimize loop: $v ($va $a) [$prev, $elem -> $k]") if $ctx->{log};
						splice(@$list, $j-1, 1); # remove $prev from list
						$res->[$i] = $k;
						$changed = 1;
						push(@$list, $k);
						next ELEM;
					}
				}
			}
			# if no variable was found, then substitute new single array elem assigment -> array assignmet
			#
			my ($va, $a) = $ctx->get_indexed_array_var($v);
			if (defined $va) {
				my $arr = $parser->{strmap}{$a};
				my $keys = $arr->get_keys();
				my $size = scalar @$keys;

				# also allow assignment to existing array ($size > 1)
				#
				if ($size > 1) {
					$ctx->{log}->($ctx, $type, $stmt, "optimize loop: initial $va already has elements") if $ctx->{log};
				}
				my $k = $parser->setexpr('=', $va, $a);
				$ctx->{log}->($ctx, $type, $stmt, "optimize loop: initial $va ($a size=$size) [$elem -> $k]") if $ctx->{log};
				$res->[$i] = $k;
				$changed = 1;
				push(@$list, $k);
				next ELEM;
			}
		}

		# merge previous echo statement with new one
		#
		my ($args, $all_str) = _get_echo_arglist($parser, $elem);
		if (defined $args) {
			for (my $j = scalar @$list; $j > 0; $j--) {
				my $prev = $list->[$j-1];
				my ($prev_args, $prev_all_str) = _get_echo_arglist($parser, $prev);

				if (!defined $prev_args) {
					next;
				}
				my $k;
				if ($all_str && $prev_all_str) {
					my $val = join('', map { $parser->{strmap}->{$_} } (@$prev_args, @$args));
					my $str = $parser->setstr($val);
					$k = $parser->setstmt(['echo', [$str]]);
				} else {
					$k = $parser->setstmt(['echo', [@$prev_args, @$args]]);
				}
				$ctx->{log}->($ctx, $type, $stmt, "optimize loop: echo [$prev, $elem -> $k]") if $ctx->{log};
				splice(@$list, $j-1, 1); # remove $prev from list
				$res->[$i] = $k;
				$changed = 1;
				push(@$list, $k);
				next ELEM;
			}
		}
		push(@$list, $elem);
	}
	return $changed;
}

sub set_tainted {
	my ($ctx, $stmt) = @_;

	if ($ctx->{tainted}) {
		$ctx->{warn}->($ctx, 'taint', $stmt, "set ctx tainted");
	} else {
		$ctx->{warn}->($ctx, 'taint', $stmt, "set ctx tainted (untainted before)");
	}
	if (exists $ctx->{with}{invalidate_tainted_vars}) {
		foreach my $k (keys %{$ctx->{globals}}) {
			if (is_variable($k) && !$ctx->is_superglobal($k)) {
				$ctx->{globals}{$k} = '#unresolved';
			}
		}
		foreach my $k (keys %{$ctx->{varmap}{global}}) {
			if (is_variable($k) && !$ctx->is_superglobal($k)) {
				$ctx->{globals}{$k} = '#unresolved';
			}
		}
	}
	$ctx->{tainted} += 1;
	return;
}

sub set_globals_unresolved {
	my ($ctx, $list) = @_;

	foreach my $k (@$list) {
		if (is_variable($k) && !$ctx->is_superglobal($k)) {
			if (!exists $ctx->{globals}{$k} || ($ctx->{globals}{$k} ne '#unresolved')) {
				$ctx->{log}->($ctx, 'set_unresolved', $k, "(global)") if $ctx->{log};
				$ctx->{globals}{$k} = '#unresolved';
			}
		}
	}
	return;
}

sub set_locals_unresolved {
	my ($ctx, $list) = @_;

	foreach my $k (@$list) {
		if (is_variable($k) && !$ctx->is_superglobal($k)) {
			if (!exists $ctx->{varmap}{$k} || ($ctx->{varmap}{$k} ne '#unresolved')) {
				$ctx->{log}->($ctx, 'set_unresolved', $k, "(local)") if $ctx->{log};
				$ctx->{varmap}{$k} = '#unresolved';
			}
		}
	}
	return;
}

sub set_undefined_globals_unresolved {
	my ($ctx, $list) = @_;

	foreach my $k (@$list) {
		if (is_variable($k) && !$ctx->is_superglobal($k)) {
			if (!exists $ctx->{globals}{$k}) {
				$ctx->{log}->($ctx, 'set_unresolved', $k, "(undefined global)") if $ctx->{log};
				$ctx->{globals}{$k} = '#unresolved';
			}
		}
	}
	return;
}

sub set_undefined_locals_unresolved {
	my ($ctx, $list) = @_;

	foreach my $k (@$list) {
		if (is_variable($k) && !$ctx->is_superglobal($k)) {
			if (!exists $ctx->{varmap}{$k}) {
				if (exists $ctx->{varmap}{global}{$k}) {
					if (!exists $ctx->{globals}{$k}) {
						$ctx->{log}->($ctx, 'set_unresolved', $k, "(undefined local global)") if $ctx->{log};
						$ctx->{globals}{$k} = '#unresolved';
					}
				} else {
					$ctx->{log}->($ctx, 'set_unresolved', $k, "(undefined local)") if $ctx->{log};
					$ctx->{varmap}{$k} = '#unresolved';
				}
			}
		}
	}
	return;
}

# invalidate all undefined variables so that they do not resolve to '#null'.
#
sub invalidate_undefined_vars {
	my ($ctx, $info, $type, $stmt) = @_;

	if (keys %{$info->{globals}}) {
		$ctx->{warn}->($ctx, $type, $stmt, "unresolve - found globals[%s]", join(' ', keys %{$info->{globals}}));
		$ctx->set_undefined_globals_unresolved([keys %{$info->{globals}}]);
	}
	if (keys %{$info->{vars}}) {
		my @vars = grep { !exists $info->{globals}{$_} && !exists $info->{unresolved}{$_} } keys %{$info->{vars}};
		if (@vars) {
			$ctx->{warn}->($ctx, $type, $stmt, "unresolve - found locals[%s]", join(' ', @vars));
			$ctx->set_undefined_locals_unresolved(\@vars);
		}
	}
	return;
}

# invalidate all variables with dependencies on subsequent calls of same block.
#
sub invalidate_vars {
	my ($ctx, $info, $type, $stmt) = @_;

	if (keys %{$info->{global_assigns}}) {
		$ctx->{warn}->($ctx, $type, $stmt, "unresolve - found global assigns[%s]", join(' ', keys %{$info->{global_assigns}}));
		$ctx->set_globals_unresolved([keys %{$info->{global_assigns}}]);
	}
	if (keys %{$info->{local_assigns}}) {
		$ctx->{warn}->($ctx, $type, $stmt, "unresolve - found local assigns[%s]", join(' ', keys %{$info->{local_assigns}}));
		$ctx->set_locals_unresolved([keys %{$info->{local_assigns}}]);
	}
	if (keys %{$info->{unresolved}}) {
		$ctx->{warn}->($ctx, $type, $stmt, "unresolve - found unresolved[%s]", join(' ', keys %{$info->{unresolved}}));

		# TODO: is this necessary with set_tainted()?
		#
		if (keys %{$info->{globals}}) {
			$ctx->{warn}->($ctx, $type, $stmt, "unresolve - found globals[%s]", join(' ', keys %{$info->{globals}}));
			$ctx->set_globals_unresolved([keys %{$info->{globals}}]);
		}
		if (keys %{$info->{vars}}) {
			my @vars = grep { !exists $info->{globals}{$_} && !exists $info->{unresolved}{$_} } keys %{$info->{vars}};
			if (@vars) {
				$ctx->{warn}->($ctx, $type, $stmt, "unresolve - found locals[%s]", join(' ', @vars));
				$ctx->set_locals_unresolved(\@vars);
			}
		}
	}
	return;
}

sub update_unresolved {
	my ($ctx, $ctx2) = @_;

	# copy unresolved status from ctx2 to ctx
	#
	foreach my $k (keys %{$ctx2->{globals}}) {
		if (is_variable($k) && !$ctx2->is_superglobal($k)) {
			if (!exists $ctx->{globals}{$k} || ($ctx->{globals}{$k} ne $ctx2->{globals}{$k})) {
				$ctx->{log}->($ctx, 'set_unresolved', $k, "(global) update from clone") if $ctx->{log};
				$ctx->{globals}{$k} = '#unresolved';
			}
		}
	}
	foreach my $k (keys %{$ctx2->{varmap}}) {
		if (is_variable($k) && !$ctx2->is_superglobal($k)) {
			if (!exists $ctx->{varmap}{$k} || ($ctx->{varmap}{$k} ne $ctx2->{varmap}{$k})) {
				$ctx->{log}->($ctx, 'set_unresolved', $k, "(local) update from clone") if $ctx->{log};
				$ctx->{varmap}{$k} = '#unresolved';
			}
		}
	}
	return;
}

sub is_superglobal {
	my ($ctx, $var) = @_;

	return exists $ctx->{superglobal}{$var};
}

# check if variable is global in current context
#
sub is_global_var {
	my ($ctx, $var) = @_;
	my ($g) = global_split($var);
	if (defined $g) {
		return $g; # converted $GLOBALS['var']
	}
	if (exists $ctx->{varmap}{global}{$var}) {
		return $var; # 'global $var;'
	}
	unless ($ctx->{infunction}) {
		return $var; # outside of func all vars are global
	}
	return;
}

# check if variable is instance var
#
sub is_instvar {
	my ($var) = @_;
	my ($inst, $instvar) = inst_split($var);
	if (defined $inst) {
		return ($inst =~ /^#inst\d+$/);
	}
	return 0;
}

sub is_inst_or_classvar {
	my ($var) = @_;
	my ($inst, $instvar) = inst_split($var);
	if (defined $inst) {
		return 1;
	}
	return 0;
}

sub setvar {
	my ($ctx, $var, $val, $in_block) = @_;
	my $wasset = 0;

	# set class vars when classes are initialized
	#
	if (!$ctx->{infunction} && $ctx->{class_scope}) {
		my ($inst, $instvar) = inst_split($var);
		if (!defined $inst || ($inst ne 'GLOBALS')) {
			$var = inst_var($ctx->{class_scope}, $var);
		}
	}
	my ($global) = global_split($var);
	my ($inst, $instvar) = inst_split($var);
	$inst = lc($inst) if defined $inst;

	if ($ctx->is_superglobal($var)) {
		$global = $var;
	}
	if (defined $global) {
		if (exists $ctx->{globals}) {
			$ctx->{globals}{$global} = $val;
			$wasset = 1;
		}
	} elsif (exists $ctx->{varmap}{global}{$var}) {
		if (exists $ctx->{globals}) {
			$ctx->{globals}{$var} = $val;
			$var = global_var($var);
			$wasset = 1;
		}
	} elsif (exists $ctx->{varmap}{ref}{$var}) {
		my ($ctx2, $var1) = @{$ctx->{varmap}{ref}{$var}};
		$ctx2->setvar($var1, $val, $in_block);
	} elsif (exists $ctx->{varmap}{static}{$ctx->{infunction}}{$var}) {
		if ($ctx->{infunction} && $ctx->{incall}) {
			$ctx->{varmap}{static}{$ctx->{infunction}}{$var} = $val;
			$wasset = 1;
		} else {
			$ctx->{warn}->($ctx, 'setvar', $var, "static not in call");
		}
	} elsif (defined $inst && exists $ctx->{varmap}{inst}{$inst}) {
		$ctx->{varmap}{inst}{$inst}{$instvar} = $val;
		$wasset = 1;
	} else {
		$ctx->{varmap}{$var} = $val;
		$wasset = 1;
	}
	if ($wasset) {
		if (!$in_block) {
			$ctx->{log}->($ctx, 'setvar', $var, "= $val [TRACK]") if $ctx->{log};
			$ctx->track_assignment($var, $val);
		} else {
			$ctx->{log}->($ctx, 'setvar', $var, "= $val") if $ctx->{log};
		}
	}
	return;
}

sub add_namespace {
	my ($ctx, $name) = @_;

	if ($name =~ /^\\(.*)$/) {
		$name = $1; # remove absolute
	} elsif ($ctx->{namespace}) {
		$name = ns_name(lc($ctx->{namespace}), $name); # relative
	}
	return $name;
}

# function and class names are case-insensitive
# https://www.php.net/manual/en/functions.user-defined.php
#
sub registerfun {
	my ($ctx, $name, $f) = @_;

	# functions are always global, but locally defined functions
	# are temporarily registered in the local varmap if a function
	# is simplified (see: subglobctx).
	#
	if (exists $ctx->{class_scope}) {
		$name = method_name($ctx->{class_scope}, lc($name));
	} else {
		$name = lc($name); # functions are not case-sensitive
	}
	if ($ctx->{namespace}) {
		$name = ns_name(lc($ctx->{namespace}), $name);
	}
	if ($ctx->{infunction}) {
		$ctx->{varmap}{fun}{$name} = $f;
	} else {
		$ctx->{globals}{fun}{$name} = $f;
	}
	$ctx->{log}->($ctx, 'registerfun', $name, "$f") if $ctx->{log};
	return;
}

# lookup method name by instance name
#
sub lookup_method_name {
	my ($ctx, $name) = @_;

	$name = lc($name); # functions are not case-sensitive

	my ($inst, $prop) = method_split($name);

	if (defined $inst) {
		if (exists $ctx->{varmap}{inst}{$inst} && exists $ctx->{varmap}{inst}{$inst}{$prop}) {
			my $method = $ctx->{varmap}{inst}{$inst}{$prop}; # lookup instance function
			return $method;
		}
	}
	return;
}

sub getfun {
	my ($ctx, $name) = @_;

	$name = lc($name); # functions are not case-sensitive

	if (my $method = $ctx->lookup_method_name($name)) {
		$name = $method;
	} elsif (exists $ctx->{class_scope}) {
		my $method = lc(method_name($ctx->{class_scope}, $name));
		if (exists $ctx->{globals}{fun}{$method}) {
			return $ctx->{globals}{fun}{$method};
		} elsif (exists $ctx->{varmap}{fun}{$method}) {
			return $ctx->{varmap}{fun}{$method};
		}
	}
	if (exists $ctx->{globals}{fun}{$name}) {
		return $ctx->{globals}{fun}{$name};
	} elsif (exists $ctx->{varmap}{fun}{$name}) {
		return $ctx->{varmap}{fun}{$name};
	}
	return;
}

sub registerclass {
	my ($ctx, $name, $c) = @_;

	$name = lc($name);

	if ($ctx->{namespace}) {
		$name = ns_name(lc($ctx->{namespace}), $name);
	}
	if ($ctx->{infunction}) {
		$ctx->{varmap}{class}{$name} = $c;
	} else {
		$ctx->{globals}{class}{$name} = $c;
	}
	$ctx->{log}->($ctx, 'registerclass', $name, "$c") if $ctx->{log};
	return;
}

sub getclass {
	my ($ctx, $name) = @_;

	$name = lc($name);

	if (exists $ctx->{globals}{class}{$name}) {
		return $ctx->{globals}{class}{$name};
	} elsif (exists $ctx->{varmap}{class}{$name}) {
		return $ctx->{varmap}{class}{$name};
	}
	return;
}

sub getvar {
	my ($ctx, $var, $quiet) = @_;

	# variable names are case sensitive
	#
	my ($global) = global_split($var);
	my ($inst, $instvar) = inst_split($var);
	$inst = lc($inst) if defined $inst;

	if ($ctx->is_superglobal($var)) {
		$global = $var;
	}
	if (defined $global) {
		if (exists $ctx->{globals}) {
			if (exists $ctx->{globals}{$global}) {
				my $val = $ctx->{globals}{$global};
				return $val;
			}
			if (!$ctx->is_superglobal($var)) {
				if ($ctx->{incall} || !(exists $ctx->{skip}{null})) {
					unless ($ctx->{tainted}) {
						$ctx->{warn}->($ctx, 'getvar', $var, "global not found -> #null") unless $quiet;
						return '#null';
					}
				}
			}
			$ctx->{warn}->($ctx, 'getvar', $var, "global not found") unless $quiet;
		}
	} elsif (exists $ctx->{varmap}{global}{$var}) {
		if (exists $ctx->{globals}) {
			if (exists $ctx->{globals}{$var}) {
				my $val = $ctx->{globals}{$var};
				return $val;
			}
			$ctx->{warn}->($ctx, 'getvar', $var, "global not found") unless $quiet;
		}
	} elsif (exists $ctx->{varmap}{ref}{$var}) {
		my ($ctx2, $var1) = @{$ctx->{varmap}{ref}{$var}};
		return $ctx2->getvar($var1, $quiet);
	} elsif (exists $ctx->{varmap}{static}{$ctx->{infunction}}{$var}) {
		if ($ctx->{infunction} && $ctx->{incall}) {
			my $val = $ctx->{varmap}{static}{$ctx->{infunction}}{$var};
			if (!defined $val) {
				return '#null';
			}
			return $val;
		}
		$ctx->{warn}->($ctx, 'getvar', $var, "static not in call") unless $quiet;
	} elsif (defined $inst && exists $ctx->{varmap}{inst}{$inst}) {
		if (exists $ctx->{varmap}{inst}{$inst}{$instvar}) {
			my $val = $ctx->{varmap}{inst}{$inst}{$instvar};
			if (!defined $val) {
				return '#null';
			}
			return $val;
		} elsif (exists $ctx->{class_scope} && $ctx->{varmap}{inst}{$ctx->{class_scope}}{$instvar}) {
			$ctx->{log}->($ctx, 'getvar', $var, "class $ctx->{class_scope}") if $ctx->{log};
			my $val = $ctx->{varmap}{inst}{$ctx->{class_scope}}{$instvar};
			if (!defined $val) {
				return '#null';
			}
			return $val;
		}
		if ($ctx->{incall} || !(exists $ctx->{skip}{null})) {
			if (!$ctx->{tainted}) {
				$ctx->{warn}->($ctx, 'getvar', $var, "instvar $instvar not found -> #null") unless $quiet;
				return '#null';
			}
		}
		$ctx->{warn}->($ctx, 'getvar', $var, "instvar $instvar not found") unless $quiet;
	} elsif (exists $ctx->{varmap}{$var}) {
		my $val = $ctx->{varmap}{$var};
		return $val;
	} else {
		# if the program is executed and the variable ist not a superglobal,
		# then the default val for undefined vars is null:
		# https://php.net/manual/en/language.types.null.php
		#
		# - with E_NOTICE php warn 'Undefined Variable'
		# - in arithmetic operations an undefined var is 0
		#
		if ($ctx->{incall} || !(exists $ctx->{skip}{null})) {
			if (!$ctx->{tainted}) {
				$ctx->{warn}->($ctx, 'getvar', $var, "not found -> #null") unless $quiet;
				return '#null';
			}
		}
		$ctx->{warn}->($ctx, 'getvar', $var, "not found") unless $quiet;
	}
	return;
}

# remove local variable assignments from block if variable is otherwise unused
#
sub eliminate_local_assigments {
	my ($ctx, $info, $code) = @_;
	my $parser = $ctx->{parser};

	$info->{remaining_locals} = {} unless exists $info->{remaining_locals};
	$info->{remaining_statics} = {} unless exists $info->{remaining_statics};

	my $out = $parser->map_stmt($code, sub {
		my ($s) = @_;

		if ($s =~ /^#expr\d+$/) {
			# $var = <val>
			my ($op, $v1, $v2) = @{$parser->{strmap}->{$s}};
			if (($op eq '=') && is_variable($v1)) {
				my ($inst, $instvar) = inst_split($v1);

				# note: class functions are inititialized without {inst}-map,
				#       so don't check for class-var existence here.
				#
				if ($ctx->is_superglobal($v1)) {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment: keep superglobal $v1") if $ctx->{log};
				} elsif (exists $ctx->{varmap}{ref}{$v1}) {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment: keep ref var $v1") if $ctx->{log};
					$info->{remaining_locals}{$v1} = 1; # XXX
				} elsif (exists $ctx->{varmap}{global}{$v1}) {
					my $vv1 = global_var($v1); # convert to explicit global
					my $vv2 = $ctx->eliminate_local_assigments($info, $v2);
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment: convert global var $v1=$v2 -> $vv1=$vv2") if $ctx->{log};
					$info->{global_assigns}{$v1} = 1;
					my $k = $parser->setexpr('=', $vv1, $vv2);
					return $k;
				} elsif (defined $inst && ($inst eq 'GLOBALS')) {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment: keep global var $v1") if $ctx->{log};
				} elsif ($ctx->{infunction} && exists $ctx->{varmap}{static}{$ctx->{infunction}}{$v1}) {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment: keep static func var $v1") if $ctx->{log};
					$info->{remaining_statics}{$v1} = 1;
				} elsif (defined $inst && exists $ctx->{class_scope} && (lc($inst) eq $ctx->{class_scope})) {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment: keep static class var $v1") if $ctx->{log};
					$info->{remaining_statics}{$v1} = 1;
					delete $info->{local_assigns}{$v1};
				} elsif (exists $info->{local_assigns}{$v1}) {
					if (exists $info->{noassigns}{$v1}) {
						$ctx->{log}->($ctx, 'eliminate', $code, "assignment $s: remaining local var $v1") if $ctx->{log};
						$info->{remaining_locals}{$v1} = 1;
					} elsif (is_strval($v2)) {
						$ctx->{log}->($ctx, 'eliminate', $code, "assignment $s: local var $v1=$v2 -> []") if $ctx->{log};
						my $empty = $parser->setblk('flat', []);
						return $empty;
					} elsif (is_array($v2) && PHP::Decode::Op::array_is_const($parser, $v2)) {
						$ctx->{log}->($ctx, 'eliminate', $code, "assignment $s: local var $v1=$v2 -> []") if $ctx->{log};
						my $empty = $parser->setblk('flat', []);
						return $empty;
					} elsif (is_variable($v2)) {
						$ctx->{log}->($ctx, 'eliminate', $code, "assignment $s: local var $v1=$v2 -> []") if $ctx->{log};
						my $empty = $parser->setblk('flat', []);
						return $empty;
					} else {
						my $vv2 = $ctx->eliminate_local_assigments($info, $v2);
						$ctx->{log}->($ctx, 'eliminate', $code, "assignment $s: local var $v1=$v2 -> $vv2") if $ctx->{log};
						return $vv2;
					}
				} else {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment $s: remaining unknown var $v1") if $ctx->{log};
					$info->{remaining_locals}{$v1} = 1;
				}
			} elsif (($op eq '=') && ($v1 =~ /^#elem\d+$/)) {
				my $elemlist = _get_elemlist($parser, $v1);
				my ($v, $i) = @{$parser->{strmap}->{$elemlist->[0]}};
				if ($v =~ /^\$GLOBALS$/) {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment: keep global elem $v1") if $ctx->{log};
				} elsif ($ctx->is_superglobal($v)) {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment: keep superglobal elem $v1") if $ctx->{log};
				} elsif (exists $info->{noassigns}{$v}) {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment $s: remaining local elem $v1") if $ctx->{log};
					$info->{remaining_locals}{$v} = 1;
				} elsif (is_variable($v)) {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment $s: local elem $v1=$v2 -> []") if $ctx->{log};
					my $empty = $parser->setblk('flat', []);
					return $empty;
				} else {
					$ctx->{log}->($ctx, 'eliminate', $code, "assignment $s: remaining unknown elem $v1") if $ctx->{log};
					$info->{remaining_locals}{$v} = 1;
				}
			}
		} elsif ($s =~ /^#obj\d+$/) {
			my ($o, $m) = @{$parser->{strmap}->{$s}};
			if (lc($o) eq '$this') {
				$info->{remaining_statics}{$s} = 1; # XXX
			} else {
				$info->{remaining_locals}{$s} = 1;
			}
			$ctx->{log}->($ctx, 'eliminate', $code, "keep obj $s") if $ctx->{log};
		} elsif ($s =~ /^#stmt\d+$/) {
			my $cmd = $parser->{strmap}->{$s}->[0];
			if ($cmd eq 'static') {
				my $arglist = $parser->{strmap}->{$s}->[1];
				foreach my $v (@$arglist) {
					if ($v =~ /^#expr\d+$/) {
						$ctx->{log}->($ctx, 'eliminate', $code, "$v from static assignment $s") if $ctx->{log};
					} else {
						$ctx->{log}->($ctx, 'eliminate', $code, "$v from static definition $s") if $ctx->{log};
					}
				}
				my $empty = $parser->setblk('flat', []);
				return $empty;
			} elsif ($cmd eq 'global') {
				my $arglist = $parser->{strmap}->{$s}->[1];
				return $s; # keep variables in global statement as is
			}
		} elsif (is_variable($s)) {
			my ($inst, $instvar) = inst_split($s);

			if ($ctx->is_superglobal($s)) {
				$ctx->{log}->($ctx, 'eliminate', $code, "keep superglobal $s") if $ctx->{log};
			} elsif (exists $ctx->{varmap}{ref}{$s}) {
				$ctx->{log}->($ctx, 'eliminate', $code, "keep ref var $s") if $ctx->{log};
				$info->{remaining_locals}{$s} = 1; # XXX
			} elsif (exists $ctx->{varmap}{global}{$s}) {
				my $v = global_var($s); # convert to explicit global
				$ctx->{log}->($ctx, 'eliminate', $code, "convert global var $s -> $v") if $ctx->{log};
				return $v;
			} elsif (defined $inst && ($inst eq 'GLOBALS')) {
				$ctx->{log}->($ctx, 'eliminate', $code, "keep global var $s") if $ctx->{log};
			} elsif ($ctx->{infunction} && exists $ctx->{varmap}{static}{$ctx->{infunction}}{$s}) {
				$ctx->{log}->($ctx, 'eliminate', $code, "is static func var $s") if $ctx->{log};
				$info->{remaining_statics}{$s} = 1;
			} elsif (defined $inst && exists $ctx->{class_scope} && (lc($inst) eq $ctx->{class_scope})) {
				$ctx->{log}->($ctx, 'eliminate', $code, "keep static class var $s") if $ctx->{log};
				$info->{remaining_statics}{$s} = 1;
			} elsif (exists $info->{vars}{$s}) {
				if (lc($s) eq '$this') {
					$ctx->{log}->($ctx, 'eliminate', $code, "remaining local static var $s") if $ctx->{log};
					$info->{remaining_statics}{$s} = 1;
				} else {
					$ctx->{log}->($ctx, 'eliminate', $code, "remaining local var $s") if $ctx->{log};
					$info->{remaining_locals}{$s} = 1;
				}
			} else {
				$ctx->{log}->($ctx, 'eliminate', $code, "remaining unknown var $s") if $ctx->{log};
				$info->{remaining_locals}{$s} = 1;
			}
		}
		return;
	});

	if ($out ne $code) {
		$ctx->{log}->($ctx, 'eliminate', $code, "changed -> $out") if $ctx->{log};
	}
	return $out;
}

# convert assignment followed directly by return to single return
#
sub convert_assign_return {
	my ($ctx, $code) = @_;
	my $parser = $ctx->{parser};

	my $out = $parser->map_stmt($code, sub {
		my ($s) = @_;

		if ($s =~ /^#blk\d+$/) {
			my ($type, $a) = @{$parser->{strmap}->{$s}};
			my @args = ();
			my $arg_changed = 0;

			for (my $i=0; $i < scalar @$a; $i++) {
				my $k = $a->[$i];
				if (($i+1) < scalar @$a) {
					my $k2 = $a->[$i+1];
					my $var;
					if ($k2 =~ /^#stmt\d+$/) {
						my $cmd2 = $parser->{strmap}->{$k2}->[0];
						if ($cmd2 eq 'return') {
							$var = $parser->{strmap}->{$k2}->[1];
						}
					}
					if (defined $var && ($k =~ /^#expr\d+$/)) {
						my ($op, $v1, $v2) = @{$parser->{strmap}->{$k}};
						if (($op eq '=') && ($var eq $v1)) {
							my $r = $parser->setstmt(['return', $v2]);
							$ctx->{log}->($ctx, 'convert', $code, "assign_return $k+$k2 -> $r") if $ctx->{log};
							push(@args, $r);
							$arg_changed = 1;
							$i++;
							next;
						}
					}
				}
				my $v = $ctx->convert_assign_return($k);
				if ($v ne $k) {
					unless ($parser->is_empty_block($v)) {
						push(@args, $v);
					}
					$arg_changed = 1;
				} else {
					push(@args, $v);
				}
			}
			if ($arg_changed) {
				$s = $parser->setblk($type, \@args);
				return $s;
			}
		}
		return;
	});

	if ($out ne $code) {
		$ctx->{log}->($ctx, 'convert', $code, "assign_return changed -> $out") if $ctx->{log};
	}
	return $out;
}

# convert globals so that they match toplevel or another function
#
sub convert_globals_to_caller_ctx {
	my ($ctx, $info, $code, $cctx) = @_;
	my $parser = $ctx->{parser};

	unless (scalar keys %{$info->{global_assigns}} > 0) {
		return $code; # no global exists
	}

	my $out = $parser->map_stmt($code, sub {
		my ($s) = @_;

		if ($s =~ /^#stmt\d+$/) {
			my $cmd = $parser->{strmap}->{$s}->[0];
			if ($cmd eq 'global') {
				my $arglist = $parser->{strmap}->{$s}->[1];
				$ctx->{log}->($ctx, 'convert', $code, "global $s -> drop global stmt") if $ctx->{log};
				my $empty = $parser->setblk('flat', []);
				return $empty;
			}
		} elsif (is_variable($s)) {
			my $g = $ctx->is_global_var($s);
			my ($inst, $instvar) = inst_split($s);

			if (defined $inst && ($inst ne 'GLOBALS')) {
				if ($inst =~ /^#inst\d+$/) {
					$ctx->{log}->($ctx, 'convert', $code, "global $s -> is instvar") if $ctx->{log};
				} else {
					$ctx->{log}->($ctx, 'convert', $code, "global $s -> is classvar") if $ctx->{log};
				}
			} elsif (defined $g) {
				if ($cctx->{infunction}) {
					my $v = global_var($g); # keep global annotation
					return $v;
				} else {
					# caller is toplevel
					return $g;
				}
			}
		}
		return;
	});

	if ($out ne $code) {
		$ctx->{log}->($ctx, 'convert', $code, "global changed -> $out") if $ctx->{log};
	}
	return $out;
}

# convert global vars to explicit globals
#
sub globlify_local_vars {
	my ($ctx, $info, $code) = @_;
	my $parser = $ctx->{parser};

	my $out = $parser->map_stmt($code, sub {
		my ($s) = @_;

		if (is_variable($s)) {
			my ($inst, $instvar) = inst_split($s);

			if ($ctx->is_superglobal($s)) {
				$ctx->{log}->($ctx, 'globlify', $code, "keep superglobal $s") if $ctx->{log};
			} elsif (exists $ctx->{varmap}{ref}{$s}) {
				$ctx->{log}->($ctx, 'globlify', $code, "keep ref var $s") if $ctx->{log};
			} elsif (exists $ctx->{varmap}{global}{$s}) {
				$ctx->{log}->($ctx, 'globlify', $code, "keep global var $s") if $ctx->{log};
			} elsif (defined $inst && ($inst eq 'GLOBALS')) {
				$ctx->{log}->($ctx, 'globlify', $code, "keep global var $s") if $ctx->{log};
			} elsif ($ctx->{infunction} && exists $ctx->{varmap}{static}{$ctx->{infunction}}{$s}) {
				$ctx->{log}->($ctx, 'globlify', $code, "keep static func var $s") if $ctx->{log};
			} elsif (defined $inst && exists $ctx->{class_scope} && (lc($inst) eq $ctx->{class_scope})) {
				$ctx->{log}->($ctx, 'globlify', $code, "keep static class var $s") if $ctx->{log};
			} elsif (exists $info->{vars}{$s}) {
				$ctx->{log}->($ctx, 'globlify', $code, "remaining local var $s") if $ctx->{log};
				my $v = global_var($s);
				return $v;
			}
		}
		return;
	});

	if ($out ne $code) {
		$ctx->{log}->($ctx, 'globlify', $code, "changed -> $out") if $ctx->{log};
	}
	return $out;
}

sub _remove_final_statement {
	my ($parser, $pattern, $code) = @_;
	my @seq = ();
	my @out = ();
	my $changed = 0;

	$parser->flatten_block($code, \@seq);

	foreach my $s (@seq) {
		if ($s =~ /^#stmt\d+$/) {
			my $cmd = $parser->{strmap}->{$s}->[0];
			if ($cmd =~ /^$pattern$/) {
				$changed = 1;
				next;
			}
		}
		push(@out, $s);
	}
	if ($changed) {
		return _flat_block_or_single($parser, \@out);
	}
	return $code;
}

# can_inline is called for the callee context, and the final return
# statement is already removed (if function returns a value).
#
sub can_inline {
	my ($ctx, $code) = @_;
	my $parser = $ctx->{parser};
	my $allow = 1;

	my $out = $parser->map_stmt($code, sub {
		my ($s) = @_;
		return $s unless $allow;

		if ($s =~ /^#stmt\d+$/) {
			my $cmd = $parser->{strmap}->{$s}->[0];
			if ($cmd eq 'echo') {
				my $arglist = $parser->{strmap}->{$s}->[1];
				foreach my $a (@$arglist) {
					unless ($ctx->can_inline($a)) {
						$allow = 0;
						last;
					}
				}
				return $s;
			} elsif ($cmd eq 'print') {
				my $arg = $parser->{strmap}->{$s}->[1];
				if ($ctx->can_inline($arg)) {
					$allow = 0;
				}
				return $s;
			} elsif ($cmd eq 'global') {
				return $s;
			} elsif ($cmd eq 'return') {
				$ctx->{log}->($ctx, 'inline', $code, "detected remaining return $s") if $ctx->{log};
			} else {
				return; # check other statements
			}
		} elsif ($s =~ /^#blk\d+$/) {
			return; # check block elements
		} elsif ($s =~ /^#expr\d+$/) {
			my ($op, $v1, $v2) = @{$parser->{strmap}->{$s}};

			if ($op ne '$') { # keep varvar
				if (defined $v1) {
					unless ($ctx->can_inline($v1)) {
						$allow = 0;
					}
				}
				if ($allow && defined $v2) {
					unless ($ctx->can_inline($v2)) {
						$allow = 0;
					}
				}
				return $s;
			}
		} elsif ($s =~ /^#elem\d+$/) {
			my ($v, $i) = @{$parser->{strmap}->{$s}};

			unless ($ctx->can_inline($v)) {
				$allow = 0;
			}
			if ($allow && defined $i) {
				unless ($ctx->can_inline($i)) {
					$allow = 0;
				}
			}
			return $s;
		} elsif ($s =~ /^#call\d+$/) {
			my ($name, $arglist) = @{$parser->{strmap}->{$s}};
			my ($inst, $prop) = method_split($name);
			if (defined $inst || is_symbol($name) || is_strval($name) || ($name =~ /^#fun\d+$/)) {
				unless ($name =~ /^(eval|create_function)$/i) {
					my $can = 1;
					my $arglist = $parser->{strmap}->{$s}->[1];
					foreach my $a (@$arglist) {
						unless ($ctx->can_inline($a)) {
							$can = 0;
							last;
						}
					}
					if ($can) {
						$ctx->{log}->($ctx, 'inline', $code, "$s [$name] is allowed func") if $ctx->{log};
						return $s;
					}
				}
			}
		} elsif ($s =~ /^#fun\d+$/) {
			return $s;
		} elsif ($s =~ /^#class\d+$/) {
			return $s;
		} elsif (is_strval($s)) {
			$ctx->{log}->($ctx, 'inline', $code, "$s is strval") if $ctx->{log};
			return $s;
		} elsif (is_array($s)) {
			if (PHP::Decode::Op::array_is_const($parser, $s)) {
				$ctx->{log}->($ctx, 'inline', $code, "$s is const array") if $ctx->{log};
				return $s;
			}
		} elsif (is_variable($s)) {
			my ($inst, $instvar) = inst_split($s);

			if ($ctx->is_superglobal($s)) {
				$ctx->{log}->($ctx, 'inline', $code, "$s is superglobal") if $ctx->{log};
				return $s;
			} elsif (defined $inst && ($inst ne 'GLOBALS')) {
				$ctx->{log}->($ctx, 'inline', $code, "$s is global") if $ctx->{log};
				return $s;
			} elsif (defined $inst && !($inst =~ /^#inst\d+$/)) {
				$ctx->{log}->($ctx, 'inline', $code, "$s is classvar") if $ctx->{log};
				return $s;
			}
		}
		$ctx->{warn}->($ctx, 'inline', $code, "disallow stmt $s");
		$allow = 0;
		return;
	});
	return $allow;
}

# can_inline_eval is called for the caller context, and the final return
# statement is already removed (if function returns a value).
#
sub can_inline_eval {
	my ($ctx, $code) = @_;
	my $parser = $ctx->{parser};
	my $allow = 1;

	my $out = $parser->map_stmt($code, sub {
		my ($s) = @_;
		return $s unless $allow;

		if ($s =~ /^#stmt\d+$/) {
			my $cmd = $parser->{strmap}->{$s}->[0];
			if ($cmd eq 'echo') {
				return $s;
			} elsif ($cmd eq 'print') {
				return $s;
			} elsif ($cmd eq 'return') {
				$ctx->{log}->($ctx, 'inline', $code, "detected remaining return $s") if $ctx->{log};
			} elsif ($cmd =~ /^(if|while|do|for|foreach|switch)$/) {
				#return; # check other statements
				return $s;
			}
		} elsif ($s =~ /^#blk\d+$/) {
			return; # check block elements
		} elsif ($s =~ /^#expr\d+$/) {
			# $var = <str>
			my ($op, $v1, $v2) = @{$parser->{strmap}->{$s}};
			if ($op eq '=') {
				if (is_strval($v2)) {
					return $s;
				}
			}
		} elsif ($s =~ /^#call\d+$/) {
			# call without eval can not generate 'return <str>'
			my ($_name, $_arglist) = @{$parser->{strmap}->{$s}};
			if (!PHP::Decode::Func::func_may_return_string($_name)) {
				return $s;
			}
		} elsif ($s =~ /^#fun\d+$/) {
			return $s;
		} elsif ($s =~ /^#class\d+$/) {
			return $s;
		} elsif (is_strval($s)) {
			return $s;
		}
		$ctx->{warn}->($ctx, 'inline', $code, "eval disallow stmt $s");
		$allow = 0;
		return;
	});
	return $allow;
}

# check if function body might return
#
sub _can_return {
	my ($info) = @_;

	if (exists $info->{returns} || exists $info->{calls}{'eval'} || exists $info->{calls}{'create_function'}) {
		return 1;
	}
	return 0;
}

sub _find_unresolved_param {
	my ($info, $param) = @_;
	my $param_found = 0;

	for (my $i=0; $i < scalar @$param; $i++) {
		if ($param->[$i] =~ /^#ref\d+$/) {
			$param_found = $param->[$i];
		}
		if (exists $info->{vars}{$param->[$i]}) {
			$param_found = $param->[$i];
		}
	}
	return $param_found;
}

sub set_func_params {
	my ($ctx, $cmd, $arglist, $param) = @_;
	my $parser = $ctx->{parser};

	# optional params ($var = value) are given as #expr
	#
	# TODO: arrays are passed as value - to pass them per
	#       reference &$arr params are used.
	#
	my %varmap;
	for (my $i=0; $i < scalar @$param; $i++) {
		my $var;
		my $val;

		if ($i < scalar @$arglist) {
			$val = $arglist->[$i];
		}
		if ($param->[$i] =~ /^#expr\d+$/) {
			my ($op, $v1, $v2) = @{$parser->{strmap}->{$param->[$i]}};
			if ($op ne '=') {
				$ctx->{warn}->($ctx, 'func', $cmd, "bad default param (skip): $param->[$i]");
				return;
			}
			$var = $v1;

			if (!defined $val) {
				$val = $v2; # set default for optional param
			}
		} elsif ($param->[$i] =~ /^#ref\d+$/) {
			$var = $parser->{strmap}->{$param->[$i]}->[0];
			unless (is_variable($val)) {
				$ctx->{warn}->($ctx, 'func', $cmd, "no ref var (skip): $param->[$i] = $val");
				return;
			} else {
				$varmap{ref}{$var} = [$ctx, $val];
				$ctx->{log}->($ctx, 'func', $cmd, "$var references $val now") if $ctx->{log};

				$val = $ctx->exec_statement($val, 1); # don't remove assignments like ($x = #unresolved)
			}
		} else {
			if (!defined $val) {
				$ctx->{warn}->($ctx, 'func', $cmd, "no default param (skip): $param->[$i] (too few params %d want %d)", scalar @$arglist, scalar @$param);
				return;
			}
			$var = $param->[$i];
		}
		if (is_variable($var)) {
			my $info = {vars => {}, calls => {}, stmts => {}};
			$parser->stmt_info($val, $info);

	        	if (_skipped_call($parser, $val, '(.*)', $info)) {
				$ctx->{warn}->($ctx, 'func', $cmd, "unresolved param (skip): $param->[$i] = $val");
				return;
			}
			if ($ctx->contains_local_var($info)) {
				$ctx->{warn}->($ctx, 'func', $cmd, "unresolved local var param (skip): $param->[$i] = $val");
				return;
			} elsif (($val =~ /^#expr\d+$/) && (scalar keys %{$info->{assigns}} > 0)) {
				$ctx->{warn}->($ctx, 'func', $cmd, "unresolved expr param (skip): $param->[$i] = $val");
				return;
			} elsif (($val =~ /^#expr\d+$/) && ($parser->{strmap}->{$val}->[0] eq '$')) {
				$ctx->{warn}->($ctx, 'func', $cmd, "unresolved varvar param (skip): $param->[$i] = $val");
				return;
			} elsif (scalar keys %{$info->{vars}} > 0) {
				$val = $ctx->globlify_local_vars($info, $val);
				$varmap{$var} = $val;
				$ctx->{log}->($ctx, 'func', $cmd, "globlified param: $var = $val") if $ctx->{log};
			} else {
				$varmap{$var} = $val;
				$ctx->{log}->($ctx, 'func', $cmd, "param: $var = $val") if $ctx->{log};
			}
		}
	}
	return \%varmap;
}

# exec_func() returns: ($retval, $code)
#
# If the function returns with 'return', the result is returned only if
# no function call or variable access was skipped.
#
# Return the executed code as the second result param.
# If a function parameters can't be resolved resolved, keep original call.
#
# - call complete:
#   ($ret, $code):      $ret from func-return statement.
#   (#noreturn, $code): return from void-func (substituted later by #null)
#
#   For '$code=undef' keep original call-statement.
#   Otherwise $code can be inlined by the caller.
#   - when the function returns a value, it is not part of the code.
#   - when local variables are left, $code is converted to an anonymous function call.
#   - when call returns tainted state, set also caller tainted
#
# - call not completly executed:
#   (#notaint, $code):  return anonymous function for inlining
#   (#notaint, undef):  keep original call-statement
#   undef:              keep original call-statement & set tainted
#
# - constructor call:
#   (#construct, $code): for constructor call just show executed statements
#
sub _exec_func {
	my ($ctx, $cmd, $arglist, $param, $block) = @_;
	my $parser = $ctx->{parser};

	# all variables in functions have local scope except
	# $GLOBALS[var] or varibales declared 'global $var'.
	#
	my $varmap = $ctx->set_func_params($cmd, $arglist, $param);
	if (!defined $varmap) {
		return;
	}
	$ctx->{log}->($ctx, 'func', $cmd, "START with varmap: [%s]", join(' ', keys %$varmap)) if $ctx->{log};
	#$ctx->{log}->($ctx, 'func', $cmd, "%s", $parser->format_stmt($block)) if $ctx->{log};
	#$ctx->{log}->($ctx, 'func', $cmd, "GLOBALS %s BLOCK %s", join(' ', keys %{$ctx->{globals}}), $block) if $ctx->{log};

	my $out;
	my $ctx2 = $ctx->subscope_ctx(varmap => $varmap, infunction => lc($cmd), incall => 1);
	$ctx2->{varhist} = {};

	my $is_construct;
	my ($inst, $prop) = method_split(lc($cmd));
	if (defined $inst) {
		my $method = $ctx->lookup_method_name(lc($cmd)); # lookup instance function
		if (defined $method) {
			$cmd = $method;
			$ctx2->{varmap}{'$this'} = $inst; # init $this var for instance
			if ($prop eq '__construct') {
				$is_construct = 1;
			} elsif (lc($cmd) eq method_name($prop, $prop)) {
				$is_construct = 1;
			}
		} else {
			$ctx2->{class_scope} = $inst; # is class call
		}
	}
	$ctx2->{infunction} = ($cmd =~ /^#fun\d+$/) ? '{closure}' : lc($cmd);

	my $res = $ctx2->exec_statement($block);
	if (defined $res) {
		$res = $ctx2->convert_assign_return($res);
		$ctx->{log}->($ctx, 'func', $cmd, "res: $res '%s'", $parser->format_stmt($res)) if $ctx->{log};
		if (is_block($res)) {
			my ($type, $a) = @{$parser->{strmap}->{$res}};
			$out = $a;
		} else {
			$out = [$res];	
		}
	}
	if (defined $out) {
		my $unresolved_param;
		my $keep_call = 0;
		my $resinfo = $ctx->get_unresolved_info($cmd, $res);

		if (scalar @$out > 0) {
			my $r = _final_break($parser, $res, '(return)');
			my $f = _skipped_call($parser, $res, '(.*)', $resinfo);
			my $u = $ctx2->unresolvable_var($resinfo); # allow to return superglobal result

			$ctx->{warn}->($ctx, 'func', $cmd, "found remaining [global assigns: %s, local assigns: %s, var: %s, calls: %s (%s)]: %s -> %s", join(' ', keys %{$resinfo->{global_assigns}}), join(' ', keys %{$resinfo->{local_assigns}}), $u ? $u : '-', $f ? $f : '-', join(' ', keys %{$resinfo->{calls}}), $block, $res);

			my $res1 = $ctx2->eliminate_local_assigments($resinfo, $res);
			if ((scalar keys %{$resinfo->{remaining_locals}} == 0) && (scalar keys %{$resinfo->{remaining_statics}} == 0)) {
				if ($res ne $res1) {
					$res = $res1;
				}
				$resinfo = $ctx->get_unresolved_info($cmd, $res);
				$unresolved_param = _find_unresolved_param($resinfo, $param);
			} elsif (scalar keys %{$resinfo->{remaining_statics}} > 0) {
				$keep_call = 1;
			} else {
				$unresolved_param = _find_unresolved_param($resinfo, $param);
			}

			if ($is_construct) {
				unless (_anon_func_call($parser, $res)) {
					$res = _to_code_block($parser, $res);
				}
				$ctx->{log}->($ctx, 'func', $cmd, "return $res for void construct") if $ctx->{log};
				return ('#construct', $res); # return dummy result & show simplified code for construct
			}

			# undefined result
			#
			if (defined $u || defined $f) {
				if ($ctx2->{tainted} > $ctx->{tainted}) {
					$ctx->{warn}->($ctx, 'func', $cmd, "not completely executed (and tainted)");
					$ctx->{tainted} = $ctx2->{tainted};
				}
			}

			if (_can_return($resinfo)) {
				if (!defined $r) {
					if ($ctx->{infunction} && !$ctx->{incall}) {
						$ctx->{log}->($ctx, 'func', $cmd, "don't expand subcalls while function is parsed") if $ctx->{log};
						return (undef, $res);
					}
					$ctx->{log}->($ctx, 'func', $cmd, "has return but no final return -> inline anon func") if $ctx->{log};
					$res = _to_anon_func_call($parser, $res);
					return ('#notaint', $res);
				}
				my $arg = $parser->{strmap}->{$r}->[1];
				my $arginfo = {vars => {}, calls => {}, stmts => {}};
				$parser->stmt_info($arg, $arginfo);

				if ($ctx2->contains_local_var($arginfo)) {
					if ($ctx->{infunction} && !$ctx->{incall}) {
						$ctx->{log}->($ctx, 'func', $cmd, "don't expand subcalls while function is parsed") if $ctx->{log};
						return (undef, $res);
					}
					if ($keep_call || $unresolved_param) {
						$ctx->{log}->($ctx, 'func', $cmd, "return $arg is local var & unresolved locals -> keep call") if $ctx->{log};
						return ('#notaint', undef);
					}
					$ctx->{log}->($ctx, 'func', $cmd, "return $arg is local var -> inline anon func") if $ctx->{log};
					$res = _to_anon_func_call($parser, $res);
					return ('#notaint', $res);
				}
				$arg = $ctx2->convert_globals_to_caller_ctx($resinfo, $arg, $ctx);

				my $res1 = _remove_final_statement($parser, '(return)', $res);

				if ($keep_call || $unresolved_param) {
					$resinfo = $ctx->get_unresolved_info($cmd, $res1);
					if (_can_return($resinfo)) {
						$ctx->{log}->($ctx, 'func', $cmd, "has multiple returns & unresolved locals -> keep call") if $ctx->{log};
						return ('#notaint', undef);
					} else {
						$ctx->{log}->($ctx, 'func', $cmd, "has return $arg & unresolved locals -> keep call") if $ctx->{log};
						return ($arg, undef);
					}
				}
				if ($ctx2->can_inline($res1)) {
					$res1 = $ctx2->convert_globals_to_caller_ctx($resinfo, $res1, $ctx);
					return ($arg, $res1);
				}
				$ctx->{log}->($ctx, 'func', $cmd, "has return $arg but can't inline -> inline anon func") if $ctx->{log};
				$res = _to_anon_func_call($parser, $res);
				return ('#notaint', $res);
			}
		} else {
			$unresolved_param = _find_unresolved_param($resinfo, $param);
		}

		if (scalar @$out > 0) {
			# If a return was omitted the value NULL will be returned. 
			# https://php.net/manual/en/functions.returning-values.php
			#
			$ctx->{log}->($ctx, 'func', $cmd, "has no return - return #null") if $ctx->{log};

			if ($keep_call || $unresolved_param) {
				return ('#noreturn', undef);
			}
			if ($ctx2->can_inline($res)) {
				$res = $ctx2->convert_globals_to_caller_ctx($resinfo, $res, $ctx);
				return ('#noreturn', $res);
			}
			$res = _to_anon_func_call($parser, $res);
			return ('#noreturn', $res);
		}
	}
	return;
}

sub exec_func {
	my ($ctx, $cmd, $arglist, $param, $block) = @_;
	my $parser = $ctx->{parser};
	my $ret;
	my $code;

	if (exists $parser->{strmap}{_CALL}{$cmd}) {
		$parser->{strmap}{_CALL}{$cmd} += 1;
	} else {
		$parser->{strmap}{_CALL}{$cmd} = 1;
	}
	my $level = $parser->{strmap}{_CALL}{$cmd};

	if ($level > 4) {
		$ctx->{warn}->($ctx, 'func', $cmd, "max recursion level ($level) reached");
	} else {
		($ret, $code) = $ctx->_exec_func($cmd, $arglist, $param, $block);
	}
	$parser->{strmap}{_CALL}{$cmd} -= 1;

	if (defined $ret) {
		return ($ret, $code);
	}
	return;
}

# get elem list for multidimensional array (base elem first)
#
sub _get_elemlist {
	my ($parser, $var) = @_;
	my @list = ();

	while ($var =~ /^#elem\d+$/) {
		my ($v, $i) = @{$parser->{strmap}->{$var}};

		unshift(@list, $var);
		$var = $v;
	}
	return \@list;
}

# convert elem list to point to new base var
#
sub _update_elemlist {
	my ($parser, $var, $elemlist) = @_;
	my @list = ();

	foreach my $elem (@$elemlist) {
		my ($v, $i) = @{$parser->{strmap}->{$elem}};
		my $next = $parser->setelem($var, $i);
		push(@list, $next);
		$var = $next;
	}
	return \@list;
}

sub resolve_varvar {
	my ($ctx, $var, $in_block) = @_;
	my $parser = $ctx->{parser};

	# https://www.php.net/manual/en/language.variables.variable.php
	#
	if ($var =~ /^#expr\d+$/) {
		my ($op, $v1, $v2) = @{$parser->{strmap}->{$var}};

		if (($op eq '$') && !defined $v1 && defined $v2) {
			my $op2 = $ctx->exec_statement($v2, $in_block);
			my $val = $parser->varvar_to_var($op2);
			if (defined $val) {
				return $val;
			}
			if ($v2 ne $op2) {
				# simplify expr
				$val = $parser->setexpr($op, undef, $op2);
				return $val;
			}
		}
	}
	return $var;
}

sub resolve_obj {
	my ($ctx, $var, $in_block) = @_;
	my $parser = $ctx->{parser};

	if ($var =~ /^#obj\d+$/) {
		my ($o, $m) = @{$parser->{strmap}->{$var}};

		if ($o =~ /^#inst\d+$/) {
			$ctx->{warn}->($ctx, 'resolve', $var, "obj already instanciated $o");
		}
		my ($basevar, $has_index, $idxstr) = $ctx->resolve_variable($o, $in_block);
		my $basestr;
		if (defined $basevar && !$has_index) {
			$basestr = $ctx->exec_statement($basevar, $in_block);
			if ($basestr ne $basevar) {
				$ctx->{log}->($ctx, 'resolve', $var, "obj-var $o basevar $basevar [%s]", defined $basestr ? $basestr : '') if $ctx->{log};
			}
		} elsif ($o =~ /^#inst\d+$/) {
			$ctx->{log}->($ctx, 'resolve', $var, "has inst $o") if $ctx->{log};
			$basestr = $o;
		}
		if (!defined $basestr) {
			my $inst = $ctx->exec_statement($o);
			if ($inst ne $o) {
				$ctx->{log}->($ctx, 'resolve', $var, "created $inst") if $ctx->{log};
				$basestr = $inst;
			}
		}
		$ctx->{log}->($ctx, 'resolve', $var, "[$o->$m] -> %s", defined $basestr ? $basestr : '-') if $ctx->{log};

		if (defined $basestr && ($basestr =~ /^#inst\d+$/)) {
			my $inst = $basestr;
			my $sym = $m;

			# $obj->{'a'}() or $obj->{$x}() is allowed
			#
			if (is_block($m) || is_variable($m)) {
				$sym = $ctx->exec_statement($m);
			}
			if (is_strval($sym) && !is_null($sym)) {
				$sym = $parser->{strmap}{$sym};
				$ctx->{log}->($ctx, 'resolve', $var, "resolved sym $o :: $m -> $inst :: $sym") if $ctx->{log};
			}
			return ($inst, $sym);
		}
	}
	return;
}

sub resolve_scope {
	my ($ctx, $var, $in_block) = @_;
	my $parser = $ctx->{parser};

	# https://php.net/manual/en/language.oop5.paamayim-nekudotayim.php
	#
	if ($var =~ /^#scope\d+$/) {
		my ($c, $e) = @{$parser->{strmap}->{$var}};
		my $class;
		my $scopename;

		if ($c =~ /^#class\d+$/) {
			$ctx->{warn}->($ctx, 'resolve', $var, "scope already resolved $c");
			$class = $c;
		} else {
			my $name = $c;
			if (!is_symbol($name)) {
				my $s = $ctx->exec_statement($name);
				if (is_strval($s) && !is_null($s)) {
					$name = $parser->{strmap}->{$s};
				} else {
					$name = $s;
				}
				$ctx->{log}->($ctx, 'resolve', $var, "map %s (%s) -> %s", $c, $s, $name) if $ctx->{log};
			}
			if ($name eq 'self') {
				if (exists $ctx->{class_scope}) {
					$class = $ctx->getclass($ctx->{class_scope});
				} else {
					$ctx->{warn}->($ctx, 'resolve', $var, "self used outside of class scope");
				}
			} elsif ($name eq 'parent') {
				if (exists $ctx->{class_scope}) {
					$ctx->{warn}->($ctx, 'resolve', $var, "parent for class $ctx->{class_scope} not supported");
				} else {
					$ctx->{warn}->($ctx, 'resolve', $var, "parent used outside of class scope");
				}
			} else {
				$scopename = $ctx->add_namespace($name);
				$class = $ctx->getclass($scopename);
			}
		}
		if (defined $class) {
			my ($n, $b, $p) = @{$parser->{strmap}->{$class}};

			$scopename = $n unless defined $scopename;

			if (is_variable($e)) {
				my ($basevar, $has_index, $idxstr) = $ctx->resolve_variable($e, $in_block);
				if (defined $basevar && is_variable($basevar)) {
					$ctx->{log}->($ctx, 'resolve', $var, "var %s::%s -> %s::%s", $c, $e, $scopename, $basevar) if $ctx->{log};
					return ($scopename, $basevar);
				}
			} else {
				my $sym = $e;
				if (is_block($e)) {
					$sym = $ctx->exec_statement($e);
				}
				if (is_strval($sym) && !is_null($sym)) {
					$sym = $parser->{strmap}{$sym};
					$ctx->{log}->($ctx, 'resolve', $var, "sym %s::%s -> %s::%s", $c, $e, $scopename, $sym) if $ctx->{log};
				}
				return ($scopename, $sym);
			}
		}
	}
	return;
}

sub resolve_ns {
	my ($ctx, $var, $in_block) = @_;
	my $parser = $ctx->{parser};

	# https://php.net/manual/en/language.namespaces.rationale.php
	#
	if ($var =~ /^#ns\d+$/) {
		my ($n, $e) = @{$parser->{strmap}->{$var}};
		my $ns;

		if (!defined $n) {
			$ctx->{log}->($ctx, 'resolve', $var, "toplevel") if $ctx->{log};
			$ns = ''; # toplevel
		} else {
			my $name = $n;
			if (!is_symbol($name)) {
				my $s = $ctx->exec_statement($name);
				if (is_strval($s) && !is_null($s)) {
					$name = $parser->{strmap}->{$s};
				} else {
					$name = $s;
				}
				$ctx->{log}->($ctx, 'resolve', $var, "map %s (%s) -> %s", $n, $e, $name) if $ctx->{log};
			}
			if ($name eq 'namespace') {
				$ns = lc($ctx->{namespace});
			} else {
				$ns = $name;
			}
		}
		return ($ns, $e);
	}
	return;
}

# convert first elem of elem list to variable if possible
#
sub get_baseelem {
	my ($ctx, $var, $in_block) = @_;
	my $parser = $ctx->{parser};
	my $elemlist = _get_elemlist($parser, $var);

	if ($elemlist->[0] =~ /^#elem\d+$/) {
		my ($v, $i) = @{$parser->{strmap}->{$elemlist->[0]}};

		if (defined $i && ($v !~ /^#elem\d+$/)) {
			# allow only to resolve variable recursively
			# todo: use resolve_variable() here?
			#
			my $val;
			if ($v =~ /^#expr\d+$/) {
				$val = $ctx->resolve_varvar($v, $in_block);
				if (($val ne $v) && !is_variable($val)) {
					return _update_elemlist($parser, $val, $elemlist);
				}
			} elsif ($v =~ /^#obj\d+$/) {
				my ($inst, $prop) = $ctx->resolve_obj($v, $in_block);
				if (defined $inst) {
					$val = inst_var($inst, '$'.$prop);
				}
			} else {
				$val = $ctx->exec_statement($v, $in_block);
			}
			if (defined $val && is_variable($val)) {
				my $idx = $ctx->exec_statement($i);
				my $g = $parser->globalvar_to_var($val, $idx);
				if (defined $g) {
					# convert resolved basevar $GLOBALS['x'] -> $x,
					# 
					if ($ctx->{infunction}) {
						$g = global_var($g);
					}
					shift(@$elemlist);
					if (@$elemlist) {
						return _update_elemlist($parser, $g, $elemlist);
					} else {
						return [$g];
					}
				} elsif ($ctx->is_superglobal($val)) {
					return $elemlist;
				} else {
					# convert resolved baseelem ${$a}['x'] -> $b['x'],
					# 
					return _update_elemlist($parser, $val, $elemlist);
				}
			}
		}
	}
	return $elemlist;
}

# For undefined multidimensional arrays create_basearray() allocates
# missing intermediate arrays. Also assigns a new array or a copy of
# the existing array via setvar() to basevar.
#
# return: ($var, $val, $basevar);
# - var: the variable part for the topmost element (topmost index ignored)
# - val: the matching (sub)-array for this variable (might be undef)
# - basevar: the base variable of the array.
#
sub create_basearray {
	my ($ctx, $elemlist, $in_block) = @_;
	my $parser = $ctx->{parser};
	my $superglobals_writable = 1;

	my $elem = $elemlist->[0];
	my ($v, $i) = @{$parser->{strmap}->{$elem}};
	my $val = $ctx->exec_statement($v, $in_block);
	my $basevar = $v;

	if (is_variable($val)) {
		# resolved reference
		if (!$ctx->is_superglobal($val) || $superglobals_writable) {
			$v = $val;
			$val = undef;
		}
	}
	if (defined $val && is_strval($val) && ($parser->get_strval_or_str($val) eq '')) {
		# up to php70 empty strings are treated like an empty array
		# https://www.php.net/manual/en/migration71.incompatible.php
		#
		unless (exists $ctx->{skip}{treat_empty_str_like_empty_array}) {
			$ctx->{warn}->($ctx, 'elem', $elem, "treat empty str $val like empty array");
			$val = undef;
		}
	}
	if (defined $val && is_null($val)) {
		$val = undef;
	} 
	if (!defined $val || is_array($val)) {
		if (!defined $val) {
			# nonexisting array is auto-created
			#
			my $arr = $parser->newarr();
			$val = $arr->{name};
			$ctx->{log}->($ctx, 'elem', $elem, "create_base autoarr $v: $val") if $ctx->{log};
		} else {
			# TODO: don't copy array if not displayed since last update
			#       (track tainted state for each array)
			#
			my $arr = $parser->{strmap}{$val};
			$arr = $arr->copy(); # recursive copy
			$ctx->{log}->($ctx, 'elem', $elem, "create_base copyarr $v: $val -> $arr->{name}") if $ctx->{log};
			$val = $arr->{name};
		}
		# don't insert '$x = array()' into block
		#
		$ctx->setvar($v, $val, 1);
		#$ctx->setvar($v, $val, $in_block);
	} else {
		# something like #obj?
		#
		my $lastelem = $elemlist->[-1];
		my ($lastvar, $lastidx) = @{$parser->{strmap}->{$lastelem}};
		return ($lastvar, $val, $basevar);
	}

	# resolve next index
	#
	foreach my $nextelem (@$elemlist[1..@$elemlist-1]) {
		my $idx;
		my $nextval;
		my $arr = $parser->{strmap}{$val};

		if (defined $i) {
			$idx = $ctx->exec_statement($i, $in_block);
			$idx = $parser->setstr('') if is_null($idx); # null maps to '' array index
			my $arrval = $arr->get($idx);
			if (defined $arrval) {
				$nextval = $arrval;
			}
		}
		if (!defined $nextval || is_array($nextval)) {
			if (!defined $nextval) {
				# nonexisting intermediate array is auto-created
				#
				my $newarr = $parser->newarr();
				$ctx->{log}->($ctx, 'elem', $elem, "create_base autoarr $nextelem: = $newarr->{name} [basevar: $basevar]") if $ctx->{log};
				$nextval = $newarr->{name};
			}
			if (!defined $idx) {
				$arr->set(undef, $nextval);
				$ctx->{log}->($ctx, 'elem', $elem, "create_base set: %s[] = %s", $val, $nextval) if $ctx->{log};
			} elsif (is_strval($idx)) {
				$arr->set($idx, $nextval);
				$ctx->{log}->($ctx, 'elem', $elem, "create_base set: %s[%s] = %s", $val, $idx, $nextval) if $ctx->{log};
			} else {
				$ctx->{log}->($ctx, 'elem', $elem, "create_base set: %s[%s] bad idx", $val, $idx) if $ctx->{log};
			}
		}
		if (($elem ne $v) || ($idx ne $i)) {
			$elem = $parser->setelem($v, $idx);
		}
		$v = $elem;
		$val = $nextval;
		($elem, $i) = @{$parser->{strmap}->{$nextelem}};
	}
	return ($v, $val, $basevar);
}

# resolve_variable() returns: ($basevar, $has_idx, [$baseidx])
# - basevar: resolved variable name (a.e: array name)
# - has_idx: is array dereference
# - baseidx: if is array: indexvalue of last index or undef if index is empty
#
sub resolve_variable {
	my ($ctx, $var, $in_block) = @_;
	my $parser = $ctx->{parser};

	# returns: <$resolved_var> <strmap_entry_if_exists> <has_index> <indexval|undef>
	#
	if (!defined $var) {
		$ctx->{warn}->($ctx, 'resolve', '', "<UNDEF>");
		return;
	}
	if (is_variable($var)) {
	        if (exists $ctx->{varmap}{ref}{$var}) {
			my ($ctx2, $var1) = @{$ctx->{varmap}{ref}{$var}};
			# special case for '$var = &$GLOBALS' reference
		    	if ($var1 =~ /^\$GLOBALS$/) {
				$ctx->{log}->($ctx, 'resolve', $var, "superglobals reference -> $var1") if $ctx->{log};
				return $ctx2->resolve_variable($var1, $in_block);
			}
		}
		return ($var, 0);
	} elsif ($var =~ /^#obj\d+$/) {
		my ($inst, $prop) = $ctx->resolve_obj($var, $in_block);
		if (defined $inst) {
			my $instvar = inst_var($inst, '$'.$prop);
			$ctx->{log}->($ctx, 'resolve', $var, "obj -> $instvar") if $ctx->{log};
			return $ctx->resolve_variable($instvar, $in_block);
		}
	} elsif ($var =~ /^#scope\d+$/) {
		my ($scope, $val) = $ctx->resolve_scope($var, $in_block);
		if (defined $scope && is_variable($val)) {
			my $classvar = inst_var($scope, $val);
			$ctx->{log}->($ctx, 'resolve', $var, "scope -> $classvar") if $ctx->{log};
			return $ctx->resolve_variable($classvar, $in_block);
		}
	} elsif ($var =~ /^#elem\d+$/) {
		my ($v, $i) = @{$parser->{strmap}->{$var}};

		if (!defined $v) {
			$ctx->{warn}->($ctx, 'resolve', $var, "BAD ELEM");
			return;
		}
		if (is_strval($v)) {
			# #strliteral[#num] -> substring
			#
			my $idxstr = $ctx->exec_statement($i);
			if (defined $idxstr) {
				$ctx->{log}->($ctx, 'resolve', $var, "%s[%s] -> is substring", $v, $idxstr) if $ctx->{log};
				return ($v, 1, $idxstr);
			}
		}
		if (is_array($v)) {
			# #arr[#num] -> elem
			#
			my $idxstr = $ctx->exec_statement($i);
			if (defined $idxstr) {
				$ctx->{log}->($ctx, 'resolve', $var, "%s[%s] -> is array elem", $v, $idxstr) if $ctx->{log};
				return ($v, 1, $idxstr);
			}
		}
		my $elemlist = $ctx->get_baseelem($var, $in_block);
		my $basevar = $elemlist->[0];
		my $baseidx;

		# this was a conversion '$GLOBALS[x] -> $x'
		#
		unless ($basevar =~ /^(\#elem\d+)$/) {
			$ctx->{log}->($ctx, 'resolve', $var, "%s[%s] -> global %s", $v, $i, $basevar) if $ctx->{log};
			return ($basevar, 0);
		}
		($basevar, $baseidx) = @{$parser->{strmap}->{$basevar}};

		$ctx->{log}->($ctx, 'resolve', $var, "%s[%s] -> %s[%s]", $v, defined $i ? $i : '-', defined $basevar ? $basevar : '-', defined $baseidx ? $baseidx : '-') if $ctx->{log};

		if (defined $basevar) {
			if (defined $i) {
				my $idxstr = $ctx->exec_statement($i);
				return ($basevar, 1, $idxstr);
			}
		}
	} elsif ($var =~ /^#expr\d+$/) {
		my $val = $ctx->resolve_varvar($var, $in_block);
		if (($val ne $var) && !($val =~ /^#expr\d+$/)) {
			return $ctx->resolve_variable($val, $in_block);
		}
	}
	return;
}

# resolves variables for function call argument list
# - an optional $prototype-list can be passed to check arguments
#
sub resolve_arglist {
	my ($ctx, $arglist, $param, $in_block) = @_;
	my @args = ();
	my $arg_changed = 0;
	my $i = 0;

	foreach my $p (@$arglist) {
		if (($i < scalar @$param) && ($param->[$i++] =~ /^#ref\d+$/)) {
			# reference is resolved in exec_func->set_func_params
			#
			push(@args, $p);
		} elsif (!is_strval($p) || is_const($p)) {
			my $v = $ctx->exec_statement($p, $in_block);

			push(@args, $v);
			if ($v ne $p) {
				$arg_changed = 1;
			}
		} else {
			push(@args, $p);
		}
	}
	return (\@args, $arg_changed);
}

sub invalidate_arglist_refs {
	my ($ctx, $arglist, $param, $in_block) = @_;
	my $i = 0;

	foreach my $p (@$arglist) {
		if (($i < scalar @$param) && ($param->[$i++] =~ /^#ref\d+$/)) {
			if (is_variable($p)) {
				$ctx->setvar($p, '#unresolved', $in_block);
			}
			# todo: elem
		}
	}
	return;
}

sub loop_start {
	my ($parser) = @_;

	unless (exists $parser->{strmap}->{_LOOP}) {
		$parser->{strmap}->{_LOOP} = 0;
		$parser->{strmap}->{_LOOP_LEVEL} = 1;
		return 1;
	} else {
		$parser->{strmap}->{_LOOP_LEVEL}++;
	}
	return 0;
}

sub loop_val {
	my ($parser, $i) = @_;
	return $i + $parser->{strmap}->{_LOOP};
}

sub loop_level {
	my ($parser) = @_;
	return $parser->{strmap}->{_LOOP_LEVEL};
}

sub loop_end {
	my ($parser, $toploop, $i) = @_;

	if ($toploop) {
		delete $parser->{strmap}->{_LOOP};
		delete $parser->{strmap}->{_LOOP_LEVEL};
	} else {
		$parser->{strmap}->{_LOOP} += $i;
		$parser->{strmap}->{_LOOP_LEVEL}--;
	}
	return;
}

sub exec_statement {
	my ($ctx, $var, $in_block) = @_;
	my $parser = $ctx->{parser};

	if (!defined $var) {
		$ctx->{warn}->($ctx, 'exec', '', "<UNDEF>");
		return $var;
	}
	if (is_strval($var) && !is_const($var)) {
		return $var;
	}
	if ($var =~ /^#ref\d+$/) {
		return $var;
	}
	$ctx->{log}->($ctx, 'exec', $var, "%s%s", $parser->stmt_str($var), $in_block ? ' (inblock)' : '') if $ctx->{log};

	if (is_variable($var)) {
		if (exists $ctx->{varmap}{ref}{$var}) {
			my ($ctx2, $var1) = @{$ctx->{varmap}{ref}{$var}};
			#if (!$ctx->is_superglobal($var1) || ($var1 =~ /^\$GLOBALS$/)) {
				$ctx->{log}->($ctx, 'exec', $var, "resolve reference -> $var1") if $ctx->{log};
				$var = $var1;
				$ctx = $ctx2;
			#}
		}
		my $val = $ctx->getvar($var);
		if (defined $val && ($val eq '#unresolved')) {
			$ctx->{log}->($ctx, 'exec', $var, "is unresolved") if $ctx->{log};
			$val = undef;
		}
		#if (defined $val && is_variable($val)) {
		#	my $vval = $ctx->exec_statement($val);
		#	$ctx->{log}->($ctx, 'exec', $var, "val $val vval $vval") if $ctx->{log};
		#	if ($ctx->is_unresolved_assignment($vval)) {
		#		$val = undef;
		#	}
		#}
		if (defined $val) {
		    #unless ($val =~ /^\$GLOBALS$/) {
			my $str = $val;
			if (is_strval($val)) {
				$str = $parser->{strmap}{$val};
				$ctx->{log}->($ctx, 'getvar', $var, "-> %s [%s]", $val, $parser->shortstr($str, 60)) if $ctx->{log};
			} elsif (is_array($val)) {
				my $arr = $parser->{strmap}{$val};
				my $keys = $arr->get_keys();
				$ctx->{log}->($ctx, 'getvar', $var, "-> %s [size: %d]", $val, scalar @$keys) if $ctx->{log};
			} else {
				$ctx->{log}->($ctx, 'getvar', $var, "-> %s", $val) if $ctx->{log};
			}
			return $val;
		    #} else {
		    #	$ctx->{log}->($ctx, 'exec', $var, "is superglobal") if $ctx->{log};
		    #}
		}
		return $var;
	} elsif (is_const($var)) {
		my $v = $parser->{strmap}->{$var};

		# constant (undefined constants propagate to string)
		# constants are always global
		#
		# - some constants are magic (__LINE__ is handled in parser):
		#   https://www.php.net/manual/en/language.constants.magic.php
		#
		my $nv = $ctx->add_namespace($v);

		if (exists $ctx->{defines}{$nv}) {
			my $val = $ctx->{defines}{$nv};
			my $str = $val;
			$ctx->{log}->($ctx, 'getdef', $var, "%s -> %s [%s]", $nv, $val, $parser->shortstr($str, 60)) if $ctx->{log};
			return $val;
		} elsif ($v =~ /^__FUNCTION__$/) {
			if ($ctx->{infunction}) {
				my ($class, $prop) = method_split($ctx->{infunction});
				$prop = $ctx->{infunction} unless defined $prop;
				my $fun = $ctx->getfun($prop);
			        if (defined $fun) { # convert name to mixedcase
					my ($f, $a, $b, $p) = @{$parser->{strmap}->{$fun}};
					if ($ctx->{namespace}) {
						$f = ns_name($ctx->{namespace}, $f); # keep namespace case here
					}
					return $parser->setstr($f);
				}
			} else {
				return $parser->setstr('');
			}
		} elsif ($v =~ /^__CLASS__$/) {
			if (exists $ctx->{class_scope}) {
				my $class = $ctx->getclass($ctx->{class_scope});
				if (defined $class) { # convert name to mixedcase
					my ($n, $b, $p) = @{$parser->{strmap}->{$class}};
					if ($ctx->{namespace}) {
						$n = ns_name($ctx->{namespace}, $n); # keep namespace case here
					}
					return $parser->setstr($n);
				}
			} else {
				return $parser->setstr('');
			}
		} elsif ($v =~ /^__METHOD__$/) {
			if ($ctx->{infunction}) {
				# internal method representation matches php class::name
				my $fun = $ctx->getfun($ctx->{infunction});
				if (defined $fun) {
					my ($f, $a, $b, $p) = @{$parser->{strmap}->{$fun}};
					my ($classname, $prop) = method_split($ctx->{infunction});
					my $name; # convert name to mixedcase
					if (defined $classname) {
						my $class = $ctx->getclass($classname);
						my ($n, $cb, $cp) = @{$parser->{strmap}->{$class}};
						$name = method_name($n, $f);
					} else {
						$name = $f;
					}
					if ($ctx->{namespace}) {
						$name = ns_name($ctx->{namespace}, $name); # keep namespace case here
					}
					return $parser->setstr($name);
				}
			} else {
				return $parser->setstr('');
			}
		} elsif ($v =~ /^__NAMESPACE__$/) {
			if ($ctx->{namespace}) {
				return $parser->setstr($ctx->{namespace});
			} else {
				return $parser->setstr('');
			}
		} elsif ($v =~ /^__DIR__$/) {
			# skip
		} elsif ($v =~ /^DIRECTORY_SEPARATOR$/) {
			return $parser->setstr('/');
		} elsif ($v =~ /^PATH_SEPARATOR$/) {
			return $parser->setstr('/');
		} elsif (exists $ctx->{globals} && exists $ctx->{globals}{$v}) {
			my $val = $ctx->{globals}{$v};
			my $str = $val;
			if (is_strval($val)) {
				$str = $parser->{strmap}->{$val};
			}
			$ctx->{log}->($ctx, 'getconst', $var, "%s -> %s [%s]", $v, $val, $parser->shortstr($str, 60)) if $ctx->{log};
			return $val;
		} else {
			unless ($ctx->{tainted}) {
				my $k = $parser->setstr($v);
				$ctx->{warn}->($ctx, 'exec', $var, "convert undefined const to string: $v -> $k");
				return $k;
			} else {
				$ctx->{warn}->($ctx, 'exec', $var, "don't convert undefined const to string: $v -> tainted");
			}
		}
		return $var;
	} elsif ($var =~ /^#arr\d+$/) {
		my $arr = $parser->{strmap}{$var};

		# try to simplify array here (if not in function)
		#
		unless ($ctx->{incall}) {
		    if (exists $ctx->{simplify}{arr}) {
			my @newkeys;
			my %newmap;
			my $changed = 0;
			my $keys = $arr->get_keys();

			foreach my $k (@$keys) {
				my $val = $arr->val($k);
				if ((is_int_index($k) || is_strval($k)) && (!defined $val
					|| (defined $val && is_strval($val)))) {
					push(@newkeys, $k);
					$newmap{$k} = $val;
				} else {
					my $k2 = $k;
					unless (is_int_index($k)) {
						$k2 = $ctx->exec_statement($k);
					}
					push(@newkeys, $k2);
					if (defined $val) {
						my $v = $ctx->exec_statement($val);
						$newmap{$k2} = $v;
					} else {
						$newmap{$k2} = undef;
					}
					if (($k ne $k2) || ($val ne $newmap{$k2})) {
						$changed = 1;
					}
				}
			}
			if ($changed) {
				$arr = $parser->newarr();
				foreach my $k (@newkeys) {
					$arr->set($k, $newmap{$k});
				}
				$ctx->{log}->($ctx, 'exec', $var, "simplify -> $arr->{name}") if $ctx->{log};
				return $arr->{name};
			}
		    }
		}
		return $var;
	} elsif ($var =~ /^#obj\d+$/) {
		my ($o, $m) = @{$parser->{strmap}->{$var}};

		my ($inst, $prop) = $ctx->resolve_obj($var, $in_block);
		if (defined $inst) {
			my $instvar = inst_var($inst, '$'.$prop);

			my $basestr = $ctx->getvar($instvar);
			if (defined $basestr && ($basestr ne '#unresolved')) {
				return $basestr;
			}
			if ($m ne $prop) {
				my $k = $parser->setobj($o, $prop);
				$ctx->{log}->($ctx, 'exec', $var, "simplify partial -> $k") if $ctx->{log};
				return $k;
			}
		}
		return $var;
	} elsif ($var =~ /^#scope\d+$/) {
		my ($c, $e) = @{$parser->{strmap}->{$var}};

		my ($scope, $val) = $ctx->resolve_scope($var, $in_block);
		if (defined $scope) {
			if (is_variable($val)) {
				my $classvar = inst_var($scope, $val);

				my $basestr = $ctx->getvar($classvar);
				if (defined $basestr && ($basestr ne '#unresolved')) {
					return $basestr;
				}
				return $classvar;
			} elsif (is_symbol($val)) {
				my $name = method_name($scope, $val);

				if (exists $ctx->{defines}{$name}) {
					my $const = $ctx->{defines}{$name};
					$ctx->{log}->($ctx, 'exec', $var, "lookup const %s -> %s", $name, $const) if $ctx->{log};
					return $const;
				}
				return $name;
			}
			if ($c ne $scope) {
				if ($ctx->{incall} && ($c =~ /^(self|parent)$/)) {
					$ctx->{warn}->($ctx, 'exec', $var, "simplify $c -> $scope in function");
				}
				# only simplified call, no result
				my $k = $parser->setscope($scope, $e);
				$ctx->{log}->($ctx, 'exec', $var, "simplify partial -> $k") if $ctx->{log};
				return $k;
			}
		}
		return $var;
	} elsif ($var =~ /^#ns\d+$/) {
		my ($n, $e) = @{$parser->{strmap}->{$var}};

		my ($ns, $val) = $ctx->resolve_ns($var, $in_block);
		if (defined $ns) {
			if ($val =~ /^#class\d+$/) {
			} elsif ($val =~ /^#fun\d+$/) {
			} elsif (is_const($val)) {
				my $str = $parser->get_strval($val);
				my $name = ns_name(lc($ns), $str);
				my ($sym) = $name =~ /^\\(.*)$/; # remove toplevel

				if (defined $sym && exists $ctx->{defines}{$sym}) {
					my $const = $ctx->{defines}{$sym};
					$ctx->{log}->($ctx, 'exec', $var, "lookup const %s -> %s", $name, $const) if $ctx->{log};
					return $const;
				}
				return $name;
			} elsif (is_strval($val)) {
				my $str = $parser->get_strval($val);
				my $name = ns_name(lc($ns), $str);
				return $name;
			} elsif (is_symbol($val)) {
				my $name = ns_name(lc($ns), $val);
				my ($sym) = $name =~ /^\/(.*)$/;
				return $name;
			}
		}
		return $var;
	} elsif ($var =~ /^#elem\d+$/) {
		my ($v, $i) = @{$parser->{strmap}->{$var}};
		my $basevar = $v;
		my $basestr = $ctx->exec_statement($v, $in_block);
		my $idxstr = $i;

		if (is_null($basestr)) {
			$basestr = undef;
		}
		if (defined $i) {
			if (!is_strval($i) || is_const($i)) {
				$idxstr = $ctx->exec_statement($i);
			}
			if (defined $basestr) {
				my $g = $parser->globalvar_to_var($basestr, $idxstr);
				if (defined $g) {
					if ($ctx->{infunction}) {
						$g = global_var($g);
					}
					$basestr = $ctx->getvar($g);

					$ctx->{log}->($ctx, 'exec', $var, "getelem %s -> %s (%s)", $parser->stmt_str($var), $g, defined $basestr ? $basestr : '-') if $ctx->{log};

					if (defined $basestr && ($basestr eq '#unresolved')) {
						$basestr = undef;
					}
					if (defined $basestr) {
						return $ctx->exec_statement($basestr);
					}
					return $g; # return simplified global var
				} elsif ($ctx->is_superglobal($basestr)) {
					$basevar = $basestr;
					my $val = $ctx->getvar($basestr);
					if (defined $val) {
						$basestr = $val;
					}
				} elsif (is_variable($basestr)) {
					if ($basestr eq $basevar) { # getvar() failed
						$basestr = $ctx->getvar($basevar);
					} else {
						$basevar = $basestr;
					}
				} elsif ($basestr =~ /^#elem\d+$/) {
					$basevar = $basestr;
				}
			}
		}
		$ctx->{log}->($ctx, 'exec', $var, "getelem %s -> %s[%s] (%s)", $parser->stmt_str($var), $basevar, defined $idxstr ? $idxstr : '-', defined $basestr ? $basestr : '-') if $ctx->{log};

		if (defined $basestr && ($basestr eq '#unresolved')) {
			$ctx->{warn}->($ctx, 'exec', $var, "getelem %s[%s] is unresolved", $basevar, defined $i ? $i : '');
		} elsif (defined $basestr && is_strval($basestr) && !is_null($basestr) && defined $idxstr && is_strval($idxstr)) { # TODO: is_numeric() for undefined vars?
			my $baseval = $parser->get_strval($basestr);
			my $pos = $parser->get_strval($idxstr);

			# todo: $pos might be non-numeric array-key here
			#
			if ($pos =~ /^[\d\.]+$/) {
				$pos = int($pos);
				if ($pos >= length($baseval)) {
					# array out of range maps to empty string
					# todo: support string access via brackets: $str{4}
					#
					$ctx->{warn}->($ctx, 'exec', $var, "get array index out of range %d (%d): %s", $pos, length($baseval), $baseval);
					# just allow off-by-one errors for now to avoid endless loops
					#
					if ($pos == length($baseval)) {
						my $ch = '';
						return $parser->setstr($ch);
					}
				} else {
					my $ch = substr($baseval, $pos, 1);
					my $k = $parser->setstr($ch);
					$ctx->{log}->($ctx, 'exec', $var, "getelem %s[%s] = %s", $basestr, $pos, $ch) if $ctx->{log};
					return $k;
				}
			}
		} elsif (defined $basestr && is_array($basestr) && defined $idxstr) {
			my $arr = $parser->{strmap}{$basestr};
			$idxstr = $parser->setstr('') if is_null($idxstr); # null maps to '' array index
			my $arrval = $arr->get($idxstr);
			if (defined $arrval) {
				$ctx->{log}->($ctx, 'exec', $var, "getelem %s[%s] = %s[%s]", $basevar, $idxstr, $basestr, $arrval) if $ctx->{log};
				return $arrval;
			}
		} elsif (!(exists $ctx->{skip}{null}) && !defined $basestr && (!$ctx->is_superglobal($basevar) || ($basevar =~ /^\$GLOBALS$/))) {
			unless ($ctx->{tainted}) {
				$ctx->{warn}->($ctx, 'exec', $var, "getelem %s[%s] not found -> #null", $basevar, defined $i ? $i : '');
				return '#null';
			}
		}
		# simplify elem expression
		# (don't simplify $GLOBAL[..] references when parsing function)
		#
		if (exists $ctx->{simplify}{elem}) {
			if (defined $i) {
				if (($v ne $basevar) || ($i ne $idxstr)) {
					my $k = $parser->setelem($basevar, $idxstr);
					$ctx->{log}->($ctx, 'exec', $var, "simplify %s -> %s[%s]", $parser->stmt_str($var), $basevar, $idxstr) if $ctx->{log};
					return $k;
				}
			}
		}
		return $var;
	} elsif ($var =~ /^#expr\d+$/) {
		my ($op, $v1, $v2) = @{$parser->{strmap}->{$var}};
		my $op2;

		if (($op eq '=') && defined $v2) {
			my $vv1 = $v1;

			if ($v1 =~ /^#obj\d+$/) {
				my ($inst, $prop) = $ctx->resolve_obj($v1, $in_block);
				if (defined $inst) {
					my $instvar = inst_var($inst, '$'.$prop);
					$ctx->{log}->($ctx, 'exec', $var, "assign to var $v1 -> resolved to instvar $instvar") if $ctx->{log};
					$vv1 = $instvar;
				}
			}
			if ($v1 =~ /^#scope\d+$/) {
				my ($scope, $val) = $ctx->resolve_scope($v1, $in_block);
				if (defined $scope && is_variable($val)) {
					my $classvar = inst_var($scope, $val);
					$ctx->{log}->($ctx, 'exec', $var, "assign to var $v1 -> resolved to classvar $classvar") if $ctx->{log};
					$vv1 = $classvar;
				}
			}
			if ($v1 =~ /^#expr\d+$/) {
				# calc variable name (a.e: ${ $var })
				#
				my $basevar = $ctx->resolve_varvar($v1, $in_block);
				if (defined $basevar && ($basevar ne $v1)) {
					$ctx->{log}->($ctx, 'exec', $var, "assign to var $v1 -> resolved to varvar $basevar") if $ctx->{log};
					$vv1 = $basevar;
				}
			}
			# don't simplify #obj variable to $#inst\d+$var
			#
			my $vv1_sim = is_instvar($vv1) ? $v1 : $vv1;

			if (defined $v2) {
				# always track variables here for statements like '$a = $b = 1'
				#
				$op2 = $ctx->exec_statement($v2);
			}
			if (is_variable($vv1)) {
				if (defined $op2 && ($op2 =~ /^#ref\d+$/)) {
					my $v = $parser->{strmap}->{$op2}->[0];

					# reference operator sets variable alias
					# (-> undo alias by unset($vv1) or by assignment of another reference)
					#	
					$ctx->{varmap}{ref}{$vv1} = [$ctx, $v];
					$ctx->{log}->($ctx, 'setref', $vv1, "references $v now") if $ctx->{log};
				} elsif (defined $v2 && ($v2 =~ /^\$GLOBALS$/)) {
					# $var = $GLOBALS assignment is always equal to reference (but not superglobals)
					# https://php.net/manual/en/reserved.variables.globals.php
					#
					$ctx->{varmap}{ref}{$vv1} = [$ctx, $v2];
					$ctx->{log}->($ctx, 'setref', $vv1, "implicitly references GLOBALS now") if $ctx->{log};
				} elsif (defined $v2 && $ctx->is_superglobal($v2)) {
					# other superglobal assignments work only on a copy of the array
					# - returns 1: $_POST['a']=1; $x=$_POST; echo $x['a'];
					# - returns null: $x=$_POST; $_POST['a']=1; echo $x['a'];
					# - returns 1: $x=$_POST; $x['a']=1; echo $x['a'];
					# - returns null: $x=$_POST; $x['a']=1; echo $_POST['a'];
					# - returns null: $x["a"]="b"; $x=$_POST; echo $_POST["a"];
					# but normal reference work:
					# - returns 1 $x=&$_POST; $x["a"]=1; echo $_POST["a"];
					#
					# Note: The resulting code should track superglobal derefences,
					#       so handle them like $GLOBALS for now.
					#
					my $a = $ctx->getvar($v2);
					if (defined $a && is_array($a)) {
						my $arr = $parser->{strmap}{$a};
						$arr = $arr->copy();
						my $a2 = $arr->{name};
						$ctx->{log}->($ctx, 'setref', $vv1, "copy defined superglobal $v2 -> $a") if $ctx->{log};
						$ctx->setvar($vv1, $a2, $in_block);
						return $parser->setexpr('=', $vv1_sim, $a2);
					} else {
						#$ctx->setvar($vv1, $v2, $in_block);
						$ctx->setvar($vv1, '#unresolved', $in_block);
						$op2 = $v2;
						$ctx->{log}->($ctx, 'setref', $vv1, "keep undefined superglobal $v2") if $ctx->{log};
					}
				} elsif ($ctx->is_unresolved_assignment($op2)) {
					# mark variable as unresolved if rhs is not resolvable
					#
					$ctx->setvar($vv1, '#unresolved', $in_block);
					if ($in_block || !exists $ctx->{varhist}) {
						$ctx->{log}->($ctx, 'exec', $var, "assign to var $vv1 = $op2 -> #unresolved") if $ctx->{log};
						if (($v1 ne $vv1_sim) || ($v2 ne $op2)) {
							return $parser->setexpr('=', $vv1_sim, $op2);
						}
						return $var;
					}
					$ctx->{log}->($ctx, 'exec', $var, "assign to var $vv1 = $op2 -> #unresolved [TRACK]") if $ctx->{log};
					$ctx->track_assignment($vv1, $op2);
					return $vv1;
				} elsif (is_block($op2)) {
					# this might be a create_function() assignment returning a
					# block with multiple elements.
					# convert '$var = { #fun; #stmt }' to '{ $var = #fun; #stmt }'
					#
					my ($type, $a) = @{$parser->{strmap}->{$op2}};
					if (scalar @$a > 0) {
						$ctx->setvar($vv1, $a->[0], $in_block);
						my $k = $parser->setexpr('=', $vv1_sim, $a->[0]);
						my $b = $parser->setblk('flat', [$k, @$a[1..@$a-1]]);
						$ctx->{log}->($ctx, 'exec', $var, "assign to var $vv1 = $op2 -> converted to block $k") if $ctx->{log};
						return $b;
					} else {
						$ctx->{log}->($ctx, 'exec', $var, "assign to var %s = %s -> %s (block)", $vv1, $v2, $op2) if $ctx->{log};
						$ctx->setvar($vv1, $op2, $in_block);
					}
				} else {
					$ctx->{log}->($ctx, 'exec', $var, "assign to var %s = %s -> %s", $vv1, $v2, $op2) if $ctx->{log};
					$ctx->setvar($vv1, $op2, $in_block);
				}
				if ($in_block) {
					if (($v1 ne $vv1_sim) || ($v2 ne $op2)) {
						return $parser->setexpr('=', $vv1_sim, $op2);
					}
				} else {
					return $op2;
				}
			} elsif ($v1 =~ /^#elem\d+$/) {
				my ($v, $i) = @{$parser->{strmap}->{$v1}};
				my $elemlist = $ctx->get_baseelem($v1, $in_block);
				my $basevar = $elemlist->[0];
				my $basestr;
				my $baseidx;
				my $idxstr;
				my $has_index;
				my $parent;

				if ($basevar =~ /^(\#elem\d+)$/) {
					($basevar, $baseidx) = @{$parser->{strmap}->{$basevar}};
					($parent, $basestr, $basevar) = $ctx->create_basearray($elemlist, $in_block);
					$has_index = 1;
				} else {
					$has_index = 0; # conversion '$GLOBALS[x] -> $x'
					$parent = $basevar;
					$basestr = $ctx->exec_statement($basevar, $in_block);
				}
			
				if (defined $basestr && is_null($basestr)) {
					$basestr = undef;
				}
				if (defined $basestr && ($basestr eq '#unresolved')) {
					$basestr = undef;
				}
				if (defined $i) {
					$idxstr = $ctx->exec_statement($i);
				}

				if (defined $basevar) {
					$ctx->{log}->($ctx, 'exec', $var, "assign to elem $v1 %s (%s[%s]) = %s (%s) -> resolved elem-parent: %s elem-val: %s", $parser->stmt_str($v1), $basevar, defined $idxstr ? $idxstr : '-', $v2, $op2, defined $parent ? $parent : '-', defined $basestr ? $basestr : '-') if $ctx->{log};

					if (!$has_index) {
						if ($ctx->is_unresolved_assignment($op2)) {
							$ctx->setvar($basevar, "#unresolved", $in_block);
						} else {
							$ctx->setvar($basevar, $op2, $in_block);
						}
						return $parser->setexpr('=', $basevar, $op2);
					} elsif (defined $basestr && is_strval($basestr) && !is_null($basestr) && defined $idxstr) {
						if (is_strval($op2)) {
							# also allowed to change chars past end of string
							# (changing an empty '' string should silently allocate
							# an array variable)
							# https://php.net/manual/en/language.types.string.php
							#
							my $str = $parser->{strmap}->{$basestr};
							my $pos = $parser->{strmap}->{$idxstr};
							my $ch = $parser->{strmap}->{$op2};

							# todo: $pos might be non-numeric array-key here
							#
							eval { substr($str, $pos, 1) = $ch; };
							if ($@) {
								$ctx->{warn}->($ctx, 'exec', $var, "assign to elem $v1: bad set substr(%s, %s, 1) = %s", $str, $pos, $ch);
							}
							my $k = $parser->setstr($str);
							$ctx->setvar($v, $k, $in_block);

							$ctx->{log}->($ctx, 'exec', $var, "assign to elem $v1: setstr %s [%s] (%s, %s) = %s -> %s", $basevar, $parent, $pos, $ch, $str, $k) if $ctx->{log};
							return $parser->setexpr('=', $v, $k);
						}
					} elsif (!defined $basestr || is_array($basestr)) {
						if (defined $basestr) {
						    my $arr = $parser->{strmap}{$basestr};
						    if (!defined $idxstr) {
							# $arr[] = val - appends at end of array
							#
							if ($ctx->is_unresolved_assignment($op2)) {
								# mark variable as unresolved if rhs is not resolvable
								#
								$ctx->setvar($basevar, '#unresolved', $in_block);
								$arr->set(undef, $v2);
								$ctx->{log}->($ctx, 'exec', $var, "assign to elem $v1 set: %s[] = %s -> #unresolved", $v, $op2) if $ctx->{log};
							} else {
								$arr->set(undef, $op2);
								$ctx->{log}->($ctx, 'exec', $var, "assign to elem $v1 set: %s[] = %s", $v, $op2) if $ctx->{log};
							}
						    } elsif (is_strval($idxstr)) {
							my $key = $idxstr;
							if ($ctx->is_unresolved_assignment($op2)) {
								$ctx->setvar($basevar, '#unresolved', $in_block);
								$arr->set($key, $v2);
								$ctx->{log}->($ctx, 'exec', $var, "assign to elem $v1 set: %s[%s] = %s -> #unresolved", $v, $idxstr, $v2) if $ctx->{log};
							} elsif (is_null($idxstr)) {
								$key = $parser->setstr(''); # null maps to '' array index
								$arr->set($key, $op2);
								$ctx->{log}->($ctx, 'exec', $var, "assign to elem $v1 set: %s[null] = %s", $v, $op2) if $ctx->{log};
							} else {
								$arr->set($key, $op2);
								$ctx->{log}->($ctx, 'exec', $var, "assign to elem $v1 set: %s[%s] = %s", $v, $idxstr, $op2) if $ctx->{log};
							}
						    }
						} else {
							if ($ctx->is_unresolved_assignment($op2)) {
								$ctx->setvar($basevar, '#unresolved', $in_block);
							}
						}

						# keep the index-syntax instead of an array assignment.
						# -> $x['a']['b'] = 'foo' versus $x['a'] = array('b' => 'foo')
						#
						if (exists $ctx->{simplify}{expr}) {
							my $op1 = $v1;
							if (($v ne $parent) || (defined $idxstr && ($i ne $idxstr))) {
								# don't simplify obj-var to inst-var here
								#
								if (!is_instvar($parent) && !is_instvar($basevar)) {
									$op1 = $parser->setelem($parent, $idxstr);
								}
							}
							if ($in_block || !exists $ctx->{varhist}) {
								if (($v1 ne $op1) || ($v2 ne $op2)) {
									my $k = $parser->setexpr('=', $op1, $op2);
									$ctx->{log}->($ctx, 'exec', $var, "simplify assign to elem $v1 %s ($op1) = $v2 ($op2) -> $k (stmt)", $parser->stmt_str($v1)) if $ctx->{log};
									return $k;
								}
								return $var;
							}

							# track elem assignments in expressions
							#
							if (($v1 ne $op1) || ($v2 ne $op2)) {
								$ctx->{log}->($ctx, 'exec', $var, "simplify assign to elem $v1 %s ($op1) = $v2 -> $op2 [TRACK]", $parser->stmt_str($v1)) if $ctx->{log};
							} else {
								$ctx->{log}->($ctx, 'exec', $var, "assign to elem $v1 = $v2 -> $v2 [TRACK]") if $ctx->{log};
							}
							$ctx->track_assignment($op1, $op2);

							if (is_strval($op2) || is_array($op2)) {
								return $op2;
							}
							return $op1;
						}
						return $var;
					}
				}
				$ctx->{warn}->($ctx, 'exec', $var, "assign to elem $v1: %s not found", $parser->stmt_str($v1));
			} elsif ($v1 =~ /^#arr\d+$/) {
				# list($a,$b) = array(..)
				#
				my $arr_d = $parser->{strmap}{$v1};
				my $keys_d = $arr_d->get_keys();

				my $arr_s;
				if (is_array($op2)) {
					$arr_s = $parser->{strmap}{$op2};
				} elsif (is_strval($op2)) {
					# string or null list assignment sets all values to null
					$arr_s = $parser->newarr();
				}
				if (defined $arr_s) {
					my $keys_s = $arr_s->get_keys();
					my $newarr = $parser->newarr();
					foreach my $k (@$keys_d) {
						my $dst = $arr_d->val($k);
						next if (!defined $dst);
						my $src = $arr_s->get($k);
						if (defined $src) {
							if (is_variable($dst)) {
								if ($ctx->is_unresolved_assignment($src)) {
									$ctx->setvar($dst, '#unresolved', $in_block);
									$ctx->{warn}->($ctx, 'exec', $var, "set array key $k ($dst) is unref");
								} else {
									$ctx->setvar($dst, $src, $in_block);
								}
							} elsif ($dst =~ /^#elem\d+$/) {
								my ($v, $i) = @{$parser->{strmap}{$dst}};
								$ctx->{log}->($ctx, 'exec', $var, "assign to array $v1 = $op2 -> key $k ($dst) is elem") if $ctx->{log};

								my $sub = $parser->setexpr('=', $dst, $src);
								my $had_assigns = $ctx->have_assignments();
								$src = $ctx->exec_statement($sub);
								if (!$had_assigns) {
									# remove any pending assignments, to avoid variable
									# insertion for the 'sub'-assignmenmt.
									# The full array assignment is inserted after the loop
									#
									$ctx->discard_pending_assignments();
								}
							}
							$newarr->set($k, $src);
						}
					}
					if ($in_block || !exists $ctx->{varhist}) {
						if (($v2 ne $op2)) {
							my $k = $parser->setexpr('=', $v1, $op2);
							$ctx->{log}->($ctx, 'exec', $var, "simplify assign to array $v1 = $v2 ($op2) -> $k") if $ctx->{log};
							return $k;
						}
						return $var;
					}
					return $newarr->{name};
				}
			}
			if (exists $ctx->{simplify}{expr}) {
				if ($v1 =~ /^#elem\d+$/) {
					$vv1 = $ctx->exec_statement($v1, $in_block);
					if (!$ctx->is_superglobal($vv1)) {
						if (!is_variable($vv1) && !($vv1 =~ /^#elem\d+$/)) {
							$vv1 = $v1;
						}
					}
					$vv1_sim = $vv1;
				}

				if (($v1 ne $vv1_sim) || ($v2 ne $op2)) {
					# simplify expr
					#
					my $k = $parser->setexpr('=', $vv1_sim, $op2);
					$ctx->{log}->($ctx, 'exec', $var, "simplify assign to $v1 ($vv1_sim) = $v2 ($op2) -> $k") if $ctx->{log};
					return $k;
				}
			}
			return $var;
		}
		my $op1;

		if (defined $v1) {
			if ($v1 =~ /^#stmt\d+$/) {
				$ctx->{warn}->($ctx, 'exec', $var, "first op $v1 is no expr");
				$op1 = $v1;
			} else {
				$op1 = $ctx->exec_statement($v1, $in_block);
			}
		}
		if (!defined $v1 && defined $v2 && ($op eq 'new')) {
			if ($v2 =~ /^#call\d+$/) {
				my ($name0, $arglist) = @{$parser->{strmap}->{$v2}};

				# new class()
				# - class properties are initialized when exec(#class) is called
				#
				my ($args, $arg_changed) = $ctx->resolve_arglist($arglist, [], $in_block);
				my $name = lc($name0);

				$name = $ctx->add_namespace($name);

				my $class = $ctx->getclass($name);
				if (defined $class && exists $ctx->{varmap}{inst}{$name}) {
					my ($n, $b, $p) = @{$parser->{strmap}->{$class}};
					my $ctx2 = $ctx;

					$ctx->{log}->($ctx, 'new', $v2, "found class $class") if $ctx->{log};

					# create class instance
					#
					my $c2 = $v2;
					if ($arg_changed) {
						my @argssim = map { ($args->[$_] =~ /^(#inst\d+)$/) ? $arglist->[$_] : $args->[$_] } 0..$#$args;
						$c2 = $parser->setcall($name0, \@argssim);
					}
					my $inst = $parser->setinst($class, $c2, $ctx2);
					$ctx2->{varmap}{inst}{$inst} = {}; # init instance var map

					$ctx->{log}->($ctx, 'new', $v2, "clone inst vars [%s]", join(', ', keys %{$ctx2->{varmap}{inst}{$name}})) if $ctx->{log};

					# initialize instance vars with class properties
					#
					my %varmap = %{$ctx->{varmap}};
					$ctx2->{varmap}{inst}{$inst} = {%{$ctx2->{varmap}{inst}{$name}}}; # copy class var map

					# initialize instance methods class functions
					#
					my ($type, $memlist) = @{$parser->{strmap}->{$b}};
					foreach my $m (@$memlist) {
						if ($m =~ /^#fun\d+$/) {
							my ($f, $a, $b, $p) = @{$parser->{strmap}->{$m}};
							if (defined $f && is_symbol($f)) {
								my $instvar = method_name($inst, lc($f)); # inst var default is class func
								my $classfunc = method_name($name, lc($f));
								$ctx2->{varmap}{inst}{$inst}{lc($f)} = $classfunc;
								$ctx->{log}->($ctx, 'new', $v2, "init inst func $instvar -> $classfunc") if $ctx->{log};
							}
						}
					}

					# constructor returns void
					#
					my $init = method_name($inst, '__construct');
					my $f = $ctx2->getfun($init);
					if (!defined $f) {
						# try old-style constructor (prior php80)
						my $init2 = method_name($inst, $name);
						$f = $ctx2->getfun($init2);
						if (defined $f) {
							$ctx->{log}->($ctx, 'new', $v2, "found oldstyle constructor $name") if $ctx->{log};
							$init = $init2;
						}
					}
				        if (defined $f) {
						my $c = $parser->setcall($init, $arglist);
						my $k = $ctx2->exec_statement($c);
						# ignore void result
					}
					return $inst;
				}
				unless ($ctx->{incall}) {
					if (exists $ctx->{simplify}{stmt}) {
						if ($arg_changed) {
							my @argssim = map { ($args->[$_] =~ /^(#inst\d+)$/) ? $arglist->[$_] : $args->[$_] } 0..$#$args;
							my $c2 = $parser->setcall($name0, \@argssim);
							if ($v2 ne $c2) {
								my $k = $parser->setexpr('new', undef, $c2);
								$ctx->{log}->($ctx, 'new', $v2, "simplify -> $k") if $ctx->{log};
								return $k;
							}
						}
			    		}
				}
			}
		} elsif (!defined $v1 && defined $v2) {
			$op2 = $ctx->exec_statement($v2, $in_block);

			if ($op eq '$') {
				my $var1 = $parser->varvar_to_var($op2);
				if (defined $var1) {
					return $ctx->exec_statement($var1);
				}
				if (exists $ctx->{simplify}{expr}) {
				    if (is_variable($op2) && ($v2 ne $op2)) {
					# simplify expr
					#
					my $k = $parser->setexpr($op, undef, $op2);
					$ctx->{log}->($ctx, 'exec', $var, "simplify varvar $v2 ($op2) -> $k") if $ctx->{log};
					return $k;
				    }
				}
			} elsif ((($op eq '--') || ($op eq '++')) && is_variable($v2)) {
				# ++$var
				# --$var
				#
				if (is_strval($op2)) {
					my ($val, $result) = PHP::Decode::Op::unary($parser, $op, $op2);

					if (defined $val) {
						$ctx->{log}->($ctx, 'exec', $var, "%s %s -> %s = %s", $op, $op2, $val, $result) if $ctx->{log};

						my $k = $parser->setexpr('=', $v2, $val);
						my $res = $ctx->exec_statement($k, $in_block);
						return $res;
					}
				} else {
					# remove from varmap to avoid later simplification
					#
					$ctx->setvar($v2, '#unresolved', $in_block);
				}
			} else {
				if (is_strval($op2) || is_array($op2)) {
					my ($k, $result) = PHP::Decode::Op::unary($parser, $op, $op2);
					if (defined $k) {
						$ctx->{log}->($ctx, 'exec', $var, "%s %s -> %s = %s", $op, $op2, $k, $result) if $ctx->{log};
						return $k;
					} else {
						$ctx->{warn}->($ctx, 'exec', $var, "%s %s -> failed", $op, $op2);
					}
				}
			}
			if (exists $ctx->{simplify}{expr}) {
				if (is_instvar($op2)) {
					$op2 = $v2;
				}
				if ($v2 ne $op2) {
					# simplify expr
					#
					my $k = $parser->setexpr($op, undef, $op2);
					$ctx->{log}->($ctx, 'exec', $var, "simplify unary $var: $op $v2 ($op2) -> $k") if $ctx->{log};
					return $k;
				}
			}
		} elsif (defined $v1 && is_strval($op1) && !defined $v2) {
			# $var++
			# $var--
			#
			if (is_strval($op1)) {
				my ($val, $result) = PHP::Decode::Op::unary($parser, $op, $op1);
				if (defined $val) {
					$ctx->{log}->($ctx, 'exec', $var, "%s %s -> %s = %s", $op1, $op, $val, $result) if $ctx->{log};

					my $k = $parser->setexpr('=', $v1, $val);
					my $res = $ctx->exec_statement($k, $in_block);

					# if assignment is tracked, return old value instead
					# of new value here.
					#
					if (defined $res && ($res !~ /^#expr\d+$/)) {
						$res = $op1;
					}
					return $res;
				}
			} else {
				# remove from varmap to avoid later simplification
				#
				$ctx->setvar($v1, '#unresolved', $in_block);
			}
		} elsif (defined $v1 && defined $v2) {
			if ($v1 =~ /^#stmt\d+$/) {
				$ctx->{warn}->($ctx, 'exec', $var, "second op $v2 is no expr");
				$op2 = $v2;
			} else {
				if (!$in_block && (($op eq '||') || ($op eq 'or') || ($op eq '&&') || ($op eq 'and') || ($op eq '?') || ($op eq ':'))) {
					$ctx->{log}->($ctx, 'exec', $var, "set in_block for lazy or ordered evaluation") if $ctx->{log};
					$in_block = 1;
				}
				$op2 = $ctx->exec_statement($v2, $in_block);
			}

			if ((is_strval($op1) || is_array($op1)) && (is_strval($op2) || is_array($op2))) {
				if (($op ne '?') && ($op ne ':')) {
					my ($k, $result) = PHP::Decode::Op::binary($parser, $op1, $op, $op2);
					if (defined $k) {
						$ctx->{log}->($ctx, 'exec', $var, "%s %s %s -> %s", $op1, $op, $op2, $k) if $ctx->{log};
						return $k;
					} else {
						$ctx->{warn}->($ctx, 'exec', $var, "%s %s %s -> failed", $op1, $op, $op2);
					}
				}
			} elsif ($op eq '?') {
				if ((is_strval($op1) || is_array($op1)) && ($op2 =~ /^#expr\d+$/) && ($parser->{strmap}->{$op2}->[0] eq ':')) {
					# ternary: $expr1 ? $expr2 : $expr3
					#          represented as [$op1 ? [$op2 : $op3]]
					#
					my $val = $parser->{strmap}{$op1};
					if (is_array($op1)) {
						my $arr = $parser->{strmap}{$op1};
						$val = !$arr->empty();
					}
					my $k;
					if ($val) {
						$k = $ctx->exec_statement($parser->{strmap}->{$op2}->[1]);
					} else {
						$k = $ctx->exec_statement($parser->{strmap}->{$op2}->[2]);
					}
					return $k;
				}
			} elsif (($op eq '===') && ($op1 eq '#null')) {
				my $k = PHP::Decode::Func::exec_cmd($ctx, 'is_null', [$op2]);
				if (defined $k) {
					return $k;
				}
			} elsif (($op eq '===') && ($op2 eq '#null')) {
				my $k = PHP::Decode::Func::exec_cmd($ctx, 'is_null', [$op1]);
				if (defined $k) {
					return $k;
				}
			} elsif (($op eq '==') && ($op1 eq '#null')) {
				my $k = PHP::Decode::Func::exec_cmd($ctx, 'is_null_weak', [$op2]);
				if (defined $k) {
					return $k;
				}
			} elsif (($op eq '==') && ($op2 eq '#null')) {
				my $k = PHP::Decode::Func::exec_cmd($ctx, 'is_null_weak', [$op1]);
				if (defined $k) {
					return $k;
				}
			}

			if (exists $ctx->{simplify}{expr}) {
				if (is_instvar($op1)) {
					$op1 = $v1;
				}
				if (is_instvar($op2)) {
					$op2 = $v2;
				}
				if (($v1 ne $op1) || ($v2 ne $op2)) {
					# simplify expr (no variable setting must occur)
					#
					my $k = $parser->setexpr($op, $op1, $op2);
					$ctx->{log}->($ctx, 'exec', $var, "simplify binary %s (%s) %s %s (%s) -> %s", $v1, $op1, $op, $v2, $op2, $k) if $ctx->{log};
					return $k;
				}
			}
		}
		return $var;
	} elsif ($var =~ /^#call\d+$/) {
		my ($name, $arglist) = @{$parser->{strmap}->{$var}};
		my $cmd = $name;
		my $cmdsim = $name;

		if (is_variable($name) || ($name =~ /^#elem\d+$/) || ($name =~ /^#expr\d+$/) || ($name =~ /^#stmt\d+$/) || is_block($name)) {
			my $s = $ctx->exec_statement($name);
			if ($s =~ /^#fun\d+$/) {
				$cmd = $s;
				$cmdsim = $s;
			} elsif (!is_null($s)) {
				if (is_strval($s)) {
					$cmd = $parser->{strmap}->{$s};
				} else {
					$cmd = $s;
				}
				$cmdsim = $cmd;
			}
			$ctx->{log}->($ctx, 'exec', $var, "map %s (%s) -> %s", $name, $s, $cmd) if $ctx->{log};
		} elsif ($name =~ /^#obj\d+$/) {
			my ($inst, $prop) = $ctx->resolve_obj($name);
			if (defined $inst) {
				if (is_symbol($prop)) {
					$cmd = method_name($inst, $prop);
				} else {
					my ($o, $m) = @{$parser->{strmap}->{$name}};
					if ($m ne $prop) {
						$cmdsim = $parser->setobj($o, $prop);
						$ctx->{log}->($ctx, 'exec', $var, "obj simplify partial $name: -> $cmdsim") if $ctx->{log};
					}
				}
			}
			$ctx->{log}->($ctx, 'exec', $var, "map obj %s -> %s", $name, $cmd) if $ctx->{log};
		} elsif ($name =~ /^#scope\d+$/) {
			my ($scope, $val) = $ctx->resolve_scope($name);
			if (defined $scope) {
				if (is_symbol($val)) {
					$cmd = method_name($scope, $val);
					$cmdsim = $cmd;
				}
			}
			$ctx->{log}->($ctx, 'exec', $var, "map scope %s -> %s", $name, $cmd) if $ctx->{log};
		} elsif ($name =~ /^#ns\d+$/) {
			my ($ns, $val) = $ctx->resolve_ns($name);
			if (defined $ns) {
				$cmd = $parser->ns_to_str($name);
				$cmdsim = $cmd;
			}
			$ctx->{log}->($ctx, 'exec', $var, "map ns %s -> %s", $name, $cmd) if $ctx->{log};
		} elsif (is_symbol($name)) {
			$cmd = $name;
			$cmdsim = $cmd;
		}

		# function passed by name, by reference or anonymous function
		#
		my $fun;
		$fun = $cmd if ($cmd =~ /^#fun\d+$/);
		unless (defined $fun) {
			my $ncmd = $ctx->add_namespace($cmd);
			$fun = $ctx->getfun($ncmd);
			if (defined $fun) {
				$cmd = $ncmd;
			}
		}
		if (defined $fun) {
			my $cmd1 = _is_wrapped_call($parser, $fun);
			if (defined $cmd1) {
				$ctx->{log}->($ctx, 'exec', $var, "map wrapped %s -> %s", $cmd, $cmd1) if $ctx->{log};
				$cmd = $cmd1;
				$cmdsim = $cmd1;
				$fun = $ctx->getfun($cmd);
			}
		}

		my $args = [];
		my $arg_changed = 0;

	        if (defined $fun) {
		    unless (exists $ctx->{skip}{call}) {
			my ($_name, $param, $block, $p) = @{$parser->{strmap}->{$fun}};

			($args, $arg_changed) = $ctx->resolve_arglist($arglist, $param, $in_block);

			my ($key, $code);
			if (exists $ctx->{with}{translate}) {
			    my $perl = $parser->translate_func($fun, undef, 0);
			    if (defined $perl) {
				$ctx->{log}->($ctx, 'exec', $var, "translated $fun -> $perl") if $ctx->{log};
				my $sub = eval($perl);
				if ($@) {
					$ctx->{warn}->($ctx, 'exec', $var, "eval $fun failed: $@");
				} else {
					if ((scalar @$args == 1) && is_strval($args->[0])) {
						my $val = $parser->{strmap}->{$args->[0]};
						my $res = eval { &$sub($val) };
						if ($@) {
							$ctx->{warn}->($ctx, 'exec', $var, "eval $fun ERR: %s", $@);
						} else {
							$ctx->{log}->($ctx, 'exec', $var, "eval $fun => %s", defined $res ? $res : 'undef') if $ctx->{log};
							if (defined $res) {
								#if ($res =~ /^[0-9][0-9\.]+$/) {
								if ($res =~ /^[0-9]+$/) {
									$key = $parser->setnum($res);
								} else {
									$key = $parser->setstr($res);
								}
								$code = '';
							}
						}
					}
				}
			    }
			}
			unless (defined $key) {
				($key, $code) = $ctx->exec_func($cmd, $args, $param, $block);
			}
			if (!defined $key) {
				my $info = $ctx->get_unresolved_info($cmd, defined $code ? $code : $block);

				unless (keys %{$info->{unresolved}}) {
					$ctx->{warn}->($ctx, 'func', $cmd, "%s executed (but no additional taint) (globals[%s])", defined $code ? 'partially' : 'not', join(' ', keys %{$info->{global_assigns}}));
					$ctx->set_globals_unresolved([keys %{$info->{global_assigns}}]);
					$key = '#notaint';
				} else {
					$ctx->{warn}->($ctx, 'func', $cmd, "%s executed (unresolved[%s] globals[%s])", defined $code ? 'partially' : 'not', join(' ', keys %{$info->{unresolved}}), join(' ', keys %{$info->{global_assigns}}));
				}
			}
			if (defined $key) {
				# register exposed funcs
				#
				if (defined $code) {
					if (is_block($code)) {
						my ($type, $a) = @{$parser->{strmap}->{$code}};
						register_funcs($a, $ctx, $parser);
					} else {
						register_funcs([$code], $ctx, $parser);
					}
				}
				if ($key ne '#construct') {
					my $name_changed = 0;
					if ($cmd ne $name) {
						# expand anonymous function if not variable in #call
						#
						if (($cmd =~ /^#fun\d+$/) && is_variable($name)) {
							$cmd = $name;
						} elsif (is_instvar($cmd)) {
							# don't simplify obj-var to inst-var here
							$cmd = $name;
						} else {
							$name_changed = 1;
						}
					}

					# insert simplified or anonymous function
					# (but keep calls in lazy evaluated expressions like '$x || f()')
					#
					my $c;
					my $v = '$'.'eval'.'$'.$cmd;
					#my $v = '$'.'call'.'$'.$cmd;
					if (defined $code && !$in_block) {
						$c = $code;
					} else {
						if ($name_changed || $arg_changed) {
							my @argssim = map { ($args->[$_] =~ /^(#inst\d+)$/) ? $arglist->[$_] : $args->[$_] } 0..$#$args;
							$c = $parser->setcall($cmdsim, \@argssim);
						} else {
							$c = $var;
						}
					}
					if ($key eq '#notaint') {
						$key = $c;
					} elsif ($in_block) {
						if ((is_strval($key) || is_array($key) || _anon_func_call($parser, $key)) && defined $code && $parser->is_empty_block($code)) {
							# keep simple key & ignore call if no code to inline is left
							$ctx->{log}->($ctx, 'exec', $var, "%s(%s) -> keep key $key and ignore empty code $code", $cmd, join(' , ', @$arglist)) if $ctx->{log};
						} else {
							$key = $c;
						}
					} else {
						$ctx->track_assignment($v, $c);

						# void functions return 'null'. If null is not assigned,
						# it will be removed in later flatten_block() calls.
						#
						if ($key eq '#noreturn') {
							$key = '#null';
						}
					}
				}
				if ($key eq '#construct') {
					# insert simplified anonymous function here
					#
					my $methodname = $ctx->lookup_method_name($cmd);
					if (defined $methodname) {
						my ($classname, $prop) = method_split($methodname);
						my $f;
						unless ($f = _anon_func_call($parser, $code)) {
							$f = $parser->setfun(undef, [], $code);
						}
						my $v = '$__'.$classname.'_'.'__construct';
						$ctx->track_assignment($v, $f); # always track this variable
					}
				}
				$ctx->{log}->($ctx, 'exec', $var, "%s(%s) -> %s [%s]", $cmd, join(' , ', @$arglist), $key, defined $code ? $code : '-') if $ctx->{log};
				return $key;
			} else {
				$ctx->set_tainted($var);
				$ctx->invalidate_arglist_refs($arglist, $param, $in_block);
			}
		    } else {
			$ctx->set_tainted($var);
		    }
	        } elsif ((lc($cmd) eq 'eval') && (scalar @$arglist == 1)) {
			($args, $arg_changed) = $ctx->resolve_arglist($arglist, [], $in_block);

			# linenum restarts with line 1 for each eval() and is increased
			# for each newline in evalstring (verified with php).
			# (the __FILE__ content keeps the same)
			#
			my $oldline = $parser->{strmap}->{'__LINE__'};
			$parser->{strmap}->{'__LINE__'} = 1;
			my $parser2 = $parser->subparser();
			my $ctx2 = $ctx->subctx(parser => $parser2, varhist => {});
			my $blk = $ctx2->parse_eval($args->[0]);
			my $key;
			if (defined $blk) { # might be non-string
				$key = $ctx2->exec_eval($blk);
			}
			$parser->{strmap}->{'__LINE__'} = $oldline;

			if (defined $key) {
				my $result = $parser->{strmap}->{$key};

				# eval returns concatted list of statements (as example a single #str)
				#
				$ctx->{log}->($ctx, 'eval', $var, "%s(%s) -> %s", $cmd, $arglist->[0], $key) if $ctx->{log};

				if (is_block($key)) {
					my ($type, $a) = @{$parser->{strmap}->{$key}};
					register_funcs($a, $ctx, $parser);
				} else {
					register_funcs([$key], $ctx, $parser);
				}

				my @seq = ();
				$parser->flatten_block($key, \@seq);
				my $r = _final_break($parser, $key, '(return)');
				if (defined $r) {
					my $arg = $parser->{strmap}->{$r}->[1];

					my $r2 = pop(@seq); # remove return statement from block
					if ($r ne $r2) {
						$ctx->{warn}->($ctx, 'eval', $var, "%s return mismatch $r != $r2", $parser->stmt_str($var));
					}
					if (scalar @seq > 0) {
						# insert simplified block without return here
						my $b = $parser->setblk('flat', [@seq]);
						my $v = '$eval$'.$var;
						$ctx->track_assignment($v, $b); # track special $eval variable
						$ctx->{log}->($ctx, 'eval', $var, "%s(%s) returns block %s [TRACK]", $cmd, $arglist->[0], $b) if $ctx->{log};
					} else {
						$ctx->{log}->($ctx, 'eval', $var, "%s(%s) returns %s", $cmd, $arglist->[0], $r) if $ctx->{log};
					}
					return $arg;
				}

				# keep eval() around unresolved assignments for output
				# (can't use $ctx->can_inline($key) here - local vars are valid).
				#
				my $resolved_eval = $ctx->can_inline_eval($key);

				if (!$resolved_eval && (scalar @seq == 1)) {
					my $k = $parser->setcall('eval', [$key]);
					$ctx->{log}->($ctx, 'eval', $var, "%s(%s) keep eval around return -> %s", $cmd, $arglist->[0], $key) if $ctx->{log};
					return $k;
				}

				if ($key ne '#null') {
					my $v = '$eval$x'.$var;
					$ctx->track_assignment($v, $key); # track special $eval variable
					$ctx->{log}->($ctx, 'eval', $var, "%s(%s) track last %s", $cmd, $arglist->[0], $key) if $ctx->{log};
					#$key = $parser->setblk('flat', []);
					$key = '#null'; 
				}
				return $key;
			}
			if (exists $ctx->{simplify}{call}) {
				if ($args->[0] =~ /^#call\d+$/) {
					# call without eval can not generate 'return <str>'
					my $name = $parser->{strmap}->{$args->[0]}->[0];

					if (!PHP::Decode::Func::func_may_return_string($name)) {
						my $v = '$eval$x'.$var;
						$ctx->track_assignment($v, $args->[0]); # track special $eval variable
						$ctx->{log}->($ctx, 'eval', $var, "%s(%s) track call $args->[0]", $cmd, $arglist->[0]) if $ctx->{log};
						return '#null'; 
					}
				}
			}
			$ctx->set_tainted($var); # eval() might always change variables
	        } elsif (($cmd eq 'assert') && (scalar @$arglist == 1)) {
			my $val = $arglist->[0];
			my $key = $ctx->exec_statement($val);

			if (is_strval($key)) {
				my $e = $parser->setcall('eval', [$val]);
				$key = $ctx->exec_statement($e);
			}
			return $key;
	        } else {
			if ($cmd =~ /^\\(.*)$/) {
				$cmd = $1; # remove absolute namespace
			}
			my $f = PHP::Decode::Func::get_php_func($cmd);

			if (defined $f && exists $f->{param}) {
				($args, $arg_changed) = $ctx->resolve_arglist($arglist, $f->{param}, $in_block);
			} else {
				($args, $arg_changed) = $ctx->resolve_arglist($arglist, [], $in_block);
			}
			my $key = PHP::Decode::Func::exec_cmd($ctx, $cmd, $args);
			if (defined $key) {
				$ctx->{log}->($ctx, 'cmd', $var, "%s(%s) -> %s = %s", $cmd, join(' , ', @$args), $key, $parser->shortstr($parser->get_strval_or_str($key), 60)) if $ctx->{log};

				if ($key eq '#noreturn') {
					$key = $var;
					if (($name ne $cmdsim) || $arg_changed) {
						my @argssim = map { ($args->[$_] =~ /^(#inst\d+)$/) ? $arglist->[$_] : $args->[$_] } 0..$#$args;
						$key = $parser->setcall($cmdsim, \@argssim);
						$ctx->{log}->($ctx, 'cmd', $var, "simplify %s -> %s = %s(%s)", $parser->stmt_str($var), $key, $cmdsim, join(' , ', @argssim)) if $ctx->{log};
		    			}
				}
				return $key;
			}
			if (defined $f) {
				if (exists $f->{param}) {
					$ctx->invalidate_arglist_refs($arglist, $f->{param}, $in_block);
				}
			} else {
				$ctx->{warn}->($ctx, 'cmd', $var, "not found %s(%s)", $cmd, join(', ', @$arglist));
			}
			if (PHP::Decode::Func::func_may_call_callbacks($cmd)) {
				$ctx->set_tainted($var);
			}
		}
	        # simplify function params for failed call
		#
		if (exists $ctx->{simplify}{call}) {
			if (is_instvar($cmdsim)) {
				$cmdsim = $name;
			}
			my @argssim = map { ($args->[$_] =~ /^(#inst\d+)$/) ? $arglist->[$_] : $args->[$_] } 0..$#$args;

			if (($name ne $cmdsim) || $arg_changed) {
				my $k = $parser->setcall($cmdsim, \@argssim);
				$ctx->{warn}->($ctx, 'exec', $var, "skip %s(%s) -> %s %s", $cmd, join(', ', @$arglist), $k, $parser->stmt_str($k));
				return $k;
			}
		}
	        $ctx->{warn}->($ctx, 'exec', $var, "skip %s(%s)", $cmd, join(', ', @$arglist));
		return $var;
	} elsif ($var =~ /^#blk\d+$/) {
		my ($type, $arglist) = @{$parser->{strmap}->{$var}};
		my @args = ();
		my $changed = 0;
		foreach my $p (@$arglist) {
			my $keep_assign = 0;

			if (($type ne 'brace') && ($type ne 'expr')) {
				my ($rhs, $lhs) = _var_assignment($parser, $p);
				if (defined $rhs || _is_increment_op($parser, $p)) {
					$ctx->{log}->($ctx, 'exec', $var, "keep assignment $p intact -> set in_block") if $ctx->{log};
					$keep_assign = 1;
				}
			}
			my $v = $ctx->exec_statement($p, $keep_assign ? 1 : $in_block);
			unless (defined $v) {
				last;
			}

			# insert assignments only in code blocks. Assigments
			# in expressions are inserted into the next outer block.
			#
			if (($type ne 'brace') && ($type ne 'expr')) {
				my $v1 = $ctx->insert_assignments($v);
				if ($v1 ne $v) {
					if (exists $ctx->{with}{optimize_block_vars}) {
						my @seq = ();
						$parser->flatten_block($v1, \@seq);
						$ctx->optimize_loop_var_list('exec', $var, \@args, \@seq);
					} else {
						$parser->flatten_block($v1, \@args);
					}
					$changed = 1;
				} else {
					$parser->flatten_block($v, \@args);
				}
			} else {
				$parser->flatten_block($v, \@args);
			}
			if ($p ne $v) {
				$changed = 1;
			}
			my $f = _final_break($parser, $v, '(break|continue|return)');
			if (defined $f) {
				if (scalar @args < scalar @$arglist) {
					$changed = 1;
				}
				last;
			}
		}
		# evaluate block to string or anonymous func if possible
		#
		if (scalar @args == 1 && (is_strval($args[0]) || ($args[0] =~ /^#fun\d+$/))) {
			$ctx->{log}->($ctx, 'exec', $var, "reduce: $arglist->[0] -> $args[0]") if $ctx->{log};
			return $args[0];
		}
		if ($changed) {
			$var = $parser->setblk($type, \@args);
		}
		return $var;
	} elsif ($var =~ /^#stmt\d+$/) {
		my $cmd = $parser->{strmap}->{$var}->[0];

		if ($cmd eq 'echo') {
			my $arglist = $parser->{strmap}->{$var}->[1];
			my @param = ();
			my $all_str = 1;
			my $changed = 0;

		    	foreach my $p (@$arglist) {
				if (!is_strval($p) || is_const($p)) {
					my $v = $ctx->exec_statement($p);
					push(@param, $v);
					if ($v ne $p) {
						$changed = 1;
					}
					unless (is_strval($v)) {
						$all_str = 0;
					}
				} else {
					push(@param, $p);
				}
			}
			# keep consts in simplified statement
			#
			my @paramsim = map { (is_const($arglist->[$_]) && !$parser->is_magic_const($arglist->[$_]) && !exists $ctx->{defines}{$parser->{strmap}{$arglist->[$_]}}) ? $arglist->[$_] : $param[$_] } 0..$#param;

			my $v = $parser->{strmap}->{$var};

			# echo echoes also non-quoted arguments (undefined constants propagate to string)
			# (keep them separated here if not all arguments could get resolved)
			#
			if ($all_str && (scalar @param > 1)) {
				my $res = join('', map { $parser->{strmap}->{$_} } @param);
				my $k = $parser->setstr($res);
				@param = ($k);
				$changed = 1;
			}
			unless ($ctx->{skipundef}) {
				if (exists $ctx->{globals} && exists $ctx->{globals}{stdout}) {
					if (exists $ctx->{globals}{stdout}{ob}) {
						push(@{$ctx->{globals}{stdout}{ob}}, @param);
					} else {
						push(@{$ctx->{globals}{stdout}{buf}}, @param);
					}
				}
			}
			if (exists $ctx->{simplify}{stmt}) {
				if ($changed) {
					if (scalar @paramsim > 1) {
						merge_str_list(\@paramsim, $parser);
					}
					my $k = $parser->setstmt(['echo', \@paramsim]);
					$ctx->{log}->($ctx, 'echo', $var, "simplify -> $k") if $ctx->{log};
					return $k;
				}
			}
			return $var;
		} elsif ($cmd eq 'print') {
			my $arg = $parser->{strmap}->{$var}->[1];
			my $v = $ctx->exec_statement($arg);

			unless ($ctx->{skipundef}) {
				if (exists $ctx->{globals} && exists $ctx->{globals}{stdout}) {
					if (exists $ctx->{globals}{stdout}{ob}) {
						push(@{$ctx->{globals}{stdout}{ob}}, $v);
					} else {
						push(@{$ctx->{globals}{stdout}{buf}}, $v);
					}
				}
			}
			if (exists $ctx->{simplify}{stmt}) {
				if ($v ne $arg) {
					my $k = $parser->setstmt(['print', $v]);
					$ctx->{log}->($ctx, 'print', $var, "simplify -> $k") if $ctx->{log};
					return $k;
				}
			}
			return $var;
		} elsif ($cmd eq 'global') {
			my $arglist = $parser->{strmap}->{$var}->[1];
			my @param = ();

			foreach my $v (@$arglist) {
				if (is_variable($v)) {
					if ($ctx->is_superglobal($v)) {
						$ctx->{log}->($ctx, 'global', $var, "ignore global superglobal $v") if $ctx->{log};
					} else {
						$ctx->{varmap}{global}{$v} = 1;
						$ctx->{log}->($ctx, 'global', $var, "set func var $v global") if $ctx->{log};
					}
				}
			}
			return $var;
		} elsif ($cmd eq 'static') {
			my $arglist = $parser->{strmap}->{$var}->[1];
			my @param = ();

			foreach my $v (@$arglist) {
				if (is_variable($v)) {
					if ($ctx->is_superglobal($v)) {
						$ctx->{log}->($ctx, 'static', $var, "ignore static superglobal $v") if $ctx->{log};
					} else {
						if ($ctx->{infunction}) {
							unless (exists $ctx->{varmap}{static}{$ctx->{infunction}}{$v}) {
								$ctx->{varmap}{static}{$ctx->{infunction}}{$v} = undef;
								$ctx->{log}->($ctx, 'static', $var, "set static func var $v") if $ctx->{log};
							}
						} elsif (exists $ctx->{class_scope}) {
							unless (exists $ctx->{varmap}{inst}{$ctx->{class_scope}}{$v}) {
								$ctx->{varmap}{inst}{$ctx->{class_scope}}{$v} = undef;
								$ctx->{log}->($ctx, 'static', $var, "set static class var $v") if $ctx->{log};
							}
						} else {
							$ctx->{log}->($ctx, 'static', $var, "ignore toplevel static var $v") if $ctx->{log};
						}
					}
				} elsif ($v =~ /^#expr\d+$/) {
					my ($op, $v1, $v2) = @{$parser->{strmap}->{$v}};
					if ($op eq '=') {
						if ($ctx->is_superglobal($v1)) {
							$ctx->{log}->($ctx, 'static', $var, "ignore static superglobal $v1") if $ctx->{log};
						} else {
							if ($ctx->{infunction}) {
								unless (exists $ctx->{varmap}{static}{$ctx->{infunction}}{$v1}) {
									$ctx->{varmap}{static}{$ctx->{infunction}}{$v1} = $v2;
									$ctx->{log}->($ctx, 'static', $var, "set static func var $v1 = $v2") if $ctx->{log};
								}
							} elsif (exists $ctx->{class_scope}) {
								unless (exists $ctx->{varmap}{inst}{$ctx->{class_scope}}{$v1}) {
									$ctx->{varmap}{inst}{$ctx->{class_scope}}{$v1} = $v2;
									$ctx->{log}->($ctx, 'static', $var, "set static class var $v1 = $v2") if $ctx->{log};
								}
							} else {
								$ctx->{log}->($ctx, 'static', $var, "ignore toplevel static var $v1") if $ctx->{log};
							}
						}
					} else {
						$ctx->{warn}->($ctx, 'static', $var, "bad init $v");
					}
				} else {
					my $k = $ctx->exec_statement($v, 1);
				}
			}
			return $var;
		} elsif ($cmd eq 'const') {
			my $arglist = $parser->{strmap}->{$var}->[1];
			my @param = ();

			foreach my $v (@$arglist) {
				if ($v =~ /^#expr\d+$/) {
					my ($op, $v1, $v2) = @{$parser->{strmap}->{$v}};

					if ($op eq '=') {
						unless (is_const($v1)) {
							$ctx->{warn}->($ctx, 'const', $var, "ignore non-const const $v1") if $ctx->{log};
						} elsif ($ctx->{infunction}) {
							$ctx->{warn}->($ctx, 'const', $var, "ignore in-function const $v1") if $ctx->{log};
						} else {
							my $name = $parser->{strmap}{$v1}; # consts are case-sensitive
							my $op2 = $ctx->exec_statement($v2, 1); # should be constant expression

							if (exists $ctx->{class_scope}) {
								$name = method_name($ctx->{class_scope}, $name);
							}
							if ($ctx->{namespace}) {
								$name = ns_name(lc($ctx->{namespace}), $name);
							}
							$ctx->{defines}{$name} = $op2;
							$ctx->{log}->($ctx, 'const', $var, "set const $name = $op2") if $ctx->{log};
						}
					} else {
						$ctx->{warn}->($ctx, 'const', $var, "bad const expr $v");
					}
				} else {
					$ctx->{warn}->($ctx, 'const', $var, "bad const statement $v");
				}
			}
			return $var;
		} elsif ($cmd eq 'return') {
			my $arg = $parser->{strmap}->{$var}->[1];
			my $res = $ctx->exec_statement($arg);
			if (defined $res && ($arg ne $res)) {
				my $k = $parser->setstmt(['return', $res]);
				return $k;
			}
			return $var;
		} elsif ($cmd eq 'unset') {
			# https://www.php.net/manual/en/function.unset.php
			#
			my $arglist = $parser->{strmap}->{$var}->[1];
			my @param = ();
			my $all_var = 1;
			my $changed = 0;

			foreach my $p (@$arglist) {
				if (is_variable($p)) {
					if (exists $ctx->{varmap}{$p}) {
						$ctx->{log}->($ctx, 'unset', $var, "unset $p") if $ctx->{log};
					} else {
						$ctx->{log}->($ctx, 'unset', $var, "unset undefined $p") if $ctx->{log};
					}
					$ctx->setvar($p, '#null', 1);
					push(@param, $p);
					next;
				} elsif ($p =~ /^(\#elem\d+)$/) {
					# todo: suppport multi dimensional
					#
					my ($v, $i) = @{$parser->{strmap}->{$p}};
					my ($basevar, $has_index, $idxstr) = $ctx->resolve_variable($p, 0);
					if (defined $basevar) {
					    if ($has_index) {
						my $basestr = $ctx->exec_statement($basevar, 0);
						if (defined $basestr && is_array($basestr) && defined $idxstr) {
							my $arr = $parser->{strmap}->{$basestr};
							$idxstr = $parser->setstr('') if is_null($idxstr); # null maps to '' array index
							my $arrval = $arr->get($idxstr);
							if (defined $arrval) {
								my $idxval = $arr->get_index($idxstr);
								$ctx->{log}->($ctx, 'unset', $var, "unset elem $p: %s %s[%s]", $basevar, $basestr, $idxstr) if $ctx->{log};
								my $arr2 = $arr->copy();
								$arr2->delete($idxval);
								$ctx->setvar($basevar, $arr2->{name}, 1);
							}
						} else {
							$ctx->{log}->($ctx, 'unset', $var, "unset undefined elem $p") if $ctx->{log};
						}
					    } else {
						if (exists $ctx->{varmap}{$basevar}) {
							$ctx->{log}->($ctx, 'unset', $var, "unset global $p: $basevar") if $ctx->{log};
						} else {
							$ctx->{log}->($ctx, 'unset', $var, "unset undefined global $p: $basevar") if $ctx->{log};
						}
						$ctx->setvar($basevar, '#null', 1);
						push(@param, $basevar);
						$changed = 1;
						next;
					    }
					}
				} else {
					$ctx->{warn}->($ctx, 'unset', $var, "$p not found");
				}
				my $v = $ctx->exec_statement($p);
				push(@param, $v);
				if ($v ne $p) {
					$changed = 1;
				}
				$all_var = 0;
			}
			#unless ($all_var) {
			#	$ctx->set_tainted($var);
			#}
			if (exists $ctx->{simplify}{stmt}) {
				if ($changed) {
					my $k = $parser->setstmt(['unset', \@param]);
					$ctx->{log}->($ctx, 'unset', $var, "simplify -> $k") if $ctx->{log};
					return $k;
				}
			}
			return $var;
		} elsif ($cmd eq 'break') {
			return $var;
		} elsif ($cmd eq 'continue') {
			return $var;
		} elsif ($cmd eq 'namespace') {
			my ($arg, $block) = @{$parser->{strmap}->{$var}}[1..2];

			$ctx->{namespace} = $arg; # always use case in-sensitive later

			if (defined $block) {
				my $block1 = $ctx->exec_statement($block);
				if ($block1 ne $block) {
					my $k = $parser->setstmt(['namespace', $arg, $block1]);
					return $k;
				}
			}
			return $var;
		} elsif ($cmd =~ /^(include|include_once|require|require_once)$/) {
			my $arg = $parser->{strmap}->{$var}->[1];
			my $v = $ctx->exec_statement($arg);

			$ctx->set_tainted($var);

			if (exists $ctx->{simplify}{stmt}) {
				if ($v ne $arg) {
					my $k = $parser->setstmt([$cmd, $v]);
					$ctx->{log}->($ctx, $cmd, $var, "simplify -> $k") if $ctx->{log};
					return $k;
				}
			}
			return $var;
		} elsif ($cmd eq 'if') {
			my ($expr, $then, $else) = @{$parser->{strmap}->{$var}}[1..3];

			my $cond = $ctx->exec_statement($expr);

			# insert possible assignment from expr
			#
			my $fin = $ctx->insert_assignments(undef);

			$ctx->{log}->($ctx, 'if', $var, "expr %s -> %s", $expr, defined $cond ? $cond : '<UNDEF>') if $ctx->{log};
			if (defined $cond && (is_strval($cond) || is_array($cond))) {
				my $res;

				my $val = $parser->{strmap}{$cond};
				if (is_array($cond)) {
					my $arr = $parser->{strmap}{$cond};
					$val = !$arr->empty();
				}
				if ($val) {
					$res = $ctx->exec_statement($then);
					$res = $parser->flatten_block_if_single($res);
				} elsif (defined $else) {
					$res = $ctx->exec_statement($else);
					$res = $parser->flatten_block_if_single($res);
				} else {
					$res = $parser->setblk('flat', []);
				}

				# convert std blocks to flat
				#
				my @seq = ();
				$parser->flatten_block($fin, \@seq) if defined $fin;
				$parser->flatten_block($res, \@seq);
				if (scalar @seq > 1) {
					$res = $parser->setblk('flat', [@seq]);
				} elsif (scalar @seq > 0) {
					$res = $seq[0];
				}
				return $res;
			}

			# simplify if
			#
			# invalidate undefined variables first to avoid '#null' compares
			#
			my $var0 = $var;
			if ($expr ne $cond) {
				# use cond with removed assignments
				$var0 = $parser->setstmt(['if', $cond, $then, $else]);
			}
			my $info = $ctx->get_unresolved_info($var, $var0);
			$ctx->invalidate_undefined_vars($info, 'if', $var);

			# run with unresolved vars to simplify then/else and
			# unresolve changed variables afterwards again.
			#
			my $ctx_t = $ctx->clone();
			my $ctx_e;
			my $then1 = $ctx_t->exec_statement($then);
			my $else1;
			if (defined $else) {
				$ctx_e = $ctx->clone();
				$else1 = $ctx_e->exec_statement($else);
			}
			$ctx->update_unresolved($ctx_t);
			if (defined $else) {
				$ctx->update_unresolved($ctx_e);
			}
			if (is_instvar($cond)) {
				$cond = $expr;
			}
			if (($cond ne $expr) || ($then ne $then1) || (defined $else && ($else ne $else1))) {
				# put braces around simplified then/else blocks,
				# but no brace around 'else if'.
				#
				if (($then ne $then1) && !is_block($then1)) {
					$then1 = $parser->setblk('std', [$then1]);
				}
				if (defined $else && ($else ne $else1) && !is_block($else1)) {
					$else1 = $parser->setblk('std', [$else1]);
				}
				my $k = $parser->setstmt(['if', $cond, $then1, $else1]);
				$ctx->{log}->($ctx, 'if', $var, "simplify -> $k") if $ctx->{log};
				$var = $k;
			}
			if (defined $fin) {
				my @seq = ();
				$parser->flatten_block($fin, \@seq);
				push(@seq, $var);
				if (scalar @seq > 1) {
					$var = $parser->setblk('std', [@seq]);
				} elsif (scalar @seq > 0) {
					$var = $seq[0];
				}
			}
			return $var;
		} elsif ($cmd eq 'while') {
			my ($expr, $block) = @{$parser->{strmap}->{$var}}[1..2];

			# - expr is recalculated on each loop
			#   (can't pre-simplify expressions like '$i < 7' or '--$x' -> 'num' or
			#   assignments, because this will lead to wrong code like 'while (1)')
			#
			unless (exists $ctx->{skip}{loop}) {
				my $orgloop = $parser->format_stmt($var);
				my $toploop = loop_start($parser);
				my $i = 0;
				my $res;
				my @seq = ();

				while (1) {
					my $cond = $ctx->exec_statement($expr);

					if (($i == 0) && (is_strval($cond) || (is_array($cond)))) {
						# optimze 'while(0) { ... }' cases away
						#
						my $val = $parser->{strmap}->{$cond};
						if (is_array($cond)) {
							my $arr = $parser->{strmap}{$cond};
							$val = !$arr->empty();
						}
						if (!$val) {
							$res = $parser->setblk('flat', []);
							loop_end($parser, $toploop, $i);
							return $res;
						}
					}
					$ctx->{log}->($ctx, 'while', $var, "%d: cond result: %s -> %s", $i, $expr, $cond) if $ctx->{log};
					if (is_strval($cond) || is_array($cond)) {
						my $val = $parser->{strmap}->{$cond};
						if (is_array($cond)) {
							my $arr = $parser->{strmap}{$cond};
							$val = !$arr->empty();
						}
						if (!$val) {
							# loop might never execute
							unless (defined $res) {
								$ctx->{log}->($ctx, 'while', $var, "%d: block never executed", $i) if $ctx->{log};
								$res = $parser->setblk('flat', []);
							}
							last;
						}
					} elsif ($i == 0) {
						# can't resolve expression - just return full while()-statement
						$ctx->{warn}->($ctx, 'while', $var, "initial bad cond %s -> %s", $expr, $cond);
						last;
					} else {
						$ctx->{warn}->($ctx, 'while', $var, "bad cond after %d iterations %s -> %s", $i, $expr, $cond);
						$res = undef;
						last;
					}
					# need to keep assignments in block here
					#
					$res = $ctx->exec_statement($block);
					unless (defined $res) {
						last;
					}
					my $info = {vars => {}, calls => {}, stmts => {}};
					$parser->stmt_info($res, $info);
					my $r = _final_break($parser, $res, '(break)');
					my $u = $ctx->unresolvable_var($info);
					my $f = _skipped_call($parser, $res, '(.*)', $info);
					if (defined $u || (defined $f && (!defined $r || ($f ne $r)))) {
						$ctx->{warn}->($ctx, 'while', $var, "skip loop after %d interations: found remaining call[%s]: %s -> %s", $i, defined $f ? $f : $u, $block, $res);
						$res = undef;
						last;
					}
					$ctx->{log}->($ctx, 'while', $var, "%d: block result: %s -> %s", $i, $block, $res) if $ctx->{log};
					if (defined $r) {
						$ctx->{log}->($ctx, 'while', $var, "%d: block break: %s", $i, $res) if $ctx->{log};
						last;
					}
					my $fin = $ctx->insert_assignments(undef);

					my @list = ();
					if (defined $fin) {
						$parser->flatten_block($fin, \@list);
					}
					$parser->flatten_block($res, \@list);
					$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);

					if ($i >= $ctx->{max_loop_while}) {
						$ctx->{warn}->($ctx, 'while', $var, "stop loop after %d [%d] iterations: $res [$expr]", $i, loop_val($parser, $i));
						last;
					}
					if ((loop_level($parser) > 1) && (loop_val($parser, $i) >= (2 * $ctx->{max_loop}))) {
						$ctx->{warn}->($ctx, 'while', $var, "stop loop after %d nested iterations: $res [$expr]", loop_val($parser, $i));
						last;
					}
					if (($i >= $ctx->{max_loop_const}) && is_strval($expr)) {
						# stop 'while(true)' and similay cases
						$ctx->{warn}->($ctx, 'while', $var, "stop loop after %d const iterations: $res [$expr]", $i);
						last;
					}
					$i++;
				}
				loop_end($parser, $toploop, $i);

				if (defined $res) {
					# insert final loop var value
					#
					my $fin = $ctx->insert_assignments(undef);
					if (defined $fin) {
						my @list = ();
						$parser->flatten_block($fin, \@list);
						$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);
					}
					if (scalar @seq > 1) {
						$res = $parser->setblk('std', [@seq]);
					} elsif (scalar @seq > 0) {
						$res = $seq[0];
					}
					$ctx->{log}->($ctx, 'while', $var, "optimized '%s' -> $res '%s'", $orgloop, $parser->format_stmt($res)) if $ctx->{log};
					return $res;
				}
			}

			if (exists $ctx->{simplify}{stmt}) {
				$ctx->{log}->($ctx, 'while', $var, "simplify start %s", $parser->stmt_str($var)) if $ctx->{log};

				# when not executed, invalidate loop variables and keep original statement
				# - assignments might be used in next loop, so these vars are #unresolved
				# - more vars might be changed if there are unresolvable left-hand-sides
				#   of assignments or calls, so invalidate remaining variables used in loop.
				#
				my $info = $ctx->get_unresolved_info($var, $var);
				$ctx->invalidate_vars($info, 'while', $var);
				$ctx->discard_pending_assignments(); # remove any pending assignments (from 'cond')

				# run with unresolved vars to simplify block and
				# unresolve changed variables afterwards again.
				#
				my $ctx_e = $ctx->clone();
				my $expr0 = $ctx_e->exec_statement($expr, 1); # keep assignments inline
				$ctx->update_unresolved($ctx_e);

				my $ctx_b = $ctx->clone();
				my $block0 = $ctx_b->exec_statement($block);
				$ctx->update_unresolved($ctx_b);

				if (is_instvar($expr0)) {
					$expr0 = $expr;
				}
				if (($expr ne $expr0) || ($block ne $block0)) {
					my $k = $parser->setstmt(['while', $expr0, $block0]);
					return $k;
				}
			}
			return $var;
		} elsif ($cmd eq 'do') {
			my ($expr, $block) = @{$parser->{strmap}->{$var}}[1..2];

			# - block is executed at least once
			#   (does optimze 'do { ... } while(0)' cases)
			#
			my $orgloop = $parser->format_stmt($var);
			my @seq = ();

			my $res = $ctx->exec_statement($block);
			if (defined $res) {
				my @list = ();
				$parser->flatten_block($res, \@list);
				$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);
			}
			unless (exists $ctx->{skip}{loop}) {
				my $i = 0;
				my $toploop = loop_start($parser);

				while (defined $res) {
					my $cond = $ctx->exec_statement($expr);

					$ctx->{log}->($ctx, 'do', $var, "%d: cond result: %s -> %s", $i, $expr, $cond) if $ctx->{log};
					if (is_strval($cond) || is_array($cond)) {
						my $val = $parser->{strmap}{$cond};
						if (is_array($cond)) {
							my $arr = $parser->{strmap}{$cond};
							$val = !$arr->empty();
						}
						if (!$val) {
							last;
						}
					} elsif ($i == 0) {
						# can't resolve expression - just return full do()-statement
						$ctx->{warn}->($ctx, 'do', $var, "initial bad cond %s -> %s", $expr, $cond);
						$res = undef;
						last;
					} else {
						$ctx->{warn}->($ctx, 'do', $var, "bad cond after %d iterations %s -> %s", $i, $expr, $cond);
						#$res = $parser->setblk('flat', []);
						$res = undef;
						last;
					}
					$res = $ctx->exec_statement($block);
					unless (defined $res) {
						last;
					}
					my $info = {vars => {}, calls => {}, stmts => {}};
					$parser->stmt_info($res, $info);
					my $r = _final_break($parser, $res, '(break)');
					my $u = $ctx->unresolvable_var($info);
					my $f = _skipped_call($parser, $res, '(.*)', $info);
					if (defined $u || (defined $f && (!defined $r || ($f ne $r)))) {
						$ctx->{warn}->($ctx, 'do', $var, "skip loop after %d interations: found remaining call[%s]: %s -> %s", $i, defined $f ? $f : $u, $block, $res);
						$res = undef;
						last;
					}
					$ctx->{log}->($ctx, 'do', $var, "%d: block result: %s -> %s", $i, $block, $res) if $ctx->{log};
					if (defined $r) {
						$ctx->{log}->($ctx, 'do', $var, "%d: block break: %s", $i, $res) if $ctx->{log};
						last;
					}
					my $fin = $ctx->insert_assignments(undef);

					my @list = ();
					if (defined $fin) {
						$parser->flatten_block($fin, \@list);
					}
					$parser->flatten_block($res, \@list);
					$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);

					if ($i >= $ctx->{max_loop}) {
						$ctx->{warn}->($ctx, 'do', $var, "stop loop after %d [%d] iterations: $res [$expr]", $i, loop_val($parser, $i));
						last;
					}
					if ((loop_level($parser) > 1) && (loop_val($parser, $i) >= (2 * $ctx->{max_loop}))) {
						$ctx->{warn}->($ctx, 'do', $var, "stop loop after %d nested iterations: $res [$expr]", loop_val($parser, $i));
						last;
					}
					if (($i >= $ctx->{max_loop_const}) && is_strval($expr)) {
						# stop 'while(true)' and similay cases
						$ctx->{warn}->($ctx, 'do', $var, "stop loop after %d const iterations: $res [$expr]", $i);
						last;
					}
					$i++;
				}
				loop_end($parser, $toploop, $i);
			}
			if (defined $res) {
				# insert final loop var value
				#
				my $fin = $ctx->insert_assignments(undef);
				if (defined $fin) {
					my @list = ();
					$parser->flatten_block($fin, \@list);
					$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);
				}
				if (scalar @seq > 1) {
					$res = $parser->setblk('std', [@seq]);
				} elsif (scalar @seq > 0) {
					$res = $seq[0];
				}
				$ctx->{log}->($ctx, 'do', $var, "optimized '%s' -> %s '%s'", $orgloop, $res, $parser->format_stmt($res)) if $ctx->{log};
				return $res;
			}

			if (exists $ctx->{simplify}{stmt}) {
				$ctx->{log}->($ctx, 'do', $var, "simplify start %s", $parser->stmt_str($var)) if $ctx->{log};

				# when not executed, invalidate loop variables and keep original statement
				# - assignments might be used in next loop, so these vars are #unresolved
				# - more vars might be changed if there are unresolvable left-hand-sides
				#   of assignments or calls, so invalidate remaining variables used in loop.
				#
				my $info = $ctx->get_unresolved_info($var, $var);
				$ctx->invalidate_vars($info, 'do', $var);
				$ctx->discard_pending_assignments(); # remove any pending assignments (from block)

				# run with unresolved vars to simplify block and
				# unresolve changed variables afterwards again.
				#
				my $ctx_b = $ctx->clone();
				my $block0 = $ctx_b->exec_statement($block);
				$ctx->update_unresolved($ctx_b);

				my $ctx_e = $ctx->clone();
				my $expr0 = $ctx_e->exec_statement($expr, 1); # keep assignments inline
				$ctx->update_unresolved($ctx_e);

				if (is_instvar($expr0)) {
					$expr0 = $expr;
				}
				if (($expr ne $expr0) || ($block ne $block0)) {
					my $k = $parser->setstmt(['do', $expr0, $block0]);
					return $k;
				}
			}
			return $var;
		} elsif ($cmd eq 'for') {
			my ($pre, $expr, $post, $block) = @{$parser->{strmap}->{$var}}[1..4];

			# - pre is executed just once at the start of foreach
			# - expr & post are recalculated on each loop
			#
			my $pre0 = $ctx->exec_statement($pre, 1);

			unless (exists $ctx->{skip}{loop}) {
				my $orgloop = $parser->format_stmt($var);
				my $toploop = loop_start($parser);
				my $i = 0;
				my $res;
				my @seq = ();

				# add initial variable assignments to result list
				#
				my @list = ();
				$parser->flatten_block($pre0, \@list);
				$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);

				while (1) {
					my $cond = $ctx->exec_statement($expr);

					$ctx->{log}->($ctx, 'for', $var, "%d: cond result: %s -> %s", $i, $expr, $cond) if $ctx->{log};
					if ($parser->is_empty_block($cond)) {
						$cond = '#null'; # null statements are eliminated in block execution
					}
					if (is_strval($cond) || is_array($cond)) {
						my $val = $parser->{strmap}{$cond};
						if (is_array($cond)) {
							my $arr = $parser->{strmap}{$cond};
							$val = !$arr->empty();
						}
						if (!$val) {
							# loop might never execute
							unless (defined $res) {
								$ctx->{log}->($ctx, 'for', $var, "%d: block $block never executed", $i) if $ctx->{log};
								$res = $parser->setblk('flat', []);
							}
							last;
						}
					} elsif ($i == 0) {
						# can't resolve expression - just return full for()-statement
						last;
					} else {
						$ctx->{warn}->($ctx, 'for', $var, "bad cond after %d iterations %s -> %s", $i, $expr, $cond);
						#$res = $parser->setblk('flat', []);
						$res = undef;
						last;
					}
					$res = $ctx->exec_statement($block);
					unless (defined $res) {
						last;
					}
					my $info = {vars => {}, calls => {}, stmts => {}};
					$parser->stmt_info($res, $info);
					my $r = _final_break($parser, $res, '(break)');
					my $u = $ctx->unresolvable_var($info);
					my $f = _skipped_call($parser, $res, '(.*)', $info);
					if (defined $u || (defined $f && (!defined $r || ($f ne $r)))) {
						$ctx->{warn}->($ctx, 'for', $var, "skip loop after %d interations: found remaining call[%s]: '%s' %s -> %s", $i, defined $f ? $f : $u, $orgloop, $block, $res);
						$res = undef;
						last;
					}
					$ctx->{log}->($ctx, 'for', $var, "%d: block result: %s -> %s", $i, $block, $res) if $ctx->{log};
					if (defined $r) {
						$ctx->{log}->($ctx, 'for', $var, "%d: block break: %s", $i, $res) if $ctx->{log};
						last;
					}
					# recalculate post on each loop
					#
					my $fin = $ctx->insert_assignments(undef);

					my @list = ();
					if (defined $fin) {
						$parser->flatten_block($fin, \@list);
					}
					$parser->flatten_block($res, \@list);
					$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);

					my $post0 = $ctx->exec_statement($post);
					$ctx->{log}->($ctx, 'for', $var, "%d: post result: %s -> %s", $i, $post, $post0) if $ctx->{log};

					if ($i >= $ctx->{max_loop}) {
						$ctx->{warn}->($ctx, 'for', $var, "stop loop after %d [%d] iterations: $res [$expr]", $i, loop_val($parser, $i));
						last;
					}
					if ((loop_level($parser) > 1) && (loop_val($parser, $i) >= (2 * $ctx->{max_loop}))) {
						$ctx->{warn}->($ctx, 'for', $var, "stop loop after %d nested iterations: $res [$expr]", loop_val($parser, $i));
						last;
					}
					$i++;
				}
				loop_end($parser, $toploop, $i);

				if (defined $res) {
					# insert final loop var value
					#
					my $fin = $ctx->insert_assignments(undef);
					if (defined $fin) {
						my @list = ();
						$parser->flatten_block($fin, \@list);
						$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);
					}
					# todo: can getting very long statement list here for seq - just return values from last loop
					#
					if (scalar @seq > 1) {
						$res = $parser->setblk('std', [@seq]);
					} elsif (scalar @seq > 0) {
						$res = $seq[0];
					}
					$ctx->{log}->($ctx, 'for', $var, "optimized '%s' -> %s '%s'", $orgloop, $res, $parser->format_stmt($res)) if $ctx->{log};
					return $res;
				}
			}

			if (exists $ctx->{simplify}{stmt}) {
				$ctx->{log}->($ctx, 'for', $var, "simplify start %s", $parser->stmt_str($var)) if $ctx->{log};

				# when not executed, invalidate loop variables and keep original statement
				# - key/value change for each loop, so they are #unresolved
				# - assignments might be used in next loop, so these vars are #unresolved
				# - more vars might be changed if there are unresolvable left-hand-sides
				#   of assignments or calls, so invalidate remaining variables used in loop.
				#
				my $var0 = $var;
				if ($pre ne $pre0) {
					$var0 = $parser->setstmt(['for', $pre0, $expr, $post, $block]);
				}
				my $info = $ctx->get_unresolved_info($var, $var0);
				$ctx->invalidate_vars($info, 'for', $var);
				$ctx->discard_pending_assignments(); # remove any pending assignments (from 'cond')

				# run with unresolved vars to simplify block and
				# unresolve changed variables afterwards again.
				#
				my $ctx_e = $ctx->clone();
				my $expr0 = $ctx_e->exec_statement($expr, 1); # keep assignments inline
				$ctx->update_unresolved($ctx_e);

				my $ctx_b = $ctx->clone();
				my $block0 = $ctx_b->exec_statement($block);
				$ctx->update_unresolved($ctx_b);

				my $ctx_p = $ctx->clone();
				my $post0 = $ctx_p->exec_statement($post, 1); # keep assignments inline
				$ctx->update_unresolved($ctx_p);

				if (is_instvar($expr0)) {
					$expr0 = $expr;
				}
				if (($pre ne $pre0) || ($expr ne $expr0) || ($post ne $post0) || ($block ne $block0)) {
					my $k = $parser->setstmt(['for', $pre0, $expr0, $post0, $block0]);
					return $k;
				}
			}
			return $var;
		} elsif ($cmd eq 'foreach') {
			my ($expr, $key, $value, $block) = @{$parser->{strmap}->{$var}}[1..4];
			my $valvar;
			my $keyvar;

			# - expr is executed just once at the start of foreach
			# - key and value are recalculated on each loop
			# - TODO: reference on value var
			#
			my $expr0 = $ctx->exec_statement($expr);

			if (defined $key) {
				my ($_basevar2, $_has_index2, $_idxstr2) = $ctx->resolve_variable($key, $in_block);
				$keyvar = defined $_basevar2 ? $_basevar2 : $key;
			}
			my ($_basevar, $_has_index, $_idxstr) = $ctx->resolve_variable($value, $in_block);
			$valvar = defined $_basevar ? $_basevar : $value;

			# loop should be unrolled only after variables are available
			unless (exists $ctx->{skip}{loop}) {
				my $orgloop = $parser->format_stmt($var);
				my $toploop = loop_start($parser);
				my $i = 0;
				my $res;
				my @seq = ();

				if (is_array($expr0)) {
					#my ($a2, $array2) = $parser->copyarr($expr0); # copy if value not reference
					#$expr0 = $a2;
					my $arr = $parser->{strmap}{$expr0};
					my $keys = $arr->get_keys();

					# loop might never execute
					if ((scalar @$keys == 0) && !$ctx->{tainted}) {
						$ctx->{log}->($ctx, 'foreach', $var, "block $block never executed") if $ctx->{log};
						$res = $parser->setblk('flat', []);
					}
					foreach my $k (@$keys) {
						if (defined $key && defined $keyvar && is_variable($keyvar)) {
							if (is_int_index($k)) {
								my $kstr = $parser->setnum($k);
								$ctx->{varmap}{$keyvar} = $kstr;
							} else {
								$ctx->{varmap}{$keyvar} = $k;
							}
						}
						if (defined $valvar && is_variable($valvar)) {
							my $arrval = $arr->val($k);
							$ctx->{varmap}{$valvar} = $arrval;
						}
						$res = $ctx->exec_statement($block);
						unless (defined $res) {
							last;
						}
						my $info = {vars => {}, calls => {}, stmts => {}};
						$parser->stmt_info($res, $info);
						my $r = _final_break($parser, $res, '(break)');
						my $u = $ctx->unresolvable_var($info);
						my $f = _skipped_call($parser, $res, '(.*)', $info);
						if (defined $u || (defined $f && (!defined $r || ($f ne $r)))) {
							$ctx->{warn}->($ctx, 'foreach', $var, "skip loop after %d interations (key %s): found remaining call[%s]: %s -> %s", $i, $k, defined $f ? $f : $u, $block, $res);
							$res = undef;
							last;
						}
						if (defined $r) {
							$ctx->{log}->($ctx, 'foreach', $var, "%s: block break: %s", $k, $res) if $ctx->{log};
							last;
						}
						my $fin = $ctx->insert_assignments(undef);

						my @list = ();
						if (defined $fin) {
							$parser->flatten_block($fin, \@list);
						}
						$parser->flatten_block($res, \@list);
						$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);

						# recalculate key & value on each loop
						#
						if (defined $key && defined $keyvar && ($keyvar ne $key)) {
							my ($_basevar2, $_has_index2, $_idxstr2) = $ctx->resolve_variable($key, $in_block);
							$keyvar = defined $_basevar2 ? $_basevar2 : $key;
						}
						if (defined $valvar && ($valvar ne $value)) {
							my ($_basevar, $_has_index, $_idxstr) = $ctx->resolve_variable($value, $in_block);
							$valvar = defined $_basevar ? $_basevar : $value;
						}
						$i++;
					}
				} else {
					$ctx->{log}->($ctx, 'foreach', $var, "can't handle expr: %s (%s)", $expr, $expr0) if $ctx->{log};
				}
				loop_end($parser, $toploop, $i);

				if (defined $res) {
					# insert final loop var value
					#
					my $fin = $ctx->insert_assignments(undef);
					if (defined $fin) {
						my @list = ();
						$parser->flatten_block($fin, \@list);
						$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);
					}
					# todo: can getting very long statement list here for seq - just return values from last loop
					#
					if (scalar @seq > 1) {
						$res = $parser->setblk('std', [@seq]);
					} elsif (scalar @seq > 0) {
						$res = $seq[0];
					}
					$ctx->{log}->($ctx, 'foreach', $var, "optimized '%s' -> %s '%s'", $orgloop, $res, $parser->format_stmt($res)) if $ctx->{log};
					return $res;
				}
			}

			if (exists $ctx->{simplify}{stmt}) {
				$ctx->{log}->($ctx, 'foreach', $var, "simplify start %s", $parser->stmt_str($var)) if $ctx->{log};

				# when not executed, invalidate loop variables and keep original statement
				# - key/value change for each loop, so they are #unresolved
				# - assignments might be used in next loop, so these vars are #unresolved
				# - more vars might be changed if there are unresolvable left-hand-sides
				#   of assignments or calls, so invalidate remaining variables used in loop.
				#
				my $var0 = $var;
				if ($expr ne $expr0) {
					# use expr with removed assignments
					$var0 = $parser->setstmt(['foreach', $expr0, $key, $value, $block]);
				}
				my $info = $ctx->get_unresolved_info($var, $var0);
				$ctx->invalidate_vars($info, 'foreach', $var);

				# run with unresolved vars to simplify block and
				# unresolve changed variables afterwards again.
				#
				my $ctx_b = $ctx->clone();
				my $block0 = $ctx_b->exec_statement($block);
				$ctx->update_unresolved($ctx_b);

				if (($expr ne $expr0) || ($block ne $block0) || (defined $valvar && ($value ne $valvar)) || (defined $key && defined $keyvar && ($key ne $keyvar))) {
					# simplify elem expression
					#
					my $k = $parser->setstmt(['foreach', $expr0, $keyvar, $valvar, $block0]);
					$ctx->{log}->($ctx, 'foreach', $var, "simplify -> $k") if $ctx->{log};
					return $k;
				}
			}
			return $var;
		} elsif ($cmd eq 'switch') {
			my ($expr, $cases) = @{$parser->{strmap}->{$var}}[1..2];
			my $op1 = $ctx->exec_statement($expr);

			# insert possible assignment from expr
			#
			my $fin = $ctx->insert_assignments(undef);

			if (is_strval($op1)) {
				my $found;
				my @seq = ();

				$parser->flatten_block($fin, \@seq) if defined $fin;
				$fin = undef;

				for (my $i=0; $i < scalar @$cases; $i++) {
					my $e = $cases->[$i];
					my $c = $e->[0];
					if (defined $c) {
						my $op2 = $ctx->exec_statement($c);
		    				if (is_strval($op2)) {
							my ($val, $result) = PHP::Decode::Op::binary($parser, $op1, '==', $op2);
							if (defined $result && $result) {
								$found = $i;
								last;
							}
						} else {
							$ctx->{warn}->($ctx, 'switch', $var, "bad cond %s == %s -> %s", $op1, $c, $op2);
							$found = -1;
							last;
						}
					}
				}
				if (!defined $found) {
					# process 'default:'
					#
					for (my $i=0; $i < scalar @$cases; $i++) {
						my $e = $cases->[$i];
						my $c = $e->[0];
						if (!defined $c) {
							$found = $i;
							last;
						}
					}
				}
				if (defined $found && ($found >= 0)) {
					for (my $i=$found; $i < scalar @$cases; $i++) {
						my $e = $cases->[$i];
						my $b = $e->[1];
						my $res = $ctx->exec_statement($b);
						unless (defined $res) {
							last;
						}
						my @list = ();
						my $f = _final_break($parser, $res, '(break|continue|return)');
						if (defined $f) {
							$res = _remove_final_statement($parser, '(break|continue)', $res);
						}
						$parser->flatten_block($res, \@list);
						$ctx->optimize_loop_var_list($cmd, $var, \@seq, \@list);
						if (defined $f) {
							last;
						}
					}
					# convert std blocks to flat
					#
					my $res;
					if (scalar @seq > 1) {
						$res = $parser->setblk('flat', [@seq]);
					} elsif (scalar @seq > 0) {
						$res = $seq[0];
					} else {
						$res = $parser->setblk('flat', []);
					}
					return $res;
				}
			}

			if (exists $ctx->{simplify}{stmt}) {
				$ctx->{log}->($ctx, 'switch', $var, "simplify start %s", $parser->stmt_str($var)) if $ctx->{log};

				# invalidate variables first to avoid '#null' compares
				# - since there are 'fallthrough' dependencies between
				#   case blocks, all variables need to be invalidated.
				#
				my $var0 = $var;
				if ($expr ne $op1) {
					# use cond with removed assignments
					$var0 = $parser->setstmt(['switch', $op1, $cases]);
				}
				my $info = $ctx->get_unresolved_info($var, $var0);
				#$ctx->invalidate_undefined_vars($info, 'switch', $var);
				$ctx->invalidate_vars($info, 'switch', $var);

				# run with unresolved vars to simplify then/else and
				# unresolve changed variables afterwards again.
				#
				my @cnew = ();
				my @cctx = ();
				my $changed = 0;
				for (my $i=0; $i < scalar @$cases; $i++) {
					my $e = $cases->[$i];
					my $c = $e->[0];
					my $b = $e->[1];
					my $c0 = $c;

					$cctx[$i] = $ctx->clone();
					if (defined $c) {
						$c0 = $cctx[$i]->exec_statement($c);
					}
					my $b0 = $cctx[$i]->exec_statement($b);

					if ((defined $c0 && ($c0 ne $c)) || ($b0 ne $b)) {
						$changed = 1;
					}
					push (@cnew, [$c0, $b0]);
				}
				for (my $i=0; $i < scalar @$cases; $i++) {
					$ctx->update_unresolved($cctx[$i]);
				}

				if (($expr ne $op1) || $changed) {
					my $k = $parser->setstmt(['switch', $op1, \@cnew]);
					$ctx->{log}->($ctx, 'switch', $var, "simplify -> $k") if $ctx->{log};
					$var = $k;
					return $k;
				}
				if (defined $fin) {
					my @seq = ();
					$parser->flatten_block($fin, \@seq);
					push(@seq, $var);
					if (scalar @seq > 1) {
						$var = $parser->setblk('std', [@seq]);
					} elsif (scalar @seq > 0) {
						$var = $seq[0];
					}
				}
			}
			return $var;
		}
	} elsif ($var =~ /^#fun\d+$/) {
		my ($f, $a, $b, $p) = @{$parser->{strmap}->{$var}};

		# read with temporary varmap to simplify local variables
		# (this should just run once per func)
		# (keep globals in functions untouched until function is called)
		#
		my $name = defined $f ? (exists $ctx->{class_scope} ? method_name($ctx->{class_scope}, lc($f)) : lc($f)) : '{closure}';
		my $ctx2 = $ctx->simplification_ctx(infunction => $name);

		# invalidate function params for simplification
		#
		if (scalar @$a > 0) {
			foreach my $v (@$a) {
				if (is_variable($v)) {
					$ctx2->setvar($v, "#unresolved", 0);
				} elsif ($v =~ /^#expr\d+$/) {
					my ($op, $v1, $v2) = @{$parser->{strmap}->{$v}};
					if (($op eq '=') && is_variable($v1)) {
						$ctx2->setvar($v1, "#unresolved", 0);
					}
				} elsif ($v =~ /^#ref\d+$/) {
					my $r = $parser->{strmap}->{$v}->[0];
					if (is_variable($r)) {
						$ctx2->setvar($r, "#unresolved", 0);
					}
				}
			}
		}
		my $b2 = $ctx2->exec_statement($b);

		if (!is_block($b2)) {
			$b2 = $parser->setblk('std', [$b2]);
		}

		# copy static function variables into live context
		#
		foreach my $sf (keys %{$ctx2->{varmap}{static}}) {
			foreach my $sv (keys %{$ctx2->{varmap}{static}{$sf}}) {
				$ctx->{varmap}{static}{$sf}{$sv} = $ctx2->{varmap}{static}{$sf}{$sv};
				$ctx->{log}->($ctx, 'exec', $var, "register static var $sv in func $sf") if $ctx->{log};
			}
		}
		if ($b2 ne $b) {
			my $k = $parser->setfun($f, $a, $b2, $p);
			if (defined $f) {
				$ctx->registerfun($f, $k);
			}
			return $k;
		}
		if (defined $f && !$ctx->getfun($f)) {
			# allow local functions also for block simplify
			#
			$ctx->{log}->($ctx, 'exec', $var, "register local func $var [$f]") if $ctx->{log};
			$ctx->registerfun($f, $var);
		}
	} elsif ($var =~ /^#class\d+$/) {
		my ($c, $b, $p) = @{$parser->{strmap}->{$var}};
		my ($type, $arglist) = @{$parser->{strmap}->{$b}};
		my $name = defined $c ? $c : 'class@anonymous';

		$ctx->{varmap}{inst}{lc($c)} = {}; # init class var map

		# init class properties here
		# https://www.php.net/manual/en/language.oop5.properties.php
		#
		my @args = ();
		my $changed = 0;
		foreach my $a (@$arglist) {
			if ($a =~ /^#fun\d+$/) {
				# function bodies are replaced inplace
				my $ctx2 = $ctx->subscope_ctx(varmap => {}, class_scope => lc($name), infunction => 0);
				my $f = $ctx2->exec_statement($a, 1);
				push(@args, $f);
				if ($f ne $a) {
					$changed = 1;
				}
			} elsif (($a =~ /^#expr\d+$/)) {
				my ($op, $o1, $o2) = @{$parser->{strmap}->{$a}};
				my $ctx2 = $ctx->subscope_ctx(varmap => {}, class_scope => lc($name), infunction => 0);
				if ($op eq '=') {
					my $k = $ctx2->exec_statement($a, 1);
					push(@args, $k);
				}
			} elsif ($a =~ /^#stmt\d+$/) {
				my $cmd = $parser->{strmap}->{$a}->[0];
				my $ctx2 = $ctx->subscope_ctx(varmap => {}, class_scope => lc($name), infunction => 0);
				if ($cmd eq 'static') {
					my $k = $ctx2->exec_statement($a, 1);
					push(@args, $k);
				} elsif ($cmd eq 'const') {
					my $k = $ctx2->exec_statement($a, 1);
					push(@args, $k);
				}
			} else {
				push(@args, $a);
			}
		}
		if ($changed) {
			my $b2 = $parser->setblk('std', \@args);
			my $k = $parser->setclass($c, $b2, $p);
			$ctx->registerclass($c, $k);
			return $k;
		}
		if (defined $c && !$ctx->getclass($c)) {
			$ctx->{log}->($ctx, 'exec', $var, "register local class $var [$c]") if $ctx->{log};
			$ctx->registerclass($c, $var);
		}
	} else {
		$ctx->{warn}->($ctx, 'exec', $var, "skip");
	}
	return $var;
}

# track variable assignments in expressions (optionally reinsert them later)
#
sub track_assignment {
	my ($ctx, $var, $val) = @_;

	$ctx->{varhist}{$var} = [$val, $histidx++];
	return;
}

sub discard_pending_assignments {
	my ($ctx) = @_;
	$ctx->{varhist} = {};
	return;
}

sub have_assignments {
	my ($ctx) = @_;

	if (scalar keys %{$ctx->{varhist}} > 0) {
		return 1;
	}
	return 0;
}

sub insert_assignments {
	my ($ctx, $stmt) = @_;
	my $parser = $ctx->{parser};

	if (scalar keys %{$ctx->{varhist}} > 0) {
		# add assignments in exec-order
		#
		my @blk = ();
		my @ass = ();
		foreach my $v (sort { $ctx->{varhist}{$a}->[1] <=> $ctx->{varhist}{$b}->[1] } keys %{$ctx->{varhist}}) {
			$ctx->{log}->($ctx, 'assign', defined $stmt ? $stmt : '[]', "$v = $ctx->{varhist}{$v}->[0]") if $ctx->{log};

			if ($ctx->{varhist}{$v}->[0] ne '#unresolved') {
				my $e;
				if ($v =~ /^\$eval\$/) {
					# eval blocks are inserted at front before assignments
					#
					$e = $ctx->{varhist}{$v}->[0]; # eval block
					if (is_block($e)) {
						$parser->flatten_block($e, \@blk);
					} else {
						push(@blk, $e);
					}
				} else {
					# assignments are inserted at front
					#
					$e = $parser->setexpr('=', $v, $ctx->{varhist}{$v}->[0]);
					push(@ass, $e);
				}
			}
		}
		if ((scalar @ass > 0) || (scalar @blk > 0)) {
			if (defined $stmt) {
				$parser->flatten_block($stmt, \@ass);
			}
			$stmt = $parser->setblk('flat', [@blk, @ass]);
		}
	}
	$ctx->{varhist} = {};
	return $stmt;
}

1;

__END__

=head1 NAME

PHP::Decode::Transformer

=head1 SYNOPSIS

  # Create an instance

  sub warn_cb {
	my ($ctx, $action, $stmt, $fmt) = (shift, shift, shift, shift);

	my $msg = sprintf $fmt, @_;
	print "WARN: [$ctx->{infunction}] $action $stmt", $msg, "\n";
  }
  my %strmap;
  my $parser = PHP::Decode::Parser->new(strmap => \%strmap);
  my $ctx = PHP::Decode::Transformer->new(parser => $parser, warn => \&warn_cb);

  # Parse and transform php code

  my $str = $parser->setstr('<?php echo "test"; ?>');
  my $blk = $ctx->parse_eval($str);
  my $stmt = $ctx->exec_eval($blk);

  # Expand to code again

  my $code = $parser->format_stmt($stmt);
  print $code;

  # Output: echo 'test' ; $STDOUT = 'test' ;

=head1 DESCRIPTION

The PHP::Decode::Transformer Module applies static transformations to PHP statements
parsed by the PHP::Decode::Parser module.

=head1 METHODS

=head2 new

  $ctx = PHP::Decode::Transformer->new(parser => $parser);

Create a PHP::Decode::Transformer object. Arguments are passed in key => value pairs.

The only required argument is `parser`.

The new constructor dies when arguments are invalid, or if required
arguments are missing.

The accepted arguments are:

=over 4

=item warn: optional handler to log transformer warning messages

=item log: optional handler to log transformer info messages

=item debug: optional handler to log transformer debug messages

=item max_loop: optional max iterations for php loop execution (default: 10000)

=item skip: optional transformer features to skip on execution

=item $skip->{call}: skip function calls

=item $skip->{loop}: skip loop execution

=item $skip->{null}: dont' assume null for undefined vars

=item $skip->{stdout}: don't include STDOUT

=item with: optional transformer features to use for execution

=item $with->{getenv}: eval getenv() for passed enviroment hash

=item $with->{translate}: translate self-contained funcs to native code (experimental)

=item $with->{optimize_block_vars}: remove intermediate block vars on toplevel

=item $with->{invalidate_tainted_vars}: invalidate vars after tainted calls

=back

=head2 parse_eval

Parse a php code string.

    $stmt = $ctx->parse_eval($str);

The php code string is tokenized and converted to an internal representation
of php statements. If a script contains more than one top level statement,
the method returns block with a list of these statements.

For more information about the statement types, see the L<PHP::Decode::Parser> Module.

=head2 exec_eval

Execute a php statement.

    $stmt = $ctx->exec_eval($stmt);

The exec method applies static transformations to the passed php statements,
and returns the resulting statements.

=head2 subctx

Create sub-class of transformer referencing the global and local varmaps from parent.

    $ctx2 = $ctx->subctx(%args);

=head2 exec_statement

Execute a php statement and return the result or simplified statement if transformed.

    $stmt2 = $ctx->exec_statement($stmt, $in_block);

=head2 resolve_variable

Resolve an indexed variable to its basevar and index

    ($var, $has_idx, $idx) = $ctx->resolve_variable($stmt, $in_block);

    - var: resolved variable name (a.e: array name)
    - has_idx: is array dereference
    - idx: if is array: indexvalue of last index or undef if index is empty

=head2 getvar

Get value of a variable

    $val = $ctx->getvar($var, $quiet);

=head2 setvar

Set value of a variable

    $ctx->setvar($var, $val, $in_block);

=head2 registerfun

Register a '#fun' definition as callable function

    $ctx->registerfun($name, $fun);

=head2 getfun

Lookup a user defined function by name

    $fun = $ctx->getfun($name);

=head2 registerclass

Register a '#class' definition as instantiatable class

    $ctx->registerclass($name, $class);

=head2 getclass

Lookup a class by name

    $class = $ctx->getclass($name);

=head1 SEE ALSO

Requires the L<PHP::Decode::Parser>, L<PHP::Decode::Array> and L<PHP::Decode::Func> Modules.

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut

