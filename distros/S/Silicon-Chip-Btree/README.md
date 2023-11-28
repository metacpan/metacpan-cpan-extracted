<div>
    <p><a href="https://github.com/philiprbrenan/SiliconChipBtree"><img src="https://github.com/philiprbrenan/SiliconChipBtree/workflows/Test/badge.svg"></a>
</div>

# Name

Silicon::Chip::Btree - Implement a B-Tree as a silicon chip.

# Synopsis

# Description

Implement a B-Tree as a silicon chip.

Version 20231101.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Btree Node

A node in a B-Tree containing keys, data and links to other nodes. Nodes only produce output when their preset id is present on their enable bus.  This makes it possible for one node to select another node for further processing of the key being sought.

## newBtreeNodeCompare ($chip, $id, $output, $enable, $find, $keys, $data, $next, $top, $N, $B, %options)

Create a new B-Tree node. The node is activated only when its preset id appears on its enable bus otherwise it produces zeroes regardless of its inputs.

        Parameter  Description
     1  $chip      Chip
     2  $id        Numeric id of this node
     3  $output    Output name
     4  $enable    Enable bus
     5  $find      Key to find
     6  $keys      Keys to search
     7  $data      Data corresponding to keys
     8  $next      Next links
     9  $top       Top next link
    10  $N         Maximum number of keys in a node
    11  $B         Size of key in bits
    12  %options   Options

**Example:**

    if (1)
     {my $B = 3; my $N = 3; my $id = 5;

      my $c = Silicon::Chip::newChip;

         $c->inputBits ("enable",   $B);                                            # Enable - the node only operates if this value matches its preset id
         $c->inputBits ("find",     $B);                                            # Key to search for
         $c->inputWords("keys", $N, $B);                                            # Keys to search
         $c->inputWords("data", $N, $B);                                            # Data associated with each key
         $c->inputWords("next", $N, $B);                                            # Next node associated with each key
         $c->inputBits ("top",      $B);                                            # Top next node


         $c->newBtreeNodeCompare($id, qw(out enable find keys data next top),$N,$B);# B-Tree node  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my sub test($)                                                                # Find keys in a node
       {my ($f) = @_;

        my %e = $c->setBits ("enable",    $id);
        my %f = $c->setBits ("find",      $f);
        my %t = $c->setBits ("top",       $N+1);
        my %k = $c->setWords("keys",   1..$N);
        my %d = $c->setWords("data",   1..$N);
        my %n = $c->setWords("next",   1..$N);
        my $i = {%e, %f, %k, %d, %n, %t};
        my $s = $c->simulate($i, $f == 2 ? (svg=>q(svg/btreeNode)) : ());

        is_deeply($s->steps, 11);
        is_deeply($s->value("out.found"),     $f >= 1 && $f <= $N ? 1 : 0);
        is_deeply($s->bint ("out.dataFound"), $f <= $N ? $f : 0);
        is_deeply($s->bint ("out.nextLink"),  $f <= $N ? $f+1 : $N+1);
       }
      test($_) for 0..$N+1;

      my sub test2($)                                                               # Find and not find keys in a node
       {my ($f) = @_;

        my %e = setBits ($c, "enable",        $id);
        my %f = setBits ($c, "find",          $f);
        my %t = setBits ($c, "top",         2*$N+1);
        my %k = setWords($c, "keys",   map {2*$_}   1..$N);
        my %d = setWords($c, "data",                1..$N);
        my %n = setWords($c, "next",   map {2*$_-1} 1..$N);
        my $i = {%e, %f, %k, %d, %n, %t};
        my $s = $c->simulate($i);

        is_deeply($s->steps, 11);
        is_deeply($s->value('out.found'),     $f == 0 || $f % 2 ? 0 : 1);
        is_deeply($s->bint ("out.dataFound"), $f % 2 ? 0 : $f / 2);
        is_deeply($s->bint ("out.nextLink"),  $f + ($f % 2 ? 0 : 1)) if $f <= 2*$N ;
       }
      test2($_) for 0..2*$N+1;

      my sub test3($)                                                               # Not enabled so only ever outputs 0
       {my ($f) = @_;

        my %e = setBits ($c, "enable",     0);                                      # Disable
        my %f = setBits ($c, "find",       $f);
        my %t = setBits ($c, "top",      2*$N+1);
        my %k = setWords($c, "keys",   map {2*$_}   1..$N);
        my %d = setWords($c, "data",                1..$N);
        my %n = setWords($c, "next",   map {2*$_-1} 1..$N);
        my $i = {%e, %f, %k, %d, %n, %t};
        my $s = $c->simulate($i);

        is_deeply($s->steps, 11);
        is_deeply($s->value("out.found"),     0);
        is_deeply($s->bint ("out.dataFound"), 0);
        is_deeply($s->bint ("out.nextLink"),  0);
       }
      test3($_) for 0..2*$N+1;
     }

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChipBtree/main/lib/Silicon/Chip/svg/btreeNode.svg">
</div>

## newBtreeNode($chip, $output, $N, $B, %options)

Create a new B-Tree node. The node is activated only when its preset id appears on its enable bus otherwise it produces zeroes regardless of its inputs.

       Parameter  Description
    1  $chip      Chip
    2  $output    Name prefix for node
    3  $N         Maximum number of keys in a node
    4  $B         Size of key in bits
    5  %options   Options

**Example:**

    if (1)
     {my $B = 3; my $N = 3;

      my $c = Silicon::Chip::newChip;

      my @n = map {$c->newBtreeNode("n", $N, $B)} 1..3;                             # B-Tree node  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %e = map {setBits ($c, $_->enable,     1)             } @n;
      my %f = map {setBits ($c, $_->find,       2)             } @n;
      my %t = map {setBits ($c, $_->top,      2*$N+1)          } @n;
      my %k = map {setWords($c, $_->keys,   map {2*$_}   1..$N)} @n;
      my %d = map {setWords($c, $_->data,                1..$N)} @n;
      my %n = map {setWords($c, $_->next,   map {2*$_-1} 1..$N)} @n;
      my $i = {%e, %f, %k, %d, %n, %t};

      my $s = $c->simulate($i, svg=>q(svg/btreeNode));
      is_deeply($s->value($n[0]->found),             1);
      is_deeply($s->bint ($n[0]->dataFound), 1);
      is_deeply($s->bint ($n[0]->nextLink),  3);
     }

# Index

1 [newBtreeNode](#newbtreenode) - Create a new B-Tree node.

2 [newBtreeNodeCompare](#newbtreenodecompare) - Create a new B-Tree node.

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


For documentation see: [CPAN](https://metacpan.org/pod/Silicon::Chip::Btree)