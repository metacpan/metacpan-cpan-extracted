package Python::Bytecode;
use 5.6.0;

use strict;

our $VERSION = "2.7";

use overload '""' => sub { my $obj = shift; 
    "<Code object ".$obj->{name}.", file ".$obj->{filename}." line ".$obj->{lineno}." at ".sprintf('0x%x>',0+$obj);
    }, "0+" => sub { $_[0] }, fallback => 1;

sub new {
    my ($class, $fh) = (@_);
    my $self = bless { };
    if (ref $fh) { $self->{fh} = $fh; } 
    else { $self->{stuff} = [ split //, $fh ] }

    my $magic = $self->r_long();
    my $data = _get_data_by_magic($magic);
    $self->{version} = $Python::Bytecode::versions{$magic};
    # What we use to read words from the source. May be r_short or r_long
    *Python::Bytecode::r_word = $Python::Bytecode::readword{$magic};
    $self->r_long(); # Second magic number
    $self->{mainobj} = $self->r_object();
    $self->_init($data);
    return $self;
}

sub _get_data_by_magic {
    require Python::Bytecode::v21;
    require Python::Bytecode::v22;
    require Python::Bytecode::v23;
    my $magic = shift;
    unless (exists $Python::Bytecode::data{$magic}) {
        require Carp;
        Carp::croak("Unrecognised magic number $magic; Only know Python versions "
        . join ", ", map { "$_ ($Python::Bytecode::versions{$_})" } keys %Python::Bytecode::versions
        );
    }
    return $Python::Bytecode::data{$magic};
}

sub r_byte { 
    my $self = shift;
    if (exists $self->{stuff}) { ord shift @{$self->{stuff}};}
    else { ord getc $self->{fh} }
}

sub r_long {
    use integer;
    my $self = shift;
    my $x = $self->r_byte;
    $x |= $self->r_byte << 8;
    $x |= $self->r_byte << 16;
    $x |= $self->r_byte << 24;
    return $x;
}

sub r_short {
    my $self = shift;
    my $x = $self->r_byte;
    $x |= $self->r_byte << 8;
    $x |= -($x & 0x8000);
    return $x;
}

sub r_string { 
    my $self = shift;
    my $length = $self->r_long; 
    my $buf; 
    if ( exists $self->{stuff}) {
        $buf = join "", splice ( @{$self->{stuff}},0,$length,() );
    } else {
        read $self->{fh}, $buf, $length; 
    }
    return $buf;
}

# This really ought to return a real unicode string, rather than a plain 
# binary string that we fib about
sub r_unicode { 
    my $self = shift;
    my $length = $self->r_long; 
    my $buf; 
    if ( exists $self->{stuff}) {
        $buf = join "", splice ( @{$self->{stuff}},0,$length,() );
    } else {
        read $self->{fh}, $buf, $length; 
    }
    return $buf;
}

sub r_float {
    my $self = shift;
    my $length = $self->r_byte;
    my $buf; 
    if ( exists $self->{stuff}) {
        $buf = join "", splice ( @{$self->{stuff}},0,$length,() );
    } else {
        read $self->{fh}, $buf, $length; 
    }
    $buf += 0;
    return $buf;
}

sub r_complex {
    my $self = shift;
    my $length = $self->r_byte;
    my $real; 
    if ( exists $self->{stuff}) {
        $real = join "", splice ( @{$self->{stuff}},0,$length,() );
    } else {
        read $self->{fh}, $real, $length; 
    }
    $real += 0;

    $length = $self->r_byte;
    my $imag; 
    if ( exists $self->{stuff}) {
        $imag = join "", splice ( @{$self->{stuff}},0,$length,() );
    } else {
        read $self->{fh}, $imag, $length; 
    }
    $imag += 0;
    return bless([$real, $imag], "Python::Bytecode::Complex");
}

sub r_object {
    my $self = shift;
    my $cooked = shift;
    my $type = chr $self->r_byte();
    return $self->r_code() if $type eq "c";
    if ($cooked) { 
        return bless \($self->r_string()), "Python::Bytecode::String" if $type eq "s";
        return bless \($self->r_long()), "Python::Bytecode::Long"   if $type eq "i";
        return bless \do{my $x=undef}, "Python::Bytecode::Undef"   if $type eq "N";
    } else {
        return $self->r_string if $type eq "s";
        return $self->r_long() if $type eq "i";
        return undef if $type eq "N"; # None indeed.
    }
    if ($type eq "(") {
        my @tuple = $self->r_tuple($cooked);
        return bless [@tuple], "Python::Bytecode::Tuple"  unless wantarray;
        return @tuple;
    }
    if ($type eq 'u') {
      return bless\($self->r_unicode()), "Python::Bytecode::Unicode";
    }
    if ($type eq 'l') {
      return bless \($self->r_extralong()), "Python::Bytecode::Extralong";
    }
    if ($type eq 'f') {
      return bless \($self->r_float()), "Python::Bytecode::Float";
    }
    if ($type eq 'x') {
      return $self->r_complex();
    }
    die "Oops! I didn't implement ".ord($type) . " (".  length($type) .  " bytes)";
}

sub r_tuple {
    my $self = shift;
    my $cooked = shift;
    my $n = $self->r_long;
    return () unless $n;
    my @rv;
    push @rv, scalar $self->r_object($cooked) for (1..$n);
    return @rv;
}

# This is an extended precision long read. It'll likely be incorrect if the size of the
# long exceeds the precision of perl's double, and it really ought to generate a
# Math::BigInt instead.
sub r_extralong {
  my $self = shift;
  my $n = $self->r_long;
  my $size = $n<0 ? -$n : $n;
  my $num = 0;

  foreach (1..$size) {
    my $digit = $self->r_short();
    $num *= 32768;
    $num += $digit;
  }

  return $num;

}

sub r_code {
    my $file = shift;
    my $self = bless {bytecode => $file}, 'Python::Bytecode::Codeobj';
    $self->{argcount} = $file->r_word; #
    $self->{nlocals}  = $file->r_word; #
    $self->{stacksize}= $file->r_word; #
    $self->{flags}    = $file->r_word; #
    if ($self->{code}     = $file->r_object) {
      if ($self->{constants}= $file->r_object(1)) {
	if ($self->{names}    = $file->r_object) {
	  if ($self->{varnames} = $file->r_object) {
	    if ($self->{freevars} = $file->r_object) {
	      if ($self->{cellvars} = $file->r_object) {
		if ($self->{filename} = $file->r_object) {
		  if ($self->{name}     = $file->r_object) {
		    $self->{lineno}   = $file->r_word; # 
		    $self->{lnotab}   = $file->r_object;
		  }}}}}}}}
    return $self;
}

for (qw(argcount nlocals stacksize flags code constants names
varnames freevars cellvars filename name lineno lnotab)) {
    no strict q/subs/;
    eval "sub $_ { return \$_[0]->{mainobj}->$_ }";
}

sub version {
    return $_[0]->{version};
}

$Parrot::Bytecode::DATA = <<EOF;

# This'll amuse you. It's actually lifted directly from dis.py :)
# Instruction opcodes for compiled code

def_op('STOP_CODE', 0)
def_op('POP_TOP', 1)
def_op('ROT_TWO', 2)
def_op('ROT_THREE', 3)
def_op('DUP_TOP', 4)
def_op('ROT_FOUR', 5)

def_op('UNARY_POSITIVE', 10)
def_op('UNARY_NEGATIVE', 11)
def_op('UNARY_NOT', 12)
def_op('UNARY_CONVERT', 13)

def_op('UNARY_INVERT', 15)

def_op('BINARY_POWER', 19)

def_op('BINARY_MULTIPLY', 20)
def_op('BINARY_DIVIDE', 21)
def_op('BINARY_MODULO', 22)
def_op('BINARY_ADD', 23)
def_op('BINARY_SUBTRACT', 24)
def_op('BINARY_SUBSCR', 25)

def_op('SLICE+0', 30)
def_op('SLICE+1', 31)
def_op('SLICE+2', 32)
def_op('SLICE+3', 33)

def_op('STORE_SLICE+0', 40)
def_op('STORE_SLICE+1', 41)
def_op('STORE_SLICE+2', 42)
def_op('STORE_SLICE+3', 43)

def_op('DELETE_SLICE+0', 50)
def_op('DELETE_SLICE+1', 51)
def_op('DELETE_SLICE+2', 52)
def_op('DELETE_SLICE+3', 53)

def_op('INPLACE_ADD', 55)
def_op('INPLACE_SUBTRACT', 56)
def_op('INPLACE_MULTIPLY', 57)
def_op('INPLACE_DIVIDE', 58)
def_op('INPLACE_MODULO', 59)
def_op('STORE_SUBSCR', 60)
def_op('DELETE_SUBSCR', 61)

def_op('BINARY_LSHIFT', 62)
def_op('BINARY_RSHIFT', 63)
def_op('BINARY_AND', 64)
def_op('BINARY_XOR', 65)
def_op('BINARY_OR', 66)
def_op('INPLACE_POWER', 67)

def_op('PRINT_EXPR', 70)
def_op('PRINT_ITEM', 71)
def_op('PRINT_NEWLINE', 72)
def_op('PRINT_ITEM_TO', 73)
def_op('PRINT_NEWLINE_TO', 74)
def_op('INPLACE_LSHIFT', 75)
def_op('INPLACE_RSHIFT', 76)
def_op('INPLACE_AND', 77)
def_op('INPLACE_XOR', 78)
def_op('INPLACE_OR', 79)
def_op('BREAK_LOOP', 80)

def_op('LOAD_LOCALS', 82)
def_op('RETURN_VALUE', 83)
def_op('IMPORT_STAR', 84)
def_op('EXEC_STMT', 85)

def_op('POP_BLOCK', 87)
def_op('END_FINALLY', 88)
def_op('BUILD_CLASS', 89)

HAVE_ARGUMENT = 90      # Opcodes from here have an argument:

name_op('STORE_NAME', 90)   # Index in name list
name_op('DELETE_NAME', 91)  # ""
def_op('UNPACK_SEQUENCE', 92)   # Number of tuple items

name_op('STORE_ATTR', 95)   # Index in name list
name_op('DELETE_ATTR', 96)  # ""
name_op('STORE_GLOBAL', 97) # ""
name_op('DELETE_GLOBAL', 98)    # ""
def_op('DUP_TOPX', 99)      # number of items to duplicate
def_op('LOAD_CONST', 100)   # Index in const list
hasconst.append(100)
name_op('LOAD_NAME', 101)   # Index in name list
def_op('BUILD_TUPLE', 102)  # Number of tuple items
def_op('BUILD_LIST', 103)   # Number of list items
def_op('BUILD_MAP', 104)    # Always zero for now
name_op('LOAD_ATTR', 105)   # Index in name list
def_op('COMPARE_OP', 106)   # Comparison operator
hascompare.append(106)
name_op('IMPORT_NAME', 107) # Index in name list
name_op('IMPORT_FROM', 108) # Index in name list

jrel_op('JUMP_FORWARD', 110)    # Number of bytes to skip
jrel_op('JUMP_IF_FALSE', 111)   # ""
jrel_op('JUMP_IF_TRUE', 112)    # ""
jabs_op('JUMP_ABSOLUTE', 113)   # Target byte offset from beginning of code
jrel_op('FOR_LOOP', 114)    # Number of bytes to skip

name_op('LOAD_GLOBAL', 116) # Index in name list

jrel_op('SETUP_LOOP', 120)  # Distance to target address
jrel_op('SETUP_EXCEPT', 121)    # ""
jrel_op('SETUP_FINALLY', 122)   # ""

def_op('LOAD_FAST', 124)    # Local variable number
haslocal.append(124)
def_op('STORE_FAST', 125)   # Local variable number
haslocal.append(125)
def_op('DELETE_FAST', 126)  # Local variable number
haslocal.append(126)

def_op('SET_LINENO', 127)   # Current line number
SET_LINENO = 127

def_op('RAISE_VARARGS', 130)    # Number of raise arguments (1, 2, or 3)
def_op('CALL_FUNCTION', 131)    # #args + (#kwargs << 8)
def_op('MAKE_FUNCTION', 132)    # Number of args with default values
def_op('BUILD_SLICE', 133)      # Number of items

def_op('CALL_FUNCTION_VAR', 140)     # #args + (#kwargs << 8)
def_op('CALL_FUNCTION_KW', 141)      # #args + (#kwargs << 8)
def_op('CALL_FUNCTION_VAR_KW', 142)  # #args + (#kwargs << 8)

def_op('EXTENDED_ARG', 143)
EXTENDED_ARG = 143

EOF

# Set up op code data structures
sub _init {
    my $self = shift;
    my $data = shift;
    my @opnames;
    my %c; # Natty constants.
    my %has;
    for (split /\n/, $data) { # This ought to come predigested, but I am lazy
        next if /^#/ or not /\S/;
        if    (/^def_op\('([^']+)', (\d+)\)/) { $opnames[$2]=$1; } 
        elsif (/^(jrel|jabs|name)_op\('([^']+)', (\d+)\)/) { $opnames[$3]=$2; $has{$1}{$3}++ } 
        elsif (/(\w+)\s*=\s*(\d+)/) { $c{$1}=$2; }
        elsif (/^has(\w+)\.append\((\d+)\)/) { $has{$1}{$2}++ }
    }
    $self->{opnames} = \@opnames;
    $self->{has} = \%has;
    $self->{c} = \%c;
}

sub disassemble {
    my $self = shift;
    return $self->{mainobj}->disassemble;
}

# Now we've read in the op tree, disassemble it.
package Python::Bytecode::Codeobj;

use overload '""' => sub { my $obj = shift; 
    "<Code object ".$obj->{name}.", file ".$obj->{filename}." line ".$obj->{lineno}." at ".sprintf('0x%x>',0+$obj);
    }, "0+" => sub { $_[0] }, fallback => 1;

for (qw(argcount nlocals stacksize flags code constants names
varnames freevars cellvars filename name lineno lnotab)) {
    no strict q/subs/;
    eval "sub $_ { return \$_[0]->{$_} }";
}


sub findlabels {
    my $self = shift;
    my $bytecode = $self->{bytecode};
    my %labels = ();
    my @code = @_;
    my $offset = 0;
    while (@code) {
        my $c = shift @code;
        $offset++;
        if ($c>=$bytecode->{c}{HAVE_ARGUMENT}) {
            my $arg = shift @code; 
            $arg += (256 * shift (@code));
            $offset += 2;
            if ($bytecode->{has}{jrel}{$c}) { $labels{$offset + $arg}++ };
            if ($bytecode->{has}{jabs}{$c}) { $labels{$offset}++ };
        }
    }
    return %labels; 
}

my @cmp_op   = ('<', '<=', '==', '!=', '>', '>=', 'in', 'not in', 'is', 'is not', 'exception match', 'BAD');

sub __printconst {
  my $thing = shift;

  my $class = ref $thing;
  if ($class =~ /String/ || $class =~ /Long/) {
    return $$thing;
  }
  if ($class =~ /Undef/) {
    return "";
  }
  return $thing;
  
}

sub disassemble {
    my $self = shift;
    my $bytecode = $self->{bytecode};
    my @code = map { ord } split //, $self->{code};
    my %labels = $self->findlabels(@code);
    my $offset = 0;
    my $extarg = 0;
    my @dis;
    while (@code) {
        my $c = shift @code;
        my $text = (($labels{$offset}) ? ">>" : "  ");
        $text .= sprintf "%4i", $offset;
        $text .= sprintf "%20s", $self->opname($c);
        $offset++;
        my $arg;
        if ($c>=$bytecode->{c}{HAVE_ARGUMENT}) {
            $arg = shift @code; 
            $arg += (256 * shift (@code)) + $extarg;
            $extarg = 0;
            $extarg = $arg * 65535 if ($c == $bytecode->{c}{EXTENDED_ARG});
            $offset+=2;
            $text .= sprintf "%5i", $arg;
            $text .= " (".__printconst($self->{constants}->[$arg]).")" if (ref $self->{constants}->[$arg] && $bytecode->{has}{const} && $bytecode->{has}{const}{$c});
            $text .= " (".$self->{varnames}->[$arg].")"  if ($bytecode->{has}{"local"}{$c});
            $text .= " [".$self->{names}->[$arg]."]"     if ($bytecode->{has}{name}{$c});
            $text .= " [".$cmp_op[$arg]."]"              if ($bytecode->{has}{compare}{$c});
            $text .= " (to ".($offset+$arg).")"          if ($bytecode->{has}{jrel}{$c});
        }
        push @dis, [$text, $c, $arg];
    }
    return @dis;
}

sub opname { $_[0]->{bytecode}{opnames}[$_[1]] }

1;

=head1 NAME

Python::Bytecode - Disassemble and investigate Python bytecode

=head1 SYNOPSIS

    use Python::Bytecode
    my $bytecode = Python::Bytecode->new($bytecode);
    my $bytecode = Python::Bytecode->new(FH);
    for ($bytecode->disassemble) {
        print $_->[0],"\n"; # Textual representation of disassembly
    }

    foreach my $constant (@{$bytecode->constants()}) {
      if ($constant->can('disassemble')) {
        print "code constant:\n";
        for ($constant->disassemble) {
          print $_->[0], "\n";
        }
      }
    }

=head1 DESCRIPTION

C<Python::Bytecode> accepts a string or filehandle contain Python
bytecode and puts it into a format you can manipulate.

=head1 METHODS

=over 3

=item C<disassemble>

This is the basic method for getting at the actual code. It returns an 
array representing the individual operations in the bytecode stream.
Each element is a reference to a three-element array containing
a textual representation of the disassembly, the opcode number, (the
C<opname()> function can be used to turn this into an op name) and
the argument to the op, if any.

=item C<constants>

This returns an array reflecting the constants table of the code object.
Some operations such as C<LOAD_CONST> refer to constants by index in
this array.

=item C<labels>

Similar to C<constants>, some operations branch to labels by index
in this table.

=item C<varnames>

Again, when variables are referred to by name, the names are stored
as an index into this table.

=item C<filename>

The filename from which this compiled bytecode is derived.

=back

There are other methods, but you can read the code to find them. It's
not hard, and besides, it's probably easiest to work off the textual
representation of the disassembly anyway.

=head1 STRUCTURE

The structure of the decoded bytecode file is reasonably simple.

The output of the C<new> method is an object that represents the fully
parsed bytecode file. This object contains the information about the
bytecode file, as well as the top-level code object for the file.

Each python code object in the bytecode file has its own perl object
that represents it. This object can be disassembled, has its own
constants (which themselves may be code objects) and its own variables.

The module completely decodes the bytecode object when the bytecode
file is handed to the C<new> method, but to get all the pieces of the
bytecode may require digging into the constants of each code object.

=head1 PERPETRATORS

Simon Cozens, C<simon@cpan.org>. Mutation for Python 2.3 by Dan
Sugalski C<dan@sidhe.org>

=head1 LICENSE

This code is licensed under the same terms as Perl itself.

