#
# parse PHP source files
#
package PHP::Decode::Parser;
use base 'PHP::Decode::Tokenizer';

use strict;
use warnings;
use Carp 'croak';
use Config;
use PHP::Decode::Array qw(is_int_index);
use Exporter qw(import);
our @EXPORT_OK = qw(is_variable is_symbol is_null is_const is_numval is_strval is_array is_block global_var global_split inst_var inst_split method_name method_split ns_name ns_split);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.127';

# avoid 'Deep recursion' warnings for depth > 100
#
no warnings 'recursion';

my $stridx = 1;
my $numidx = 1;
my $constidx = 1;
my $funidx = 1;
my $callidx = 1;
my $elemidx = 1;
my $expridx = 1;
my $stmtidx = 1;
my $blkidx = 1;
my $pfxidx = 1;
my $objidx = 1;   # obj->
my $scopeidx = 1; # class::
my $refidx = 1;   # & $var
my $classidx = 1; # class name {}
my $instidx = 1;  # class instance
my $traitidx = 1; # trait name {}
my $nsidx = 1;    # namespace\
my $fhidx = 1;

# Initialize new parser using PHP::Decode::Tokenizer
# {inscript}   - set to indicate already inside of script
# {warn}       - warning message handler
# {log}        - log message handler
# {debug}      - debug message handler
# {filename}   - optional filename (if not stdin or textstr)
# {max_strlen} - max strlen for debug strings
#
sub new {
	my ($class, %args) = @_;
	my $strmap = $args{strmap} or croak __PACKAGE__ . " expects strmap";

	my $self = $class->SUPER::new(%args);
	$self->{max_strlen} = 0 unless exists $self->{max_strlen};
	$self->{tok} = []; # init token list

	# filename is required to decode __FILE__
	$self->{filename} = '__FILE__' unless exists $self->{filename};

	$strmap->{'__LINE__'} = 1 unless exists $strmap->{'__LINE__'};
	$strmap->{'#null'} = '' unless exists $strmap->{'#null'};
	return $self;
}

# A sub parser is always inscript (the parent might have inscript=0)
#
sub subparser {
	my ($self, %args) = @_;
	my $parser = PHP::Decode::Parser->new(strmap => $self->{strmap}, inscript => 1, filename => $self->{filename}, max_strlen => $self->{max_strlen}, warn => $self->{warn});
	$parser->{log} = $self->{log} if exists $self->{log};
	$parser->{debug} = $self->{debug} if exists $self->{debug};

	foreach my $k (keys %args) {
		$parser->{$k} = $args{$k};
	}
	return $parser;
}

sub clear_strmap {
	my ($self) = @_;

	$stridx = 1;
	$self->{strmap} = {};
	$self->{strmap}{'__LINE__'} = 1;
	return;
}

my %ctrlmap = map { chr($_) => sprintf "\\x%02x", $_ } (0x00..0x1f, 0x7f);

# convert controls from pattern to "\xNN"
#
sub escape_ctrl {
	my ($s, $pat) = @_;
	my @list = ();

	return "''" if ($s eq '');

	$_ = $s;
	while (1) {
		#if(/\G([${pat}])/sgc) {
		#	push(@list, sprintf "\"\\x%02x\"", ord($1));
		if(/\G([${pat}]+)/sgc) {
			push(@list, '"' . join('', map { exists $ctrlmap{$_} ? $ctrlmap{$_} : $_ } split(//, $1)) . '"');
		} elsif (/\G([^${pat}]+)/sgc) {
			push(@list, "'" . $1 . "'");
		} else {
			last;
		}
	}
	return join('.', @list);
}

sub shortstr {
	my ($self, $s, $maxlen) = @_;

	if (!defined $s) {
		return '(null)';
	}

	# remove linefeeds
	#
	#$s =~ s/\r\n/ /g;

	# remove non-printable 
	#
	$s =~ s/[\x01-\x1f\x7f]/\./g;

	if (($self->{max_strlen} > 0) && (!$maxlen || ($maxlen > $self->{max_strlen}))) {
		$maxlen = $self->{max_strlen};
	}
	if ($maxlen && (length($s) > $maxlen)) {
		$s = substr($s, 0, $maxlen-2).'..';
	}
	return $s;
}

# 'str' -> #str$i
#
sub setstr {
	my ($self, $v) = @_;
	my $k;

	if (exists $self->{strmap}->{rev}{$v}) {
		$k = $self->{strmap}->{rev}{$v};
		return $k;
	} else {
		$k = "#str$stridx";
		$stridx++;
		$self->{strmap}->{$k} = $v;
		$self->{strmap}->{rev}{$v} = $k;
	}
	# TODO: log also for $opt{P}
	$self->{log}->('setstr', "%s = %s", $k, $self->shortstr($v, $self->{max_strlen} || 60)) if $self->{log};
	return $k;
}

# for expensive operations like repeated strconcat don't
# store reverse entry to save some space 
#
sub setstr_norev {
	my ($self, $v) = @_;
	my $k;

	if (exists $self->{strmap}->{rev}{$v}) {
		$k = $self->{strmap}->{rev}{$v};
		return $k;
	} else {
		$k = "#str$stridx";
		$stridx++;
		$self->{strmap}->{$k} = $v;
	}
	# TODO: log also for $opt{P}
	$self->{log}->('setstr', "%s = %s [norev]", $k, $self->shortstr($v, $self->{max_strlen} || 60)) if $self->{log};
	return $k;
}

# number -> #num$i
#
sub setnum {
	my ($self, $v) = @_;
	my $k;

	if (exists $self->{strmap}->{num}{$v}) {
		$k = $self->{strmap}->{num}{$v};
		return $k;
	} else {
		$k = "#num$numidx";
		$numidx++;
		$self->{strmap}->{$k} = $v;
		$self->{strmap}->{num}{$v} = $k;
	}
	$self->{log}->('setnum', "%s = %s", $k, $self->shortstr($v, 60)) if $self->{log};
	return $k;
}

# 'const' -> #const$i
#
sub setconst {
	my ($self, $v) = @_;
	my $k = "#const$constidx";
	$constidx++;

	$self->{strmap}->{$k} = $v;
	$self->{log}->('setconst', "%s = %s", $k, $v) if $self->{log};
	return $k;
}

sub newarr {
	my ($self) = @_;
	my $arr = PHP::Decode::Array->new(strmap => $self->{strmap});
	$self->{log}->('newarr', "%s", $arr->{name}) if $self->{log};
	return $arr;
}

# function -> #fun$i
#
sub setfun {
	my ($self, $cmd, $arglist, $block, $p) = @_;
	my $k = "#fun$funidx";
	$funidx++;

	$self->{strmap}->{$k} = [$cmd, $arglist, $block, $p];
	$self->{log}->('setfun', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setcall {
	my ($self, $cmd, $arglist) = @_;
	my $k = "#call$callidx";
	$callidx++;

	$self->{strmap}->{$k} = [$cmd, $arglist];
	$self->{log}->('setcall', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setelem {
	my ($self, $var, $idx) = @_;
	my $k = "#elem$elemidx";
	$elemidx++;

	$self->{strmap}->{$k} = [$var, $idx];
	$self->{log}->('setelem', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setexpr {
	my ($self, $op, $v1, $v2) = @_;
	my $k = "#expr$expridx";
	$expridx++;

	$self->{strmap}->{$k} = [$op, $v1, $v2];
	$self->{log}->('setexpr', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setblk {
	my ($self, $type, $a) = @_;
	my $k = "#blk$blkidx";
	$blkidx++;

	$self->{strmap}->{$k} = [$type, $a];
	$self->{log}->('setblk', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setstmt {
	my ($self, $s) = @_;
	my $k = "#stmt$stmtidx";
	$stmtidx++;

	$self->{strmap}->{$k} = $s;
	$self->{log}->('setstmt', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setpfx {
	my ($self, $s) = @_;
	my $k = "#pfx$pfxidx";
	$pfxidx++;

	$self->{strmap}->{$k} = $s;
	$self->{log}->('setpfx', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setobj {
	my ($self, $s, $property) = @_;
	my $k = "#obj$objidx";
	$objidx++;

	$self->{strmap}->{$k} = [$s, $property];
	$self->{log}->('setobj', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setscope {
	my ($self, $s, $elem) = @_;
	my $k = "#scope$scopeidx";
	$scopeidx++;

	$self->{strmap}->{$k} = [$s, $elem];
	$self->{log}->('setscope', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setref {
	my ($self, $s) = @_;
	my $k = "#ref$refidx";
	$refidx++;

	$self->{strmap}->{$k} = [$s];
	$self->{log}->('setref', "%s = %s", $k, $s) if $self->{log};
	return $k;
}

sub setclass {
	my ($self, $name, $block, $p) = @_;
	my $k = "#class$classidx";
	$classidx++;

	$self->{strmap}->{$k} = [$name, $block, $p];
	$self->{log}->('setclass', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub settrait {
	my ($self, $name, $block) = @_;
	my $k = "#trait$traitidx";
	$traitidx++;

	$self->{strmap}->{$k} = [$name, $block];
	$self->{log}->('settrait', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub setinst {
	my ($self, $class, $initcall, $instctx) = @_;
	my $k = "#inst$instidx";
	$instidx++;

	$self->{strmap}->{$k} = [$class, $initcall, $instctx];
	$self->{log}->('setinst', "%s = %s", $k, $class) if $self->{log};
	return $k;
}

sub setns {
	my ($self, $name, $elem) = @_;
	my $k = "#ns$nsidx";
	$nsidx++;

	$self->{strmap}->{$k} = [$name, $elem];
	$self->{log}->('setns', "%s = %s", $k, $self->stmt_str($k)) if $self->{log};
	return $k;
}

sub newfh {
	my ($self, $filename, $mode) = @_;
	my %file;
	my $a;
	my $fh = "#fh$fhidx";
	$fhidx++;

	$self->{strmap}->{$fh} = \%file;
	$self->{strmap}->{idx}{$fh} = 0;

	$file{name} = $filename;
	$file{mode} = $mode;
	$file{pos} = 0;
	if ($filename eq '__FILE__') {
		$file{buf} = $self->{strmap}->{$filename}; # todo: cleanup
	} else {
		$file{buf} = '';
		return; # TODO: support write & non-existing files
	}
	$self->{log}->('newfh', "$fh ($filename, $mode)") if $self->{log};
	return ($fh, \%file);
}

sub stmt_str {
	my ($self, $s) = @_;

	unless ($s =~ /^#\w+\d+$/) {
		return $s;
	}

	if ($s =~ /^#null$/) {
		return 'null'; # '' or 0 in str/num context
	} elsif ($s =~ /^#num\d+$/) {
		return $self->{strmap}{$s};
	} elsif ($s =~ /^#const\d+$/) {
		return $self->{strmap}{$s};
	} elsif ($s =~ /^#str\d+$/) {
		my $v = $self->{strmap}{$s};
		return $self->shortstr($v, 60);
	} elsif ($s =~ /^#arr\d+$/) {
		my $arr = $self->{strmap}{$s};
		my $keys = $arr->get_keys();
		my $size = scalar @$keys;

		return $arr->{name} . "[size $size]";
	} elsif ($s =~ /^#fun\d+$/) {
		my ($f, $a, $b, $p) = @{$self->{strmap}{$s}};
		my ($type, $stmts) = @{$self->{strmap}{$b}};

		return (defined $f ? $f : '') . "(" . join(', ', @$a) . ") { " . join(' ', @$stmts) . " }";
	} elsif ($s =~ /^#call\d+$/) {
		my ($f, $a) = @{$self->{strmap}->{$s}};

		return $f . "(" . join(', ', @$a) . ")";
	} elsif ($s =~ /^#elem\d+$/) {
		my ($v, $i) = @{$self->{strmap}{$s}};

		return $v . "[" . (defined $i ? $i : '') . "]";
	} elsif ($s =~ /^#expr\d+$/) {
		# if v1 missing: prefix op
		# if v2 missing: postfix op
		my ($op, $v1, $v2) = @{$self->{strmap}{$s}};

		return (defined $v1 ? $v1 . " " : '') . $op . (defined $v2 ? " " . $v2 : '');
	} elsif ($s =~ /^#pfx\d+$/) {
		my $pfx = $self->{strmap}{$s};
		return join(' ', sort keys %$pfx);
	} elsif ($s =~ /^#obj\d+$/) {
		my ($o, $m) = @{$self->{strmap}{$s}};
		return $o . "->" . $m;
	} elsif ($s =~ /^#scope\d+$/) {
		my ($c, $e) = @{$self->{strmap}{$s}};
		return $c . "::" . $e;
	} elsif ($s =~ /^#ns\d+$/) {
		my ($n, $e) = @{$self->{strmap}{$s}};
		return (defined $n ? $n : '') . '\\' . $e;
	} elsif ($s =~ /^#inst\d+$/) {
		my ($c, $f, $i) = @{$self->{strmap}{$s}};
		return $c;
	} elsif ($s =~ /^#ref\d+$/) {
		my ($v) = @{$self->{strmap}{$s}};
		return "&" . $v;
	} elsif ($s =~ /^#class\d+$/) {
		my ($c, $b, $p) = @{$self->{strmap}{$s}};
		my ($type, $stmts) = @{$self->{strmap}{$b}};

		return (defined $c ? $c : '') . (exists $p->{parent} ? " extends $p->{parent}" : '') . " { " . join(' ', @$stmts) . " }";
	} elsif ($s =~ /^#trait\d+$/) {
		my ($t, $b) = @{$self->{strmap}{$s}};
		my ($type, $stmts) = @{$self->{strmap}{$b}};

		return (defined $t ? $t : '') . " { " . join(' ', @$stmts) . " }";
	} elsif ($s =~ /^#fh\d+$/) {
		my $f = $self->{strmap}{$s}{name};
		my $m = $self->{strmap}{$s}{mode};
		my $p = $self->{strmap}{$s}{pos};

		return "(" . $f . ", " . $m . ")";
	} elsif ($s =~ /^#blk\d+$/) {
		my ($type, $a) = @{$self->{strmap}{$s}};
		return $type . " { " . join(' ', @$a) . " }";
	} elsif ($s =~ /^#stmt\d+$/) {
		my $cmd = $self->{strmap}{$s}[0];

		if ($cmd eq 'echo') {
			my $a = $self->{strmap}{$s}[1];
			return $cmd . " " . join(', ', @$a);
		} elsif ($cmd eq 'print') {
			my $arg = $self->{strmap}{$s}[1];
			return $cmd . " " . $arg;
		} elsif ($cmd eq 'namespace') {
			my ($arg, $block) = @{$self->{strmap}->{$s}}[1..2];
			return $cmd . " " . $arg . (defined $block ? " { $block }" : '');
		} elsif ($cmd =~ /^(include|include_once|require|require_once)$/) {
			my $arg = $self->{strmap}{$s}[1];
			return $cmd . " " . $arg;
		} elsif ($cmd eq 'use') {
			my $a = $self->{strmap}{$s}[1];
			return $cmd . " " . join(', ', @$a);
		} elsif ($cmd eq 'global') {
			my $a = $self->{strmap}{$s}[1];
			return $cmd . " " . join(', ', @$a);
		} elsif ($cmd eq 'static') {
			my ($a, $p) = @{$self->{strmap}{$s}}[1..2];
			return $cmd . join(' ', (grep { $_ ne $cmd } sort keys %$p), $cmd) . ' ' . join(', ', @$a);
		} elsif ($cmd eq 'const') {
			my ($a, $p) = @{$self->{strmap}{$s}}[1..2];
			return $cmd . join(' ', (grep { $_ ne $cmd } sort keys %$p), $cmd) . ' ' . join(', ', @$a);
		} elsif ($cmd eq 'unset') {
			my $a = $self->{strmap}{$s}[1];
			return $cmd . " (" . join(', ', @$a) . ")";
		} elsif ($cmd eq 'return') {
			my $a = $self->{strmap}{$s}[1];
			return $cmd . " " . $a;
		} elsif ($cmd eq 'goto') {
			my $a = $self->{strmap}{$s}[1];
			return $cmd . " " . $a;
		} elsif ($cmd eq 'label') {
			my $a = $self->{strmap}{$s}[1];
			return $cmd . " " . $a . ":";
		} elsif ($cmd eq 'throw') {
			my $arg = $self->{strmap}{$s}[1];
			return $cmd . " " . $arg;
		} elsif ($cmd eq 'if') {
			my ($cond, $then, $else) = @{$self->{strmap}{$s}}[1..3];
			return $cmd . " ($cond) then $then" . (defined $else ? " else $else" : '');
		} elsif ($cmd eq 'while') {
			my ($cond, $block) = @{$self->{strmap}{$s}}[1..2];
			return $cmd . " ($cond) { $block }";
		} elsif ($cmd eq 'do') {
			my ($cond, $block) = @{$self->{strmap}{$s}}[1..2];
			return $cmd . " { $block } while ($cond)";
		} elsif ($cmd eq 'for') {
			my ($pre, $cond, $post, $block) = @{$self->{strmap}{$s}}[1..4];
			return $cmd . " ($pre; $cond; $post) { $block }";
		} elsif ($cmd eq 'foreach') {
			my ($expr, $key, $value, $block) = @{$self->{strmap}{$s}}[1..4];
			return $cmd . " ($expr " . (defined $key ? "$key => " : '') . "$value) { $block }";
		} elsif ($cmd eq 'switch') {
			my ($expr, $cases) = @{$self->{strmap}{$s}}[1..2];
			return $cmd . " ($expr) { " . join(' ', map { sprintf "%s %s", defined $_->[0] ? "case $_->[0]:" : "default:", $_->[1]; } @$cases) . " }";
		} elsif ($cmd eq 'case') {
			my $expr = $self->{strmap}{$s}[1];
			return (defined $expr ? "case $expr:" : "default:");
		} elsif ($cmd eq 'try') {
			my ($try, $catches, $finally) = @{$self->{strmap}->{$s}}[1..3];
			return $cmd . " { $try }" . join(' ', map { sprintf " catch (%s) { %s }", $_->[0] // '-', $_->[1]; } @$catches) . (defined $finally ? " finally { $finally }" : '');
		} else {
			return $cmd;
		}
	}
	return $s;
}

sub val {
	my ($self, $s) = @_;
	#exists $self->{strmap}{$s} || die "assert: bad statement $s passed to parser->val()";
	return $self->{strmap}{$s}; # for lookup after is_strval(), is_array(), ..
}

sub get_strval {
	my ($self, $s) = @_;
	#defined($s) || die "assert: undefined statement passed to parser->get_strval()";

	if ($s =~ /^(\#(str|num|const)\d+|\#null)$/) {
		return $self->{strmap}{$s};
	}
	return;
}

sub get_strval_or_str {
	my ($self, $s) = @_;

	if ($s =~ /^(\#(str|num|const)\d+|\#null)$/) {
		$s = $self->{strmap}{$s};
	}
	return $s;
}

sub get_numval {
	my ($self, $s) = @_;

	if ($s =~ /^(\#num\d+|\#null)$/) {
		$s = $self->{strmap}{$s};
	}
	return $s;
}

sub is_null {
	my ($s) = @_;

	if ($s =~ /^(\#null)$/) {
		return 1;
	}
	return 0;
}

sub is_const {
	my ($s) = @_;

	if ($s =~ /^(\#const\d++)$/) {
		return 1;
	}
	return 0;
}

sub is_numval {
	my ($s) = @_;

	if ($s =~ /^(\#num\d+)$/) {
		return 1;
	}
	return 0;
}

sub is_strval {
	my ($s) = @_;

	if ($s =~ /^(\#(str|num|const)\d+|\#null)$/) {
		return 1;
	}
	return 0;
}

sub is_array {
	my ($s) = @_;

	if ($s =~ /^#arr\d+$/) {
		return 1;
	}
	return 0;
}

sub is_block {
	my ($s) = @_;

	if ($s =~ /^#blk\d+$/) {
		return 1;
	}
	return 0;
}

sub bighex {
	my ($hex) = @_;

	# hex() warns for 64-bit numbers like 0x10000000
	# (Hexadecimal number > 0xffffffff non-portable)
	# php converts such numbers to float.
	#
	# The 'use bigint qw/hex/' workaround would transparently
	# use Math::BigInt internally. So convert 64-bit floats
	# manually to float.
	#
	# also: perl warns for '0X'-prefix - php not
	#
	if (length($hex) <= 10) {
		if ($hex =~ /^0X(.*)$/) {
			return hex($1);
		} else {
			return hex($hex);
		}
	}
	my ($high, $low) = $hex =~ /^0[xX]([0-9a-fA-F]{1,8})([0-9a-fA-F]{8})$/;
	unless (defined $high) {
		warn "$hex is not a 64-bit hex number";
		return hex($hex);
	}
	# with 32bit integers perl truncates (1 << 32) to 0x1
	#
	# use bignum instead of bigint here - bigint overrides the
	# operators to result in a bigint when one of its operands
	# is a bigint (so division would never result in a float).
	# https://perldoc.perl.org/bigint
	#
	if ($Config{ivsize} == 4) {
		use bignum;
		return hex("0x$low") + (hex("0x$high") << 32);
	} else {
		return hex("0x$low") + (hex("0x$high") << 32);
	}
}

# override methods inherited from PhpTokenizer 
{
	sub add {
		my ($tab, $sym) = @_;
		push(@{$tab->{tok}}, $sym);
		return;
	}
	sub add_open {
		my ($tab, $sym) = @_;
		push(@{$tab->{tok}}, $sym);
		return;
	}
	sub add_close {
		my ($tab, $sym) = @_;
		my $pos = scalar @{$tab->{tok}};

		# join string literals with '.' operator if possible
		# (this should also be done by php_decode)
		#
		if (defined $tab->{strmap}
			&& ($sym eq ')')
			&& ($pos > 2)
			&& ($tab->{tok}->[$pos-1] =~ /^#num\d+$/) 
			&& ($tab->{tok}->[$pos-2] eq '(')
			&& ($tab->{tok}->[$pos-3] =~ /^chr$/i)) {
			my $val = $tab->{strmap}->{$tab->{tok}->[$pos-1]}; 
			if ($val != 0) {
				my $ch = chr(int($val) & 0xff);
				pop(@{$tab->{tok}});
				pop(@{$tab->{tok}});
				pop(@{$tab->{tok}});
				#$tab->{log}->('tokenize', "CHR chr($val) [$ch]") if $tab->{log};
				$tab->add_str($ch);
			} else {
				push(@{$tab->{tok}}, $sym);
			}
		} else {
			push(@{$tab->{tok}}, $sym);
		}
		return;
	}
	sub add_white {
		my ($tab, $sym) = @_;
		if ($sym eq "\n") {
			$tab->{strmap}->{'__LINE__'} += 1;
			$tab->{debug}->('tokenize', "set linenum: %d", $tab->{strmap}->{'__LINE__'}) if $tab->{debug};
		}
		#push(@{$tab->{tok}}, ' ');
		return;
	}
	sub add_comment {
		my ($tab, $sym) = @_;
		#push(@{$tab->{tok}}, "/*$sym*/");
		return;
	}
	sub add_sym {
		my ($tab, $sym) = @_;
		if ($sym eq '__LINE__') {
			# TODO: track line-number for each symbol, so that
			#       it is also valid in eval()-code?
			#
			$tab->{warn}->('tokenize', "substitute __LINE__ with %d", $tab->{strmap}->{'__LINE__'});
			my $k = $tab->setnum($tab->{strmap}->{'__LINE__'});
			push(@{$tab->{tok}}, $k);
		} else {
			push(@{$tab->{tok}}, $sym);
		}
		return;
	}
	sub add_var {
		my ($tab, $sym) = @_;
		push(@{$tab->{tok}}, '$'.$sym);
		return;
	}
	sub add_str {
		my ($tab, $sym) = @_;

		if (defined $tab->{strmap}) {
			my $pos = scalar @{$tab->{tok}};

			# join string literals with '.' operator if possible
			# (this should also be done by php_decode)
			#
			if (($pos > 1) && ($tab->{tok}->[$pos-1] eq '.') && ($tab->{tok}->[$pos-2] =~ /^#str\d+$/)) {
				my $oldstr = $tab->{strmap}->{$tab->{tok}->[$pos-2]}; 
				pop(@{$tab->{tok}});
				pop(@{$tab->{tok}});
				#$tab->{log}->('tokenize', "JOIN $oldstr . $sym") if $tab->{log};
				$sym = $oldstr . $sym;
			}

			# remember last linenum for each new #str symbol
			#
			$tab->{strmap}->{'__LINEMAP__'}{"#str$stridx"} = $tab->{strmap}->{'__LINE__'};

			# substitute: 'str' -> #str$i
			#
			my $k = $tab->setstr($sym);
			push(@{$tab->{tok}}, $k);
		} else {
			push(@{$tab->{tok}}, '\'');
			push(@{$tab->{tok}}, $sym);
			push(@{$tab->{tok}}, '\'');
		}
		return;
	}
	sub add_num {
		my ($tab, $sym) = @_;

		if (defined $tab->{strmap}) {
			# substitute: number -> #num$i
			# 
			my $num;
			if ($sym =~ /^0[xX][0-9a-fA-F]+$/) {
				#$num = hex($sym);
				$num = bighex($sym);
			} elsif ($sym =~ /^0[0-7]+$/) {
				$num = oct($sym);
			} elsif ($sym =~ /^[0-9]*\.[0-9]*/) {
				$num = $sym * 1; 
			} else {
				$num = $sym;
			}
			my $k = $tab->setnum($num);
			push(@{$tab->{tok}}, $k);
		} else {
			push(@{$tab->{tok}}, $sym);
		}
		return;
	}
	sub add_script_start {
		my ($tab, $sym) = @_;
		#push(@{$tab->{tok}}, $sym);
		return;
	}
	sub add_script_end {
		my ($tab, $sym) = @_;
		#push(@{$tab->{tok}}, $sym);
		return;
	}
	sub add_noscript {
		my ($tab, $sym) = @_;

		if ((scalar @{$tab->{tok}} > 0) && ($tab->{tok}->[-1] ne ';')) {
			# append ';' if missing at end of php-block
			$tab->add(';');
		}
		$tab->add_sym('echo');
		$tab->add_str($sym);
		$tab->add(';');
		$tab->add_script_end('');
		return;
	}
	sub add_bad_open {
		my ($tab, $sym) = @_;

		$tab->{warn}->('tokenize', "in script got bad open %s", $sym);
		$tab->add($sym); 
		return;
	}
	sub tok_dump {
		my ($tab) = @_;
		return join('', @{$tab->{tok}});
	}
	sub tok_count {
		my ($tab) = @_;
		return scalar @{$tab->{tok}};
	}
}

# http://php.net/manual/en/reserved.keywords.php
# 
my %php_keywords = map { $_ => 1 } ('__halt_compiler', 'abstract', 'and', 'array', 'as', 'break', 'callable', 'case', 'catch', 'class', 'clone', 'const', 'continue', 'declare', 'default', 'die', 'do', 'echo', 'else', 'elseif', 'empty', 'enddeclare', 'endfor', 'endforeach', 'endif', 'endswitch', 'endwhile', 'eval', 'exit', 'extends', 'final', 'for', 'foreach', 'function', 'global', 'goto', 'if', 'implements', 'include', 'include_once', 'instanceof', 'insteadof', 'interface', 'isset', 'list', 'namespace', 'new', 'or', 'print', 'private', 'protected', 'public', 'readonly', 'require', 'require_once', 'return', 'static', 'switch', 'throw', 'trait', 'try', 'unset', 'use', 'var', 'while', 'xor');

my %php_modifiers = map { $_ => 1 } ('const', 'final', 'private', 'protected', 'public', 'readonly', 'static', 'var');

# All magic constants are resolved at compile time
# https://www.php.net/manual/en/language.constants.magic.php
#
my %magic_constants = map { $_ => 1 } ('__CLASS__', '__DIR__', '__FILE__', '__FUNCTION__', '__LINE__', '__METHOD__', '__NAMESPACE__', '__TRAIT__', 'ClassName::class');

# builtin types: https://www.php.net/manual/en/language.types.intro.php
#
use constant {
	T_VOID   => 0x0001,
	T_INT    => 0x0002,
	T_FLOAT  => 0x0004,
	T_BOOL   => 0x0008,
	T_STR    => 0x0010,
	T_ARRAY  => 0x0020,
	T_OBJECT => 0x0040,
	T_CALL   => 0x0080,
	T_MASK   => 0xffff,
};


# see: http://perldoc.perl.org/perlop.html#Operator-Precedence-and-Associativity
#      http://php.net/manual/en/language.operators.precedence.php
#
my %op_prio = (
	'\\' => 0,
	'->' => 1,
	'::' => 1,
	'+-' => 2, # sign
	'$'  => 2,
	'++' => 2,
	'--' => 2,
	'new'=> 2, # unary
	'**' => 3,
	'!'  => 4, # unary
	'~'  => 4, # unary
	'*'  => 5,
	'/'  => 5,
	'%'  => 5,
	'+'  => 6,
	'-'  => 6,
	'.'  => 6,
	'<<' => 7,
	'>>' => 7,
	'<'  => 8,
	'>'  => 8,
	'<=' => 8,
	'>=' => 8,
	'lt' => 8, # (does not exist in php5-8)
	'gt' => 8, # (does not exist in php5-8)
	'le' => 8, # (does not exist in php5-8)
	'ge' => 8, # (does not exist in php5-8)
	'==' => 9,
	'!=' => 9,
	'<>' => 9, # diamond seems to work as != even if not documented
	'===' => 9,
	'!==' => 9,
	'<=>' => 9, # spaceship since php7
	'eq' => 9, # (does not exist in php5-8)
	'ne' => 9, # (does not exist in php5-8)
	'&'  => 10,
	'^'  => 11,
	'|'  => 12,
	'&&' => 13,
	'||' => 14,
	'??' => 15, # right since php7
	':'  => 16, # right
	'?'  => 17, # right
	'?:' => 17, # right
	'='  => 18, # right
	'not'=> 19, # right (does not exist in php5-8)
	'and'=> 20,
	'or' => 21,
	'xor'=> 21,
	'instanceof'=> 21,
	'...'=> 22, # ellipses
);

my %op_right = (
	'**' => 1, # right associative
	'->' => 1, # right associative
	'::' => 1, # right associative
	'??' => 1, # right associative
	'$'  => 1, # right associative
	'='  => 1, # right associative
);

my %op_unary = (
	'new'=> 1, # unary
	'!'  => 1, # unary
	'~'  => 1, # unary
	'?'  => 1, # in ternary (dummy for op_prio)
	':'  => 1, # in ternary (dummy for op_prio)
);

# Variables, constants & function names: ^[a-zA-Z_\x80-\xff][a-zA-Z0-9_\x80-\xff]*$
# see: https://www.php.net/manual/en/language.variables.basics.php
# see: https://www.php.net/manual/en/language.constants.php
# see: https://www.php.net/manual/en/functions.user-defined.php
#
sub is_variable {
	my ($s) = @_;

	# represent global vars as $GLOBALS$varname
	# represent class vars as $classname$varname
	# represent instance vars as $#instNNN$varname
	# represent non symbol ${"xxx"} vars also as $#instNNN$varname
	#
	if ($s =~/^\$(GLOBALS\$|#inst\d+\$|[\w\x80-\xff]+\$)?(\$|[^\$]*)$/) {
		return 1;
	}
	return 0;
}

sub is_strict_variable {
	my ($s) = @_;

	if ($s =~/^\$(GLOBALS\$|#inst\d+\$|[\w\x80-\xff]+\$)?[a-zA-Z_\x80-\xff][a-zA-Z0-9_\x80-\xff]*$/) {
		return 1;
	}
	return 0;
}

sub is_symbol {
	my ($s) = @_;

	if ($s =~/^[a-zA-Z_\x80-\xff][a-zA-Z0-9_\x80-\xff]*$/) {
		return 1;
	}
	return 0;
}

sub is_magic_const {
	my ($self, $s) = @_;

	if ($s =~ /^#const\d+$/) {
		if (exists $magic_constants{$self->{strmap}->{$s}}) {
			return $self->{strmap}->{$s};
		}
	}
	return;
}

# check if statement is empty block
#
sub is_empty_block {
	my ($self, $s) = @_;

	if (is_block($s)) {
		my ($type, $a) = @{$self->{strmap}->{$s}};
		if (scalar @$a == 0) {
			return 1;
		}
	}
	return 0;
}

# flatten block (and remove #null statements)
#
sub flatten_block {
	my ($self, $s, $out) = @_;

	if (is_block($s)) {
		my ($type, $a) = @{$self->{strmap}{$s}};
		foreach my $stmt (@$a) {
			$self->flatten_block($stmt, $out);
		}
	} else {
		if ($s ne '#null') {
			push(@$out, $s); 
		}
	}
	return;
}

# flatten block with single statement
#
sub flatten_block_if_single {
	my ($self, $s) = @_;

	if (is_block($s)) {
		my ($type, $a) = @{$self->{strmap}{$s}};
		if (scalar @$a == 1) {
			return $a->[0];
		}
	}
	return $s;
}

# create and split global var
#
sub global_var {
	my ($global) = @_;
	return '$GLOBALS' . $global;
}

sub global_split {
	my ($var) = @_;
	my ($global) = $var =~ /^\$GLOBALS(\$.*)$/;
	return $global;
}

# create and split method name
#
sub method_name {
	my ($class, $name) = @_;
	return $class . '::' . $name;
}

sub method_split {
	my ($method) = @_;
	# allow namespace prefix
	my ($class, $name) = $method =~ /^(#inst\d+|[\w\x80-\xff\\]+)::([\w\x80-\xff]+)$/;
	return ($class, $name);
}

# create and split instance var
#
sub inst_var {
	my ($inst, $var) = @_;
	return '$' . $inst . $var;
}

sub inst_split {
	my ($instvar) = @_;
	my ($inst, $var) = $instvar =~ /^\$(#inst\d+|[\w\x80-\xff]+)(\$.*)$/;
	return ($inst, $var);
}

# create and split namespace name
#
sub ns_name {
	my ($name, $elem) = @_;
	return $name . '\\' . $elem;
}

sub ns_split {
	my ($name) = @_;
	my ($ns, $elem) = $name =~ /^([^\\]*)\\(.+)$/;
	return ($ns, $elem);
}

# create path from namespace
#
sub ns_to_str {
	my ($self, $var) = @_;

	if ($var =~ /^#ns\d+$/) {
		my ($n, $e) = @{$self->{strmap}{$var}};

		unless (defined $n) {
			$n = ''; # toplevel
		}
		$e = $self->ns_to_str($e);
		if (defined $e) {
			return ns_name($n, $e);
		}
	} elsif (is_strval($var)) {
		return $self->{strmap}{$var};
	} else {
		return $var;
	}
	return;
}

# create variable from variable variable
# $$var -> $val
# ${$var} -> $val
#
sub varvar_to_var {
	my ($self, $var) = @_;

	if (is_strval($var)) {
		my $str = $self->{strmap}{$var};

		# variable names are only handled up to first '$'.
		# also 'null' is allowed (represented as '' or ${null})
		#
		my ($suffix) = $str =~ /^(\$$|[^\$]*)/;
		return '$' . $suffix;
	}
	return;
}

# $GLOBALS['str'] -> $str
#
sub globalvar_to_var {
	my ($self, $base, $idx) = @_;

	if ($base =~ /^\$GLOBALS$/) {
		my $idxval = $self->get_strval($idx);
		if (defined $idxval) {
			# variable names are only handled up to first '$'.
			# also 'null' is allowed (represented as '' or ${null})
			#
			my ($suffix) = $idxval =~ /^(\$$|[^\$]*)/;
			return '$' . $suffix;
		}
	}
	return;
}

# return base var of multi dimensional elem
#
sub elem_base {
	my ($self, $s) = @_;

	while ($s =~ /^#elem\d+$/) {
		my ($v, $i) = @{$self->{strmap}->{$s}};

		if (defined $i) {
			# add resolvable globals
			#
			my $g = $self->globalvar_to_var($v, $i);
			if (defined $g) {
				$g = global_var($g);
				return $g;
			}
		}
		$s = $v;
	}
	return $s;
}

sub getline {
	my ($self) = @_;

	#$self->{log}->('getline', "%d", $self->{strmap}->{'__LINE__'}) if $self->{log};
	return $self->{strmap}->{'__LINE__'};
}

sub updateline {
	my ($self, $var) = @_;

	#$self->{log}->('updateline', "test $var") if $self->{log};

	# update line number based on preceeding string
	#
	if (exists $self->{strmap}->{'__LINEMAP__'}{$var}) {
		my $val = $self->{strmap}->{'__LINEMAP__'}{$var};
		if ($self->{strmap}->{'__LINE__'} < $val) {
			$self->{log}->('updateline', "[$var] %d -> %d", $self->{strmap}->{'__LINE__'}, $val) if $self->{log};
			$self->{strmap}->{'__LINE__'} = $val;
		}
	}
	return;
}

sub trim_list {
	my ($list) = @_;

	while ((scalar @$list > 0) && ($list->[0] =~ /^\s+$/)) {
		shift @$list;
	}
	while ((scalar @$list > 0) && ($list->[-1] =~ /^\s+$/)) {
		pop @$list;
	}
}

sub unspace_list {
	my ($list) = @_;
	# remove empty fields
	my @filtered = grep { $_ !~ /^\s+$/ } @$list;

	# remove comments
	@filtered = grep { $_ !~ /^\/\*.*\*\/$/ } @filtered;

	return \@filtered;
}

sub unquote_names {
	my ($str) = @_;

	# todo: is this really needed?
	if (1) {
		# \xXX
		$str =~ s/\\x([0-9a-fA-F]{2})/chr(hex($1))/ge;
	}
	return $str;
}

sub dump_line {
	my ($self, $prefix, $tok) = @_;

	for (my $i=0; $i < scalar @$tok; $i++) {
		my $word = $tok->[$i];

		if ($word =~ /^#/) {
			my $s = $self->shortstr($self->{strmap}->{$word}, 100);
			print "$prefix> $word [$s]\n";
		} else {
			my $t = unquote_names($word);
			print "$prefix> $t [$word]\n";
		}
	}
	my $q = join('', @$tok);
	print "$prefix> SHORTQ: $q\n";
	return;
}

sub read_array {
	my ($self, $tok, $close, $arr) = @_;

	while (1) {
		if (scalar @$tok == 0) {
			last;
		}
		if ($tok->[0] eq $close) {
			shift @$tok;
			last;
		}
		my $val = $self->read_statement($tok, undef);
		if (!defined $val || ($val eq $close)) {
			last;
		}
		if ($val eq ',') {
			$arr->set(undef, undef);
			next; # allow empty fields for list()
		}
		if (scalar @$tok > 0) {
			if ($tok->[0] eq $close) {
				shift @$tok;
				$arr->set(undef, $val);
				last;
			} elsif ($tok->[0] eq ',') {
				shift @$tok;
				$arr->set(undef, $val);
				next;
			} elsif ($tok->[0] eq '=>') {
				shift @$tok;
				my $key = $val;
				if ($key =~ /^#expr\d+$/) {
					my ($op, $v1, $v2) = @{$self->{strmap}->{$key}};
					if (($op eq '-') && !defined $v1) {
						my $str = $self->get_strval($v2);
						if (defined $str && is_int_index($str)) {
							$key = -$str;
						}
					}
				} elsif (is_null($key)) {
					$key = $self->setstr(''); # null maps to '' array index
				}
				$val = $self->read_statement($tok, undef);
				if (!defined $val || ($val eq $close)) {
					$arr->set($key, undef);
					last;
				}
				$arr->set($key, $val);
				if (scalar @$tok > 0) {
					if ($tok->[0] eq $close) {
						shift @$tok;
						last;
					} elsif ($tok->[0] eq ',') {
						shift @$tok;
						next;
					}
				} else {
					last;
				}
			}
		}
	}
	return;
}

# last_op is optional param
#
sub _read_statement {
	my ($self, $tok, $last_op) = @_;

	if ((scalar @$tok > 0) && ($tok->[0] =~ /^([\;\:\,\)\]\}]|else|endif|endwhile|endfor|endforeach|as|=>|catch|finally)$/i)) {
		my $sym = shift @$tok;
		return $sym;
	} elsif ((scalar @$tok > 0) && ($tok->[0] =~ /^null$/i)) {
		shift @$tok;
		unshift(@$tok, '#null');
		my $res = $self->read_statement($tok, $last_op);
		return $res;
	} elsif ((scalar @$tok > 1) && ($tok->[0] eq '{')) {
		# block expression { statement1; statement2; ... }
		# also allow empty { } block
		#
		shift @$tok;
		my $arglist = $self->read_code_block($tok, '}', ';');
		my $k = $self->setblk('std', $arglist);
		return $k;
	} elsif ((scalar @$tok > 1) && ($tok->[0] eq '(')) {
		# brace expression ( expr | call ) => result
		# also: allow empty ( ) block
		# also: type casting (int|bool|float|array|object|unset)
		#       http://php.net/manual/en/language.types.type-juggling.php
		#
		shift @$tok;
		my $arglist = $self->read_block($tok, ')', undef);

		if (scalar @$arglist > 0) {
		    if (scalar @$arglist == 1) {
			my $ref = $arglist->[0];
			my $str = $self->get_strval_or_str($ref);
			#$self->{log}->('parse', "braces: $ref, $str") if $self->{log};
			if (is_strval($ref) && ($str =~ /^(int|bool|float|string|array|object|unset)$/)) {
				# type casting
				# https://www.php.net/manual/en/language.types.type-juggling.php
				# https://www.php.net/manual/en/function.settype.php
				#
				my $res = $self->read_statement($tok, $last_op);
				my $k;
				if ($str eq 'int') {
					$k = $self->setcall('intval', [$res]);
				} elsif ($str eq 'integer') {
					$k = $self->setcall('intval', [$res]);
				} elsif ($str eq 'string') {
					$k = $self->setcall('strval', [$res]);
				} elsif ($str eq 'binary') {
					$k = $self->setcall('strval', [$res]);
				} elsif ($str eq 'float') {
					$k = $self->setcall('floatval', [$res]);
				} elsif ($str eq 'double') {
					$k = $self->setcall('floatval', [$res]);
				} elsif ($str eq 'real') { # removed in php8
					$k = $self->setcall('floatval', [$res]);
				} elsif ($str eq 'bool') {
					$k = $self->setcall('boolval', [$res]);
				} elsif ($str eq 'boolean') {
					$k = $self->setcall('boolval', [$res]);
				} elsif ($str eq 'array') {
					$k = $self->setcall('array', [$res]);
				} elsif ($str eq 'object') {
					$k = $self->setcall('object', [$res]);
				} elsif ($str eq 'unset') { # removed in php8
					my $t = $self->setstr('null');
					$k = $self->setcall('settype', [$res, $t]);
				} else {
					$k = $self->setcall('settype', [$res, $ref]);
				}
				unshift(@$tok, $k);
				$res = $self->read_statement($tok, $last_op);
				return $res;
			}
			if (is_strval($ref) || ($ref =~ /^#expr\d+$/) || ($ref =~ /^#call\d+$/) || ($ref =~ /^#inst\d+$/)) {
				unshift(@$tok, $ref);
				my $res = $self->read_statement($tok, $last_op);
				return $res;
			}
		    }
		    my $res = $self->setblk('brace', $arglist);

		    # - anonymous functions might be called directly -> '(function () { return 1; })()'
		    # - also subexpressions might use braces -> '$x = ($y) ? 1 : 2'
		    #
		    unshift(@$tok, $res);
		    $res = $self->read_statement($tok, $last_op);
		    return $res;
		}
		my $res = $self->setblk('brace', []);
		return $res;
	} elsif ((scalar @$tok > 1) && ($tok->[0] eq '[')) {
		# $array = ['a','b','c']
		#
		shift @$tok;

		my $arr = $self->newarr();
		$self->read_array($tok, ']', $arr);

		#my $arglist = $self->read_block($tok, ']', ',');
		#foreach my $val (@$arglist) {
		#	$arr->set(undef, $val);
		#}
		unshift(@$tok, $arr->{name});
		my $res = $self->read_statement($tok, $last_op);
		return $res;
	} elsif ((scalar @$tok > 1) && ($tok->[0] eq '&')) {
		# variable reference
		# & $var
		#
		shift @$tok;

		my $var = $self->read_statement($tok, undef);
		my $k = $self->setref($var);
		return $k;
	} elsif (((scalar @$tok == 1)
		|| ((scalar @$tok > 1) && ($tok->[1] =~ /^([\;\,\)\]\}]|as|=>)$/))
		|| ((scalar @$tok > 2) && ($tok->[1] eq ':') && ($tok->[2] ne ':'))) && !exists $php_keywords{$tok->[0]}) {
		# variable dereference
		# #str/#num/#const
		# constant
		# __FILE__
		# __LINE__
		#
		my $sym = shift @$tok;
		my $var = unquote_names($sym);

		if (is_strict_variable($var) || ($var =~ /^#/)) {
			if ($var =~ /^#str/) {
				$self->updateline($var);
			}
			return $var;
		} elsif ($var =~ /^__FILE__$/) {
			my $v = $self->{filename};
			my $k = $self->setstr($v);
			$self->{log}->('parse', "getfile: $k -> $v") if $self->{log};
			return $k;
		} elsif ($var =~ /^__LINE__$/) {
			my $k = $self->setnum($self->getline());
			$self->{log}->('parse', "getline: $k -> %d", $self->{strmap}->{$k}) if $self->{log};
			return $k;
		} elsif ($var =~ /^false$/i) {
			return $self->setnum(0);
		} elsif ($var =~ /^true$/i) {
			return $self->setnum(1);
		} elsif (is_symbol($var)) {
			# constants are always global
			# (undefined constants are propagated to string in exec)
			# 
			my $k = $self->setconst($var);
			if ((scalar @$tok > 1) && ($tok->[0] eq ':') && ($tok->[1] ne ':') && !defined $last_op) {
				shift @$tok;
				$k = $self->setstmt(['label', $k]); # goto label
			}
			return $k;
		}
		return $var;
	} elsif ((scalar @$tok > 1) && ($tok->[0] eq '<') && ($tok->[1] eq '?')) {
		if ((scalar @$tok > 2) && ($tok->[2] eq 'php')) {
			shift @$tok;
			shift @$tok;
			shift @$tok;
			return '<?php';
		} else {
			shift @$tok;
			shift @$tok;
			return '<?';
		}
	} elsif ((scalar @$tok > 5) && ($tok->[0] eq '<') && ($tok->[1] eq 'script') && ($tok->[2] eq 'type') && ($tok->[3] eq '=') && ($tok->[5] eq '>')) {
		# filter out bad javascript tags in scripts with no proper end-tag
		# (this avoids misinterpretations of javascript while(1)-loops)
		#
		my @list = ();
		push(@list, shift @$tok);
		push(@list, shift @$tok);
		push(@list, shift @$tok);
		push(@list, shift @$tok);
		push(@list, shift @$tok); # type
		push(@list, shift @$tok);

		while (scalar @$tok > 0) {
			if ((scalar @$tok > 3) && ($tok->[0] eq '<') && ($tok->[1] eq '/') && ($tok->[2] eq 'script') && ($tok->[3] eq '>')) {
				push(@list, shift @$tok);
				push(@list, shift @$tok);
				push(@list, shift @$tok);
				push(@list, shift @$tok);
				last;
			}
			my $sym = shift @$tok;
			push(@list, $sym);
		}
		my $script = join(' ', @list);
		my $s = $self->setstr($script);
		my $k = $self->setstmt(['echo', [$s]]);
		$self->{log}->('parse', "javascript string: %s", $script) if $self->{log};
		return $k;
	} elsif ((scalar @$tok > 1) && ($tok->[0] eq '?') && ($tok->[1] eq '>')) {
		shift @$tok;
		shift @$tok;
		return '?>';
	} elsif ((scalar @$tok > 1) && (lc($tok->[0]) eq 'echo')) {
		shift @$tok;
		my $all_str = 1;
		my @args = ();
		while (1) {
			my $arg = $self->read_statement($tok, undef);

			unless (is_strval($arg)) {
				$all_str = 0;
			}
			if ($arg ne ',') {
				push(@args, $arg);
			}
			unless ((scalar @$tok > 0) && ($tok->[0] eq ',')) {
				last;
			}	
			shift @$tok;
		}
		my $k = $self->setstmt(['echo', \@args]);

		# execute expr & might continue with operation
		#
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 1) && (lc($tok->[0]) eq 'print')) {
		shift @$tok;
		my $arg = $self->read_statement($tok, undef);
		my $k = $self->setstmt(['print', $arg]);

		# execute expr & might continue with operation
		#
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 1) && (lc($tok->[0]) eq 'namespace')) {
		shift @$tok;

		my $arg = ''; # toplevel
		if ($tok->[0] ne '{') {
			$arg = $self->read_statement($tok, undef);
			my $str = $self->ns_to_str($arg);
			if (defined $str) {
				$arg = $str;
			} else {
				$self->{warn}->('parse', "bad namespace: %s", $arg);
			}
		}
		my $block;
		if ((scalar @$tok > 0) && ($tok->[0] eq '{')) {
			shift @$tok;
			my $arglist = $self->read_code_block($tok, '}', ';');
			$block = $self->setblk('std', $arglist);
		}
		return $self->setstmt(['namespace', $arg, $block]);
	} elsif ((scalar @$tok > 1) && (lc($tok->[0]) eq 'use')) {
		shift @$tok;
		# https://php.net/manual/en/language.oop5.traits.php
		my @args = ();
		while (1) {
			my $arg = $self->read_statement($tok, undef);

			push(@args, $arg);
			unless ((scalar @$tok > 0) && ($tok->[0] eq ',')) {
				last;
			}
			shift @$tok;
		}
		return $self->setstmt(['use', \@args]);
	} elsif ((scalar @$tok > 1) && ($tok->[0] =~ /^(include|include_once|require|require_once)$/i)) {
		my $type = lc(shift @$tok);
		my $arg = $self->read_statement($tok, undef);
		return $self->setstmt([$type, $arg]);
	} elsif ((scalar @$tok > 1) && (lc($tok->[0]) eq 'global')) {
		shift @$tok;
		my @args = ();
		while (1) {
			my $arg = $self->read_statement($tok, undef);

			push(@args, $arg);
			unless ((scalar @$tok > 0) && ($tok->[0] eq ',')) {
				last;
			}	
			shift @$tok;
		}
		return $self->setstmt(['global', \@args]);
	} elsif ((scalar @$tok > 1) && (lc($tok->[0]) eq 'return')) {
		shift @$tok;
		my $res = $self->read_statement($tok, undef);
		# remove trailing ';' if evaluated as string
		#
		if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
			shift @$tok;
		}
		return $self->setstmt(['return', $res]);
	} elsif ((scalar @$tok > 1) && (lc($tok->[0]) eq 'goto')) {
		shift @$tok;
		my $res = $self->read_statement($tok, undef);
		# remove trailing ';' if evaluated as string
		#
		if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
			shift @$tok;
		}
		return $self->setstmt(['goto', $res]);
	} elsif ((scalar @$tok > 1) && (lc($tok->[0]) eq 'throw')) {
		shift @$tok;
		my $arg = $self->read_statement($tok, undef);
		return $self->setstmt(['throw', $arg]);
	} elsif ((scalar @$tok > 0) && (lc($tok->[0]) eq 'break')) {
		shift @$tok;
		my $res = $self->read_statement($tok, undef); # optional level
		if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
			shift @$tok;
		}
		return $self->setstmt(['break', $res]);
	} elsif ((scalar @$tok > 0) && (lc($tok->[0]) eq 'continue')) {
		shift @$tok;
		my $res = $self->read_statement($tok, undef); # optional level
		if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
			shift @$tok;
		}
		return $self->setstmt(['continue', $res]);
	} elsif ((scalar @$tok > 0) && (lc($tok->[0]) =~ /^(var|static|public|protected|private|final|const)$/)) {
		my $type = shift @$tok;
		my $pfx = {$type => 1};

		if ((scalar @$tok > 0) && (lc($tok->[0]) =~ /^(var|static|public|protected|private|final|const)$/)) {
			$type = shift @$tok;
			$pfx->{$type} = 1;
		}
		my $k = $self->setpfx($pfx);
		unshift(@$tok, $k);
		return $self->read_statement($tok);
	} elsif ((scalar @$tok > 0) && (lc($tok->[0]) eq '__halt_compiler')) {
		my $k = shift @$tok;
		@$tok = ();
		return $k;
	} elsif ((scalar @$tok > 3) && (lc($tok->[0]) eq 'if') && ($tok->[1] eq '(')) {
		shift @$tok;
		shift @$tok;
		my $expr = $self->read_block($tok, ')', undef);
		my $then;
		my $else;

		if ((scalar @$tok > 0) && ($tok->[0] eq ':')) {
			# allow alternative block syntax
			# http://php.net/manual/en/control-structures.alternative-syntax.php
			#
			shift @$tok;
			my $block = $self->read_code_block($tok, 'endif', ';');
			$then = $self->setblk('std', $block);
		} else {
			$then = $self->read_statement($tok);
			if (!is_block($then)) {
				if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
					shift @$tok;
				}
				# always put '{ .. }' braces around if/else
				$then = $self->setblk('std', [$then]);
			}
		}
		if ((scalar @$tok > 0) && (lc($tok->[0]) eq 'else')) {
			shift @$tok;
			if ((scalar @$tok > 0) && ($tok->[0] eq ':')) {
				# allow alternative block syntax
				# http://php.net/manual/en/control-structures.alternative-syntax.php
				#
				shift @$tok;
				my $block = $self->read_code_block($tok, 'endif', ';');
				$else = $self->setblk('std', $block);
			} else {
				$else = $self->read_statement($tok);
				if (!is_block($else)) {
					if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
						shift @$tok;
					}
					$else = $self->setblk('std', [$else]);
				}
			}
		} elsif ((scalar @$tok > 0) && (lc($tok->[0]) eq 'elseif')) {
			shift @$tok;
			unshift(@$tok, 'if');
			$else = $self->read_statement($tok, undef);
			if (!is_block($else)) {
				$else = $self->setblk('std', [$else]);
			}
		}
		if (scalar @$expr > 1) {
			$self->{warn}->('parse', "if: bad cond %s", join(' ', @$expr));
			my $badcond = $self->setblk('expr', $expr);
			$expr = [$badcond];
		}
		return $self->setstmt(['if', $expr->[0], $then, $else]);
	} elsif ((scalar @$tok > 3) && (lc($tok->[0]) eq 'switch') && ($tok->[1] eq '(')) {
		shift @$tok;
		shift @$tok;
		my $expr = $self->read_block($tok, ')', undef);
		my $block = [];
		if ((scalar @$tok > 0) && ($tok->[0] eq ':')) {
			# allow alternative block syntax
			# http://php.net/manual/en/control-structures.alternative-syntax.php
			#
			shift @$tok;
			$block = $self->read_code_block($tok, 'endswitch', ';');
		} elsif ((scalar @$tok > 0) && ($tok->[0] eq '{')) {
			shift @$tok;
			$block = $self->read_code_block($tok, '}', ';');
		} else {
			$self->{warn}->('parse', "expected switch block {}");
		}
		if (scalar @$expr > 1) {
			$self->{warn}->('parse', "switch: bad cond %s", join(' ', @$expr));
			my $badcond = $self->setblk('expr', $expr);
			$expr = [$badcond];
		}
		my @cases = ();
		my $inst;
		foreach my $e (@$block) {
			if ($e =~ /^#stmt\d+$/ && (lc($self->{strmap}->{$e}->[0]) eq 'case')) {
				my $c = $self->{strmap}->{$e}->[1]; # undef for default case
				$inst = [];
				my $b = $self->setblk('case', $inst); # block content added in next iterations
				push (@cases, [$c, $b]);
			} else {
				if (!defined $inst) {
					$self->{warn}->('parse', "switch: inst w/o case: %s", $e);
					$inst = [];
				}
				push (@$inst, $e);
			}
		}
		return $self->setstmt(['switch', $expr->[0], \@cases]);
	} elsif ((scalar @$tok > 2) && (lc($tok->[0]) eq 'case')) {
		shift @$tok;
		my $expr = $self->read_statement($tok, undef);
		# 'case' might also be terminated by ';'
		#
		if ((scalar @$tok > 0) && ($tok->[0] eq ':') || ($tok->[0] eq ';')) {
			shift @$tok;
		}
		if ($expr =~ /^#stmt\d+$/ && (lc($self->{strmap}->{$expr}->[0]) eq 'label')) {
			$expr = $self->{strmap}->{$expr}->[1]; # label -> const
		}
		return $self->setstmt(['case', $expr]);
	} elsif ((scalar @$tok > 1) && (lc($tok->[0]) eq 'default')) {
		shift @$tok;
		# 'case' might also be terminated by ';'
		#
		if ((scalar @$tok > 0) && ($tok->[0] eq ':') || ($tok->[0] eq ';')) {
			shift @$tok;
		}
		return $self->setstmt(['case', undef]);
	} elsif ((scalar @$tok > 3) && (lc($tok->[0]) eq 'try') && ($tok->[1] eq '{')) {
		shift @$tok;
		my $try;
		my $finally;

		# https://www.php.net/manual/en/language.exceptions.php
		#
		$try = $self->read_statement($tok);
		if (!is_block($try)) {
			if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
				shift @$tok;
			}
			# always put '{ .. }' braces around try
			$try = $self->setblk('std', [$try]);
		}
		my @catches = ();
		while ((scalar @$tok > 1) && (lc($tok->[0]) eq 'catch') && ($tok->[1] eq '(')) {
			shift @$tok;
			shift @$tok;
			my $exception = $self->read_block($tok, ')', undef);
			my $block= $self->read_statement($tok);

			if (!is_block($block)) {
				if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
					shift @$tok;
				}
				# always put '{ .. }' braces around catch
				$block = $self->setblk('std', [$block]);
			}
			push (@catches, [$exception->[0], $block]);
		}
		if ((scalar @$tok > 0) && (lc($tok->[0]) eq 'finally')) {
			shift @$tok;
			$finally= $self->read_statement($tok);

			if (!is_block($finally)) {
				if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
					shift @$tok;
				}
				# always put '{ .. }' braces around finally
				$finally = $self->setblk('std', [$finally]);
			}
		}
		return $self->setstmt(['try', $try, \@catches, $finally]);
	} elsif ((scalar @$tok > 3) && (lc($tok->[0]) eq 'for') && ($tok->[1] eq '(')) {
		# note: just for-loops can take ',' operators in pre- and post-cond.
		#       All 3 expressions can be empty;
		#       http://php.net/manual/en/control-structures.for.php
		#
		shift @$tok;
		shift @$tok;
		my $expr1 = $self->read_code_block($tok, ';', ',');
		my $expr2 = $self->read_code_block($tok, ';', ',');
		my $expr3 = $self->read_code_block($tok, ')', ',');
		my $block;
		if ((scalar @$tok > 0) && ($tok->[0] eq ':')) {
			# allow alternative block syntax
			# http://php.net/manual/en/control-structures.alternative-syntax.php
			#
			shift @$tok;
			$block = $self->read_code_block($tok, 'endfor', ';');
			$block = $self->setblk('std', $block);
		} else {
			$block = $self->read_statement($tok);
			if (!is_block($block)) {
				if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
					shift @$tok;
				}
				# always put '{ .. }' braces around if/else
				$block = $self->setblk('std', [$block]);
			}
		}
		my $pre = $self->setblk('expr', $expr1);
		my $cond = $self->setblk('expr', $expr2);
		my $post = $self->setblk('expr', $expr3);
		return $self->setstmt(['for', $pre, $cond, $post, $block]);
	} elsif ((scalar @$tok > 3) && (lc($tok->[0]) eq 'while') && ($tok->[1] eq '(')) {
		shift @$tok;
		shift @$tok;
		my $expr = $self->read_block($tok, ')', ',');
		my $block;
		if ((scalar @$tok > 0) && ($tok->[0] eq ':')) {
			# allow alternative block syntax
			# http://php.net/manual/en/control-structures.alternative-syntax.php
			#
			shift @$tok;
			$block = $self->read_code_block($tok, 'endwhile', ';');
			$block = $self->setblk('std', $block);
		} else {
			$block = $self->read_statement($tok);
			if (!is_block($block)) {
				if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
					shift @$tok;
				}
				# always put '{ .. }' braces around if/else
				$block = $self->setblk('std', [$block]);
			}
		}
		if (scalar @$expr > 1) {
			$self->{warn}->('parse', "while: bad cond %s", join(' ', @$expr));
			my $badcond = $self->setblk('expr', $expr);
			$expr = [$badcond];
		}
		return $self->setstmt(['while', $expr->[0], $block]);
	} elsif ((scalar @$tok > 3) && (lc($tok->[0]) eq 'do') && ($tok->[1] eq '{')) {
		shift @$tok;
		my $block;
		my $expr;

		$block = $self->read_statement($tok);
		if (!is_block($block)) {
			if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
				shift @$tok;
			}
			# always put '{ .. }' braces around do-while block
			$block = $self->setblk('std', [$block]);
		}
		if ((scalar @$tok > 3) && (lc($tok->[0]) eq 'while') && ($tok->[1] eq '(')) {
			shift @$tok;
			shift @$tok;
			$expr = $self->read_block($tok, ')', ',');

			if (scalar @$expr > 1) {
				$self->{warn}->('parse', "do-while: bad cond %s", join(' ', @$expr));
				my $badcond = $self->setblk('expr', $expr);
				$expr = [$badcond];
			}
		} else {
			$self->{warn}->('parse', "do-while: miss while");
			my $badcond = $self->setblk('expr', undef);
			$expr = [$badcond];
		}
		return $self->setstmt(['do', $expr->[0], $block]);
	} elsif ((scalar @$tok > 3) && (lc($tok->[0]) eq 'foreach') && ($tok->[1] eq '(')) {
		shift @$tok;
		shift @$tok;
		my $expr = $self->read_block($tok, ')', ',');
		my $key;
		my $value;

		if ((scalar @$expr == 3) && (lc($expr->[1]) eq 'as')) {
			$value = $expr->[2];
		} elsif ((scalar @$expr == 5) && (lc($expr->[1]) eq 'as') && ($expr->[3] eq '=>')) {
			$key = $expr->[2];
			$value = $expr->[4];
		} else {
			$self->{warn}->('parse', "foreach: bad expr %s", join(' ', @$expr));
			my $badcond = $self->setblk('expr', $expr);
			$expr = [$badcond];
		}
		my $block;
		if ((scalar @$tok > 0) && ($tok->[0] eq ':')) {
			# allow alternative block syntax
			# http://php.net/manual/en/control-structures.alternative-syntax.php
			#
			shift @$tok;
			$block = $self->read_code_block($tok, 'endforeach', ';');
			$block = $self->setblk('std', $block);
		} else {
			$block = $self->read_statement($tok);
			if (!is_block($block)) {
				if ((scalar @$tok > 0) && ($tok->[0] eq ';')) {
					shift @$tok;
				}
				# always put '{ .. }' braces around if/else
				$block = $self->setblk('std', [$block]);
			}
		}
		return $self->setstmt(['foreach', $expr->[0], $key, $value, $block]);
	} elsif ((scalar @$tok > 2) && ($tok->[0] =~ /^array$/i) && ($tok->[1] eq '(')) {
		shift @$tok;
		shift @$tok;

		my $arr = $self->newarr();
		$self->read_array($tok, ')', $arr);

		# execute expr & might continue with operation -> 'array(...)[idx]'?
		#
		unshift(@$tok, $arr->{name});
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 4) && ((lc($tok->[0]) eq 'function') || (($tok->[0] =~ /^#pfx\d+$/) && (lc($tok->[1]) eq 'function')))) {
		my $pfx = shift @$tok;
		my $p = {};

		if ($pfx =~ /^#pfx\d+$/) {
			$p = $self->{strmap}->{$pfx};
			shift @$tok;
		}
		my $cmd;

		# also allow anonymous funcs: http://php.net/manual/en/functions.anonymous.php
		#
		if ($tok->[0] ne '(') {
			my $sym = shift @$tok;
			$cmd = $self->read_statement([$sym], undef);
			if (is_strval($cmd)) {
				$cmd = $self->{strmap}{$cmd};
			}
		}
		my $arglist = [];
		if ((scalar @$tok > 0) && ($tok->[0] eq '(')) {
			shift @$tok;
			$arglist = $self->read_block($tok, ')', ',');
		} else {
			$self->{warn}->('parse', "expected function arglist ()");
		}
		my $block = [];
		if ((scalar @$tok > 0) && ($tok->[0] eq '{')) {
			shift @$tok;
			$block = $self->read_code_block($tok, '}', ';');
		} else {
			$self->{warn}->('parse', "expected function block {}");
		}
		$block = $self->setblk('std', $block);

		# function are registered later via registerfun
		#
		my $k = $self->setfun($cmd, $arglist, $block, $p);

		unless (defined $cmd) {
			# anonymous functions might be called directly -> 'function () { return 1; }()'
			#
			unshift(@$tok, $k);
			$k = $self->read_statement($tok, $last_op);
		}
		return $k;
	} elsif ((scalar @$tok > 3) && ((lc($tok->[0]) eq 'class') || (($tok->[0] =~ /^#pfx\d+$/) && (lc($tok->[1]) eq 'class')))) {
		my $pfx = shift @$tok;
		my $p = {};

		if ($pfx =~ /^#pfx\d+$/) {
			$p = $self->{strmap}->{$pfx};
			shift @$tok;
		}
		my $name = shift @$tok;

		# http://php.net/manual/en/language.oop5.basic.php
		#
		if ($tok->[0] eq 'extends') {
			shift @$tok;
			$p->{parent} = shift @$tok;
		}
		my $block = [];
		if ((scalar @$tok > 0) && ($tok->[0] eq '{')) {
			shift @$tok;
			$block = $self->read_block($tok, '}', ';');
		}
		$block = $self->setblk('std', $block);
		return $self->setclass($name, $block, $p);
	} elsif ((scalar @$tok > 3) && (lc($tok->[0]) eq 'trait')) {
		shift @$tok;
		my $name = shift @$tok;

		# https://www.php.net/manual/en/language.oop5.traits.php
		#
		my $block = [];
		if ((scalar @$tok > 0) && ($tok->[0] eq '{')) {
			shift @$tok;
			$block = $self->read_block($tok, '}', ';');
		}
		$block = $self->setblk('std', $block);
		return $self->settrait($name, $block);
	} elsif ((scalar @$tok > 1) && ($tok->[0] =~ /^#pfx\d+$/)) {
		my $sym = shift @$tok;

		# TODO: support const and other visibility modifiers
		# https://www.php.net/manual/en/language.oop5.visibility.php
		#
		if (exists $self->{strmap}->{$sym}) {
			my $pfx = $self->{strmap}->{$sym};
			if (exists $pfx->{static}) {
				my @args = ();
				while (1) {
					my $arg = $self->read_statement($tok, undef);

					push(@args, $arg);
					unless ((scalar @$tok > 0) && ($tok->[0] eq ',')) {
						last;
					}
					shift @$tok;
				}
				return $self->setstmt(['static', \@args, $pfx]);
			}
			if (exists $pfx->{const}) {
				my @args = ();
				while (1) {
					my $arg = $self->read_statement($tok, undef);

					push(@args, $arg);
					unless ((scalar @$tok > 0) && ($tok->[0] eq ',')) {
						last;
					}
					shift @$tok;
				}
				return $self->setstmt(['const', \@args, $pfx]);
			}
		}
		return $sym;
	} elsif ((scalar @$tok > 2) && ($tok->[0] !~ /^([\~\!\+\-\\]|new)$/i) && ($tok->[1] eq '(')) {
		# function call
		# (function name might be variable)
		#
		my $sym = shift @$tok;
		my $cmd = $sym;

		unless (is_symbol($sym)) {
			$cmd = $self->read_statement([$sym], undef);
		}
		if (defined $last_op && ($last_op eq '$')) {
			# handle case: $$var(x) is ${$var}(x)
			return $cmd;
		}
		if (defined $last_op && ($last_op eq '::')) {
			# handle case: (class::member)(x)
			return $cmd;
		}
		if (defined $last_op && ($last_op eq '->')) {
			# handle case: ($obj->method)(x)
			return $cmd;
		}
		if (defined $last_op && ($last_op eq '\\')) {
			# handle case: (ns \\ cmd)(x)
			return $cmd;
		}
		if (is_strict_variable($sym)) {
			$cmd = $sym; # don't insert copy anonymous function here
		}
		shift @$tok;

		if (is_strval($cmd) && !is_null($cmd)) {
			$cmd = $self->{strmap}{$cmd};
		}
		if ($cmd =~ /^\@(.*)$/) {
			# remove optional '@' error suppress operator
			$cmd = $1;
		}
		# get arglist so that ref-params are not resolved to value
		# (need function definition to decide how to resolve variables)
		#
		my $arglist = $self->read_block($tok, ')', ',');
		my $k;
		if ($cmd eq 'unset') {
			$k = $self->setstmt(['unset', $arglist]);
		} elsif ($cmd eq 'list') {
			my $arr = $self->newarr();
			foreach my $val (@$arglist) {
				$arr->set(undef, $val);
			}
			$k = $arr->{name};
		} else {
			$k = $self->setcall($cmd, $arglist);
		}
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 1) && ($tok->[0] eq '$') && (is_symbol($tok->[1]))) {
		# variable reference via $ val => $val
		#
		shift @$tok;
		my $sym = shift @$tok;

		my $str = $self->get_strval_or_str($sym);
		my $var = '$' . $str;
		unshift(@$tok, $var);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 1) && ($tok->[0] eq '$') && ($tok->[1] =~ /^\$/)) {
		# variable variable via $ $var => $<string-in-var>
		# Attention:
		# - $$var[x] is ${$var[x]}
		# - $$var(x) is ${$var}(x)
		#
		shift @$tok;
		my $res = $self->read_statement($tok, '$');
		my $k = $self->setexpr('$', undef, $res);

		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	#} elsif ((scalar @$tok > 1) && ($tok->[0] eq '#') && ($tok->[1] =~ /^(str|num)\d+$/)) {
	#	# for re-eval: literal reference via # str/num => #str
	#	#
	#	shift @$tok;
	#	my $sym = shift @$tok;
	#
	#	my $var = '#' . $sym;
	#	unshift(@$tok, $var);
	#	return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 3) && ($tok->[0] eq '$') && ($tok->[1] eq '{')) {
		# variable variable via $ { string } => $string
		# variable variable via $ { func(xxx) } is also allowed
		#
		shift @$tok;
		shift @$tok;

		my $arglist = $self->read_block($tok, '}', undef);
		my $k;
		if (scalar @$arglist == 1) {
			my $res = $arglist->[0];
			if (is_strval($res)) {
				my $str = $self->{strmap}{$res};
				if (is_symbol($str)) {
					my $var = '$' . $str;
					unshift(@$tok, $var);
					return $self->read_statement($tok, $last_op);
				}
			}
			$k = $self->setexpr('$', undef, $res);
		} else {
			$self->{warn}->('parse', "bad arglist \$ { %s }", join(' ', @$arglist));
			my $res = $self->setblk('std', $arglist);
			$k = $self->setexpr('$', undef, $res);
		}
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 3) && (is_strict_variable($tok->[0]) || ($tok->[0] =~ /^#/)) && (($tok->[1] eq '[') || ($tok->[1] eq '{'))) {
		# array reference via $var['string']
		# or: variable $GLOBALS['string'] -> $string
		# or: $strvar[idx] -> char
		#
		# or: $var[string] -> string
		# (old: php autoconverts bare string into string const which
		#  contains the string - not always the same as the 'str' index
		#  see: http://php.net/manual/en/language.types.array.php
		#  see: define('const', 'val')
		# )
		#
		# http://php.net/manual/de/language.types.string.php
		# - Strings may also be accessed using braces, as in $str{42},
		#   for the same purpose. However, this syntax is deprecated as
		#   of php7.4 and disabled in php8. Use square brackets instead.
		#
		my $sym = shift @$tok;

		if (defined $last_op && ($last_op eq '::')) {
			# handle case: (class::$var)(x)
			return $sym;
		}
		if (defined $last_op && ($last_op eq '->')) {
			# handle case: ($obj->var)(x)
			return $sym;
		}
		my $bracket = shift @$tok;
		my $arglist;

		if ($bracket eq '[') {
			$arglist = $self->read_index_block($tok, ']', undef);
		} else {
			$arglist = $self->read_index_block($tok, '}', undef);
		}
		if (scalar @$arglist > 1) {
			$self->{warn}->('parse', "bad arglist %s [ %s ]", $sym, join(' ', @$arglist));
			unshift(@$tok, ('[', @$arglist, ']'));
			return $sym;
		}
		if ((scalar @$arglist == 1) && is_strval($arglist->[0])) {
			my $str = $arglist->[0];
if (0) {
			if ($sym =~ /^\$GLOBALS$/) {
				my $val = $self->get_strval($str);
				my $var = '$' . $val;
				unshift(@$tok, $var);
				my $res = $self->read_statement($tok, $last_op);
				return $res;
			}
}
		} elsif ((scalar @$arglist == 1) && (is_symbol($arglist->[0]))) {
			# bare string
			my $str = $arglist->[0];
			my $k = $self->setstr($str);
			unshift(@$tok, ($sym, '[', $k, ']'));
			my $res = $self->read_statement($tok, $last_op);
			return $res;
		}
		my $k = $self->setelem($sym, $arglist->[0]);

		# execute expr & might continue with lower prio operation
		#
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 2) && ($tok->[0] =~ /^(\+|\-)$/) && ($tok->[1] eq $tok->[0])) {
		# ++$var
		# --$var
		#
		my $op = shift @$tok;
		shift @$tok;

		my $var = $self->read_statement($tok, "$op$op");
		my $k = $self->setexpr($op.$op, undef, $var);

		# execute expr & might continue with lower prio operation
		#
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 3) && ($tok->[0] eq '.') && ($tok->[1] eq '.') && ($tok->[2] eq '.')) {
		# ...$var
		#
		shift @$tok;
		shift @$tok;
		shift @$tok;

		my $var = $self->read_statement($tok, '...');
		my $k = $self->setexpr('...', undef, $var);

		# execute expr & might continue with lower prio operation
		#
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 1) && ($tok->[0] =~ /^\\$/)) {
		# \val
		#
		my $op = shift @$tok;

		my $val = $self->read_statement($tok, $op);
		my $k = $self->setns(undef, $val); # toplevel namespace

		# execute expr & might continue with lower prio operation
		#
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 1) && ($tok->[0] =~ /^([\~\!\+\-]|new|exception)$/i)) {
		# ~val
		# !val
		# +val
		# -val
		# new val
		#
		my $op = shift @$tok;
		my $val;

		if (($op eq '+') || ($op eq '-')) {
			$val = $self->read_statement($tok, '+-');
		} elsif (lc($op) eq 'new') {
			# add optional parenthesis for 'new a' if necessary
			# -> with parenthesis $val is parsed as #call
			#
			$val = $self->read_statement($tok, $op);
			if ($val =~ /^#(str|const)/) {
				$val = $self->setcall($self->{strmap}->{$val}, []);
			}
		} else {
			$val = $self->read_statement($tok, $op);
		}
		my $k = $self->setexpr($op, undef, $val);

		# execute expr & might continue with lower prio operation
		#
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	} elsif ((scalar @$tok > 2) && ($tok->[1] =~ /^([\.\+\-\*\/\^\&\|\%<>\?\:]|=|\!|==|\!=|<>|<=|>=|<<|>>|===|\!==|<=>|\?\:|\?\?|\&\&|\|\||\+\+|\-\-|and|or|xor|instanceof|\->|::|\\)$/i)) {
		# val1 . val2
		# val1 + val2
		# val1 - val2
		# val1 ^ val2
		# ...
		#
		if (($tok->[1] =~ /^[<>\&\|\*\?]$/) && ($tok->[2] eq $tok->[1])) {
			# val1 << val2 (also: <<=)
			# val1 >> val2 (also: >>=)
			# val1 ** val2 (also: **=)
			# val1 ?? val2 (also: ??=)
			# val1 || val2
			# val1 && val2
			#
			my $sym = shift @$tok;
			my $op = shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, $op.$op));
			# fall through
		}
		if (($tok->[2] eq '=') && ($tok->[1] =~ /^([\.\+\-\*\/\^\&\|\%]|<<|>>|\*\*|\?\?)$/)) {
			# num += ...
			# num .= ...
			#
			my $sym = shift @$tok;
			my $op = shift @$tok;
			shift @$tok;

			# keep in_block flag for '='
			my $op2 = $self->read_statement($tok, undef);

			# keep precedence of $op against following expr
			my $k2 = $self->setexpr($op, $sym, $op2);
			unshift(@$tok, ($sym, '=', $k2));
			return $self->read_statement($tok, $last_op);
		}
		if (($tok->[1] eq '=') && ($tok->[2] eq '>')) {
			# $expr1 =>
			#
			my $sym = shift @$tok;
			shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, '=>'));

			return $self->read_statement($tok, $last_op);
		}
		if (($tok->[1] =~ /^(\+|\-)$/) && ($tok->[2] eq $tok->[1]) && (is_strict_variable($tok->[0]) || ($tok->[0] =~ /^#(scope|inst)\d+$/))) {
			# $var++
			# $var--
			#
			my $sym = shift @$tok;
			my $op = shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, $op.$op));
			# fall through
		} elsif ((scalar @$tok > 3) && ($tok->[1] =~ /^[=\!]$/) && ($tok->[2] eq '=') && ($tok->[3] eq '=')) {
			# val1 === val2
			# val1 !== val2
			#
			my $sym = shift @$tok;
			my $op = shift @$tok;
			shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, $op.'=='));
			# fall through
		} elsif ((scalar @$tok > 3) && ($tok->[1] eq '<') && ($tok->[2] eq '=') && ($tok->[3] eq '>')) {
			# val1 <=> val2
			#
			my $sym = shift @$tok;
			my $op = shift @$tok;
			shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, '<=>'));
			# fall through
		} elsif (($tok->[1] =~ /^[=\!<>]$/) && ($tok->[2] eq '=')) {
			# val1 == val2
			# val1 != val2
			# val1 <= val2
			# val1 >= val2
			#
			my $sym = shift @$tok;
			my $op = shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, $op.'='));
			# fall through
		} elsif (($tok->[1] eq '<') && ($tok->[2] eq '>')) {
			# val1 <> val2 (diamond operator work as !=)
			#
			my $sym = shift @$tok;
			my $op = shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, '!='));
			# fall through
		} elsif (($tok->[1] =~ /^[=\!]$/) && ($tok->[2] eq '==')) { # TODO: does this occur?
			# val1 === val2
			# val1 !== val2
			#
			my $sym = shift @$tok;
			my $op = shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, $op.'=='));
			# fall through
		} elsif (($tok->[1] eq '-') && ($tok->[2] eq '>')) {
			# $obj -> member
			#
			my $sym = shift @$tok;
			shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, '->')); # for operator precedence
			# fall through
		} elsif (($tok->[1] eq ':') && ($tok->[2] eq ':')) {
			# class :: elem
			#
			my $sym = shift @$tok;
			shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, '::'));
			# fall through
		} elsif (($tok->[1] eq '?') && ($tok->[2] eq ':')) {
			# ternary: $expr1 ?: $expr3
			#
			my $sym = shift @$tok;
			shift @$tok;
			shift @$tok;
			unshift(@$tok, ($sym, '?:'));
			# fall through
		}
		# remaining binary ops
		# variable assignment
		#
		my $sym = shift @$tok;
		my $op = shift @$tok;
		my $op1;
		$op = lc($op);

		if (($op eq '->') || ($op eq '::') || ($op eq '\\')) {
			$op1 = $sym; # don't evaluate lefthand side variable
		} else {
			$op1 = $self->read_statement([$sym], undef);
		}
		if (defined $last_op) {
			unless (exists $op_prio{$op}) {
				$self->{warn}->('parse', "missing op_prio(%s) [last %s]", $op, $last_op);
			}
			unless (exists $op_prio{$last_op}) {
				$self->{warn}->('parse', "op_prio(%s) [op %s]", $last_op, $op);
			}
			$self->{debug}->('parse', "SYM $sym OP %s LAST %s", $op, $last_op) if $self->{debug};
			if ($op_prio{$op} >= $op_prio{$last_op}) {
				# - for right associative ops like '=' continue to parse left-hand side.
				# - but for identical ops like '$a=$b=1' parse right-hand side first.
				# - there is a special case for unary op and '=' ('!$x=2' is same as '!($x=2)')
				#
				if (($op ne $last_op) || !exists $op_right{$op}) {
				    unless (($op eq '=') && (exists $op_unary{$last_op} || !exists $op_right{$last_op})) {
					$self->{log}->('parse', "curr %s %s has higher/equal prio than last %s", $op1, $op, $last_op) if $self->{log};
					unshift(@$tok, $op);
					return $op1;
				    }
				}
			}
		}
		my $k;
		if ($op eq '?') {
			# ternary: $op1 ? $expr2 : $expr3
			#
			my $expr2 = $self->read_statement($tok, $op);
			if ((scalar @$tok > 0) && $tok->[0] eq ':') {
				shift @$tok;
			} else {
				$self->{warn}->('parse', "ternary: missing : [%s ? %s]", $sym, $expr2);
			}
			my $expr3 = $self->read_statement($tok, ':');
			my $op2 = $self->setexpr(':', $expr2, $expr3);
			$k = $self->setexpr('?', $op1, $op2);
		} elsif ($op eq '->') {
			# $obj -> member
			#
			my $op2 = $self->read_statement($tok, $op);

			if (is_block($op2)) {
				# $obj -> {'member'}
				#
				my ($type, $a) = @{$self->{strmap}->{$op2}};
				if (scalar @$a == 1) {
					$op2 = $a->[0];
				}
			}
			$op2 = $self->get_strval_or_str($op2);

			$k = $self->setobj($op1, $op2);
		} elsif ($op eq '::') {
			# class :: member
			#
			my $class = $sym;
			unless (is_symbol($sym)) {
				$class = $self->read_statement([$sym], undef);
				$class = $self->get_strval_or_str($class);
			}
			my $elem = $self->read_statement($tok, $op);
			$elem = $self->get_strval_or_str($elem);

			$k = $self->setscope($class, $elem);
		} elsif ($op eq '\\') {
			# ns/elem
			#
			my $op2 = $self->read_statement($tok, $op);
			$op1 = $self->get_strval_or_str($op1);

			$k = $self->setns($op1, $op2);
		} elsif (($op eq '++') || ($op eq '--')) {
			# $var++
			# $var--
			#
			$k = $self->setexpr($op, $op1, undef);
		} else {
			if (1) {
				# optimize long concat chains to avoid memory exhaustion
				# (sometimes hundreds of strings get concatted)
				#
				if (($op eq '.') && is_strval($op1) && (scalar @$tok > 2) && is_strval($tok->[0]) && ($tok->[1] eq '.')) {
					my @list;
					push(@list, $op1);
					while ((scalar @$tok > 2) && is_strval($tok->[0]) && ($tok->[1] eq '.')) {
						my $s = shift @$tok;
						shift @$tok;
						push(@list, $s);
					}
					$self->{warn}->('parse', "optimize concat chain here: %s", join(' ', @list));
					my $line = join('', map { $self->{strmap}->{$_} } @list);
					$op1 = $self->setstr($line);
				}
			}
			my $op2 = $self->read_statement($tok, $op);
			$k = $self->setexpr($op, $op1, $op2);
		}
		# execute expr & might continue with lower prio operation
		#
		unshift(@$tok, $k);
		return $self->read_statement($tok, $last_op);
	}

	if (scalar @$tok > 0) {
		my $sym = shift @$tok;

		# some symbols are pushed back into token-stream and might be passed through here
		#
		$self->{log}->('parse', "skip symbol %s", $sym) if $self->{log};
		return $sym;
	}
	return;
}

# last_op & in_block are optional params
#
sub read_statement {
	my ($self, $tok, $last_op) = @_;
	my $level = 0;

	if (exists $self->{strmap}->{_LEVEL}) {
		$self->{strmap}->{_LEVEL} += 1;
	} else {
		$self->{strmap}->{_LEVEL} = 1;
	}
	$level = $self->{strmap}->{_LEVEL};

	# show next 10 tokens to process
	#
	my $tl = (scalar @$tok > 10) ? 10 : scalar @$tok;
	#$self->{log}->('PARSE', "[%d:%d] %s %s", $level, scalar @$tok, join(' ', @$tok[0..$tl-1]), (scalar @$tok > 10) ? '...' : '') if $self->{log};
	my $tab = ($level <= 1) ? '' : ('....' x ($level-2)) . '... ';
	$self->{log}->('PARSE', "$tab%s%s", join(' ', @$tok[0..$tl-1]), (scalar @$tok > 10) ? ' ..['.(scalar @$tok - 10).']' : '') if $self->{log};

	my $ret = $self->_read_statement($tok, $last_op);
	$self->{strmap}->{_LEVEL} -= 1;
	return $ret;
}

sub filter_bad_brace {
	my ($stmt) = @_;

	if ($stmt =~ /^[\)\]\}]$/) {
		$stmt = "<BAD_BRACE_$stmt>";
	}
	return $stmt;
}

sub read_index_block {
	my ($self, $tok, $close, $separator) = @_;
	my @out = ();

	$self->{debug}->('parse', "B+$close") if $self->{debug};

	while (scalar @$tok > 0) {
		# always resolve assignment in index to value
		#
		my $stmt = $self->read_statement($tok, undef);

		$self->{debug}->('parse', "B-$close $stmt") if $self->{debug};

		if ($stmt eq $close) {
			# block end
			#
			return \@out;
		} elsif (defined $separator && ($stmt eq $separator)) {
			#push(@out, $separator);
		} else {
			$stmt = filter_bad_brace($stmt);
			push(@out, $stmt);
		}
	}
	return \@out;
}

sub read_block {
	my ($self, $tok, $close, $separator) = @_;
	my @out = ();
	my $last;

	$self->{debug}->('parse', "B+$close") if $self->{debug};

	while (scalar @$tok > 0) {
		my $stmt = $self->read_statement($tok, undef);

		$self->{debug}->('parse', "B-$close $stmt") if $self->{debug};

		if ($stmt eq $close) {
			# block end
			#
			return \@out;
		} elsif (defined $separator && ($stmt eq $separator)) {
			if (defined $last && ($last eq $separator)) {
				push(@out, undef); # allow empty field
			}
			#push(@out, $separator);
		} else {
			$stmt = filter_bad_brace($stmt);
			push(@out, $stmt);
		}
		$last = $stmt;
	}
	return \@out;
}

sub read_code_block {
	my ($self, $tok, $close, $separator) = @_;
	my @out = ();

	$self->{debug}->('parse', "B+$close") if $self->{debug};

	while (scalar @$tok > 0) {
		my $stmt = $self->read_statement($tok, undef);

		$self->{debug}->('parse', "B-$close $stmt") if $self->{debug};

		if ($stmt eq $close) {
			# block end
			#
			return \@out;
		} elsif (defined $separator && ($stmt eq $separator)) {
			#push(@out, $separator);
		} else {
			$stmt = filter_bad_brace($stmt);
			push(@out, $stmt);
		}
	}
	return \@out;
}

sub tokens {
	my ($self) = @_;
	return $self->{tok};
}

sub read_code {
	my ($self, $tok) = @_;
	my $in;
	my @out = ();

	$in = unspace_list($tok);

	my $stmts = $self->read_code_block($in, '?>', ';');
	if (scalar @$stmts == 1) {
		return $stmts->[0];
	}
	my $k = $self->setblk('flat', $stmts);
	return $k;
}

sub map_stmt {
	my ($self, $s, $cb, @params) = @_;

	#$self->{log}->('MAP', "$s") if $self->{log};

	my $k = $cb->($s, @params);
	if (defined $k) {
		return $k;
	}
	my $s0 = $s;

	if (!defined $s) {
		$self->{warn}->('map', "undefined symbol");
		# keep
	} elsif ($s =~ /^#null$/) {
		# keep
	} elsif ($s =~ /^#num\d+$/) {
		# keep
	} elsif ($s =~ /^#const\d+$/) {
		# keep
	} elsif ($s =~ /^#str\d+$/) {
		# keep
	} elsif ($s =~ /^#arr\d+$/) {
		my $arr = $self->{strmap}{$s};
		my $keys = $arr->get_keys();
		my %newmap;
		my @newkeys = ();
		my $changed = 0;

		foreach my $k (@$keys) {
			my $val = $arr->val($k);
			if ((is_int_index($k) || is_strval($k)) && (!defined $val
				|| (defined $val && is_strval($val)))) {
				push(@newkeys, $k);
				$newmap{$k} = $val;
			} else {
				my $k2 = $k;
				unless (is_int_index($k)) {
					$k2 = $self->map_stmt($k, $cb, @params);
				}
				push(@newkeys, $k2);
				if (defined $val) {
					my $v = $self->map_stmt($val, $cb, @params);
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
			$arr = $self->newarr();
			foreach my $k (@newkeys) {
				$arr->set($k, $newmap{$k});
			}
			$s = $arr->{name};
		}
	} elsif ($s =~ /^#fun\d+$/) {
		my ($f, $a, $b, $p) = @{$self->{strmap}->{$s}};
		# no context change here
	} elsif ($s =~ /^#call\d+$/) {
		my ($f, $a) = @{$self->{strmap}->{$s}};
		my @args = ();
		my $arg_changed = 0;
		my $name = $f;

		if ($f =~ /^#fun\d+$/) {
			# no context change here
			#$name = $self->map_stmt($f, $cb, @params);
		} else {
			$name = $self->map_stmt($f, $cb, @params);
		}
		foreach my $k (@$a) {
			my $v = $self->map_stmt($k, $cb, @params);
			push(@args, $v);
			if ($v ne $k) {
				$arg_changed = 1;
			}
		}
		if (($name ne $f) || $arg_changed) {
			$s = $self->setcall($name, \@args);
		}
	} elsif ($s =~ /^#elem\d+$/) {
		my ($v, $i) = @{$self->{strmap}->{$s}};
		my $vv = $self->map_stmt($v, $cb, @params);
		my $ii = $i;

		if (defined $i) {
			$ii = $self->map_stmt($i, $cb, @params);
		}
		if (($v ne $vv) || (defined $i && ($i ne $ii))) {
			$s = $self->setelem($vv, $ii);
		}
	} elsif ($s =~ /^#expr\d+$/) {
		# if v1 missing: prefix op
		# if v2 missing: postfix op
		my ($op, $v1, $v2) = @{$self->{strmap}->{$s}};
		my $vv1 = $v1;
		my $vv2 = $v2;

		if (defined $v1) {
			$vv1 = $self->map_stmt($v1, $cb, @params);
		}
		if (defined $v2) {
			$vv2 = $self->map_stmt($v2, $cb, @params);
		}
		if ((defined $v1 && ($v1 ne $vv1)) || (defined $v2 && ($v2 ne $vv2))) {
			$s = $self->setexpr($op, $vv1, $vv2);
		}
	} elsif ($s =~ /^#pfx\d+$/) {
		# keep
	} elsif ($s =~ /^#obj\d+$/) {
		my ($o, $m) = @{$self->{strmap}->{$s}};
		my $oo = $o;
		my $mm = $m;

		unless ($o =~ /^#call\d+$/) {
			# not 'new'
			$oo = $self->map_stmt($o, $cb, @params);
		}
		unless (exists $self->{strmap}->{$m} && is_symbol($self->{strmap}->{$m})) {
			# not 'sym'
			$mm = $self->map_stmt($m, $cb, @params);
		}
		if (($o ne $oo) || ($m ne $mm)) {
			$s = $self->setobj($oo, $mm);
		}
	} elsif ($s =~ /^#scope\d+$/) {
		my ($c, $e) = @{$self->{strmap}->{$s}};
		my $cc = $c;
		my $ee = $e;

		unless (exists $self->{strmap}->{$c} && is_symbol($self->{strmap}->{$c})) {
			# not 'class'
			$cc = $self->map_stmt($c, $cb, @params);
		}
		unless (exists $self->{strmap}->{$e} && is_symbol($self->{strmap}->{$e})) {
			# not 'sym'
			$ee = $self->map_stmt($e, $cb, @params);
		}
		if (($c ne $cc) || ($e ne $ee)) {
			$s = $self->setscope($cc, $ee);
		}
	} elsif ($s =~ /^#ns\d+$/) {
		my ($n, $e) = @{$self->{strmap}->{$s}};
		my $nn = $n;
		my $ee = $self->map_stmt($e, $cb, @params);

		if (defined $n) {
			# non-sym should be error
			unless (exists $self->{strmap}->{$n} && is_symbol($self->{strmap}->{$n})) {
				$nn = $self->map_stmt($n, $cb, @params);
			}
		}
		if ((defined $n && ($n ne $nn)) || ($e ne $ee)) {
			$s = $self->setobj($nn, $ee);
		}
	} elsif ($s =~ /^#inst\d+$/) {
		my ($c, $f, $i) = @{$self->{strmap}->{$s}};
	} elsif ($s =~ /^#ref\d+$/) {
		my ($v) = @{$self->{strmap}->{$s}};
	} elsif ($s =~ /^#class\d+$/) {
		my ($c, $b, $p) = @{$self->{strmap}->{$s}};
		# no context change here
	} elsif ($s =~ /^#trait\d+$/) {
		my ($t, $b) = @{$self->{strmap}->{$s}};
		# no context change here
	} elsif ($s =~ /^#fh\d+$/) {
		my $f = $self->{strmap}->{$s}{name};
		my $m = $self->{strmap}->{$s}{mode};
		my $p = $self->{strmap}->{$s}{pos};
	} elsif ($s =~ /^#blk\d+$/) {
		my ($type, $a) = @{$self->{strmap}->{$s}};
		my @args = ();
		my $arg_changed = 0;

		foreach my $k (@$a) {
			my $v = $self->map_stmt($k, $cb, @params);
			if ($v ne $k) {
				unless ($self->is_empty_block($v)) {
					push(@args, $v);
				}
				$arg_changed = 1;
			} else {
				push(@args, $v);
			}
		}
		if ($arg_changed) {
			$s = $self->setblk($type, \@args);
		}
	} elsif ($s =~ /^#stmt\d+$/) {
		my $cmd = $self->{strmap}->{$s}->[0];
		if ($cmd eq 'echo') {
			my $a = $self->{strmap}->{$s}->[1];
			my @args = ();
			my $arg_changed = 0;

			foreach my $k (@$a) {
				my $v = $self->map_stmt($k, $cb, @params);
				push(@args, $v);
				if ($v ne $k) {
					$arg_changed = 1;
				}
			}
			if ($arg_changed) {
				$s = $self->setstmt(['echo', \@args]);
			}
		} elsif ($cmd eq 'print') {
			my $arg = $self->{strmap}->{$s}->[1];
			my $v = $self->map_stmt($arg, $cb, @params);

			if ($v ne $arg) {
				$s = $self->setstmt(['print', $v]);
			}
		} elsif ($cmd eq 'namespace') {
			my ($arg, $block) = @{$self->{strmap}->{$s}}[1..2];
			my $v = $arg;
			my $block1 = $block;

			if (defined $block) {
				$block1 = $self->map_stmt($block, $cb, @params);
			}
			if (($v ne $arg) || ($block1 ne $block)) {
				$s = $self->setstmt(['namespace', $v, $block1]);
			}
		} elsif ($cmd =~ /^(include|include_once|require|require_once)$/) {
			my $arg = $self->{strmap}->{$s}->[1];
			my $v = $self->map_stmt($arg, $cb, @params);

			if ($v ne $arg) {
				$s = $self->setstmt([$cmd, $v]);
			}
		} elsif ($cmd eq 'use') {
			my $a = $self->{strmap}->{$s}->[1];
			my @args = ();
			my $arg_changed = 0;

			foreach my $k (@$a) {
				my $v = $self->map_stmt($k, $cb, @params);
				push(@args, $v);
				if ($v ne $k) {
					$arg_changed = 1;
				}
			}
			if ($arg_changed) {
				$s = $self->setstmt(['use', \@args]);
			}
		} elsif ($cmd eq 'global') {
			my $a = $self->{strmap}->{$s}->[1];
			my @args = ();
			my $arg_changed = 0;

			foreach my $k (@$a) {
				my $v = $self->map_stmt($k, $cb, @params);
				push(@args, $v);
				if ($v ne $k) {
					$arg_changed = 1;
				}
			}
			if ($arg_changed) {
				$s = $self->setstmt(['global', \@args]);
			}
		} elsif ($cmd eq 'static') {
			my ($a, $p) = @{$self->{strmap}->{$s}}[1..2];
			my @args = ();
			my $arg_changed = 0;

			foreach my $k (@$a) {
				my $v = $self->map_stmt($k, $cb, @params);
				push(@args, $v);
				if ($v ne $k) {
					$arg_changed = 1;
				}
			}
			if ($arg_changed) {
				$s = $self->setstmt(['static', \@args, $p]);
			}
		} elsif ($cmd eq 'const') {
			my ($a, $p) = @{$self->{strmap}->{$s}}[1..2];
			my @args = ();
			my $arg_changed = 0;

			foreach my $k (@$a) {
				my $v = $self->map_stmt($k, $cb, @params);
				push(@args, $v);
				if ($v ne $k) {
					$arg_changed = 1;
				}
			}
			if ($arg_changed) {
				$s = $self->setstmt(['const', \@args, $p]);
			}
		} elsif ($cmd eq 'unset') {
			my $a = $self->{strmap}->{$s}->[1];
			my @args = ();
			my $arg_changed = 0;

			foreach my $k (@$a) {
				my $v = $self->map_stmt($k, $cb, @params);
				push(@args, $v);
				if ($v ne $k) {
					$arg_changed = 1;
				}
			}
			if ($arg_changed) {
				$s = $self->setstmt(['unset', \@args]);
			}
		} elsif ($cmd eq 'return') {
			my $arg = $self->{strmap}->{$s}->[1];
			my $v = $arg;

			if (defined $v) {
				$v = $self->map_stmt($arg, $cb, @params);
			}
			if (defined $v && ($v ne $arg)) {
				$s = $self->setstmt(['return', $v]);
			}
		} elsif ($cmd eq 'goto') {
			my $arg = $self->{strmap}->{$s}->[1];
			my $v = $self->map_stmt($arg, $cb, @params);

			if ($v ne $arg) {
				$s = $self->setstmt(['goto', $v]);
			}
		} elsif ($cmd eq 'label') {
			my $arg = $self->{strmap}->{$s}->[1];
			my $v = $self->map_stmt($arg, $cb, @params);

			if ($v ne $arg) {
				$s = $self->setstmt(['label', $v]);
			}
		} elsif ($cmd eq 'throw') {
			my $arg = $self->{strmap}->{$s}->[1];
			my $v = $self->map_stmt($arg, $cb, @params);

			if ($v ne $arg) {
				$s = $self->setstmt(['throw', $v]);
			}
		} elsif ($cmd eq 'if') {
			my ($cond, $then, $else) = @{$self->{strmap}->{$s}}[1..3];
			my $cond1 = $self->map_stmt($cond, $cb, @params);
			my $then1 = $self->map_stmt($then, $cb, @params);
			my $else1 = $else;

			if (defined $else) {
				$else1 = $self->map_stmt($else, $cb, @params);
			}
			if (($cond ne $cond1) || ($then ne $then1) || (defined $else && ($else ne $else1))) {
				if ($self->is_empty_block($then1) && (!defined $else || $self->is_empty_block($else1))) {
					$s = $cond1;
				} else {
					$s = $self->setstmt(['if', $cond1, $then1, $else1]);
				}
			}
		} elsif ($cmd eq 'while') {
			my ($cond, $block) = @{$self->{strmap}->{$s}}[1..2];
			my $cond1 = $self->map_stmt($cond, $cb, @params);
			my $block1 = $self->map_stmt($block, $cb, @params);

			if (($cond ne $cond1) || ($block ne $block1)) {
				$s = $self->setstmt(['while', $cond1, $block1]);
			}
		} elsif ($cmd eq 'do') {
			my ($cond, $block) = @{$self->{strmap}->{$s}}[1..2];
			my $cond1 = $self->map_stmt($cond, $cb, @params);
			my $block1 = $self->map_stmt($block, $cb, @params);

			if (($cond ne $cond1) || ($block ne $block1)) {
				$s = $self->setstmt(['do', $cond1, $block1]);
			}
		} elsif ($cmd eq 'for') {
			my ($pre, $cond, $post, $block) = @{$self->{strmap}->{$s}}[1..4];
			my $pre1 = $self->map_stmt($pre, $cb, @params);
			my $cond1 = $self->map_stmt($cond, $cb, @params);
			my $post1 = $self->map_stmt($post, $cb, @params);
			my $block1 = $self->map_stmt($block, $cb, @params);

			if (($pre ne $pre1) || ($cond ne $cond1) || ($post ne $post1) || ($block ne $block1)) {
				$s = $self->setstmt(['for', $pre1, $cond1, $post1, $block1]);
			}
		} elsif ($cmd eq 'foreach') {
			my ($expr, $key, $value, $block) = @{$self->{strmap}->{$s}}[1..4];
			my $expr1 = $self->map_stmt($expr, $cb, @params);
			my $key1 = $key;

			if (defined $key) {
				$key1 = $self->map_stmt($key, $cb, @params);
			}
			my $value1 = $self->map_stmt($value, $cb, @params);
			my $block1 = $self->map_stmt($block, $cb, @params);

			if (($expr ne $expr1) || (defined $key && ($key ne $key1)) || ($value ne $value1) || ($block ne $block1)) {
				$s = $self->setstmt(['foreach', $expr1, $key1, $value1, $block1]);
			}
		} elsif ($cmd eq 'switch') {
			my ($expr, $cases) = @{$self->{strmap}->{$s}}[1..2];
			my $expr1 = $self->map_stmt($expr, $cb, @params);
			my @cnew = ();
			my $changed = 0;

			foreach my $e (@$cases) {
				my $c = $e->[0];
				my $b = $e->[1];
				my $c1 = $c;

				if (defined $c) {
					$c1 = $self->map_stmt($c, $cb, @params);
				}
				my $b1 = $self->map_stmt($b, $cb, @params);

				if ((defined $c1 && ($c ne $c1)) || ($b ne $b1)) {
					$changed = 1;
				}
				push (@cnew, [$c1, $b1]);
			}
			if (($expr ne $expr1) || $changed) {
				$s = $self->setstmt(['switch', $expr1, \@cnew]);
			}
		} elsif ($cmd eq 'case') {
			my $expr = $self->{strmap}->{$s}->[1];
			my $expr1 = $expr;

			if (!defined $expr) {
				$expr1 = $self->map_stmt($expr, $cb, @params);
			}
			if (defined $expr && ($expr ne $expr1)) {
				$s = $self->setstmt(['case', $expr1]);
			}
		} elsif ($cmd eq 'try') {
			my ($try, $catches, $finally) = @{$self->{strmap}->{$s}}[1..3];
			my $try1 = $self->map_stmt($try, $cb, @params);
			my $finally1 = $finally;
			my @cnew = ();
			my $changed = 0;

			foreach my $c (@$catches) {
				my $e = $c->[0];
				my $b = $c->[1];

				my $e1 = $self->map_stmt($e, $cb, @params);
				my $b1 = $self->map_stmt($b, $cb, @params);

				if ((defined $e1 && ($e ne $e1)) || ($b ne $b1)) {
					$changed = 1;
				}
				push (@cnew, [$e1, $b1]);
			}
			if (defined $finally) {
				$finally1 = $self->map_stmt($finally, $cb, @params);
			}
			if (($try ne $try1) || $changed || (defined $finally && ($finally ne $finally1))) {
				$s = $self->setstmt(['try', $try1, \@cnew, $finally1]);
			}
		}
	} elsif (is_variable($s)) {
		# keep
	}
	if ($s ne $s0) {
		$self->{debug}->('map', "map %s -> %s", $s0, $s) if $self->{debug};
	}
	return $s;
}

sub escape_str {
	my ($s, $fmt) = @_;

	# escape string (keep newlines as newline like php does)
	# http://php.net/manual/de/language.types.string.php
	# - php single quoted strings suppport backslash escapes
	#   for literal backslash & single quote.
	# - use single quotes to avoid string interpolation on
	#   re-evaluation.
	#
	$s =~ s/\\/\\\\/sg;
	$s =~ s/'/\\'/sg;

	if (exists $fmt->{escape_ctrl}) {
		# convert controls other than \t\r\n to "\xNN"
		$s = escape_ctrl($s, "\x00-\x08\x0b\x0c\x0e-\x1f\x7f");
	} else {
		$s = "'" . $s . "'";
	}
	return $s;
}

sub expand_stmt {
	my ($self, $out, $s, $fmt) = @_;

	#$self->{log}->('EXPAND', "$s") if $self->{log};

	if (!defined $s) {
		$self->{warn}->('expand', "undefined symbol");
		push(@$out, '<UNDEF>');
	} elsif ($s =~ /^#null$/) {
		push(@$out, 'null');
	} elsif ($s =~ /^#num\d+$/) {
		if (exists $self->{strmap}->{$s}) {
			unless (exists $fmt->{unified}) {
				$s = $self->{strmap}->{$s};
			}
		}
		push(@$out, $s);
	} elsif ($s =~ /^#const\d+$/) {
		if (exists $self->{strmap}->{$s}) {
			unless (exists $fmt->{unified}) {
				$s = $self->{strmap}->{$s};
			}
		}
		push(@$out, $s);
	} elsif ($s =~ /^#str\d+$/) {
		if (exists $self->{strmap}->{$s}) {
			unless (exists $fmt->{unified}) {
				$s = $self->{strmap}->{$s};
				if (exists $fmt->{mask_eval}) {
					# substitute 'eval' in strings on output
					$s =~ s/(^|\W)eval(\s*\()/$1$fmt->{mask_eval}$2/g;
				}
				if (exists $fmt->{max_strlen} && (length($s) > $fmt->{max_strlen})) {
					$s = substr($s, 0, $fmt->{max_strlen}-2).'..';
				}
				$s = escape_str($s, $fmt);
			}
		}
		push(@$out, $s);
	} elsif ($s =~ /^#arr\d+$/) {
		my $arr = $self->{strmap}{$s};
		my $keys = $arr->get_keys();
		push(@$out, 'array');
		push(@$out, '(');

		foreach my $k (@$keys) {
			my $val = $arr->val($k);
			$self->expand_stmt($out, $k, $fmt);
			push(@$out, '=>');
			if (defined $val) {
				$self->expand_stmt($out, $val, $fmt);
			}
			push(@$out, ',');
		}
		if (scalar @$keys > 0) {
			pop(@$out);
		}
		push(@$out, ')');
	} elsif ($s =~ /^#fun\d+$/) {
		my ($f, $a, $b, $p) = @{$self->{strmap}->{$s}};

		foreach my $k (sort grep { exists $php_modifiers{$_} } keys %$p) {
			push(@$out, $k);
		}
		push(@$out, 'function');
		if (defined $f) {
			push(@$out, $f);
		}
		push(@$out, '(');
		foreach my $k (@$a) {
			#push(@$out, $k);
			$self->expand_stmt($out, $k, $fmt);
			push(@$out, ',');
		}
		if (scalar @$a > 0) {
			pop(@$out);
		}
		push(@$out, ')');
		$self->expand_stmt($out, $b, $fmt);
		#push(@$out, '{');
		#foreach my $k (@$b) {
		#	$self->expand_stmt($out, $k, $fmt);
		#	push(@$out, ';');
		#}
		#if (scalar @$b > 0) {
		#	pop(@$out);
		#}
		#push(@$out, '}');
	} elsif ($s =~ /^#call\d+$/) {
		my ($f, $a) = @{$self->{strmap}->{$s}};

		if ($f =~ /^#fun\d+$/) {
			# anonymous function call requires braces around func
			push(@$out, '(');
			$self->expand_stmt($out, $f, $fmt);
			push(@$out, ')');
		} else {
			$self->expand_stmt($out, $f, $fmt);
		}
		push(@$out, '(');
		foreach my $k (@$a) {
			$self->expand_stmt($out, $k, $fmt);
			push(@$out, ',');
		}
		if (scalar @$a > 0) {
			pop(@$out);
		}
		push(@$out, ')');
	} elsif ($s =~ /^#elem\d+$/) {
		my ($v, $i) = @{$self->{strmap}->{$s}};

		$self->expand_stmt($out, $v, $fmt);
		push(@$out, '[');
		if (defined $i) {
			$self->expand_stmt($out, $i, $fmt);
		}
		push(@$out, ']');
	} elsif ($s =~ /^#expr\d+$/) {
		# if v1 missing: prefix op
		# if v2 missing: postfix op
		my ($op, $v1, $v2) = @{$self->{strmap}->{$s}};

		if (defined $v1) {
			if ($v1 =~ /^#expr\d+$/) {
				my ($vop, $vv1, $vv2) = @{$self->{strmap}->{$v1}};
				my $add_brace = 0;
				if (($op ne '=') && ($op ne $vop)) {
					$add_brace = 1;
				}
				if (exists $op_unary{$vop} && ($vop ne 'new') && (is_variable($vv2) || ($vv2 =~ /^#elem\d+$/) || ($vv2 =~ /^#call\d+$/))) {
					$add_brace = 0;
				}
				if ($add_brace) {
					push(@$out, '(');
				}
				$self->expand_stmt($out, $v1, $fmt);
				if ($add_brace) {
					push(@$out, ')');
				}
			} elsif (($op eq '=') && ($v1 =~ /^#arr\d+$/)) {
				# output lhs array() as list() and allow empty elems
				#
				my $arr = $self->{strmap}{$v1};
				my $keys = $arr->get_keys();
				my $numerical = $arr->is_numerical();
				push(@$out, 'list');
				push(@$out, '(');

				foreach my $k (@$keys) {
					my $val = $arr->val($k);
					if (defined $val) {
						unless ($numerical) {
							$self->expand_stmt($out, $k, $fmt);
							push(@$out, '=>');
						}
						$self->expand_stmt($out, $val, $fmt);
					}
					push(@$out, ',');
				}
				if (scalar @$keys > 0) {
					pop(@$out);
				}
				push(@$out, ')');
			} else {
				$self->expand_stmt($out, $v1, $fmt);
			}
		}
		push(@$out, $op);
		if (defined $v2) {
			if ($op eq '$') {
				push(@$out, '{');
			}
			if ($v2 =~ /^#expr\d+$/) {
				my ($vop, $vv1, $vv2) = @{$self->{strmap}->{$v2}};
				my $add_brace = 0;
				if (($op ne '?') && ($op ne '=') && ($op ne $vop)) {
					$add_brace = 1;
				}
				if (exists $op_unary{$vop} && (is_variable($vv2) || ($vv2 =~ /^#elem\d+$/) || ($vv2 =~ /^#call\d+$/))) {
					$add_brace = 0;
				}
				if ($add_brace) {
					push(@$out, '(');
				}
				$self->expand_stmt($out, $v2, $fmt);
				if ($add_brace) {
					push(@$out, ')');
				}
			} else {
				$self->expand_stmt($out, $v2, $fmt);
			}
			if ($op eq '$') {
				push(@$out, '}');
			}
		}
	} elsif ($s =~ /^#pfx\d+$/) {
		my $pfx = $self->{strmap}->{$s};
		foreach my $k (sort keys %$pfx) {
			push(@$out, $k);
		}
	} elsif ($s =~ /^#obj\d+$/) {
		my ($o, $m) = @{$self->{strmap}->{$s}};

		if ($o =~ /^#call\d+$/) {
			push(@$out, '(');
			$self->expand_stmt($out, $o, $fmt);
			push(@$out, ')');
		} else { 
			$self->expand_stmt($out, $o, $fmt);
		}
		push(@$out, '->');
		if (exists $self->{strmap}->{$m} && is_strval($m)) {
			my $sym = $self->{strmap}->{$m};
			if (is_symbol($sym)) {
				push(@$out, $sym);
			} else {
				$sym = escape_str($sym, $fmt);

				push(@$out, '{');
				push(@$out, $sym);
				push(@$out, '}');
			}
		} else {
			$self->expand_stmt($out, $m, $fmt);
		}
	} elsif ($s =~ /^#scope\d+$/) {
		my ($c, $e) = @{$self->{strmap}->{$s}};

		if (exists $self->{strmap}->{$c} && is_symbol($self->{strmap}->{$c})) {
			push(@$out, $self->{strmap}->{$c});
		} else {
			$self->expand_stmt($out, $c, $fmt);
		}
		push(@$out, '::');
		if (exists $self->{strmap}->{$e} && is_symbol($self->{strmap}->{$e})) {
			push(@$out, $self->{strmap}->{$e});
		} else {
			$self->expand_stmt($out, $e, $fmt);
		}
	} elsif ($s =~ /^#ns\d+$/) {
		my ($n, $e) = @{$self->{strmap}->{$s}};

		if (defined $n) {
			if (exists $self->{strmap}->{$n} && is_symbol($self->{strmap}->{$n})) {
				push(@$out, $self->{strmap}->{$n});
			} else {
				$self->expand_stmt($out, $n, $fmt);
			}
		}
		push(@$out, '\\');
		$self->expand_stmt($out, $e, $fmt);
	} elsif ($s =~ /^#inst\d+$/) {
		my ($c, $f, $i) = @{$self->{strmap}->{$s}};

		push(@$out, 'new');
		$self->expand_stmt($out, $f, $fmt);
	} elsif ($s =~ /^#ref\d+$/) {
		my ($v) = @{$self->{strmap}->{$s}};

		push(@$out, '&');
		$self->expand_stmt($out, $v, $fmt);
	} elsif ($s =~ /^#class\d+$/) {
		my ($c, $b, $p) = @{$self->{strmap}->{$s}};

		foreach my $k (sort grep { exists $php_modifiers{$_} } keys %$p) {
			push(@$out, $k);
		}
		push(@$out, 'class');
		push(@$out, $c);

		if (exists $p->{parent}) {
			push(@$out, 'extends');
			push(@$out, $p->{parent});
		}
		$self->expand_stmt($out, $b, $fmt);
	} elsif ($s =~ /^#trait\d+$/) {
		my ($t, $b) = @{$self->{strmap}->{$s}};

		push(@$out, 'trait');
		push(@$out, $t);
		$self->expand_stmt($out, $b, $fmt);
	} elsif ($s =~ /^#fh\d+$/) {
		my $f = $self->{strmap}->{$s}{name};
		my $m = $self->{strmap}->{$s}{mode};
		my $p = $self->{strmap}->{$s}{pos};
		push(@$out, 'FH');
		push(@$out, '(');
		push(@$out, $f);
		push(@$out, ',');
		push(@$out, $m);
		push(@$out, ')');
	} elsif ($s =~ /^#blk\d+$/) {
		my ($type, $a) = @{$self->{strmap}->{$s}};
		if ($type eq 'expr') {
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				push(@$out, ',');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
		} elsif ($type eq 'flat') {
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				if ($k =~ /^#pfx\d+$/) {
					next; # avoid ;
				}
				if (($out->[-1] ne '}') && ($out->[-1] ne ':')) {
					push(@$out, ';');
				}
			}
			if ((scalar @$a > 0) && ($out->[-1] eq ';')) {
				pop(@$out) if $fmt->{avoid_semicolon};
			}
		} elsif ($type eq 'case') {
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				push(@$out, ';');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
		} elsif ($type eq 'brace') {
			if (scalar @$a == 1) {
				$self->expand_stmt($out, $a->[0], $fmt);
			} else {
				push(@$out, '(');
				foreach my $k (@$a) {
					$self->expand_stmt($out, $k, $fmt);
					if ($out->[-1] ne ')') {
						push(@$out, ';');
					}
				}
				if ((scalar @$a > 0) && ($out->[-1] eq ';')) {
					pop(@$out);
				}
				push(@$out, ')');
			}
		} else {
			push(@$out, '{');
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				if ($k =~ /^#pfx\d+$/) {
					next; # avoid ;
				}
				if (($out->[-1] ne '}') && ($out->[-1] ne ':')) {
					push(@$out, ';');
				}
			}
			if ((scalar @$a > 0) && ($out->[-1] eq ';')) {
				pop(@$out) if $fmt->{avoid_semicolon};
			}
			push(@$out, '}');
		}
	} elsif ($s =~ /^#stmt\d+$/) {
		my $cmd = $self->{strmap}->{$s}->[0];
		if ($cmd eq 'echo') {
			my $a = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				push(@$out, ',');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
			#push(@$out, ';');
		} elsif ($cmd eq 'print') {
			my $arg = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			$self->expand_stmt($out, $arg, $fmt);
		} elsif ($cmd eq 'namespace') {
			my ($arg, $block) = @{$self->{strmap}->{$s}}[1..2];
			push(@$out, $cmd);
			if ($arg ne '') {
				push(@$out, $arg);
			}
			if (defined $block) {
				$self->expand_stmt($out, $block, $fmt);
			}
		} elsif ($cmd =~ /^(include|include_once|require|require_once)$/) {
			my $arg = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			$self->expand_stmt($out, $arg, $fmt);
		} elsif ($cmd eq 'use') {
			my $a = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				push(@$out, ',');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
		} elsif ($cmd eq 'global') {
			my $a = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				push(@$out, ',');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
		} elsif ($cmd eq 'static') {
			my ($a, $p) = @{$self->{strmap}->{$s}}[1..2];

			#push(@$out, join(' ', sort keys %$p));
			push(@$out, join(' ', (grep { $_ ne $cmd } sort keys %$p), $cmd));
			#push(@$out, $cmd);
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				push(@$out, ',');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
		} elsif ($cmd eq 'const') {
			my ($a, $p) = @{$self->{strmap}->{$s}}[1..2];

			#push(@$out, join(' ', sort keys %$p));
			push(@$out, join(' ', (grep { $_ ne $cmd } sort keys %$p), $cmd));
			#push(@$out, $cmd);
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				push(@$out, ',');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
		} elsif ($cmd eq 'unset') {
			my $a = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			push(@$out, '(');
			foreach my $k (@$a) {
				$self->expand_stmt($out, $k, $fmt);
				push(@$out, ',');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
			push(@$out, ')');
		} elsif ($cmd eq 'return') {
			my $a = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			$self->expand_stmt($out, $a, $fmt);
		} elsif ($cmd eq 'goto') {
			my $a = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			$self->expand_stmt($out, $a, $fmt);
		} elsif ($cmd eq 'label') {
			my $a = $self->{strmap}->{$s}->[1];
			$self->expand_stmt($out, $a, $fmt);
			push(@$out, ':');
		} elsif ($cmd eq 'throw') {
			my $arg = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			$self->expand_stmt($out, $arg, $fmt);
		} elsif ($cmd eq 'if') {
			my ($cond, $then, $else) = @{$self->{strmap}->{$s}}[1..3];

			push(@$out, $cmd);
			push(@$out, '(');
			$self->expand_stmt($out, $cond, $fmt);
			push(@$out, ')');
			$self->expand_stmt($out, $then, $fmt);
			if (defined $else) {
				push(@$out, 'else');

				# remove block around 'if else'
				#
				my $stmts = is_block($else) ? $self->{strmap}->{$else}->[1] : [];
				if ((@$stmts == 1) && ($stmts->[0] =~ /#stmt\d+$/) && ($self->{strmap}->{$stmts->[0]}->[0] eq 'if')) {
					$self->expand_stmt($out, $stmts->[0], $fmt);
				} else {
					$self->expand_stmt($out, $else, $fmt);
				}
			}
		} elsif ($cmd eq 'while') {
			my ($cond, $block) = @{$self->{strmap}->{$s}}[1..2];

			push(@$out, $cmd);
			push(@$out, '(');
			$self->expand_stmt($out, $cond, $fmt);
			push(@$out, ')');
			$self->expand_stmt($out, $block, $fmt);
		} elsif ($cmd eq 'do') {
			my ($cond, $block) = @{$self->{strmap}->{$s}}[1..2];

			push(@$out, $cmd);
			$self->expand_stmt($out, $block, $fmt);
			push(@$out, 'while');
			push(@$out, '(');
			$self->expand_stmt($out, $cond, $fmt);
			push(@$out, ')');
		} elsif ($cmd eq 'for') {
			my ($pre, $cond, $post, $block) = @{$self->{strmap}->{$s}}[1..4];

			push(@$out, $cmd);
			push(@$out, '(');
			$self->expand_stmt($out, $pre, $fmt);
			push(@$out, ';');
			$self->expand_stmt($out, $cond, $fmt);
			push(@$out, ';');
			$self->expand_stmt($out, $post, $fmt);
			push(@$out, ')');
			$self->expand_stmt($out, $block, $fmt);
		} elsif ($cmd eq 'foreach') {
			my ($expr, $key, $value, $block) = @{$self->{strmap}->{$s}}[1..4];

			push(@$out, $cmd);
			push(@$out, '(');
			$self->expand_stmt($out, $expr, $fmt);
			push(@$out, 'as');
			if (defined $key) {
				$self->expand_stmt($out, $key, $fmt);
				push(@$out, '=>');
			}
			$self->expand_stmt($out, $value, $fmt);
			push(@$out, ')');
			$self->expand_stmt($out, $block, $fmt);
		} elsif ($cmd eq 'switch') {
			my ($expr, $cases) = @{$self->{strmap}->{$s}}[1..2];

			push(@$out, $cmd);
			push(@$out, '(');
			$self->expand_stmt($out, $expr, $fmt);
			push(@$out, ')');
			push(@$out, '{');
			foreach my $e (@$cases) {
				my $c = $e->[0];
				my $b = $e->[1];
				if (defined $c) {
					push(@$out, 'case');
					$self->expand_stmt($out, $c, $fmt);
					push(@$out, ':');
				} else {
					push(@$out, 'default');
					push(@$out, ':');
				}
				$self->expand_stmt($out, $b, $fmt);
				push(@$out, ';');
			}
			push(@$out, '}');
		} elsif ($cmd eq 'case') {
			my $expr = $self->{strmap}->{$s}->[1];
			if (!defined $expr) {
				push(@$out, 'default');
				push(@$out, ':');
			} else {
				push(@$out, 'case');
				$self->expand_stmt($out, $expr, $fmt);
				push(@$out, ':');
			}
		} elsif ($cmd eq 'try') {
			my ($try, $catches, $finally) = @{$self->{strmap}->{$s}}[1..3];

			push(@$out, $cmd);
			$self->expand_stmt($out, $try, $fmt);
			foreach my $c (@$catches) {
				my $e = $c->[0];
				my $b = $c->[1];
				push(@$out, 'catch');
				push(@$out, '(');
				$self->expand_stmt($out, $e, $fmt);
				push(@$out, ')');
				$self->expand_stmt($out, $b, $fmt);
			}
			if (defined $finally) {
				push(@$out, 'finally');
				$self->expand_stmt($out, $finally, $fmt);
			}
		} else {
			push(@$out, $cmd);
		}
	} elsif (is_variable($s)) {
		my ($global) = global_split($s);
		if (defined $global) {
			my ($sym) = $global =~ /^\$(.*)$/;
			push(@$out, '$GLOBALS');
			push(@$out, '[');
			push(@$out, '\'' . $sym . '\'');
			push(@$out, ']');
		} else {
			my ($class, $sym) = inst_split($s);
			if (defined $class) {
				push(@$out, $class);
				push(@$out, '::');
				push(@$out, $sym);
			} elsif ($s eq '$') {
				push(@$out, '$');
				push(@$out, '{');
				push(@$out, 'null');
				push(@$out, '}');
			} elsif (!is_strict_variable($s)) {
				($sym) = $s =~ /^\$(.*)$/;
				$sym = escape_str($sym, $fmt);

				push(@$out, '$');
				push(@$out, '{');
				push(@$out, $sym);
				push(@$out, '}');
			} else {
				push(@$out, $s);
			}
		}
	} else {
		my ($class, $sym) = method_split($s);
		if (defined $class) {
			if ($class =~ /^(#inst\d+)$/) {
				$self->expand_stmt($out, $class, $fmt);
				push(@$out, '->');
				push(@$out, $sym);
			} else {
				push(@$out, $class);
				push(@$out, '::');
				push(@$out, $sym);
			}
		} else {
			push(@$out, $s);
		}
	}
	return;
}

sub expand_formatted {
	my ($out, $in, $tabs) = @_;
	my $orgtabs = $tabs;
	my $spc = "\t" x $tabs;
	my $val;
	my $lastval;
	my $varblk = 0;

	# insert newlines and indent {}-blocks
	#
	while (1) {
		my $val = shift @$in;
		my $isfor = 0;
		my $isswitch = 0;
		my $iscase = 0;
		my $isfunc = 0;
		my $exprblk = 0;

		if (!defined $val) {
			return;
		}
		if ($val eq '}') {
			return;
		}
		push(@$out, $spc);
		STMT: while(defined $val) {
			if ($val =~ /^(case|default)$/) {
				$iscase = 1;
			} elsif ($val =~ /^(function|class)$/) {
				$isfunc = 1;
			}
			if ((scalar @$in > 0) && ($in->[0] =~ /^(case|default)$/)) {
				$tabs = $orgtabs;
				$spc = "\t" x $tabs;
			}
			push(@$out, $val);
			if (($val eq '{') && defined $lastval && ($lastval eq '$')) {
				$varblk++;
			} elsif ($val eq '(') {
				if (defined $lastval && ($lastval eq 'for')) {
					$isfor = 1;
				} elsif (defined $lastval && ($lastval eq 'switch')) {
					$isswitch = 1;
				}
				$exprblk++;
			} elsif ($val eq '{') {
				push(@$out, "\n");
				if ($isswitch) {
					&expand_formatted($out, $in, $tabs);
				} else {
					&expand_formatted($out, $in, $tabs+1);
				}
				push(@$out, $spc);
				push(@$out, "}");
				if ((scalar @$in > 0) && !($in->[0] =~ /^(else|catch|finally|\))$/)) {
					push(@$out, "\n");
					#push(@$out, "\n") if $isfunc; # blank line after function?
					last STMT;
				}
			} elsif ($val eq ';') {
				if (!$isfor) {
					push(@$out, "\n");
					last STMT;
				}
			} elsif ($val eq ':') {
				if ($iscase) {
					push(@$out, "\n");
					$iscase = 0;
					$tabs++;
					$spc .= "\t";
					last STMT;
				}
			}
			$lastval = $val;
			$val = shift @$in;

			if (defined $val && ($val eq '}')) {
				if ($varblk == 0) {
					return;
				}
				$varblk--;
			}
			if (defined $val && ($val eq ')')) {
				$exprblk--;
			}
		}
	}
	return;
}

sub insert_blanks {
	my ($in) = @_;
	my @out = ();
	my $lastval;

	while (1) {
		my $val = shift @$in;
		if (!defined $val) {
			last;
		}
		# - no blanks in parenthesis or square brackets
		# - blank after semicolon or comma
		# - blank after most php keywords
		# - no blank after function calls
		# - no blank after unary ops
		# - no blank in pre/post inc/decrement
		# - no blank in object/scope reference
		#
		if (defined $lastval && ($lastval ne "\n") && ($lastval !~ /^\t*$/)) { # zero or more tabs
			if ($val !~ /^(\[|\]|\(|\)|\;|\,|\\n|->|::)$/) {
				if ($lastval !~ /^(\[|\(|\!|\~|->|::)$/) {
					unless ((($val eq '++') || ($val eq '--')) && is_strict_variable($lastval)) {
						push(@out, ' ');
					}
				}
			} elsif (($val eq '(') && exists $php_keywords{lc($lastval)}) {
				unless ($lastval =~ /^(array|empty|isset|unset|list)$/) {
					push(@out, ' ');
				}
			} elsif (($val eq '(') && !is_symbol($lastval) && ($lastval !~ /^(\[|\]|\(|\))$/)) {
				push(@out, ' ');
			}
		}
		push(@out, $val);
		$lastval = $val;
	}
	return @out;
}

# convert statements to code (flags are optional)
# {indent}          - output indented multiline code
# {unified}         - unified #str/#num output
# {mask_eval}       - mask eval in strings with pattern
# {escape_ctrl}     - escape control characters in output strings
# {avoid_semicolon} - avoid semicolons after braces
# {max_strlen}      - max length for strings in output
#
sub format_stmt {
	my ($self, $line, $fmt) = @_;
	my @out = ();
	$fmt = {} unless defined $fmt;

	$self->expand_stmt(\@out, $line, $fmt);

	if (!$fmt->{avoid_semicolon} && (scalar @out > 0) && ($out[-1] ne '}') && ($out[-1] ne ';')) {
		push(@out, ';');
	}
	if (exists $fmt->{indent}) {
		my @tmp = ();
		expand_formatted(\@tmp, \@out, 0);
		return join('', insert_blanks(\@tmp));
	}
	return join(' ', @out);
}

use constant HINT_ASSIGN => 0x10000; # variable is assigned to
use constant HINT_UNSET  => 0x20000; # variable is unset

# if expression in block contains an unresolvable variable, then return it
#
sub stmt_info {
	my ($self, $s, $info, $hint) = @_;

	if ($s =~ /^#blk\d+$/) {
		my ($type, $a) = @{$self->{strmap}->{$s}};
		foreach my $stmt (@$a) {
			$self->stmt_info($stmt, $info);
		}
	#} elsif ($s =~ /^#num\d+$/) {
	#	my $v = $self->{strmap}->{$s};
	#	$info->{nums}{$s} = $v; 
	#} elsif ($s =~ /^#str\d+$/) {
	#	my $v = $self->{strmap}->{$s};
	#	$info->{strs}{$s} = $v; 
	} elsif ($s =~ /^#const\d+$/) {
		$s = $self->{strmap}->{$s};
		$info->{consts}{$s} = 1; 
	} elsif ($s =~ /^#arr\d+$/) {
		my $arr = $self->{strmap}{$s};
		my $keys = $arr->get_keys();
		my $haskey = 0;

		foreach my $k (@$keys) {
			my $val = $arr->val($k);
			unless (is_int_index($k)) {
				$self->stmt_info($k, $info);
			}
			if (defined $val) {
				$self->stmt_info($val, $info);
				$haskey = 1;
			}
		}
		if ($haskey) {
			$info->{arrays}{$s} = 'map';
		} else {
			$info->{arrays}{$s} = 'array';
		}
	} elsif ($s =~ /^#fun\d+$/) {
		my ($f, $a, $b, $p) = @{$self->{strmap}->{$s}};
		if (defined $f) {
			$info->{funcs}{$f} = 1;
		} else {
			$info->{funcs}{$s} = 1; # anon func
		}
	} elsif ($s =~ /^#expr\d+$/) {
		my ($op, $v1, $v2) = @{$self->{strmap}->{$s}};
		if (defined $v1) {
			if (($op eq '=') && ($v1 =~ /^#elem\d+$/) && defined $v2) {
				my ($v, $i) = @{$self->{strmap}->{$v1}};

				unless (defined $i) {
					$self->stmt_info($v1, $info, T_ARRAY|HINT_ASSIGN);
				} else {
					$self->stmt_info($v1, $info, HINT_ASSIGN);
				}
			} elsif (($op eq '=') && defined $v2 && ($v2 =~ /^#call\d+$/)) {
				my ($f, $a) = @{$self->{strmap}->{$v2}};

				if ($f eq 'range') {
					$self->stmt_info($v1, $info, T_ARRAY|HINT_ASSIGN);
				} else {
					$self->stmt_info($v1, $info, HINT_ASSIGN);
				}
			} elsif (($op eq '=') && defined $v2) {
				$self->stmt_info($v1, $info, HINT_ASSIGN);
			} elsif ($op eq '.') {
				$self->stmt_info($v1, $info, T_STR);
			} elsif (($op eq '++') || ($op eq '--')) {
				$self->stmt_info($v1, $info, HINT_ASSIGN);
			} else {
				$self->stmt_info($v1, $info);
			}
			if ($op eq '=') {
				my $vb = $self->elem_base($v1);
				$info->{assigns}{$vb} = 1;
			} elsif ($op eq '++') {
				my $vb = $self->elem_base($v1);
				$info->{assigns}{$vb} = 1;
			} elsif ($op eq '--') {
				my $vb = $self->elem_base($v1);
				$info->{assigns}{$vb} = 1;
			}
		}
		if (defined $v2) {
			if ($op eq '.') {
				$self->stmt_info($v2, $info, T_STR);
			} elsif (($op eq '++') || ($op eq '--')) {
				$self->stmt_info($v2, $info, HINT_ASSIGN);
			} else {
				$self->stmt_info($v2, $info);
			}
			if ($op eq '++') {
				my $vb = $self->elem_base($v2);
				$info->{assigns}{$vb} = 1;
			} elsif ($op eq '--') {
				my $vb = $self->elem_base($v2);
				$info->{assigns}{$vb} = 1;
			}
		}
	} elsif ($s =~ /^#elem\d+$/) {
		my ($v, $i) = @{$self->{strmap}->{$s}};
		if (defined $v) {
			my $hint_assign = 0;
			$hint_assign = HINT_ASSIGN if (defined $hint && ($hint & HINT_ASSIGN));
			if (defined $i) {
				$self->stmt_info($v, $info, $hint_assign);
			} else {
				$self->stmt_info($v, $info, T_STR|T_ARRAY|$hint_assign);
			}
		}
		if (defined $i) {
			$self->stmt_info($i, $info);

			# add resolvable globals
			#
			my $g = $self->globalvar_to_var($v, $i);
			if (defined $g) {
				$info->{globals}{$g} = 1;
			}
		}
	} elsif ($s =~ /^#obj\d+$/) {
		my ($o, $m) = @{$self->{strmap}->{$s}};
		if (lc($o) ne '$this') {
			$self->stmt_info($o, $info);
		}
		if (defined $m) {
			$self->stmt_info($m, $info);
		}
	} elsif ($s =~ /^#inst\d+$/) {
		my ($c, $f, $i) = @{$self->{strmap}->{$s}};
		if (defined $c) {
			$self->stmt_info($c, $info);
		}
	} elsif ($s =~ /^#scope\d+$/) {
		my ($c, $e) = @{$self->{strmap}->{$s}};
		if (defined $e) {
			$self->stmt_info($e, $info);
		}
	} elsif ($s =~ /^#ns\d+$/) {
		my ($n, $e) = @{$self->{strmap}->{$s}};
		if (defined $e) {
			$self->stmt_info($e, $info);
		}
	} elsif ($s =~ /^#ref\d+$/) {
		my $v = $self->{strmap}->{$s}->[0];
		if (defined $v) {
			$self->stmt_info($v, $info);
		}
	} elsif ($s =~ /^#call\d+$/) {
		my ($f, $a) = @{$self->{strmap}->{$s}};
		my $narg = scalar @$a;
		if (exists $info->{state} && $info->{state}) {
			$info->{calls}{$f} = $info->{state}; 
		} else {
			$info->{calls}{$f} = 1; 
		}
		$info->{callargs}{$f}{$narg} = 1; # track args count

		foreach my $k (@$a) {
			if ($f eq 'strlen') {
				$self->stmt_info($k, $info, T_STR);
			} elsif ($f eq 'base64_decode') {
				$self->stmt_info($k, $info, T_STR);
			} elsif ($f eq 'gzinflate') {
				$self->stmt_info($k, $info, T_STR);
			} else {
				$self->stmt_info($k, $info);
			}
		}
	} elsif ($s =~ /^#pfx\d+$/) {
		my $pfx = $self->{strmap}->{$s};
	} elsif ($s =~ /^#class\d+$/) {
		my ($c, $b, $p) = @{$self->{strmap}->{$s}};
		$info->{classes}{$c} = 1;
	} elsif ($s =~ /^#trait\d+$/) {
		my ($t, $b) = @{$self->{strmap}->{$s}};
		$info->{traits}{$t} = 1;
	} elsif ($s =~ /^#fh\d+$/) {
		my $f = $self->{strmap}->{$s}{name};
		my $m = $self->{strmap}->{$s}{mode};
		my $p = $self->{strmap}->{$s}{pos};
		$info->{fhs}{$f} = 1;
	} elsif ($s =~ /^#stmt\d+$/) {
		my $cmd = $self->{strmap}->{$s}->[0];
		if ($cmd eq 'echo') {
			my $a = $self->{strmap}->{$s}->[1];
			foreach my $k (@$a) {
				$self->stmt_info($k, $info);
			}
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'print') {
			my $arg = $self->{strmap}->{$s}->[1];
			$self->stmt_info($arg, $info);
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'namespace') {
			my ($arg, $block) = @{$self->{strmap}->{$s}}[1..2];
			if (defined $block) {
				$self->stmt_info($block, $info);
			}
			$info->{stmts}{$s} = 1;
		} elsif ($cmd =~ /^(include|include_once|require|require_once)$/) {
			my $arg = $self->{strmap}->{$s}->[1];
			$info->{includes}{$arg} = 1;
			$self->stmt_info($arg, $info);
		} elsif ($cmd eq 'use') {
			my $a = $self->{strmap}->{$s}->[1];
			foreach my $v (@$a) {
				$self->stmt_info($v, $info);
			}
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'global') {
			my $a = $self->{strmap}->{$s}->[1];
			foreach my $v (@$a) {
				$info->{globals}{$v} = 1;
				$self->stmt_info($v, $info);
			}
		} elsif ($cmd eq 'static') {
			my $a = $self->{strmap}->{$s}->[1];
			foreach my $v (@$a) {
				$info->{statics}{$v} = 1;
				$self->stmt_info($v, $info);
			}
		} elsif ($cmd eq 'const') {
			my $a = $self->{strmap}->{$s}->[1];
			foreach my $v (@$a) {
				$info->{const}{$v} = 1;
				$self->stmt_info($v, $info);
			}
		} elsif ($cmd eq 'unset') {
			my $a = $self->{strmap}->{$s}->[1];
			foreach my $v (@$a) {
				$info->{assigns}{$v} = 1;
				$self->stmt_info($v, $info, HINT_ASSIGN|HINT_UNSET);
			}
		} elsif ($cmd eq 'return') {
			my $a = $self->{strmap}->{$s}->[1];
			my $old;
			$old = $info->{state} if exists $info->{state};
			$info->{state} = 'return';
			$self->stmt_info($a, $info);
			$info->{state} = $old;
			$info->{returns}{$a} = 1;
		} elsif ($cmd eq 'goto') {
			my $arg = $self->{strmap}->{$s}->[1];
			$self->stmt_info($arg, $info);
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'label') {
			my $arg = $self->{strmap}->{$s}->[1];
			$self->stmt_info($arg, $info);
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'throw') {
			my $arg = $self->{strmap}->{$s}->[1];
			$self->stmt_info($arg, $info);
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'if') {
			my ($cond, $then, $else) = @{$self->{strmap}->{$s}}[1..3];

			$self->stmt_info($cond, $info);
			$self->stmt_info($then, $info);
			if (defined $else) {
				$self->stmt_info($else, $info);
			}
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'while') {
			my ($cond, $block) = @{$self->{strmap}->{$s}}[1..2];

			$self->stmt_info($cond, $info);
			$self->stmt_info($block, $info);
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'do') {
			my ($cond, $block) = @{$self->{strmap}->{$s}}[1..2];

			$self->stmt_info($block, $info);
			$self->stmt_info($cond, $info);
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'for') {
			my ($pre, $cond, $post, $block) = @{$self->{strmap}->{$s}}[1..4];

			$self->stmt_info($pre, $info);
			$self->stmt_info($cond, $info);
			$self->stmt_info($post, $info);
			$self->stmt_info($block, $info);
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'foreach') {
			my ($expr, $key, $value, $block) = @{$self->{strmap}->{$s}}[1..4];

			$self->stmt_info($expr, $info);
			if (defined $key) {
				$self->stmt_info($key, $info);
				$info->{assigns}{$key} = 1;
			}
			$self->stmt_info($value, $info);
			$info->{assigns}{$value} = 1;
			$self->stmt_info($block, $info);
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'switch') {
			my ($expr, $cases) = @{$self->{strmap}->{$s}}[1..2];

			$self->stmt_info($expr, $info);
			foreach my $e (@$cases) {
				my $c = $e->[0];
				my $b = $e->[1];
				if (defined $c) {
					$self->stmt_info($c, $info);
				}
				$self->stmt_info($b, $info);
			}
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'case') {
			my $expr = $self->{strmap}->{$s}->[1];
			if (defined $expr) {
				$self->stmt_info($expr, $info);
			}
		} elsif ($cmd eq 'try') {
			my ($try, $catches, $finally) = @{$self->{strmap}->{$s}}[1..3];

			$self->stmt_info($try, $info);
			foreach my $c (@$catches) {
				my $e = $c->[0];
				my $b = $c->[1];
				$self->stmt_info($e, $info);
				$self->stmt_info($b, $info);
			}
			if (defined $finally) {
				$self->stmt_info($finally, $info);
			}
			$info->{stmts}{$s} = 1;
		} elsif ($cmd eq 'break') {
			$info->{breaks}{$s} = 1;
		} elsif ($cmd eq 'continue') {
			$info->{continues}{$s} = 1;
		}
	} elsif (is_variable($s)) {
		my ($global) = global_split($s);
		if (defined $global) {
			$info->{globals}{$global} = 1; 
		} else {
			if (defined $hint) {
				$info->{vars}{$s} |= ($hint & T_MASK);
				$info->{noassigns}{$s} |= ($hint & T_MASK) unless ($hint & HINT_ASSIGN);
			} else {
				$info->{vars}{$s} |= 0;
				$info->{noassigns}{$s} |= 0;
			}
		}
	}
	return;
}

sub translate_stmt {
	my ($self, $out, $s, $info) = @_;

	#$self->{log}->('TRANSLATE', "$s") if $self->{log};

	if (!defined $s) {
		$self->{warn}->('translate', "undefined symbol");
		return;
	} elsif ($s =~ /^#null$/) {
		push(@$out, 'undef');
	} elsif ($s =~ /^#num\d+$/) {
		unless (exists $self->{strmap}->{$s}) {
			$self->{warn}->('translate', "num $s not found");
			return;
		}
		$s = $self->{strmap}->{$s};
		push(@$out, $s);
	} elsif ($s =~ /^#const\d+$/) {
		unless (exists $self->{strmap}->{$s}) {
			$self->{warn}->('translate', "bad const $s");
			return;
		}
		$s = $self->{strmap}->{$s};
		unless (is_symbol($s)) {
			$self->{warn}->('translate', "bad const name $s");
			return;
		}
		push(@$out, '$'.$s); # convert to var
	} elsif ($s =~ /^#str\d+$/) {
		unless (exists $self->{strmap}->{$s}) {
			$self->{warn}->('translate', "bad str $s");
			return;
		}
		$s = $self->{strmap}->{$s};
		# escape string (keep newlines as newline like php does)
		#
		$s =~ s/\\/\\\\/sg;
		$s =~ s/'/\\'/sg;
		$s = '\'' . $s . '\'';
		push(@$out, $s);
	} elsif ($s =~ /^#arr\d+$/) {
		my $arr = $self->{strmap}{$s};
		my $keys = $arr->get_keys();
		push(@$out, '{');

		foreach my $k (@$keys) {
			my $val = $arr->val($k);
			if (is_int_index($k)) {
				push(@$out, $k);
			} else {
				return unless $self->translate_stmt($out, $k, $info);
			}
			push(@$out, '=>');
			if (defined $val) {
				return unless $self->translate_stmt($out, $val, $info);
			} else {
				push(@$out, 'undef');
			}
			push(@$out, ',');
		}
		if (scalar @$keys > 0) {
			pop(@$out);
		}
		push(@$out, '}');
	} elsif ($s =~ /^#fun\d+$/) {
		my ($f, $a, $b, $p) = @{$self->{strmap}->{$s}};

		push(@$out, 'sub');
		if (defined $f) {
			unless (is_symbol($f)) {
				$self->{warn}->('translate', "bad func name $s $f not supported");
				return;
			}
			$self->{warn}->('translate', "func in func $s $f not supported");
			return;
			#push(@$out, $f);
		}
		push(@$out, '{');
		if (scalar @$a > 0) {
			push(@$out, 'my');
			push(@$out, '(');
			foreach my $k (@$a) {
				return unless $self->translate_stmt($out, $k, $info);
				push(@$out, ',');
			}
			pop(@$out);
			push(@$out, ')');
			push(@$out, '=');
			push(@$out, '@_');
			push(@$out, ';');
		}
		# TODO: don't pass local func info from outside
		#
		if (keys %{$info->{locals}} > 0) {
			push(@$out, 'my');
			push(@$out, '(');
			foreach my $k (keys %{$info->{locals}}) {
				return unless $self->translate_stmt($out, $k, $info);
				push(@$out, ',');
			}
			pop(@$out);
			push(@$out, ')');
			push(@$out, ';');
		}
		#$self->translate_stmt($out, $b, $info);

		my ($type, $c) = @{$self->{strmap}->{$b}};
		foreach my $k (@$c) {
			return unless $self->translate_stmt($out, $k, $info);
			#if ($out->[-1] ne '}') {
				push(@$out, ';');
			#}
		}
		push(@$out, '}');
	} elsif ($s =~ /^#call\d+$/) {
		my ($f, $a) = @{$self->{strmap}->{$s}};

		unless (is_symbol($f)) {
			$self->{warn}->('translate', "call name $s $f not supported");
			return;
		}
		if (($f eq 'strlen') && (scalar @$a == 1)) {
			push(@$out, 'length');
		} elsif (($f eq 'isset') && (scalar @$a == 1)) {
			push(@$out, 'defined');
		} elsif (($f eq 'range') && (scalar @$a == 2)) {
			push(@$out, '[');
			return unless $self->translate_stmt($out, $a->[0], $info);
			push(@$out, '..');
			return unless $self->translate_stmt($out, $a->[1], $info);
			push(@$out, ']');
			return 1;
		} elsif (($f eq 'base64_encode') && (scalar @$a == 1)) {
			# encode_base64($s,'')
			push(@$out, 'encode_base64');
			push(@$out, '(');
			return unless $self->translate_stmt($out, $a->[0], $info);
			push(@$out, ',');
			push(@$out, '\'\'');
			push(@$out, ')');
			return 1;
		} elsif (($f eq 'base64_decode') && (scalar @$a == 1)) {
			# decode_base64($s)
			push(@$out, 'decode_base64');
			push(@$out, '(');
			return unless $self->translate_stmt($out, $a->[0], $info);
			push(@$out, ')');
			return 1;
		} elsif (($f eq 'gzinflate') && (scalar @$a == 1)) {
			# (Compress::Zlib::inflateInit(-WindowBits => -(MAX_WBITS))->inflate($s))[0])
			push(@$out, '(');
			push(@$out, 'Compress::Zlib::inflateInit(-WindowBits => -(MAX_WBITS))->inflate');
			push(@$out, '(');
			return unless $self->translate_stmt($out, $a->[0], $info);
			push(@$out, ')');
			push(@$out, ')');
			push(@$out, '[');
			push(@$out, '0');
			push(@$out, ']');
			return 1;
		} elsif (($f =~ /^(chr|ord)$/) && (scalar @$a == 1)) {
			push(@$out, $f);
		} else {
			$self->{warn}->('translate', "call $s $f not supported");
			return;
		}
		push(@$out, '(');
		foreach my $k (@$a) {
			return unless $self->translate_stmt($out, $k, $info);
			push(@$out, ',');
		}
		if (scalar @$a > 0) {
			pop(@$out);
		}
		push(@$out, ')');
	} elsif ($s =~ /^#elem\d+$/) {
		my ($v, $i) = @{$self->{strmap}->{$s}};

		if (exists $info->{vars}{$v} && (($info->{vars}{$v} & T_MASK) == T_STR)) {
			push(@$out, 'substr');
			push(@$out, '(');
			return unless $self->translate_stmt($out, $v, $info);
			push(@$out, ',');
			if (defined $i) {
				return unless $self->translate_stmt($out, $i, $info);
				push(@$out, ',');
				push(@$out, '1');
			} else {
				push(@$out, '-1');
			}
			push(@$out, ')');
			return 1;
		}
		return unless $self->translate_stmt($out, $v, $info);
		push(@$out, '->');
		if (exists $info->{vars}{$v} && (($info->{vars}{$v} & T_MASK) == T_ARRAY)) {
			push(@$out, '[');
			if (defined $i) {
				return unless $self->translate_stmt($out, $i, $info);
			}
			push(@$out, ']');
		} else {
			push(@$out, '{');
			if (defined $i) {
				return unless $self->translate_stmt($out, $i, $info);
			}
			push(@$out, '}');
		}
	} elsif ($s =~ /^#expr\d+$/) {
		my ($op, $v1, $v2) = @{$self->{strmap}->{$s}};

		if (defined $v1) {
			if ($v1 =~ /^#expr\d+$/) {
				my $vop = $self->{strmap}->{$v1}->[0];
				if (($op ne '=') && ($op ne $vop)) {
					push(@$out, '(');
				}
				return unless $self->translate_stmt($out, $v1, $info);
				if (($op ne '=') && ($op ne $vop)) {
					push(@$out, ')');
				}
			} elsif (($v1 =~ /^#elem\d+$/) && defined $v2 && ($op eq '=')) {
				my $v = $self->{strmap}->{$v1}->[0];
				my $i = $self->{strmap}->{$v1}->[1];
				unless (defined $i && is_strict_variable($v)) {
				    # try to emulate php-arrays with perl-maps
				    # see: https://www.php.net/manual/en/language.types.array.php
				    # - if no key is specified, the maximum of the existing int
				    #   indices is taken, and the new key will be that maximum
				    #   value plus 1 (but at least 0).
				    # - If no int indices exist yet, the key will be 0 (zero).
				    #
				    # TODO: Note that the maximum integer key used for this
				    #       need not currently exist in the array. It need only
				    #       have existed in the array at some time since the
				    #       last time the array was re-indexed.
				    #
				    if (exists $info->{vars}{$v} && (($info->{vars}{$v} && T_MASK) == T_ARRAY)) {
					# for 'array' convert '$x[] = $v' to:
					# push(@{$x}, $v)
					#
					push(@$out, 'push');
					push(@$out, '(');
					push(@$out, '@');
					push(@$out, '{');
					return unless $self->translate_stmt($out, $v, $info);
					push(@$out, '}');
					push(@$out, ',');
					return unless $self->translate_stmt($out, $v2, $info);
					push(@$out, ')');
					return 1;
				    } else {
					# for 'map' convert '$x[] = $v' to:
					# $x->{(max keys %$x)[-1] + 1} = $v
					# (or: $x->{keys %$x ? (sort keys %$x)[-1] + 1 : 0} = $v)
					#
					return unless $self->translate_stmt($out, $v, $info);
					my $vx = $out->[-1];
					push(@$out, '->');
					push(@$out, '{');
					push(@$out, '(');
					push(@$out, 'max');
					push(@$out, 'keys');
					push(@$out, '%'.$vx);
					push(@$out, ')');
					push(@$out, '[');
					push(@$out, '-1');
					push(@$out, ']');
					push(@$out, '+');
					push(@$out, '1');
					push(@$out, '}');
				    }
				} else {
					return unless $self->translate_stmt($out, $v1, $info);
				}
			} else {
				return unless $self->translate_stmt($out, $v1, $info);
			}
		}
		if ($op eq '==') {
			push(@$out, 'eq');
		} elsif ($op eq '!=') {
			push(@$out, 'ne');
		} else {
			push(@$out, $op);
		}
		if (defined $v2) {
			if ($op eq '$') {
				push(@$out, '{');
			}
			if ($v2 =~ /^#expr\d+$/) {
				my $vop = $self->{strmap}->{$v2}->[0];
				if (($op ne '?') && ($op ne '=') && ($op ne $vop)) {
					push(@$out, '(');
				}
				return unless $self->translate_stmt($out, $v2, $info);
				if (($op ne '?') && ($op ne '=') && ($op ne $vop)) {
					push(@$out, ')');
				}
			} else {
				return unless $self->translate_stmt($out, $v2, $info);
			}
			if ($op eq '$') {
				push(@$out, '}');
			}
		}
	} elsif ($s =~ /^#pfx\d+$/) {
		unless (exists $self->{strmap}->{$s}) {
			$self->{warn}->('translate', "pfx $s not found");
			return;
		}
		my $pfx = $self->{strmap}->{$s};
		if (exists $pfx->{global}) {
			my $s = join(' ', sort keys %$pfx);
			$self->{warn}->('translate', "global pfx $s");
			return;
		}
		push(@$out, 'my');
	} elsif ($s =~ /^#obj\d+$/) {
		my ($o, $m) = @{$self->{strmap}->{$s}};

		$self->{warn}->('translate', "obj $s $o->$m not supported");
		return;
	} elsif ($s =~ /^#scope\d+$/) {
		my ($c, $e) = @{$self->{strmap}->{$s}};

		$self->{warn}->('translate', "scope $s $c::$e not supported");
		return;
	} elsif ($s =~ /^#ns\d+$/) {
		my ($n, $e) = @{$self->{strmap}->{$s}};

		$self->{warn}->('translate', "namespace $s $n::$e not supported");
		return;
	} elsif ($s =~ /^#inst\d+$/) {
		my ($c, $f, $i) = @{$self->{strmap}->{$s}};

		$self->{warn}->('translate', "new inst $s $f not supported");
		return;
	} elsif ($s =~ /^#ref\d+$/) {
		my $v = $self->{strmap}->{$s}->[0];
		push(@$out, '\\');
		return unless $self->translate_stmt($out, $v, $info);
	} elsif ($s =~ /^#class\d+$/) {
		my ($c, $b, $p) = @{$self->{strmap}->{$s}};

		$self->{warn}->('translate', "class $s $c not supported");
		return;
	} elsif ($s =~ /^#trait\d+$/) {
		my ($t, $b) = @{$self->{strmap}->{$s}};

		$self->{warn}->('translate', "trait $s $t not supported");
		return;
	} elsif ($s =~ /^#fh\d+$/) {
		my $f = $self->{strmap}->{$s}{name};
		my $m = $self->{strmap}->{$s}{mode};
		my $p = $self->{strmap}->{$s}{pos};

		$self->{warn}->('translate', "fh $s $f not supported");
		return;
	} elsif ($s =~ /^#blk\d+$/) {
		my ($type, $a) = @{$self->{strmap}->{$s}};

		if ($type eq 'expr') {
			foreach my $k (@$a) {
				return unless $self->translate_stmt($out, $k, $info);
				push(@$out, ',');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
		} elsif ($type eq 'flat') {
			foreach my $k (@$a) {
				return unless $self->translate_stmt($out, $k, $info);
				if ($k =~ /^#pfx\d+$/) {
					next; # avoid ;
				}
				if ($out->[-1] ne '}') {
					push(@$out, ';');
				}
			}
			if ((scalar @$a > 0) && ($out->[-1] eq ';')) {
				pop(@$out);
			}
		} elsif ($type eq 'case') {
			foreach my $k (@$a) {
				return unless $self->translate_stmt($out, $k, $info);
				push(@$out, ';');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
		} elsif ($type eq 'brace') {
			if (scalar @$a == 1) {
				return unless $self->translate_stmt($out, $a->[0], $info);
			} else {
				push(@$out, '(');
				foreach my $k (@$a) {
					return unless $self->translate_stmt($out, $k, $info);
					if ($out->[-1] ne ')') {
						push(@$out, ';');
					}
				}
				if ((scalar @$a > 0) && ($out->[-1] eq ';')) {
					pop(@$out);
				}
				push(@$out, ')');
			}
		} else {
			push(@$out, '{');
			foreach my $k (@$a) {
				return unless $self->translate_stmt($out, $k, $info);
				if ($k =~ /^#pfx\d+$/) {
					next; # avoid ;
				}
				if ($out->[-1] ne '}') {
					push(@$out, ';');
				}
			}
			if ((scalar @$a > 0) && ($out->[-1] eq ';')) {
				pop(@$out);
			}
			push(@$out, '}');
		}
	} elsif ($s =~ /^#stmt\d+$/) {
		my $cmd = $self->{strmap}->{$s}->[0];
		if ($cmd eq 'echo') {
			my $a = $self->{strmap}->{$s}->[1];
			push(@$out, 'print');
			foreach my $k (@$a) {
				return unless $self->translate_stmt($out, $k, $info);
				push(@$out, ',');
			}
			if (scalar @$a > 0) {
				pop(@$out);
			}
		} elsif ($cmd eq 'print') {
			my $arg = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			return unless $self->translate_stmt($out, $arg, $info);
		} elsif ($cmd eq 'namespace') {
			my ($a, $block) = @{$self->{strmap}->{$s}}[1..2];
			$self->{warn}->('translate', "namespace $s $a not supported");
			return;
		} elsif ($cmd =~ /^(include|include_once|require|require_once)$/) {
			my $arg = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			return unless $self->translate_stmt($out, $arg, $info);
		} elsif ($cmd eq 'use') {
			my $a = $self->{strmap}->{$s}->[1];
			$self->{warn}->('translate', "use $s not supported");
			return;
		} elsif ($cmd eq 'global') {
			my $a = $self->{strmap}->{$s}->[1];
			$self->{warn}->('translate', "global $s not supported");
			return;
		} elsif ($cmd eq 'static') {
			my $a = $self->{strmap}->{$s}->[1];
			$self->{warn}->('translate', "static $s not supported");
			return;
		} elsif ($cmd eq 'const') {
			my $a = $self->{strmap}->{$s}->[1];
			$self->{warn}->('translate', "const $s not supported");
			return;
		} elsif ($cmd eq 'unset') {
			my $a = $self->{strmap}->{$s}->[1];
			$self->{warn}->('translate', "unset $s not supported");
			return;
		} elsif ($cmd eq 'return') {
			my $a = $self->{strmap}->{$s}->[1];
			push(@$out, $cmd);
			return unless $self->translate_stmt($out, $a, $info);
		} elsif ($cmd eq 'goto') {
			my $a = $self->{strmap}->{$s}->[1];
			$self->{warn}->('translate', "goto $s not supported");
			return;
		} elsif ($cmd eq 'label') {
			my $a = $self->{strmap}->{$s}->[1];
			$self->{warn}->('translate', "label $s not supported");
			return;
		} elsif ($cmd eq 'if') {
			my ($cond, $then, $else) = @{$self->{strmap}->{$s}}[1..3];

			push(@$out, $cmd);
			push(@$out, '(');
			return unless $self->translate_stmt($out, $cond, $info);
			push(@$out, ')');
			return unless $self->translate_stmt($out, $then, $info);
			if (defined $else) {
				push(@$out, 'else');
				return unless $self->translate_stmt($out, $else, $info);
			}
		} elsif ($cmd eq 'while') {
			my ($cond, $block) = @{$self->{strmap}->{$s}}[1..2];

			push(@$out, $cmd);
			push(@$out, '(');
			return unless $self->translate_stmt($out, $cond, $info);
			push(@$out, ')');
			return unless $self->translate_stmt($out, $block, $info);
		} elsif ($cmd eq 'do') {
			my ($cond, $block) = @{$self->{strmap}->{$s}}[1..2];

			push(@$out, $cmd);
			return unless $self->translate_stmt($out, $block, $info);
			push(@$out, 'while');
			push(@$out, '(');
			return unless $self->translate_stmt($out, $cond, $info);
			push(@$out, ')');
		} elsif ($cmd eq 'for') {
			my ($pre, $cond, $post, $block) = @{$self->{strmap}->{$s}}[1..4];

			push(@$out, $cmd);
			push(@$out, '(');
			#push(@$out, 'my'); # set as local -> persists after for-loop
			return unless $self->translate_stmt($out, $pre, $info);
			push(@$out, ';');
			return unless $self->translate_stmt($out, $cond, $info);
			push(@$out, ';');
			return unless $self->translate_stmt($out, $post, $info);
			push(@$out, ')');
			return unless $self->translate_stmt($out, $block, $info);
		} elsif ($cmd eq 'foreach') {
			my ($expr, $key, $value, $block) = @{$self->{strmap}->{$s}}[1..4];

			if (defined $key) {
				# convert 'foreach ($x as $k => $v)' to
				# foreach my $k ( sort { $a <=> $b } keys %$x ) { my $v = $x->{$k}; .. }
				#
				push(@$out, 'foreach');
				#push(@$out, 'my');
				return unless $self->translate_stmt($out, $key, $info);
				push(@$out, '(');
				push(@$out, 'sort');
				push(@$out, '{');
				push(@$out, '$a');
				push(@$out, '<=>');
				push(@$out, '$b');
				push(@$out, '}');
				push(@$out, 'keys');
				push(@$out, '%');
				push(@$out, '{');
				return unless $self->translate_stmt($out, $expr, $info);
				push(@$out, '}');
				push(@$out, ')');
				push(@$out, '{');

				#push(@$out, 'my');
				return unless $self->translate_stmt($out, $value, $info);
				push(@$out, '=');
				return unless $self->translate_stmt($out, $expr, $info);
				push(@$out, '->');
				push(@$out, '{');
				return unless $self->translate_stmt($out, $key, $info);
				push(@$out, '}');
				push(@$out, ';');

				my $type = $self->{strmap}->{$block}->[1];
				my $c = $self->{strmap}->{$block}->[2];
				foreach my $k (@$c) {
					return unless $self->translate_stmt($out, $k, $info);
					#if ($out->[-1] ne '}') {
						push(@$out, ';'); # might follow {} after map define/deref
					#}
				}
				push(@$out, '}');
				return 1;
			} else {
				push(@$out, $cmd);
				push(@$out, 'my');
				return unless $self->translate_stmt($out, $value, $info);
				push(@$out, '(');
				return unless $self->translate_stmt($out, $expr, $info);
				push(@$out, ')');
			}
			return unless $self->translate_stmt($out, $block, $info);
		} elsif ($cmd eq 'switch') {
			my ($expr, $cases) = @{$self->{strmap}->{$s}}[1..2];
			my $first = 1;

			foreach my $e (@$cases) {
				my $c = $e->[0];
				my $b = $e->[1];
				if (!defined $c) {
					if ($first) {
						$self->{warn}->('translate', "bad switch $s");
						return;
					}
					push(@$out, 'else');
				} else {
					if ($first) {
						push(@$out, 'if');
						$first = 0;
					} else {
						push(@$out, 'elsif');
					}
					push(@$out, '(');
					return unless $self->translate_stmt($out, $expr, $info);
					push(@$out, '==');
					push(@$out, '(');
					return unless $self->translate_stmt($out, $c, $info);
					push(@$out, ')');
					push(@$out, ')');
				}
				push(@$out, '{');
				return unless $self->translate_stmt($out, $b, $info);
				push(@$out, '}');
			}
		} elsif ($cmd eq 'break') {
			push(@$out, 'last');
		} elsif ($cmd eq 'continue') {
			push(@$out, 'next');
		} else {
			$self->{warn}->('translate', "bad statement $s");
			return;
		}
	} elsif (is_variable($s)) {
		my ($global) = global_split($s);
		if (defined $global) {
			$self->{warn}->('translate', "global $s not supported");
			return;
		}
		unless (is_symbol($s)) {
			$self->{warn}->('translate', "bad var name $s not supported");
			return;
		}
		push(@$out, $s);
	} else {
		$self->{warn}->('translate', "bad symbol $s not supported");
		return;
	}
	return 1;
}

sub translate_func {
	my ($self, $s, $maxlen, $format) = @_;
	my @out = ();

	unless ($s =~ /^#fun\d+$/) {
		$self->{warn}->('translate', "no func $s");
		return;
	}
	# create anonymous subroutine here
	#
	my ($f, $a, $b, $p) = @{$self->{strmap}->{$s}};
	$f = $self->setfun(undef, $a, $b, $p);

	my $info = {args => {}, vars => {}, locals => {}, globals => {}, calls => {}, returns => {}};
	$self->stmt_info($b, $info);

	if (scalar @$a > 0) {
		foreach my $v (@$a) {
			$info->{args}{$v} = 0;
		}
		foreach my $v (keys %{$info->{vars}}) {
			$info->{locals}{$v} |= $info->{vars}{$v} unless exists $info->{args}{$v};
		}
		foreach my $v (keys %{$info->{args}}) {
			$info->{vars}{$v} |= $info->{args}{$v} unless exists $info->{vars}{$v};
		}
	} else {
		$info->{locals} = $info->{vars};
	}
	if (keys %{$info->{args}}) {
		$self->{log}->('translate', "local args: %s", join(' ', map { ($info->{vars}{$_} ne '1') ? "$_:$info->{vars}{$_}" : $_ } keys %{$info->{args}})) if $self->{log};
	}
	if (keys %{$info->{locals}}) {
		$self->{log}->('translate', "local vars: %s", join(' ', map { ($info->{vars}{$_} ne '1') ? "$_:$info->{vars}{$_}" : $_ } keys %{$info->{locals}})) if $self->{log};
	}
	if (keys %{$info->{globals}}) {
		$self->{log}->('translate', "globals: %s", join(' ', keys %{$info->{globals}})) if $self->{log};
	}
	if (keys %{$info->{calls}}) {
		$self->{log}->('translate', "calls: %s", join(' ', keys %{$info->{calls}})) if $self->{log};
	}
	if (keys %{$info->{returns}}) {
		$self->{log}->('translate', "returns: %s", join(' ', keys %{$info->{returns}})) if $self->{log};
	} else {
		$self->{warn}->('translate', "no return for func $s");
		return;
	}

	unless ($self->translate_stmt(\@out, $f, $info)) {
		return;
	}

	if ($format) {
		my @tmp = ();
		expand_formatted(\@tmp, \@out, 0);
		return join(' ', @tmp);
	}
	return join(' ', @out);
}

1;

__END__

=head1 NAME

PHP::Decode::Parser

=head1 SYNOPSIS

  # Create an instance

  sub warn_msg {
	my ($action, $fmt) = (shift, shift);
	my $msg = sprintf $fmt, @_;
	print 'WARN: ', $action, ': ', $msg, "\n";
  }
  my %strmap;
  my $parser = PHP::Decode::Parser->new(strmap => \%strmap, filename => 'test', warn => \&warn_msg);

  # Parse php token list

  my $line = '<?php echo "test"; ?>';
  my $quote = $parser->tokenize_line($line);
  my $tokens = $parser->tokens();
  my $stmt = $parser->read_code($tokens);

  # Expand to code again

  my $code = $parser->format_stmt($stmt, {format => 1});
  print $code;

=head1 DESCRIPTION

The PHP::Decode::Parser Module tokenizes and parses php code strings. The parser
does not depend on a special php version. It supports most php syntax of
interpreters from php5 to php8.

The parser assumes that the input file is a valid php script, and does
not enforce strict syntactic checks. Unrecognized tokens are simply passed
through.

The parser converts the php code into a unified form when the resulting
output is formatted (for example intermittent php-script-tags and variables
from string interpolation are removed and rewritten to php echo statements).

=head1 METHODS

=head2 new

  $parser = PHP::Decode::Parser->new(%args);

Create a PHP::Decode::Parser object. Arguments are passed in key => value pairs.

The only required argument is `strmap`.

The new constructor dies when arguments are invalid, or if required
arguments are missing.

The accepted arguments are:

=over 4

=item strmap: hashmap for parsed php statements

=item inscript: set to indicate that paser starts inside of script

=item filename: optional script filename (if not stdin or textstr)

=item max_strlen: max strlen for debug strings

=item warn: optional handler to log warning messages

=item log: optional handler to log info messages

=item debug: optional handler to log debug messages

=back

=head2 tokenize_line

Tokenize a php code string

    quote = $parser->tokenize_line($line);

See the description of the L<PHP::Decode::Tokenizer> module for the token types.

=head2 read_code

Parse a token list

  <tok> php token list

    $stmt = $parser->read_code($tokens);

The read_code method converts the token list to an internal representation
of php statements. If a script contains more than one top level statement,
the method returns block with a list of these statements.

The following types are used to represent php statements:

=over 4

=item #null: null value

=item #num: unquoted integer or float

=item #str: quoted string

=item #const: unquoted symbol

=item $var: variable

=item #arr: ordered array (see: L<PHP::Decode::Array>)

=item #blk: block of statements

=item #fun: function definition

=item #call: function call

=item #elem: indexed elem access

=item #expr: unary or binary expression

=item #ns: namespace prefix

=item #class: class definition

=item #scope: class property dereference

=item #inst: class instance

=item #obj: obj property dereference

=item #ref: reference to variable

=item #trait: class trait

=item #fh: file handle (limited to __FILE__)

=item #stmt: remaining php statements (like if, while, echo, global, ..)

=back

Each of of these statements is uniquely numbered and stored in the
strmap of the parser.

=head2 format_stmt

Format a php statement to a php code string.

    $code = $parser->format_stmt($stmt, $fmt);

The accepted arguments are:

=over 4

=item stmt: the toplevel php statement to format

=item fmt: optional format flags

=item $fmt->{indent}: output indented multiline code

=item $fmt->{unified}: unified #str/#num output

=item $fmt->{mask_eval}: mask eval in strings with pattern

=item $fmt->{escape_ctrl}: escape control characters in output strings

=item $fmt->{avoid_semicolon}: avoid semicolons after braces

=item $fmt->{max_strlen}: max length for strings in output

=back

=head1 SEE ALSO

Requires the L<PHP::Decode::Tokenizer> Module.

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut
