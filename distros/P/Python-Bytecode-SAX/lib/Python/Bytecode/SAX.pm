=head1 NAME

Python::Bytecode::SAX - Process Python bytecode, generating SAX events.

=head1 SYNOPSIS

  use Python::Bytecode::SAX;
  use XML::SAX::Writer;
  my $handler = XML::SAX::Writer->new( Output => 'foo.xml' );
  my $parser = Python::Bytecode::SAX->new( Handler => $handler, SAX => 2 );
  $parser->parse_file('foo.pyc');

Or

  use Python::Bytecode::SAX;
  use XML::Handler::YAWriter;
  my $handler = XML::Handler::YAWriter->new(
      AsFile => 'foo.xml',
      Pretty  => {
          CompactAttrIndent  => 1,
          PrettyWhiteIndent  => 1,
          PrettyWhiteNewline => 1,
          CatchEmptyElement  => 1
      }
  );
  my $parser = Python::Bytecode::SAX->new( Handler => $handler, SAX => 1 );
  $parser->parse_file('foo.pyc');

=head1 DESCRIPTION

This module reads and decodes a Python bytecode file, generating SAX1 or SAX2
events (SAX1 is the default) for what it finds.

Until more documentation is written, you can examine the two XML files generated
in the F<t/> directory by C<make test> to get a feel for the overal structure and
the element and attribute names.

=head1 HISTORY

Based on the L<Python::Bytecode> module by Simon Cozens E<lt>simon@cpan.orgE<gt>,
which is based on the F<dis.py> file in the Python Standard Library.

=head1 SEE ALSO

L<Python::Bytecode> by Simon Cozens E<lt>simon@cpan.orgE<gt>.

=head1 AUTHOR

Gregor N. Purdy E<lt>gregor@focusresearch.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Gregor N. Purdy. All rights reserved.

=head1 LICENSE

This program is free software. Its use is subject to the same license as Perl.

=cut

package Python::Bytecode::SAX;
use 5.6.0;

our $VERSION = '0.1';

use strict;
use Data::Dumper;
use Carp;

use overload '""' => sub { my $obj = shift; 
    "<Code object ".$obj->{name}.", file ".$obj->{filename}." line ".$obj->{lineno}." at ".sprintf('0x%x>',0+$obj);
    }, "0+" => sub { $_[0] }, fallback => 1;

my $no_main_yet;


#
# new()
#

sub new
{
    my $class = shift;
    my %opts = @_;

    return bless { %opts }, $class;
}


#
# _start_doc()
#

sub _start_doc
{
    my $self = shift;

    $self->{Handler}->start_document();
}


#
# _end_doc()
#

sub _end_doc
{
    my $self = shift;

    $self->_flush;
    $self->{Handler}->end_document();
}


#
# _start_elem()
#

sub _start_elem
{
    my $self = shift;
    my $name = shift;

    $self->_flush;
    $self->{_elem}  = $name;
    $self->{_attrs} = { };
}


#
# _attr()
#

sub _attr
{
   my $self  = shift;
   my $attr  = shift;
   my $value = shift;

   $self->{_attrs}{$attr} = $value;
}


#
# _end_elem()
#

sub _end_elem
{
    my $self = shift;
    my $name = shift;

    $self->_flush;
    
    my $SAX = $self->{SAX} || 1;

    if ($SAX == 1) {
        $self->{Handler}->end_element({ Name => $name });
    }
    else {
        $self->{Handler}->end_element({ Name => $name });
    }
}


#
# _chars()
#

sub _chars
{
    my $self = shift;
    my $data = shift;

    $self->_flush;

    my $SAX = $self->{SAX} || 1;

    if ($SAX == 1) {
        $self->{Handler}->characters({ Data => $data });
    }
    else {
        $self->{Handler}->characters({ Data => $data });
    }
}


#
# _flush
#

sub _flush
{
    my $self = shift;

    return unless $self->{_elem};

    my $SAX = $self->{SAX} || 1;

    if ($SAX == 1) {
        $self->{Handler}->start_element({ Name => $self->{_elem}, Attributes => $self->{_attrs} });
    }
    else {
        my $attrs = { };
        foreach my $attr (keys %{$self->{_attrs}}) {
          $attrs->{$attr}{Name} = $attr;
          $attrs->{$attr}{Value} = $self->{_attrs}{$attr};
        }
        $self->{Handler}->start_element({ Name => $self->{_elem}, Attributes => $attrs });
    }

    $self->{_elem}  = undef;
    $self->{_attrs} = undef;
}


#
# parse_string()
#
# Open a filehandle for reading the string.
#

sub parse_string
{
  my $self = shift;
  my $string = shift;

  my $fh;
  open($fh, "<", \$string) or die;
  $self->{fh} = $fh;

  return $self->_parse;
}


#
# parse_file()
#
# Open a filehandle for reading the file.
#

sub parse_file
{
    my $self = shift;
    my $file = shift;

    my $fh;
    open($fh, "<", $file) or die;
    $self->{fh} = $fh;

    return $self->_parse;
}


#
# _parse()
#

sub _parse
{
    my $self = shift;

    my $magic   = $self->r_long();
    my $magic2  = $self->r_long(); # Second magic number
    my $version = $Python::Bytecode::versions{$magic};

    my $data    = _get_data_by_magic($magic);
    $self->_init($data);

    $self->_start_doc();

    $self->_start_elem('file');
    $self->_attr(magic   => $magic);
    $self->_attr(magic2  => $magic2);
    $self->_attr(version => $version);

    $self->r_object(emit => 1);

    $self->_end_elem('file');

    $self->_end_doc();

    return $self;
}


#
# _get_data_by_magic()
#

sub _get_data_by_magic
{
    require Python::Bytecode::v21;
    require Python::Bytecode::v22;
    my $magic = shift;
    unless (exists $Python::Bytecode::data{$magic}) {
        require Carp;
        Carp::croak("Unrecognised magic number $magic; Only know Python versions "
        . join ", ", map { "$_ ($Python::Bytecode::versions{$_})" } keys %Python::Bytecode::versions
        );
    }
    return $Python::Bytecode::data{$magic};
}


#
# r_byte()
#

sub r_byte
{ 
    my $self = shift;
    return ord getc $self->{fh};
}


#
# r_long()
#

sub r_long
{
    my $self = shift;
    my $x = $self->r_byte;
    $x |= $self->r_byte << 8;
    $x |= $self->r_byte << 16;
    $x |= $self->r_byte << 24;
    return $x;
}


#
# r_short()
#

sub r_short
{
    my $self = shift;
    my $x = $self->r_byte;
    $x |= $self->r_byte << 8;
    $x |= -($x & 0x8000);
    return $x;
}


#
# r_string()
#

sub r_string
{
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


#
# r_object()
#

sub r_object
{
    my $self = shift;
    my %options = @_;

    confess "Don't know whether or not to emit!" unless exists $options{emit};

    my $type = chr $self->r_byte();

    if ($type eq "c") {
        my $code = $self->r_code(emit => $options{emit}, $options{index});
        return $code;
    }
    elsif ($type eq 's') {
      if ($options{emit}) {
          $self->_start_elem('literal');
          $self->_attr(type  => 'String');
          $self->_attr(value => $self->r_string);
          $self->_attr(index => $options{index}) if defined $options{index};
          $self->_end_elem('literal');
      }
      else {
          return $self->r_string();
      }
    }
    elsif ($type eq 'i') {
      if ($options{emit}) {
          $self->_start_elem('literal');
          $self->_attr(type  => 'Long');
          $self->_attr(value => $self->r_long);
          $self->_attr(index => $options{index}) if defined $options{index};
          $self->_end_elem('literal');
      }
      else {
          return $self->r_long();
      }
    }
    elsif ($type eq 'N') {
      if ($options{emit}) {
          $self->_start_elem('literal');
          $self->_attr(type  => 'None');
          $self->_attr(index => $options{index}) if defined $options{index};
          $self->_end_elem('literal');
      }
      else {
          return undef;
      }
    }
    elsif ($type eq "(") {
        $self->r_tuple(name => $options{name}, index => $options{index});
    }
    else {
        die "Oops! I didn't implement ".ord $type;
    }
}


#
# r_tuple()
#

sub r_tuple
{
    my $self = shift;
    my %options = @_;

    my $n = $self->r_long;
   
    $options{name} = 'tuple' unless $options{name};

    $self->_start_elem($options{name});
    $self->_attr(index => $options{index}) if defined $options{index};
    $self->_attr('count' => $n);
    
    for my $i (0..$n - 1) {
      $self->r_object(index => $i, emit => 1);
    }

    $self->_end_elem($options{name});
}


#
# r_code()
#

sub r_code {
    my $self = shift;

    $self->_start_elem('outer_code');
    $self->_attr('argcount'  => $self->r_short);
    $self->_attr('nlocals'   => $self->r_short);
    $self->_attr('stacksize' => $self->r_short);
    $self->_attr('flags'     => $self->r_short);

    $self->_start_elem('code');
    $self->disassemble($self->r_object(emit => 0));
    $self->_end_elem('code');

    $self->r_object(name => 'constants', emit => 1);
    $self->r_object(name => 'names',     emit => 1);
    $self->r_object(name => 'varnames',  emit => 1);
    $self->r_object(name => 'freevars',  emit => 1);
    $self->r_object(name => 'cellvars',  emit => 1);

    $self->_start_elem('filename');
    $self->r_object(emit => 1);
    $self->_end_elem('filename');

    $self->_start_elem('name');
    $self->r_object(emit => 1);
    $self->_end_elem('name');

    $self->_start_elem('lineno');
    $self->_chars($self->r_short);
    $self->_end_elem('lineno');

    $self->_start_elem('lnotab'); # Maps address to line #?
    $self->r_object(emit => 1); 
    $self->_end_elem('lnotab');

    $self->_end_elem('outer_code');
}


###############################################################################
###############################################################################
##
## DATA TABLES
##
###############################################################################
###############################################################################


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


#
# _init()
#

# Set up op code data structures

sub _init
{
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


#
# disassemble()
#

my @cmp_op   = ('<', '<=', '==', '!=', '>', '>=', 'in', 'not in', 'is', 'is not', 'exception match', 'BAD');

sub disassemble
{
    my $self = shift;
    my $code = shift;

confess "NO CODE!" unless $code;

    my @code = map { ord } split //, $code;

    my $offset = 0;
    my $extarg = 0;
    my @dis;

    while (@code) {
        my $c = shift @code;

        my $opname = $self->opname($c);

        $self->_start_elem('op');
        $self->_attr('offset' => $offset);
        $self->_attr('name'   => $opname);
        $self->_attr('code'   => $c);
        
        $offset++;
        my $arg;

        if ($c>=$self->{c}{HAVE_ARGUMENT}) {
            $arg = shift @code; 
            $arg += (256 * shift (@code)) + $extarg;
            $extarg = 0;
            $extarg = $arg * 65535 if ($c == $self->{c}{EXTENDED_ARG});
            $offset+=2;

            $self->_attr('value' => $arg);

            if ($self->{has}{const}{$c}) {
                $self->_attr('value-type'    => 'const-index');
            }
            elsif ($self->{has}{"local"}{$c}) {
                $self->_attr('value-type'    => 'local-index');
            }
            elsif ($self->{has}{name}{$c}) {
                $self->_attr('value-type'    => 'name-index');
            }
            elsif ($self->{has}{compare}{$c}) {
                $self->_attr('value-type'    => 'compare-op');
                $self->_attr('value-compare' => $cmp_op[$arg]);
            }
            elsif ($self->{has}{jrel}{$c}) {
                $self->_attr('value-type'    => 'jump-offset');
                $self->_attr('value-jump'    => 'rel');
                $self->_attr('value-target'  => $offset + $arg );
            }
            elsif ($self->{has}{jabs}{$c}) {
                $self->_attr('value-type'    => 'jump-target');
                $self->_attr('value-jump'    => 'rel');
                $self->_attr('value-target'  => $arg );
            }
            else {
                $self->_attr('value-type'    => 'literal');
            }
        }

        $self->_end_elem('op');
    }
}


#
# opname()
#

sub opname {
    $_[0]->{opnames}[$_[1]];
}


1;

