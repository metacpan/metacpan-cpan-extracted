#!/usr/bin/perl

package SWF::Builder::ActionScript::Compiler;

use strict;

use Carp;
use SWF::Element;
use SWF::Builder::ExElement;

@SWF::Builder::ActionScript::Compiler::ISA = ('SWF::Builder::ActionScript::Compiler::Error');

our $VERSION = '0.01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

my $nl = "\x0a\x0d\x{2028}\x{2029}";
my $BE = (CORE::pack('s',1) eq CORE::pack('n',1));
my $INF  = "\x00\x00\x00\x00\x00\x00\xf0\x7f";
my $NINF = "\x00\x00\x00\x00\x00\x00\xf0\xff";
if ($BE) {
    $INF  = reverse $INF;
    $NINF = reverse $NINF;
}
my $MANTISSA  = ~$NINF;
my $INFINITY = unpack('d', $INF);

our %O;

BEGIN {
    %O = 
	( O_ALL        => ~0,
	  O_PEEPHOLE   => 1<<0, # peephole optimization
	  O_CONSTEXP   => 1<<1, # calculate constant expressions
	  O_CONSTMATH  => 1<<2, # calculate math funcs with constant args and constant properties
	  O_LEFTONCE   => 1<<3, # evaluate the lefthand side of assignment expression only once
	  O_REGISTER   => 1<<4, # assign local variables to registers.
	  O_LOCALREG   => 1<<5, # assign local variables to local registers using ActionDefineFunction2. Need O_REGISTER. Flash player 6.0.65 and above only.
	  O_6R65       => 1<<5,

	  );
}

use constant \%O;

our %GLOBAL_OPTIONS;

sub new {
    my $class = shift;
    my $text = shift;
    my %option = (%GLOBAL_OPTIONS, @_);

    my $new = bless {
	text => $text,
	line => 1,
	ungets => [],
	scope => [],
	regvars => [],
	stat => {
	    code => [],
	    label => 'A',
	    loop => [],
	    with => 0,
	    Trace => 'eval',
	    Warning => 1,
	    Optimize => O_ALL & ~O_REGISTER & ~O_LOCALREG,
	    Version => 6,
	},
    }, $class;
    my $stat = $new->{stat};

    for my $o (qw/Warning Version Trace/) {
	$stat->{$o} = $option{$o} if defined $option{$o};
    }
    if (defined(my $opt = $option{Optimize})) {
	if ($opt =~ /^\d+$/) {
	    $stat->{Optimize} = $opt;
	} else {
	    my $o = $stat->{Optimize};
	    my @o = split /[\s|]+/, $opt;

	    for (@o) {
		if (/^-/) {
		    s/^-//;
		    carp "Unknown optimize option '$_'" unless exists $O{$_};
		    $o &= ~$O{$_};
		} else {
		    carp "Unknown optimize option '$_'" unless exists $O{$_};
		    $o |= $O{$_};
		}
	    }
	    $stat->{Optimize} = $o;
	}
    }
    if ($stat->{Optimize} & O_LOCALREG) {
	$stat->{Optimize} |= O_REGISTER;
	if ($new->{stat}{Version} < 6) {
	    $new->_error('O_LOCALREG can use SWF version 6 or later.');
	}
    }

    return $new;
}

sub compile {
    my ($self, $actions) = @_;
    my $tree = $self->source_elements;
    my $option = $actions||'';

    $tree->_tree_dump, return if $option eq 'tree';
    $tree->compile;
    $self->_tidy_up;
    $self->_code_print, return if $option eq 'text';
    $actions = SWF::Element::Array::ACTIONRECORDARRAY->new unless ref($actions);
    $self->_encode($actions);
    $actions->dumper, return if $option eq 'dump';
    $actions;
}

sub assemble {
    my ($self, $actions) = @_;
    my $option = $actions||'';

    push @{$self->{stat}{code}}, grep /[^#]/, split /[$nl]/, $self->{text};
    $self->_tidy_up;
    $self->_code_print, return if $option eq 'text';
    $actions = SWF::Element::Array::ACTIONRECORDARRAY->new unless ref($actions);
    $self->_encode($actions);
    $actions->dumper, return if $option eq 'dump';
    $actions;
}

### parser


my %reserved = (
		null       => ['', 'NULLLiteral'],
		undefined  => ['', 'UNDEFLiteral'],
		true       => [1, 'BooleanLiteral'],
		false      => [0, 'BooleanLiteral'],
		newline    => ["\n", 'StringLiteral'],

		add        => 'AddOp',
		and        => 'AndOp',
		break      => 'Statement',
		case       => 'Label',
		continue   => 'Statement',
		default    => 'Label',
		delete     => 'DeleteOp',
		do         => 'Statement',
		else       => 'Else',
		eq         => 'EqOp',
		for        => 'Statement',
		function   => 'Function',
		ge         => 'Relop',
		gt         => 'Relop',
		if         => 'Statement',
		ifFrameLoaded
		           => 'Statement',
		in         => 'In',
		instanceof => 'RelOp',
		le         => 'Relop',
		lt         => 'Relop',
		ne         => 'Eqop',
		new        => 'New',
		not        => 'UnaryOp',
		or         => 'OrOp',
		return     => 'Statement',
		switch     => 'Statement',
		tellTarget => 'Statement',
		typeof     => 'UnaryOp',
		var        => 'Statement',
		void       => 'UnaryOp',
		while      => 'Statement',
		with       => 'Statement',

		abstract   => 'Reserved',
#		boolean    => 'Reserved',
		byte       => 'Reserved',
		catch      => 'Reserved',
		char       => 'Reserved',
		class      => 'Reserved',
		const      => 'Reserved',
		debugger   => 'Reserved',
		double     => 'Reserved',
		enum       => 'Reserved',
		export     => 'Reserved',
		extends    => 'Reserved',
		finally    => 'Reserved',
		final      => 'Reserved',
		float      => 'Reserved',
		goto       => 'Reserved',
		implements => 'Reserved',
		import     => 'Reserved',
#		int        => 'Reserved',
		interface  => 'Reserved',
		long       => 'Reserved',
		native     => 'Reserved',
		package    => 'Reserved',
		private    => 'Reserved',
		protected  => 'Reserved',
		public     => 'Reserved',
		short      => 'Reserved',
		static     => 'Reserved',
		synchronized
		           => 'Reserved',
		throws     => 'Reserved',
		throw      => 'Reserved',
		transient  => 'Reserved',
		try        => 'Reserved',
		volatile   => 'Reserved',
	);

my %property;
@property{ qw / _x           _y           _xscale       _yscale
	       _currentframe _totalframes _alpha        _visible
	       _width        _height      _rotation     _target
	       _framesloaded _name        _droptarget   _url
	       _highquality  _focusrect   _soundbuftime _quality
	       _xmouse       _ymouse / 
	  } = (0..21);

my %ops = ('=' => 'AssignmentOp', 
	   '+' => 'AddOp',
	   '-' => 'AddOp',
	   '<' => 'RelOp',
	   '>' => 'RelOp',
	   '*' => 'MultOp',
	   '/' => 'MultOp',
	   '%' => 'MultOp',
	   '&' => 'BitAndOp',
	   '^' => 'BitXorOp',
	   '|' => 'BitOrOp',
	   '~' => 'UnaryOp',
	   '!' => 'UnaryOp',
	   '?' => 'ConditionalOp',
	   ':' => ':',
	   );

=begin comment

$self->_get_token(@token);

get the next token. return ($token_text, $token_type, $line_terminator_count).
$num_line_terminator is a number of skipped line terminator or newline.
it is used for automatic semicolon insertion.

=cut

sub _get_token {
    my $self = shift;
    my $ln = 0;
    my @token;

    if (@{$self->{ungets}}) {
	@token = @{pop @{$self->{ungets}}};
	$self->{line}+=$token[2];
	return @token;
    }

    for ($self->{text}) {
	s/\A(?:[\x09\x0b\x0c\x20\xa0\p{IsZs}]|\/\/.+?(?=[$nl])|\/\*[^$nl]*?\*\/)+//o
	    and redo;
	s/\A((?:\/\*.*?[$nl].*?\*\/|[$nl])(?:\/\*.*?\*\/|\/\/.*?[$nl]|\s)*)//os
	    and do {
		my $ln1 = scalar($1=~tr/\x0a\x0d\x{2028}\x{2029}/\x0a\x0d\x{2028}\x{2029}/);
		$self->{line} += $ln1;
		$ln += $ln1;
		redo;
	    };
	s/\A([_\$\p{IsLl}\p{IsLu}\p{IsLt}\p{IsLm}\p{IsLo}\p{IsNl}][\$\w]*)//
	    and do {
		my $key = $1;
		return ((ref($reserved{$key})? @{$reserved{$key}} : ($key, $reserved{$key}||(exists $property{lc($key)} ? 'Property' : 'Identifier'))), $ln);
	    };
	s/\A\"((?>(?:[^\"\\]|\\.)*))\"//s
	    and do {
		my $s = $1;
		$self->{line}+=scalar($s=~tr/\x0a\x0d\x{2028}\x{2029}/\x0a\x0d\x{2028}\x{2029}/);
                $s=~s/(\\*)\'/$1.(length($1)%2==1?"'":"\\'")/ge;
		return ($s, 'StringLiteral', $ln);
	    };
	s/\A\'((?>(?:[^\'\\]|\\.)*))\'//s
	    and do {
		my $s = $1;
		$self->{line}+=scalar($s=~tr/\x0a\x0d\x{2028}\x{2029}/\x0a\x0d\x{2028}\x{2029}/);
		return ($s, 'StringLiteral', $ln);
	    };

        m/\A0/                   and
        ( s/\A(0[0-7]+)//i       or
	  s/\A(0x[0-9a-f]+)//i   or
	  s/\A(0b[01]+)//i  )    and return (oct($1), 'NumberLiteral', $ln);
        s/\A((?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?)//
         	                 and return ($1, 'NumberLiteral', $ln);

	s/\A\;//                 and return (';', 'StatementTerminator', $ln);
	s/\A([.,(){}\[\]])//     and return ($1, $1, $ln);
	s/\A\&&//                and return ('&&', 'AndOp', $ln);
	s/\A\|\|//               and return ('||', 'OrOp', $ln);
	s/\A\+\+//               and return ('++', 'PrefixOp', $ln);
	s/\A\-\-//               and return ('--', 'PrefixOp', $ln);
	s/\A([*\/%+\-&^|]=)//     and return ($1, 'AssignmentOp', $ln);
	s/\A\<<=//               and return ('<<=', 'AssignmentOp', $ln);
	s/\A\>>>=//              and return ('>>>=', 'AssignmentOp', $ln);
	s/\A\>>=//               and return ('>>=', 'AssignmentOp', $ln);
	s/\A\<<//                and return ('<<', 'ShiftOp', $ln);
	s/\A\>>>//               and return ('>>>', 'ShiftOp', $ln);
	s/\A\>>//                and return ('>>', 'ShiftOp', $ln);
	s/\A\<=//                and return ('<=', 'RelOp', $ln);
	s/\A\>=//                and return ('>=', 'RelOp', $ln);
	s/\A([!=]==?)//          and return ($1, 'EqOp', $ln);
	s/\A([=+\-<>*\/%&^|~!?:])//
                                 and return ($1, $ops{$1}, $ln);

	s/\A\#([^$nl]+)[$nl]//os
	    and do {
		$self->{line}++;
		return ($1, 'Pragma', $ln);
	    };
    }

    return ('', '', $ln);

}

sub identifier {
    my $self = shift;
    my @token = $self->_get_token;
    my $t = $token[1];

    unless ($t eq 'Identifier' or $t eq 'Property' or $t eq 'Reserved') {
	$self->_unget_token(@token);
	return;
    }
    if ($t eq 'Reserved') {
	$self->_warn(2, '"%s" should not use as an identifier because it is reserved future', $token[0]);
    }
    return $token[0];
}

=begin comment

$self->_unget_token(@token);

unget the token. 

=cut

sub _unget_token {
    my ($self, @token) = @_;

    push @{$self->{ungets}}, [@token];
    $self->{line}-=$token[2];
}

=begin comment

$self->_check_token($tokens);

take $tokens for the token type(s) to check. text for one token,
and arrayref for two or more tokens.
if $tokens matched the next token, read(skip) and return the token.
if not match, unget the token and return undef.

=cut

sub _check_token {
    my ($self, $tokens) = @_;

    $tokens = [$tokens] unless ref($tokens);
    my @token = $self->_get_token;
    if (@token) {
	for my $c (@$tokens) {
	    return @token if $c eq $token[1];
	}
	$self->_unget_token(@token);
    }
    return;
}

sub _check_token_fatal {
    my @token = &_check_token;
    $_[0]->_error($_[2]||'Syntax error') unless $token[1];
    return @token;
}

=begin comment

$keep = $self->_keep_context;

keep the compiler context to $keep.

=cut

use Storable 'dclone';

sub _keep_context {
    my $self = shift;
    return {
	text => $self->{text},
	line => $self->{line},
	scope => $self->{scope}[-1] ? dclone($self->{scope}) : [],
	ungets => [@{$self->{ungets}}],
	};
}

=begin comment

$self->_restore_context($keep);

restore the kept context.

=cut

sub _restore_context {
    my ($self, $keep) = @_;
    $self->{text} = $keep->{text};
    $self->{line} = $keep->{line};
    $self->{scope} = $keep->{scope};
    $self->{ungets} = $keep->{ungets};
}

sub new_node {
    my ($self, $node) = @_;

    bless { line => $self->{line}, stat => $self->{stat}, node => [], regvars => $self->{regvars}[-1]}, "SWF::Builder::ActionScript::SyntaxNode::$node";
}

sub new_scope {
    my $self = shift;
    return unless $self->{stat}{Optimize} & O_REGISTER;

    my $scope = {
	vars => {
	    this      => { count => 0, start => 0, end => 0, preload => 1 },
	    arguments => { count => 0, start => 0, end => 0, preload => 1 },
	    super     => { count => 0, start => 0, end => 0, preload => 1 },
	    _root     => { count => 0, start => 0, end => 0, preload => 1 },
	    _parent   => { count => 0, start => 0, end => 0, preload => 1 },
	    _global   => { count => 0, start => 0, end => 0, preload => 1 },
	},
	count   => 0,   # node count
	preload => [],  # variables to need to preload
    };
    push @{$self->{scope}}, $scope;
    push @{$self->{regvars}}, {};
}

sub exit_scope {  # assign local variables to registers.
    my $self = shift;
    return unless $self->{stat}{Optimize} & O_REGISTER;
    my $scope = pop @{$self->{scope}};
    my $regvars = pop @{$self->{regvars}};
    my $reg_count = ($self->{stat}{Optimize} & O_LOCALREG) ? 255 : 3;
    my $node_count = $scope->{count};
    my $vars = $scope->{vars};

    my @vars;
    my $null = pack("b$node_count", '0' x $node_count);
    my @regmap = ($null) x $reg_count;
    my $regno = 0;

    if ($self->{stat}{Optimize} & O_LOCALREG) {
	for my $prevar (qw/ this arguments super _root _parent _global /) {
	    next if $vars->{$prevar}{count} <= 0;
	    my $v_start = $vars->{$prevar}{start};
	    my $v_end = $vars->{$prevar}{end};
	    $regmap[$regno] |= pack("b$node_count", '0' x $v_start . '1' x ($v_end - $v_start + 1));
	    $regvars->{$prevar} = ++$regno;
	}
	@vars = sort{$vars->{$b}{count}<=>$vars->{$a}{count}} grep {$vars->{$_}{count} > 0 and !exists($regvars->{$_})} keys %$vars;
    } else {
	@vars = sort{$vars->{$b}{count}<=>$vars->{$a}{count}} grep {$vars->{$_}{count} > $vars->{$_}{preload}} keys %$vars;
    }

    for my $v (@vars) {
	my $v_start = $vars->{$v}{start};
	my $v_end = $vars->{$v}{end};
	my $v_bits = pack("b$node_count", '0' x $v_start . '1' x ($v_end - $v_start + 1));
	for (my $i = 0; $i < $reg_count; $i++) {
	    next if (($regmap[$i] & $v_bits) ne $null) ;
	    $regmap[$i] |= $v_bits;
	    $regvars->{$v} = $i+1;
	    last;
	}
    }

    my $i = 0;
    while ( $i < $reg_count ) {
	last if ($regmap[$i++] eq $null) ;
    }
    $regvars->{' regcount'} = $i;
}

sub countup_node {
    my $self = shift;
    return unless $self->{stat}{Optimize} & O_REGISTER;
    $self->{scope}[-1]{count}++;
}

sub add_var {
    my ($self, $var, $initcount, $preload) = @_;
    return unless $self->{stat}{Optimize} & O_REGISTER;
    my $scope = $self->{scope}[-1];
    return unless defined $scope;  # top level (not in function).
    my $vars = $scope->{vars};
    $self->_error("Variable '%s' is already declared", $var) if exists $vars->{$var};
    $vars->{$var} = {count => $initcount, start => $scope->{count}, end => $scope->{count}, preload => $preload};
}

sub use_var { 
    my ($self, $var) = @_;
    return unless $self->{stat}{Optimize} & O_REGISTER;
    my $scope = $self->{scope}[-1];
    return unless defined $scope;  # top level (not in function).

    my  $vars = $scope->{vars};
    if (exists $vars->{$var}) { # if $var is declared in the current scope...

# negative count means the var should not be assigned to register
# (using in the inner scope).

	return if ($vars->{$var}{count} < 0);	

# count up $var.
# $_x are treated as register variables. weighted.

	$vars->{$var}{end} = $scope->{count};
	if ($vars->{$var}{count} == 0 and !(($self->{stat}{Optimize} & O_LOCALREG) and $vars->{$var}{preload}) ) {
	    $vars->{$var}{start} = $scope->{count};
	    push @{$scope->{preload}}, $var;
	}
	if ($var =~ /^\$_/) {
	    $vars->{$var}{count} += 100;
	} else {
	    $vars->{$var}{count}++;
	}
    } else { # search outer scope.
	my $i = -1;
	while (defined($scope = $self->{scope}[--$i])) {
	    my $vars = $scope->{vars};
	    if (exists $vars->{$var} and $vars->{$var}{count} >= 0) {

# If the var is declared in the outer scope,
# it should not be assigned to register. negate.

		$vars->{$var}{count} = -$vars->{$var}{count}-1;
		last;
	    }
	}
    }
}

sub source_elements {
    my $self = shift;
    my ($c, $cf);
    my $node = $self->new_node('SourceElements');

    while($c = ($self->function_declaration || $self->statement)) {
	if (ref($c)=~/:Function$/) {
	    $node->unshift_node($c);
	} else {
	    $node->add_node($c);
	}
	$cf = 1;
    }
    return ((defined $cf) ? $node : undef);
}

sub function_declaration {
    my $self = shift;

    $self->_check_token('Function') or return;

    my $name = $self->identifier;
    $self->_error('Function name is necessary to declare function') unless $name;

    $self->function_expression($name);
}


sub statement {
    my $self = shift;
    my @token = $self->_get_token;
    return unless $token[1];
    for($token[1]) {
	/^\{$/ and do {
	    my $statements = $self->new_node('StatementBlock');
	    $statements->add_node($self->statement) until $self->_check_token('}');
	    return $statements;
	};
	/^StatementTerminator$/ and return $self->new_node('NullStatement');
        /^Statement$/ and do {
	    for ($token[0]) {
		/^var$/ and do {
		    my $r = $self->variable_declaration_list;
		    $self->_statement_terminator;
		    return $r;
		};
		/^if$/     and return $self->if_statement;
		/^for$/    and return $self->for_statement;
		/^do$/     and return $self->do_while_statement;
		/^while$/  and return $self->while_statement;
		/^with$/   and return $self->with_statement;
		/^switch$/ and return $self->switch_statement;

		/^ifFrameLoaded$/ and return $self->ifframeloaded_statement;
		/^tellTarget$/    and return $self->telltarget_statement;

# simple actions.
		/^continue$/ and do {
		    $self->_statement_terminator;
		    return $self->new_node('ContinueStatement');

		};
		/^break$/ and do {
		    $self->_statement_terminator;
		    return $self->new_node('BreakStatement');
		};
		/^return$/ and do {
		    my $n = $self->new_node('ReturnStatement');
		    eval{$self->_statement_terminator};
		    if ($@) {
			die if $@!~/^Syntax/;
			my $e = $self->expression or $self->_error('Syntax error.');
			$n->add_node($e);
			$self->_statement_terminator;
		    }
		    return $n;
		};

		$self->_error('Syntax error');
	    }
	};
	/^Pragma$/ and do {
	    $self->_warn(2, 'Pragma is not supported');
	};
    }
    $self->_unget_token(@token);
    $self->expression_statement;
}

sub variable_declaration_list {
    my $self = shift;
    my $node = $self->new_node('VariableDeclarationList');
    do {
	my $v = $self->variable_declaration;
	$node->add_node($v);
    } while ($self->_check_token(','));
    return $node;
}

sub variable_declaration {
    my $self = shift;
    my $i = $self->identifier or $self->_error("Error token '%s', identifier expected.", ($self->_get_token)[0]);
    my $n = $self->new_node('VariableDeclaration');
    if (my @op = $self->_check_token('AssignmentOp')) {
	$self->_error("Syntax error") if $op[0] ne '=';
	$self->add_var($i, 1);
	my $e = $self->assignment_expression or $self->_error("Syntax error");
	$n->add_node($i, $e);
	return bless $n, 'SWF::Builder::ActionScript::SyntaxNode::VariableDeclarationWithParam';
    } else {
	$self->add_var($i, 0);
	$n->add_node($i);
	return $n;
    }
}

sub telltarget_statement {
    my $self = shift;

    $self->_warn_not_recommend("'tellTarget' action", "'with'");
    $self->_check_token_fatal('(');
    my $e = $self->expression or $self->_error("Target movieclip is needed in 'tellTarget'.");
    my $n = $self->new_node('TellTargetStatement');
    $n->add_node($e);
    $self->_check_token_fatal(')');
    $n->add_node($self->statement);
    return $n;
}

sub ifframeloaded_statement {
    my $self = shift;

    $self->_warn_not_recommend("'ifFrameLoaded' action", " property");
    $self->_check_token_fatal('('); 
    my $e = $self->expression or $self->_error("Frame number is needed in 'ifFrameLoaded'.");
    my $n = $self->new_node('IfFrameLoadedStatement');
    $n->add_node($e);
    $self->_check_token_fatal(')');
    $n->add_node($self->statement);
    return $n;
}

sub switch_statement {
    my $self = shift;
    my $default;
    $self->_check_token_fatal('(');
    my $e = $self->expression or $self->_error("Object expression is needed in 'switch'.");
    $self->_check_token_fatal(')');
    $self->_check_token_fatal('{');
    my $n = $self->new_node('SwitchStatement');
    $n->add_node($e);

    while (my @token = $self->_check_token('Label')) {
	if ($token[0] eq 'case') {
	    my $e = $self->expression or $self->_error('Missing case expression.');
	    $self->_check_token_fatal(':');
	    my $case = $self->new_node('CaseClause');
	    $case->add_node($e);
	    my $statements = $self->new_node('StatementBlock');
	    my @token;
	    until (@token = $self->_check_token(['Label', '}'])) {
		$statements->add_node($self->statement);
	    }
	    $self->_unget_token(@token);
	    $case->add_node($statements);
	    $n->add_node($case);
	} else {
	    $self->_check_token_fatal(':');
	    $default = $self->new_node('StatementBlock');
	    my @token;
	    until (@token = $self->_check_token(['Label', '}'])) {
		$default->add_node($self->statement);
	    }
	    $self->_unget_token(@token);
	    last;
	}
    }
    $self->_check_token_fatal('}');
    $n->add_node($default);
    return $n;
}

sub with_statement {
    my $self = shift;
    $self->_check_token_fatal('(');
    my $e = $self->expression or $self->_error("Object expression is needed in 'with'.");
    $self->_check_token_fatal(')');
    my $n = $self->new_node('WithStatement');
    $n->add_node($e);
    $self->{stat}{with}++;
    $n->add_node($self->statement);
    $self->{stat}{with}--;
    return $n;
}

sub while_statement {
    my $self = shift;
    $self->_check_token_fatal('(');
    my $e = undef;
    unless ($self->_check_token(')')) {
	$e = $self->expression or $self->_error('Syntax error');
	$self->_check_token_fatal(')');
    }
    my $s = $self->statement;
    if ($self->{stat}{Optimize} & O_CONSTEXP and $e and $e->isa('SWF::Builder::ActionScript::SyntaxNode::Literal')) {
	if ($e->istrue) {
	    $e = undef;
	} else {
	    return $self->new_node('NullStatement');
	}
    }
    my $n = $self->new_node('WhileStatement');
    $n->add_node($e, $s);
    return $n;
}

sub do_while_statement {
    my $self = shift;

    my $s = $self->statement;
    my @token = $self->_check_token_fatal('Statement');
    $self->_error("'do' without 'while'.") if $token[0] ne 'while';
    $self->_check_token_fatal('(');
    my $e = undef;
    unless ($self->_check_token(')')) {
	$e = $self->expression or $self->_error('Syntax error');
	$self->_check_token_fatal(')');
    }
    if ($self->{stat}{Optimize} & O_CONSTEXP and $e and $e->isa('SWF::Builder::ActionScript::SyntaxNode::Literal')) {
	if ($e->istrue) {
	    $e = undef;
	} else {
	    return $s;
	}
    }
    my $n = $self->new_node('DoWhileStatement');
    $n->add_node($s, $e);

    return $n;
}

sub if_statement {
    my $self = shift;
    my $line = $self->{line};

    $self->_check_token_fatal('(');
    my $e = undef;
    unless ($self->_check_token(')')) {
	$e = $self->expression or $self->_error('Syntax error');
	$self->_check_token_fatal(')');
    }
    my $then = $self->statement;
    my $else;
    if ($self->_check_token('Else')) {
	$else = $self->statement;
    }
    if ($self->{stat}{Optimize} & O_CONSTEXP and $e and $e->isa('SWF::Builder::ActionScript::SyntaxNode::Literal')) {
	if ($e->istrue) {
	    return $then;
	} else {
	    return ($else || $self->new_node('NullStatement'));
	}
    } else {
	my $n = $self->new_node('IfStatement');
	$n->add_node($e, $then);
	$n->add_node($else) if $else;
	return $n;
    }
}

sub for_statement {
    my $self = shift;

    $self->_check_token_fatal('(');
    my $keep = $self->_keep_context;
    {
	my $n = $self->new_node('ForStatement');
	if (my @token = $self->_check_token('Statement')) {
	    $self->_error('Syntax error.') if $token[0] ne 'var';
	    $n->add_node($self->variable_declaration_list);
	    $self->_check_token('StatementTerminator') or last;
	} else {
	    unless ($self->_check_token('StatementTerminator')) {
		$n->add_node($self->expression);
		$self->_check_token('StatementTerminator') or last;
	    } else {
		$n->add_node(undef);
	    }
	}
	unless ($self->_check_token('StatementTerminator')) {
	    $n->add_node($self->expression);
	    $self->_check_token_fatal('StatementTerminator');
	} else {
	    $n->add_node(undef);
	}
	unless ($self->_check_token(')')) {
	    $n->add_node($self->expression);
	    $self->_check_token_fatal(')');
	} else {
	    $n->add_node(undef);
	}
	$n->add_node($self->statement);
	return $n;
    }
    {
	$self->_restore_context($keep);

	my $n = $self->new_node('ForEachStatement');
	if (my @token = $self->_check_token('Statement')) {
	    $self->_error('Syntax error.') if $token[0] ne 'var';
	    $n->add_node($self->variable_declaration);
	} else {
	    my $l = ($self->call_or_member_expression);
	    for (defined($l) and ref($l->{node}[-1])||ref($l)) {
		$self->_error("Left hand side of 'in' must be a variable or a property.") unless /:Variable$/ or /:Property$/ or /:Member$/ or ($self->{stat}{Version}<=5 and /:Arguments$/ and $l->{node}[0]{node}[0] eq 'eval');
	    }
	    $n->add_node($l);
	}
	$self->_check_token_fatal('In');
	my $e = $self->expression or $self->_error('Syntax error.');
	$n->add_node($e);
	$self->_check_token_fatal(')');
	$n->add_node($self->statement);
	return $n;
    }
}

sub assignment_expression {
    my $self = shift;

    if (my $l = $self->conditional_expression) {
	my @op = $self->_get_token;
	if ($op[1] eq 'AssignmentOp') {
	    $self->_error("$_ Left hand side of '%s' must be a variable or a property.", $op[0]) unless $l->_lhs;
	    my $v = $self->assignment_expression or $self->_error("Operator '%s' needs an operand.", $op[0]);
	    my $n = $self->new_node('AssignmentExpression');
	    $n->add_node($l, $op[0], $v);
	    return $n;
	} else {
	    $self->_unget_token(@op);
	    return $l;
	}
    }
    return;
}

sub conditional_expression {
    my $self = shift;

    my $e = $self->binary_op_expression or return;
    $self->_check_token('ConditionalOp') or return $e;
    ( my $a1 = $self->assignment_expression and
      $self->_check_token(':') and
      my $a2 = $self->assignment_expression )
	or $self->_error('Syntax error');
    if ($self->{stat}{Optimize} & O_CONSTEXP and $e->isa('SWF::Builder::ActionScript::SyntaxNode::Literal')) {
	return $e->istrue ? $a1 : $a2;
    }
    my $n = $self->new_node('ConditionalExpression');
    $n->add_node($e, $a1, $a2);
    return $n;
}

{
    my @bin_op = (qw/ OrOp AndOp BitOrOp BitXorOp BitAndOp EqOp RelOp ShiftOp AddOp MultOp /);
    my %literal_op_sub =
	( '*'   => ['_binop_numbers', sub{$_[0] * $_[1]}],
	  '/'   => ['_binop_numbers',
		    sub{
			my ($dividend, $divisor) = @_;
			if ($divisor == 0) {
			    return $INFINITY * ($dividend <=> 0);
			} else {
			    return $dividend / $divisor;
			}
		    }
		    ],
	  '%'   => ['_binop_numbers', sub{$_[0] % $_[1]}],
	  '+'   => ['_binop_Add2'],
	  '-'   => ['_binop_numbers', sub{$_[0] - $_[1]}],
	  '<<'  => ['_binop_numbers', sub{(abs($_[0])<<$_[1])*($_[0]<=>0)}],
	  '>>>' => ['_binop_numbers', sub{$_[0] >> $_[1]}],
	  '>>'  => ['_binop_numbers', sub{(abs($_[0])>>$_[1])*($_[0]<=>0)}],
	  '<='  => ['_binop_rel', sub {$_[0] <= $_[1]}, sub {$_[0] le $_[1]}],
	  '>='  => ['_binop_rel', sub {$_[0] >= $_[1]}, sub {$_[0] ge $_[1]}],
	  '<'   => ['_binop_rel', sub {$_[0] < $_[1]}, sub {$_[0] lt $_[1]}],
	  '>'   => ['_binop_rel', sub {$_[0] > $_[1]}, sub {$_[0] gt $_[1]}],
	  '===' => ['_binop_StrictEquals'],
	  '!==' => ['_binop_StrictEqualsNot'],
	  '=='  => ['_binop_Equals2'],
	  '!='  => ['_binop_Equals2Not'],
	  '&'   => ['_binop_numbers', sub{$_[0] & $_[1]}],
	  '^'   => ['_binop_numbers', sub{$_[0] ^ $_[1]}],
	  '|'   => ['_binop_numbers', sub{$_[0] | $_[1]}],
	  '&&'  => ['_binop_LogicalAnd'],
	  '||'  => ['_binop_LogicalOr'],
	  
	  'add' => ['_binop_strings', sub{$_[0].$_[1]}],
	  'eq'  => ['_binop_strings', sub{$_[0] eq $_[1]}],
	  'ne'  => ['_binop_strings', sub{$_[0] ne $_[1]}],
	  'ge'  => ['_binop_strings', sub{$_[0] ge $_[1]}],
	  'gt'  => ['_binop_strings', sub{$_[0] gt $_[1]}],
	  'le'  => ['_binop_strings', sub{$_[0] le $_[1]}],
	  'lt'  => ['_binop_strings', sub{$_[0] lt $_[1]}],
	  'and' => ['_binop_booleans', sub{$_[0] && $_[1]}],
	  'or'  => ['_binop_booleans', sub{$_[0] || $_[1]}],
	  );

    sub binary_op_expression {
	my ($self, $step) = @_;
	$step ||= 0;
	{
	    my (@op, $f);
	    my $next = ($step >= 9) ? 'unary_expression' : 'binary_op_expression';
	    my $e1 = $self->$next($step+1) or return;
	    my $n = $self->new_node('BinaryOpExpression');
	    $n->add_node($e1);
	    while((@op = $self->_get_token)[1] eq $bin_op[$step]) {
		my $e = $self->$next($step+1) or last;
		if (!$f and $self->{stat}{Optimize} & O_CONSTEXP and 
		    $e1->isa('SWF::Builder::ActionScript::SyntaxNode::Literal') and
		    (
		     $e ->isa('SWF::Builder::ActionScript::SyntaxNode::Literal') or
		     $op[0] eq '&&' or
		     $op[0] eq '||')) {
		    my ($op, @op_param) = @{$literal_op_sub{$op[0]}};
		    $e1 = $e1->$op($e, @op_param);
		    next;
		} else {
		    $f = 1;
		}
		$n->add_node($e, $op[0]);
		$e1=$e;
	    }
	    $self->_unget_token(@op);
	    unless ($f) {
		return $e1;
	    } elsif ($step <= 1) {
		return bless $n, 'SWF::Builder::ActionScript::SyntaxNode::'.$bin_op[$step].'Expression';
	    } else {
		return $n;
	    }
	}
	return;
    }
}

{
    my %literal_unaryop =
	( '!' => sub {
	    my $l = shift->toboolean;
	    $l->{node}[0] = -($l->{node}[0] - 1);
	    return $l;
	},
	  '~' => sub {
	      my $l = shift->tonumber;
	      return $l if $l->isa('SWF::Builder::ActionScript::SyntaxNode::NaN');
	      if ($l->isa('SWF::Builder::ActionScript::SyntaxNode::Infinity')) {
		  $l->{node}[0] = -1;
		  return bless $l, 'SWF::Builder::ActionScript::SyntaxNode::NumberLiteral';
	      } else {
		  $l->{node}[0] = ~($l->{node}[0]);
		  return $l;
	      }
	  },
	  '-' => sub {
	      my $l = shift->tonumber;
	      return $l if $l->isa('SWF::Builder::ActionScript::SyntaxNode::NaN');
	      $l->{node}[0] = -($l->{node}[0]);
	      return $l;
	  },
	  '+' => sub {
	      return shift->tonumber;
	  },
	  );
    
    sub unary_expression {
	my $self = shift;
	my @unaryop = $self->_get_token;

	if ($unaryop[1] eq 'UnaryOp' or $unaryop[0] eq '-' or $unaryop[0] eq '+') {
	    my $e = $self->unary_expression or $self->_error('Syntax error');
	    if ($self->{stat}{Optimize} & O_CONSTEXP and 
		$e->isa('SWF::Builder::ActionScript::SyntaxNode::Literal')) {
		return $literal_unaryop{$unaryop[0]}->($e);
	    } else {
		my $n = $self->new_node('UnaryExpression');
		$n->add_node($e, $unaryop[0]);
		return $n;
	    }
	} elsif ($unaryop[1] eq 'PrefixOp') {
	    my $e = $self->unary_expression;
	    $self->_error("Operator '%s' can modify only a variable or a property.", $unaryop[0]) unless $e->_lhs;
	    my $n = $self->new_node('PrefixExpression');
	    $n->add_node($e, $unaryop[0]);
	    return $n;
	} elsif ($unaryop[1] eq 'DeleteOp') {
	    my $n = $self->new_node('DeleteExpression');
	    $n->add_node($self->unary_expression, $unaryop[0]);
	    return $n;
	} else {
	    $self->_unget_token(@unaryop);
	    return $self->postfix_expression;
	}
    }
}

sub postfix_expression {
    my $self = shift;

    my $e = ($self->call_or_member_expression) or return;
    my @postop = $self->_get_token;
    if ($postop[0] eq '++' or $postop[0] eq '--') {
	if ($postop[2]>=1) {
	    $self->_unget_token(@postop);
	    $self->_unget_token(';', 'StatementTerminator', 0);
	    return $e;
	} else {
	    my $n = $self->new_node('PostfixExpression');
	    $n->add_node($e, $postop[0]);
	    return $n;
	}
    } else {
	$self->_unget_token(@postop);
	return $e;
    }
}

sub call_or_member_expression {
    my $self = shift;

    my $name = $self->member_expression or return;

    return $name unless ($self->_check_token('('));

    my $args = $self->arguments or $self->_error('Syntax error');
    my (@members, @methods, @token);

  CALL_MEMBER_LOOP:
    for(;;) {
	my $m;
	@token = $self->_get_token;
	for ($token[1]) {
	    /^\($/ and do {
		$m = $self->arguments or $self->_error('Arguments are needed');
		push @methods, $m;
		if (@members == 0 or ref($members[-1])=~/:MethodCall$/) {
		    push @members, $self->new_node('MethodCall');
		    $members[-1]->add_node('');
		} else {
		    bless $members[-1], 'SWF::Builder::ActionScript::SyntaxNode::MethodCall';
		}
		last;
	    };
	    /^\.$/ and do {
		$m = $self->member or $self->_error('Member identifier is needed');
		push @members, $m;
		last;
	    };
	    /^\[$/ and do {
		$m = $self->subscript or $self->_error('Member expression is needed');
		push @members, $m;
		last;
	    };
	    last CALL_MEMBER_LOOP;
	}
    }
    $self->_unget_token(@token);
    
  FUNCtoLITERAL:
    {
	if (@members == 0 and @methods == 0 and $self->{stat}{Optimize} & O_CONSTMATH) {
	    my $sub;
	    if (ref($name)=~/:Variable$/) {
		$sub = '_f_'.lc($name->{node}[0]);
	    } elsif (ref($name)=~/:MemberExpression/ and lc($name->{node}[0]{node}[0]) eq 'math' and @{$name->{node}} == 2) {
		$sub = '_math_'.lc($name->{node}[1]{node}[0]);
	    } else {
		last FUNCtoLITERAL;
	    }
	    my @args;
	    for my $a (@{$args->{node}}) {
		last FUNCtoLITERAL unless ($a->isa('SWF::Builder::ActionScript::SyntaxNode::Literal'));
		push @args, $a;
	    }
	    last FUNCtoLITERAL if @args<=0;
	    last FUNCtoLITERAL unless $sub = $args[0]->can($sub);
	    return &$sub(@args);
	}
    }
    my $n = $self->new_node('CallExpression');
    $n->add_node($name, $args, \@members, \@methods);
    return $n;
}

{
    my %const_prop = (
		  key_backspace =>  8,
		  key_capslock  => 20,
		  key_control   => 17,
		  key_deletekey => 46,
		  key_down      => 40,
		  key_end       => 35,
		  key_enter     => 13,
		  key_escape    => 27,
		  key_home      => 36,
		  key_insert    => 45,
		  key_left      => 37,
		  key_pgdn      => 34,
		  key_pgup      => 33,
		  key_right     => 39,
		  key_shift     => 16,
		  key_space     => 32,
		  key_tab       =>  9,
		  key_up        => 38,

		  math_e        => 2.71828182845905,
		  math_ln2      => 0.693147180559945,
		  math_ln10     => 2.30258509299405,
		  math_log2e    => 1.44269504088896,
		  math_log10e   => 0.434294481903252,
		  math_pi       => 3.14159265358979,
		  math_sqrt1_2  => 0.707106781186548,
		  math_sqrt2    => 1.4142135623731,

		  number_max_value => 1.79769313486231e+308,
		  number_min_value => 4.94065645841247e-324,
		  number_nan       => 'NaN',
		  number_negative_infinity => -$INFINITY,
		  number_positive_infinity =>  $INFINITY,
		  
		  );

    sub member_expression {
	my $self = shift;
	
	my @tree;
	my @token = $self->_get_token;
	for ($token[1]) {
	    (/^Identifier$/ or /^Reserved$/) and do {
		my $n = $self->new_node('Variable');
		$n->add_node($token[0]);
		$self->use_var($token[0]);
		push @tree, $n;
		last;
	    };
	    /Literal$/ and do {
		my $n = $self->new_node($token[1]);
		$n->add_node($token[0]);
		push @tree, $n;
		last;
	    };
	    /^Function$/ and do{
		push @tree, $self->function_expression('');
		last;
	    };
	    /^New$/ and do {
		my $m = $self->member_expression or $self->_error("Invalid expression in 'new'");
		my $newex = $self->new_node('NewExpression');
		if ($self->_check_token('(')) {
		    my $args = $self->arguments or $self->_error('Syntax error00');
		    $newex->add_node($m, $args);
		} else {
		    $newex->add_node($m, $self->new_node('Arguments'));
		}
		push @tree, $newex;
		last;
	    };
	    /^\(/ and do {
		my $e = $self->expression;
		$self->_check_token_fatal(')');
		push @tree, $e;
		last;
	    };
	    /^\{/ and do {
		push @tree, $self->object_literal;
		last;
	    };
	    /^\[/ and do {
		push @tree, $self->array_literal;
		last;
	    };
	    /^Property$/ and do {
		my $n = $self->new_node($self->{stat}{with}>0 ? 'Variable' : 'Property');
		$n->add_node($token[0]);
		push @tree, $n;
		last;
	    };
	    $self->_unget_token(@token);
	    return;
	}
	
      MEMBER_LOOP:
	for (;;){
	    @token = $self->_get_token;
	    my $m;
	    for ($token[1]) {
		/^\.$/ and do {
		    $m = $self->member or $self->_error('Syntax error');
		    last;
		};
		/^\[$/ and do {
		    $m = $self->subscript or $self->_error('Syntax error');
		    last;
		};
		last MEMBER_LOOP;
	    }
	    push @tree, $m;
	}
	$self->_unget_token(@token);
	
      PROPERTYtoLITERAL:
	{
	    last if @tree != 2 or !($self->{stat}{Optimize} & O_CONSTMATH);
	    last unless (ref($tree[0])=~/:Variable/ and ref($tree[1])=~/:Member/);
	    my $prop = lc($tree[0]->{node}[0].'_'.$tree[1]->{node}[0]);
	    last unless exists $const_prop{$prop};
	    my $n = $self->new_node('NumberLiteral');
	    $n->add_node($const_prop{$prop});
	    $n->_chk_inf_nan;
	    return $n;
	}
	return $tree[0] if @tree <= 1;
	my $n = $self->new_node('MemberExpression');
	$n->add_node(@tree);
	return $n;
    }
}

sub subscript {
    my $self = shift;
    my $e = $self->expression or return;
    my $n = $self->new_node('Member');
    $n->add_node($e);
    return ($self->_check_token(']') and $n);
}

sub arguments {
    my $self = shift;
    my $n = $self->new_node('Arguments');

  ARGUMENTS:
    {
	my @token;
	$self->_check_token(')')
	    and return $n;
	do {
	    my $e = $self->assignment_expression or last ARGUMENTS;
	    $n->add_node($e);
	    @token = $self->_get_token;
	} while ($token[1] eq ',');
	last ARGUMENTS unless $token[1] eq ')';
	return $n;
    }
    $self->_error('Syntax error');
}

sub member {
    my $self = shift;

    if (my $i = $self->identifier) {
	my $n = $self->new_node('Member');
	$n->add_node($i);
	return $n;
    } else {
	return;
    }
}

sub function_expression {
    my ($self, $name) = @_;

    $self->_check_token_fatal('(', "'(' is needed after 'function'");

    $self->new_scope;

    my $params = $self->new_node('FunctionParameter');
    my @token;
    unless ($self->_check_token(')')) {
	do {
	    my $i = $self->identifier or $self->_error('Identifier is needed in the argument list');
	    $params->add_node($i);
	    $self->add_var($i, 0, 1);
	    @token = $self->_get_token;
	} while ($token[1] eq ',');
	$self->_error("Missing ')'") unless $token[1] eq ')';
    }
    $self->_check_token_fatal('{', "Missing '{' for function '$name'");

    my $statements = $self->new_node('SourceElements');
    until($self->_check_token('}')) {
	my $c = ($self->function_declaration || $self->statement)
	    or $self->_error("Syntax error. Missing '}' for function.");
	if ($self->{scope}[-1]) {
	    for my $var (@{$self->{scope}[-1]{preload}}) {
		my $n = $self->new_node('PreloadVar');
		$n->add_node($var);
		$statements->add_node($n);
	    }
	    $self->{scope}[-1]{preload} = [];
	}
	if (ref($c)=~/:Function$/) {
	    $statements->unshift_node($c);
	} else {
	    $statements->add_node($c);
	}
	$self->countup_node;
    }
    my $node = $self->new_node('Function');
    $node->add_node($name, $params, $statements);
    $self->exit_scope($node);

    return $node;
}

sub object_literal {
    my $self = shift;
    my $n = $self->new_node('ObjectLiteral');

  OBJECT:
    {
	my @tree;
	my @token;
	$self->_check_token('}')
	    and $self->_get_token, return $n;
	do {
	    my $i = $self->identifier;
	    last OBJECT unless $i;
	    last OBJECT unless ($self->_get_token)[1] eq ':';
	    my $e = $self->assignment_expression;
	    last OBJECT unless $e;
	    $n->add_node($i, $e);
	    @token = $self->_get_token;
	} while ($token[1] eq ',');
	last OBJECT unless $token[1] eq '}';
	return $n;
    }
    $self->_error('Syntax error');
}

sub array_literal {
    my $self = shift;
    my $n = $self->new_node('ArrayLiteral');

  ARRAY:
    {
	my @tree;
	my @token;
	$self->_check_token(']')
	    and $self->_get_token, return $n;
	do {
	    my $e = $self->assignment_expression or last ARRAY;
	    $n->add_node($e);
	    @token = $self->_get_token;
	} while ($token[1] eq ',');
	last ARRAY unless $token[1] eq ']';
	return $n;
    }
    $self->_error('Syntax error');
}

sub expression {
    my $self = shift;
    my @tree;
    my @comma;

    my $e = $self->assignment_expression;
    while((@comma = $self->_get_token)[1] eq ',' ) {
	push @tree, $self->assignment_expression;
    }
    $self->_unget_token(@comma);
    if (@tree <= 0) {
	return $e;
    } else {
	my $n = $self->new_node('Expression');
	$n->add_node($e, @tree);
	return $n;
    }
}

sub expression_statement {
    my $self = shift;
    my $e = $self->expression or $self->_error('Syntax error');
    $self->_statement_terminator;
    my $n = $self->new_node('ExpressionStatement');
    $n->add_node($e);
    return $n;
}

sub _statement_terminator {
    my $self = shift;
    my @token = $self->_get_token;
    unless ($token[1] eq 'StatementTerminator') {
	if ($token[1] eq '}' or $token[2]>=1 or $token[1] eq '') {
	    $self->_unget_token(@token);
	    return 1;
	}
	$self->_unget_token(@token);
	$self->_error("Syntax error. ';' is expected.");
    }
    return 1;
}

### code generator

sub _code_print {
    my $self = shift;
    my $code = $self->{stat}{code};
    for (@$code) {
	print "$_\n";
    }
}

{
    my %encode = (
		  GotoFrame      => [qw/ Frame /],
		  GetURL         => [qw/ $UrlString $TargetString /],
		  WaitForFrame   => [qw/ Frame : SkipCount /],
		  SetTarget      => [qw/ $TargetName /],
		  GotoLabel      => [qw/ $Label /],
		  WaitForFrame2  => [qw/ : SkipCount /],
		  Jump           => [qw/ : BranchOffset /],
		  GetURL2        => [qw/ Method /],
		  If             => [qw/ : BranchOffset /],
		  GotoFrame2     => [qw/ PlayFlag /],
		  StoreRegister  => [qw/ Register /],
		  With           => [qw/ : CodeSize /],
		  );

    sub _encode {
	my ($self, $actions) = @_;
	my $code = $self->{stat}{code};
	my $lhash = $self->{stat}{labelhash};
	my @constant = map {_unescape($_)} grep {$self->{stat}{strings}{$_} >=2} keys %{$self->{stat}{strings}};
	my %constant;
	@constant{@constant} = (0..$#constant);

	if (@constant > 0) {
	    push @$actions, SWF::Element::ACTIONRECORD->new
		( Tag=>'ActionConstantPool',
		  ConstantPool => \@constant
		);
	}

	my $labelf = 0;
	my $p = 0;

	for my $c (@$code) {
	    my ($action, $param) = ($c=~/^([^ ]+) *(.+)?$/);
	    my $tag;

	    if ($action =~ /^:/) {
		$labelf = 1;
		next;
	    } elsif ($action eq 'Push') {
		$tag = SWF::Element::ACTIONRECORD->new( Tag => 'ActionPush');
		my $dl = $tag->DataList;
                while(($param =~ / *([^ ]+) +\'((:?\\.|[^\'])*)\' */g)) {
		    my ($type, $value) = ($1, $2);
		    if ($type eq 'String') {
			$value = _unescape($value);
			if (exists $constant{$value}) {
			    push @$dl, SWF::Element::ACTIONDATA::Lookup->new($constant{$value});
			} else {
			    push @$dl, SWF::Element::ACTIONDATA::String->new($value);
			}
		    } elsif ($type eq 'Number') {
			if ( $value=~/^-?\d+$/ and -2147483648<=$value and $value<2147483648 ) {
			    push @$dl, SWF::Element::ACTIONDATA::Integer->new($value);
			} else {
			    push @$dl, SWF::Element::ACTIONDATA::Double->new($value);
			}
		    } else {
			push @$dl, "SWF::Element::ACTIONDATA::$type"->new($value);
		    }
		}
	    } elsif ($action eq 'DefineFunction') {
		$tag = SWF::Element::ACTIONRECORD->new( Tag => 'ActionDefineFunction');
                $param =~ s/ *\'((?:\\.|[^\'])*)\' *//;
		my $fname = $1;
		utf2bin($fname);
		my @args = split ' ', $param;
		utf2bin($_) for @args;
		$tag->CodeSize( $self->{stat}{labelhash}{$self->{stat}{labelhash}{pop @args}} );
		$tag->FunctionName($fname);
		$tag->Params(\@args);
	    } elsif ($action eq 'DefineFunction2') {
		$tag = SWF::Element::ACTIONRECORD->new( Tag => 'ActionDefineFunction2');
                $param =~ s/ *\'((?:\\.|[^\'])*)\' *//;
		my $fname = $1;
		utf2bin($fname);
		my ($regcount, $flag, @args) = split ' ', $param;
		utf2bin($_) for @args;
		$tag->CodeSize( $self->{stat}{labelhash}{$self->{stat}{labelhash}{pop @args}} );
		$tag->FunctionName($fname);
		$tag->RegisterCount($regcount);
		$tag->Flags($flag);
		my $regp = $tag->Parameters;
		for my $arg (@args) {
		    my $n = $regp->new_element;
		    my @r = split /=/, $arg;
		    $n->ParamName($r[0]);
		    $n->Register($r[1]);
		    push @$regp, $n;
		}
	    } elsif (exists $encode{$action}) {
              my @args = ($param =~ /\'((?:\\.|[^\'])*)\'/g);
		$tag = SWF::Element::ACTIONRECORD->new( Tag => $action);
		for my $e (@{$encode{$action}}) {
		    if ($e eq ':') {
			$args[0] = $self->{stat}{labelhash}{$self->{stat}{labelhash}{$args[0]}};
		    } elsif ($e=~/^\$/) {
			$e=~s/^\$//;
			my $str = shift @args;
			utf2bin($str);
			$tag->$e($str);
		    } else {
			$tag->$e(shift @args);
		    }
		}
	    } else {
		$tag = SWF::Element::ACTIONRECORD->new( Tag => $action);
	    }

	    if ($labelf) {
		$tag->LocalLabel($self->{stat}{labelhash}{$p});
		$labelf = 0;
	    }
	    push @$actions, $tag;
	} continue {
	    $p++;
	}
	my $tag = SWF::Element::ACTIONRECORD->new ( Tag => 'ActionEnd' );
	if ($labelf) {
	    $tag->LocalLabel($self->{stat}{labelhash}{$p});
	}
	push @$actions, $tag;
	return $actions;
    }
}

{
    my %escchar = (
	       'b' => "\x08",
	       'f' => "\x0c",
	       'n' => "\x0a",
	       'r' => "\x0d",
	       't' => "\x09",
	       'u' => 'u',
	       'x' => 'x',
	       '"' => '"',
	       "'" => "'",
	       );

    sub _unescape {
	my $str = shift;

	$str =~s[\\(u([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])|x([0-9a-fA-F][0-9a-fA-F])|([0-3][0-7][0-7])|.)][
	    if ($2||$3) {
		eval(qq("\\x{).($2||$3).qq(}"));
	    } elsif ($4) {
		eval(qq("\\$4"));
	    } else {
		$escchar{$1} || '\\';
	    }
	]eg;
	utf2bin($str);
	$str;
    }
}

sub _tidy_up {
    my $self = shift;
    my $code = $self->{stat}{code};

TIDYUP:
    for (my $p = 0; $p < @$code; $p++) {
	for ($code->[$p]) {
	    if ($self->{stat}{Optimize} & O_PEEPHOLE) {
# delete double not
		(/^Not$/ and $code->[$p+1] eq 'Not') and do {
		    splice(@$code, $p, 2);
		    $p-- if $p>0;
		    redo TIDYUP;
		};
# delete push and following pop
		(/^Push / and $code->[$p+1] eq 'Pop') and do { 
		    s/ *[^ ]+ +\'(\\.|[^\'])*\' *$//;
		    if (/^Push$/) {
			splice(@$code, $p, 2);
			$p-- if $p>0;
		    } else {
			splice(@$code, $p+1, 1);
		    }
		    redo TIDYUP;
		};
# delete jump to the next step
		(/^Jump\s+'(.+)'/ and $code->[$p+1] eq ":$1") and do {
		    splice(@$code, $p, 1);
		    $p-- if $p>0;
		    redo TIDYUP;
		};
# delete the actions after jump
		(/^Jump / and $code->[$p+1]!~/^:/) and do {
		    splice(@$code, $p+1, 1) while($code->[$p+1]!~/^:/);
		    redo TIDYUP;
		};
	    }

	    (/^Push / and $code->[$p+1]=~/^Push /) and do {
		(my $push = $code->[$p+1]) =~s/Push//;
		$code->[$p].=$push;
		splice(@$code, $p+1, 1);
		redo TIDYUP;
	    };
	    /^:(.+)$/ and do {
		my $q = $p;
		my $l = $1;
		$q++ until($code->[$q]!~/^:/ or $q >= @$code);
		$self->{stat}{labelhash}{$l} = $q;
		$self->{stat}{labelhash}{$q} = "L_$l";
		last;
	    };
	    (/^Push / and / String /) and do {
		my @strings = / String +'((?:\\.|[^'])*)\'/g;
		$self->{stat}{strings}{$_}++ for (@strings);
		last;
	    };
	    if ($self->{stat}{Version}<=5) {
		/^StrictEquals$/ and do{
		    $self->_warn(0, "ActionStrictEquals is only available for version 6 or higher. ActionEquals2 is used instead.");
		    $code->[$p] = 'Equals2';
		    last;
		};
		/^Greater$/ and splice(@$code, $p, 1, 'StackSwap', 'Less2'), last;
		/^StringGreater$/ and splice(@$code, $p, 1, 'StackSwap', 'StringLess'), last;
		/^InstanceOf$/ and $self->_error("'instanceof' op is only available for version 6 or higher.");
	    }
	}
    }
}

{
    package SWF::Builder::ActionScript::Compiler::Error;

    sub _error {
	my $self = shift;
	my $msgform = shift;
#	my ($t) = ($self->{text}=~/([^\n]+)/);
	die sprintf($msgform, @_)." in ".$self->{line}."\n";
    }

    sub _warn {
	my $self = shift;
	my $level = shift;
	my $msgform = shift;
	
	warn sprintf($msgform, @_)." in ".$self->{line}."\n" if $level >= $self->{stat}{Warning};
    }

    sub _warn_not_recommend {
	my ($self, $not, $instead) = @_;

	$self->_warn(0, "$not is not recommended to use. Use $instead instead.");
    }

    sub _error_param {
	my ($self, $command) = @_;
	
	$self->_error("Wrong parameter for '%s'.", $command);
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode;
    our @ISA = ('SWF::Builder::ActionScript::Compiler::Error');

    sub add_node {
	my $self = shift;
	push @{$self->{node}}, @_;
    }

    sub unshift_node {
	my $self = shift;
	unshift @{$self->{node}}, @_;
    }


    sub _tree_dump {
	my ($self, $indent, $line)=@_;
	my ($nodename) = (ref($self)=~/([^:]+)$/);

	$indent ||= 0;
	print ((($self->{line} != $line) ? sprintf('%3d: ', $self->{line}) : '     '), ' ' x ($indent*4), "$nodename [\n");
	for my $node (@{$self->{node}}) {
	    if (ref($node)) {
		eval{$node->_tree_dump($indent+1, $self->{line})};
		if ($@) {
		    print STDERR "\n",ref($self),"\n",ref($node),"\n";
		    die;
		}
	    } else {
		print '      ', ' ' x (($indent+1)*4), "'$node'\n";
	    }
	}
	print '      ', ' ' x ($indent*4), "]\n";
    }

    sub _lhs {
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::NullStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');
    
    sub compile {}
}

{
    package SWF::Builder::ActionScript::SyntaxNode::List;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');
    
    sub compile {
	my $self = shift;
	
	for my $s (@{$self->{node}}) {
	    $s->compile;
	}
    }
}
@SWF::Builder::ActionScript::SyntaxNode::SourceElements::ISA=('SWF::Builder::ActionScript::SyntaxNode::List');
@SWF::Builder::ActionScript::SyntaxNode::StatementBlock::ISA=('SWF::Builder::ActionScript::SyntaxNode::List');
@SWF::Builder::ActionScript::SyntaxNode::VariableDeclarationList::ISA=('SWF::Builder::ActionScript::SyntaxNode::List');

{
    package SWF::Builder::ActionScript::SyntaxNode::VariableDeclaration;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;   # $context = lvalue if 'for var x in ...'
	my $code = $self->{stat}{code};
	my $regvars = $self->{regvars};
	my $var = $self->{node}[0];

	if ($regvars and exists $regvars->{$var}) {
	    push @$code, "StoreRegister '".$regvars->{$var}."'", 'Pop', -2 if defined($context) and $context eq 'lvalue';
	} else {
	    push @$code, "Push String '$var'", ($context eq 'lvalue' ? ("DefineLocal", -1) : ("DefineLocal2"));
	}
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::VariableDeclarationWithParam;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');
    
    sub compile {
	my $self = shift;
	my $code = $self->{stat}{code};
	my $regvars = $self->{regvars};
	my $var = $self->{node}[0];

	if ($regvars and exists $regvars->{$var}) {
	    $self->{node}[1]->compile('value');
	    push @$code, "StoreRegister '".$regvars->{$var}."'", 'Pop';
	} else {
	    push @$code, "Push String '$var'";
	    $self->{node}[1]->compile('value');
	    push @$code, "DefineLocal";
	}
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::BinaryOpExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    my %bin_ops =
	( '*'   => ['Multiply'],
	  '/'   => ['Divide'],
	  '%'   => ['Modulo'],
	  '+'   => ['Add2'],
	  '-'   => ['Subtract'],
	  '<<'  => ['BitLShift'],
	  '>>>' => ['BitURShift'],
	  '>>'  => ['BitRShift'],
	  '<='  => ['Greater', 'Not'],
	  '>='  => ['Less2', 'Not'],
	  '<'   => ['Less2'],
	  '>'   => ['Greater'],
	  'instanceof' => ['InstanceOf'],
	  '===' => ['StrictEquals'],
	  '!==' => ['StrictEquals', 'Not'],
	  '=='  => ['Equals2'],
	  '!='  => ['Equals2', 'Not'],
	  '&'   => ['BitAnd'],
	  '^'   => ['BitXor'],
	  '|'   => ['BitOr'],

	  'add' => ['StringAdd'],
	  'eq'  => ['StringEquals'],
	  'ne'  => ['StringEquals', 'Not'],
	  'ge'  => ['StringLess', 'Not'],
	  'gt'  => ['StringGreater'],
	  'le'  => ['StringGreater', 'Not'],
	  'lt'  => ['StringLess'],
	  
	  );
    my %obsolete = (add=>'+', eq=>'==', ne=>'!=', ge=>'>=', gt=>'>', le=>'<=', lt=>'<');

    sub compile {
	my ($self, $context) = @_;
	my $node = $self->{node};
	my $code = $self->{stat}{code};

	shift(@$node)->compile($context);

	while(@$node) {
	    my $term = shift(@$node);
	    my $op = shift(@$node);
	    $self->_warn_not_recommend("'$op' op", "'$obsolete{$op}'") if exists($obsolete{$op});
	    $term->compile($context);
	    if ($context) {
		push @$code, @{$bin_ops{$op}};
	    } else {
		$self->_warn(1, "Useless use of '$op' in void context.");
	    }
	}
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::Expression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $last = pop @{$self->{node}};

	for my $e (@{$self->{node}}) {
	    $e->compile;
	}
	$last->compile($context);
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::ExpressionStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;

	$self->{node}[0]->compile;
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::Literal;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;

	my ($type) = (ref($self) =~/([A-Za-z]+)Literal/);
	($context =~/lc?value/) and $self->_error("Can't modify literal item");
	push @{$self->{stat}{code}}, "Push $type '".$self->{node}[0]."'" if $context;
	$self;
    }

    sub toboolean {
	my $self = shift;
	$self->{node}[0] = $self->istrue;
	bless $self, 'SWF::Builder::ActionScript::SyntaxNode::BooleanLiteral';
    }

    sub _totrue {
	my $self = shift;
	$self->{node}[0] = 1;
	bless $self, 'SWF::Builder::ActionScript::SyntaxNode::BooleanLiteral';
    }

    sub _tofalse {
	my $self = shift;
	$self->{node}[0] = 0;
	bless $self, 'SWF::Builder::ActionScript::SyntaxNode::BooleanLiteral';
    }

    sub isvalue {1}

    sub _binop_numbers {
	my ($self, $term, $opsub) = @_;
	$self->tonumber;
	$term->tonumber;
	return $term if $term->isa('SWF::Builder::ActionScript::SyntaxNode::NaN');
	$self->{node}[0] = &$opsub($self->{node}[0], $term->{node}[0]);
	$self->_chk_inf_nan;
    }

    sub _binop_rel {
	my ($self) = @_;
	&_binop_numbers;
	$self->toboolean;
    }

    sub _binop_strings {
	my ($self, $term, $opsub) = @_;
	$self->tostring;
	$term->tostring;

	$self->{node}[0] = &$opsub($self->{node}[0], $term->{node}[0]);
	$self;
    }

    sub _binop_booleans {
	my ($self, $term, $opsub) = @_;
	$self->toboolean;
	$term->toboolean;

	$self->{node}[0] = &$opsub($self->{node}[0], $term->{node}[0]);
	$self;
    }

    sub _binop_Add2 {
	my ($self, $term) = @_;

	if ($term->isa('SWF::Builder::ActionScript::SyntaxNode::StringLiteral')) {
	    $self->tostring->_binop_Add2($term);
	} else {
	    $self->tonumber->_binop_Add2($term);
	}
    }

    sub _binop_LogicalAnd {
	my ($self, $term) = @_;

	if ($self->istrue) {
	    $term;
	} else {
	    $self->toboolean;
	}
    }

    sub _binop_LogicalOr {
	my ($self, $term) = @_;

	return ($self->istrue ? $self : $term);
    }

    sub _binop_Equals2Not {
	my ($self, $term) = @_;
	$self->_binop_Equals2($term);
	$self->{node}[0] = 1-$self->{node}[0];
	$self;
    }

    sub _binop_StrictEquals2Not {
	my ($self, $term) = @_;
	$self->_binop_StrictEquals2($term);
	$self->{node}[0] = 1-$self->{node}[0];
	$self;
    }

    sub _binop_StrictEquals {
	my ($self, $term) = @_;
	my ($t_self) = (ref($self)=~/([^:]+)$/);
	my ($t_term) = (ref($term)=~/([^:]+)$/);

	return $self->_tofalse if ($t_self ne $t_term) or ($t_self eq 'NaN') or ($t_term eq 'NaN');
	if ($t_self eq 'NumberLiteral') {
	    if ($self->{node}[0] == $term->{node}[0]) {
		return $self->_totrue;
	    } else {
		return $self->_tofalse;
	    }
	} else {
	    if ($self->{node}[0] eq $term->{node}[0]) {
		return $self->_totrue;
	    } else {
		return $self->_tofalse;
	    }
	}
    }

    sub __nf1 {
	my $fnn = shift;
	my $fns = shift;
	my $num = shift;
	$num->_error_param($fnn) if @_;
	
	$num->tonumber;
	return $num if $num->isa('SWF::Builder::ActionScript::SyntaxNode::NaN');
	$num->{node}[0] = &$fns($num->{node}[0]);
	$num->tostring->tonumber;
    }

    sub _f_int     {__nf1('int', sub{int shift}, @_)}

    sub _math_abs  {__nf1('Math.abs', sub{abs shift}, @_)}
    sub _math_acos {__nf1('Math.acos',
			  sub{
			      my $x = shift;
			      return 'NaN' if abs($x)>1;
			      return atan2(1-$x*$x, $x);
			  },
			  @_)}
    sub _math_asin {__nf1('Math.asin',
			  sub{
			      my $x = shift;
			      return 'NaN' if abs($x)>1;
			      return atan2($x, 1-$x*$x);
			  },
			  @_)}
    sub _math_atan {__nf1('Math.atan', sub{atan2(1, shift)}, @_)}
    sub _math_ceil {__nf1('Math.ceil',
			  sub{
 			      my $x = shift;
			      my $ix = int($x);
			      return $x if $x == $ix;
			      return $ix+($x>0);
			  },
			  @_)}
    sub _math_cos  {__nf1('Math.cos', sub{cos shift}, @_)}
    sub _math_exp  {__nf1('Math.exp', sub{exp shift}, @_)}
    sub _math_floor{__nf1('Math.floor',
			  sub{
 			      my $x = shift;
			      my $ix = int($x);
			      return $x if $x == $ix;
			      return $ix-($x<0);
			  },
			  @_)}
    sub _math_log  {__nf1('Math.log',
			  sub{
			      my $x = shift;
			      return 'NaN' if $x<0;
			      return '-Infinity' if $x == 0;
			      return log($x);
			  },
			  @_)}
    sub _math_round{__nf1('Math.round',
			  sub{
 			      my $x = shift;
			      my $ix = int($x+0.5*($x<=>0));
			      return ($ix==$x-0.5)?int($x):$ix;
			  },
			  @_)}
    sub _math_sin  {__nf1('Math.sin', sub{sin shift}, @_)}
    sub _math_sqrt {__nf1('Math.sqrt',
			  sub{
			      my $x = shift;
			      return 'NaN' if $x<0;
			      return sqrt($x);
			  },
			  @_)}
    sub _math_tan  {__nf1('Math.tan',
			  sub{
			      my $r = shift;
			      return ($r<0 ? '-Infinity':'Infinity') if cos($r)==0;
			      return sin($r)/cos($r);
			  },
			  @_)}

    sub __nf2 {
	my $fnn = shift;
	my $fns = shift;
	my $num1 = shift;
	my $num2 = shift;
	$num1->_error_param($fnn) if @_;
	
	$num1->tonumber;
	$num2->tonumber;
	return $num1 if $num1->isa('SWF::Builder::ActionScript::SyntaxNode::NaN') or $num2->isa('SWF::Builder::ActionScript::SyntaxNode::NaN');
	$num1->{node}[0] = &$fns($num1->{node}[0], $num2->{node}[0]);
	$num1->tostring->tonumber;
    }

    sub _math_atan2 {__nf2('Math.atan2', sub{atan2($_[0], $_[1])}, @_)}
    sub _math_max   {__nf2('Math.max', sub{my($a,$b)=@_;$a>$b?$a:$b}, @_)}
    sub _math_min   {__nf2('Math.min', sub{my($a,$b)=@_;$a>$b?$b:$a}, @_)}
    sub _math_pow   {__nf2('Math.pow',
			   sub {
			       my ($base, $exp) = @_;
			       if ($base < 0 and $exp != int($exp)) {
				   return 'NaN';
			       } else {
				   return $base ** $exp;
			       }
			   },
                           @_)}


}

{
    package SWF::Builder::ActionScript::SyntaxNode::BooleanLiteral;
    our @ISA=('SWF::Builder::ActionScript::SyntaxNode::Literal');

    sub tonumber {
	bless shift, 'SWF::Builder::ActionScript::SyntaxNode::NumberLiteral';
    }

    sub tostring {
	my $self = shift;
	$self->{node}[0] = $self->{node}[0] ? 'true' : 'false';
	bless $self, 'SWF::Builder::ActionScript::SyntaxNode::StringLiteral';
    }

    sub toboolean {shift}
    sub istrue {
	my $self = shift;
	return ($self->{node}[0] != 0)? 1 : 0;
    }

    sub _binop_Equals2 {
	my ($self, $term) = @_;

	unless ($term->isvalue) {
	    $self->{node}[0] = 0;
	    $self;
	} elsif ($term->isa('SWF::Builder::ActionScript::SyntaxNode::BooleanLiteral')) {
	    $self->{node}[0] = ($self->{node}[0] == $term->{node}[0]) ? 1:0;
	    $self;
	} else {
	    $self->tonumber->_binop_Equals2($term);
	}
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::NaN;
    our @ISA=('SWF::Builder::ActionScript::SyntaxNode::NumberLiteral');

    sub compile {
	my ($self, $context) = @_;

	($context =~/lc?value/) and $self->_error("Can't modify literal item");
	push @{$self->{stat}{code}}, "Push Number 'NaN'" if $context;
	$self;
    }

    sub istrue {0}
    sub isvalue {0}
    sub _binop_Equals2 {shift->_tofalse}
    sub _binop_numbers {shift}
    sub _binop_rel {shift->_tofalse}

    sub _binop_Add2 {
	my ($self, $term) = @_;

	if ($term->isa('SWF::Builder::ActionScript::SyntaxNode::StringLiteral')) {
	    $self->tostring->_binop_Add2($term);
	} else {
	    $self;
	}
    }

}

{
    package SWF::Builder::ActionScript::SyntaxNode::Infinity;
    our @ISA=('SWF::Builder::ActionScript::SyntaxNode::NumberLiteral');

    sub compile {
	my ($self, $context) = @_;

	($context =~/lc?value/) and $self->_error("Can't modify literal item");
	my $value = $self->{node}[0];
	my $packed = pack('d', $value);

	if ($packed eq $NINF) {
	    $value = '-Infinity';
	} elsif ($packed eq $INF) {
	    $value = 'Infinity';
	}
	push @{$self->{stat}{code}}, "Push Number '$value'" if $context;
	$self;
    }

    sub istrue {1}

    sub _binop_Add2 {
	my ($self, $term) = @_;

	if ($term->isa('SWF::Builder::ActionScript::SyntaxNode::StringLiteral')) {
	    return $self->tostring->_binop_Add2($term);
	} elsif ($term->isa('SWF::Builder::ActionScript::SyntaxNode::Infinity') &&
		 $self->{node}[0] ne $term->{node}[0]) {
	    $self->{node}[0] = 'NaN';
	    bless $self, 'SWF::Builder::ActionScript::SyntaxNode::NaN';
	} else {
	    $self;
	}
    }

    sub _binop_Equals2 {
	my ($self, $term) = @_;
	$term->tonumber;
	if ($self->{node}[0] eq $term->{node}[0]) {
	    $self->_totrue;
	} else {
	    $self->_tofalse;
	}
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::NumberLiteral;
    our @ISA=('SWF::Builder::ActionScript::SyntaxNode::Literal');
    
    sub tonumber{shift}

    sub tostring {
	bless shift, 'SWF::Builder::ActionScript::SyntaxNode::StringLiteral';
    }

    sub istrue {
	my $self = shift;
	return ($self->{node}[0] != 0)? 1 : 0;
    }

    sub _chk_inf_nan {
	my $self = shift;
	my $value = $self->{node}[0];

	return bless $self, 'SWF::Builder::ActionScript::SyntaxNode::NaN' if $value eq 'NaN';

	my $packed = pack('d', $value);
	return $self if (($packed & $INF) ne $INF);

	if (($packed & $MANTISSA) ne "\x00" x 8) {
	    $self->{node}[0] = 'NaN';
	    bless $self, 'SWF::Builder::ActionScript::SyntaxNode::NaN';
	} else {
	    bless $self, 'SWF::Builder::ActionScript::SyntaxNode::Infinity';
	}
	$self;
    }

    sub _binop_Add2 {
	my ($self, $term) = @_;

	if ($term->isa('SWF::Builder::ActionScript::SyntaxNode::StringLiteral')) {
	    $self->tostring->_binop_Add2($term);
	} else {
	    $term->tonumber;
	    return $term 
		if ($term->isa('SWF::Builder::ActionScript::SyntaxNode::NaN') ||
		    $term->isa('SWF::Builder::ActionScript::SyntaxNode::Infinity'));

	    $self->{node}[0] += $term->{node}[0];
	    $self->_chk_inf_nan;
	}
    }

    sub _binop_Equals2 {
	my ($self, $term) = @_;

	unless ($term->isvalue) {
	    return $self->_tofalse;
	} elsif ($term->isa('SWF::Builder::ActionScript::SyntaxNode::Infinity')) {
	    return $self->_tofalse;
	} else {
	    $term->tonumber;
	    if ($self->{node}[0] == $term->{node}[0]) {
		return $self->_totrue;
	    } else {
		return $self->_tofalse;
	    }
	}
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::StringLiteral;
    our @ISA=('SWF::Builder::ActionScript::SyntaxNode::Literal');

    sub compile {
	my ($self, $context) = @_;

	($context =~/lc?value/) and $self->_error("Can't modify literal item");
	my $value = $self->{node}[0];
	$value =~ s/([\x00-\x1f\x7f-\xff])/sprintf('\\x%2.2x', ord($1))/eg;
	push @{$self->{stat}{code}}, "Push String '".$value."'" if $context;
	$self;
    }

    sub tostring{shift}

    sub _getnumber {
	my $self = shift;
	my $value = $self->{node}[0];
	if ($value=~/^0[0-7]+$/ or $value=~/^0x[0-9a-f]$/i) {
	    $value = oct($value);
	} elsif ($value !~ /^(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ and $value !~ /^[-+]?Infinity$/) {
	    $value = '';
	}
	return $value;
    }

    sub tonumber {
	my $self = shift;
	my $value = $self->_getnumber;
	$self->{node}[0] = $value;

	if ($value =~ /^([-+]?)Infinity$/) {
	    $self->{node}[0] = ($1 eq '-' ? -$INFINITY: $INFINITY);
	    bless $self, 'SWF::Builder::ActionScript::SyntaxNode::Infinity';
	} elsif ($value eq '') {
	    $self->{node}[0] = 'NaN';
	    bless $self, 'SWF::Builder::ActionScript::SyntaxNode::NaN';
	} else {
	    bless $self, 'SWF::Builder::ActionScript::SyntaxNode::NumberLiteral';
	}
    }

    sub istrue {
	my $self = shift;
	return ($self->_getnumber ? 1 : 0);
    }

    sub _binop_rel {
	my ($self, $term, $opsub, $opsub2) = @_;

	unless ($term->isa('SWF::Builder::ActionScript::SyntaxNode::StringLiteral')) {
	    $self->tonumber->_binop_rel($term, $opsub);
	} else {
	    $self->{node}[0] = &$opsub2($self->{node}[0], $term->{node}[0]);
	    $self->toboolean;
	}
    }

    sub _binop_Equals2 {
	my ($self, $term) = @_;

	unless ($term->isvalue) {
	    return $self->_tofalse;
	} elsif ($term->isa('SWF::Builder::ActionScript::SyntaxNode::StringLiteral')) {
	    if ($self->{node}[0] eq $term->{node}[0]) {
		return $self->_totrue;
	    } else {
		return $self->_tofalse;
	    }
	} else {
	    $self->tonumber->_binop_Equals2($term);
	}
    }

    sub _binop_Add2 {
	my ($self, $term) = @_;
	$self->{node}[0] .= $term->{node}[0];
	$self;
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::NULLLiteral;
    our @ISA=('SWF::Builder::ActionScript::SyntaxNode::Literal');

    sub tostring {
	my $self = shift;
	$self->{node}[0] = 'null';
	bless $self, 'SWF::Builder::ActionScript::SyntaxNode::StringLiteral';
    }

    sub tonumber {
	my $self = shift;
	$self->{node}[0] = 0;
	bless $self, 'SWF::Builder::ActionScript::SyntaxNode::NumberLiteral';
    }

    sub istrue {0}
    sub isvalue {0}
    sub _binop_Equals2 {
	my ($self, $term) = @_;
	if ($term->isa('SWF::Builder::ActionScript::SyntaxNode::UNDEFLiteral') or
	    $term->isa('SWF::Builder::ActionScript::SyntaxNode::NULLLiteral')) {
	    $self->_totrue;
	} else {
	    $self->_tofalse;
	}
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::UNDEFLiteral;
    our @ISA=('SWF::Builder::ActionScript::SyntaxNode::Literal');

    sub tostring {
	bless shift, 'SWF::Builder::ActionScript::SyntaxNode::StringLiteral';
    }

    sub tonumber {
	my $self = shift;
	$self->{node}[0] = 0;
	bless $self, 'SWF::Builder::ActionScript::SyntaxNode::NumberLiteral';
    }

    sub istrue {0}
    sub isvalue {0}
    sub _binop_Equals2 {
	my ($self, $term) = @_;
	if ($term->isa('SWF::Builder::ActionScript::SyntaxNode::UNDEFLiteral') or
	    $term->isa('SWF::Builder::ActionScript::SyntaxNode::NULLLiteral')) {
	    $self->_totrue;
	} else {
	    $self->_tofalse;
	}
    }

}


{
    package SWF::Builder::ActionScript::SyntaxNode::ObjectLiteral;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $node = $self->{node};

	($context =~/lc?value/) and SWF::Builder::ActionScript::SyntaxNode::_error("Can't modify literal item");
	my $code = $self->{stat}{code};
	my $count = @$node / 2;
	while (@$node) {
	    my $prop = shift @$node;
	    my $value = shift @$node;
	    push @$code, "Push String '$prop'";
	    $value->compile('value');
	}
	push @$code, "Push Number '$count'", "InitObject";
	push @$code, "Pop" unless $context;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::ArrayLiteral;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	($context =~/lc?value/) and SWF::Builder::ActionScript::SyntaxNode::_error("Can't modify literal item");
	my $code = $self->{stat}{code};
	my $count = @{$self->{node}};
	for my $value (reverse @{$self->{node}}) {
	    $value->compile('value');
	}
	push @$code, "Push Number '$count'", "InitArray";
	push @$code, "Pop" unless $context;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::PreloadVar;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $var = $self->{node}[0];
	my $regvars = $self->{regvars};
	if ($regvars and exists $regvars->{$var}) {
	    push @{$self->{stat}{code}}, "Push String '$var'"
		                 , "GetVariable"
		                 , "StoreRegister '".$regvars->{$var}."'"
		                 , "Pop";
	}
	$self;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::Variable;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $code = $self->{stat}{code};
	my $regvars = $self->{regvars};
	my $var = $self->{node}[0];

	if ($regvars and exists $regvars->{$var}) {
	    push @$code, "Push Register '".$regvars->{$var}."'" if $context ne 'lvalue';
	    push @$code, "StoreRegister '".$regvars->{$var}."'", 'Pop', -2 if $context eq 'lvalue' or $context eq 'lcvalue';
	} else {
	    push @$code, "Push String '$var'";
	    push @$code, 'GetVariable' if $context eq 'value' or not $context;
	    push @$code, 'SetVariable', -1 if $context eq 'lvalue';
	    push @$code, 'PushDuplicate', 'GetVariable', 'SetVariable', -1 if $context eq 'lcvalue';
	}
	push @$code, "Pop" unless $context;
	$self;
    }

    sub _lhs {1}
}
{
    package SWF::Builder::ActionScript::SyntaxNode::Property;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $code = $self->{stat}{code};
	push @$code, "Push String '' ";
	push @$code, "Push Property '".lc($self->{node}[0])."'";
	push @$code, 'GetProperty' if $context eq 'value' or not $context;
	push @$code, 'SetProperty', -1 if $context eq 'lvalue';
	push @$code, "Push String '' ", "Push Property '".lc($self->{node}[0])."'", 'GetProperty', 'SetProperty', -1 if $context eq 'lcvalue';
	push @$code, "Pop" unless $context;
	$self;
    }

    sub _lhs {1}
}

{
    package SWF::Builder::ActionScript::SyntaxNode::MemberExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my @node = @{$self->{node}};
	my $code = $self->{stat}{code};

	shift(@node)->compile('value');
	return unless @node;
	my $last = pop @node;
	for my $member (@node){
	    $member->compile('value');
	}
	$last->compile($context);
    }

    sub _lhs {1}
}

{
    package SWF::Builder::ActionScript::SyntaxNode::Member;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $code = $self->{stat}{code};
	my $member = $self->{node}[0];

	push @$code, 'PushDuplicate' if $context eq 'lcvalue';
	if (ref($member)) {
	    $member->compile('value');
	} else {
	    push @$code, "Push String '".$member."'";
	}
	if ($context eq 'lvalue') {
	    push @$code, 'SetMember', -1;
	} elsif ($context eq 'value') {
	    push @$code, 'GetMember';
	} elsif ($context eq 'lcvalue') {
	    push @$code, "StoreRegister '0'",'GetMember', "Push Register '0'", 'StackSwap', 'SetMember', -1;
	} elsif (not defined $context) {
	    push @$code, 'GetMember', 'Pop';
	}
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::AssignmentExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');
    use constant \%O;

    my %as_ops =
	( '*='   => 'Multiply',
	  '/='   => 'Divide',
	  '%='   => 'Modulo',
	  '+='   => 'Add2',
	  '-='   => 'Subtract',
	  '<<='  => 'BitLShift',
	  '>>>=' => 'BitURShift',
	  '>>='  => 'BitRShift',
	  '&='   => 'BitAnd',
	  '^='   => 'BitXor',
	  '|='   => 'BitOr',
	  );

    sub compile {
	my ($self, $context) = @_;
	my ($lhe, $op, $e) = @{$self->{node}};
	my $code = $self->{stat}{code};
	my $opt = $self->{stat}{Optimize} & O_LEFTONCE;
	my $as_context = ($op eq '=' or !$opt)? 'lvalue' : 'lcvalue'; 

	$lhe->compile($as_context);
	my $lv = pop @$code;
	my @lv = splice(@$code, $lv);
	$lhe->compile('value') if (!$opt and $op ne '=');
	$e->compile('value');
	push @$code, $as_ops{$op} if exists $as_ops{$op};
	push @$code, "StoreRegister '0'" if $context;
	push @$code, @lv;
	push @$code, "Push Register '0'" if $context;
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::AndOpExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $node = $self->{node};
	my $label = $self->{stat}{label}++;
	my $code = $self->{stat}{code};

	shift(@$node)->compile('value');

	my ($term, $op);
	while(@$node) {
	    $term = shift @$node;
	    $op = shift @$node;
	    if ($op eq '&&') {
		push @$code, 'PushDuplicate', 'Not', "If '$label'", 'Pop';
		$term->compile('value');
	    } else {  # $op eq 'and'
		$self->_warn_not_recommend("'and' op", "'&&'");
		$term->compile('value');
		push @$code, 'And';
	    }
	}
	push @$code, ":$label";
	push @$code, "Pop" unless $context;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::OrOpExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $node = $self->{node};
	my $label = $self->{stat}{label}++;
	my $code = $self->{stat}{code};

	shift(@$node)->compile('value');

	my ($term, $op);
	while(@$node) {
	    $term = shift @$node;
	    $op = shift @$node;
	    if ($op eq '||') {
		push @$code, 'PushDuplicate', "If '$label'", 'Pop';
		$term->compile('value');
	    } else {  # $op eq 'or'
		$self->_warn_not_recommend("'or' op", "'||'");
		$term->compile('value');
		push @$code, 'Or';
	    }
	}
	push @$code, ":$label";
	push @$code, "Pop" unless $context;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::ConditionalExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $node = $self->{node};
	my $label1 = $self->{stat}{label}++;
	my $label2 = $self->{stat}{label}++;
	my $code = $self->{stat}{code};

	$node->[0]->compile('value');
	push @$code, "If '$label1'";
	$node->[2]->compile($context);
	push @$code, "Jump '$label2'", ":$label1";
	$node->[1]->compile($context);
	push @$code, ":$label2";
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::ReturnStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');
    use constant \%O;

    sub compile {
	my $self = shift;
	my $ret = shift(@{$self->{node}});
	my $opt = $self->{stat}{Optimize};
	my $code = $self->{stat}{code};


	if (defined($ret)) {
	    $ret->compile('value');
	} else {
	    push @$code, "Push UNDEF ''";
	}

	if (($opt & O_REGISTER) and !($opt & O_LOCALREG) and (my $regcount = $self->{regvars}{' regcount'}) > 0) {
	    push @$code, "StoreRegister '0'", "Pop";
	    for (my $i = $regcount; $i >= 1; $i--) {
		push @$code, "StoreRegister '$i'", "Pop";
	    }
	    push @$code, "Push Register '0'";
	}

	push @$code, "Return";
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::IfStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $stat = $self->{stat};
	my $label1 = $stat->{label}++;
	my $code = $stat->{code};
	my $node = $self->{node};

	$node->[0]->compile('value');
	if ($node->[2]) {  # else block
	    my $label2 = $stat->{label}++;
	    push @$code, "If '$label2'";
	    $node->[2]->compile;
	    push @$code, "Jump '$label1'", ":$label2";
	} else {
	    push @$code, "Not", "If '$label1'";
	}
	$node->[1]->compile;
	push @$code, ":$label1";
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::ContinueStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $code = $self->{stat}{code};
	my $loop = $self->{stat}{loop};
	my $actions;
	$actions = $loop->[-1][0] if (defined $loop->[-1]);
	$self->_error("Can't \"continue\" outside a loop block ") unless defined $actions;
	push @$code, @$actions;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::BreakStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $code = $self->{stat}{code};
	my $loop = $self->{stat}{loop};
	my $actions;
	if (defined $loop->[-1]) {
	    $actions = $loop->[-1][1];
	    $loop->[-1][-1]++;
	}
	$self->_error("Can't \"break\" outside a loop block ") unless defined $actions;
	push @$code, @$actions;
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::WhileStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $stat = $self->{stat};
	my ($cond, $block) = @{$self->{node}};
	my $enter_label = $stat->{label}++;
	my $break_label = $stat->{label}++;
	my $code = $stat->{code};
	my $loop = $stat->{loop};

	push @$loop, [["Jump '$enter_label'"], ["Jump '$break_label'"], 0 ];
	push @$code, ":$enter_label";
	if ($cond) {
	    $cond->compile('value');
	    push @$code, 'Not', "If '$break_label'";
	}
	$block->compile;
	push @$code, "Jump '$enter_label'", ":$break_label";
	pop @$loop;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::DoWhileStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $stat = $self->{stat};
	my ($block, $cond) = @{$self->{node}};
	my $enter_label = $stat->{label}++;
	my $cont_label = $stat->{label}++;
	my $break_label = $stat->{label}++;
	my $code = $stat->{code};
	my $loop = $stat->{loop};

	push @$loop, [["Jump '$cont_label'"], ["Jump '$break_label'"], 0 ];
	push @$code, ":$enter_label";
	$block->compile;
	push @$code, ":$cont_label";
	if ($cond) {
	    $cond->compile('value');
	    push @$code, "If '$enter_label'";
	} else {
	    push @$code, "Jump '$enter_label'";
	}
	push @$code, ":$break_label";
	pop @$loop;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::ForEachStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $stat = $self->{stat};
	my ($var, $obj, $statements) = @{$self->{node}};
	my $loop_out = $stat->{label}++;
	my $break_label = $stat->{label}++;
	my $cont_label = $stat->{label}++;
	my $code = $stat->{code};
	my $loop = $stat->{loop};

	push @$loop, [["Jump '$cont_label'"], ["Jump '$break_label'"], 0];

	$obj->compile('value');
	push @$code, "Enumerate2", ":$cont_label", "StoreRegister '0'", "Push NULL ''", "Equals2", "If '$loop_out'";
	$var->compile('lvalue');
	my $lv = pop @$code;
	my @lv = splice(@$code, $lv);
	push @$code, "Push Register '0'", @lv;
	$statements->compile;
	push @$code, "Jump '$cont_label'";
	if ($loop->[-1][-1]>0) {
	    push @$code, ":$break_label", "Push NULL ''", "Equals2", "Not", "If '$break_label'", ;
	}
	push @$code, ":$loop_out";
	pop @$loop;
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::SwitchStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $stat = $self->{stat};
	my ($cond, @cases) = @{$self->{node}};
	my $default = pop @cases;
	my $break_label = $stat->{label}++;
	my $code = $stat->{code};
	my $loop = $stat->{loop};

	push @$loop, [(defined ($loop->[-1]) ? [ "Pop", @{$loop->[-1][0]}] : undef), ["Jump '$break_label'"], 0 ];
	$cond->compile('value');
	for my $case (@cases) {
	    my $label = $stat->{label}++;
	    push @$code, "PushDuplicate";
	    $case->{node}[0]->compile('value');
	    push @$code, "StrictEquals", "If '$label'";
	    $case->{label} = $label;
	}
	my $default_label = $stat->{label}++;
	push @$code, "Jump '$default_label'";
	for my $case (@cases) {
	    push @$code, ":".$case->{label};
	    $case->{node}[1]->compile;
	}
	push @$code, ":$default_label";
	$default->compile if $default;
	push @$code, ":$break_label", "Pop";
	pop @$loop;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::CaseClause;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $stat = $self->{stat};
	my ($cond, $statements) = @{$self->{node}};
	my $label = $stat->{label};
	my $code = $stat->{code};

	push @$code, "dup";
	$cond->compile('value');
	push @$code, "StrictEquals", "Not", "If '$label'";
	if (@$statements) {
	    $statements->compile;
	    push @$code, ":$label";
	    $stat->{label}++;
	}
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::ForStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $stat = $self->{stat};
	my ($init, $cond, $rep, $block) = @{$self->{node}};
	my $enter_label = $stat->{label}++;
	my $cont_label = $stat->{label}++;
	my $break_label = $stat->{label}++;
	my $code = $stat->{code};
	my $loop = $stat->{loop};

	push @$loop, [["Jump '$cont_label'"], ["Jump '$break_label'"]];
	$init->compile if $init;
	push @$code, ":$enter_label";
	if ($cond) {
	    $cond->compile('value');
	    push @$code, 'Not';
	    push @$code, "If '$break_label'";
	}
	$block->compile;
	push @$code, ":$cont_label";
	$rep->compile if $rep;
	push @$code, "Jump '$enter_label'", ":$break_label";
	pop @$loop;
    }
}

@SWF::Builder::ActionScript::SyntaxNode::FunctionParameter::ISA=('SWF::Builder::ActionScript::SyntaxNode');
{
    package SWF::Builder::ActionScript::SyntaxNode::Function;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');
    use constant \%O;

    sub compile {
	my ($self, $context) = @_;
	my $stat = $self->{stat};
	my $code = $stat->{code};
	my $node = $self->{node};

	if ($context and $node->[0]) {
	    $self->_error('Can\'t declare named function in the expression');
	} elsif(!$context and !$node->[0]) {
	    $self->_error('Function name is necessary to declare function');
	}

	my $label = $stat->{label}++;
	my @args = (defined $node->[1]{node}) ? @{$node->[1]{node}} : ();
 
	if ($stat->{Optimize} & O_LOCALREG) {
	    my $flags = 0;
	    my $bit = 0;
	    my $regvars = $self->{regvars};
	    for my $prevar (qw/ this arguments super /) {
		if (exists $regvars->{$prevar}) {
		    $flags |= 1<<$bit;
			$bit += 2;
		} else {
		    $bit++;
		    $flags |= 1<<$bit;
		    $bit++;
		}
	    }
	    for my $prevar (qw/ _root _parent _global /) {
		if (exists $regvars->{$prevar}) {
		    $flags |= 1<<$bit;
			$bit ++;
		}
	    }
	    for my $arg (@args) {
		$arg .= '='.$regvars->{$arg} if exists $regvars->{$arg};
	    }
	    push @$code, "DefineFunction2 '".$node->[0]."' ".join(' ', $regvars->{' regcount'}, $flags, @args, $label);
	    $node->[2]->compile;
	} else {
	    push @$code, "DefineFunction '".$node->[0]."' ".join(' ', @args, $label);
	    if (($stat->{Optimize} & O_REGISTER) and (my $regcount = $self->{regvars}{' regcount'}) > 0) {

		my $push = 'Push ';
		for (1..$regcount) {
		    $push .= "Register '$_', ";
		}
		$push =~ s/, $//;
		push @$code, $push;

		$node->[2]->compile;

		for (my $i = $regcount; $i >= 1; $i--) {
		    push @$code, "StoreRegister '$i'", "Pop";
		}
	    } else {
		$node->[2]->compile;
	    }
	}
	push @$code, ":$label";
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::MethodCall;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $code = $self->{stat}{code};
	my $method = $self->{node}[0];

	if (ref($method)) {
	    $method->compile('value');
	} else {
	    if ($method) {
		push @$code, "Push String '".$method."'";
	    } else {
		push @$code, "Push UNDEF ''";
	    }
	}
	push @$code, 'CallMethod';
	push @$code, 'Pop' unless $context;
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::CallExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $code = $self->{stat}{code};
	my $node = $self->{node};
	my ($func, $args, $members, $methods) = @$node;

	while (my $callarg = pop @$methods) {
	    $callarg->compile('value');
	}

	{ # special function call ? 
	    if (ref($func) =~/:Variable$/) {
		my $spf = 'spf_'.lc($func->{node}[0]);
		if ($self->can($spf)) {
		    $self->$spf($args, (@$members == 0 and @$methods == 0) ? $context : 'value');
		    last;
		}
	    }
	  # not special.
	    $args->compile;
	    $func->compile('name');
	    if (ref($func) =~/:MemberExpression$/) {
		push @$code, "CallMethod";
	    } else {
		push @$code, "CallFunction";
	    }
	}
	unless (@$members) {
	    push @$code, 'Pop' unless $context;
	    return;
	}

	my $last = pop @$members;

	for my $member (@$members) {
	    $member->compile('value');
	}
	$last->compile($context);
    }

    sub _lhs {
	my ($name, $args, $members, $methods) = @{shift->{node}};

	if (lc($name->{node}[0]) eq 'eval' and @$members == 0 and @$methods == 0) {
	    return $name->{stat}{Version}<=5;
	}
	return (ref($members->[-1])=~/:Member$/);
    }


    sub spf_call {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('call') if @{$args->{node}} != 1;

	$args->{node}[0]->compile('value');
	push @$code, 'Call', "Push UNDEF ''";
    }

    sub spf_duplicatemovieclip {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('duplicateMovieClip') if @{$args->{node}} != 3;
	my ($target, $name, $depth) = @{$args->{node}};

	$target->compile('value');
	$name->compile('value');
	if (ref($depth)=~/:NumberLiteral$/) {
	    my $d = $depth->{node}[0] + 16384;
	    push @$code, "Push Number '$d'";
	} else {
	    push @$code, "Push Number '16384'";
	    $depth->compile('depth');
	    push @$code, 'Add2';
	}
	push @$code, 'CloneSprite', "Push UNDEF ''";
    }

    sub spf_eval {
	my ($self, $args, $context) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('eval') if @{$args->{node}} != 1;
	$args->{node}[0]->compile('value');
	if ($context eq 'value' or not $context) {
	    push @$code, 'GetVariable';
	} elsif ($context eq 'lvalue') {
	    push @$code, 'SetVariable', -1;
	} elsif ($context eq 'lcvalue') {
	    push @$code, 'PushDuplicate', 'GetVariable', 'SetVariable', -1;
	}
    }

    sub spf_set {
	my ($self, $args, $context) = @_;

	$self->_warn(0, "'set' is not recommended to use."); 

	my $code = $self->{stat}{code};
	$self->_error_param('eval') if @{$args->{node}} != 2;
	$args->{node}[0]->compile('value');
	$args->{node}[1]->compile('value');
	push @$code, "StoreRegister '0'" if $context;
	push @$code, 'SetVariable';
	push @$code, "Push Register '0'" if $context;
    }

    sub spf_fscommand {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param("fscommand") if @{$args->{node}} != 2;
	my ($command, $param) = @{$args->{node}};

	if ($command->isa('SWF::Builder::ActionScript::SyntaxNode::Literal') and
	    $param->isa('SWF::Builder::ActionScript::SyntaxNode::Literal')) {
		push @$code, "GetURL 'FSCommand:".$command->{node}[0]."' '".$param->{node}[0]."'";
	} else {
	    if ($command->isa('SWF::Builder::ActionScript::SyntaxNode::Literal')) {
		push @$code, "Push String 'FSCommand:".$command->{node}[0]."'";
	    } else {
		push @$code, "Push String 'FSCommand:'";
		$command->compile('value');
		push @$code, 'StringAdd';
	    }
	    $param->compile('value');
	    push @$code, "GetURL2 '0'";
	}
	push @$code, "Push UNDEF ''";
    }

    sub spf_getproperty {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	my $target = $args->{node}[0];
	my $property = lc($args->{node}[1]{node}[0]);

	$self->_error_param('getProperty') if @{$args->{node}} != 2;
	$self->_error("'%s' is not a property identifier.", $property) unless exists $property{$property};
	$self->_warn(0, "'getProperty' is not recommended to use."); 
	$target->compile('value');
	push @$code, "Push Property '".$property."'", 'GetProperty';
    }

    sub spf_setproperty {
	my ($self, $args) = @_;
	$self->_error_param('setProperty') if @{$args->{node}} != 3;

	my $code = $self->{stat}{code};
	my $target = $args->{node}[0];
	my $property = lc($args->{node}[1]{node}[0]);
	my $value = $args->{node}[2];

	$self->_error("'%s' is not a property identifier.", $property) unless exists $property{$property};
	$self->_warn(0, "'setProperty' is not recommended to use."); 
	$target->compile('value');
	push @$code, "Push Property '".$property."'";
	$value->compile('value');
	push @$code, 'SetProperty', "Push UNDEF ''";
    }

    sub spf_gettimer {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('getTimer') if @{$args->{node}} != 0;
	push @$code, "GetTime";
    }

    sub spf_geturl {
	my ($self, $args, $context, $fname, $ext) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param($fname||'getURL') if @{$args->{node}} > 3 or @{$args->{node}} <= 0;
	my ($url, $target, $method) = @{$args->{node}};

	if (!$ext and !defined $method and $url->isa('SWF::Builder::ActionScript::SyntaxNode::Literal') and (!defined $target or $target->isa('SWF::Builder::ActionScript::SyntaxNode::Literal'))) {
	    $target = $target->{node}[0] if defined $target;
	    push @$code, "GetURL '".$url->{node}[0]."' '$target'";
	} else {
	    if (defined $method) {
		$self->_error("Third parameter of 'getURL' must be 'GET' or 'POST'.") unless ref($method) =~/:StringLiteral/;
		$method = lc($method->{node}[0]);
		$self->_error("Third parameter of 'getURL' must be 'GET' or 'POST'.") unless $method eq 'get' or $method eq 'post';
		$method = $method eq 'get' ? 1 : 2;
	    } else {
		$method = 0;
	    }
	    $method |= $ext;
	    $url->compile('value');
	    if (defined $target) {
		$target->compile('value');
	    } else {
		push @$code, "Push String ''";
	    }
	    push @$code, "GetURL2 '$method'";
	}
	push @$code, "Push UNDEF ''";
    }

    sub spf_getversion {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('getVersion') if @{$args->{node}} != 0;
	push @$code, "Push String '/:\$version'", 'GetVariable';
    }

    sub spf_gotoandplay {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('gotoAndPlay') if @{$args->{node}} > 2 or @{$args->{node}} <= 0;
	$self->_error("Scene is not supported.") if @{$args->{node}} == 2;
	my $frame = $args->{node}[0];

	if (ref($frame) =~/:NumberLiteral/) {
	    $frame = int($frame->{node}[0])-1;
	    $frame = 0 if $frame < 0;
	    push @$code, "GotoFrame '$frame'", "Play";
	} elsif (ref($frame) =~/:StringLiteral/) {
	    push @$code, "GotoLabel '".$frame->{node}[0]."'", "Play";
	} else {
	    $frame->compile('value');
	    push @$code, "GotoFrame2 '1'";
	}
	push @$code, "Push UNDEF ''";
    }

    sub spf_gotoandstop {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('gotoAndStop') if @{$args->{node}} > 2 or @{$args->{node}} <= 0;
	$self->_error("Scene is not supported.") if @{$args->{node}} == 2;
	my $frame = $args->{node}[0];

	if (ref($frame) =~/:NumberLiteral/) {
	    $frame = int($frame->{node}[0])-1;
	    $frame = 0 if $frame < 0;
	    push @$code, "GotoFrame '$frame'";
	} elsif (ref($frame) =~/:StringLiteral/) {
	    push @$code, "GotoLabel '".$frame->{node}[0]."'";
	} else {
	    $frame->compile('value');
	    push @$code, "GotoFrame2 '0'";
	}
	push @$code, "Push UNDEF ''";
    }

    sub spf_loadmovie {
	push @_, 'loadMovie', 64;
	&spf_geturl;
    }

    sub spf_unloadmovie {
	my ($self, $args) = @_;

	unshift @{$args->{node}}, bless {stat=> $self->{stat}, node=>['']}, 'SWF::Builder::ActionScript::SyntaxNode::StringLiteral';
	push @_, 'unloadMovie', 64;
	&spf_geturl;
    }

    sub spf_loadmovienum {
	my ($self, $args) = @_;

	_level2target($args, 1);
	$_[3]='loadMovieNum' unless $_[3];;
	&spf_geturl;
    }

    sub spf_unloadmovienum {
	my ($self, $args) = @_;

	unshift @{$args->{node}}, bless {stat=> $self->{stat}, node=>['']}, 'SWF::Builder::ActionScript::SyntaxNode::StringLiteral';
	_level2target($args, 1);
	$_[3]='unloadMovieNum' unless $_[3];;
	&spf_geturl;
    }

    sub _level2target {
	my $args = shift;
	my $n = shift;
	my $num = $args->{node}[$n];

	if (ref($num)=~/:NumberLiteral/) {
	    $args->{node}[$n] = bless {
		line => $num->{line},
		stat => $num->{stat},
		node => ['_level'.int($num->{node}[0])]
	    }, 'SWF::Builder::ActionScript::SyntaxNode::StringLiteral';
	} else {
	    $args->{node}[$n] = bless {
		line => $num->{line},
		stat => $num->{stat},
		node => 
		    [
		     (bless {
			 line => $num->{line},
			 stat => $num->{stat},
			 node => ['_level']
			 }, 'SWF::Builder::ActionScript::SyntaxNode::StringLiteral'),
		     $num, 'add'
		     ]
		}, 'SWF::Builder::ActionScript::SyntaxNode::BinaryOpExpression';
	}

    }

    sub spf_loadvariables {
	push @_, 'loadVariables', 192;
	&spf_geturl;
    }

    sub spf_loadvariablesnum {
	push @_, 'loadVariablesNum', 128;
	&spf_loadmovienum;
    }

    sub spf_nextframe {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('nextFrame') if @{$args->{node}} != 0;
	push @$code, "NextFrame", "Push UNDEF ''";
    }

    sub spf_prevframe {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('prevFrame') if @{$args->{node}} != 0;
	push @$code, "PrevFrame", "Push UNDEF ''";
    }

    sub spf_nextscene {
	shift->_error("Scene is not supported.");
    }

    sub spf_prevscene {
	shift->_error("Scene is not supported.");
    }

    sub spf_number {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('Number') if @{$args->{node}} != 1;

	$args->{node}[0]->compile('value');
	push @$code, 'ToNumber';
    }
    sub spf_play {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('play') if @{$args->{node}} != 0;
	push @$code, "Play", "Push UNDEF ''";
    }

    sub spf_stop {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('stop') if @{$args->{node}} != 0;
	push @$code, "Stop", "Push UNDEF ''";
    }

    sub spf_print {
	my ($self, $args, $context, $scheme) = @_;
	$scheme||='print';
	my $code = $self->{stat}{code};
	$self->_error_param($scheme) if @{$args->{node}} != 2;
	my ($target, $bbox) = @{$args->{node}};

	$self->_error("Second parameter of '$scheme' must be 'bframe', 'bmax' or 'bmovie'.") unless ref($bbox) =~/:StringLiteral/;
	$bbox = lc($bbox->{node}[0]);
	$self->_error("Second parameter of '$scheme' must be 'bframe', 'bmax' or 'bmovie'.") unless $bbox eq 'bframe' or $bbox eq 'bmax' or $bbox eq 'bmovie';

	($scheme = lc($scheme)) =~s/num$//;
	if ($bbox eq 'bmovie') {
	    push @$code, "Push String '$scheme:'";
	} else {
	    push @$code, "Push String '$scheme:#$bbox'";
	}
	$target->compile('value');
	push @$code, "GetURL2 '0'", "Push UNDEF ''";
    }

    sub spf_printasbitmap {
	push @_, 'printAsBitmap';
	&spf_print;
    }

    sub spf_printnum {
	my ($self, $args) = @_;

	_level2target($args,0);
	$_[3]='printNum' unless $_[3];
	&spf_print;
    }

    sub spf_printasbitmapnum {
	push @_, 'printAsBitmapNum';
	&spf_printnum;
    }

    sub spf_removemovieclip {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('removeMovieClip') if @{$args->{node}} != 1;

	$args->{node}[0]->compile('value');
	push @$code, 'RemoveSprite', "Push UNDEF ''";
    }

    sub spf_startdrag {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	my $n = @{$args->{node}};
	$self->_error_param('startDrag') unless $n == 1 or $n == 2 or $n == 6;

	my $target = shift(@{$args->{node}});
	my $lockcenter = shift(@{$args->{node}});

	if ($n == 6) {
	    for my $e(@{$args->{node}}) {
		$e->compile('value');
	    }
	    push @$code, "Push Boolean '1'";
	} else {
	    push @$code, "Push Boolean '0'";
	}
	if ($n > 1) {
	    $lockcenter->compile('value');
	} else {
	    push @$code, "Push Boolean '0'";
	}
	$target->compile('value');
	push @$code, 'StartDrag', "Push UNDEF ''";
    }

    sub spf_stopallsounds {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('stopAllSounds') if @{$args->{node}} != 0;
	push @$code, "StopSounds", "Push UNDEF ''";
    }

    sub spf_stopdrag {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('stopDrag') if @{$args->{node}} != 0;
	push @$code, 'EndDrag', "Push UNDEF ''";
    }

    sub spf_string {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('String') if @{$args->{node}} != 1;

	$args->{node}[0]->compile('value');
	push @$code, 'ToString';
    }

    sub spf_targetpath {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('targetPath') if @{$args->{node}} != 1;

	$args->{node}[0]->compile('value');
	push @$code, 'TargetPath';
    }

    sub spf_togglehighquality {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('toggleHighQuality') if @{$args->{node}} != 0;
	$self->_warn_not_recommend("'toggleHighQuality'", "'_quality' property");
	push @$code, 'ToggleQuality', "Push UNDEF ''";
    }

    sub spf_trace {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	my $trace = $self->{stat}{Trace};
	$self->_error_param('trace') if @{$args->{node}} != 1;

	if ($trace eq 'none') {
	    push @$code, "Push UNDEF ''";
	    return;
	}
	$args->{node}[0]->compile('value');
	return if $trace eq 'eval';
	if ($trace eq 'lcwin') {
	    push @$code, "Push String 'trace'", "Push String '__trace'", "Push Number '3'", "Push Number '0'", "Push String 'LocalConnection'", 'NewObject', "Push String 'send'", 'CallMethod';
	} else {
	    push @$code, "Trace";
	    push @$code, "Push UNDEF ''";
	}

    }


# FLASH4 math/string functions

    sub _flash4_fn {
	my ($self, $args, $context, $fname, $bytecode, $replace) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param($fname) if @{$args->{node}} != 1;
	$self->_warn_not_recommend("'$fname'", "'$replace'");

	$args->{node}[0]->compile('value');
	push @$code, $bytecode;
    }

    sub spf_chr {
	push @_, 'chr', 'AsciiToChar', 'String.fromCharCode';
	&_flash4_fn;
    }

    sub spf_int {
	push @_, 'int', 'ToInteger', 'Math.floor/ceil/round';
	&_flash4_fn;
    }

    sub spf_length {
	push @_, 'length', 'StringLength', 'String.length';
	&_flash4_fn;
    }

    sub spf_mbchr {
	push @_, 'mbchr', 'MBAsciiToChar', 'String.fromCharCode';
	&_flash4_fn;
    }

    sub spf_mblength {
	push @_, 'mblength', 'MBStringLength', 'String.length';
	&_flash4_fn;
    }

    sub spf_mbord {
	push @_, 'mbord', 'MBCharToAscii', 'String.charCodeAt';
	&_flash4_fn;
    }

    sub spf_ord {
	push @_, 'ord', 'CharToAscii', 'String.charCodeAt';
	&_flash4_fn;
    }

    sub spf_random {
	push @_, 'random', 'RandomNumber', 'Math.random';
	&_flash4_fn;
    }

    sub spf_substring {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('substring') if @{$args->{node}} != 3;
	$self->_warn_not_recommend("'substring'", "'String.substr'");

	for my $a (@{$args->{node}}) {
	    $a->compile('value');
	}
	push @$code, 'StringExtract';
    }

    sub spf_mbsubstring {
	my ($self, $args) = @_;
	my $code = $self->{stat}{code};
	$self->_error_param('mbsubstring') if @{$args->{node}} != 3;
	$self->_warn_not_recommend("'mbsubstring'", "'String.substr'");

	for my $a (@{$args->{node}}) {
	    $a->compile('value');
	}
	push @$code, 'MBStringExtract';
    }


}

{
    package SWF::Builder::ActionScript::SyntaxNode::NewExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $code = $self->{stat}{code};
	my $node = $self->{node};
	my $func = shift @$node;
	my $args = shift @$node;

	$args->compile;
	$func->compile('name');
	if ($func->isa('SWF::Builder::ActionScript::SyntaxNode::MemberExpression')) {
	    push @$code, "NewMethod";
	} else {
	    push @$code, "NewObject";
	}
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::Arguments;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $node = $self->{node};

	for my $s (reverse @$node) {
	    $s->compile('value');
	}
	push @{$self->{stat}{code}}, "Push Number '".@$node."'";
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::PrefixExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $code = $self->{stat}{code};

	$self->{node}[0]->compile('lcvalue');
	my $lv = pop @$code;
	my @lv = splice(@$code, $lv);
	push @$code, $self->{node}[1] eq '++' ? 'Increment' : 'Decrement';
	push @$code, "StoreRegister '0'" if $context;
	push @$code, @lv;
	push @$code, "Push Register '0'" if $context;
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::PostfixExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $code = $self->{stat}{code};

	$self->{node}[0]->compile('lcvalue');
	my $lv = pop @$code;
	my @lv = splice(@$code, $lv);
	push @$code, "StoreRegister '0'" if $context;
	push @$code, $self->{node}[1] eq '++' ? 'Increment' : 'Decrement';
	push @$code, @lv;
	push @$code, "Push Register '0'" if $context;
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::UnaryExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    my %unary_op = (
		    'void'   => ['Pop', "Push UNDEF ''"],
		    'typeof' => ['TypeOf'],
		    '-'      => ['Subtract'],
		    '~'      => ["Push Number '4294967295'", 'BitXor'],
		    '!'      => ['Not'],
		    );

    sub compile {
	my ($self, $context) = @_;
	my ($e, $op) = @{$self->{node}};
	my $code = $self->{stat}{code};

	push @$code, "Push Number '0'" if ($op eq '-' and $context);
	$e->compile($context);
	push @$code, @{$unary_op{$op}} if ($op ne '+' and $context);
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::DeleteExpression;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my ($self, $context) = @_;
	my $code = $self->{stat}{code};

	$self->{node}[0]->compile('name');
	if ($self->{node}[0]->isa('SWF::Builder::ActionScript::SyntaxNode::MemberExpression')) {
	    push @$code, "Delete";
	} else {
	    push @$code, "Delete2";
	}
	push @$code, "Pop" unless $context;
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::IfFrameLoadedStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $code = $self->{stat}{code};
	my $node = $self->{node};
	my $label = $self->{stat}{label}++;
	my $e = $node->[0];

	if (ref($e) =~ /NumberLiteral$/ and $e->{node}[0] =~ /^\d+$/) {
	    push @$code, "WaitForFrame '".$e->{node}[0]."' '$label'";
	} else {
	    $e->compile('value');
	    push @$code, "WaitForFrame2 '$label'";
	}
	$node->[1]->compile;
	push @$code, ":$label";
    }
}
{
    package SWF::Builder::ActionScript::SyntaxNode::TellTargetStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $code = $self->{stat}{code};
	my $node = $self->{node};
	my $e = $node->[0];
	my $refe = ref($e);

	if ($refe =~ /StringLiteral$/) {
	    push @$code, "SetTarget '".$e->{node}[0]."'";
	} else {
	    $e->compile('value');
	    push @$code, "SetTarget2";
	}
	$node->[1]->compile;
	push @$code, "SetTarget ''";
    }
}

{
    package SWF::Builder::ActionScript::SyntaxNode::WithStatement;
    our @ISA = ('SWF::Builder::ActionScript::SyntaxNode');

    sub compile {
	my $self = shift;
	my $code = $self->{stat}{code};
	my $node = $self->{node};
	my $label = $self->{stat}{label}++;

	$node->[0]->compile('value');
	push @$code, "With '$label'";
	$node->[1]->compile;
	push @$code, ":$label";
    }
}

1;
