#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Preprocess ▷ and ▶ as method dispatch operators in ANSI-C.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2020
#-------------------------------------------------------------------------------
# podDocumentation
package Preprocess::Ops;
our $VERSION = 20200823;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all !trim);
use feature qw(say current_sub);
use utf8;

my $logFile = q(/home/phil/c/z/z/zzz.txt);                                      # Log to this file if present

#D1 Preprocess                                                                  # Preprocess ▷ and ▶ as method dispatch operators.

sub trim($)                                                                     #P Remove trailing white space and comment
 {my ($s) = @_;                                                                 # String
  $s =~ s(\s*//.*\n) ()r;
 }

sub method($)                                                                   #P Check whether a line of C code defines a method, returning (return, name, flags, comment) if it is, else ()
 {my ($line) = @_;                                                              # Line of C code
  if ($line =~ m(\Astatic\s*(.*?)(\w+)\s+//(\w*)\s*(.*)\Z))                     # Static function is always a method
   {return ($1, $2, $3, $4)
   }
  if ($line =~ m(\A(.*?)(\w+)\s+//(\w*)\s*(.*)\Z))                              # Static function is always a method
   {my @r = my ($return, $name, $flags, $comment) = ($1, $2, $3, $4);
    if ($flags and $flags =~ m([C]))                                            # Constructor
     {return @r
     }
   }
  ()
  }

sub structure($)                                                                #P Check whether a line of C code defines a structure, returning (name, flags, comment) if it is, else ()
 {my ($line) = @_;                                                              # Line of C code
  if ($line =~ m(\Astruct\s+(\w+)\s*//(w*)\s*(.*)\Z))                           # struct name, comment start, flags, comment
   {return ($1, $2, $3)
   }
  ()
  }

sub c($$$;$)                                                                    # Preprocess ▷ and ▶ as method dispatch operators in ANSI-C.
 {my ($inputFile, $cFile, $hFile, $column) = @_;                                # Input file, C output file, H output file, optional start column for comments (80)

  my $baseFile      = fn $inputFile;                                            # The base name of the fail
  my $packageName   = ucfirst $baseFile;                                        # The package name which is used to replace $
  my $commentColumn = ($column // 80) - 1;                                      # Column in which to start comments

  my %methods;                                                                  # Method descriptions
  my %structures;                                                               # Structures defined
  my %structureParameters;                                                      # Structures used as parameters
  my %testsFound;                                                               # Tests found
  my %testsNeeded;                                                              # Tests needed
  my @forwards;                                                                 # Forward declarations of functions used as methods
  my @code = readFile($inputFile);                                              # Read code

  for my $c(@code)                                                              # Replace $ with package name
   {$c =~ s(\$\$) ($baseFile)gs;                                                # $$ is base file name with first char lower cased
    $c =~ s(\$)   ($packageName)gs;                                             # $  is base file name with first character uppercased
   }

  if (1)                                                                        # Parse source code
   {my %duplicates; my @duplicates;                                             # Duplication check for first parameter plus short method name
    for my $i(keys @code)                                                       # Index of each line
     {my $line = $code[$i];

      my ($return, $name, $flags, $comment) = method($line);                    # Parse function return, name, description comment
      if ($name)
       {$methods{$name}{return}  = $return;                                     # Return type
        $methods{$name}{flags}   = {map {$_=>1} split //, $flags};              # Flags after comment start
        $methods{$name}{comment} = $comment;                                    # Comment
       ($methods{$name}{name})   = split /_/, $name;                            # Short name as used after call operator
        push @forwards, join ' ', trim($line);                                  # Save function definition for forward declaration

        for $i($i+1..$#code)                                                    # Parameter definitions
         {$line = $code[$i];
          if ($line =~ m(\A\s*[(]?(.*?)\s*(\w+)[,)]\s*//\s*(.*)\Z))             # Variable: Get type, parameter name, comment
           {push $methods{$name}{parameters}->@*, [$1, $2, $3];
           }
          elsif ($line =~ m(\A\s*(.*?)\s*\(\*(\s*(const)?\s*\w+)\)\s*(.*?)[,\)]\s*//\s*(.*)\Z)) # Function: Get type, parameter name, comment
           {push $methods{$name}{parameters}->@*, ["$1 (*$2) $4", $2, $5];
           }

          push @forwards, trim($line);                                          # Save function definition for forward declaration
          last if $line =~ m([\)]\s*//);                                        # End of parameter list
         }

        $forwards[-1] .= ';';                                                   # Terminate forward declaration
        if (my $o = $methods{$name}{structure} = $methods{$name}{parameters}[0][0])   # Structure parameter
         {$o =~ s((\A|\s+)const\s+) ();                                         # Remove const from structure name
          $structureParameters{$o}{$name}++;                                    # Record methods in each structure
          if (my $d = $duplicates{"$name$o"})                                   # Check for duplicate
           {push @duplicates, [$name, $o, $i, $d];                              # Record duplicate
           }
          $duplicates{"$name$o"} = $i;
         }
       }
      if (1)
       {my ($name, $flags, $comment) = structure($line);                        # Parse structure definition
        if ($name)
         {$structures{$name} = genHash(q(PreprocessOpsStruct),                  # Structure declaration
            name    => $name,                                                   # Name of structure
            flags   => $flags,                                                  # Flags for structure
            comment => $comment);                                               # Comment for structure
         }
       }
     }
    if (@duplicates)                                                            # Print duplicates
     {confess join "\n", "Duplicates:", dump(\@duplicates);
     }
    if (1)                                                                      # Locate tests for each method
     {my %m;                                                                    # Methods that need tests
      for my $m(sort keys %methods)
       {next if $methods{$m}{flags}{P};                                         # Ignore private methods marked with P
        $testsNeeded{$methods{$m}{name}}++;
       }

      for my $l(@code)                                                          # Each code line
       {my @t = $l =~ m((//T\w+))g;                                             # Tests located
        for my $t(@t)                                                           # Each test marker //T...
         {my $n = $t =~ s(\A//T) ()r;                                           # Remove //T
          delete $testsNeeded{$n};                                              # Test found for this method
          $testsFound{$n}++;                                                    # The tests we have found
         }
       }

      if (keys %testsNeeded)                                                    # Report methods that need tests
       {lll "The following methods need tests:\n", join "\n", sort keys %testsNeeded;
       }
     }
   }

#  if (! keys %methods)
#   {confess "No methods starting with static found in file: %inputFile";
#   }

  if (1)                                                                        # Write structureParameters
   {my @h;                                                                      # Generated code
    for my $s(sort keys %structureParameters)                                   # Each structure
     {next unless $structures{$s};                                              # The structure must be one defined in this file
      push @h, "struct ProtoTypes_$s {";                                        # Start structure
      for my $m(sort keys $structureParameters{$s}->%*)                         # Methods in structure
       {my $method = $methods{$m};                                              # Method
        my $s  = join '', '  ', $$method{return}, ' (*',  $$method{name}, ')('; # Start signature
        my $t  = join ' ', pad($s, $commentColumn), '//', $$method{comment};
        push @h, $t;
        my @p = $$method{parameters}->@*;                                       # Parameters for method
        for my $i(keys @p)                                                      # Each parameter
         {my ($return, $name, $comment) = $p[$i]->@*;

          my $cc      = $commentColumn;                                         # Comment column
          my $comma   = $i == $#p ? ');' : ',';                                 # Comma as separator
          my $Comment = "// $comment";                                          # Format comment
          my $off     = " " x 4;
          if ($return =~ m(\(*\s*(const)?\s*\w+\)))                             # Function parameter
           {push @h, join ' ', pad(qq($off$return$comma), $cc), $Comment;
           }
          else                                                                  # Variable parameter
           {push @h, join ' ', pad(qq($off$return $name$comma), $cc), $Comment;
           }
         }
       }
      push @h, join '', " } const ProtoTypes_", $s, ' =';
      push @h, join '', "{", join(', ', sort keys $structureParameters{$s}->%*), "};";
     }
    owf($hFile, join "\n", @forwards, @h, '');
   }

  if (1)                                                                        # Preprocess input C file
   {for my $c(@code)                                                            # Source code lines
     {$c =~ s{(\w+)\s*▶\s*(\w+)\s*\(} {$1->proto->$2($1, }gs;                   # Method call with arguments
      $c =~ s{(\w+)\s*▶\s*(\w+)}      {$1->proto->$2($1)}gs;                    # Method call with no arguments
      $c =~ s{(\w+)\s*▷\s*(\w+)\s*\(} {$1.proto->$2($1, }gs;                    # Method call with arguments
      $c =~ s{(\w+)\s*▷\s*(\w+)}      {$1.proto->$2($1)}gs;                     # Method call with no arguments

      $c =~ s{new(\w+\s*)\(([^:)]*:[^)]*)\)}                                    # Constructor with named arguments in parenthesis based on: https://gcc.gnu.org/onlinedocs/gcc-10.2.0/gcc/Designated-Inits.html#Designated-Inits
             {new$1(({struct $1 t = {$2, proto: &ProtoTypes_$1}; t;}))}gs;

      $c =~ s{new(\w+\s*)(\(\))?([,;])}                                         # Constructor followed by [,;] calls for default constructor.
             {new$1(({struct $1 t = {proto: &ProtoTypes_$1};   t;}))$3}gs;

      $c =~ s( +\Z) ()gs;                                                       # Remove trailing spaces at line ends
     }
    owf($cFile, qq(#line 0 "$inputFile"\n\n).join('', @code));                  # Output C file
   }

  genHash(q(PreprocessOpsParse),                                                # Structure of the C program being preprocessed
    methods             => \%methods,                                           # Methods.
    structures          => \%structures,                                        # Structure definitions.
    structureParameters => \%structureParameters,                               # Structures used as parameters
    testsFound          => \%testsFound,                                        # Tests found
    testsNeeded         => \%testsNeeded)                                       # Tests still needed
 }

#D0
#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Preprocess::Ops - Preprocess ▷ and ▶ as method dispatch operators in ANSI-C.

=head1 Synopsis

Preprocess ▷ and ▶ as method dispatch operators in ANSI-C by translating:

  p = node ▶ key("a");

to:

  p = node->proto->key(node, "a");

and:

  p = tree ▷ root;

to:

  p = tree.proto->root(tree);

Occurrences of the B<$> character are replaced by the base name of
the containing file with the first letter capitalized, so that

  typedef struct $Node $Node;

in a file called B<tree.c> becomes:

  typedef struct TreeNode TreeNode;

Occurrences of:

  newXXX

are replaced by:

  newXXX(({proto: &Prototypes_XXX}})

The prototype vectors are generated by examining all the methods defined in the
B<C>file and written to the specified B<h> file so that they can be used via
the ▷ and ▶ operators.

See: L<https://github.com/philiprbrenan/C/blob/master/c/z/xml/xml.c> for a
working example.

=head1 Description

Preprocess ▷ and ▶ as method dispatch operators in ANSI-C.


Version 20200823.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Preprocess

Preprocess ▷ and ▶ as method dispatch operators.

=head2 c($inputFile, $cFile, $hFile, $column)

Preprocess ▷ and ▶ as method dispatch operators in ANSI-C.

     Parameter   Description
  1  $inputFile  Input file
  2  $cFile      C output file
  3  $hFile      H output file
  4  $column     Optional start column for comments (80)

B<Example:>


    my $s = writeTempFile(<<END);
  struct Node                                                                     // Node definition
   {char * key;                                                                   // Key for the node
   }
  
  Node newNode                                                                    //C Create a new node
   (const struct Node node)                                                       // Input key
   {return node;
   }
  
  static Node getKey                                                              // Get the key for a node
   (const Node n)                                                                 // Node to dump
   {return n.key;
   }
  
  static Node dump_node                                                           // Dump a node
   (const Node n)                                                                 // Node to dump
   {print(n ▷ key);
   }
  
  struct Node n = newNode(key: "a");                                              //TnewNode
  struct Node o = newNode();                                                      //TnewNode
  struct Node p = newNode;                                                        //TnewNode
  n ▷ dump;                                                                       //Tdump
  END
  
  
    my $c = temporaryFile.'.c';                                                   # Translated C file  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my $h = temporaryFile.'.h';                                                   # Prototypes in H file
  
    my $r = c($s, $c, $h);                                                        # Preprocess  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
  # owf($logFile, readFile($c));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  # owf($logFile, readFile($h));
    is_deeply scalar(readFile($h)), <<END;                                                # Generated prototypes
  Node newNode
   (const struct Node node);
  static Node getKey
   (const Node n);
  static Node dump_node
   (const Node n);
  struct ProtoTypes_Node {
    Node  (*dump)(                                                                // Dump a node
      const Node n);                                                              // Node to dump
    Node  (*getKey)(                                                              // Get the key for a node
      const Node n);                                                              // Node to dump
   } const ProtoTypes_Node =
  {dump_node, getKey};
  END
  
  # dumpFile($logFile, unbless $r);
    is_deeply $r,
  {
    methods             => {
                             dump_node => {
                                            comment    => "Dump a node",
                                            flags      => {},
                                            name       => "dump",
                                            parameters => [["const Node", "n", "Node to dump"]],
                                            return     => "Node ",
                                            structure  => "const Node",
                                          },
                             getKey    => {
                                            comment    => "Get the key for a node",
                                            flags      => {},
                                            name       => "getKey",
                                            parameters => [["const Node", "n", "Node to dump"]],
                                            return     => "Node ",
                                            structure  => "const Node",
                                          },
                             newNode   => {
                                            comment    => "Create a new node",
                                            flags      => { C => 1 },
                                            name       => "newNode",
                                            parameters => [["const struct Node", "node", "Input key"]],
                                            return     => "Node ",
                                            structure  => "const struct Node",
                                          },
                           },
    structureParameters => {
                             "Node" => { dump_node => 1, getKey => 1 },
                             "struct Node" => { newNode => 1 },
                           },
    structures          => {
                             Node => { comment => "Node definition", flags => "", name => "Node" },
                           },
    testsFound          => { dump => 1, newNode => 3 },
    testsNeeded         => { getKey => 1 },
  };
   }
  
  done_testing;
  
  if ($localTest)
   {say "TO finished in ", (time() - $startTime), " seconds";
   }
  
  


=head2 PreprocessOpsParse Definition


Structure of the C program being preprocessed




=head3 Output fields


=head4 methods

Methods.

=head4 structureParameters

Structures used as parameters

=head4 structures

Structure definitions.

=head4 testsFound

Tests found

=head4 testsNeeded

Tests still needed



=head2 PreprocessOpsStruct Definition


Structure declaration




=head3 Output fields


=head4 comment

Comment for structure

=head4 flags

Flags for structure

=head4 methods

Methods.

=head4 name

Name of structure

=head4 structureParameters

Structures used as parameters

=head4 structures

Structure definitions.

=head4 testsFound

Tests found

=head4 testsNeeded

Tests still needed



=head1 Private Methods

=head2 trim($s)

Remove trailing white space and comment

     Parameter  Description
  1  $s         String

=head2 method($line)

Check whether a line of C code defines a method, returning (return, name, flags, comment) if it is, else ()

     Parameter  Description
  1  $line      Line of C code

=head2 structure($line)

Check whether a line of C code defines a structure, returning (name, flags, comment) if it is, else ()

     Parameter  Description
  1  $line      Line of C code


=head1 Index


1 L<c|/c> - Preprocess ▷ and ▶ as method dispatch operators in ANSI-C.

2 L<method|/method> - Check whether a line of C code defines a method, returning (return, name, flags, comment) if it is, else ()

3 L<structure|/structure> - Check whether a line of C code defines a structure, returning (name, flags, comment) if it is, else ()

4 L<trim|/trim> - Remove trailing white space and comment

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Preprocess::Ops

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

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
__DATA__
use warnings FATAL=>qw(all);
use strict;
require v5.26;
use Time::HiRes qw(time);
use Test::More tests => 4;

my $startTime = time();
my $localTest = ((caller(1))[0]//'Preprocess::Ops') eq "Preprocess::Ops";       # Local testing mode
Test::More->builder->output("/dev/null") if $localTest;                         # Suppress output in local testing mode
makeDieConfess;

  if (1) {
  my $s = writeTempFile(<<END);
static Node setKey_node_node_string                                             // Copy a string into the key field of a node //TsetKey
 (const Tree   tree,                                                            // Tree
  const Node   node,                                                            // Node
  const string key)                                                             // Key
 {node ▷ key = t ▶ saveString(key);                                             // Set key with saved string
  return node;
 }
END

  my $c = temporaryFile.'.c';                                                   # Translated C file
  my $h = temporaryFile.'.h';                                                   # Prototypes in H file

  c($s, $c, $h);                                                                # Preprocess
# owf($logFile, readFile($c)); exit;

  ok index(readFile($c), <<END) > -1;                                           # Generated C file. Remove first line as it contains source file name
static Node setKey_node_node_string                                             // Copy a string into the key field of a node //TsetKey
 (const Tree   tree,                                                            // Tree
  const Node   node,                                                            // Node
  const string key)                                                             // Key
 {node.proto->key(node) = t->proto->saveString(t, key);                                             // Set key with saved string
  return node;
 }
END

  ok index(readFile($h), <<END) > -1;                                            # Generated H prototypes file
static Node setKey_node_node_string
 (const Tree   tree,
  const Node   node,
  const string key);
END
   }

  if (1) {                                                                      #Tc
  my $s = writeTempFile(<<END);
struct Node                                                                     // Node definition
 {char * key;                                                                   // Key for the node
 }

Node newNode                                                                    //C Create a new node
 (const struct Node node)                                                       // Input key
 {return node;
 }

static Node getKey                                                              // Get the key for a node
 (const Node n)                                                                 // Node to dump
 {return n.key;
 }

static Node dump_node                                                           // Dump a node
 (const Node n)                                                                 // Node to dump
 {print(n ▷ key);
 }

struct Node n = newNode(key: "a");                                              //TnewNode
struct Node o = newNode();                                                      //TnewNode
struct Node p = newNode;                                                        //TnewNode
n ▷ dump;                                                                       //Tdump
END

  my $c = temporaryFile.'.c';                                                   # Translated C file
  my $h = temporaryFile.'.h';                                                   # Prototypes in H file
  my $r = c($s, $c, $h);                                                        # Preprocess
# owf($logFile, readFile($c));
# owf($logFile, readFile($h));
  is_deeply scalar(readFile($h)), <<END;                                                # Generated prototypes
Node newNode
 (const struct Node node);
static Node getKey
 (const Node n);
static Node dump_node
 (const Node n);
struct ProtoTypes_Node {
  Node  (*dump)(                                                                // Dump a node
    const Node n);                                                              // Node to dump
  Node  (*getKey)(                                                              // Get the key for a node
    const Node n);                                                              // Node to dump
 } const ProtoTypes_Node =
{dump_node, getKey};
END

# dumpFile($logFile, unbless $r);
  is_deeply $r,
{
  methods             => {
                           dump_node => {
                                          comment    => "Dump a node",
                                          flags      => {},
                                          name       => "dump",
                                          parameters => [["const Node", "n", "Node to dump"]],
                                          return     => "Node ",
                                          structure  => "const Node",
                                        },
                           getKey    => {
                                          comment    => "Get the key for a node",
                                          flags      => {},
                                          name       => "getKey",
                                          parameters => [["const Node", "n", "Node to dump"]],
                                          return     => "Node ",
                                          structure  => "const Node",
                                        },
                           newNode   => {
                                          comment    => "Create a new node",
                                          flags      => { C => 1 },
                                          name       => "newNode",
                                          parameters => [["const struct Node", "node", "Input key"]],
                                          return     => "Node ",
                                          structure  => "const struct Node",
                                        },
                         },
  structureParameters => {
                           "Node" => { dump_node => 1, getKey => 1 },
                           "struct Node" => { newNode => 1 },
                         },
  structures          => {
                           Node => { comment => "Node definition", flags => "", name => "Node" },
                         },
  testsFound          => { dump => 1, newNode => 3 },
  testsNeeded         => { getKey => 1 },
};
 }

done_testing;

if ($localTest)
 {say "TO finished in ", (time() - $startTime), " seconds";
 }

1;
