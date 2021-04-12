#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I. -I/home/phil/perl/cpan/AsmC/lib/
#-------------------------------------------------------------------------------
# Generate Nasm X86 code from Perl.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
# Register expressions via op overloading - register size and ability to add offsets, peek, pop, push clear register
# Indent opcodes by call depth, - replace push @text with a method call
package Nasm::X86;
our $VERSION = "202104014";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Asm::C qw(:all);
use feature qw(say current_sub);

my $debug = -e q(/home/phil/);                                                  # Developing
my $sde   = q(/var/isde/sde64);                                                 # Intel emulator
   $sde   = q(sde/sde64) unless $debug;

binModeAllUtf8;

my %rodata;                                                                     # Read only data already written
my %rodatas;                                                                    # Read only string already written
my %subroutines;                                                                # Subroutines generated
my @rodata;                                                                     # Read only data
my @data;                                                                       # Data
my @bss;                                                                        # Block started by symbol
my @text;                                                                       # Code

my $sysout = 1;                                                                 # File descriptor for output

BEGIN{
  my %r = (    map {$_=>'8'}    qw(al bl cl dl r8b r9b r10b r11b r12b r13b r14b r15b sil dil spl bpl ah bh ch dh));
     %r = (%r, map {$_=>'s'}    qw(cs ds es fs gs ss));
     %r = (%r, map {$_=>'16'}   qw(ax bx cx dx r8w r9w r10w r11w r12w r13w r14w r15w si di sp bp));
     %r = (%r, map {$_=>'32a'}  qw(eax  ebx ecx edx esi edi esp ebp));
     %r = (%r, map {$_=>'32b'}  qw(r8d r8l r9d r9l r10d r10l r11d r11l r12d r12l r13d r13l r14d r14l r15d r15l));
     %r = (%r, map {$_=>'f'}    qw(st0 st1 st2 st3 st4 st5 st6 st7));
     %r = (%r, map {$_=>'64'}   qw(rax rbx rcx rdx r8 r9 r10 r11 r12 r13 r14 r15 rsi rdi rsp rbp rip rflags));
     %r = (%r, map {$_=>'64m'}  qw(mm0 mm1 mm2 mm3 mm4 mm5 mm6 mm7));
     %r = (%r, map {$_=>'128'}  qw(xmm0 xmm1 xmm2 xmm3 xmm4 xmm5 xmm6 xmm7 xmm8 xmm9 xmm10 xmm11 xmm12 xmm13 xmm14 xmm15 xmm16 xmm17 xmm18 xmm19 xmm20 xmm21 xmm22 xmm23 xmm24 xmm25 xmm26 xmm27 xmm28 xmm29 xmm30 xmm31));
     %r = (%r, map {$_=>'256'}  qw(ymm0 ymm1 ymm2 ymm3 ymm4 ymm5 ymm6 ymm7 ymm8 ymm9 ymm10 ymm11 ymm12 ymm13 ymm14 ymm15 ymm16 ymm17 ymm18 ymm19 ymm20 ymm21 ymm22 ymm23 ymm24 ymm25 ymm26 ymm27 ymm28 ymm29 ymm30 ymm31));
     %r = (%r, map {$_=>'512'}  qw(zmm0 zmm1 zmm2 zmm3 zmm4 zmm5 zmm6 zmm7 zmm8 zmm9 zmm10 zmm11 zmm12 zmm13 zmm14 zmm15 zmm16 zmm17 zmm18 zmm19 zmm20 zmm21 zmm22 zmm23 zmm24 zmm25 zmm26 zmm27 zmm28 zmm29 zmm30 zmm31));
     %r = (%r, map {$_=>'m'}    qw(k0 k1 k2 k3 k4 k5 k6 k7));

  my @i0 = qw(pushfq rdtsc ret syscall);                                        # Zero operand instructions
  my @i1 = qw(call inc jge jmp jz pop push);                                    # Single operand instructions
  my @i2 =  split /\s+/, <<END;                                                 # Double operand instructions
add and cmp or lea mov shl shr sub test Vmovdqu8 vmovdqu32 vmovdqu64 vpxorq xor
END
  my @i3 =  split /\s+/, <<END;                                                 # Triple operand instructions
vprolq
END

  for my $r(sort keys %r)                                                       # Create register definitions
   {eval "sub $r\{q($r)\}";
    confess $@ if $@;
   }

  my %v = map {$_=>1} values %r;
  for my $v(sort keys %v)                                                       # Types of register
   {my @r = grep {$r{$_} eq $v} sort keys %r;
    eval "sub registers_$v\{".dump(\@r)."}";
    confess $@ if $@;
   }

  if (1)                                                                        # Instructions that take zero operands
   {my $s = '';
    for my $i(@i0)
      {my $I = ucfirst $i;
       $s .= <<END;
       sub $I()
        {\@_ == 0 or confess "No arguments allowed";
         push \@text, qq(  $i\\n);
        }
END
     }
    eval $s;
    confess $@ if $@;
   }

  if (1)                                                                        # Instructions that take one operand
   {my $s = '';
    for my $i(@i1)
      {my $I = ucfirst $i;
       $s .= <<END;
       sub $I(\$)
        {my (\$target) = \@_;
         \@_ == 1 or confess "One argument required";
         push \@text, qq(  $i \$target\\n);
        }
END
     }
    eval $s;
    confess $@ if $@;
   }

  if (1)                                                                        # Instructions that take two operands
   {my $s = '';
    for my $i(@i2)
      {my $I = ucfirst $i;
       $s .= <<END;
       sub $I(\$\$)
        {my (\$target, \$source) = \@_;
         \@_ == 2 or confess "Two arguments required";
         push \@text, qq(  $i \$target, \$source\\n);
        }
END
     }
    eval $s;
    confess $@ if $@;
   }

  if (1)                                                                        # Instructions that take three operands
   {my $s = '';
    for my $i(@i3)
      {my $I = ucfirst $i;
       $s .= <<END;
       sub $I(\$\$\$)
        {my (\$target, \$source, \$bits) = \@_;
         \@_ == 3 or confess "Three arguments required";
         push \@text, qq(  $i \$target, \$source, \$bits\\n);
        }
END
     }
    eval $s;
    confess $@ if $@;
   }
 }

sub ClearRegisters(@);                                                          # Clear registers by setting them to zero
sub Comment(@);                                                                 # Insert a comment into the assembly code
sub PeekR($);                                                                   # Peek at the register on top of the stack
sub PopR(@);                                                                    # Pop a list of registers off the stack
sub PrintOutMemory;                                                             # Print the memory addressed by rax for a length of rdi
sub PrintOutRegisterInHex($);                                                   # Print any register as a hex string
sub PushR(@);
sub Syscall();                                                                  # System call in linux 64 format per: https://filippo.io/linux-syscall-table/

#D1 Data                                                                        # Layout data

my $Labels = 0;
sub Label                                                                       #P Create a unique label
 {"l".++$Labels;                                                                # Generate a label
 }

sub SetLabel($)                                                                 # Set a label in the code section
 {my ($l) = @_;                                                                 # Label
  push @text, <<END;                                                            # Define bytes
  $l:
END
 }

sub Ds(@)                                                                       # Layout bytes in memory and return their label
 {my (@d) = @_;                                                                 # Data to be laid out
  my $d = join '', @_;
     $d =~ s(') (\')gs;
  my $l = Label;
  push @data, <<END;                                                            # Define bytes
  $l: db  '$d';
END
  $l                                                                            # Return label
 }

sub Rs(@)                                                                       # Layout bytes in read only memory and return their label
 {my (@d) = @_;                                                                 # Data to be laid out
  my $d = join '', @_;
     $d =~ s(') (\')gs;
  return $_ if $_ = $rodatas{$d};                                               # Data already exists so return it
  my $l = Label;
  $rodatas{$d} = $l;                                                            # Record label
  push @rodata, <<END;                                                          # Define bytes
  $l: db  '$d',0;
END
  $l                                                                            # Return label
 }

sub Dbwdq($@)                                                                   # Layout data
 {my ($s, @d) = @_;                                                             # Element size, data to be laid out
  my $d = join ', ', @d;
  my $l = Label;
  push @data, <<END;
  $l: d$s $d
END
  $l                                                                            # Return label
 }

sub Db(@)                                                                       # Layout bytes in the data segment and return their label
 {my (@bytes) = @_;                                                             # Bytes to layout
  Dbwdq 'b', @_;
 }
sub Dw(@)                                                                       # Layout words in the data segment and return their label
 {my (@words) = @_;                                                             # Words to layout
  Dbwdq 'w', @_;
 }
sub Dd(@)                                                                       # Layout double words in the data segment and return their label
 {my (@dwords) = @_;                                                            # Double words to layout
  Dbwdq 'd', @_;
 }
sub Dq(@)                                                                       # Layout quad words in the data segment and return their label
 {my (@qwords) = @_;                                                            # Quad words to layout
  Dbwdq 'q', @_;
 }

sub Rbwdq($@)                                                                   # Layout data
 {my ($s, @d) = @_;                                                             # Element size, data to be laid out
  my $d = join ', ', @d;                                                        # Data to be laid out
  return $_ if $_ = $rodata{$d};                                                # Data already exists so return it
  my $l = Label;                                                                # New data - create a label
  push @rodata, <<END;                                                          # Save in read only data
  $l: d$s $d
END
  $rodata{$d} = $l;                                                             # Record label
  $l                                                                            # Return label
 }

sub Rb(@)                                                                       # Layout bytes in the data segment and return their label
 {my (@bytes) = @_;                                                             # Bytes to layout
  Rbwdq 'b', @_;
 }
sub Rw(@)                                                                       # Layout words in the data segment and return their label
 {my (@words) = @_;                                                             # Words to layout
  Rbwdq 'w', @_;
 }
sub Rd(@)                                                                       # Layout double words in the data segment and return their label
 {my (@dwords) = @_;                                                            # Double words to layout
  Rbwdq 'd', @_;
 }
sub Rq(@)                                                                       # Layout quad words in the data segment and return their label
 {my (@qwords) = @_;                                                            # Quad words to layout
  Rbwdq 'q', @_;
 }

#D1 Registers                                                                   # Operations on registers

sub SaveFirstFour()                                                             # Save the first 4 parameter registers
 {Push rax;
  Push rdi;
  Push rsi;
  Push rdx;
  4 * &RegisterSize(rax);                                                         # Space occupied by push
 }

sub RestoreFirstFour()                                                          # Restore the first 4 parameter registers
 {Pop rdx;
  Pop rsi;
  Pop rdi;
  Pop rax;
 }

sub RestoreFirstFourExceptRax()                                                 # Restore the first 4 parameter registers except rax so it can return its value
 {Pop rdx;
  Pop rsi;
  Pop rdi;
  Add rsp, 8;
 }

sub SaveFirstSeven()                                                            # Save the first 7 parameter registers
 {Push rax;
  Push rdi;
  Push rsi;
  Push rdx;
  Push r10;
  Push r8;
  Push r9;
  7 * RegisterSize(rax);                                                        # Space occupied by push
 }

sub RestoreFirstSeven()                                                         # Restore the first 7 parameter registers
 {Pop r9;
  Pop r8;
  Pop r10;
  Pop rdx;
  Pop rsi;
  Pop rdi;
  Pop rax;
 }

sub RestoreFirstSevenExceptRax()                                                # Restore the first 7 parameter registers except rax which is being used to return the result
 {Pop r9;
  Pop r8;
  Pop r10;
  Pop rdx;
  Pop rsi;
  Pop rdi;
  Add rsp, RegisterSize(rax);                                                   # Skip rax
 }

sub RestoreFirstSevenExceptRaxAndRdi()                                          # Restore the first 7 parameter registers except rax and rdi which are being used to return the results
 {Pop r9;
  Pop r8;
  Pop r10;
  Pop rdx;
  Pop rsi;
  Add rsp, 2*RegisterSize(rax);                                                 # Skip rdi and rax
 }

sub RegisterSize($)                                                             # Return the size of a register
 {my ($r) = @_;                                                                 # Register
  return 16 if $r =~ m(\Ax);
  return 32 if $r =~ m(\Ay);
  return 64 if $r =~ m(\Az);
  8
 }

sub ClearRegisters(@)                                                           # Clear registers by setting them to zero
 {my (@registers) = @_;                                                         # Registers
  @_ == 1 or confess;
  for my $r(@registers)
   {my $size = RegisterSize $r;
    Xor    $r, $r if $size == 8;
    Vpxorq $r, $r if $size  > 8;
   }
 }

#D1 Structured Programming                                                      # Structured programming constructs

sub If(&;&)                                                                     # If
 {my ($then, $else) = @_;                                                       # Then - required , else - optional
  @_ >= 1 or confess;
  if (@_ == 1)                                                                  # No else
   {Comment "if then";
    my $end = Label;
    Jz $end;
    &$then;
    SetLabel $end;
   }
  else                                                                          # With else
   {Comment "if then else";
    my $endIf     = Label;
    my $startElse = Label;
    Jz $startElse;
    &$then;
    Jmp $endIf;
    SetLabel $startElse;
    &$else;
    SetLabel  $endIf;
   }
 }

sub For(&$$$)                                                                   # For
 {my ($body, $register, $limit, $increment) = @_;                               # Body, register, limit on loop, increment
  @_ == 4 or confess;
  Comment "For $register $limit";
  my $start = Label;
  my $end   = Label;
  SetLabel $start;
  Cmp $register, $limit;
  Jge $end;

  &$body;

  if ($increment == 1)
   {Inc $register;
   }
  else
   {Add $register, $increment;
   }
  Jmp $start;
  SetLabel $end;
 }

sub S(&%)                                                                       # Create a sub with optional parameters name=> the name of the subroutine so it can be reused rather than regenerated, comment=> a comment describing the sub
 {my ($body, %options) = @_;                                                    # Body, options.
  @_ >= 1 or confess;
  my $name    = $options{name};                                                 # Optional name for subroutine reuse
  my $comment = $options{comment};                                              # Optional comment
  Comment "Subroutine " .($comment//'');

  if ($name and my $n = $subroutines{$name}) {return $n}                        # Return the label of a pre-existing copy of the code

  my $start = Label;
  my $end   = Label;
  Jmp $end;
  SetLabel $start;
  &$body;
  Ret;
  SetLabel $end;
  $subroutines{$name} = $start if $name;                                        # Cache a reference to the generated code if a name was supplied

  $start
 }

sub Comment(@)                                                                  # Insert a comment into the assembly code
 {my (@comment) = @_;                                                           # Text of comment
  my $c = join "", @comment;
  push @text, <<END;
; $c
END
 }

#D1 Print                                                                       # Print

sub PrintOutNl()                                                                # Write a new line
 {@_ == 0 or confess;
  my $a = Rb(10);
  Comment "Write new line";
  SaveFirstFour;
  Mov rax, 1;
  Mov rdi, 1;
  Mov rsi, $a;
  Mov rdx, 1;
  Syscall;
  RestoreFirstFour()
 }

sub PrintOutString($)                                                           # Write a constant string to sysout.
 {my ($string) = @_;                                                            # String
  @_ == 1 or confess;

  SaveFirstFour;
  Comment "Write String: $string";
  my ($c) = @_;
  my $l = length($c);
  my $a = Rs($c);
  Mov rax, 1;
  Mov rdi, $sysout;
  Mov rsi, $a;
  Mov rdx, $l;
  Syscall;
  RestoreFirstFour();
 }

sub PrintOutRaxInHex                                                            # Write the content of register rax to stderr in hexadecimal in big endian notation
 {@_ == 0 or confess;
  Comment "Print Rax In Hex";

  my $hexTranslateTable = sub
   {my $h = '0123456789ABCDEF';
    my @t;
    for   my $i(split //, $h)
     {for my $j(split //, $h)
       {push @t, "$i$j";
       }
     }
     Rs @t                                                                      # Constant strings are only saved if they are unique, else a read only copy is returned.
   }->();

  my $sub = S                                                                   # Address conversion routine
   {SaveFirstFour;
    Mov rdx, rax;                                                               # Content to be printed
    Mov rdi, 2;                                                                 # Length of a byte in hex
    for my $i(0..7)
     {my $s = 8*$i;
      Mov rax,rdx;
      Shl rax,$s;                                                               # Push selected byte high
      Shr rax,56;                                                               # Push select byte low
      Shl rax,1;                                                                # Multiply by two because each entry in the translation table is two bytes long
      Lea rax, "[$hexTranslateTable+rax]";
      PrintOutMemory;
      PrintOutString ' ' if $i % 2;
     }
    RestoreFirstFour;
   } name => "PrintOutRaxInHex";

  Call $sub;
 }

sub ReverseBytesInRax                                                           # Reverse the bytes in rax
 {@_ == 0 or confess;
  Comment "Reverse bytes in rax";

  my $sub = S                                                                   # Reverse rax
   {my $size = RegisterSize rax;
    SaveFirstFour;
    ClearRegisters rsi;
    for(1..$size)                                                               # Reverse each byte
     {Mov rdi,rax;
      Shr rdi,($_-1)*8;
      Shl rdi,($size-1)*8;
      Shr rdi,($_-1)*8;
      Or  rsi,rdi;
     }
    Mov rax,rsi;
    RestoreFirstFourExceptRax;
   } name => "ReverseBytesInRax";

  Call $sub;
 }

sub PrintOutRaxInReverseInHex                                                   # Write the content of register rax to stderr in hexadecimal in little endian notation
 {@_ == 0 or confess;
  Comment "Print Rax In Reverse In Hex";
  ReverseBytesInRax;
  PrintOutRaxInHex;
 }

sub PrintOutRegisterInHex($)                                                    # Print any register as a hex string
 {my ($r) = @_;                                                                 # Name of the register to print
  Comment "Print register $r in Hex";
  @_ == 1 or confess;

  my $sub = S                                                                   # Reverse rax
   {PrintOutString sprintf("%6s: ", $r);

    my sub printReg(@)                                                          # Print the contents of a register
     {my (@regs) = @_;                                                          # Size in bytes, work registers
      my $s = RegisterSize $r;                                                  # Size of the register
      PushR @regs;                                                              # Save work registers
      PushR $r;                                                                 # Place register contents on stack
      PopR  @regs;                                                              # Load work registers
      for my $R(@regs)                                                          # Print work registers to print input register
       {if ($R !~ m(\Arax))
         {PrintOutString("  ");
          Mov rax, $R
         }
        PrintOutRaxInHex;                                                       # Print work register
       }
      PopR @regs;
     };
    if    ($r =~ m(\Ar)) {printReg qw(rax)}                                     # 64 bit register requested
    elsif ($r =~ m(\Ax)) {printReg qw(rax rbx)}                                 # xmm*
    elsif ($r =~ m(\Ay)) {printReg qw(rax rbx rcx rdx)}                         # ymm*
    elsif ($r =~ m(\Az)) {printReg qw(rax rbx rcx rdx r8 r9 r10 r11)}           # zmm*

    PrintOutNl;
   } name => "PrintOutRegister${r}InHex";                                       # One routine per register printed

  Call $sub;
 }

sub PrintOutRipInHex                                                            # Print the instruction pointer in hex
 {@_ == 0 or confess;
  my @regs = qw(rax);
  my $sub = S
   {PushR @regs;
    my $l = Label;
    push @text, <<END;
$l:
END
    Lea rax, "[$l]";                                                              # Current instruction pointer
    PrintOutString "rip: ";
    PrintOutRaxInHex;
    PrintOutNl;
    PopR @regs;
   } name=> "PrintOutRipInHex";

  Call $sub;
 }

sub PrintOutRflagsInHex                                                         # Print the flags register in hex
 {@_ == 0 or confess;
  my @regs = qw(rax);

  my $sub = S
   {PushR @regs;
    Pushfq;
    Pop rax;
    PrintOutString "rfl: ";
    PrintOutRaxInHex;
    PrintOutNl;
    PopR @regs;
   } name=> "PrintOutRflagsInHex";

  Call $sub;
 }

sub PrintOutRegistersInHex                                                      # Print the general purpose registers in hex
 {@_ == 0 or confess;

  my $sub = S
   {PrintOutRipInHex;
    PrintOutRflagsInHex;

    my @regs = qw(rax);
    PushR @regs;

    my $w = registers_64();
    for my $r(sort @$w)
     {next if $r =~ m(rip|rflags);
      if ($r eq rax)
       {Pop rax;
        Push rax
       }
      PrintOutString reverse(pad(reverse($r), 3)).": ";
      Mov rax, $r;
      PrintOutRaxInHex;
      PrintOutNl;
     }
    PopR @regs;
   } name=> "PrintOutRegistersInHex";

  Call $sub;
 }

#D1 Processes                                                                   # Create and manage processes

sub Fork()                                                                      # Fork
 {@_ == 0 or confess;
  Comment "Fork";
  Mov rax, 57;
  Syscall
 }

sub GetPid()                                                                    # Get process identifier
 {@_ == 0 or confess;
  Comment "Get Pid";

  Mov rax, 39;
  Syscall
 }

sub GetPPid()                                                                   # Get parent process identifier
 {@_ == 0 or confess;
  Comment "Get Parent Pid";

  Mov rax, 110;
  Syscall
 }

sub GetUid()                                                                    # Get userid of current process
 {@_ == 0 or confess;
  Comment "Get User id";

  Mov rax, 102;
  Syscall
 }

sub WaitPid()                                                                   # Wait for the pid in rax to complete
 {@_ == 0 or confess;
  Comment "WaitPid - wait for the pid in rax";
  SaveFirstSeven;
  Mov rdi,rax;
  Mov rax, 61;
  Mov rsi, 0;
  Mov rdx, 0;
  Mov r10, 0;
  Syscall;
  RestoreFirstSevenExceptRax;
 }

sub ReadTimeStampCounter()                                                      # Read the time stamp counter and return the time in nanoseconds in rax
 {@_ == 0 or confess;
  Comment "Read Time-Stamp Counter";
  Push rdx;
  Rdtsc;
  Shl rdx,32;                                                                   # Or upper half into rax
  Or rax,rdx;
  Pop rdx;
  RestoreFirstFourExceptRax;
 }

#D1 Stack                                                                       # Manage data on the stack

#D2 Push, Pop, Peek                                                             # Generic versions of push, pop, peek

sub PushR(@)                                                                    # Push registers onto the stack
 {my (@r) = @_;                                                                 # Register
  for my $r(@r)
   {my $size = RegisterSize $r;
    if    ($size > 8)
     {Sub rsp, $size;
      Vmovdqu32 "[rsp]", $r;
     }
    else
     {Push $r;
     }
   }
 }

sub PopR(@)                                                                     # Pop registers from the stack
 {my (@r) = @_;                                                                 # Register
  for my $r(reverse @r)                                                         # Pop registers in reverse order
   {my $size = RegisterSize $r;
    if    ($size > 8)
     {Vmovdqu32 $r, "[rsp]";
      Add(rsp, $size);
     }
    else
     {Pop $r;
     }
   }
 }

sub PeekR($)                                                                    # Peek at register on stack
 {my ($r) = @_;                                                                 # Register
  my $size = RegisterSize $r;
  if    ($size > 8)                                                             # x|y|zmm*
   {Vmovdqu32 $r, "[rsp]";
   }
  else                                                                          # 8 byte register
   {Mov $r, "[rsp]";
   }
 }

#D2 Declarations                                                                # Declare variables and structures

#D3 Structures                                                                  # Declare a structure

sub Structure($)                                                                # Create a structure addressed by a register
 {my ($register) = @_;                                                          # Register locating the structure
  @_ == 1 or confess;
  my $local = genHash("Structure",
    base      => $register,
    size      => 0,
    variables => [],
   );
 }

sub Structure::field($$;$)                                                      # Add a field of the specified length with an optional comment
 {my ($structure, $length, $comment) = @_;                                      # Structure data descriptor, length of data, optional comment
  @_ >= 2 or confess;
  my $variable = genHash("StructureField",
    structure  => $structure,
    loc        => $structure->size,
    size       => $length,
    comment    => $comment
   );
  $structure->size += $length;                                                  # Update size of local data
  $variable
 }

sub StructureField::addr($)                                                     # Address a field in a structure
 {my ($field) = @_;                                                             # Field
  @_ == 1 or confess;
  my $loc = $field->loc;                                                        # Offset of field in structure
  my $reg = $field->structure->base;                                            # Register locating the structure
  "[$loc+$reg]"                                                                 # Address field
 }

sub All8Structure($$)                                                           # Create a structure consisting of 8 byte fields
 {my ($base, $N) = @_;                                                          # Base register, Number of variables required
  @_ == 2 or confess;
  my $s = Structure $base;                                                      # Structure of specified size based on specified register
  my @f;
  for(1..$N)                                                                    # Create the variables
   {push @f, $s->field(RegisterSize rax)->addr;
   }
  ($s, @f)                                                                      # Structure, fields
 }

#D3 Stack Frame                                                                 # Declare local variables in a frame on the stack

sub LocalData()                                                                 # Map local data
 {@_ == 0 or confess;
  my $local = genHash("LocalData",
    size      => 0,
    variables => [],
   );
 }

sub LocalData::start($)                                                         # Start a local data area on the stack
 {my ($local) = @_;                                                             # Local data descriptor
  @_ == 1 or confess;
  my $size = $local->size;                                                      # Size of local data
  Push rbp;
  Mov rbp,rsp;
  Sub rsp, $size;
 }

sub LocalData::free($)                                                          # Free a local data area on the stack
 {my ($local) = @_;                                                             # Local data descriptor
  @_ == 1 or confess;
  Mov rsp,rbp;
  Pop rbp;
 }

sub LocalData::variable($$;$)                                                   # Add a local variable
 {my ($local, $length, $comment) = @_;                                          # Local data descriptor, length of data, optional comment
  @_ >= 2 or confess;
  my $variable = genHash("LocalVariable",
    loc        => $local->size,
    size       => $length,
    comment    => $comment
   );
  $local->size += $length;                                                      # Update size of local data
  $variable
 }

sub LocalVariable::stack($)                                                     # Address a local variable on the stack
 {my ($variable) = @_;                                                          # Variable
  @_ == 1 or confess;
  my $loc = $variable->loc;                                                     # Location of variable on stack
  "[$loc+rbp]"                                                                  # Address variable
 }

sub LocalData::allocate8($@)                                                    # Add some 8 byte local variables and return an array of variable definitions
 {my ($local, @comments) = @_;                                                  # Local data descriptor, optional comment
  my @v;
  for my $c(@comments)
   {push @v, LocalData::variable($local, 8, $c);
   }
  wantarray ? @v : $v[-1];                                                      # Avoid returning the number of elements accidently
 }

sub AllocateAll8OnStack($)                                                             # Create a local data descriptor consisting of the specified number of 8 byte local variables and return an array: (local data descriptor,  variable definitions...)
 {my ($N) = @_;                                                                 # Number of variables required
  my $local = LocalData;                                                        # Create local data descriptor
  my @v;
  for(1..$N)                                                                    # Create the variables
   {my $v = $local->variable(RegisterSize(rax));
    push @v, $v->stack;
   }
  $local->start;                                                                # Create the local data area on the stack
  ($local, @v)
 }

#D1 Memory                                                                      # Allocate and print memory

sub PrintOutMemoryInHex                                                         # Dump memory from the address in rax for the length in rdi
 {@_ == 0 or confess;
  Comment "Print out memory in hex";

  my $sub = S
   {my $size = RegisterSize rax;
    SaveFirstFour;
    Mov rsi,rax;                                                                # Position in memory
    Lea rdi,"[rax+rdi-$size+1]";                                                # Upper limit of printing with an 8 byte register
    For                                                                         # Print string in blocks
     {Mov rax, "[rsi]";
      ReverseBytesInRax;
      PrintOutRaxInHex;
     } rsi, rdi, $size;
    RestoreFirstFour;
   } name=> "PrintOutMemoryInHex";

  Call $sub;
 }

sub PrintOutMemory                                                              # Print the memory addressed by rax for a length of rdi
 {@_ == 0 or confess;
  Comment "Print memory";
  SaveFirstFour;
  Mov rsi, rax;
  Mov rdx, rdi;
  Mov rax, 1;
  Mov rdi, $sysout;
  Syscall;
  RestoreFirstFour();
 }

sub AllocateMemory                                                              # Allocate the amount of memory specified in rax via mmap and return the address of the allocated memory in rax
 {@_ == 0 or confess;
  Comment "Allocate memory";

  my $sub = S
   {SaveFirstSeven;
    my $d = extractMacroDefinitionsFromCHeaderFile "linux/mman.h";              # mmap constants
    my $pa = $$d{MAP_PRIVATE} | $$d{MAP_ANONYMOUS};
    my $wr = $$d{PROT_WRITE}  | $$d{PROT_READ};

    Mov rsi, rax;                                                               # Amount of memory
    Mov rax, 9;                                                                 # mmap
    Xor rdi, rdi;                                                               # Anywhere
    Mov rdx, $wr;                                                               # Read write protections
    Mov r10, $pa;                                                               # Private and anonymous map
    Mov r8,  -1;                                                                # File descriptor for file backing memory if any
    Mov r9,  0;                                                                 # Offset into file
    Syscall;
    RestoreFirstSevenExceptRax;
   } name=> "AllocateMemory";

  Call $sub;
 }

sub FreeMemory                                                                  # Free memory via mmap. The address of the memory is in rax, the length to free is in rdi
 {@_ == 0 or confess;
  Comment "Free memory";
  my $sub = S
   {SaveFirstFour;
    Mov rsi, rdi;
    Mov rdi, rax;
    Mov rax, 11;
    Syscall;
    RestoreFirstFourExceptRax;
   } name=> "FreeMemory";

  Call $sub;
 }

sub MemoryClear()                                                               # Clear memory - the address of the memory is in rax, the length in rdi
 {@_ == 0 or confess;
  Comment "Clear memory";

  my $size = RegisterSize zmm0;
  my $saveSize = SaveFirstFour;                                                 # Generated code
  PushR zmm0;                                                                   # Pump zeros with this register
  Lea rdi, "[rax+rdi-$size]";                                                   # Address of upper limit of buffer
  ClearRegisters zmm0;                                                          # Clear the register that will be written into memory

  For                                                                           # Clear memory
   {Vmovdqu64 "[rax]", zmm0;
   } rax, rdi, RegisterSize zmm0;

  PopR zmm0;
  RestoreFirstFour;
 }

#D1 Files                                                                       # Process a file

sub OpenRead()                                                                  # Open a file, whose name is addressed by rax, for read and return the file descriptor in rax
 {@_ == 0 or confess;
  Comment "Open a file for read";

  my $sub = S
   {my $S = extractMacroDefinitionsFromCHeaderFile "asm-generic/fcntl.h";       # Constants for reading a file
    my $O_RDONLY = $$S{O_RDONLY};
    SaveFirstFour;
    Mov rdi,rax;
    Mov rax,2;
    Mov rsi,$O_RDONLY;
    Xor rdx,rdx;
    Syscall;
    RestoreFirstFourExceptRax;
   } name=> "OpenRead";

  Call $sub;
 }

sub Close($)                                                                    # Close a file descriptor
 {my ($fdes) = @_;                                                              # File descriptor
  @_ == 1 or confess;
  Comment "Close a file";
  SaveFirstFour;
  Mov rdi,$fdes;
  Mov rax,3;
  Syscall;
  RestoreFirstFourExceptRax;
 }

sub StatSize()                                                                  # Stat a file whose name is addressed by rax to get its size in rax
 {@_ == 0 or confess;
  Comment "Stat a file for size";
  my $S = extractCStructure "#include <sys/stat.h>";                            # Get location of size field
  my $Size = $$S{stat}{size};
  my $off  = $$S{stat}{fields}{st_size}{loc};

  SaveFirstFour;
  Mov rdi, rax;                                                                 # File name
  Mov rax,4;
  Lea rsi, "[rsp-$Size]";
  Syscall;
  Mov rax, "[$off+rsp-$Size]";                                                  # Place size in rax
  RestoreFirstFourExceptRax;
 }

sub ReadFile()                                                                  # Read a file whose name is addressed by rax into memory.  The address of the mapped memory and its length are returned in registers rax,rdi
 {@_ == 0 or confess;
  Comment "Read a file into memory";

  SaveFirstSeven;                                                               # Generated code
  my ($local, $file, $addr, $size, $fdes) = AllocateAll8OnStack 4;                     # Local data

  Mov $file, rax;                                                               # Save file name

  StatSize;                                                                     # File size
  Mov $size, rax;                                                               # Save file size

  Mov rax, $file;                                                               # File name
  OpenRead;                                                                     # Open file for read
  Mov $fdes, rax;                                                               # Save file descriptor

  my $d  = extractMacroDefinitionsFromCHeaderFile "linux/mman.h";               # mmap constants
  my $pa = $$d{MAP_PRIVATE};
  my $ro = $$d{PROT_READ};

  Mov rax, 9;                                                                   # mmap
  Mov rsi, $size;                                                               # Amount of memory
  Xor rdi, rdi;                                                                 # Anywhere
  Mov rdx, $ro;                                                                 # Read write protections
  Mov r10, $pa;                                                                 # Private and anonymous map
  Mov r8,  $fdes;                                                               # File descriptor for file backing memory
  Mov r9,  0;                                                                   # Offset into file
  Syscall;
  Mov rdi, $size;
  RestoreFirstSevenExceptRaxAndRdi;
 }

#D1 Strings                                                                     # Operations on Strings

sub CreateByteString()                                                          # Create an relocatable string of bytes in an arena and returns its address in rax
 {@_ == 0 or confess;
  Comment "Create byte string";
  my $N = 4096;                                                                 # Initial size of string

  my ($string, $size, $used, $data) = All8Structure rax, 3;                     # String base

  my $sub = S                                                                   # Create string
   {SaveFirstFour;
    Mov rax, $N;
    AllocateMemory;
    ClearRegisters rdi;
    Mov $used, rdi;
    Mov rdi, $N;
    Mov $size, rdi;

    RestoreFirstFourExceptRax;
   } name=> "CreateByteString";

  Call $sub;

  genHash("ByteString",                                                         # Definition of byte string
    structure => $string,                                                       # Structure details
    size      => $size,                                                         # Size field details
    used      => $used,                                                         # Used field details
    data      => $data,                                                         # The first 8 bytes of the data
   );
 }

sub ByteString::ar($)                                                           # Append the content of rdi to the byte string addressed by rax
 {my ($byteString) = @_;                                                        # Byte string descriptor
  my $size = $byteString->size;
  my $used = $byteString->used;
  my $data = $byteString->data;

  SaveFirstFour;
  Lea rsi, $data;                                                               # Address of data field
  Add rsi, $used;                                                               # Skip over used data
  Mov "[rsi]", rdi;                                                             # Move data in

  Mov rsi, $used;                                                               # Increment used
  Add rsi, RegisterSize rdi;
  Mov $used, rsi;
  RestoreFirstFour;
 }

sub ByteString::out($)                                                          # Print the specified byte string addressed by rax on sysout
 {my ($byteString) = @_;                                                        # Byte string descriptor
  my $used = $byteString->used;
  my $data = $byteString->data;
  SaveFirstFour;
  Mov rdi, $used;                                                               # Length to print
  Lea rax, $data;                                                               # Address of data field
  PrintOutMemory;
  RestoreFirstFour;
 }

#D1 Assemble                                                                    # Assemble generated code

sub Start()                                                                     # Initialize the assembler
 {@bss = @data = @rodata = %rodata = %rodatas = %subroutines = @text = ();
  $Labels = 0;
 }

sub Exit(;$)                                                                    # Exit with the specified return code or zero if no return code supplied
 {my ($c) = @_;                                                                 # Return code
  if (@_ == 0 or $c == 0)
   {Comment "Exit code: 0";
    ClearRegisters rdi;
   }
  elsif (@_ == 1)
   {Comment "Exit code: $c";
    Mov rdi, $c;
   }
  Mov rax, 60;
  Syscall;
 }

sub Assemble(%)                                                                 # Assemble the generated code
 {my (%options) = @_;                                                           # Options
  my $r = join "\n", map {s/\s+\Z//sr} @rodata;
  my $d = join "\n", map {s/\s+\Z//sr} @data;
  my $b = join "\n", map {s/\s+\Z//sr} @bss;
  my $t = join "\n", map {s/\s+\Z//sr} @text;
  my $a = <<END;
section .rodata
  $r
section .data
  $d
section .bss
  $b
section .text
global _start, main
  _start:
  main:
  push rbp     ; function prologue
  mov  rbp,rsp
  $t
END

  my $c    = owf(q(z.asm), $a);                                                 # Source file
  my $e    =     q(z);                                                          # Executable file
  my $l    =     q(z.txt);                                                      # Assembler listing
  my $o    =     q(z.o);                                                        # Object file

  my $cmd  = qq(nasm -f elf64 -g -l $l -o $o $c; ld -o $e $o; chmod 744 $e; $sde -ptr-check -- ./$e 2>&1);
  say STDERR qq($cmd);
  my $R    = eval {qx($cmd)};
  say STDERR $R;
  unlink $e, $o;                                                                # Delete object and executable leaving listing files
  $R                                                                            # Return execution results
 }

#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(
 );
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Nasm::X86 - Generate Nasm assembler code

=head1 Synopsis

Write and execute x64 instructions from perl, using perl as a macro assembler
as shown in the following examples.

=head2 Avx512 instructions

Use avx512 instructions to reorder data using 512 bit zmm registers:

  Start;
  my $q = Rs my $s = join '', ('a'..'p')x4;;
  Mov rax, Ds('0'x128);

  Vmovdqu32 zmm0, "[$q]";
  Vprolq    zmm1, zmm0, 32;
  Vmovdqu32 "[rax]", zmm1;

  Mov rdi, length $s;
  PrintOutMemory;
  Exit;

  ok $s       =~ m(abcdefghijklmnopabcdefghijklmnopabcdefghijklmnopabcdefghijklmnop)s;
  ok Assemble =~ m(efghabcdmnopijklefghabcdmnopijklefghabcdmnopijklefghabcdmnopijkl)s;

=head2 Dynamic string held in an arena

Create a dynamic byte string, add some content to it and then print it.

  Start;                                                                        # Start the program
  my $s = CreateByteString;                                                     # Create a string
  Mov rdi, 0x68676665;                                                          # Load a string to append
  Shl rdi, 32;
  Or  rdi, 0x64636261;
  $s->ar;                                                                       # Add a string held in a register
  $s->ar;
  $s->out;                                                                      # Print byte string
  Exit;                                                                         # Return to operating system

  Assemble =~ m(abcdefghabcdefgh);                                              # Assemble and execute


=head2 Process management

Start a child process and wait for it, printing out the process identifiers of
each process involved:

  Start;                                                                        # Start the program
  Fork;                                                                         # Fork

  Test rax,rax;
  If                                                                            # Parent
   {Mov rbx, rax;
    WaitPid;
    PrintOutRegisterInHex rax;
    PrintOutRegisterInHex rbx;
    GetPid;                                                                     # Pid of parent as seen in parent
    Mov rcx,rax;
    PrintOutRegisterInHex rcx;
   }
  sub                                                                           # Child
   {Mov r8,rax;
    PrintOutRegisterInHex r8;
    GetPid;                                                                     # Child pid as seen in child
    Mov r9,rax;
    PrintOutRegisterInHex r9;
    GetPPid;                                                                    # Parent pid as seen in child
    Mov r10,rax;
    PrintOutRegisterInHex r10;
   };

  Exit;                                                                         # Return to operating system

  my $r = Assemble;

  #    r8: 0000 0000 0000 0000   #1 Return from fork as seen by child
  #    r9: 0000 0000 0003 0C63   #2 Pid of child
  #   r10: 0000 0000 0003 0C60   #3 Pid of parent from child
  #   rax: 0000 0000 0003 0C63   #4 Return from fork as seen by parent
  #   rbx: 0000 0000 0003 0C63   #5 Wait for child pid result
  #   rcx: 0000 0000 0003 0C60   #6 Pid of parent

=head2 Read a file

Read this file:

  Start;                                                                        # Start the program
  Mov rax, Rs($0);                                                              # File to read
  ReadFile;                                                                     # Read file
  PrintOutMemory;                                                               # Print memory
  Exit;                                                                         # Return to operating system

  my $r = Assemble;                                                             # Assemble and execute
  ok index($r, readFile($0)) > -1;                                              # Output contains this file

=head2 Installation

You will need the Intel Software Development Emulator and the Networkwide
Assembler installed on your test system.  For full details of how to do this
see: L<https://github.com/philiprbrenan/NasmX86/blob/main/.github/workflows/main.yml>

=head1 Description

Generate Nasm assembler code


Version "202104013".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Data

Layou data

=head2 SetLabel($l)

Set a label in the code section

     Parameter  Description
  1  $l         Label

=head2 Ds(@d)

Layout bytes in memory and return their label

     Parameter  Description
  1  @d         Data to be laid out

B<Example:>


    Start;
    my $q = Rs('a'..'z');

    Mov rax, Ds('0'x64);                                                          # Output area  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Vmovdqu32(xmm0, "[$q]");                                                      # Load
    Vprolq   (xmm0,   xmm0, 32);                                                  # Rotate double words in quad words
    Vmovdqu32("[rax]", xmm0);                                                      # Save
    Mov rdi, 16;
    PrintOutMemory;
    Exit;
    ok assemble() =~ m(efghabcdmnopijkl)s;


=head2 Rs(@d)

Layout bytes in read only memory and return their label

     Parameter  Description
  1  @d         Data to be laid out

B<Example:>


    Start;
    Comment "Print a string from memory";
    my $s = "Hello World";

    Mov rax, Rs($s);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Mov rdi, length $s;
    PrintOutMemory;
    Exit;
    ok assemble =~ m(Hello World);


=head2 Dbwdq($s, @d)

Layout data

     Parameter  Description
  1  $s         Element size
  2  @d         Data to be laid out

=head2 Db(@bytes)

Layout bytes in the data segment and return their label

     Parameter  Description
  1  @bytes     Bytes to layout

=head2 Dw(@words)

Layout words in the data segment and return their label

     Parameter  Description
  1  @words     Words to layout

=head2 Dd(@dwords)

Layout double words in the data segment and return their label

     Parameter  Description
  1  @dwords    Double words to layout

=head2 Dq(@qwords)

Layout quad words in the data segment and return their label

     Parameter  Description
  1  @qwords    Quad words to layout

=head2 Rbwdq($s, @d)

Layout data

     Parameter  Description
  1  $s         Element size
  2  @d         Data to be laid out

=head2 Rb(@bytes)

Layout bytes in the data segment and return their label

     Parameter  Description
  1  @bytes     Bytes to layout

=head2 Rw(@words)

Layout words in the data segment and return their label

     Parameter  Description
  1  @words     Words to layout

=head2 Rd(@dwords)

Layout double words in the data segment and return their label

     Parameter  Description
  1  @dwords    Double words to layout

=head2 Rq(@qwords)

Layout quad words in the data segment and return their label

     Parameter  Description
  1  @qwords    Quad words to layout

=head2 Comment(@comment)

Insert a comment into the assembly code

     Parameter  Description
  1  @comment   Text of comment

B<Example:>


    Start;

    Comment "Print a string from memory";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my $s = "Hello World";
    Mov rax, Rs($s);
    Mov rdi, length $s;
    PrintOutMemory;
    Exit;
    ok assemble =~ m(Hello World);


=head1 Registers

Operations on registers

=head2 SaveFirstFour()

Save the first 4 parameter registers


=head2 RestoreFirstFour()

Restore the first 4 parameter registers


=head2 RestoreFirstFourExceptRax()

Restore the first 4 parameter registers except rax so it can return its value


=head2 SaveFirstSeven()

Save the first 7 parameter registers


=head2 RestoreFirstSeven()

Restore the first 7 parameter registers


=head2 RestoreFirstSevenExceptRax()

Restore the first 7 parameter registers except rax which is being used to return the result


=head2 RestoreFirstSevenExceptRaxAndRdi()

Restore the first 7 parameter registers except rax and rdi which are being used to return the results


=head2 RegisterSize($r)

Return the size of a register

     Parameter  Description
  1  $r         Register

=head2 ClearRegisters(@registers)

Clear registers by setting them to zero

     Parameter   Description
  1  @registers  Registers

=head1 Structured Programming

Structured programming constructs

=head2 If($then, $else)

If

     Parameter  Description
  1  $then      Then - required
  2  $else      Else - optional

B<Example:>


    Start;
    Mov rax, 0;
    Test rax,rax;

    If  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {PrintOutRegisterInHex rax;
     } sub
     {PrintOutRegisterInHex rbx;
     };
    Mov rax, 1;
    Test rax,rax;

    If  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {PrintOutRegisterInHex rcx;
     } sub
     {PrintOutRegisterInHex rdx;
     };
    Exit;
    ok assemble() =~ m(rbx.*rcx)s;


=head2 For($body, $register, $limit, $increment)

For

     Parameter   Description
  1  $body       Body
  2  $register   Register
  3  $limit      Limit on loop
  4  $increment  Increment

B<Example:>


    Start;                                                                        # Start the program

    For  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {PrintOutRegisterInHex rax
     } rax, 16, 1;
    Exit;                                                                         # Return to operating system
    my $r = assemble;
    ok $r =~ m(( 0000){3} 0000)i;
    ok $r =~ m(( 0000){3} 000F)i;


=head2 S($body, %options)

Create a sub with optional parameters name=> the name of the subroutine so it can be reused rather than regenerated, comment=> a comment describing the sub

     Parameter  Description
  1  $body      Body
  2  %options   Options.

=head1 Print

Print

=head2 PrintOutNl()

Write a new line


B<Example:>


    Start;
    Comment "Print a string from memory";
    my $s = "Hello World";
    Mov rax, Rs($s);
    Mov rdi, length $s;
    PrintOutMemory;
    Exit;
    ok assemble =~ m(Hello World);


=head2 PrintOutString($string)

Write a constant string to sysout.

     Parameter  Description
  1  $string    String

B<Example:>


    Start;

    PrintOutString "Hello World";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Exit;
    ok assemble =~ m(Hello World);


=head2 PrintOutRaxInHex()

Write the content of register rax to stderr in hexadecimal in big endian notation


B<Example:>


    Start;
    my $q = Rs('abababab');
    Mov(rax, "[$q]");
    PrintOutString "rax: ";

    PrintOutRaxInHex;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutNl;
    Xor rax, rax;
    PrintOutString "rax: ";

    PrintOutRaxInHex;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutNl;
    Exit;
    ok assemble() =~ m(rax: 6261 6261 6261 6261.*rax: 0000 0000 0000 0000)s;


=head2 ReverseBytesInRax()

Reverse the bytes in rax


=head2 PrintOutRaxInReverseInHex()

Write the content of register rax to stderr in hexadecimal in little endian notation


B<Example:>


    Start;
    Mov rax, 0x88776655;
    Shl rax, 32;
    Or  rax, 0x44332211;
    PrintOutRaxInHex;

    PrintOutRaxInReverseInHex;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Exit;
    ok assemble =~ m(8877 6655 4433 2211 1122 3344 5566 7788)s;


=head2 PrintOutRegisterInHex($r)

Print any register as a hex string

     Parameter  Description
  1  $r         Name of the register to print

B<Example:>


    Start;
    my $q = Rs(('a'..'p')x4);
    Mov r8,"[$q]";

    PrintOutRegisterInHex r8;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Exit;
    ok assemble() =~ m(r8: 6867 6665 6463 6261)s;


=head2 PrintOutRipInHex()

Print the instruction pointer in hex


=head2 PrintOutRflagsInHex()

Print the flags register in hex


=head2 PrintOutRegistersInHex()

Print the general purpose registers in hex


B<Example:>


    Start;
    my $q = Rs('abababab');
    Mov(rax, 1);
    Mov(rbx, 2);
    Mov(rcx, 3);
    Mov(rdx, 4);
    Mov(r8,  5);
    Lea r9,  "[rax+rbx]";

    PrintOutRegistersInHex;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Exit;
    my $r = assemble();
    ok $r =~ m( r8: 0000 0000 0000 0005.* r9: 0000 0000 0000 0003.*rax: 0000 0000 0000 0001)s;
    ok $r =~ m(rbx: 0000 0000 0000 0002.*rcx: 0000 0000 0000 0003.*rdx: 0000 0000 0000 0004)s;


=head1 Processes

Create and manage processes

=head2 Fork()

Fork


B<Example:>


    Start;                                                                        # Start the program

    Fork;                                                                         # Fork  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    Test rax,rax;
    If                                                                            # Parent
     {Mov rbx, rax;
      WaitPid;
      PrintOutRegisterInHex rax;
      PrintOutRegisterInHex rbx;
      GetPid;                                                                     # Pid of parent as seen in parent
      Mov rcx,rax;
      PrintOutRegisterInHex rcx;
     }
    sub                                                                           # Child
     {Mov r8,rax;
      PrintOutRegisterInHex r8;
      GetPid;                                                                     # Child pid as seen in child
      Mov r9,rax;
      PrintOutRegisterInHex r9;
      GetPPid;                                                                    # Parent pid as seen in child
      Mov r10,rax;
      PrintOutRegisterInHex r10;
     };

    Exit;                                                                         # Return to operating system

    my $r = assemble();

  #    r8: 0000 0000 0000 0000   #1 Return from fork as seen by child
  #    r9: 0000 0000 0003 0C63   #2 Pid of child
  #   r10: 0000 0000 0003 0C60   #3 Pid of parent from child
  #   rax: 0000 0000 0003 0C63   #4 Return from fork as seen by parent
  #   rbx: 0000 0000 0003 0C63   #5 Wait for child pid result
  #   rcx: 0000 0000 0003 0C60   #6 Pid of parent

    if ($r =~ m(r8:( 0000){4}.*r9:(.*)\s{5,}r10:(.*)\s{5,}rax:(.*)\s{5,}rbx:(.*)\s{5,}rcx:(.*)\s{2,})s)
     {ok $2 eq $4;
      ok $2 eq $5;
      ok $3 eq $6;
      ok $2 gt $6;
     }

    Start;                                                                        # Start the program
    GetUid;                                                                       # Userid
    PrintOutRegisterInHex rax;
    Exit;                                                                         # Return to operating system
    my $r = assemble();
    ok $r =~ m(rax:( 0000){3});


=head2 GetPid()

Get process identifier


B<Example:>


    Start;                                                                        # Start the program
    Fork;                                                                         # Fork

    Test rax,rax;
    If                                                                            # Parent
     {Mov rbx, rax;
      WaitPid;
      PrintOutRegisterInHex rax;
      PrintOutRegisterInHex rbx;

      GetPid;                                                                     # Pid of parent as seen in parent  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Mov rcx,rax;
      PrintOutRegisterInHex rcx;
     }
    sub                                                                           # Child
     {Mov r8,rax;
      PrintOutRegisterInHex r8;

      GetPid;                                                                     # Child pid as seen in child  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Mov r9,rax;
      PrintOutRegisterInHex r9;
      GetPPid;                                                                    # Parent pid as seen in child
      Mov r10,rax;
      PrintOutRegisterInHex r10;
     };

    Exit;                                                                         # Return to operating system

    my $r = assemble();

  #    r8: 0000 0000 0000 0000   #1 Return from fork as seen by child
  #    r9: 0000 0000 0003 0C63   #2 Pid of child
  #   r10: 0000 0000 0003 0C60   #3 Pid of parent from child
  #   rax: 0000 0000 0003 0C63   #4 Return from fork as seen by parent
  #   rbx: 0000 0000 0003 0C63   #5 Wait for child pid result
  #   rcx: 0000 0000 0003 0C60   #6 Pid of parent

    if ($r =~ m(r8:( 0000){4}.*r9:(.*)\s{5,}r10:(.*)\s{5,}rax:(.*)\s{5,}rbx:(.*)\s{5,}rcx:(.*)\s{2,})s)
     {ok $2 eq $4;
      ok $2 eq $5;
      ok $3 eq $6;
      ok $2 gt $6;
     }

    Start;                                                                        # Start the program
    GetUid;                                                                       # Userid
    PrintOutRegisterInHex rax;
    Exit;                                                                         # Return to operating system
    my $r = assemble();
    ok $r =~ m(rax:( 0000){3});


=head2 GetPPid()

Get parent process identifier


B<Example:>


    Start;                                                                        # Start the program
    Fork;                                                                         # Fork

    Test rax,rax;
    If                                                                            # Parent
     {Mov rbx, rax;
      WaitPid;
      PrintOutRegisterInHex rax;
      PrintOutRegisterInHex rbx;
      GetPid;                                                                     # Pid of parent as seen in parent
      Mov rcx,rax;
      PrintOutRegisterInHex rcx;
     }
    sub                                                                           # Child
     {Mov r8,rax;
      PrintOutRegisterInHex r8;
      GetPid;                                                                     # Child pid as seen in child
      Mov r9,rax;
      PrintOutRegisterInHex r9;

      GetPPid;                                                                    # Parent pid as seen in child  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Mov r10,rax;
      PrintOutRegisterInHex r10;
     };

    Exit;                                                                         # Return to operating system

    my $r = assemble();

  #    r8: 0000 0000 0000 0000   #1 Return from fork as seen by child
  #    r9: 0000 0000 0003 0C63   #2 Pid of child
  #   r10: 0000 0000 0003 0C60   #3 Pid of parent from child
  #   rax: 0000 0000 0003 0C63   #4 Return from fork as seen by parent
  #   rbx: 0000 0000 0003 0C63   #5 Wait for child pid result
  #   rcx: 0000 0000 0003 0C60   #6 Pid of parent

    if ($r =~ m(r8:( 0000){4}.*r9:(.*)\s{5,}r10:(.*)\s{5,}rax:(.*)\s{5,}rbx:(.*)\s{5,}rcx:(.*)\s{2,})s)
     {ok $2 eq $4;
      ok $2 eq $5;
      ok $3 eq $6;
      ok $2 gt $6;
     }

    Start;                                                                        # Start the program
    GetUid;                                                                       # Userid
    PrintOutRegisterInHex rax;
    Exit;                                                                         # Return to operating system
    my $r = assemble();
    ok $r =~ m(rax:( 0000){3});


=head2 GetUid()

Get userid of current process


=head2 WaitPid()

Wait for the pid in rax to complete


B<Example:>


    Start;                                                                        # Start the program
    Fork;                                                                         # Fork

    Test rax,rax;
    If                                                                            # Parent
     {Mov rbx, rax;

      WaitPid;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      PrintOutRegisterInHex rax;
      PrintOutRegisterInHex rbx;
      GetPid;                                                                     # Pid of parent as seen in parent
      Mov rcx,rax;
      PrintOutRegisterInHex rcx;
     }
    sub                                                                           # Child
     {Mov r8,rax;
      PrintOutRegisterInHex r8;
      GetPid;                                                                     # Child pid as seen in child
      Mov r9,rax;
      PrintOutRegisterInHex r9;
      GetPPid;                                                                    # Parent pid as seen in child
      Mov r10,rax;
      PrintOutRegisterInHex r10;
     };

    Exit;                                                                         # Return to operating system

    my $r = assemble();

  #    r8: 0000 0000 0000 0000   #1 Return from fork as seen by child
  #    r9: 0000 0000 0003 0C63   #2 Pid of child
  #   r10: 0000 0000 0003 0C60   #3 Pid of parent from child
  #   rax: 0000 0000 0003 0C63   #4 Return from fork as seen by parent
  #   rbx: 0000 0000 0003 0C63   #5 Wait for child pid result
  #   rcx: 0000 0000 0003 0C60   #6 Pid of parent

    if ($r =~ m(r8:( 0000){4}.*r9:(.*)\s{5,}r10:(.*)\s{5,}rax:(.*)\s{5,}rbx:(.*)\s{5,}rcx:(.*)\s{2,})s)
     {ok $2 eq $4;
      ok $2 eq $5;
      ok $3 eq $6;
      ok $2 gt $6;
     }

    Start;                                                                        # Start the program
    GetUid;                                                                       # Userid
    PrintOutRegisterInHex rax;
    Exit;                                                                         # Return to operating system
    my $r = assemble();
    ok $r =~ m(rax:( 0000){3});


=head2 ReadTimeStampCounter()

Read the time stamp counter


B<Example:>


    Start;
    for(1..10)

     {ReadTimeStampCounter;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      PrintOutRegisterInHex rax;
     }
    Exit;
    my @s = split /
/, assemble();
    my @S = sort @s;
    is_deeply \@s, \@S;


=head1 Stack

Manage data on the stack

=head2 Push, Pop, Peek

Generic versions of push, pop, peek

=head3 PushR(@r)

Push registers onto the stack

     Parameter  Description
  1  @r         Register

=head3 PopR(@r)

Pop registers from the stack

     Parameter  Description
  1  @r         Register

B<Example:>


    Start;
    my $q = Rs my $s = join '', ('a'..'p')x4;;
    Mov rax, Ds('0'x128);

    Vmovdqu32 zmm0, "[$q]";
    Vprolq    zmm1, zmm0, 32;
    Vmovdqu32 "[rax]", zmm1;

    Mov rdi, length $s;
    PrintOutMemory;
    Exit;

    ok $s         =~ m(abcdefghijklmnopabcdefghijklmnopabcdefghijklmnopabcdefghijklmnop)s;
    ok assemble() =~ m(efghabcdmnopijklefghabcdmnopijklefghabcdmnopijklefghabcdmnopijkl)s;


=head3 PeekR($r)

Peek at register on stack

     Parameter  Description
  1  $r         Register

=head2 Declarations

Declare local varibles in a frame on the stack

=head3 LocalData()

Map local data


=head3 LocalData::start($local)

Start a local data area on the stack

     Parameter  Description
  1  $local     Local data descriptor

=head3 LocalData::free($local)

Free a local data area on the stack

     Parameter  Description
  1  $local     Local data descriptor

=head3 LocalData::variable($local, $length, $comment)

Add a local variable

     Parameter  Description
  1  $local     Local data descriptor
  2  $length    Length of data
  3  $comment   Optional comment

=head3 LocalVariable::stack($variable)

Address a local variable on the stack

     Parameter  Description
  1  $variable  Variable

=head3 LocalData::allocate8($local, @comments)

Add some 8 byte local variables and return an array of variable definitions

     Parameter  Description
  1  $local     Local data descriptor
  2  @comments  Optional comment

=head3 AllocateAll8OnStack($N)

Create a local data descriptor consisting of the specified number of 8 byte local variables and return an array: (local data descriptor,  variable definitions...)

     Parameter  Description
  1  $N         Number of variables required

=head1 Memory

Allocate and print memory

=head2 PrintOutMemoryInHex()

Dump memory from the address in rax for the length in rdi


=head2 PrintOutMemory()

Print the memory addressed by rax for a length of rdi


=head2 AllocateMemory()

Allocate the amount of memory specified in rax via mmap and return the address of the allocated memory in rax


B<Example:>


    Start;
    my $N = 2048;
    my $q = Rs('a'..'p');
    Mov rax, $N;

    AllocateMemory;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegisterInHex rax;

    Vmovdqu8 xmm0, "[$q]";
    Vmovdqu8 "[rax]", xmm0;
    Mov rdi,16;
    PrintOutMemory;
    PrintOutNl;

    Mov rdi, $N;
    FreeMemory;
    PrintOutRegisterInHex rax;
    Exit;
    ok assemble() =~ m(abcdefghijklmnop)s;

    Start;
    my $N = 4096;
    my $S = RegisterSize rax;
    Mov rax, $N;

    AllocateMemory;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegisterInHex rax;
    Mov rdi, $N;
    MemoryClear;
    PrintOutRegisterInHex rax;
    PrintOutMemoryInHex;
    Exit;

    my $r = assemble;
    if ($r =~ m((0000.*0000))s)
     {is_deeply length($1), 10269;
     }


=head2 FreeMemory()

Free memory via mmap. The address of the memory is in rax, the length to free is in rdi


B<Example:>


    Start;
    my $N = 2048;
    my $q = Rs('a'..'p');
    Mov rax, $N;
    AllocateMemory;
    PrintOutRegisterInHex rax;

    Vmovdqu8 xmm0, "[$q]";
    Vmovdqu8 "[rax]", xmm0;
    Mov rdi,16;
    PrintOutMemory;
    PrintOutNl;

    Mov rdi, $N;

    FreeMemory;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegisterInHex rax;
    Exit;
    ok assemble() =~ m(abcdefghijklmnop)s;

    Start;
    my $N = 4096;
    my $S = RegisterSize rax;
    Mov rax, $N;
    AllocateMemory;
    PrintOutRegisterInHex rax;
    Mov rdi, $N;
    MemoryClear;
    PrintOutRegisterInHex rax;
    PrintOutMemoryInHex;
    Exit;

    my $r = assemble;
    if ($r =~ m((0000.*0000))s)
     {is_deeply length($1), 10269;
     }


=head2 MemoryClear()

Clear memory - the address of the memory is in rax, the length in rdi


=head1 Files

Process a file

=head2 OpenRead()

Open a file, whose name is addressed by rax, for read and return the file descriptor in rax


B<Example:>


    Start;                                                                        # Start the program
    Mov rax, Rs($0);                                                              # File to stat

    OpenRead;                                                                     # Open file  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegisterInHex rax;
    Close(rax);                                                                   # Close file
    PrintOutRegisterInHex rax;
    Exit;                                                                         # Return to operating system
    my $r = assemble();
    ok $r =~ m(( 0000){3} 0003)i;                                                 # Expected file number
    ok $r =~ m(( 0000){4})i;                                                      # Expected file number


=head2 Close($fdes)

Close a file descriptor

     Parameter  Description
  1  $fdes      File descriptor

B<Example:>


    Start;                                                                        # Start the program
    Mov rax, Rs($0);                                                              # File to stat
    OpenRead;                                                                     # Open file
    PrintOutRegisterInHex rax;

    Close(rax);                                                                   # Close file  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegisterInHex rax;
    Exit;                                                                         # Return to operating system
    my $r = assemble();
    ok $r =~ m(( 0000){3} 0003)i;                                                 # Expected file number
    ok $r =~ m(( 0000){4})i;                                                      # Expected file number


=head2 StatSize()

Stat a file whose name is addressed by rax to get its size in rax


B<Example:>


    Start;                                                                        # Start the program
    Mov rax, Rs($0);                                                              # File to stat

    StatSize;                                                                     # Stat the file  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegisterInHex rax;
    Exit;                                                                         # Return to operating system
    my $r = assemble() =~ s( ) ()gsr;
    if ($r =~ m(rax:([0-9a-f]{16}))is)                                            # Compare file size obtained with that from fileSize()
     {is_deeply $1, sprintf("%016X", fileSize($0));
     }


=head2 ReadFile()

Read a file whose name is addressed by rax into memory.  The address of the mapped memory and its length are returned in registers rax,rdi


B<Example:>


    Start;                                                                        # Start the program
    Mov rax, Rs($0);                                                              # File to read

    ReadFile;                                                                     # Read file  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutMemory;                                                               # Print memory
    Exit;                                                                         # Return to operating system
    my $r = assemble();                                                           # Assemble and execute
    ok index($r =~ s([^0x0-0x7f]) ()gsr, readFile($0) =~ s([^0x0-0x7f]) ()gsr)>-1;# Output contains this file


=head1 Assemble

Assemble generated code

=head2 Start()

Initialize the assembler


B<Example:>



    Start;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutString "Hello World";
    Exit;
    ok assemble =~ m(Hello World);


=head2 Exit($c)

Exit with the specified return code or zero if no return code supplied

     Parameter  Description
  1  $c         Return code

B<Example:>


    Start;
    PrintOutString "Hello World";

    Exit;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok assemble =~ m(Hello World);


=head2 assemble(%options)

Assemble the generated code

     Parameter  Description
  1  %options   Options

B<Example:>


    Start;
    PrintOutString "Hello World";
    Exit;

    ok assemble =~ m(Hello World);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲




=head1 Private Methods

=head2 label()

Create a unique label



=head1 Index


1 L<AllocateAll8OnStack|/AllocateAll8OnStack> - Create a local data descriptor consisting of the specified number of 8 byte local variables and return an array: (local data descriptor,  variable definitions.

2 L<AllocateMemory|/AllocateMemory> - Allocate the amount of memory specified in rax via mmap and return the address of the allocated memory in rax

3 L<assemble|/assemble> - Assemble the generated code

4 L<ClearRegisters|/ClearRegisters> - Clear registers by setting them to zero

5 L<Close|/Close> - Close a file descriptor

6 L<Comment|/Comment> - Insert a comment into the assembly code

7 L<Db|/Db> - Layout bytes in the data segment and return their label

8 L<Dbwdq|/Dbwdq> - Layout data

9 L<Dd|/Dd> - Layout double words in the data segment and return their lab

10 L<Dq|/Dq> - Layout quad words in the data segment and return their label

11 L<Ds|/Ds> - Layout bytes in memory and return their label

12 L<Dw|/Dw> - Layout words in the data segment and return their label

13 L<Exit|/Exit> - Exit with the specified return code or zero if no return code supplied

14 L<For|/For> - For

15 L<Fork|/Fork> - Fork

16 L<FreeMemory|/FreeMemory> - Free memory via mmap.

17 L<GetPid|/GetPid> - Get process identifier

18 L<GetPPid|/GetPPid> - Get parent process identifier

19 L<GetUid|/GetUid> - Get userid of current process

20 L<If|/If> - If

21 L<label|/label> - Create a unique label

22 L<LocalData|/LocalData> - Map local data

23 L<LocalData::allocate8|/LocalData::allocate8> - Add some 8 byte local variables and return an array of variable definitions

24 L<LocalData::free|/LocalData::free> - Free a local data area on the stack

25 L<LocalData::start|/LocalData::start> - Start a local data area on the stack

26 L<LocalData::variable|/LocalData::variable> - Add a local variable

27 L<LocalVariable::stack|/LocalVariable::stack> - Address a local variable on the stack

28 L<MemoryClear|/MemoryClear> - Clear memory - the address of the memory is in rax, the length in rdi

29 L<OpenRead|/OpenRead> - Open a file, whose name is addressed by rax, for read and return the file descriptor in rax

30 L<PeekR|/PeekR> - Peek at register on stack

31 L<PopR|/PopR> - Pop registers from the stack

32 L<PrintOutMemory|/PrintOutMemory> - Print the memory addressed by rax for a length of rdi

33 L<PrintOutMemoryInHex|/PrintOutMemoryInHex> - Dump memory from the address in rax for the length in rdi

34 L<PrintOutNl|/PrintOutNl> - Write a new line

35 L<PrintOutRaxInHex|/PrintOutRaxInHex> - Write the content of register rax to stderr in hexadecimal in big endian notation

36 L<PrintOutRaxInReverseInHex|/PrintOutRaxInReverseInHex> - Write the content of register rax to stderr in hexadecimal in little endian notation

37 L<PrintOutRegisterInHex|/PrintOutRegisterInHex> - Print any register as a hex string

38 L<PrintOutRegistersInHex|/PrintOutRegistersInHex> - Print the general purpose registers in hex

39 L<PrintOutRflagsInHex|/PrintOutRflagsInHex> - Print the flags register in hex

40 L<PrintOutRipInHex|/PrintOutRipInHex> - Print the instruction pointer in hex

41 L<PrintOutString|/PrintOutString> - Write a constant string to sysout.

42 L<PushR|/PushR> - Push registers onto the stack

43 L<Rb|/Rb> - Layout bytes in the data segment and return their label

44 L<Rbwdq|/Rbwdq> - Layout data

45 L<Rd|/Rd> - Layout double words in the data segment and return their label

46 L<ReadFile|/ReadFile> - Read a file whose name is addressed by rax into memory.

47 L<ReadTimeStampCounter|/ReadTimeStampCounter> - Read the time stamp counter

48 L<RegisterSize|/RegisterSize> - Return the size of a register

49 L<RestoreFirstFour|/RestoreFirstFour> - Restore the first 4 parameter registers

50 L<RestoreFirstFourExceptRax|/RestoreFirstFourExceptRax> - Restore the first 4 parameter registers except rax so it can return its value

51 L<RestoreFirstSeven|/RestoreFirstSeven> - Restore the first 7 parameter registers

52 L<RestoreFirstSevenExceptRax|/RestoreFirstSevenExceptRax> - Restore the first 7 parameter registers except rax which is being used to return the result

53 L<RestoreFirstSevenExceptRaxAndRdi|/RestoreFirstSevenExceptRaxAndRdi> - Restore the first 7 parameter registers except rax and rdi which are being used to return the results

54 L<ReverseBytesInRax|/ReverseBytesInRax> - Reverse the bytes in rax

55 L<Rq|/Rq> - Layout quad words in the data segment and return their label

56 L<Rs|/Rs> - Layout bytes in read only memory and return their label

57 L<Rw|/Rw> - Layout words in the data segment and return their label

58 L<S|/S> - Create a sub with optional parameters name=> the name of the subroutine so it can be reused rather than regenerated, comment=> a comment describing the sub

59 L<SaveFirstFour|/SaveFirstFour> - Save the first 4 parameter registers

60 L<SaveFirstSeven|/SaveFirstSeven> - Save the first 7 parameter registers

61 L<SetLabel|/SetLabel> - Set a label in the code section

62 L<Start|/Start> - Initialize the assembler

63 L<StatSize|/StatSize> - Stat a file whose name is addressed by rax to get its size in rax

64 L<WaitPid|/WaitPid> - Wait for the pid in rax to complete

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Nasm::X86

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
#__DATA__
use Time::HiRes qw(time);
use Test::More;

my $localTest = ((caller(1))[0]//'Nasm::X86') eq "Nasm::X86";                   # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

$ENV{PATH} = $ENV{PATH}.":/var/isde:sde";                                       # Intel emulator

if ($^O =~ m(bsd|linux)i)                                                       # Supported systems
 {if (confirmHasCommandLineCommand(q(nasm)) and                                 # Network assembler
      confirmHasCommandLineCommand(q(sde64)))                                   # Intel emulator
   {plan tests => 30;
   }
  else
   {plan skip_all =>qq(Nasm or Intel 64 emulator not available);
   }
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

my $start = time;                                                               # Tests

#goto latest;

if (1) {                                                                        #TExit #TPrintOutString #Tassemble #TStart
  Start;
  PrintOutString "Hello World";
  Exit;
  ok Assemble =~ m(Hello World);
 }

if (1) {                                                                        #TMov #TComment #TRs #TPrintOutNl
  Start;
  Comment "Print a string from memory";
  my $s = "Hello World";
  Mov rax, Rs($s);
  Mov rdi, length $s;
  PrintOutMemory;
  Exit;
  ok Assemble =~ m(Hello World);
 }

if (1) {                                                                        #TPrintOutRaxInHex #TXor
  Start;
  my $q = Rs('abababab');
  Mov(rax, "[$q]");
  PrintOutString "rax: ";
  PrintOutRaxInHex;
  PrintOutNl;
  Xor rax, rax;
  PrintOutString "rax: ";
  PrintOutRaxInHex;
  PrintOutNl;
  Exit;
  ok Assemble =~ m(rax: 6261 6261 6261 6261.*rax: 0000 0000 0000 0000)s;
 }

if (1) {                                                                        #TPrintOutRegistersInHex #TLea
  Start;
  my $q = Rs('abababab');
  Mov(rax, 1);
  Mov(rbx, 2);
  Mov(rcx, 3);
  Mov(rdx, 4);
  Mov(r8,  5);
  Lea r9,  "[rax+rbx]";
  PrintOutRegistersInHex;
  Exit;
  my $r = Assemble;
  ok $r =~ m( r8: 0000 0000 0000 0005.* r9: 0000 0000 0000 0003.*rax: 0000 0000 0000 0001)s;
  ok $r =~ m(rbx: 0000 0000 0000 0002.*rcx: 0000 0000 0000 0003.*rdx: 0000 0000 0000 0004)s;
 }

if (1) {                                                                        #TVmovdqu32 #TVprolq  #TDs
  Start;
  my $q = Rs('a'..'z');
  Mov rax, Ds('0'x64);                                                          # Output area
  Vmovdqu32(xmm0, "[$q]");                                                      # Load
  Vprolq   (xmm0,   xmm0, 32);                                                  # Rotate double words in quad words
  Vmovdqu32("[rax]", xmm0);                                                      # Save
  Mov rdi, 16;
  PrintOutMemory;
  Exit;
  ok Assemble =~ m(efghabcdmnopijkl)s;
 }

if (1) {
  Start;
  my $q = Rs(('a'..'p')x2);
  Mov rax, Ds('0'x64);
  Vmovdqu32(ymm0, "[$q]");
  Vprolq   (ymm0,   ymm0, 32);
  Vmovdqu32("[rax]", ymm0);
  Mov rdi, 32;
  PrintOutMemory;
  Exit;
  ok Assemble =~ m(efghabcdmnopijklefghabcdmnopijkl)s;
 }

if (1) {                                                                        #TPopR #TVmovdqu64
  Start;
  my $q = Rs my $s = join '', ('a'..'p')x4;;
  Mov rax, Ds('0'x128);

  Vmovdqu32 zmm0, "[$q]";
  Vprolq    zmm1, zmm0, 32;
  Vmovdqu32 "[rax]", zmm1;

  Mov rdi, length $s;
  PrintOutMemory;
  Exit;

  ok $s       =~ m(abcdefghijklmnopabcdefghijklmnopabcdefghijklmnopabcdefghijklmnop)s;
  ok Assemble =~ m(efghabcdmnopijklefghabcdmnopijklefghabcdmnopijklefghabcdmnopijkl)s;
 }

if (1) {                                                                        #TPrintOutRegisterInHex
  Start;
  my $q = Rs(('a'..'p')x4);
  Mov r8,"[$q]";
  PrintOutRegisterInHex r8;
  Exit;
  ok Assemble =~ m(r8: 6867 6665 6463 6261)s;
 }

if (1) {                                                                        #TVmovdqu8
  Start;
  my $q = Rs('a'..'p');
  Vmovdqu8 xmm0, "[$q]";
  PrintOutRegisterInHex xmm0;
  Exit;
  ok Assemble =~ m(xmm0: 706F 6E6D 6C6B 6A69   6867 6665 6463 6261)s;
 }

if (1) {
  Start;
  my $q = Rs('a'..'p', 'A'..'P', );
  Vmovdqu8 ymm0, "[$q]";
  PrintOutRegisterInHex ymm0;
  Exit;
  ok Assemble =~ m(ymm0: 504F 4E4D 4C4B 4A49   4847 4645 4443 4241   706F 6E6D 6C6B 6A69   6867 6665 6463 6261)s;
 }

if (1) {
  Start;
  my $q = Rs(('a'..'p', 'A'..'P') x 2);
  Vmovdqu8 zmm0, "[$q]";
  PrintOutRegisterInHex zmm0;
  Exit;
  ok Assemble =~ m(zmm0: 504F 4E4D 4C4B 4A49   4847 4645 4443 4241   706F 6E6D 6C6B 6A69   6867 6665 6463 6261   504F 4E4D 4C4B 4A49   4847 4645 4443 4241   706F 6E6D 6C6B 6A69   6867 6665 6463 6261)s;
 }

if (1) {                                                                        #TAllocateMemory #TFreeMemory
  Start;
  my $N = 2048;
  my $q = Rs('a'..'p');
  Mov rax, $N;
  AllocateMemory;
  PrintOutRegisterInHex rax;

  Vmovdqu8 xmm0, "[$q]";
  Vmovdqu8 "[rax]", xmm0;
  Mov rdi,16;
  PrintOutMemory;
  PrintOutNl;

  Mov rdi, $N;
  FreeMemory;
  PrintOutRegisterInHex rax;
  Exit;
  ok Assemble =~ m(abcdefghijklmnop)s;
 }

if (1) {                                                                        #TReadTimeStampCounter
  Start;
  for(1..10)
   {ReadTimeStampCounter;
    PrintOutRegisterInHex rax;
   }
  Exit;
  my @s = split /\n/, Assemble;
  my @S = sort @s;
  is_deeply \@s, \@S;
 }

if (1) {                                                                        #TIf
  Start;
  Mov rax, 0;
  Test rax,rax;
  If
   {PrintOutRegisterInHex rax;
   } sub
   {PrintOutRegisterInHex rbx;
   };
  Mov rax, 1;
  Test rax,rax;
  If
   {PrintOutRegisterInHex rcx;
   } sub
   {PrintOutRegisterInHex rdx;
   };
  Exit;
  ok Assemble =~ m(rbx.*rcx)s;
 }

if (1) {                                                                        #TFork #TGetPid #TGetPPid #TWaitPid
  Start;                                                                        # Start the program
  Fork;                                                                         # Fork

  Test rax,rax;
  If                                                                            # Parent
   {Mov rbx, rax;
    WaitPid;
    PrintOutRegisterInHex rax;
    PrintOutRegisterInHex rbx;
    GetPid;                                                                     # Pid of parent as seen in parent
    Mov rcx,rax;
    PrintOutRegisterInHex rcx;
   }
  sub                                                                           # Child
   {Mov r8,rax;
    PrintOutRegisterInHex r8;
    GetPid;                                                                     # Child pid as seen in child
    Mov r9,rax;
    PrintOutRegisterInHex r9;
    GetPPid;                                                                    # Parent pid as seen in child
    Mov r10,rax;
    PrintOutRegisterInHex r10;
   };

  Exit;                                                                         # Return to operating system

  my $r = Assemble;

#    r8: 0000 0000 0000 0000   #1 Return from fork as seen by child
#    r9: 0000 0000 0003 0C63   #2 Pid of child
#   r10: 0000 0000 0003 0C60   #3 Pid of parent from child
#   rax: 0000 0000 0003 0C63   #4 Return from fork as seen by parent
#   rbx: 0000 0000 0003 0C63   #5 Wait for child pid result
#   rcx: 0000 0000 0003 0C60   #6 Pid of parent

  if ($r =~ m(r8:( 0000){4}.*r9:(.*)\s{5,}r10:(.*)\s{5,}rax:(.*)\s{5,}rbx:(.*)\s{5,}rcx:(.*)\s{2,})s)
   {ok $2 eq $4;
    ok $2 eq $5;
    ok $3 eq $6;
    ok $2 gt $6;
   }
 }

if (1) {                                                                        #TFork #TGetPid #TGetPPid #TWaitPid
  Start;                                                                        # Start the program
  GetUid;                                                                       # Userid
  PrintOutRegisterInHex rax;
  Exit;                                                                         # Return to operating system
  my $r = Assemble;
  ok $r =~ m(rax:( 0000){3});
 }

if (1) {                                                                        #TStatSize
  Start;                                                                        # Start the program
  Mov rax, Rs($0);                                                              # File to stat
  StatSize;                                                                     # Stat the file
  PrintOutRegisterInHex rax;
  Exit;                                                                         # Return to operating system
  my $r = Assemble =~ s( ) ()gsr;
  if ($r =~ m(rax:([0-9a-f]{16}))is)                                            # Compare file size obtained with that from fileSize()
   {is_deeply $1, sprintf("%016X", fileSize($0));
   }
 }

if (1) {                                                                        #TOpenRead #TClose
  Start;                                                                        # Start the program
  Mov rax, Rs($0);                                                              # File to stat
  OpenRead;                                                                     # Open file
  PrintOutRegisterInHex rax;
  Close(rax);                                                                   # Close file
  PrintOutRegisterInHex rax;
  Exit;                                                                         # Return to operating system
  my $r = Assemble;
  ok $r =~ m(( 0000){3} 0003)i;                                                 # Expected file number
  ok $r =~ m(( 0000){4})i;                                                      # Expected file number
 }

if (1) {                                                                        #TFor
  Start;                                                                        # Start the program
  For
   {PrintOutRegisterInHex rax
   } rax, 16, 1;
  Exit;                                                                         # Return to operating system
  my $r = Assemble;
  ok $r =~ m(( 0000){3} 0000)i;
  ok $r =~ m(( 0000){3} 000F)i;
 }

if (1) {                                                                        #TPrintOutRaxInReverseInHex
  Start;
  Mov rax, 0x88776655;
  Shl rax, 32;
  Or  rax, 0x44332211;
  PrintOutRaxInHex;
  PrintOutRaxInReverseInHex;
  Exit;
  ok Assemble =~ m(8877 6655 4433 2211 1122 3344 5566 7788)s;
 }

if (1) {                                                                        #TAllocateMemory #TFreeMemory
  Start;
  my $N = 4096;
  my $S = RegisterSize rax;
  Mov rax, $N;
  AllocateMemory;
  PrintOutRegisterInHex rax;
  Mov rdi, $N;
  MemoryClear;
  PrintOutRegisterInHex rax;
  PrintOutMemoryInHex;
  Exit;

  my $r = Assemble;
  if ($r =~ m((0000.*0000))s)
   {is_deeply length($1), 10289;
   }
 }

if (1) {                                                                        #TCall #TS
  Start;
  Mov rax, 0x44332211;
  PrintOutRegisterInHex rax;

  my $s = S
   {PrintOutRegisterInHex rax;
    Inc rax;
    PrintOutRegisterInHex rax;
   };

  Call $s;

  PrintOutRegisterInHex rax;
  Exit;
  my $r = Assemble;
  ok $r =~ m(0000 0000 4433 2211.*2211.*2212.*0000 0000 4433 2212)s;
 }

if (1) {                                                                        #TReadFile #TPrintMemory
  Start;                                                                        # Start the program
  Mov rax, Rs($0);                                                              # File to read
  ReadFile;                                                                     # Read file
  PrintOutMemory;                                                               # Print memory
  Exit;                                                                         # Return to operating system
  my $r = Assemble;                                                             # Assemble and execute
  ok index($r =~ s([^0x0-0x7f]) ()gsr, readFile($0) =~ s([^0x0-0x7f]) ()gsr)>-1;# Output contains this file
 }

latest:;

if (1) {                                                                        #TCreateByteString
  Start;                                                                        # Start the program
  my $s = CreateByteString;                                                     # Create a string
  Mov rdi, 0x68676665;                                                          # Load a string to append
  Shl rdi, 32;
  Or  rdi, 0x64636261;
  $s->ar;                                                                       # Add a string held in a register
  $s->ar;
  $s->out;                                                                      # Print byte string
  Exit;                                                                         # Return to operating system
  Assemble =~ m(abcdefghabcdefgh);                                              # Assemble and execute
 }

lll "Finished:", time - $start;
