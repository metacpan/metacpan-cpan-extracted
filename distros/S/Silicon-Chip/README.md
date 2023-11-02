<div>
    <p><a href="https://github.com/philiprbrenan/SiliconChip"><img src="https://github.com/philiprbrenan/SiliconChip/workflows/Test/badge.svg"></a>
</div>

# Name

Silicon::Chip - Design a [silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) by combining [logic gates](https://en.wikipedia.org/wiki/Logic_gate) and sub [chips](https://en.wikipedia.org/wiki/Integrated_circuit).

# Synopsis

Create and simulate the operation of a 4-bit comparator. Given two 4-bit
unsigned integers, the comparator indicates whether the first integer is
greater than the second:

    my $B = 4;
    my $c = Silicon::Chip::newChip(title=>"$B Bit Compare");

    $c->input( "a$_") for 1..$B;                                    # First number
    $c->input( "b$_") for 1..$B;                                    # Second number
    $c->gate("nxor",   "e$_", {1=>"a$_", 2=>"b$_"}) for 1..$B-1;    # Test each bit for equality
    $c->gate("gt",     "g$_", {1=>"a$_", 2=>"b$_"}) for 1..$B;      # Test each bit pair for greater

    for my $b(2..$B)
     {$c->and(  "c$b", {(map {$_=>"e$_"} 1..$b-1), $b=>"g$b"});     # Greater on one bit and all preceding bits are equal
     }

    $c->gate("or",     "or",  {1=>"g1",  (map {$_=>"c$_"} 2..$B)}); # Any set bit indicates that 'a' is greater than 'b'
    $c->output( "out", "or");                                       # Output 1 if a > b else 0

    my $t = $c->simulate({a1=>1, a2=>1, a3=>1, a4=>0,
                          b1=>1, b2=>0, b3=>1, b4=>0},
                          svg=>"svg/Compare$B");                    # Svg drawing of layout
    is_deeply($t->values->{out}, 1);

To obtain:

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Compare4.svg">
</div>

Other circuit diagrams can be seen in folder: [lib/Silicon/svg](https://github.com/philiprbrenan/SiliconChip/tree/main/lib/Silicon/svg)

# Description

Design a [silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) by combining [logic gates](https://en.wikipedia.org/wiki/Logic_gate) and sub [chips](https://en.wikipedia.org/wiki/Integrated_circuit).

Version 20231030.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Construct

Construct a [Silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) using standard [logic gates](https://en.wikipedia.org/wiki/Logic_gate).

## newChip(%options)

Create a new [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                           # Single AND gate

     {my $c = Silicon::Chip::newChip;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->input ("i1");
      $c->input ("i2");
      $c->and   ("and1", {1=>q(i1), 2=>q(i2)});
      $c->output("o", "and1");
      my $s = $c->simulate({i1=>1, i2=>1});
      ok($s->steps          == 2);
      ok($s->values->{and1} == 1);
     }

## gate($chip, $type, $output, $inputs)

A [logic gate](https://en.wikipedia.org/wiki/Logic_gate) of some sort to be added to the [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

       Parameter  Description
    1  $chip      Chip
    2  $type      Gate type
    3  $output    Output name
    4  $inputs    Input names to output from another gate

**Example:**

    if (1)                                                                           # Two AND gates driving an OR gate a tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {my $c = newChip;
      $c->input ("i11");
      $c->input ("i12");
      $c->and   ("and1", {1=>q(i11),  2=>q(i12)});
      $c->input ("i21");
      $c->input ("i22");
      $c->and   ("and2", {1=>q(i21),  2=>q(i22)});
      $c->or    ("or",   {1=>q(and1), 2=>q(and2)});
      $c->output( "o", "or");
      my $s = $c->simulate({i11=>1, i12=>1, i21=>1, i22=>1});
      ok($s->steps         == 3);
      ok($s->values->{or}  == 1);
         $s  = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>1});
      ok($s->steps         == 3);
      ok($s->values->{or}  == 1);
         $s  = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>0});
      ok($s->steps         == 3);
      ok($s->values->{o}   == 0);
     }

## install($chip, $subChip, $inputs, $outputs, %options)

Install a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) within another [chip](https://en.wikipedia.org/wiki/Integrated_circuit) specifying the connections between the inner and outer [chip](https://en.wikipedia.org/wiki/Integrated_circuit).  The same [chip](https://en.wikipedia.org/wiki/Integrated_circuit) can be installed multiple times as each [chip](https://en.wikipedia.org/wiki/Integrated_circuit) description is read only.

       Parameter  Description
    1  $chip      Outer chip
    2  $subChip   Inner chip
    3  $inputs    Inputs of inner chip to to outputs of outer chip
    4  $outputs   Outputs of inner chip to inputs of outer chip
    5  %options   Options

**Example:**

    if (1)                                                                           # Install one inside another chip, specifically one chip that performs NOT is installed three times sequentially to flip a value
     {my $i = newChip(name=>"inner");
         $i->input ("Ii");
         $i->not   ("In", "Ii");
         $i->output("Io", "In");

      my $o = newChip(name=>"outer");
         $o->input ("Oi1");
         $o->output("Oo1", "Oi1");
         $o->input ("Oi2");
         $o->output("Oo", "Oi2");


      $o->install($i, {Ii=>"Oo1"}, {Io=>"Oi2"});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $s = $o->simulate({Oi1=>1}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");

      is_deeply($s, {steps  => 2,
        changed => { "(inner 1 In)" => 0,             "Oo" => 1 },
        values  => { "(inner 1 In)" => 0, "Oi1" => 1, "Oo" => 0 },
        svg     => "svg/not1.svg"});
     }

# Basic Circuits

Some well known basic circuits.

## compareEq($bits, %options)

Compare two unsigned binary integers **a**, **b** of a specified width. Output **1** if **a** is equal to **b** else **0**.

       Parameter  Description
    1  $bits      Bits
    2  %options   Options

**Example:**

    if (1)                                                                           # Compare 8 bit unsigned integers 'a' == 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
     {my $B = 4;

      my $c = Silicon::Chip::compareEq($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %a = map {("a$_"=>0)} 1..$B;
      my %b = map {("b$_"=>0)} 1..$B;

      my $s = $c->simulate({%a, %b, "a2"=>1, "b2"=>1}, svg=>"svg/CompareEq$B");     # Svg drawing of layout
    # my $s = $c->simulate({%a, %b, "a2"=>1, "b2"=>1});                             # Equal: a == b
      is_deeply($s->values->{out}, 1);                                              # Equal
      is_deeply($s->steps,         3);                                              # Number of steps to stability

      my $t = $c->simulate({%a, %b, "b2"=>1});                                      # Less: a < b
      is_deeply($t->values->{out}, 0);                                              # Not equal
      is_deeply($s->steps,         3);                                              # Number of steps to stability
     }

## compareGt($bits, %options)

Compare two unsigned binary integers **a**, **b** of a specified width. Output **1** if **a** is greater than **b** else **0**.

       Parameter  Description
    1  $bits      Bits
    2  %options   Options

**Example:**

    if (1)                                                                           # Compare 8 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
     {my $B = 8;

      my $c = Silicon::Chip::compareGt($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %a = map {("a$_"=>0)} 1..$B;
      my %b = map {("b$_"=>0)} 1..$B;

    # my $s = $c->simulate({%a, %b, "a2"=>1}, svg=>"svg/CompareGt$B");              # Svg drawing of layout
      my $s = $c->simulate({%a, %b, "a2"=>1});                                      # Greater: a > b
      is_deeply($s->values->{out}, 1);
      is_deeply($s->steps,         4);                                              # Which goes to show that the comparator operates in O(4) time

      my $t = $c->simulate({%a, %b, "b2"=>1});                                      # Less: a < b
      is_deeply($t->values->{out}, 0);
      is_deeply($s->steps,         4);                                              # Number of steps to stability
     }

## compareLt($bits, %options)

Compare two unsigned binary integers **a**, **b** of a specified width. Output **1** if **a** is less than **b** else **0**.

       Parameter  Description
    1  $bits      Bits
    2  %options   Options

**Example:**

    if (1)                                                                           # Compare 8 bit unsigned integers 'a' < 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
     {my $B = 8;

      my $c = Silicon::Chip::compareLt($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %a = map {("a$_"=>0)} 1..$B;
      my %b = map {("b$_"=>0)} 1..$B;

    # my $s = $c->simulate({%a, %b, "a2"=>1}, svg=>"svg/CompareLt$B");              # Svg drawing of layout
      my $s = $c->simulate({%a, %b, "b2"=>1});                                      # Less: a < b
      is_deeply($s->values->{out}, 1);
      is_deeply($s->steps,         4);                                              # Which goes to show that the comparator operates in O(4) time

      my $t = $c->simulate({%a, %b, "a2"=>1});                                      # Greater: a > b
      is_deeply($t->values->{out}, 0);
      is_deeply($s->steps,         4);                                              # Number of steps to stability
     }

## pointToInteger($bits, %options)

Convert a mask known to have at most a single bit on - also known as a **point mask** - to an output number representing the location in the mask of the bit set to **1**. If no such bit exists in the point mask then output is **0**.

       Parameter  Description
    1  $bits      Bits
    2  %options   Options

**Example:**

    if (1)
     {my $B = 4;

      my $c = pointToInteger($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my %i = map {("i$_"=>0)} 1..2**$B-1;
         $i{i5} = 1;
      my $s = $c->simulate(\%i, svg=>"svg/point$B");
      is_deeply($s->steps, 2);
      is_deeply($s->values->{o1}, 1);
      is_deeply($s->values->{o2}, 0);
      is_deeply($s->values->{o3}, 1);
      is_deeply($s->values->{o4}, 0);
     }

## monotoneMaskToInteger($bits, %options)

Convert a monotone mask to an output number representing the location in the mask of the bit set to **1**. If no such bit exists in the point then output is **0**.

       Parameter  Description
    1  $bits      Bits
    2  %options   Options

**Example:**

    if (1)
     {my $B = 4;

      my $c = monotoneMaskToInteger($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my %i = map {("i$_"=>1)} 1..2**$B-1;
         $i{"i$_"} = 0 for 1..6;

      my $s = $c->simulate(\%i, svg=>"svg/monotoneMask$B");

      is_deeply($s->steps, 4);
      is_deeply($s->values->{o1}, 1);
      is_deeply($s->values->{o2}, 1);
      is_deeply($s->values->{o3}, 1);
      is_deeply($s->values->{o4}, 0);
     }

## chooseWordUnderMask($words, $bits, %options)

Choose one of a specified number of words, each of a specified width, using a point mask.

       Parameter  Description
    1  $words     Number of words
    2  $bits      Bits in each word
    3  %options   Options

**Example:**

    if (1)
     {my $B = 2; my $W = 2;

      my $c = chooseWordUnderMask($W, $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my %i;
      for   my $w(1..$W)
       {my $s = sprintf "%0${B}b", $w;
        for my $b(1..$B)
         {my $c = sprintf "w%1d_%1d", $w, $b;
          $i{$c} = substr($s, -$b, 1);
         }
       }
      my %m = map{("m$_"=>0)} 1..$W;

      my $s = $c->simulate({%i, %m, "m1"=>1}, svg=>"svg/choose_${W}_$B");

      is_deeply($s->steps, 3);
      is_deeply($s->values->{o1}, 1);
      is_deeply($s->values->{o2}, 0);
     }

## findWord($words, $bits, %options)

Choose one of a specified number of words, each of a specified width, using a key.  Return a mask indicating the locations of the key or an empty mask if the key is not present.

       Parameter  Description
    1  $words     Number of words
    2  $bits      Bits in each word and key
    3  %options   Options

**Example:**

    if (1)
     {my $B = 2; my $W = 2;

      my $c = findWord($W, $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %i;
      for my $w(1..$W)
       {my $s = sprintf "%0${B}b", $w;
        for my $b(1..$B)
         {my $c = sprintf "w%1d_%1d", $w, $b;
          $i{$c} = substr($s, -$b, 1);
         }
       }
      my %m = map{("m$_"=>0)} 1..$W;

      if (1)                                                                        # Find key 2 at position 2
       {my $s = $c->simulate({%i, %m, "k2"=>1, "k1"=>0}, svg=>"svg/findWord_${W}_$B");
        is_deeply($s->steps, 3);
        is_deeply($s->values->{o1}, 0);
        is_deeply($s->values->{o2}, 1);
       }

      if (1)                                                                        # Find key 1 at position 1
       {my $s = $c->simulate({%i, %m, "k2"=>0, "k1"=>1});
        is_deeply($s->steps, 3);
        is_deeply($s->values->{o1}, 1);
        is_deeply($s->values->{o2}, 0);
       }

      if (1)                                                                        # Find key 0 - does not exist
       {my $s = $c->simulate({%i, %m, "k2"=>0, "k1"=>0});
        is_deeply($s->steps, 3);
        is_deeply($s->values->{o1}, 0);
        is_deeply($s->values->{o2}, 0);
       }

      if (1)                                                                        # Find key 3 - does not exist
       {my $s = $c->simulate({%i, %m, "k2"=>1, "k1"=>1});
        is_deeply($s->steps, 3);
        is_deeply($s->values->{o1}, 0);
        is_deeply($s->values->{o2}, 0);
       }
     }

# Simulate

Simulate the behavior of the [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

## simulate($chip, $inputs, %options)

Simulate the action of the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) for a given set of inputs until the output values of each [logic gate](https://en.wikipedia.org/wiki/Logic_gate) stabilize.

       Parameter  Description
    1  $chip      Chip
    2  $inputs    Hash of input names to values
    3  %options   Options

**Example:**

    if (1)
     {my $i = newChip(name=>"inner");
         $i->input ("Ii");
         $i->not   ("In", "Ii");
         $i->output( "Io", "In");

      my $o = newChip(name=>"outer");
         $o->input ("Oi1");
         $o->output("Oo1", "Oi1");
         $o->input ("Oi2");
         $o->output("Oo2", "Oi2");
         $o->input ("Oi3");
         $o->output("Oo3", "Oi3");
         $o->input ("Oi4");
         $o->output("Oo",  "Oi4");

      $o->install($i, {Ii=>"Oo1"}, {Io=>"Oi2"});
      $o->install($i, {Ii=>"Oo2"}, {Io=>"Oi3"});
      $o->install($i, {Ii=>"Oo3"}, {Io=>"Oi4"});


      my $s = $o->simulate({Oi1=>1}, dumpGatesOff=>"dump/not3", svg=>"svg/not3");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply($s->values->{Oo}, 0);
      is_deeply($s->steps,        4);
     }

# Hash Definitions

## Silicon::Chip Definition

Chip description

### Output fields

#### gateSeq

GAte squqnce number - this allows us to display the gates in the order they were defined ti simplify the understanding of drawn layouts

#### gates

Gates in chip

#### installs

Chips installed within the chip

#### name

Name of chip

#### title

Title if known

# Private Methods

## AUTOLOAD($chip, @options)

Autoload by [logic gate](https://en.wikipedia.org/wiki/Logic_gate) name to provide a more readable way to specify the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

       Parameter  Description
    1  $chip      Chip
    2  @options   Options

# Index

1 [AUTOLOAD](#autoload) - Autoload by [logic gate](https://en.wikipedia.org/wiki/Logic_gate) name to provide a more readable way to specify the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

2 [chooseWordUnderMask](#choosewordundermask) - Choose one of a specified number of words, each of a specified width, using a point mask.

3 [compareEq](#compareeq) - Compare two unsigned binary integers **a**, **b** of a specified width.

4 [compareGt](#comparegt) - Compare two unsigned binary integers **a**, **b** of a specified width.

5 [compareLt](#comparelt) - Compare two unsigned binary integers **a**, **b** of a specified width.

6 [findWord](#findword) - Choose one of a specified number of words, each of a specified width, using a key.

7 [gate](#gate) - A [logic gate](https://en.wikipedia.org/wiki/Logic_gate) of some sort to be added to the [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

8 [install](#install) - Install a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) within another [chip](https://en.wikipedia.org/wiki/Integrated_circuit) specifying the connections between the inner and outer [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

9 [monotoneMaskToInteger](#monotonemasktointeger) - Convert a monotone mask to an output number representing the location in the mask of the bit set to **1**.

10 [newChip](#newchip) - Create a new [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

11 [pointToInteger](#pointtointeger) - Convert a mask known to have at most a single bit on - also known as a **point mask** - to an output number representing the location in the mask of the bit set to **1**.

12 [simulate](#simulate) - Simulate the action of the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) for a given set of inputs until the output values of each [logic gate](https://en.wikipedia.org/wiki/Logic_gate) stabilize.

# Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via **cpan**:

    sudo cpan install Silicon::Chip

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://www.appaapps.com](http://www.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.


For documentation see: [CPAN](https://metacpan.org/pod/Silicon::Chip)