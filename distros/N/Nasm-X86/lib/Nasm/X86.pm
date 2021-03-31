#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I. -I/home/phil/perl/cpan/AsmC/lib/
#-------------------------------------------------------------------------------
# Generate Nasm X86 code from Perl.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Nasm::X86;
our $VERSION = "20210330";
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

my %rodata;                                                                     # Read only data already written
my %rodatas;                                                                    # Read only string already written
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
     %r = (%r, map {$_=>'64'}   qw(rax rbx rcx rdx r8 r9 r10 r11 r12 r13 r14 r15 rsi rdi rsp rbp rip));
     %r = (%r, map {$_=>'64m'}  qw(mm0 mm1 mm2 mm3 mm4 mm5 mm6 mm7));
     %r = (%r, map {$_=>'128'}  qw(xmm0 xmm1 xmm2 xmm3 xmm4 xmm5 xmm6 xmm7 xmm8 xmm9 xmm10 xmm11 xmm12 xmm13 xmm14 xmm15 xmm16 xmm17 xmm18 xmm19 xmm20 xmm21 xmm22 xmm23 xmm24 xmm25 xmm26 xmm27 xmm28 xmm29 xmm30 xmm31));
     %r = (%r, map {$_=>'256'}  qw(ymm0 ymm1 ymm2 ymm3 ymm4 ymm5 ymm6 ymm7 ymm8 ymm9 ymm10 ymm11 ymm12 ymm13 ymm14 ymm15 ymm16 ymm17 ymm18 ymm19 ymm20 ymm21 ymm22 ymm23 ymm24 ymm25 ymm26 ymm27 ymm28 ymm29 ymm30 ymm31));
     %r = (%r, map {$_=>'512'}  qw(zmm0 zmm1 zmm2 zmm3 zmm4 zmm5 zmm6 zmm7 zmm8 zmm9 zmm10 zmm11 zmm12 zmm13 zmm14 zmm15 zmm16 zmm17 zmm18 zmm19 zmm20 zmm21 zmm22 zmm23 zmm24 zmm25 zmm26 zmm27 zmm28 zmm29 zmm30 zmm31));
     %r = (%r, map {$_=>'m'}    qw(k0 k1 k2 k3 k4 k5 k6 k7));

  for my $r(sort keys %r)
   {eval "sub $r\{q($r)\}";
    confess $@ if $@;
   }

  my %v = map {$_=>1} values %r;
  for my $v(sort keys %v)                                                       # Types of register
   {my @r = grep {$r{$_} eq $v} sort keys %r;
    eval "sub registers_$v\{".dump(\@r)."}";
    confess $@ if $@;
   }
 }

#D1 Generate Network Assembler Code                                             # Generate assembler code that can be assembled with Nasm

my $labels = 0;
sub label                                                                       #P Create a unique label
 {"l".++$labels;                                                                # Generate a label
 }

sub Start()                                                                     # Initialize the assembler
 {@bss = @data = @rodata = %rodata = %rodatas = @text = (); $labels = 0;
 }

sub Ds(@)                                                                       # Layout bytes in memory and return their label
 {my (@d) = @_;                                                                 # Data to be laid out
  my $d = join '', @_;
     $d =~ s(') (\')gs;
  my $l = label;
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
  my $l = label;
  $rodatas{$d} = $l;                                                            # Record label
  push @rodata, <<END;                                                          # Define bytes
  $l: db  '$d';
END
  $l                                                                            # Return label
 }

sub Dbwdq($@)                                                                   # Layout data
 {my ($s, @d) = @_;                                                             # Element size, data to be laid out
  my $d = join ', ', @d;
  my $l = label;
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
  my $l = label;                                                                # New data - create a label
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

sub Comment(@)                                                                  # Insert a comment into the assembly code
 {my (@comment) = @_;                                                           # Text of comment
  my $c = join "", @comment;
  push @text, <<END;
; $c
END
 }

sub Exit(;$)                                                                    # Exit with the specified return code or zero if no return code supplied
 {my ($c) = @_;                                                                 # Return code
  if (@_ == 0 or $c == 0)
   {Comment "Exit code: 0";
    push @text, <<END;
  xor rdi, rdi            ; zero
END
   }
  elsif (@_ == 1)
   {Comment "Exit code: $c";
    push @text, <<END;
  mov rdi, $c             ; Constant return code
END
   }
  push @text, <<END;
  mov rax, 60             ; 1 - sys_exit
  syscall                 ; Exit
END
 }

sub SaveFirstFour()                                                             # Save the first 4 parameter registers
 {push @text, <<END;
  push rax
  push rdi
  push rsi
  push rdx
END
 }

sub RestoreFirstFour()                                                          # Restore the first 4 parameter registers
 {push @text, <<END;
  pop rdx
  pop rsi
  pop rdi
  pop rax
END
 }

sub RestoreFirstFourExceptRax()                                                 # Restore the first 4 parameter registers except rax so it can return its value
 {push @text, <<END;
  pop rdx
  pop rsi
  pop rdi
  add rsp, 8
END
 }

sub SaveFirstSeven()                                                            # Save the first 7 parameter registers
 {push @text, <<END;
  push rax
  push rdi
  push rsi
  push rdx
  push r10
  push r8
  push r9
END
 }

sub RestoreFirstSeven()                                                         # Restore the first 7 parameter registers
 {push @text, <<END;
  pop r9
  pop r8
  pop r10
  pop rdx
  pop rsi
  pop rdi
  pop rax
END
 }

sub RestoreFirstSevenExceptRax()                                                # Restore the first 7 parameter registers except rax which is being used to return the result
 {push @text, <<END;
  pop r9
  pop r8
  pop r10
  pop rdx
  pop rsi
  pop rdi
  add rsp,8 ; Skip over value of rax so we can return rax instead
END
 }

sub Lea($$)                                                                     # Load effective address
 {my ($target, $source) = @_;                                                   # Target, source
  @_ == 2 or confess;
  push @text, <<END;
  lea $target,$source
END
 }

sub Mov($$)                                                                     # Move data
 {my ($target, $source) = @_;                                                   # Target, source
  @_ == 2 or confess;
  push @text, <<END;
  mov $target,$source
END
 }

sub PushR(@)                                                                    # Push registers onto the stack
 {my (@r) = @_;                                                                 # Register
  push @text, map {"  push $_\n"} @r;
 }

sub PopR(@)                                                                     # Pop registers in reverse order from the stack so the same parameter list can be shared with pushR
 {my (@r) = @_;                                                                 # Register
  push @text, map {"  pop $_\n"} reverse @r;
 }

sub Sub($$)                                                                     # Subtract
 {my ($target, $source) = @_;                                                   # Target, source
  @_ == 2 or confess;
  push @text, <<END;
  sub $target,$source
END
 }

sub PrintOutNl()                                                                # Write a new line
 {SaveFirstFour;
  @_ == 0 or confess;
  my $a = Rb(10);
  Comment "Write new line";
  push @text, <<END;
  mov rax, 1              ; write
  mov rdi, 1              ; sysout
  mov rsi, $a             ; New line
  mov rdx, 1              ; Length of new line
  syscall
END
  RestoreFirstFour()
 }

sub PrintOutString($;$)                                                         # One: Write a constant string to sysout. Two write the bytes addressed for the specified length to sysout
 {my ($string, $length) = @_;                                                   # String, length
  SaveFirstFour;
  Comment "Write String Out: ", dump(\@_);
  if (@_ == 1)                                                                  # Constant string
   {my ($c) = @_;
    my $l = length($c);
    my $a = Rs($c);
    push @text, <<END;
  mov rax, 1              ; write
  mov rdi, $sysout              ; sysout
  mov rsi, $a             ; String
  mov rdx, $l             ; Length
  syscall                 ; write $l: $c
END
   }
  elsif (@_ == 2)                                                               # String, length
   {my ($a, $l) = @_;
    push @text, <<END unless $a eq rsi;
  mov rsi, $a             ; String
END
    push @text, <<END unless $l eq rdx;
  mov rdx, $l             ; Length
END
    push @text, <<END;
  mov rax, 1              ; write
  mov rdi, $sysout              ; sysout
  syscall                 ; Write $l: $a
END
   }
  else
   {confess "Wrong number of parameters";
   }
  RestoreFirstFour()
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
     Rs @t
   }->();

  my @regs = qw(rax rsi);
  PushR @regs;
  for my $i(0..7)
   {my $s = 8*$i;
    push @text, <<END;
  mov rsi,rax
  shl rsi,$s ; Push selected byte high
  shr rsi,56 ; Push select byte low
  shl rsi,1  ; Multiply by two because each entry in the translation table is two bytes long
  lea rsi,[$hexTranslateTable+rsi]
END
    PrintOutString &rsi, 2;
    PrintOutString ' ' if $i % 2;
   }
  PopR @regs;
 }

sub PrintOutRegisterInHex($)                                                       # Print any register as a hex string
 {my ($r) = @_;                                                                 # Name of the register to print
  Comment "Print register $r in Hex";
  @_ == 1 or confess;
  PrintOutString sprintf("%6s: ", $r);

  my sub printReg($$@)                                                          # Print the contents of a x/y/zmm* register
   {my ($r, $s, @regs) = @_;                                                    # Register to print, size in bytes, work registers
    PushR @regs;                                                                # Save work registers
    push @text, <<END unless $s == 8;                                           # Place register contents on stack
  sub rsp,$s
  vmovdqu8 [rsp],$r
END
    push @text, <<END     if $s == 8;                                           # Place register contents on stack
  push $r
END
    PopR @regs;                                                                 # Load work registers
    for my $R(@regs)                                                            # Print work registers to print input register
     {if ($R !~ m(\Arax))
       {PrintOutString("  ");
        push @text, <<END;
  mov rax, $R
END
       }
      PrintOutRaxInHex;                                                         # Print work register
     }
    PopR @regs;
   };

  if    ($r =~ m(\Ar)) {printReg $r, 8,  qw(rax)}                               # 64 bit register requested
  elsif ($r =~ m(\Ax)) {printReg $r, 16, qw(rax rbx)}                           # xmm*
  elsif ($r =~ m(\Ay)) {printReg $r, 32, qw(rax rbx rcx rdx)}                   # ymm*
  elsif ($r =~ m(\Az)) {printReg $r, 64, qw(rax rbx rcx rdx r8 r9 r10 r11)}     # zmm*

  PrintOutNl;
 }

sub PrintOutRegistersInHex                                                      # Print the general purpose registers in hex
 {@_ == 0 or confess;
  my @regs = qw(rax);
  PushR @regs;
  my $l = label;
  push @text, <<END;
$l: lea rax,[$l]
END
  PrintOutString "rip: ";
  PrintOutRaxInHex;
  PrintOutNl;

  my $w = registers_64();
  for my $r(sort @$w)
   {next if $r =~ m(rip);
    push @text, <<END if $r eq rax;
  pop rax
  push rax
END
    PrintOutString reverse(pad(reverse($r), 3)).": ";
    push @text, <<END;
  mov rax,$r
END
    PrintOutRaxInHex;
    PrintOutNl;
   }
  PopR @regs;
 }

sub Xor($$)                                                                     # Xor one register into another
 {my ($t, $s) = @_;                                                           # Target register, source register
  @_ == 2 or confess;
  push @text, <<END;
  xor $t, $s
END
 }

sub Vmovdqu8($$)                                                                # Move memory in 8 bit blocks to an x/y/zmm* register
 {my ($r, $m) = @_;                                                             # Register, memory
  @_ == 2 or confess;
  push @text, <<END;
  VMOVDQU8 $r, $m
END
 }

sub Vmovdqu32($$)                                                               # Move memory in 32 bit blocks to an x/y/zmm* register
 {my ($r, $m) = @_;                                                             # Register, memory
  @_ == 2 or confess;
  push @text, <<END;
  VMOVDQU32 $r, $m
END
 }

sub Vmovdqu64($$)                                                               # Move memory in 64 bit blocks to an x/y/zmm* register
 {my ($r, $m) = @_;                                                             # Register, memory
  @_ == 2 or confess;
  push @text, <<END;
  VMOVDQU64 $r, $m
END
 }

sub Vprolq($$$)                                                                 # Rotate left within quad word indicated number of bits
 {my ($r, $m, $bits) = @_;                                                      # Register, memory, number of bits to rotate
  @_ == 3 or confess;
  push @text, <<END;
  VPROLQ $r, $m, $bits
END
 }

sub allocateMemory($)                                                           # Allocate memory via mmap
 {my ($s) = @_;                                                                 # Amount of memory to allocate
  @_ == 1 or confess;
  Comment "Allocate $s bytes of memory";
  if (@_ == 1)                                                                  # Constant string
   {SaveFirstSeven;
    my $d = extractMacroDefinitionsFromCHeaderFile "linux/mman.h";              # mmap constants
    my $pa = $$d{MAP_PRIVATE} | $$d{MAP_ANONYMOUS};
    my $wr = $$d{PROT_WRITE}  | $$d{PROT_READ};

    push @text, <<END;
  mov rax, 9              ; mmap
  xor rdi, rdi            ; Anywhere
  mov rsi, $s             ; Amount of memory
  mov rdx, $wr            ; PROT_WRITE  | PROT_READ
  mov r10, $pa            ; MAP_PRIVATE | MAP_ANON
  mov r8,  -1             ; File descriptor for file backing memory if any
  mov r9,  0              ; Offset into file
  syscall                 ; mmap $s
END
    RestoreFirstSevenExceptRax;
   }
  else
   {confess "Wrong number of parameters";
   }
 }

sub freeMemory($$)                                                              # Free memory via mmap
 {my ($a, $l) = @_;                                                             # Address of memory to free, length of memory to free
  @_ == 2 or confess;
  Comment "Free memory at:  $a length: $l";
  SaveFirstFour;
  push @text, <<END;
  mov rax, 11             ; unmmap
  mov rdi, $a             ; Address
  mov rsi, $l             ; Length
  syscall                 ; unmmap $a, $l
END
  RestoreFirstFourExceptRax;
 }

sub readTimeStampCounter()                                                      # Read the time stamp counter
 {@_ == 0 or confess;
  Comment "Read Time-Stamp Counter";
  push @text, <<END;
  push rdx
  RDTSC
  shl rdx,32
  or rax,rdx
  pop rdx
END
  RestoreFirstFourExceptRax;
 }

sub assemble(%)                                                                 # Assemble the generated code
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
  say STDERR readFile($l) if $options{list};                                    # Print listing if requested
  say STDERR $R;
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

=head1 Description

Generate Nasm assembler code


Version "20210330".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Generate Network Assembler Code

Generate assembler code that can be assembled with Nasm

=head2 Start()

Initialize the assembler


B<Example:>


  
    Start;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutString "Hello World";
    Exit;
    ok assemble =~ m(Hello World);
  

=head2 Ds(@d)

Layout bytes in memory and return their label

     Parameter  Description
  1  @d         Data to be laid out

B<Example:>


    Start;
    my $q = Rs('a'..'z');
  
    my $d = Ds('0'x64);                                                           # Output area  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Vmovdqu32(xmm0, "[$q]");                                                      # Load
    Vprolq   (xmm0,   xmm0, 32);                                                  # Rotate double words in quad words
    Vmovdqu32("[$d]", xmm0);                                                      # Save
    PrintOutString($d, 16);
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
  
    my $m = Rs($s);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Mov rsi, $m;
    PrintOutString rsi, length($s);
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
    my $m = Rs($s);
    Mov rsi, $m;
    PrintOutString rsi, length($s);
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


=head2 Lea($target, $source)

Load effective address

     Parameter  Description
  1  $target    Target
  2  $source    Source

B<Example:>


    Start;
    my $q = Rs('abababab');
    Mov(rax, 1);
    Mov(rbx, 2);
    Mov(rcx, 3);
    Mov(rdx, 4);
    Mov(r8,  5);
  
    Lea r9,  "[rax+rbx]";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegistersInHex;
    Exit;
    ok assemble() =~ m(r8: 0000 0000 0000 0005.*r9: 0000 0000 0000 0003.*rax: 0000 0000 0000 0001)s;
  

=head2 Mov($target, $source)

Move data

     Parameter  Description
  1  $target    Target
  2  $source    Source

B<Example:>


    Start;
    Comment "Print a string from memory";
    my $s = "Hello World";
    my $m = Rs($s);
  
    Mov rsi, $m;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutString rsi, length($s);
    Exit;
    ok assemble =~ m(Hello World);
  

=head2 PushR(@r)

Push registers onto the stack

     Parameter  Description
  1  @r         Register

=head2 PopR(@r)

Pop registers in reverse order from the stack so the same parameter list can be shared with pushR

     Parameter  Description
  1  @r         Register

B<Example:>


    Start;
    my $q = Rs(('a'..'p')x4);
    my $d = Ds('0'x128);
    Vmovdqu32(zmm0, "[$q]");
    Vprolq   (zmm0,   zmm0, 32);
    Vmovdqu32("[$d]", zmm0);
    PrintOutString($d, 64);
    Sub rsp, 64;
    Vmovdqu64 "[rsp]", zmm0;
  
    PopR rax;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRaxInHex;
    Exit;
    ok assemble() =~ m(efghabcdmnopijklefghabcdmnopijklefghabcdmnopijklefghabcdmnopijkl)s;
  

=head2 Sub($target, $source)

Subtract

     Parameter  Description
  1  $target    Target
  2  $source    Source

=head2 PrintOutNl()

Write a new line


B<Example:>


    Start;
    Comment "Print a string from memory";
    my $s = "Hello World";
    my $m = Rs($s);
    Mov rsi, $m;
    PrintOutString rsi, length($s);
    Exit;
    ok assemble =~ m(Hello World);
  

=head2 PrintOutString($string, $length)

One: Write a constant string to sysout. Two write the bytes addressed for the specified length to sysout

     Parameter  Description
  1  $string    String
  2  $length    Length

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
    ok assemble() =~ m(r8: 0000 0000 0000 0005.*r9: 0000 0000 0000 0003.*rax: 0000 0000 0000 0001)s;
  

=head2 Xor($t, $s)

Xor one register into another

     Parameter  Description
  1  $t         Target register
  2  $s         Source register

B<Example:>


    Start;
    my $q = Rs('abababab');
    Mov(rax, "[$q]");
    PrintOutString "rax: ";
    PrintOutRaxInHex;
    PrintOutNl;
  
    Xor rax, rax;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutString "rax: ";
    PrintOutRaxInHex;
    PrintOutNl;
    Exit;
    ok assemble() =~ m(rax: 6261 6261 6261 6261.*rax: 0000 0000 0000 0000)s;
  

=head2 Vmovdqu8($r, $m)

Move memory in 8 bit blocks to an x/y/zmm* register

     Parameter  Description
  1  $r         Register
  2  $m         Memory

B<Example:>


    Start;
    my $q = Rs('a'..'p');
  
    Vmovdqu8 xmm0, "[$q]";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegisterInHex xmm0;
    Exit;
    ok assemble() =~ m(xmm0: 706F 6E6D 6C6B 6A69   6867 6665 6463 6261)s;
  

=head2 Vmovdqu32($r, $m)

Move memory in 32 bit blocks to an x/y/zmm* register

     Parameter  Description
  1  $r         Register
  2  $m         Memory

B<Example:>


    Start;
    my $q = Rs('a'..'z');
    my $d = Ds('0'x64);                                                           # Output area
  
    Vmovdqu32(xmm0, "[$q]");                                                      # Load  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Vprolq   (xmm0,   xmm0, 32);                                                  # Rotate double words in quad words
  
    Vmovdqu32("[$d]", xmm0);                                                      # Save  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutString($d, 16);
    Exit;
    ok assemble() =~ m(efghabcdmnopijkl)s;
  

=head2 Vmovdqu64($r, $m)

Move memory in 64 bit blocks to an x/y/zmm* register

     Parameter  Description
  1  $r         Register
  2  $m         Memory

B<Example:>


    Start;
    my $q = Rs(('a'..'p')x4);
    my $d = Ds('0'x128);
    Vmovdqu32(zmm0, "[$q]");
    Vprolq   (zmm0,   zmm0, 32);
    Vmovdqu32("[$d]", zmm0);
    PrintOutString($d, 64);
    Sub rsp, 64;
  
    Vmovdqu64 "[rsp]", zmm0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PopR rax;
    PrintOutRaxInHex;
    Exit;
    ok assemble() =~ m(efghabcdmnopijklefghabcdmnopijklefghabcdmnopijklefghabcdmnopijkl)s;
  

=head2 Vprolq($r, $m, $bits)

Rotate left within quad word indicated number of bits

     Parameter  Description
  1  $r         Register
  2  $m         Memory
  3  $bits      Number of bits to rotate

B<Example:>


    Start;
    my $q = Rs('a'..'z');
    my $d = Ds('0'x64);                                                           # Output area
    Vmovdqu32(xmm0, "[$q]");                                                      # Load
  
    Vprolq   (xmm0,   xmm0, 32);                                                  # Rotate double words in quad words  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Vmovdqu32("[$d]", xmm0);                                                      # Save
    PrintOutString($d, 16);
    Exit;
    ok assemble() =~ m(efghabcdmnopijkl)s;
  

=head2 allocateMemory($s)

Allocate memory via mmap

     Parameter  Description
  1  $s         Amount of memory to allocate

B<Example:>


    Start;
    my $N = 2048;
    my $n = Rq($N);
    my $q = Rs('a'..'p');
  
    allocateMemory "[$n]";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegisterInHex rax;
    Vmovdqu8 xmm0, "[$q]";
    Vmovdqu8 "[rax]", xmm0;
    PrintOutString rax,16;
    PrintOutNl;
  
    Mov rbx, rax;
    freeMemory rbx, "[$n]";
    PrintOutRegisterInHex rax;
    Vmovdqu8 "[rbx]", xmm0;
    Exit;
    ok assemble() =~ m(abcdefghijklmnop)s;
  

=head2 freeMemory($a, $l)

Free memory via mmap

     Parameter  Description
  1  $a         Address of memory to free
  2  $l         Length of memory to free

B<Example:>


    Start;
    my $N = 2048;
    my $n = Rq($N);
    my $q = Rs('a'..'p');
    allocateMemory "[$n]";
    PrintOutRegisterInHex rax;
    Vmovdqu8 xmm0, "[$q]";
    Vmovdqu8 "[rax]", xmm0;
    PrintOutString rax,16;
    PrintOutNl;
  
    Mov rbx, rax;
  
    freeMemory rbx, "[$n]";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutRegisterInHex rax;
    Vmovdqu8 "[rbx]", xmm0;
    Exit;
    ok assemble() =~ m(abcdefghijklmnop)s;
  

=head2 readTimeStampCounter()

Read the time stamp counter


B<Example:>


    Start;
    for(1..10)
  
     {readTimeStampCounter;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      PrintOutRegisterInHex rax;
     }
    Exit;
    my @s = split /
/, assemble();
    my @S = sort @s;
    is_deeply \@s, \@S;
  

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


1 L<allocateMemory|/allocateMemory> - Allocate memory via mmap

2 L<assemble|/assemble> - Assemble the generated code

3 L<Comment|/Comment> - Insert a comment into the assembly code

4 L<Db|/Db> - Layout bytes in the data segment and return their label

5 L<Dbwdq|/Dbwdq> - Layout data

6 L<Dd|/Dd> - Layout double words in the data segment and return their label

7 L<Dq|/Dq> - Layout quad words in the data segment and return their label

8 L<Ds|/Ds> - Layout bytes in memory and return their label

9 L<Dw|/Dw> - Layout words in the data segment and return their label

10 L<Exit|/Exit> - Exit with the specified return code or zero if no return code supplied

11 L<freeMemory|/freeMemory> - Free memory via mmap

12 L<label|/label> - Create a unique label

13 L<Lea|/Lea> - Load effective address

14 L<Mov|/Mov> - Move data

15 L<PopR|/PopR> - Pop registers in reverse order from the stack so the same parameter list can be shared with pushR

16 L<PrintOutNl|/PrintOutNl> - Write a new line

17 L<PrintOutRaxInHex|/PrintOutRaxInHex> - Write the content of register rax to stderr in hexadecimal in big endian notation

18 L<PrintOutRegisterInHex|/PrintOutRegisterInHex> - Print any register as a hex string

19 L<PrintOutRegistersInHex|/PrintOutRegistersInHex> - Print the general purpose registers in hex

20 L<PrintOutString|/PrintOutString> - One: Write a constant string to sysout.

21 L<PushR|/PushR> - Push registers onto the stack

22 L<Rb|/Rb> - Layout bytes in the data segment and return their label

23 L<Rbwdq|/Rbwdq> - Layout data

24 L<Rd|/Rd> - Layout double words in the data segment and return their label

25 L<readTimeStampCounter|/readTimeStampCounter> - Read the time stamp counter

26 L<RestoreFirstFour|/RestoreFirstFour> - Restore the first 4 parameter registers

27 L<RestoreFirstFourExceptRax|/RestoreFirstFourExceptRax> - Restore the first 4 parameter registers except rax so it can return its value

28 L<RestoreFirstSeven|/RestoreFirstSeven> - Restore the first 7 parameter registers

29 L<RestoreFirstSevenExceptRax|/RestoreFirstSevenExceptRax> - Restore the first 7 parameter registers except rax which is being used to return the result

30 L<Rq|/Rq> - Layout quad words in the data segment and return their label

31 L<Rs|/Rs> - Layout bytes in read only memory and return their label

32 L<Rw|/Rw> - Layout words in the data segment and return their label

33 L<SaveFirstFour|/SaveFirstFour> - Save the first 4 parameter registers

34 L<SaveFirstSeven|/SaveFirstSeven> - Save the first 7 parameter registers

35 L<Start|/Start> - Initialize the assembler

36 L<Sub|/Sub> - Subtract

37 L<Vmovdqu32|/Vmovdqu32> - Move memory in 32 bit blocks to an x/y/zmm* register

38 L<Vmovdqu64|/Vmovdqu64> - Move memory in 64 bit blocks to an x/y/zmm* register

39 L<Vmovdqu8|/Vmovdqu8> - Move memory in 8 bit blocks to an x/y/zmm* register

40 L<Vprolq|/Vprolq> - Rotate left within quad word indicated number of bits

41 L<Xor|/Xor> - Xor one register into another

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

if ($^O =~ m(bsd|linux)i)                                                       # Supported systems
 {if (confirmHasCommandLineCommand(q(nasm)))
   {plan tests => 13;
   }
  else
   {plan skip_all =>qq(Nasm not available);
   }
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

my $start = time;                                                               # Tests

if (1) {                                                                        #TExit #TPrintOutString #Tassemble #TStart
  Start;
  PrintOutString "Hello World";
  Exit;
  ok assemble =~ m(Hello World);
 }

if (1) {                                                                        #TMov #TComment #TRs #TPrintOutNl
  Start;
  Comment "Print a string from memory";
  my $s = "Hello World";
  my $m = Rs($s);
  Mov rsi, $m;
  PrintOutString rsi, length($s);
  Exit;
  ok assemble =~ m(Hello World);
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
  ok assemble() =~ m(rax: 6261 6261 6261 6261.*rax: 0000 0000 0000 0000)s;
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
  ok assemble() =~ m(r8: 0000 0000 0000 0005.*r9: 0000 0000 0000 0003.*rax: 0000 0000 0000 0001)s;
 }

if (1) {                                                                        #TVmovdqu32 #TVprolq  #TDs
  Start;
  my $q = Rs('a'..'z');
  my $d = Ds('0'x64);                                                           # Output area
  Vmovdqu32(xmm0, "[$q]");                                                      # Load
  Vprolq   (xmm0,   xmm0, 32);                                                  # Rotate double words in quad words
  Vmovdqu32("[$d]", xmm0);                                                      # Save
  PrintOutString($d, 16);
  Exit;
  ok assemble() =~ m(efghabcdmnopijkl)s;
 }

if (1) {
  Start;
  my $q = Rs(('a'..'p')x2);
  my $d = Ds('0'x64);
  Vmovdqu32(ymm0, "[$q]");
  Vprolq   (ymm0,   ymm0, 32);
  Vmovdqu32("[$d]", ymm0);
  PrintOutString($d, 32);
  Exit;
  ok assemble() =~ m(efghabcdmnopijklefghabcdmnopijkl)s;
 }

if (1) {                                                                        #TPopR #TVmovdqu64
  Start;
  my $q = Rs(('a'..'p')x4);
  my $d = Ds('0'x128);
  Vmovdqu32(zmm0, "[$q]");
  Vprolq   (zmm0,   zmm0, 32);
  Vmovdqu32("[$d]", zmm0);
  PrintOutString($d, 64);
  Sub rsp, 64;
  Vmovdqu64 "[rsp]", zmm0;
  PopR rax;
  PrintOutRaxInHex;
  Exit;
  ok assemble() =~ m(efghabcdmnopijklefghabcdmnopijklefghabcdmnopijklefghabcdmnopijkl)s;
 }

if (1) {                                                                        #TPrintOutRegisterInHex
  Start;
  my $q = Rs(('a'..'p')x4);
  Mov r8,"[$q]";
  PrintOutRegisterInHex r8;
  Exit;
  ok assemble() =~ m(r8: 6867 6665 6463 6261)s;
 }

if (1) {                                                                        #TVmovdqu8
  Start;
  my $q = Rs('a'..'p');
  Vmovdqu8 xmm0, "[$q]";
  PrintOutRegisterInHex xmm0;
  Exit;
  ok assemble() =~ m(xmm0: 706F 6E6D 6C6B 6A69   6867 6665 6463 6261)s;
 }

if (1) {
  Start;
  my $q = Rs('a'..'p', 'A'..'P', );
  Vmovdqu8 ymm0, "[$q]";
  PrintOutRegisterInHex ymm0;
  Exit;
  ok assemble() =~ m(ymm0: 504F 4E4D 4C4B 4A49   4847 4645 4443 4241   706F 6E6D 6C6B 6A69   6867 6665 6463 6261)s;
 }

if (1) {
  Start;
  my $q = Rs(('a'..'p', 'A'..'P') x 2);
  Vmovdqu8 zmm0, "[$q]";
  PrintOutRegisterInHex zmm0;
  Exit;
  ok assemble() =~ m(zmm0: 504F 4E4D 4C4B 4A49   4847 4645 4443 4241   706F 6E6D 6C6B 6A69   6867 6665 6463 6261   504F 4E4D 4C4B 4A49   4847 4645 4443 4241   706F 6E6D 6C6B 6A69   6867 6665 6463 6261)s;
 }

if (1) {                                                                        #TallocateMemory #TfreeMemory
  Start;
  my $N = 2048;
  my $n = Rq($N);
  my $q = Rs('a'..'p');
  allocateMemory "[$n]";
  PrintOutRegisterInHex rax;
  Vmovdqu8 xmm0, "[$q]";
  Vmovdqu8 "[rax]", xmm0;
  PrintOutString rax,16;
  PrintOutNl;

  Mov rbx, rax;
  freeMemory rbx, "[$n]";
  PrintOutRegisterInHex rax;
  Vmovdqu8 "[rbx]", xmm0;
  Exit;
  ok assemble() =~ m(abcdefghijklmnop)s;
 }

if (1) {                                                                        #TreadTimeStampCounter
  Start;
  for(1..10)
   {readTimeStampCounter;
    PrintOutRegisterInHex rax;
   }
  Exit;
  my @s = split /\n/, assemble();
  my @S = sort @s;
  is_deeply \@s, \@S;
 }

lll "Finished:", time - $start;
