#!/usr/bin/perl -I/home/phil/perl/cpan/SvgSimple/lib/
#-------------------------------------------------------------------------------
# Design a silicon chip by combining gates and sub chips.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
# Update sizes from sub chips
# Forward propogation of constants from bits()
# Speed up left/down collapse by tracking the positions of corners we wish to collapse
use v5.34;
package Silicon::Chip;
our $VERSION = 20231118;                                                        # Version
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess carp);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Digest::MD5 qw(md5_hex);
use Svg::Simple;

makeDieConfess;

my sub maxSimulationSteps {100}                                                 # Maximum simulation steps
my sub gateNotIO          {0}                                                   # Not an input or output gate
my sub gateInternalInput  {1}                                                   # Input gate on an internal chip
my sub gateInternalOutput {2}                                                   # Output gate on an internal chip
my sub gateExternalInput  {3}                                                   # Input gate on the external chip
my sub gateExternalOutput {4}                                                   # Output gate on the external chip
my sub gateOuterInput     {5}                                                   # Input gate on the external chip connecting to the outer world
my sub gateOuterOutput    {6}                                                   # Output gate on the external chip connecting to the outer world

my $possibleTypes = q(and|continue|gt|input|lt|nand|nor|not|nxor|one|or|output|xor|zero);#Substitute: possible gate types

sub debugMask {0}                                                               # Adds a grid and fiber names to a mask to help debug fibers if true.

#D1 Construct                                                                   # Construct a L<silicon> L<chip> using standard L<lgs>, components and sub chips combined via buses.

sub newChip(%)                                                                  # Create a new L<chip>.
 {my (%options) = @_;                                                           # Options
  !@_ or !ref($_[0]) or confess "Call as a sub not as a method";
  genHash(__PACKAGE__,                                                          # Chip description
    name => $options{name} // $options{title}  // "Unnamed chip: ".timeStamp,   # Name of chip
    gates     => $options{gates} // {},                                         # Gates in chip
    installs  => $options{installs} // [],                                      # Chips installed within the chip
    title     => $options{title},                                               # Title if known
    gateSeq   => 0,                                                             # Gate sequence number - this allows us to display the gates in the order they were defined ti simplify the understanding of drawn layouts
    sizeBits  => {},                                                            # Sizes of buses
    sizeWords => {},                                                            # Sizes of buses
   );
 }

my sub newGate($$$$)                                                            # Make a L<lg>.
 {my ($chip, $type, $output, $inputs) = @_;                                     # Chip, gate type, output name, input names to output from another gate

  my $g = genHash(__PACKAGE__."::Gate",                                         # Gate
   type     => $type,                                                           # Gate type
   output   => $output,                                                         # Output name which is used as the name of the gate as well
   inputs   => $inputs,                                                         # Input names to driving outputs
   io       => gateNotIO,                                                       # Whether an input/output gate or not
   seq      => ++$chip->gateSeq,                                                # Sequence number for this gate
  );
 }

my sub validateName($$%)                                                        # Confirm that a component name looks like a variable name and has not already been used
 {my ($chip, $output, %options) = @_;                                           # Chip, name, options

  my $gates = $chip->gates;                                                     # Gates implementing the chip

  $output =~ m(\A[a-z][a-z0-9_.:]*\Z)i or confess <<"END";
Invalid gate name: '$output'
END

  $$gates{$output} and confess <<"END";
Gate: '$output' has already been specified
END
  1
 }

sub gate($$$;$$)                                                                # A L<lg> chosen from B<possibleTypes>.  The gate type can be used as a method name, so B<-E<gt>gate("and",> can be reduced to B<-E<gt>and(>.
 {my ($chip, $type, $output, $input1, $input2) = @_;                            # Chip, gate type, output name, input from another gate, input from another gate
  @_ >= 3 or confess "Three or more parameters";
  my $gates = $chip->gates;                                                     # Gates implementing the chip

  my $inputs;                                                                   # Input hash mapping used to accept outputs from other gates as inputs for this gate

  validateName $chip, $output;                                                  # Validate the name of the gate

  if ($type =~ m(\A(input)\Z)i)                                                 # Input gates input to themselves unless they have been connected to an output gate during sub chip expansion
   {@_> 3 and confess <<"END";
No input hash allowed for input gate: '$output'
END
    $inputs = {$output=>$output};                                               # Convert convenient scalar name to hash for consistency with gates in general
   }
  elsif ($type =~ m(\A(one|zero)\Z)i)                                           # Input gates input to themselves unless they have been connected to an output gate during sub chip expansion
   {@_> 3 and confess <<"END";
No input hash allowed for '$type' gate: '$output'
END
    $inputs = {};                                                               # Convert convenient scalar name to hash for consistency with gates in general
   }
  elsif ($type =~ m(\A(output)\Z)i)                                             # Output has one optional scalar value naming its input if known at this point
   {if (defined($input1))
     {ref($input1) and confess <<"END";
Scalar input name required for input on output gate: '$output'
END
      $inputs = {$output=>$input1};                                             # Convert convenient scalar name to hash for consistency with gates in general
     }
   }
  elsif ($type =~ m(\A(continue|not)\Z)i)                                       # These gates have one input expressed as a name rather than a hash
   {!defined($input1) and confess "Input name required for gate: '$output'\n";
    $type =~ m(\Anot\Z)i and ref($input1) =~ m(hash)i and confess <<"END";
Scalar input name required for: '$output'
END
    $inputs = {$output=>$input1};                                               # Convert convenient scalar name to hash for consistency with gates in general
   }
  elsif ($type =~ m(\A(nxor|xor|gt|ngt|lt|nlt)\Z)i)                             # These gates must have exactly two inputs expressed as a hash mapping input pin name to connection to a named gate.  These operations are associative.
   {!defined($input1) and confess <<"END" =~ s/\n/ /gsr;
Input one required for gate: '$output'
END
    !defined($input2) and confess <<"END" =~ s/\n/ /gsr;
Input two required for gate: '$output'
END
    ref($input1) and confess <<"END" =~ s/\n/ /gsr;
Input one must be the name of the connecting gate.
END
    ref($input2) and confess <<"END" =~ s/\n/ /gsr;
Input two must be the name of the connecting gate.
END
    $inputs = {1=>$input1, 2=>$input2};                                         # Construct the inputs hash expected in general for these two input gates
   }
  elsif ($type =~ m(\A(and|nand|nor|or)\Z)i)                                    # These gates must have two or more inputs expressed as a hash mapping input pin name to connection to a named gate.  These operations are associative.
   {!defined($input1) and confess <<"END" =~ s/\n/ /gsr;
Input hash required for gate: '$output'
END
    if (ref($input1) =~ m(hash)i)
     {$inputs = $input1;
     }
    elsif (ref($input1) =~ m(array)i)
     {$inputs = {map {$_=>$$input1[$_]} keys @$input1};
     }
    else
     {confess <<"END" =~ s/\n/ /gsr;
Inputs must be either a hash of input gate
names to output gate names or an array of input gate name for gate: '$output'
END
     }
   }
  else                                                                          # Unknown gate type
   {confess <<"END" =~ s/\n/ /gsr;
Unknown gate type: '$type' for gate: '$output',
possible types are: '$possibleTypes
END
   }

  $chip->gates->{$output} = newGate($chip, $type, $output, $inputs);            # Construct gate, save it and return it
 }

our $AUTOLOAD;                                                                  # The method to be autoloaded appears here. This allows us to have gate names like 'or' and 'and' without overwriting the existing Perl operators with these names.

sub AUTOLOAD($@)                                                                #P Autoload by L<lg> name to provide a more readable way to specify the L<lgs> on a L<chip>.
 {my ($chip, @options) = @_;                                                    # Chip, options
  my $type = $AUTOLOAD =~ s(\A.*::) ()r;
  if ($type !~ m(\A($possibleTypes|DESTROY)\Z))                                 # Select autoload requests we can process as gate names
   {confess <<"END" =~ s/\n/ /gsr;
Unknown method: '$type'
END
   }
  &gate($chip, $type, @options) if $type =~ m(\A($possibleTypes)\Z);
 }

my sub cloneGate($$)                                                            # Clone a L<lg> on a L<chip>.
 {my ($chip, $gate) = @_;                                                       # Chip, gate
  my %i = $gate->inputs ? $gate->inputs->%* : ();                               # Copy inputs
  newGate($chip, $gate->type, $gate->output, {%i})
 }

my sub getGate($$)                                                              # Details of a named gate or confess if no such gate
 {my ($chip, $name) = @_;                                                       # Chip, gate name
  my $g = $chip->gates->{$name};                                                # Gate details
  $g or confess "No such gate as $name\n";
  $g
 }

my sub renameGateInputs($$$)                                                    # Rename the inputs of a L<lg> on a L<chip>.
 {my ($chip, $gate, $name) = @_;                                                # Chip, gate, prefix name
  for my $p(qw(inputs))
   {my %i;
    my $i = $gate->inputs;
    for my $n(sort keys %$i)
     {$i{$n} = sprintf "(%s %s)", $name, $$i{$n};
     }
    $gate->inputs = \%i;
   }
  $gate
 }

my sub renameGate($$$)                                                          # Rename a L<lg> on a L<chip> by adding a prefix.
 {my ($chip, $gate, $name) = @_;                                                # Chip, gate, prefix name
  $gate->output = sprintf "(%s %s)", $name, $gate->output;
  $gate
 }

#D2 Buses                                                                       # A bus is an array of bits or an array of arrays of bits

#D3 Bits                                                                        # An array of bits that can be manipulated via one name.

my sub sizeBits($$%)                                                            # Size of a bits bus.
 {my ($chip, $name, %options) = @_;                                             # Chip, bits bus name, options
  return $options{bits} if defined($options{bits});
  my $s = $chip->sizeBits->{$name};
  defined($s) or confess "No bit bus named ".dump($name)."\n";
  $s
 }

sub setSizeBits($$$%)                                                           # Set the size of a bits bus.
 {my ($chip, $name, $bits, %options) = @_;                                      # Chip, bits bus name, options
  @_ >= 3 or confess "Three or more parameters";
  defined($chip->sizeBits->{$name}) and confess <<"END";
A bit bus with name: $name has already been defined
END
  $chip->sizeBits->{$name} = $bits;
  $chip
 }

sub bits($$$$%)                                                                 # Create a bus set to a specified number.
 {my ($chip, $name, $bits, $value, %options) = @_;                              # Chip, name of bus, width in bits of bus, value of bus, options
  @_ >= 4 or confess "Four or more parameters";
  my @b = reverse split //, sprintf "%0${bits}b", $value;                       # Bits needed
  for my $b(1..@b)                                                              # Generate constant
   {my $v = $b[$b-1];                                                           # Bit value
    $chip->one (n($name, $b)) if     $v;                                        # Set 1
    $chip->zero(n($name, $b)) unless $v;                                        # Set 0
   }
  setSizeBits($chip, $name, $bits);                                             # Record bus width
 }

sub inputBits($$$%)                                                             # Create an B<input> bus made of bits.
 {my ($chip, $name, $bits, %options) = @_;                                      # Chip, name of bus, width in bits of bus, options
  @_ >= 3 or confess "Three or more parameters";
  setSizeBits($chip, $name, $bits);                                             # Record bus width
  map {$chip->input(n($name, $_))} 1..$bits;                                    # Bus of input gates
 }

sub outputBits($$$%)                                                            # Create an B<output> bus made of bits.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my $bits = sizeBits($chip, $input, %options);
  map {$chip->output(n($name, $_), n($input, $_))} 1..$bits;                    # Bus of output gates
  setSizeBits($chip, $name, $bits);                                             # Record bus width
 }

sub notBits($$$%)                                                               # Create a B<not> bus made of bits.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my $bits = sizeBits($chip, $input, %options);
  map {$chip->not(n($name, $_), n($input, $_))} 1..$bits;                       # Bus of not gates
  setSizeBits($chip, $name, $bits);                                             # Record bus width
 }

sub andBits($$$%)                                                               # B<and> a bus made of bits.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my $bits = sizeBits($chip, $input, %options);
  $chip->and($name, {map {($_=>n($input, $_))} 1..$bits});                      # Combine inputs in one B<and> gate
  setSizeBits($chip, $name, $bits);                                             # Record bus width
 }

sub nandBits($$$%)                                                              # B<nand> a bus made of bits.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my $bits = sizeBits($chip, $input, %options);
  $chip->nand($name, {map {($_=>n($input, $_))} 1..$bits});                     # Combine inputs in one B<nand> gate
  setSizeBits($chip, $name, $bits);                                             # Record bus width
 }

sub orBits($$$%)                                                                # B<or> a bus made of bits.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, options
  @_ >= 3 or confess "Three or more parameters";
  my $bits = sizeBits($chip, $input, %options);
  $chip->or($name,  {map {($_=>n($input, $_))} 1..$bits});                      # Combine inputs in one B<or> gate
  setSizeBits($chip, $name, $bits);                                             # Record bus width
 }

sub norBits($$$%)                                                               # B<nor> a bus made of bits.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, options
  @_ >= 3 or confess "Three or more parameters";
  my $bits = sizeBits($chip, $input, %options);
  $chip->nor($name,  {map {($_=>n($input, $_))} 1..$bits});                     # Combine inputs in one B<nor> gate
  setSizeBits($chip, $name, $bits);                                             # Record bus width
 }

#D3 Words                                                                       # An array of arrays of bits that can be manipulated via one name.

my sub sizeWords($$%)                                                           # Size of a words bus.
 {my ($chip, $name, %options) = @_;                                             # Chip, word bus name, options
  my $s = $chip->sizeWords->{$name};
  my $w = $options{bits}  // $$s[0];
  my $b = $options{words} // $$s[1];
  defined($w) or confess "No words width specified or defaulted for $name";
  defined($b) or confess "No bits width specified or defaulted for $name";
  ($w, $b)
 }

sub setSizeWords($$$$%)                                                         # Set the size of a bits bus.
 {my ($chip, $name, $words, $bits, %options) = @_;                              # Chip, bits bus name, words, bits per word, options
  @_ >= 4 or confess "Four or more parameters";
  defined($chip->sizeWords->{$name}) and confess <<"END";
A word bus with name: $name has already been defined
END
  $chip->sizeWords->{$name} = [$words, $bits];                                  # Word bus size
  setSizeBits($chip, n($name, $_), $bits) for 1..$words;                        # Size of bit bus for each word in the word bus
  $chip
 }

sub words($$$@)                                                                 # Create a word bus set to specified numbers.
 {my ($chip, $name, $bits, @values) = @_;                                       # Chip, name of bus,  width in bits of each word, values of words
  @_ >= 3 or confess "Three or more parameters";
  for my $w(1..@values)                                                         # Each value to put on the bus
   {my $value = $values[$w-1];                                                  # Each value to put on the bus
    my @b = reverse split //, sprintf "%0${bits}b", $value;                     # Bits needed
    for my $b(1..@b)                                                            # Generate constant
     {my $v = $b[$b-1];                                                         # Bit value
      $chip->one (nn($name, $w, $b)) if     $v;                                 # Set 1
      $chip->zero(nn($name, $w, $b)) unless $v;                                 # Set 0
     }
   }
  setSizeWords($chip, $name, scalar(@values), $bits);                           # Record bus width
 }

sub inputWords($$$$%)                                                           # Create an B<input> bus made of words.
 {my ($chip, $name, $words, $bits, %options) = @_;                              # Chip, name of bus, width in words of bus, width in bits of each word on bus, options
  @_ >= 4 or confess "Four or more parameters";
  for my $w(1..$words)                                                          # Each word on the bus
   {map {$chip->input(nn($name, $w, $_))} 1..$bits;                             # Bus of input gates
   }
  setSizeWords($chip, $name, $words, $bits);                                    # Record bus size
 }

sub outputWords($$$%)                                                           # Create an B<output> bus made of words.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my ($words, $bits) = sizeWords($chip, $input);
  for my $w(1..$words)                                                          # Each word on the bus
   {map {$chip->output(nn($name, $w, $_), nn($input, $w, $_))} 1..$bits;        # Bus of output gates
   }
  setSizeWords($chip, $name, $words, $bits);                                    # Record bus size
 }

sub notWords($$$%)                                                              # Create a B<not> bus made of words.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my ($words, $bits) = sizeWords($chip, $input, %options);
  for my $w(1..$words)                                                          # Each word on the bus
   {map {$chip->not(nn($name, $w, $_), nn($input, $w, $_))} 1..$bits;           # Bus of not gates
   }
  setSizeWords($chip, $name, $words, $bits);                                    # Record bus size
 }

sub andWords($$$%)                                                              # B<and> a bus made of words to produce a single word.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my ($words, $bits) = sizeWords($chip, $input, %options);
  for my $w(1..$words)                                                          # Each word on the bus
   {$chip->andBits(n($name, $w), n($input, $w));                                # Combine inputs using B<and> gates
   }
  setSizeBits($chip, $name, $words);                                            # Record bus size
 }

sub andWordsX($$$%)                                                             # B<and> a bus made of words by and-ing the corresponding bits in each word to make a single word.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my ($words, $bits) = sizeWords($chip, $input, %options);
  for my $b(1..$bits)                                                           # Each word on the bus
   {$chip->and(n($name, $b), {map {($_=>nn($input, $_, $b))} 1..$words});       # Combine inputs using B<and> gates
   }
  setSizeBits($chip, $name, $bits);                                             # Record bus size
 }

sub orWords($$$%)                                                               # B<or> a bus made of words to produce a single word.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my ($words, $bits) = sizeWords($chip, $input, %options);
  for my $w(1..$words)                                                          # Each word on the bus
   {$chip->orBits(n($name, $w), n($input, $w));                                 # Combine inputs using B<or> gates
   }
  setSizeBits($chip, $name, $words);                                            # Record bus size
 }

sub orWordsX($$$%)                                                              # B<or> a bus made of words by or-ing the corresponding bits in each word to make a single word.
 {my ($chip, $name, $input, %options) = @_;                                     # Chip, name of bus, name of inputs, options
  @_ >= 3 or confess "Three or more parameters";
  my ($words, $bits) = sizeWords($chip, $input, %options);
  for my $b(1..$bits)                                                           # Each word on the bus
   {$chip->or(n($name, $b), {map {($_=>nn($input, $_, $b))} 1..$words});        # Combine inputs using B<or> gates
   }
  setSizeBits($chip, $name, $bits);                                             # Record bus size
 }

#D2 Connect                                                                     # Connect input buses to other buses.

sub connectInput($$$%)                                                          # Connect a previously defined input gate to the output of another gate on the same chip. This allows us to define a set of gates on the chip without having to know, first, all the names of the gates that will provide input to these gates.
 {my ($chip, $in, $to, %options) = @_;                                          # Chip, input gate, gate to connect input gate to, options
  @_ >= 3 or confess "Three or more parameters";
  my $gates = $chip->gates;
  my $i = $$gates{$in};
  defined($i) or confess "No definition of input gate $in";
  $i->type =~ m(\Ainput\Z) or confess "No definition of input gate $in";
  $i->inputs = {1=>$to};
  $chip
 }

sub connectInputBits($$$%)                                                      # Connect a previously defined input bit bus to another bit bus provided the two buses have the same size.
 {my ($chip, $in, $to, %options) = @_;                                          # Chip, input gate, gate to connect input gate to, options
  @_ >= 3 or confess "Three or more parameters";
  my $I = sizeBits($chip, $in);
  my $T = sizeBits($chip, $to);
  $I == $T or confess <<"END" =~ s/\n(.)/ $1/gsr;
Mismatched bits bus width: input has $I bits but output has $T bits.
END
  connectInput($chip, n($in, $_), n($to, $_)) for 1..$I;
  $chip
 }

sub connectInputWords($$$%)                                                     # Connect a previously defined input word bus to another word bus provided the two buses have the same size.
 {my ($chip, $in, $to, %options) = @_;                                          # Chip, input gate, gate to connect input gate to, options
  @_ >= 3 or confess "Three or more parameters";
  my ($iw, $ib) = sizeWords($chip, $in);
  my ($tw, $tb) = sizeWords($chip, $to);
  $iw == $tw or confess <<"END" =~ s/\n(.)/ $1/gsr;
Mismatched words bus: input has $iw words but output has $tw words
END
  $ib == $tb or confess <<"END" =~ s/\n(.)/ $1/gsr;
Mismatched bits width of words bus: input has $ib bits but output has $tb bits
END
  connectInputBits($chip, n($in, $_), n($to, $_)) for 1..$iw;
  $chip
 }

#D2 Install                                                                     # Install a chip within a chip as a sub chip.

sub install($$$$%)                                                              # Install a L<chip> within another L<chip> specifying the connections between the inner and outer L<chip>.  The same L<chip> can be installed multiple times as each L<chip> description is read only.
 {my ($chip, $subChip, $inputs, $outputs, %options) = @_;                       # Outer chip, inner chip, inputs of inner chip to to outputs of outer chip, outputs of inner chip to inputs of outer chip, options
  @_ >= 4 or confess "Four or more parameters";
  my $c = genHash(__PACKAGE__."::Install",                                      # Installation of a chip within a chip
    chip    => $subChip,                                                        # Chip being installed
    inputs  => $inputs,                                                         # Outputs of outer chip to inputs of inner chip
    outputs => $outputs,                                                        # Outputs of inner chip to inputs of outer chip
   );
  push $chip->installs->@*, $c;                                                 # Install chip
  $c
 }

my sub getGates($%)                                                             # Get the L<lgs> of a L<chip> and all it installed sub chips.
 {my ($chip, %options) = @_;                                                    # Chip, options

  my %outerGates;
  for my $g(sort {$a->seq <=> $b->seq} values $chip->gates->%*)                 # Copy gates from outer chip
   {my $G = $outerGates{$g->output} = cloneGate($chip, $g);
    if    ($G->type =~ m(\Ainput\Z)i)  {$G->io = gateExternalInput}             # Input gate on outer chip
    elsif ($G->type =~ m(\Aoutput\Z)i) {$G->io = gateExternalOutput}            # Output gate on outer chip
   }

  my @installs = $chip->installs->@*;                                           # Each sub chip used in this chip

  for my $install(keys @installs)                                               # Each sub chip
   {my $s = $installs[$install];                                                # Sub chip installed in this chip
    my $n = $s->chip->name;                                                     # Name of sub chip
    my $innerGates = __SUB__->($s->chip);                                       # Gates in sub chip

    for my $G(sort {$$innerGates{$a}->seq <=> $$innerGates{$b}->seq}
              keys  %$innerGates)                                               # Each gate in sub chip on definition order
     {my $g = $$innerGates{$G};                                                 # Gate in sub chip
      my $o = $g->output;                                                       # Name of gate
      my $copy = cloneGate $chip, $g;                                           # Clone gate from chip description
      my $newGateName = sprintf "$n %d", $install+1;                            # Rename gates to prevent name collisions from the expansions of the definitions of the inner chips

      if ($copy->type =~ m(\Ainput\Z)i)                                         # Input gate on inner chip - connect to corresponding output gate on containing chip
       {my $in = $copy->output;                                                 # Name of input gate on inner chip
        my $o  = $s->inputs->{$in};
           $o or confess <<"END";
No connection specified to inner input gate: '$in' on sub chip: '$n'
END
        my $O  = $outerGates{$o};
           $O or confess <<"END" =~ s(\n) ( )gsr;
No outer output gate '$o' to connect to inner input gate: '$in'
on sub chip: '$n'
END
        my $ot = $O->type;
        my $on = $O->output;
           $ot =~ m(\Aoutput\Z)i or confess <<"END" =~ s(\n) ( )gsr;
Output gate required for connection to: '$in' on sub chip $n,
not: '$ot' gate: '$on'
END
        $copy->inputs = {1 => $o};                                              # Connect inner input gate to outer output gate
        renameGate $chip, $copy, $newGateName;                                  # Add chip name to gate to disambiguate it from any other gates
        $copy->io = gateInternalInput;                                          # Mark this as an internal input gate
       }

      elsif ($copy->type =~ m(\Aoutput\Z)i)                                     # Output gate on inner chip - connect to corresponding input gate on containing chip
       {my $on = $copy->output;                                                 # Name of output gate on outer chip
        my $i  = $s->outputs->{$on};
           $i or confess <<"END";
No connection specified to inner output gate: '$on' on sub chip: '$n'
END
        my $I  = $outerGates{$i};
           $I or confess <<"END";
No outer input gate: '$i' to connect to inner output gate: $on on sub chip: '$n'
END
        my $it = $I->type;
        my $in = $I->output;
           $it =~ m(\Ainput\Z)i or confess <<"END" =~ s(\n) ( )gsr;
Input gate required for connection to '$in' on sub chip '$n',
not gate '$in' of type '$it'
END
        renameGateInputs $chip, $copy, $newGateName;
        renameGate       $chip, $copy, $newGateName;
        $I->inputs = {11 => $copy->output};                                     # Connect inner output gate to outer input gate
        $copy->io  = gateInternalOutput;                                        # Mark this as an internal output gate
       }
      else                                                                      # Rename all other gate inputs
       {renameGateInputs $chip, $copy, $newGateName;
        renameGate       $chip, $copy, $newGateName;
       }

      $outerGates{$copy->output} = $copy;                                       # Install gate with new name now it has been connected up
     }
   }
  \%outerGates                                                                  # Return all the gates in the chip extended by its sub chips
 }

my sub checkIO($%)                                                              # Check that each input L<lg> is connected to one output  L<lg>.
 {my ($chip, %options) = @_;                                                    # Chip, options
  my $gates = $chip->gates;                                                     # Gates on chip

  my %o;
  for my $G(sort keys %$gates)                                                  # Find all inputs and outputs
   {my $g = $$gates{$G};                                                        # Address gate
    my $t = $g->type;                                                           # Type of gate
    my %i = $g->inputs->%*;                                                     # Inputs for gate
    for my $i(sort keys %i)                                                     # Each input
     {my $o = $i{$i};                                                           # Output driving input
      defined($o) or  confess <<"END";                                          # No driving output
No output driving input pin '$i' on '$t' gate '$G'
END
      my $O = $$gates{$o};
      defined($O) or  confess <<"END";                                          # No driving output
No output driving input '$o' on '$t' gate '$G'
END
      if ($g->io != gateOuterInput)                                             # The gate must inputs driven by the outputs of other gates
       {$o{$o}++;                                                               # Show that this output has been used
        my $T = $O->type;
        if ($g->type =~ m(\Ainput\Z)i)
         {$O->type =~ m(\Aoutput\Z)i or confess <<"END" =~ s(\n) ( )gsr;
Input gate: '$G' must connect to an output gate on pin: '$i'
not to '$T' gate: '$o'
END
         }
        elsif (!$g->io)                                                         # Not an io gate so it cannot have an input from an output gate
         {$O->type =~ m(\Aoutput\Z) and confess <<"END";
Cannot drive a '$t' gate: '$G' using output gate: '$o'
END
         }
       }
     }
   }

  for my $G(sort keys %$gates)                                                  # Check all inputs and outputs are being used
   {my $g = $$gates{$G};                                                        # Address gate
    next if $g->type =~ m(\Aoutput\Z)i;
    $o{$G} or confess <<"END" =~ s/\n/ /gsr;
Output from gate '$G' is never used
END
   }
 }

my sub setOuterGates($$%)                                                       # Set outer  L<lgs> on external chip that connect to the outer world.
 {my ($chip, $gates, %options) = @_;                                            # Chip, gates in chip plus all sub chips as supplied by L<getGates>.

  for my $G(sort keys %$gates)                                                  # Find all inputs and outputs
   {my $g = $$gates{$G};                                                        # Address gate
    next unless $g->io == gateExternalInput;                                    # Input on external chip
    my ($i) = values $g->inputs->%*;
    $g->io = gateOuterInput if $g->output eq $i;                                # Unconnected input gates reflect back on themselves - this is a short hand way of discovering such gates
   }

  gate: for my $G(sort keys %$gates)                                            # Find all inputs and outputs
   {my $g = $$gates{$G};                                                        # Address gate
    next unless $g->io == gateExternalOutput;                                   # Output on external chip
    for my $H(sort keys %$gates)                                                # Gates driven by this gate
     {next if $G eq $H;
      my %i = $$gates{$H}->inputs->%*;                                          # Inputs to this gate
      for my $I(sort keys %i)                                                   # Each input
       {next gate if $i{$I} eq $G;                                              # Found a gate that accepts input from this gate
       }
     }
    $g->io = gateOuterOutput;                                                   # Does not drive any other gate
   }
 }

my sub removeExcessIO($$%)                                                      # Remove unneeded IO L<lgs> .
 {my ($chip, $gates, %options) = @_;                                            # Chip, gates in chip plus all sub chips as supplied by L<getGates>.

  my %d;                                                                        # Names of gates to delete
  for(;;)                                                                       # Multiple passes until no more gates can be replaced
   {my $changes = 0;

    gate: for my $G(sort keys %$gates)                                          # Find all inputs and outputs
     {my $g = $$gates{$G};                                                      # Address gate
      next unless $g->io;                                                       # Skip non IO gates
      next if     $g->io == gateOuterInput or $g->io == gateOuterOutput;        # Cannot be collapsed
      my ($n) = values $g->inputs->%*;                                          # Name of the gate driving this gate

      for my $H(sort keys %$gates)                                              # Gates driven by this gate
       {next if $G eq $H;
        my $h = $$gates{$H};                                                    # Address gate
        my %i = $h->inputs->%*;                                                 # Inputs
        for my $i(sort keys %i)                                                 # Each input
         {if ($i{$i} eq $G)                                                     # Found a gate that accepts input from this gate
           {my $replace = $h->inputs->{$i};
            $h->inputs->{$i} = $n;                                              # Bypass io gate
            $d{$G}++;                                                           # Delete this gate
            ++$changes;                                                         # Count changes in this pass
           }
         }
       }
     }
    last unless $changes;
   }
  for my $d(sort keys %d)                                                       # Gates to delete
   {delete $$gates{$d};
   }
 }

#D1 Visualize                                                                   # Visualize the L<chip> in various ways.

my sub orderGates($%)                                                           # Order the L<lgs> on a L<chip> so that input L<lg> are first, the output L<lgs> are last and the non io L<lgs> are in between. All L<lgs> are first ordered alphabetically. The non io L<lgs> are then ordered by the step number at which they last changed during simulation of the L<chip>.  This has the effect of placing all the buses in the upper right corner as there are no loops.
 {my ($chip, %options) = @_;                                                    # Chip, options

  my $gates = $chip->gates;                                                     # Gates on chip
  my @i; my @n; my @o;

  for my $G(sort {$$gates{$a}->seq <=> $$gates{$b}->seq} keys %$gates)          # Dump each gate one per line in definition order
   {my $g = $$gates{$G};
    push @i, $G if $g->type =~ m(\Ainput\Z)i;
    push @n, $G if $g->type !~ m(\A(in|out)put\Z)i;
    push @o, $G if $g->type =~ m(\Aoutput\Z)i;
   }

  if (my $c = $options{changed})                                                # Order non IO gates by last change time during simulation if possible
   {@n = sort {($$c{$a}//0) <=> ($$c{$b}//0)} @n;
   }

  (\@i, \@n, \@o)
 }

sub print($%)                                                                   # Dump the L<lgs> present on a L<chip>.
 {my ($chip, %options) = @_;                                                    # Chip, gates, options
  my $gates  = $chip->gates;                                                    # Gates on chip
  my $values = $options{values};                                                # Values of each gate if known
  my @s;
  my ($i, $n, $o) = orderGates $chip, %options;                                 # Gates by type
  for my $G(@$i, @$n, @$o)                                                      # Dump each gate one per line
   {my $g = $$gates{$G};
    my %i = $g->inputs ? $g->inputs->%* : ();

    my $p = sub                                                                 # Instruction name and type
     {my $v = $$values{$G};                                                     # Value if known for this gate
      my $o = $g->output;
      my $t = $g->type;
      return sprintf "%-32s: %3d %-32s", $o, $v, $t if defined($v);             # With value
      return sprintf "%-32s:     %-32s", $o,     $t;                            # Without value
     }->();

    if (my @i = map {$i{$_}} sort keys %i)                                      # Add actual inputs in same line sorted in input pin name
     {$p .= join " ", @i;
     }
    push @s, $p;
   }
  my $s = join "\n", @s, '';                                                    # Representation of gates as text
  owf fpe($options{print}, q(txt)), $s if $options{print};                      # Write representation of gates as text to the named file
  $s
 }

sub Silicon::Chip::Simulation::print($%)                                        # Print simulation results as text.
 {my ($sim, %options) = @_;                                                     # Simulation, options
  $sim->chip->print(%options, values=>$sim->values);
 }

my sub newGatePosition(%)                                                       # Specify the position of a L<lg> on a drawing of the containing L<chip>.
 {my (%options) = @_;                                                           # Options

  genHash(__PACKAGE__."::Position",                                             # Gate position
    gate     => $options{gate}      // undef,                                   # Gate
    x        => $options{x}         // undef,                                   # X position of gate
    y        => $options{y}         // undef,                                   # Y position of gate
    width    => $options{width}     // undef,                                   # Width of gate
    busLine  => $options{busLine}   // undef,                                   # Bus line
    busStart => $options{busStart}  // undef,                                   # Bus line start
    busEnd   => $options{busEnd}    // undef,                                   # Bus Line end
   );
 }

my sub firstLastOne($)                                                          # Find the first and last ones in a bit string and return the 1-based indices as a pair.
 {my ($a) = @_;                                                                 # First string, second string
  my sub a($) {substr($a, $_[0]-1, 1)}                                          # Index to element of first  bit string array

  my $f; my $l;                                                                 # First  B<1> and last B<1> in the string
  for my $i(1..length($a))
   {$l = $i if a $i;                                                            # Later B<1>
    $f = $i if a($i) and !defined $f;                                           # First B<1>
   }
  ($f, $l)
 }

my sub layoutInputBus(@)                                                        # Given an array of bit strings lay them out from left to right in lines so that the B<1>s of each possible pairs of bit strings do not overlap per L<canBothFitOnSameLine>.  Returns an array mapping the strings to lines.  There is no reason to suppose that the proposed layout is optimal - this is a packing problem with all the usual difficulties associated with such problems.  This layout requires three levels. 1: Down from input gate. 2: horizontal until vertically above a gate we wish to connect this input pin to.  3: down to the gate we wish to connect to.  Three levels is enough because in the worst case each input gate can have its own horizontal which we can reach because the gates are spaced  horizontally.  Each such horizontal can be connected vertically on level 3 to an input of a non input gate because no two input gates are connected to the same pin on any other gate.
 {my (@a) = @_;                                                                 # Array of bit strings to be laid out

  my @l;                                                                        # Proposed input bus lines
  my %u = map {$_=>1} 1..@a;                                                    # Unplaced inputs
  my @m;                                                                        # Input index to input bus line

  my sub combine($$)                                                            # Combine the latest element to fit on the specified line
   {my ($a, $b) = @_;                                                           # Old line new line
    my $c = '';                                                                 # Resulting line
    for  my $i(1..length($a))
     {$c .= substr($a, $i-1, 1) || substr($b, $i-1, 1) ? '1' : '0';             # Merge bit by bit
     }
    $c
   }

  my sub findFirst()                                                            # Find first remaining input to place
   {my ($a) = sort {$a <=> $b} keys %u;
    $a
   }

  for(;keys %u;)                                                                # Unplaced inputs still
   {my $p  = findFirst;                                                         # New bus line with first remaining input gate
    delete $u{$p};                                                              # Show placed
    my $l  = $a[$p-1];                                                          # Places required
    my ($s, $e) = firstLastOne($l);                                             # Placement range
    push @l, $l;                                                                # New bus line
    $m[$p] = @l;                                                                # Map gate to bus line

    for my $i(1..@a)                                                            # Possible inputs on this line
     {next unless $u{$i};                                                       # Skip inputs already placed
      my $l = $a[$i-1];                                                         # Places required
      my ($S, $F) = firstLastOne($l);                                           # Position requested on bus line
      if ($S > $e)                                                              # Can fit on the current line
       {$l[-1] = combine($l[-1], $l);                                           # Place latest addition to current line
        $m[$i] = @l;                                                            # Map placement
        $e     = $F;                                                            # Current end point
        delete $u{$i};                                                          # Used
       }
     }
   }
  shift @m;                                                                     # Remove initial L<undef> to make result array zero based
  @m
 }

sub printSvg($%)                                                                # Mask the L<lgs> onto a L<chip> as an L<svg> drawing to help visualize the structure of the L<chip> using a condensed input bus.
 {my ($chip, %options) = @_;                                                    # Chip, options
  my $gates   = $chip->gates;                                                   # Gates on chip
  my $title   = $chip->title;                                                   # Title of chip
  my $changed = $options{changed};                                              # Step at which gate last changed in simulation
  my $values  = $options{values};                                               # Values of each gate if known
  my $steps   = $options{steps};                                                # Number of steps to equilibrium

  my sub fs {0.2} my sub fw {0.02}                                              # Font sizes
  my sub Fs {0.4} my sub Fw {0.04}
  my sub op0 {q(transparent)}

  my @defaults = (defaults=>{stroke_width=>fw, font_size=>fs});                 # Default values
  my $s = Svg::Simple::new(@defaults, %options, grid=>0);                       # Draw each gate via Svg

  my %p;                                                                        # Dimensions and drawing positions of gates
  my ($iG, $nG, $oG) = orderGates $chip, %options;                              # Gates by type

  for my $i(keys @$iG)                                                          # Position of each input gate
   {my $G = $$iG[$i];                                                           # Gate name
    my $g = $$gates{$G};                                                        # Gate
    $p{$G} = newGatePosition(gate=>$g, x=>$i, y=>0, width=>1);                  # Position input gate. The gates are drawn horizontally across the top with the input bus beneath them.
   }

  my $W = 0;                                                                    # Number of inputs to all the non IO gates
  my @iBus;                                                                     # Input bus
  my $miw = 0;                                                                  # Maximum width of input bus

  for my $i(keys @$nG)                                                          # Position of each non io gate
   {my $G = $$nG[$i];                                                           # Gate name
    my $g = $$gates{$G};                                                        # Gate
    my %i = $g->inputs->%*;                                                     # Gates driving this gate
    my $w = 0;                                                                  # Input pin position on gate
    for my $I(sort keys %i)                                                     # Each driver of this gate in pin order
     {my $D = $i{$I};                                                           # Name of driving gate
      my $d = $$gates{$D};                                                      # Details of driving gate
      if ($d->io == gateOuterInput)
       {my $ix = $p{$d->output}->x;                                             # Position of input gate in x
        my $nx = $W+$w;                                                         # Position of driven gate in x
        $iBus[$ix][$ix] = '1';                                                  # Mark position of driving input gate on input bus
        $iBus[$ix][$nx] = '1';                                                  # Mark position of pin on driven gate on input bus
        $miw = max($miw, $ix+1, $nx+1);                                         # Maximum width of input bus. Plus one because we must take into account the width of the input gate and the driven pins
       }
      $w++;                                                                     # Next driver position
     }
    $p{$G} = newGatePosition(gate => $g, x => $W, y => $i, width =>$w);         # Position non io gate
    $W    += $w;                                                                # Width of area needed for non io gates
   }

  for my $b(@iBus)                                                              # Represent the input bus lines as strings as they are easier to visualize
   {$b = pad join('', map {$_ ? '1' : '0'} @$b), $miw, '0';
   }

  my @iBusLayout = layoutInputBus(@iBus);                                       # Input bus line for each input gate

  if (@iBusLayout)                                                              # Usually there are outer input pins - but not  always.
   {my $iBusHeight = 1 + max(@iBusLayout);                                      # The height of the input bus area
    #say STDERR "Improvement: ", scalar(@iBus) / $iBusHeight);
    for my $i(keys @$iG)                                                        # Position of each input gate
     {my $G = $$iG[$i];                                                         # Gate name
      my $L = $p{$G};                                                           # Layout for input gate
      my $B = $L->busLine = $iBusLayout[$i];                                    # Bus line for this input gate
      my ($f, $l) = firstLastOne($iBus[$i]);                                    # Limits on bus line for this input gate
      $L->busStart = $f; $L->busEnd = $l;                                       # Save limits on bus line for this input gate
      my $y = 1/2 + $B;                                                         # Vertical position of input bus line
      my $c = q(#DC143C);                                                       # B<Spanish Crimson> for horizontal input bus lines
      if ($f != $l)                                                             # Horizontal input bar required for this gate
       {$s->line(x1 => $f-1/2, x2 => $l-1/2, y1 => $y, y2 => $y, stroke => $c); # Draw level 2 input bus line
       }
      my $Lx = $L->x+1/2; my $Ly = 1/2 + $B; my @o = (opacity=>0.3);
      $s->line  (x1 => $Lx, x2 => $Lx, @o,    stroke_width => 2*Fw,             # Draw vertical level 1 input bus line
                 y1 => 1,   y2 => $Ly,              stroke => "blue");
      $s->circle(cx => $Lx, cy => $Ly, r => 3*Fw, @o, fill => "blue");          # Draw circle connecting vertical level 1 input bus line to horizontal level 2
     }

    for my $i(keys @$nG)                                                        # Reposition the non io gates a little further down to make room for the input bus area
     {my $G = $$nG[$i];                                                         # Gate name
      my $n = $p{$G};                                                           # Layout for input gate
      $n->y += $iBusHeight;
     }
   }

  for my $i(keys @$oG)                                                          # Position each output gate
   {my $G = $$oG[$i];                                                           # Gate name
    my $g = $$gates{$G};                                                        # Gate
    my %i = $g->inputs ? $g->inputs->%* : ();                                   # Inputs to gate
    my ($d) = values %i;                                                        # The one driver for this gate
    next unless defined $p{$d};
    my $y = $p{$d}->y;
    $p{$G} = newGatePosition(gate=>$g, x=>$W, y=>$y, width=>1);                 # Position output gate
   }

  my $pageWidth = $W + 1;                                                       # Width of input, output and non io gates as laid out.

  if (defined($title))                                                          # Title if known
   {$s->text(x=>$pageWidth, y=>0.5, fill=>"darkGreen", text_anchor=>"end",
      stroke_width=>Fw, font_size=>Fs, z=>-1,
      cdata=>$title);
   }

  if (defined($steps))                                                          # Number of steps taken if known
   {$s->text(x=>$pageWidth, y=>1.5, fill=>"darkGreen", text_anchor=>"end",
      stroke_width=>Fw, font_size=>Fs, z=>-1,
      cdata=>"$steps steps");
   }

  for my $P(sort keys %p)                                                       # Each gate with text describing it
   {my $p = $p{$P};
    my $x = $p->x;
    my $y = $p->y;
    my $w = $p->width;
    my $g = $p->gate;

    my $color = sub
     {return "red"  if $g->io == gateOuterOutput;
      return "blue" if $g->io == gateOuterInput;
      "green"
     }->();

    if ($g->io)                                                                 # Circle for io pin
     {$s->circle(cx=>$x+1/2, cy=>$y+1/2, r=>1/2,   fill=>op0, stroke=>$color);
     }
    else                                                                        # Rectangle for non io gate
     {$s->rect(x=>$x, y=>$y, width=>$w, height=>1, fill=>op0, stroke=>$color);
     }

    if (defined(my $v = $$values{$g->output}))                                  # Value of gate if known
     {$s->text(
       x                 => $g->io != gateOuterOutput ? $x : $x + 1,
       y                 => $y,
       fill              =>"black",
       stroke_width      => Fw,
       font_size         => Fs,
       text_anchor       => $g->io != gateOuterOutput ? "start": "end",
       dominant_baseline => "hanging",
       cdata             => $v ? "1" : "0");
     }

    if (defined(my $t = $$changed{$g->output}) and !$g->io)                     # Gate change time if known for a non io gate
     {$s->text(
       x                 => $w + ($g->io != gateOuterOutput ? $x : $x + 1),
       y                 => 1 + $y,
       fill              =>"black",
       stroke_width      => fw,
       font_size         => fs,
       text_anchor       => "end",
       cdata             => $t+1);
     }

    my sub ot($$$$)                                                             # Output svg text
     {my ($dy, $fill, $pos, $text) = @_;
      $s->text(x                 => $x+$w/2,
               y                 => $y+$dy,
               fill              => $fill,
               text_anchor       => "middle",
               dominant_baseline => $pos,
               cdata             => $text);
      }

    ot(5/12, "red",      "auto",    $g->type);                                  # Type of gate
    ot(7/12, "darkblue", "hanging", $g->output);

    if ($g->io != gateOuterInput)                                               # Not an input pin
     {my %i = $g->inputs ? $g->inputs->%* : ();
      my @i = sort keys %i;                                                     # Connections to each gate
      my $o = $g->output;

      for my $i(keys @i)                                                        # Connections to each gate
       {my $D = $i{$i[$i]};                                                     # Driving gate name
        my $P = $p{$D};                                                         # Driving gate
        defined($P) or confess <<"END";
No such gate as: '$D' on gate $o
END
        my $X = $P->x; my $Y = $P->y; my $W = $P->width; my $G = $P->gate;      # Position of source gate
        my $dx = $i + 1/2;
        my $dy = $Y < $y ?  0 : 1;
        my $dX = $X < $x ? $W : 0;
        my $dY = $Y < $y ?  0 : 0;
        my $cx = $x+$dx;                                                        # Horizontal line corner x
        my $cy = $Y+$dY+1/2;                                                    # Horizontal line corner y

        my $xc = $X < $x ? q(black) : q(darkBlue);                              # Horizontal line color
        my $x2 = $g->io == gateOuterOutput ? $cx - 1/2 : $cx;

        if ($P->gate->io != gateOuterInput)                                     # Not being driven by an outer input gate.
         {$s->line(x1=>$X+$dX, x2=>$x2, y1=>$cy, y2=>$cy, stroke=>$xc);         # Outgoing value along horizontal lines
         }

        my $yc = $Y < $y ? q(purple) : q(darkRed);                              # Vertical lines

        if ($g->io != gateOuterOutput)                                          # Not an output gate
         {my $Cy = $cy;
             $Cy = $P->busLine + 1/2 if $P->gate->io == gateOuterInput;         # Connect to input level 2 horizontal bar if connecting to an outer input gate
          $s->line  (x1=>$cx, x2=>$cx, y1=>$Cy, y2=>$y+$dy, stroke=>$yc);       # Incoming value along vertical line - not needed for outer output gates
          $s->circle(cx=>$cx, cy=>$Cy,    r=>0.06, fill=>"red");                # Line corner
          $s->circle(cx=>$x2, cy=>$y+$dy, r=>0.04, fill=>"blue");               # Line entering gate
         }
        else                                                                    # External output gate
         {$s->circle(cx=>$x2,   cy=>$y+$dy-1/2, r=>0.04, fill=>"blue");         # Line entering output
         }

        if ($P->gate->io != gateOuterInput)                                     # Not an outer input gate
         {$s->circle(cx=>$X+$W, cy=>$cy, r=>0.04, fill=>"red");                 # Horizontal line exiting gate
         }

        if (defined(my $v = $$values{$G->output}) and $g->io != gateOuterOutput)# Value of gate if known except for output gates written else where
         {my $bottom = $x > $X || $G->io == gateOuterInput;
          my $Y = $y + $dy + fs;
          $s->text(
            x            => $cx,
            y            => $Y,
            fill         => "black",
            stroke_width => fw,
            font_size    => fs,
            text_anchor  => "middle",
            $bottom ? () : (dominant_baseline=>"hanging"),
            cdata        =>  $v ? "1" : "0");
         }
       }
     }
   }
  my $t = $s->print;
  return owf(fpe($options{svg}, q(svg)), $t) if $options{svg};
  $t
 }

sub Silicon::Chip::Simulation::printSvg($%)                                     # Print simulation results as svg.
 {my ($sim, %options) = @_;                                                     # Simulation, options
  printSvg($sim->chip, %options, values=>$sim->values);
 }

my sub layoutAsFiberBundle($%)                                                  # Layout the gates as a fiber bundle collapsed down to as close to the gates as possible.  The returned information is sufficient to draw an svg image of the fiber bundle.
 {my ($chip, %options) = @_;                                                    # Chip, options
  my %gates   = $chip->gates->%*;                                               # Gates on chip
  my $changed = $options{changed};                                              # Step at which gate last changed in simulation
  my $values  = $options{values};                                               # Values of each gate if known

  my @gates = sort {$gates{$a}->seq <=> $gates{$b}->seq} keys %gates;           # Gates in definition order
  if (my $c = $options{changed})                                                # Order non IO gates by last change time during simulation if possible
   {@gates = sort {($$c{$a}//0) <=> ($$c{$b}//0)} @gates;
   }

  my @fibers;                                                                   # Squares of the page, each of which can either be undefined or contain the name of the fiber crossing it from left to right or up and down
  my @inPlay;                                                                   # Squares of the page in play
  my @positions;                                                                # Position of each gate indexed by position in layout
  my %positions;                                                                # Position of each gate indexed by gate name
  my $width  = 1;                                                               # Width of page consumed so far until it becomes the page width.
  my $height = 0;                                                               # Height of page consumed so far until it becomes the page height

  for my $i(keys @gates)                                                        # Position each gate
   {my $g = $gates{$gates[$i]};                                                 # Gate details
    my $s = $g->type =~ m(\A(input|one|output|zero)\Z);                         # These gates can be positioned without consuming more horizontal space
    my %i = $g->inputs->%*;                                                     # Inputs hash for gate
    my @i = sort keys %i;                                                       # Connections to each gate in pin order
    my $w = $s ? 1 : scalar(@i);                                                # Width of this gate
    my $n = $g->output;                                                         # Name of gate

    my sub color()                                                              # Color of gate
     {return "red"  if $g->io == gateOuterOutput;
      return "blue" if $g->io == gateOuterInput;
      "green"
     }

    my $x = $width; $x-- if $s;                                                 # Position of gate
    my $y = $i;

    my $p = genHash(__PACKAGE__."::GatePosition",
      output      => $g->output,                                                # Gate name
      x           => $x,                                                        # Gate x position
      y           => $y,                                                        # Gate y position
      width       => $w,                                                        # Width of gate
      fiber       => 0,                                                         # Number of fibers running past this gate
      position    => $i,                                                        # Number of fibers running past this gate
      type        => $g->type,                                                  # Type of gate
      value       => $$values {$g->output},                                     # Value of gate if known
      changed     => $$changed{$g->output},                                     # Last change time of gate if known
      inputs      => [map {$i{$_}}       @i],                                   # Names of gates driving input pins on this gate
      inputValues => [map {$$values{$i{$_}}} @i],                               # Values on input pins if known
      color       => color,                                                     # Color of gate
      inPin       => $g->io == gateOuterInput,                                  # Input pin for  chip
      outPin      => $g->io == gateOuterOutput,                                 # Output pin for  chip
     );

    $positions[$i] = $p;  $positions{$p->output} = $p;                          # Index the gates
    $width += $w unless $s;                                                     # Io gates are tucked in in such way that they do not contribute to the width
    $height++    unless $g->io == gateOuterOutput;                              # Output gates do not contribute to the height of the mask
   }

  for my $i(keys @positions)                                                    # Position output pins along bottom of mask
   {my $p = $positions[$i];
    next unless $p->outPin;
    my ($D) = $p->inputs->@*;                                                   # An output gate only has one input so we can safe relocate it next to the single gate that produces that output
    my  $d  = $positions{$D};                                                   # Driving gate
    $p->x = $d->x - 1;                                                          # Reposition output gate
    $p->y = $d->y;
   }

  for my $p(@positions)                                                         # Connect gates loosely
   {my $g = $gates{$p->output};                                                 # Detail for this gate
    my @i = $p->inputs->@*;                                                     # Connections to each gate
    for my $i(keys @i)                                                          # Connections to each gate
     {my $D = $i[$i];                                                           # Driving gate name
      my $d = $positions{$D};                                                   # Driving gate position
      my $X = $p->x+$i;                                                         # X position of input pin to gate
      my $Y = $p->y;                                                            # Y position of input pin to gate
      $fibers[$_][$d->y][0] = $D for $d->x+$d->width..$X;                       # Horizontal line
      $fibers[$X][$_]   [1] = $D for $d->y..$Y-1;                               # Vertical line
      if (!$g->io)                                                              # Mark column as in play
       {for my $j(0..$Y-1)
         {$inPlay[$X][$j] = 1;
         }
       }
     }
   }

  my sub collapseFibers()                                                       # Perform one collapse pass of the fibers returning the number of collapses performed
   {my $changes = 0;                                                            # Number of changes made in this pass

    my sub removeOrphans($)                                                     # Remove any vertical orphans in the specified column
     {my ($i) = @_;                                                             # Column to check
      for my $j(keys $fibers[$i]->@*)
       {my $h = $fibers[$i][$j][0];                                             # Horizontal line
        my $v = $fibers[$i][$j][1];                                             # Vertical line
        last if defined($h) and defined($v) and $h eq $v;                       # Found the vertical so we can stop
        $fibers[$i][$j][1] = undef;                                             # Remove vertical as it never meets a corresponding horizontal and so is of no use
       }
     }

    for my $i(keys @fibers)                                                     # Examine each cell for a corner that we can collapse either left or down
     {for my $j(keys $fibers[$i]->@*)
       {my sub i() {$i}
        my sub j() {$j}
        my sub h($$) :lvalue {my ($i, $j) = @_; return undef unless $i >= 0 and $j >= 0 and $inPlay[$i][$j]; $fibers[$i][$j][0]} # A horizontal element relative to the current corner
        my sub v($$) :lvalue {my ($i, $j) = @_; return undef unless $i >= 0 and $j >= 0 and $inPlay[$i][$j]; $fibers[$i][$j][1]} # A vertical   element relative to the current corner

        my $a = h(i-1, j+0); my sub a() {$a}
        my $b = h(i+0, j+0);
        my $B = v(i+0, j+0);
        my $C = v(i+0, j+1);
        my $D = v(i+0, j-1);
        my $e = h(i+1, j+0);
        next unless defined($a) and defined($b) and defined($B) and defined($C);# Possible corner
        next unless $a eq $b and $b eq $B and $B eq $C;                         # Confirm corner
        next if defined($D) and $D eq $a;                                       # If it is a corner it points north east.
        next if defined($e) and $e eq $a;                                       # If it is a corner it points north east.

        my $wentLeft;                                                           # If we collapsed left we made a change and so need to come around again before attempting to collapse down
        if (1)                                                                  # Collapse left
         {my $k; my sub k() :lvalue {$k}                                        # Position of new corner going left
          for my $I(reverse 0..i-1)                                             # Look for an opposite corner
           {last if $j+2 >= $fibers[$I]->$#*;
            last   unless defined(h($I, j)) and h($I, j) eq $a;                 # Make sure horizontal is occupied with expected bus line
            last   if  defined h($I, j+1);                                      # Horizontal is occupied so we will not be able to reuse it
            k = $I if !defined v($I, j+1);                                      # Possible opposite because it is not being used vertically
           }

          if (defined(k))                                                       # Reroute through new corner
           {v(i, j)   = undef;                                                  # Remove old upper right corner vertical
            v(k, j)   = a;                                                      # New upper left corner
            h(k, j)   = undef unless k > 0                 and defined(h(k-1, j)) and h(k-1, j) eq a; # Situation x: we might, or might not be on a corner here
            v(i, j+1) = undef unless j+1 < $fibers[i]->$#* and defined(v(i, j+2)) and v(i, j+2) eq a; # Situation y: we might, or might not be on a corner here
            h(k, j+1) = a;                                                      # New lower left corner
            v(k, j+1) = a;                                                      # New lower left corner
            for my $I(k+1..i)                                                   # Route along lower side
             {h($I, j  ) = undef;                                               # Remove upper side
              h($I, j+1) = a;                                                   # Add lower side
              if (defined(v($I, j)) and v($I, j) eq a)                          # Crossing a T so we need to move the cross down one
               {v($I, j)   = undef;                                             # Remove upper cross
                v($I, j+1) = a;                                                 # Enable lower cross
               }
             }
            ++$changes; $wentLeft++;
            #removeOrphans(k)   if k;
            #removeOrphans(k-1) if k;
           }
         }
#  d        |x           |
# abe       +-+    =>    |
#  c          |y         |
#             +--        +---

        if (!$wentLeft)                                                         # Collapse down
         {my $k; my sub k() :lvalue {$k}                                        # Position of new corner going down
          for my $J(j..scalar($fibers[i-1]->$#*))                               # Look for an opposite corner
           {last unless defined(v(i,   $J)) and v(i,   $J) eq a;                # Make sure vertical is occupied with expected fiber
            last   if   defined(v(i-1, $J)) and v(i-1, $J) ne a;                # Vertical is occupied so we will not be able to reuse it
            k = $J if  !defined(h(i-1, $J));                                    # Possible corner as horizontal is free
           }

          if (defined(k))                                                       # Reroute through new corner
           {h(i,   j) = undef;                                                  # Remove old upper right corner horizontal
            v(i,   j) = undef;                                                  # Remove old upper right corner vertical
            v(i-1, j) = a;                                                      # New upper left corner
            h(i-1, j) = undef unless i-1 > 0               and defined(h(i-2, j)) and h(i-2, j) eq a; # Situation x: we might, or might not be on a corner here
            v(i,   k) = undef unless k   < $fibers[i]->$#* and defined(v(i, k+1)) and v(i, k+1) eq a; # Situation y: we might, or might not be on a corner here
            h(i-1, k) = a;                                                      # New lower left corner
            v(i-1, k) = a;                                                      # New lower left corner
            h(i, k) = a;                                                        # Add lower right corner
            for my $J(j..k-1)                                                   # Route down opposite side
             {v(i  , $J) = undef;                                               # Remove right side
              v(i-1, $J) = a;                                                   # Add left side
             }
            ++$changes;
            #removeOrphans(i+1);
            #removeOrphans(i);
           }
         }
       }
     }

    $changes
   }

  for my $i(1..@positions) {last unless collapseFibers()}                       # Collapse fibers

  my $t = 0;                                                                    # Size of thickest bundle
  for   my $i(keys @fibers)
   {my $c = 0;
    for my $j(keys $fibers[$i]->@*)
     {++$c if defined $fibers[$i][$j][0];                                       # Only horizontal fibers count to the total thickness
     }
   $t = $c if $c > $t;
  }

  genHash(__PACKAGE__."::Layout",                                               # Details of layout
    chip           => $chip,                                                    # Chip being masked
    positionsArray => \@positions,                                              # Position array
    positionsHash  => \%positions,                                              # Position hash
    fibers         => \@fibers,                                                 # Fibers after collapse
    inPlay         => \@inPlay,                                                 # Squares in play for collapsing
    height         => $height,                                                  # Height of drawing
    width          => $width,                                                   # Width of drawing
    steps          => $options{steps},                                          # Steps in simulation
    thickness      => $t,                                                       # Width of the thickest fiber bundle
   );
 }

sub Silicon::Chip::Layout::draw($%)                                             #P Draw a mask for the gates.
 {my ($layout, %options) = @_;                                                  # Layout, options
  my $chip      = $layout->chip;                                                # Chip being masked
  my %gates     = $chip->gates->%*;                                             # Gates on chip
  my @fibers    = $layout->fibers->@*;                                          # Squares of the page, each of which can either be undefined or contain the name of the fiber crossing it from left to right or up and down
  my @inPlay    = $layout->inPlay->@*;                                          # Squares available for collapsing
  my @positions = $layout->positionsArray->@*;                                  # Position of each gate indexed by position in layout
  my %positions = $layout->positionsHash ->%*;                                  # Position of each gate indexed by gate name
  my $width     = $layout->width;                                               # Width of mask
  my $height    = $layout->height;                                              # Height of mask
  my $steps     = $layout->steps;                                               # Number of steps to equilibrium
  my $thickness = $layout->thickness;                                           # Thickness of fiber bundle

  my sub ts() {$height/64} my sub tw() {ts/16}  my sub tl() {1.25 * ts}         # Font sizes for titles
  my sub Ts() {2*ts}       my sub Tw() {2*tw}   my sub Tl() {2*tl}

  my sub fs() {1/6}        my sub fw() {fs/16}  my sub fl() {1.25 * fs}         # Font sizes for gates
  my sub Fs() {2*fs}       my sub Fw() {2*fw}   my sub Fl() {2*fl}

  my @defaults = (defaults=>                                                    # Default values
   {stroke_width => fw,
    font_size    => fs,
    fill         => q(transparent)});

  my $svg = Svg::Simple::new(@defaults, %options, grid=>debugMask ? 1 : 0);     # Draw each gate via Svg. Grid set to 1 produces a grid that can be helpful debugging layout problems

  if (1)                                                                        # Show squares in play with a small number of rectangles
   {my @i = map {$_ ? [@$_] : $_} @inPlay;                                      # Deep copy
    for   my $i(keys @i)                                                        # Each row
     {for my $j(keys $i[$i]->@*)                                                # Each column
       {if ($i[$i][$j])                                                         # Found a square in play
         {my $w = 1;                                                            # Width of rectangle
          for my $I($i+1..$#inPlay)                                             # Extend as far as possible to the right
           {if ($i[$I][$j])
             {++$w;
              $i[$I][$j] = undef;                                               # Show that this square has been written - safe because we did a deep copy earlier
             }
           }
          $svg->rect(x=>$i, y=>$j, width=>$w, height=>1,
            fill=>"mistyrose", stroke=>"transparent");
         }
       }
     }
   }

  my $py = 0;
  my sub wt($;$)                                                                # Write titles on following lines
   {my ($t, $T) = @_;                                                           # Value, title to write
    if (defined($t))                                                            # Value to write
     {$py += Tl;                                                                # Position to write at
      my $s = $t; $s .= " $T" if $T;                                            # Text to write
      $svg->text(x => $width, y => $py, cdata => $s,                            # Write text
        fill=>"darkGreen", text_anchor=>"end", stroke_width=>Tw, font_size=>Ts);
     }
   }

  wt($chip->title);                                                             # Title if known
  wt($steps,     "steps");                                                      # Number of steps taken if known
  wt($thickness, "thick");                                                      # Thickness of bundle
  wt($width,     "wide");                                                       # Width of page

  for my $p(@positions)                                                         # Draw each gate
   {my $x = $p->x; my $y = $p->y; my $w = $p->width; my $c = $p->color;
    my $io = $p->inPin || $p->outPin;
    $svg->circle(cx => $x+1/2, cy=>$y+1/2, r=>1/2, stroke=>$c) if  $io;         # Circle for io pin
    $svg->rect(x=>$x, y=>$y, width=>$w, height=>1, stroke=>$c) if !$io;         # Rectangle for non io gate

    if (defined(my $v = $p->value))                                             # Value of gate if known
     {$svg->text(
       x                 => $p->x,
       y                 => $p->y,
       fill              =>"black",
       stroke_width      => Fw,
       font_size         => Fs,
       text_anchor       => "start",
       dominant_baseline => "hanging",
       cdata             => $v ? "1" : "0");
     }

    if (defined(my $t = $p->changed) and !$p->inPin and !$p->outPin)            # Gate change time if known for a non io gate
     {$svg->text(
       x                 => $p->x + $p->width,
       y                 => $p->y + 1,
       fill              => "darkBlue",
       stroke_width      => fw,
       font_size         => fs,
       text_anchor       => "end",
       cdata             => $t+1);
     }

    my sub ot($$$$)                                                             # Output svg text
     {my ($dy, $fill, $pos, $text) = @_;
      $svg->text(x                 => $p->x+$p->width/2,
                 y                 => $p->y+$dy,
                 fill              => $fill,
                 text_anchor       => "middle",
                 dominant_baseline => $pos,
                 cdata             => $text);
      }

    ot(5/12, "red",      "auto",    $p->type);                                  # Type of gate
    ot(7/12, "darkblue", "hanging", $p->output);

    my @i = $p->inputValues->@*;

    for my $i(keys @i)                                                          # Draw input values to each pin on the gate
     {next if $p->inPin or $p->outPin;
      my $v = $p->inputValues->[$i];
      if (defined($v))
       {$svg->text(
          x                 => $p->x + $i + 1/2,
          y                 => $p->y,
          fill              => "darkRed",
          stroke_width      => fw,
          font_size         => fs,
          text_anchor       => "middle",
          dominant_baseline => "hanging",
          cdata             => $v ? "1" : "0");
       }
     }
   }

  if (debugMask)                                                                # Show fiber names - useful when debugging bus lines
   {for my $i(keys @fibers)
     {for my $j(keys $fibers[$i]->@*)
       {if (defined(my $n = $fibers[$i][$j][0]))                                # Horizontal
         {$svg->text(
            x                 => $i+1/2,
            y                 => $j+1/2,
            fill              =>"black",
            stroke_width      => fw,
            font_size         => fs,
            text_anchor       => 'middle',
            dominant_baseline => 'auto',
            cdata             => $n,
           )# if $n eq "a4" || $n eq "a4";
         }
        if (defined(my $n = $fibers[$i][$j][1]))                                # Vertical
         {$svg->text(
            x                 => $i+1/2,
            y                 => $j+1/2,
            fill              =>"red",
            stroke_width      => fw,
            font_size         => fs,
            text_anchor       => 'middle',
            dominant_baseline => 'hanging',
            cdata             => $n,
           )# if $n eq "a4" || $n eq "a4";
         }
       }
     }
   }

  if (1)                                                                        # Show fiber lines
   {my @h = (stroke =>"darkgreen", stroke_width => Fw);                         # Fiber lines horizontal
    my @v = (stroke =>"darkgreen", stroke_width => Fw);                         # Fiber lines vertical
    my @f = @fibers;
    my @i = @inPlay;
    my @H; my @V;                                                               # Straight line cells

    for my $i(keys @f)
     {for my $j(keys $f[$i]->@*)
       {my $h = $f[$i][$j][0];                                                  # Horizontal
        my $v = $f[$i][$j][1];                                                  # Vertical

        if (defined($h) and defined($v) and $h eq $v)                           # Cross
         {my $l = !$i[$i-1][$j]     || ($i[$i-1][$j] && ($f[$i-1][$j][0]//'') eq $h); # Left horizontal
          my $r =                       $i[$i+1][$j] && ($f[$i+1][$j][0]//'') eq $h;  # Right horizontal
          my $a = $j >  0           &&  $i[$i][$j-1] && ($f[$i][$j-1][1]//'') eq $h;  # Vertically above
          my $b = $j >= $f[$i]->$#* || ($i[$i][$j+1] && ($f[$i][$j+1][1]//'') eq $h); # Vertically below

#     | A     --+   |C       D
#     +--     B |   +--    --+--
#                   |        |

          my $D = $l && $r && $b;
          my $C = $a && $r && $b;
          my $A = $a && $r;
          my $B = $l && $b;

          my @B = my @A = (r=>    Fw, fill=>"darkRed");                         # Fiber connections
          my @C =         (r=>1.5*Fw, fill=>"darkRed");

          if ($C)
           {$svg->line(x1=>$i+1/2,   y1=>$j,     x2=>$i+1/2, y2=>$j+1,   @h);
            $svg->line(x1=>$i+1/2,   y1=>$j+1/2, x2=>$i+1,   y2=>$j+1/2, @h);
            $svg->circle(cx=>$i+1/2, cy=>$j+1/2, @C);
           }
          elsif ($D)
           {$svg->line(x1=>$i,       y1=>$j+1/2, x2=>$i+1,   y2=>$j+1/2, @h);
            $svg->line(x1=>$i+1/2,   y1=>$j+1/2, x2=>$i+1/2, y2=>$j+1,   @h);
            $svg->circle(cx=>$i+1/2, cy=>$j+1/2, @C);
           }
          elsif ($A)                                                            # Draw corners
           {$svg->line  (x1=>$i+1/2, y1=>$j,     x2=>$i+1,   y2=>$j+1/2, @h);
            $svg->circle(cx=>$i+1/2, cy=>$j,     @A);
            $svg->circle(cx=>$i+1,   cy=>$j+1/2, @A);
           }
          elsif ($B)
           {$svg->line  (x1=>$i,     y1=>$j+1/2, x2=>$i+1/2, y2=>$j+1, @h);
            $svg->circle(cx=>$i,     cy=>$j+1/2, @B);
            $svg->circle(cx=>$i+1/2, cy=>$j+1,   @B);
           }
         }
        else                                                                    # Straight
         {$H[$i][$j] = $h;                                                      # Horizontal
          $V[$i][$j] = $v;                                                      # Vertical
         }
       }
     }

    my @hc = (stroke => "darkgreen", stroke_width => Fw);                       # Horizontal line color
    my @vc = (stroke => "darkgreen", stroke_width => Fw);                       # Vertical   line color

    for my $i(keys @f)                                                          # Draw horizontal and vertical bars with a minimal number of lines otherwise the svg files get very big
     {for my $j(keys $f[$i]->@*)
       {if (defined(my $h = $H[$i][$j]))                                        # Horizontal
         {my $e = $i;
          for my $I($i..$#f)                                                    # Go as far right as possible
           {my $H = \$H[$I][$j];
            last unless $$H and $$H eq $h;                                      # Still in line
            $$H = undef;                                                        # Erase line as no longer needed
            $e  = $I;                                                           # Current known end of the line
           }
          $svg->line(x1=>$i, y1=>$j+1/2, x2=>$e+1, y2=>$j+1/2, @hc);            # Draw horizontal line
         }
        if (defined(my $v = $V[$i][$j]))                                        # Vertical
         {my $e = $j;
          for my $J($j..$f[$i]->$#*)                                            # Go as far down as possible
           {my $V = \$V[$i][$J];
            last unless $$V and $$V eq $v;                                      # Still in line
            $$V = undef;                                                        # Erase line as no longer needed
            $e  = $J;                                                           # Current known end of the line
           }
          $svg->line(x1=>$i+1/2, y1=>$j, x2=>$i+1/2, y2=>$e+1, @vc);            # Draw vertical line
         }
       }
     }
   }

  my $t = $svg->print;                                                          # Text of svg
  my $f = $options{svg};                                                        # Svg file
  return owf(fpe($f, q(svg)), $t) if $f;                                        # Draw bundle as an svg drawing
  $t
 }

my %drawMask;                                                                   # Track masks drawn so we can complain about duplicates

my sub drawMask($%)                                                             # Draw a mask for the gates.
 {my ($chip, %options) = @_;                                                    # Chip, options
  my $s = $options{svg};
  $drawMask{$s}++ and confess <<"END" =~ s/\n(.)/ $1/gsr;                       # Complain about duplicate mask names
Duplicate mask name: $s specified
END
  my $layout = layoutAsFiberBundle($chip, %options);                            # Gates on chip
     $layout->draw(%options);                                                   # Draw mask
 }

#D1 Basic Circuits                                                              # Some well known basic circuits.

sub n(*$)                                                                       # Gate name from single index.
 {my ($c, $i) = @_;                                                             # Gate name, bit number
  !@_ or !ref($_[0]) or confess <<"END";
Call as a sub not as a method
END
  "${c}_$i"
 }

sub nn(*$$)                                                                     # Gate name from double index.
 {my ($c, $i, $j) = @_;                                                         # Gate name, word number, bit number
  !@_ or !ref($_[0]) or confess confess <<"END";
Call as a sub not as a method
END
 "${c}_${i}_$j"
 }

#D2 Comparisons                                                                 # Compare unsigned binary integers of specified bit widths.

sub compareEq($$$$%)                                                            # Compare two unsigned binary integers of a specified width returning B<1> if they are equal else B<0>.
 {my ($chip, $output, $a, $b, %options) = @_;                                   # Chip, name of component also the output bus, first integer, second integer, options
  @_ >= 4 or confess "Four or more parameters";
  my $o  = $output;
  my $A = sizeBits($chip, $a);
  my $B = sizeBits($chip, $b);
  $A == $B or confess <<"END" =~ s/\n(.)/ $1/gsr;
Input $a has width $A but input $b has width $B
END
  $chip->nxor(n("$o.e", $_), n($a, $_), n($b, $_)) for 1..$B;                   # Test each bit pair for equality
  $chip->andBits($o, "$o.e", bits=>$B);                                         # All bits must be equal

  $chip
 }

sub compareGt($$$$%)                                                            # Compare two unsigned binary integers and return B<1> if the first integer is more than B<b> else B<0>.
 {my ($chip, $output, $a, $b, %options) = @_;                                   # Chip, name of component also the output bus, first integer, second integer, options
  @_ >= 4 or confess "Four or more parameters";
  my $o  = $output;
  my $A = sizeBits($chip, $a);
  my $B = sizeBits($chip, $b);
  $A == $B or confess <<"END" =~ s/\n(.)/ $1/gsr;
Input $a has width $A but input $b has width $B
END
  $chip->nxor (n("$o.e", $_), n($a, $_), n($b, $_)) for 2..$B;                  # Test all but the lowest bit pair for equality
  $chip->gt   (n("$o.g", $_), n($a, $_), n($b, $_)) for 1..$B;                  # Test each bit pair for more than

  for my $b(2..$B)                                                              # More than on one bit and all preceding bits are equal
   {$chip->and(n("$o.c", $b),
     {(map {$_=>n("$o.e", $_)} $b..$B), ($b-1)=>n("$o.g", $b-1)});
   }

  $chip->or   ($o, {$B=>n("$o.g", $B),  (map {($_-1)=>n("$o.c", $_)} 2..$B)});  # Any set bit indicates that B<a> is more than B<b>

  $chip
 }

sub compareLt($$$$%)                                                            # Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is B<1> if B<a> is less than B<b> else B<0>.
 {my ($chip, $output, $a, $b, %options) = @_;                                   # Chip, name of component also the output bus, first integer, second integer, options
  @_ >= 4 or confess "Four or more parameters";

  my $A = sizeBits($chip, $a);
  my $B = sizeBits($chip, $b);
  $A == $B or confess <<"END" =~ s/\n(.)/ $1/gsr;
Input $a has width $A but input $b has width $B
END

  my $o = $output;

  $chip->nxor (n("$o.e", $_), n($a, $_), n($b, $_)) for 2..$B;                  # Test all but the lowest bit pair for equality
  $chip->lt   (n("$o.l", $_), n($a, $_), n($b, $_)) for 1..$B;                  # Test each bit pair for less than

  for my $b(2..$B)                                                              # More than on one bit and all preceding bits are equal
   {$chip->and(n("$o.c", $b),
     {(map {$_=>n("$o.e", $_)} $b..$B), ($b-1)=>n("$o.l", $b-1)});
   }

  $chip->or   ($o, {$B=>n("$o.l", $B),  (map {($_-1)=>n("$o.c", $_)} 2..$B)});  # Any set bit indicates that B<a> is less than B<b>

  $chip
 }

sub chooseFromTwoWords($$$$$%)                                                  # Choose one of two words based on a bit.  The first word is chosen if the bit is B<0> otherwise the second word is chosen.
 {my ($chip, $output, $a, $b, $choose, %options) = @_;                          # Chip, name of component also the chosen word, the first word, the second word, the choosing bit, options
  @_ >= 5 or confess "Five or more parameters";
  my $o = $output;

  my $A = sizeBits($chip, $a);
  my $B = sizeBits($chip, $b);
  $A == $B or confess <<"END" =~ s/\n(.)/ $1/gsr;
Input $a has width $A but input $b has width $B
END

  $chip->not("$o.n", $choose);                                                  # Not of the choosing bit
  for my $i(1..$B)
   {$chip->and(n("$o.a", $i), [n($a, $i),     "$o.n"       ]);                  # Choose first word
    $chip->and(n("$o.b", $i), [n($b, $i),     $choose      ]);                  # Choose second word
    $chip->or (n($o,     $i), [n("$o.a", $i), n("$o.b", $i)]);                  # Or results of choice
   }
  setSizeBits($chip, $o, $B);                                                   # Record bus size

  $chip
 }

sub enableWord($$$$%)                                                           # Output a word or zeros depending on a choice bit.  The first word is chosen if the choice bit is B<1> otherwise all zeroes are chosen.
 {my ($chip, $output, $a, $enable, %options) = @_;                              # Chip, name of component also the chosen word, the first word, the second word, the choosing bit, options
  @_ >= 4 or confess "Four or more parameters";
  my $o = $output;
  my $B = sizeBits($chip, $a);

  for my $i(1..$B)                                                              # Choose each bit of input word
   {$chip->and(n($o, $i), [n($a, $i), $enable]);
   }
  setSizeBits($chip, $o, $B);                                                   # Record bus size
  $chip
 }

#D2 Masks                                                                       # Point masks and monotone masks. A point mask has a single B<1> in a sea of B<0>s as in B<00100>.  A monotone mask has zero or more B<0>s followed by all B<1>s as in: B<00111>.

sub pointMaskToInteger($$$%)                                                    # Convert a mask B<i> known to have at most a single bit on - also known as a B<point mask> - to an output number B<a> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point mask then output number B<a> is B<0>.
 {my ($chip, $output, $input, %options) = @_;                                   # Chip, output name, input mask, options
  @_ >= 3 or confess "Three or more parameters";
  my $B = sizeBits($chip, $input);                                              # Bits in input bus
  my $I = containingPowerOfTwo($B);                                             # Bits in integer
  my $i = $input;                                                               # The bits in the input mask
  my $o = $output;                                                              # The name of the output bus

  my %b;
  for my $b(1..$B)                                                              # Bits in mask to bits in resulting number
   {my $s = sprintf "%b", $b;
    for my $p(1..length($s))
     {$b{$p}{$b}++ if substr($s, -$p, 1);
     }
   }

  for my $b(sort keys %b)
   {$chip->or(n($o, $b), {map {$_=>n($i, $_)} sort keys $b{$b}->%*});           # Bits needed to drive a bit in the resulting number
   }
  setSizeBits $chip, $o, $I;                                                    # Size of resulting integer
  $chip
 }

sub integerToPointMask($$$%)                                                    # Convert an integer B<i> of specified width to a point mask B<m>. If the input integer is B<0> then the mask is all zeroes as well.
 {my ($chip, $output, $input, %options) = @_;                                   # Chip, output name, input mask, options
  @_ >= 3 or confess "Three or more parameters";
  my $bits = sizeBits($chip, $input);                                           # Size of input integer in bits
  my $B = 2**$bits-1;
  my $o = $output;                                                              # Output mask

  $chip->notBits("$o.n", $input);                                               # Not of each input

  for my $b(1..$B)                                                              # Each bit of the mask
   {my @s = reverse split //, sprintf "%0${bits}b", $b;                         # Bits for this point in the mask
    my %a;
    for my $i(1..@s)
     {$a{$i} = n($s[$i-1] ? 'i' : "$o.n", $i);                                  # Combination of bits to enable this mask bit
     }
    $chip->and(n($output, $b), {%a});                                           # And to set this point in the mask
   }
  setSizeBits($chip, $output, $B);                                              # Size of output bus

  $chip
 }

sub monotoneMaskToInteger($$$%)                                                 # Convert a monotone mask B<i> to an output number B<r> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point then output in B<r> is B<0>.
 {my ($chip, $output, $input, %options) = @_;                                   # Chip, output name, input mask, options
  @_ >= 3 or confess "Three or more parameters";
  my $B = sizeBits($chip, $input);
  my $I = containingPowerOfTwo($B);
  my $o = $output;

  my %b;
  for my $b(1..$B)
   {my $s = sprintf "%b", $b;
    for my $p(1..length($s))
     {$b{$p}{$b}++ if substr($s, -$p, 1);
     }
   }
  $chip->not     (n("$o.n", $_), n($input, $_)) for 1..$B-1;                    # Not of each input
  $chip->continue(n("$o.a", 1),  n($input, 1));
  $chip->and     (n("$o.a", $_), [n("$o.n", $_-1), n('i', $_)]) for 2..$B;      # Look for trailing edge

  for my $b(sort keys %b)
   {$chip->or    (n($o, $b), [map {n("$o.a", $_)} sort keys $b{$b}->%*]);       # Bits needed to drive a bit in the resulting number
   }
  setSizeBits($chip, $o, $I);

  $chip
 }

sub monotoneMaskToPointMask($$$%)                                               # Convert a monotone mask B<i> to a point mask B<o> representing the location in the mask of the first bit set to B<1>. If the monotone mask is all B<0>s then point mask is too.
 {my ($chip, $output, $input, %options) = @_;                                   # Chip, output name, input mask, options
  @_ >= 3 or confess "Three or more parameters";
  my $o = $output;
  my $bits = sizeBits($chip, $input);
  $chip->continue(n($o, 1), n($input, 1));                                      # The first bit in the monotone mask matches the first bit of the point mask
  for my $b(2..$bits)
   {$chip->xor(n($o, $b), n($input, $b-1), n($input, $b));                      # Detect transition
   }
  setSizeBits($chip, $o, $bits);

  $chip
 }

sub integerToMonotoneMask($$$%)                                                 # Convert an integer B<i> of specified width to a monotone mask B<m>. If the input integer is B<0> then the mask is all zeroes.  Otherwise the mask has B<i-1> leading zeroes followed by all ones thereafter.
 {my ($chip, $output, $input, %options) = @_;                                   # Chip, output name, input mask, options
  @_ >= 3 or confess "Three or more parameters";
  my $I = sizeBits($chip, $input);
  my $B = 2**$I-1;
  my $o = $output;

  $chip->notBits("$o.n", $input);                                               # Not of each input

  for my $b(1..$B)                                                              # Each bit of the mask
   {my @s = (reverse split //, sprintf "%0${I}b", $b);                          # Bits for this point in the mask
    my %a;
    for  my $i(1..@s)
     {$a{$i} = n($s[$i-1] ? $input : "$o.n", $i);                               # Choose either the input bit or the not of the input but depending on the number being converted to binary
     }
    $chip->and(n("$o.a", $b), {%a});                                            # Set at this point and beyond
    $chip-> or(n($o, $b), [map {n("$o.a", $_)} 1..$b]);                         # Set mask
   }
  setSizeBits($chip, $o, $B);
  $chip
 }

sub chooseWordUnderMask($$$$%)                                                  # Choose one of a specified number of words B<w>, each of a specified width, using a point mask B<m> placing the selected word in B<o>.  If no word is selected then B<o> will be zero.
 {my ($chip, $output, $input, $mask, %options) = @_;                            # Chip, output, inputs, mask, options
  @_ >= 3 or confess "Three or more parameters";
  my $o = $output;

  my ($words, $bits) = sizeWords($chip, $input);
  my ($mi)           = sizeBits ($chip, $mask);
  $mi == $words or confess <<"END" =~ s/\n(.)/ $1/gsr;
Mask width $mi does not match number of words $words.
END

  for   my $w(1..$words)                                                        # And each bit of each word with the mask
   {for my $b(1..$bits)                                                         # Bits in each word
     {$chip->and(nn("$o.a", $w, $b), [n($mask, $w), nn($input, $w, $b)]);
     }
   }

  for   my $b(1..$bits)                                                         # Bits in each word
   {$chip->or(n($o, $b), [map {nn("$o.a", $_, $b)} 1..$words]);
   }
  setSizeBits($chip, $o, $bits);

  $chip
 }

sub findWord($$$$%)                                                             # Choose one of a specified number of words B<w>, each of a specified width, using a key B<k>.  Return a point mask B<o> indicating the locations of the key if found or or a mask equal to all zeroes if the key is not present.
 {my ($chip, $output, $key, $words, %options) = @_;                             # Chip, found point mask, key, words to search, options
  @_ >= 4 or confess "Four or more parameters";
  my $o = $output;
  my ($W, $B) = sizeWords($chip, $words);
  my $bits    = sizeBits ($chip, $key);
  $B == $bits or confess <<"END" =~ s/\n(.)/ $1/gsr;
Number of bits in each word $B differs from words in key $bits.
END
  for   my $w(1..$W)                                                            # Input words
   {$chip->compareEq(n($o, $w), n($words, $w), $key);                           # Compare each input word with the key to make a mask
   }
  setSizeBits($chip, $o, $W);

  $chip
 }

#D1 Simulate                                                                    # Simulate the behavior of the L<chip> given a set of values on its input gates.

my sub setBit($*$%)                                                             # Set a single bit
 {my ($chip, $name, $value, %options) = @_;                                     # Chip, name of input gates, number to set to, options
  @_ >= 3 or confess "Three or more parameters";
  my $g = getGate($chip, $name);
  my $t = $g->type;
  $g->io == gateOuterInput or confess <<"END" =~ s/\n(.)/ $1/gsr;
Only outer input gates are setable. Gate $name is of type $t
END
  my %i = ($name => $value ? $value : 0);
  %i
 }

sub setBits($*$%)                                                               # Set an array of input gates to a number prior to running a simulation.
 {my ($chip, $name, $value, %options) = @_;                                     # Chip, name of input gates, number to set to, options
  @_ >= 3 or confess "Three or more parameters";
  my $bits = sizeBits($chip, $name);                                            # Size of bus
  my $W = 2**$bits;
  $value >= 0 or confess <<"END";
Value $value is less than 0
END
  $value < $W or confess <<"END";
Value $value is greater then or equal to $W
END
  my @b = reverse split //,  sprintf "%0${bits}b", $value;
  my %i = map {n($name, $_) => $b[$_-1]} 1..$bits;
  %i
 }

sub setWords($$@)                                                               # Set an array of arrays of gates to an array of numbers prior to running a simulation.
 {my ($chip, $name, @values) = @_;                                              # Chip, name of input gates, number of bits in each array element, numbers to set to
  @_ >= 3 or confess "Three or more parameters";
  my ($words, $bits) = sizeWords($chip, $name);
  my %i;
  my $M = 2**$bits-1;                                                           # Maximum we can store in a word of this many bits
  for   my $w(1..$words)                                                        # Each word
   {my $n = shift @values;
    $n >= 0 or confess <<"END";
Value $n is less than 0
END
    $n <= $M or confess <<"END";
 "Value $n is greater then or equal to $M";
END
    my @b = split //,  sprintf "%0${bits}b", $n;
    for my $b(1..$bits)                                                         # Each bit
     {$i{nn($name, $w, $b)} = $b[-$b];
     }
   }
  %i
 }

sub connectBits($*$*%)                                                          # Create a connection list connecting a set of output bits on the one chip to a set of input bits on another chip.
 {my ($oc, $o, $ic, $i, %options) = @_;                                         # First chip, name of gates on first chip, second chip, names of gates on second chip, options
  @_ >= 4 or confess "Four or more parameters";
  my %c;
  my $O = sizeBits($oc, $o);
  my $I = sizeBits($ic, $i);
  $O == $I or confess <<"END";
Mismatch between size of bus $o at $O and bus $i at $I
END

  for my $b(1..$I)                                                              # Bit to connect
   {$c{n($o, $b)} = n($i, $b);                                                  # Connect bits
   }
  %c                                                                            # Connection list
 }

sub connectWords($*$*$$%)                                                       # Create a connection list connecting a set of words on the outer chip to a set of words on the inner chip.
 {my ($oc, $o, $ic, $i, $words, $bits, %options) = @_;                          # First chip, name of gates on first chip, second chip, names of gates on second chip, number of words to connect, options
  @_ >= 6 or confess "Six or more parameters";
  my %c;
  for   my $w(1..$bits)                                                         # Word to connect
   {for my $b(1..$bits)                                                         # Bit to connect
     {$c{nn($o, $w, $b)} = nn($i, $w, $b);                                      # Connection list
     }
   }
  %c                                                                            # Connection list
 }

my sub merge($%)                                                                # Merge a L<chip> and all its sub L<chips> to make a single L<chip>.
 {my ($chip, %options) = @_;                                                    # Chip, options

  my $gates = getGates $chip;                                                   # Gates implementing the chip and all of its sub chips
  setOuterGates ($chip, $gates);                                                # Set the outer gates which are to be connected to in the real word
  removeExcessIO($chip, $gates);                                                # By pass and then remove all interior IO gates as they are no longer needed

  my $c = newChip %$chip, %options, gates=>$gates, installs=>[];                # Create the new chip with all installs expanded
  #print($c, %options)     if $options{print};                                  # Print the gates
  #printSvg ($c, %options) if $options{svg};                                    # Draw the gates using svg
  checkIO $c;                                                                   # Check all inputs are connected to valid gates and that all outputs are used

  $c
 }

my sub simulationResults($%)                                                    # Simulation results obtained by specifying the inputs to all the L<lgs> on the L<chip> and allowing its output L<lgs> to stabilize.
 {my ($chip, %options) = @_;                                                    # Chip, hash of final values for each gate, options

  genHash(__PACKAGE__."::Simulation",                                           # Simulation results
    chip    => $chip,                                                           # Chip being simulated
    changed => $options{changed},                                               # Last time this gate changed
    steps   => $options{steps},                                                 # Number of steps to reach stability
    values  => $options{values},                                                # Values of every output at point of stability
    svg     => $options{svg},                                                   # Name of file containing svg drawing if requested
   );
 }

sub Silicon::Chip::Simulation::value($$%)                                       # Get the value of a gate as seen in a simulation.
 {my ($simulation, $name, %options) = @_;                                       # Chip, gate, options
  @_ >= 2 or confess "Two or more parameters";
  $simulation->values->{$name}                                                  # Value of gate
 }

my sub checkInputs($$%)                                                         # Check that an input value has been provided for every input pin on the chip.
 {my ($chip, $inputs, %options) = @_;                                           # Chip, inputs, hash of final values for each gate, options

  for my $g(values $chip->gates->%*)                                            # Each gate on chip
   {if   ($g->io == gateOuterInput)                                             # Outer input gate
     {my ($i) = values $g->inputs->%*;                                          # Inputs
      if (!defined($$inputs{$i}))                                               # Check we have a corresponding input
       {my $n = $g->output;
        confess "No input value for input gate: $n\n";
       }
     }
   }
 }

sub Silicon::Chip::Simulation::bInt($$%)                                        # Represent the state of bits in the simulation results as an unsigned binary integer.
 {my ($simulation, $output, %options) = @_;                                     # Chip, name of gates on bus, options
  @_ >= 2 or confess "Two or more parameters";
  my $B = sizeBits($simulation->chip, $output);
  my %v = $simulation->values->%*;
  my @b;
  for my $b(1..$B)                                                              # Bits
   {push @b, $v{n $output, $b};
   }

  eval join '', '0b', reverse @b;                                               # Convert to number
 }

sub Silicon::Chip::Simulation::wInt($$%)                                        # Represent the state of words in the simulation results as an array of unsigned binary integer.
 {my ($simulation, $output, %options) = @_;                                     # Chip, name of gates on bus, options
  @_ >= 2 or confess "Two or more parameters";
  my ($words, $bits) = sizeWords($simulation->chip, $output);
  my %v = $simulation->values->%*;
  my @w;
  for my $w(1..$words)                                                          # Words
   {my @b;
    for my $b(1..$bits)                                                         # Bits
     {push @b, $v{nn $output, $w, $b};
     }

    push @w,  eval join '', '0b', reverse @b;                                   # Convert to number
   }
  @w
 }

sub Silicon::Chip::Simulation::wordXToInteger($$%)                              # Represent the state of words in the simulation results as an array of unsigned binary integer.
 {my ($simulation, $output, %options) = @_;                                     # Chip, name of gates on bus, options
  @_ >= 2 or confess "Two or more parameters";
  my ($words, $bits) = sizeWords($simulation->chip, $output);
  my %v = $simulation->values->%*;
  my @w;
  for my $b(1..$bits)                                                           # Bits
   {my @b;
    for my $w(1..$words)                                                        # Words
     {push @b, $v{nn $output, $w, $b};
     }

    push @w,  eval join '', '0b', reverse @b;                                   # Convert to number
   }
  @w
 }

my sub simulationStep($$%)                                                      # One step in the simulation of the L<chip> after expansion of inner L<chips>.
 {my ($chip, $values, %options) = @_;                                           # Chip, current value of each gate, options
  my $gates = $chip->gates;                                                     # Gates on chip
  my %changes;                                                                  # Changes made

  for my $G(sort {$$gates{$a}->seq <=> $$gates{$b}->seq} keys %$gates)          # Each gate in sub chip on definition order to get a repeatable order
   {my $g = $$gates{$G};                                                        # Address gate
    my $t = $g->type;                                                           # Gate type
    my $n = $g->output;                                                         # Gate name
    my %i = $g->inputs->%*;                                                     # Inputs to gate
    my @i = map {$$values{$i{$_}}} sort keys %i;                                # Values of inputs to gates in input pin name order

    my $u = 0;                                                                  # Number of undefined inputs
    for my $i(@i)
     {++$u unless defined $i;
     }

    if ($u == 0)                                                                # All inputs defined
     {my $r;                                                                    # Result of gate operation
      if ($t =~ m(\Aand|nand\Z)i)                                               # Elaborate and B<and> and B<nand> gates
       {my $z = grep {!$_} @i;                                                  # Count zero inputs
        $r = $z ? 0 : 1;
        $r = !$r if $t =~ m(\Anand\Z)i;
       }
      elsif ($t =~ m(\A(input)\Z)i)                                             # An B<input> gate takes its value from the list of inputs or from an output gate in an inner chip
       {if (my @i = values $g->inputs->%*)                                      # Get the value of the input gate from the current values
         {my $n = $i[0];
             $r = $$values{$n};
         }
        else
         {confess "No driver for input gate: $n\n";
         }
       }
      elsif ($t =~ m(\A(continue|nor|not|or|output)\Z)i)                        # Elaborate B<not>, B<or> or B<output> gate. A B<continue> gate places its single input unchanged on its output
       {my $o = grep {$_} @i;                                                   # Count one inputs
        $r = $o ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Anor|not\Z)i;
       }
      elsif ($t =~ m(\A(nxor|xor)\Z)i)                                          # Elaborate B<xor>
       {@i == 2 or confess "$t gate: '$n' must have exactly two inputs\n";
        $r = $i[0] ^ $i[1] ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Anxor\Z)i;
       }
      elsif ($t =~ m(\A(gt|ngt)\Z)i)                                            # Elaborate B<a> more than B<b> - the input pins are assumed to be sorted by name with the first pin as B<a> and the second as B<b>
       {@i == 2 or confess "$t gate: '$n' must have exactly two inputs\n";
        $r = $i[0] > $i[1] ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Angt\Z)i;
       }
      elsif ($t =~ m(\A(lt|nlt)\Z)i)                                            # Elaborate B<a> less than B<b> - the input pins are assumed to be sorted by name with the first pin as B<a> and the second as B<b>
       {@i == 2 or confess "$t gate: '$n' must have exactly two inputs\n";
        $r = $i[0] < $i[1] ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Anlt\Z)i;
       }
      elsif ($t =~ m(\Aone\Z)i)                                                 # One
       {@i == 0 or confess "$t gate: '$n' must have no inputs\n";
        $r = 1;
       }
      elsif ($t =~ m(\Azero\Z)i)                                                # Zero
       {@i == 0 or confess "$t gate: '$n' must have no inputs\n";
        $r = 0;
       }
      else                                                                      # Unknown gate type
       {confess "Need implementation for '$t' gates";
       }
      $changes{$G} = $r unless defined($$values{$G}) and $$values{$G} == $r;    # Value computed by this gate
     }
   }
  %changes
 }

sub simulate($$%)                                                               # Simulate the action of the L<lgs> on a L<chip> for a given set of inputs until the output value of each L<lg> stabilizes.
 {my ($chip, $inputs, %options) = @_;                                           # Chip, Hash of input names to values, options
  @_ >= 2 or confess "Two or more parameters";
  my $c = merge($chip, %options);                                               # Merge all the sub chips to make one chip with no sub chips
  checkInputs($c, $inputs);                                                     # Confirm that there is an input value for every input to the chip

  my %values = %$inputs;                                                        # The current set of values contains just the inputs at the start of the simulation
  my %changed;                                                                  # Last step on which this gate changed.  We use this to order the gates on layout

  my $T = maxSimulationSteps;                                                   # Maximum steps
  for my $t(0..$T)                                                              # Steps in time
   {my %changes = simulationStep $c, \%values;                                  # Changes made

    if (!keys %changes)                                                         # Keep going until nothing changes
     {my $svg;                                                                  # Svg drawing of chip if requested
#      if ($options{svg})                                                        # Draw the gates using svg with the final values attached
#       {$svg = printSvg $c, values=>\%values, changed=>\%changed,
#                        steps=>$t, %options;
#       }
      if ($options{svg})                                                        # Layout the gates as a fiber bundle
       {$svg = drawMask $c, values=>\%values, changed=>\%changed,
          steps=>$t, %options;
       }
      return simulationResults $chip, values=>\%values, changed=>\%changed,     # Keep going until nothing changes
               steps=>$t, svg=>$svg;
     }

    for my $c(keys %changes)                                                    # Update state of circuit
     {$values{$c} = $changes{$c};
      if ($options{latest})
       {$changed{$c} = $t;                                                      # Latest time we changed this gate
       }
      else
       {$changed{$c} = $t unless defined($changed{$c});                         # Earliest time we changed this gate
       }
     }
   }

  confess "Out of time after $T steps";                                         # Not enough steps available
 }

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# containingFolder

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(connectBits connectWords n nn setBits setWords);
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

#Images https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/

=pod

=encoding utf-8

=for html <p><a href="https://github.com/philiprbrenan/SiliconChip"><img src="https://github.com/philiprbrenan/SiliconChip/workflows/Test/badge.svg"></a>

=head1 Name

Silicon::Chip - Design a L<silicon|https://en.wikipedia.org/wiki/Silicon> L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> by combining L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> and sub L<chips|https://en.wikipedia.org/wiki/Integrated_circuit>.

=head1 Synopsis

Create a chip to compare two 4 bit big endian unsigned integers for equality:

  my $B = 4;                                              # Number of bits

  my $c = Silicon::Chip::newChip(title=>"$B Bit Equals"); # Create chip

  $c->input ("a$_")                       for 1..$B;      # First number
  $c->input ("b$_")                       for 1..$B;      # Second number

  $c->nxor  ("e$_", {1=>"a$_", 2=>"b$_"}) for 1..$B;      # Test each bit for equality
  $c->and   ("and", {map{$_=>"e$_"}           1..$B});    # And tests together to get total equality

  $c->output("out", "and");                               # Output gate

  my $s = $c->simulate({a1=>1, a2=>0, a3=>1, a4=>0,       # Input gate values
                        b1=>1, b2=>0, b3=>1, b4=>0},
                        svg=>q(svg/Equals$B));             # Svg drawing of layout

  is_deeply($s->steps,         3);                        # Three steps
  is_deeply($s->values->{out}, 1);                        # Out is 1 for equals

  my $t = $c->simulate({a1=>1, a2=>1, a3=>1, a4=>0,
                        b1=>1, b2=>0, b3=>1, b4=>0});
  is_deeply($t->values->{out}, 0);                        # Out is 0 for not equals

To obtain:

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Equals.svg">

Other circuit diagrams can be seen in folder: L<lib/Silicon/svg|https://github.com/philiprbrenan/SiliconChip/tree/main/lib/Silicon/svg>

=head1 Description

Design a L<silicon|https://en.wikipedia.org/wiki/Silicon> L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> by combining L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> and sub L<chips|https://en.wikipedia.org/wiki/Integrated_circuit>.


Version 20231118.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Construct

Construct a L<Silicon|https://en.wikipedia.org/wiki/Silicon> L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> using standard L<logic gates|https://en.wikipedia.org/wiki/Logic_gate>, components and sub chips combined via buses.

=head2 newChip (%options)

Create a new L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  %options   Options

B<Example:>


  if (1)

   {my $c = Silicon::Chip::newChip;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $c->one ("one");
    $c->zero("zero");
    $c->or  ("or",   [qw(one zero)]);
    $c->and ("and",  [qw(one zero)]);
    $c->output("o1", "or");
    $c->output("o2", "and");
    my $s = $c->simulate({}, svg=>q(svg/oneZero));
    is_deeply($s->steps       , 3);
    is_deeply($s->value("o1"), 1);
    is_deeply($s->value("o2"), 0);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/oneZero.svg">

  if (1)                                                                           # Single AND gate

   {my $c = Silicon::Chip::newChip;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $c->input ("i1");
    $c->input ("i2");
    $c->and   ("and1", [qw(i1 i2)]);
    $c->output("o", "and1");
    my $s = $c->simulate({i1=>1, i2=>1}, svg=>q(svg/and));
    ok($s->steps         == 2);
    ok($s->value("and1") == 1);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/and.svg">

  if (1)                                                                           # 4 bit equal
   {my $B = 4;                                                                    # Number of bits


    my $c = Silicon::Chip::newChip(title=><<"END");                               # Create chip  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  $B Bit Equals
  END
    $c->input ("a$_")                 for 1..$B;                                  # First number
    $c->input ("b$_")                 for 1..$B;                                  # Second number

    $c->nxor  ("e$_", "a$_", "b$_")   for 1..$B;                                  # Test each bit for equality
    $c->and   ("and", {map{$_=>"e$_"}     1..$B});                                # And tests together to get total equality

    $c->output("out", "and");                                                     # Output gate

    my $s = $c->simulate({a1=>1, a2=>0, a3=>1, a4=>0,                             # Input gate values
                          b1=>1, b2=>0, b3=>1, b4=>0},
                          svg=>q(svg/Equals));                                    # Svg drawing of layout

    is_deeply($s->steps,        3);                                               # Three steps
    is_deeply($s->value("out"), 1);                                               # Out is 1 for equals
    is_deeply(substr(md5_hex(readFile $s->svg), 0, 4), '9ff8');

    my $t = $c->simulate({a1=>1, a2=>1, a3=>1, a4=>0,
                          b1=>1, b2=>0, b3=>1, b4=>0});
    is_deeply($t->value("out"), 0);                                               # Out is 0 for not equals
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Equals.svg">


=head2 gate($chip, $type, $output, $input1, $input2)

A L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> chosen from B<and|continue|gt|input|lt|nand|nor|not|nxor|one|or|output|xor|zero>.  The gate type can be used as a method name, so B<-E<gt>gate("and",> can be reduced to B<-E<gt>and(>.

     Parameter  Description
  1  $chip      Chip
  2  $type      Gate type
  3  $output    Output name
  4  $input1    Input from another gate
  5  $input2    Input from another gate

B<Example:>



  if (1)                                                                           # Two AND gates driving an OR gate  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   {my $c = newChip;
    $c->input ("i11");
    $c->input ("i12");
    $c->and   ("and1", [qw(i11   i12)]);
    $c->input ("i21");
    $c->input ("i22");
    $c->and   ("and2", [qw(i21   i22 )]);
    $c->or    ("or",   [qw(and1  and2)]);
    $c->output( "o", "or");
    my $s = $c->simulate({i11=>1, i12=>1, i21=>1, i22=>1}, svg=>q(svg/andOr));
    ok($s->steps        == 3);
    ok($s->value("or")  == 1);
       $s  = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>1});
    ok($s->steps        == 3);
    ok($s->value("or")  == 1);
       $s  = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>0});
    ok($s->steps        == 3);
    ok($s->value("o")   == 0);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOr.svg">


=head2 Buses

A bus is an array of bits or an array of arrays of bits

=head3 Bits

An array of bits that can be manipulated via one name.

=head4 setSizeBits ($chip, $name, $bits, %options)

Set the size of a bits bus.

     Parameter  Description
  1  $chip      Chip
  2  $name      Bits bus name
  3  $bits      Options
  4  %options

B<Example:>


  if (1)
   {my $c = newChip();

    $c->setSizeBits ('i', 2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $c->setSizeWords('j', 3, 2);
    is_deeply($c->sizeBits,  {i => 2, j_1 => 2, j_2 => 2, j_3 => 2});
    is_deeply($c->sizeWords, {j => [3, 2]});
   }


=head4 bits($chip, $name, $bits, $value, %options)

Create a bus set to a specified number.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $bits      Width in bits of bus
  4  $value     Value of bus
  5  %options   Options

B<Example:>


  if (1)
   {my $N = 4;
    for my $i(0..2**$N-1)
     {my $c = Silicon::Chip::newChip;

      $c->bits      ("c", $N, $i);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->outputBits("o", "c");

      my $s = $c->simulate({}, $i == 3 ? (svg=>q(svg/bits)) : ());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply($s->steps, 2);
      is_deeply($s->bInt("o"), $i);
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/bits.svg">


=head4 inputBits   ($chip, $name, $bits, %options)

Create an B<input> bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $bits      Width in bits of bus
  4  %options   Options

B<Example:>


  if (1)
   {my $W = 8;
    my $i = newChip(name=>"not");

       $i->inputBits('i', $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $i->notBits   (qw(n i));
       $i->outputBits(qw(o n));

    my $o = newChip(name=>"outer");

       $o->inputBits ('a', $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $o->outputBits(qw(A a));

       $o->inputBits ('b', $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $o->outputBits(qw(B b));

    my %i = connectBits($i, 'i', $o, 'A');
    my %o = connectBits($i, 'o', $o, 'b');
    $o->install($i, {%i}, {%o});

    my %d = setBits($o, 'a', 0b10110);
    my $s = $o->simulate({%d}, svg=>q(svg/not));
    is_deeply($s->bInt('B'), 0b11101001);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/not.svg">


=head4 outputBits  ($chip, $name, $input, %options)

Create an B<output> bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my $W = 8;
    my $i = newChip(name=>"not");
       $i->inputBits('i', $W);
       $i->notBits   (qw(n i));

       $i->outputBits(qw(o n));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my $o = newChip(name=>"outer");
       $o->inputBits ('a', $W);

       $o->outputBits(qw(A a));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $o->inputBits ('b', $W);

       $o->outputBits(qw(B b));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my %i = connectBits($i, 'i', $o, 'A');
    my %o = connectBits($i, 'o', $o, 'b');
    $o->install($i, {%i}, {%o});

    my %d = setBits($o, 'a', 0b10110);
    my $s = $o->simulate({%d}, svg=>q(svg/not));
    is_deeply($s->bInt('B'), 0b11101001);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/not.svg">

  if (1)
   {my @B = ((my $W = 4), (my $B = 2));

    my $c = newChip();
       $c->inputWords ('i', @B);
       $c->andWords   (qw(and  i));
       $c->andWordsX  (qw(andX i));
       $c-> orWords   (qw( or  i));
       $c-> orWordsX  (qw( orX i));
       $c->notWords   (qw(n    i));

       $c->outputBits (qw(And  and));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


       $c->outputBits (qw(AndX andX));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


       $c->outputBits (qw(Or   or));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


       $c->outputBits (qw(OrX  orX));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputWords(qw(N    n));
    my %d = setWords($c, 'i', 0b00, 0b01, 0b10, 0b11);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrWords));

    is_deeply($s->bInt('And'),  0b1000);
    is_deeply($s->bInt('AndX'), 0b0000);

    is_deeply($s->bInt('Or'),  0b1110);
    is_deeply($s->bInt('OrX'), 0b11);
    is_deeply([$s->wInt('N')], [3, 2, 1, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrWords.svg">


=head4 notBits ($chip, $name, $input, %options)

Create a B<not> bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my $W = 8;
    my $i = newChip(name=>"not");
       $i->inputBits('i', $W);

       $i->notBits   (qw(n i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $i->outputBits(qw(o n));

    my $o = newChip(name=>"outer");
       $o->inputBits ('a', $W);
       $o->outputBits(qw(A a));
       $o->inputBits ('b', $W);
       $o->outputBits(qw(B b));

    my %i = connectBits($i, 'i', $o, 'A');
    my %o = connectBits($i, 'o', $o, 'b');
    $o->install($i, {%i}, {%o});

    my %d = setBits($o, 'a', 0b10110);
    my $s = $o->simulate({%d}, svg=>q(svg/not));
    is_deeply($s->bInt('B'), 0b11101001);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/not.svg">


=head4 andBits ($chip, $name, $input, %options)

B<and> a bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my $W = 8;

    my $c = newChip();
       $c-> inputBits('i', $W);

       $c->   andBits(qw(and  i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->    orBits(qw(or   i));
       $c->  nandBits(qw(nand i));
       $c->   norBits(qw(nor  i));
       $c->output    (qw(And  and));
       $c->output    (qw(Or   or));
       $c->output    (qw(nAnd nand));
       $c->output    (qw(nOr  nor));

    my %d = setBits($c, 'i', 0b10110);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));

    is_deeply($s->value("And"),  0);
    is_deeply($s->value("Or"),   1);
    is_deeply($s->value("nAnd"), 1);
    is_deeply($s->value("nOr"),  0);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrBits.svg">


=head4 nandBits($chip, $name, $input, %options)

B<nand> a bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my $W = 8;

    my $c = newChip();
       $c-> inputBits('i', $W);
       $c->   andBits(qw(and  i));
       $c->    orBits(qw(or   i));

       $c->  nandBits(qw(nand i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->   norBits(qw(nor  i));
       $c->output    (qw(And  and));
       $c->output    (qw(Or   or));
       $c->output    (qw(nAnd nand));
       $c->output    (qw(nOr  nor));

    my %d = setBits($c, 'i', 0b10110);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));

    is_deeply($s->value("And"),  0);
    is_deeply($s->value("Or"),   1);
    is_deeply($s->value("nAnd"), 1);
    is_deeply($s->value("nOr"),  0);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrBits.svg">


=head4 orBits  ($chip, $name, $input, %options)

B<or> a bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Options
  4  %options

B<Example:>


  if (1)
   {my $W = 8;

    my $c = newChip();
       $c-> inputBits('i', $W);
       $c->   andBits(qw(and  i));

       $c->    orBits(qw(or   i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->  nandBits(qw(nand i));
       $c->   norBits(qw(nor  i));
       $c->output    (qw(And  and));
       $c->output    (qw(Or   or));
       $c->output    (qw(nAnd nand));
       $c->output    (qw(nOr  nor));

    my %d = setBits($c, 'i', 0b10110);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));

    is_deeply($s->value("And"),  0);
    is_deeply($s->value("Or"),   1);
    is_deeply($s->value("nAnd"), 1);
    is_deeply($s->value("nOr"),  0);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrBits.svg">


=head4 norBits ($chip, $name, $input, %options)

B<nor> a bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Options
  4  %options

B<Example:>


  if (1)
   {my $W = 8;

    my $c = newChip();
       $c-> inputBits('i', $W);
       $c->   andBits(qw(and  i));
       $c->    orBits(qw(or   i));
       $c->  nandBits(qw(nand i));

       $c->   norBits(qw(nor  i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->output    (qw(And  and));
       $c->output    (qw(Or   or));
       $c->output    (qw(nAnd nand));
       $c->output    (qw(nOr  nor));

    my %d = setBits($c, 'i', 0b10110);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));

    is_deeply($s->value("And"),  0);
    is_deeply($s->value("Or"),   1);
    is_deeply($s->value("nAnd"), 1);
    is_deeply($s->value("nOr"),  0);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrBits.svg">


=head3 Words

An array of arrays of bits that can be manipulated via one name.

=head4 setSizeWords($chip, $name, $words, $bits, %options)

Set the size of a bits bus.

     Parameter  Description
  1  $chip      Chip
  2  $name      Bits bus name
  3  $words     Words
  4  $bits      Bits per word
  5  %options   Options

B<Example:>


  if (1)
   {my $c = newChip();
    $c->setSizeBits ('i', 2);

    $c->setSizeWords('j', 3, 2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply($c->sizeBits,  {i => 2, j_1 => 2, j_2 => 2, j_3 => 2});
    is_deeply($c->sizeWords, {j => [3, 2]});
   }


=head4 words   ($chip, $name, $bits, @values)

Create a word bus set to specified numbers.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $bits      Width in bits of each word
  4  @values    Values of words

B<Example:>


  if (1)                                                                           # Internal input gate
   {my @n = qw(3 2 1 2 3);
    my $c = newChip();

       $c->words('i', 2, @n);                                                     # Input  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputWords(qw(o i));                                                  # Output

    my $s = $c->simulate({}, svg=>q(svg/words));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply($s->steps, 2);
    is_deeply([$s->wInt("i")], [@n]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/words.svg">


=head4 inputWords  ($chip, $name, $words, $bits, %options)

Create an B<input> bus made of words.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $words     Width in words of bus
  4  $bits      Width in bits of each word on bus
  5  %options   Options

B<Example:>


  if (1)
   {my @b = ((my $W = 4), (my $B = 3));

    my $c = newChip();

       $c->inputWords ('i',      @b);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputWords(qw(o i));

    my %d = setWords($c, 'i', 0b000, 0b001, 0b010, 0b011);
    my $s = $c->simulate({%d}, svg=>q(svg/words$W));

    is_deeply([$s->wInt('o')], [0..3]);
    is_deeply([$s->wordXToInteger('o')], [10, 12, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/words$W.svg">


=head4 outputWords ($chip, $name, $input, %options)

Create an B<output> bus made of words.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my @b = ((my $W = 4), (my $B = 3));

    my $c = newChip();
       $c->inputWords ('i',      @b);

       $c->outputWords(qw(o i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my %d = setWords($c, 'i', 0b000, 0b001, 0b010, 0b011);
    my $s = $c->simulate({%d}, svg=>q(svg/words$W));

    is_deeply([$s->wInt('o')], [0..3]);
    is_deeply([$s->wordXToInteger('o')], [10, 12, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/words$W.svg">


=head4 notWords($chip, $name, $input, %options)

Create a B<not> bus made of words.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my @B = ((my $W = 4), (my $B = 2));

    my $c = newChip();
       $c->inputWords ('i', @B);
       $c->andWords   (qw(and  i));
       $c->andWordsX  (qw(andX i));
       $c-> orWords   (qw( or  i));
       $c-> orWordsX  (qw( orX i));

       $c->notWords   (qw(n    i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits (qw(And  and));
       $c->outputBits (qw(AndX andX));
       $c->outputBits (qw(Or   or));
       $c->outputBits (qw(OrX  orX));
       $c->outputWords(qw(N    n));
    my %d = setWords($c, 'i', 0b00, 0b01, 0b10, 0b11);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrWords));

    is_deeply($s->bInt('And'),  0b1000);
    is_deeply($s->bInt('AndX'), 0b0000);

    is_deeply($s->bInt('Or'),  0b1110);
    is_deeply($s->bInt('OrX'), 0b11);
    is_deeply([$s->wInt('N')], [3, 2, 1, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrWords.svg">


=head4 andWords($chip, $name, $input, %options)

B<and> a bus made of words to produce a single word.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my @B = ((my $W = 4), (my $B = 2));

    my $c = newChip();
       $c->inputWords ('i', @B);

       $c->andWords   (qw(and  i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->andWordsX  (qw(andX i));
       $c-> orWords   (qw( or  i));
       $c-> orWordsX  (qw( orX i));
       $c->notWords   (qw(n    i));
       $c->outputBits (qw(And  and));
       $c->outputBits (qw(AndX andX));
       $c->outputBits (qw(Or   or));
       $c->outputBits (qw(OrX  orX));
       $c->outputWords(qw(N    n));
    my %d = setWords($c, 'i', 0b00, 0b01, 0b10, 0b11);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrWords));

    is_deeply($s->bInt('And'),  0b1000);
    is_deeply($s->bInt('AndX'), 0b0000);

    is_deeply($s->bInt('Or'),  0b1110);
    is_deeply($s->bInt('OrX'), 0b11);
    is_deeply([$s->wInt('N')], [3, 2, 1, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrWords.svg">

  if (1)
   {my @b = ((my $W = 4), (my $B = 3));

    my $c = newChip();
       $c->inputWords ('i',      @b);
       $c->outputWords(qw(o i));

    my %d = setWords($c, 'i', 0b000, 0b001, 0b010, 0b011);
    my $s = $c->simulate({%d}, svg=>q(svg/words$W));

    is_deeply([$s->wInt('o')], [0..3]);
    is_deeply([$s->wordXToInteger('o')], [10, 12, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/words$W.svg">


=head4 andWordsX   ($chip, $name, $input, %options)

B<and> a bus made of words by and-ing the corresponding bits in each word to make a single word.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my @B = ((my $W = 4), (my $B = 2));

    my $c = newChip();
       $c->inputWords ('i', @B);
       $c->andWords   (qw(and  i));

       $c->andWordsX  (qw(andX i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c-> orWords   (qw( or  i));
       $c-> orWordsX  (qw( orX i));
       $c->notWords   (qw(n    i));
       $c->outputBits (qw(And  and));
       $c->outputBits (qw(AndX andX));
       $c->outputBits (qw(Or   or));
       $c->outputBits (qw(OrX  orX));
       $c->outputWords(qw(N    n));
    my %d = setWords($c, 'i', 0b00, 0b01, 0b10, 0b11);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrWords));

    is_deeply($s->bInt('And'),  0b1000);
    is_deeply($s->bInt('AndX'), 0b0000);

    is_deeply($s->bInt('Or'),  0b1110);
    is_deeply($s->bInt('OrX'), 0b11);
    is_deeply([$s->wInt('N')], [3, 2, 1, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrWords.svg">


=head4 orWords ($chip, $name, $input, %options)

B<or> a bus made of words to produce a single word.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my @B = ((my $W = 4), (my $B = 2));

    my $c = newChip();
       $c->inputWords ('i', @B);
       $c->andWords   (qw(and  i));
       $c->andWordsX  (qw(andX i));

       $c-> orWords   (qw( or  i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c-> orWordsX  (qw( orX i));
       $c->notWords   (qw(n    i));
       $c->outputBits (qw(And  and));
       $c->outputBits (qw(AndX andX));
       $c->outputBits (qw(Or   or));
       $c->outputBits (qw(OrX  orX));
       $c->outputWords(qw(N    n));
    my %d = setWords($c, 'i', 0b00, 0b01, 0b10, 0b11);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrWords));

    is_deeply($s->bInt('And'),  0b1000);
    is_deeply($s->bInt('AndX'), 0b0000);

    is_deeply($s->bInt('Or'),  0b1110);
    is_deeply($s->bInt('OrX'), 0b11);
    is_deeply([$s->wInt('N')], [3, 2, 1, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrWords.svg">

  if (1)
   {my @b = ((my $W = 4), (my $B = 3));

    my $c = newChip();
       $c->inputWords ('i',      @b);
       $c->outputWords(qw(o i));

    my %d = setWords($c, 'i', 0b000, 0b001, 0b010, 0b011);
    my $s = $c->simulate({%d}, svg=>q(svg/words$W));

    is_deeply([$s->wInt('o')], [0..3]);
    is_deeply([$s->wordXToInteger('o')], [10, 12, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/words$W.svg">


=head4 orWordsX($chip, $name, $input, %options)

B<or> a bus made of words by or-ing the corresponding bits in each word to make a single word.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  %options   Options

B<Example:>


  if (1)
   {my @B = ((my $W = 4), (my $B = 2));

    my $c = newChip();
       $c->inputWords ('i', @B);
       $c->andWords   (qw(and  i));
       $c->andWordsX  (qw(andX i));
       $c-> orWords   (qw( or  i));

       $c-> orWordsX  (qw( orX i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->notWords   (qw(n    i));
       $c->outputBits (qw(And  and));
       $c->outputBits (qw(AndX andX));
       $c->outputBits (qw(Or   or));
       $c->outputBits (qw(OrX  orX));
       $c->outputWords(qw(N    n));
    my %d = setWords($c, 'i', 0b00, 0b01, 0b10, 0b11);
    my $s = $c->simulate({%d}, svg=>q(svg/andOrWords));

    is_deeply($s->bInt('And'),  0b1000);
    is_deeply($s->bInt('AndX'), 0b0000);

    is_deeply($s->bInt('Or'),  0b1110);
    is_deeply($s->bInt('OrX'), 0b11);
    is_deeply([$s->wInt('N')], [3, 2, 1, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrWords.svg">


=head2 Connect

Connect input buses to other buses.

=head3 connectInput($chip, $in, $to, %options)

Connect a previously defined input gate to the output of another gate on the same chip. This allows us to define a set of gates on the chip without having to know, first, all the names of the gates that will provide input to these gates.

     Parameter  Description
  1  $chip      Chip
  2  $in        Input gate
  3  $to        Gate to connect input gate to
  4  %options   Options

B<Example:>


  if (1)                                                                          # Internal input gate
   {my $c = newChip();
       $c->input ('i');                                                           # Input
       $c->input ('j');                                                           # Internal input which we will connect to later
       $c->output(qw(o j));                                                       # Output


       $c->connectInput(qw(j i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    my $s = $c->simulate({i=>1}, svg=>q(svg/connectInput));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply($s->steps, 1);
    is_deeply($s->value("j"), undef);
    is_deeply($s->value("o"), 1);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/connectInput.svg">

  if (1)                                                                           # Internal input gate
   {my @n = qw(3 2 1 2 3);
    my $c = newChip();
       $c->words('i', 2, @n);                                                     # Input
       $c->outputWords(qw(o i));                                                  # Output
    my $s = $c->simulate({}, svg=>q(svg/words));
    is_deeply($s->steps, 2);
    is_deeply([$s->wInt("i")], [@n]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/words.svg">


=head3 connectInputBits($chip, $in, $to, %options)

Connect a previously defined input bit bus to another bit bus provided the two buses have the same size.

     Parameter  Description
  1  $chip      Chip
  2  $in        Input gate
  3  $to        Gate to connect input gate to
  4  %options   Options

B<Example:>


  if (1)
   {my $N = 5; my $B = 5;
     my $c = newChip();
    $c->bits      ('a', $B, $N);
    $c->inputBits ('i', $N);
    $c->outputBits(qw(o i));

    $c->connectInputBits(qw(i a));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my $s = $c->simulate({}, svg=>q(svg/connectInputBits));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply($s->steps, 2);
    is_deeply($s->bInt("o"), $N);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/connectInputBits.svg">


=head3 connectInputWords   ($chip, $in, $to, %options)

Connect a previously defined input word bus to another word bus provided the two buses have the same size.

     Parameter  Description
  1  $chip      Chip
  2  $in        Input gate
  3  $to        Gate to connect input gate to
  4  %options   Options

B<Example:>


  if (1)
   {my $W = 6; my $B = 5;
    my $c = newChip();
    $c->words      ('a',     $B, 1..$W);
    $c->inputWords ('i', $W, $B);
    $c->outputWords(qw(o i));

    $c->connectInputWords(qw(i a));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my $s = $c->simulate({}, svg=>q(svg/connectInputWords));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply($s->steps, 2);
    is_deeply([$s->wInt("o")], [1..$W]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/connectInputWords.svg">


=head2 Install

Install a chip within a chip as a sub chip.

=head3 install ($chip, $subChip, $inputs, $outputs, %options)

Install a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> within another L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> specifying the connections between the inner and outer L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.  The same L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> can be installed multiple times as each L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> description is read only.

     Parameter  Description
  1  $chip      Outer chip
  2  $subChip   Inner chip
  3  $inputs    Inputs of inner chip to to outputs of outer chip
  4  $outputs   Outputs of inner chip to inputs of outer chip
  5  %options   Options

B<Example:>


  if (1)                                                                            # Install one chip inside another chip, specifically one chip that performs NOT is installed once to flip a value
   {my $i = newChip(name=>"not");
       $i-> inputBits('i',     1);
       $i->   notBits(qw(n i));
       $i->outputBits(qw(o n));

    my $o = newChip(name=>"outer");
       $o->inputBits('i', 1); $o->outputBits(qw(n i));
       $o->inputBits('I', 1); $o->outputBits(qw(N I));

    my %i = connectBits($i, 'i', $o, 'n');
    my %o = connectBits($i, 'o', $o, 'I');

    $o->install($i, {%i}, {%o});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my %d = $o->setBits('i', 1);
    my $s = $o->simulate({%d}, svg=>q(svg/notb1));

    is_deeply($s->steps,  2);
    is_deeply($s->values, {"(not 1 n_1)"=>0, "i_1"=>1, "N_1"=>0 });
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/notb1.svg">


=head1 Visualize

Visualize the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> in various ways.

=head2 print   ($chip, %options)

Dump the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> present on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  $chip      Chip
  2  %options   Gates

B<Example:>


  if (1)
   {my $c = Silicon::Chip::newChip(title=>"And gate");
    $c->input ("i1");
    $c->input ("i2");
    $c->and   ("and1", [qw(i1 i2)]);
    $c->output("o", "and1");
    my $s = $c->simulate({i1=>1, i2=>1});


    is_deeply($c->print, <<END);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  i1                              :     input                           i1
  i2                              :     input                           i2
  and1                            :     and                             i1 i2
  o                               :     output                          and1
  END


    is_deeply($s->print, <<END);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  i1                              :   1 input                           i1
  i2                              :   1 input                           i2
  and1                            :   1 and                             i1 i2
  o                               :   1 output                          and1
  END

    ok($s->printSvg ne $c->printSvg);
   }


=head2 Silicon::Chip::Simulation::print($sim, %options)

Print simulation results as text.

     Parameter  Description
  1  $sim       Simulation
  2  %options   Options

B<Example:>


  if (1)
   {my $c = Silicon::Chip::newChip(title=>"And gate");
    $c->input ("i1");
    $c->input ("i2");
    $c->and   ("and1", [qw(i1 i2)]);
    $c->output("o", "and1");
    my $s = $c->simulate({i1=>1, i2=>1});

    is_deeply($c->print, <<END);
  i1                              :     input                           i1
  i2                              :     input                           i2
  and1                            :     and                             i1 i2
  o                               :     output                          and1
  END

    is_deeply($s->print, <<END);
  i1                              :   1 input                           i1
  i2                              :   1 input                           i2
  and1                            :   1 and                             i1 i2
  o                               :   1 output                          and1
  END

    ok($s->printSvg ne $c->printSvg);
   }


=head2 printSvg($chip, %options)

Mask the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> onto a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> as an L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> drawing to help visualize the structure of the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> using a condensed input bus.

     Parameter  Description
  1  $chip      Chip
  2  %options   Options

B<Example:>


  if (1)
   {my $c = Silicon::Chip::newChip(title=>"And gate");
    $c->input ("i1");
    $c->input ("i2");
    $c->and   ("and1", [qw(i1 i2)]);
    $c->output("o", "and1");
    my $s = $c->simulate({i1=>1, i2=>1});

    is_deeply($c->print, <<END);
  i1                              :     input                           i1
  i2                              :     input                           i2
  and1                            :     and                             i1 i2
  o                               :     output                          and1
  END

    is_deeply($s->print, <<END);
  i1                              :   1 input                           i1
  i2                              :   1 input                           i2
  and1                            :   1 and                             i1 i2
  o                               :   1 output                          and1
  END


    ok($s->printSvg ne $c->printSvg);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }


=head2 Silicon::Chip::Simulation::printSvg ($sim, %options)

Print simulation results as svg.

     Parameter  Description
  1  $sim       Simulation
  2  %options   Options

B<Example:>


  if (1)
   {my $c = Silicon::Chip::newChip(title=>"And gate");
    $c->input ("i1");
    $c->input ("i2");
    $c->and   ("and1", [qw(i1 i2)]);
    $c->output("o", "and1");
    my $s = $c->simulate({i1=>1, i2=>1});

    is_deeply($c->print, <<END);
  i1                              :     input                           i1
  i2                              :     input                           i2
  and1                            :     and                             i1 i2
  o                               :     output                          and1
  END

    is_deeply($s->print, <<END);
  i1                              :   1 input                           i1
  i2                              :   1 input                           i2
  and1                            :   1 and                             i1 i2
  o                               :   1 output                          and1
  END

    ok($s->printSvg ne $c->printSvg);
   }


=head1 Basic Circuits

Some well known basic circuits.

=head2 n   ($c, $i)

Gate name from single index.

     Parameter  Description
  1  $c         Gate name
  2  $i         Bit number

B<Example:>


  if (1)

   {is_deeply( n(a,1),   "a_1");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply(nn(a,1,2), "a_1_2");
   }


=head2 nn  ($c, $i, $j)

Gate name from double index.

     Parameter  Description
  1  $c         Gate name
  2  $i         Word number
  3  $j         Bit number

B<Example:>


  if (1)
   {is_deeply( n(a,1),   "a_1");

    is_deeply(nn(a,1,2), "a_1_2");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }


=head2 Comparisons

Compare unsigned binary integers of specified bit widths.

=head3 compareEq   ($chip, $output, $a, $b, %options)

Compare two unsigned binary integers of a specified width returning B<1> if they are equal else B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the output bus
  3  $a         First integer
  4  $b         Second integer
  5  %options   Options

B<Example:>


  if (1)                                                                           # Compare unsigned integers
   {my $B = 2;

    my $c = Silicon::Chip::newChip(title=><<"END");
  $B Bit Compare Equal
  END
    $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers

    $c->compareEq(qw(o a b));                                                     # Compare equals  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $c->output   (qw(out o));                                                     # Comparison result

    for   my $i(0..2**$B-1)                                                       # Each possible number
     {for my $j(0..2**$B-1)                                                       # Each possible number
       {my %a = $c->setBits('a', $i);                                             # Number a
        my %b = $c->setBits('b', $j);                                             # Number b

        my $s = $c->simulate({%a, %b}, $i==1&&$j==1?(svg=>q(svg/CompareEq)):());   # Svg drawing of layout

        is_deeply($s->value("out"), $i == $j ? 1 : 0);                            # Equal
        is_deeply($s->steps, 3);                                                  # Number of steps to stability
       }
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/CompareEq.svg">


=head3 compareGt   ($chip, $output, $a, $b, %options)

Compare two unsigned binary integers and return B<1> if the first integer is more than B<b> else B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the output bus
  3  $a         First integer
  4  $b         Second integer
  5  %options   Options

B<Example:>


  if (1)                                                                           # Compare 8 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
   {my $B = 3;
    my $c = Silicon::Chip::newChip(title=><<END);
  $B Bit Compare more than
  END
    $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers

    $c->compareGt(qw(o a b));                                                     # Compare more than  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $c->output   (qw(out o));                                                     # Comparison result

    for   my $i(0..2**$B-1)                                                       # Each possible number
     {for my $j(0..2**$B-1)                                                       # Each possible number
       {#$i = 2; $j = 1;
        my %a = $c->setBits('a', $i);                                             # Number a
        my %b = $c->setBits('b', $j);                                             # Number b

        my $s = $c->simulate({%a, %b}, $i==2&&$j==1?(svg=>q(svg/CompareGt)):());   # Svg drawing of layout
        is_deeply($s->value("out"), $i > $j ? 1 : 0);                             # More than
        is_deeply($s->steps, 4);                                                  # Number of steps to stability
       }
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/CompareGt.svg">


=head3 compareLt   ($chip, $output, $a, $b, %options)

Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is B<1> if B<a> is less than B<b> else B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the output bus
  3  $a         First integer
  4  $b         Second integer
  5  %options   Options

B<Example:>


  if (1)                                                                           # Compare 8 bit unsigned integers 'a' < 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
   {my $B = 3;
    my $c = Silicon::Chip::newChip(title=><<"END");
  $B Bit Compare Less Than
  END
    $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers

    $c->compareLt(qw(o a b));                                                     # Compare less than  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $c->output   (qw(out o));                                                     # Comparison result

    for   my $i(0..2**$B-1)                                                       # Each possible number
     {for my $j(0..2**$B-1)                                                       # Each possible number
       {my %a = $c->setBits('a', $i);                                             # Number a
        my %b = $c->setBits('b', $j);                                             # Number b

        my $s = $c->simulate({%a, %b}, $i==1&&$j==2?(svg=>q(svg/CompareLt)):());   # Svg drawing of layout
        is_deeply($s->value("out"), $i < $j ? 1 : 0);                             # More than
        is_deeply($s->steps, 4);                                                  # Number of steps to stability
       }
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/CompareLt.svg">


=head3 chooseFromTwoWords  ($chip, $output, $a, $b, $choose, %options)

Choose one of two words based on a bit.  The first word is chosen if the bit is B<0> otherwise the second word is chosen.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the chosen word
  3  $a         The first word
  4  $b         The second word
  5  $choose    The choosing bit
  6  %options   Options

B<Example:>


  if (1)
   {my $B = 4;

    my $c = newChip();
       $c->inputBits('a', $B);                                                    # First word
       $c->inputBits('b', $B);                                                    # Second word
       $c->input    ('c');                                                        # Chooser

       $c->chooseFromTwoWords(qw(o a b c));                                       # Generate gates  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits('out', 'o');                                                # Result

    my %a = setBits($c, 'a', 0b0011);
    my %b = setBits($c, 'b', 0b1100);


    my $s = $c->simulate({%a, %b, c=>1}, svg=>q(svg/chooseFromTwoWords));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply($s->steps,               4);
    is_deeply($s->bInt('out'), 0b1100);

    my $t = $c->simulate({%a, %b, c=>0});
    is_deeply($t->steps,               4);
    is_deeply($t->bInt('out'), 0b0011);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/chooseFromTwoWords.svg">


=head3 enableWord  ($chip, $output, $a, $enable, %options)

Output a word or zeros depending on a choice bit.  The first word is chosen if the choice bit is B<1> otherwise all zeroes are chosen.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the chosen word
  3  $a         The first word
  4  $enable    The second word
  5  %options   The choosing bit

B<Example:>


  if (1)
   {my $B = 4;

    my $c = newChip();
       $c->inputBits ('a', $B);                                                   # Word
       $c->input     ('c');                                                       # Choice bit

       $c->enableWord(qw(o a c));                                                 # Generate gates  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits(qw(out o));                                                 # Result

    my %a = setBits($c, 'a', 3);


    my $s = $c->simulate({%a, c=>1}, svg=>q(svg/enableWord));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply($s->steps,       2);
    is_deeply($s->bInt('out'), 3);

    my $t = $c->simulate({%a, c=>0});
    is_deeply($t->steps,       2);
    is_deeply($t->bInt('out'), 0);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/enableWord.svg">


=head2 Masks

Point masks and monotone masks. A point mask has a single B<1> in a sea of B<0>s as in B<00100>.  A monotone mask has zero or more B<0>s followed by all B<1>s as in: B<00111>.

=head3 pointMaskToInteger  ($chip, $output, $input, %options)

Convert a mask B<i> known to have at most a single bit on - also known as a B<point mask> - to an output number B<a> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point mask then output number B<a> is B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  %options   Options

B<Example:>


  if (1)
   {my $B = 4;
    my $N = 2**$B-1;

    my $c = Silicon::Chip::newChip(title=><<"END");
  $B bits point mask to integer
  END
    $c->inputBits         (qw(    i), $N);                                        # Mask with no more than one bit on

    $c->pointMaskToInteger(qw(o   i));                                            # Convert  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $c->outputBits        (qw(out o));                                            # Mask with no more than one bit on

    for my $i(0..$N)                                                              # Each position of mask
     {my %i = setBits($c, 'i', $i ? 1<<($i-1) : 0);                               # Point in each position with zero representing no position
      my $s = $c->simulate(\%i, $i == 5 ? (svg=>q(svg/point)) : ());
      is_deeply($s->steps, 2);
      my %o = $s->values->%*;                                                     # Output bits
      my $n = eval join '', '0b', map {$o{n(o,$_)}} reverse 1..$B;                # Output bits as number
      is_deeply($n, $i);
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/point.svg">


=head3 integerToPointMask  ($chip, $output, $input, %options)

Convert an integer B<i> of specified width to a point mask B<m>. If the input integer is B<0> then the mask is all zeroes as well.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  %options   Options

B<Example:>


  if (1)
   {my $B = 3;
    my $N = 2**$B-1;

    my $c = Silicon::Chip::newChip(title=><<"END");
  $B bit integer to $N bit monotone mask.
  END
       $c->inputBits         (qw(  i), $B);                                       # Input bus

       $c->integerToPointMask(qw(m i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits        (qw(o m));
    for my $i(0..$N)                                                              # Each position of mask
     {my %i = setBits($c, 'i', $i);

      my $s = $c->simulate(\%i, $i == 5 ? (svg=>q(svg/integerToPointMask)):());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply($s->steps, 3);

      my $r = $s->bInt('o');                                                      # Mask values
      is_deeply($r, $i ? 1<<($i-1) : 0);                                          # Expected mask
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/integerToPointMask.svg">


=head3 monotoneMaskToInteger   ($chip, $output, $input, %options)

Convert a monotone mask B<i> to an output number B<r> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point then output in B<r> is B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  %options   Options

B<Example:>


  if (1)
   {my $B = 4;
    my $N = 2**$B-1;

    my $c = Silicon::Chip::newChip(title=><<"END");
  $N bit monotone mask to $B bit integer
  END
       $c->inputBits            ('i',     $N);

       $c->monotoneMaskToInteger(qw(m i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits           (qw(o m));

    for my $i(0..$N-1)                                                            # Each monotone mask
     {my %i = setBits($c, 'i', $i > 0 ? 1<<$i-1 : 0);
      my $s = $c->simulate(\%i,

        $i == 5 ? (svg=>q(svg/monotoneMaskToInteger)) : ());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      is_deeply($s->steps, 4);
      is_deeply($s->bInt('m'), $i);
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/monotoneMaskToInteger.svg">


=head3 monotoneMaskToPointMask ($chip, $output, $input, %options)

Convert a monotone mask B<i> to a point mask B<o> representing the location in the mask of the first bit set to B<1>. If the monotone mask is all B<0>s then point mask is too.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  %options   Options

B<Example:>


  if (1)
   {my $B = 4;

    my $c = newChip();
       $c->inputBits('m', $B);                                                    # Monotone mask

       $c->monotoneMaskToPointMask(qw(o m));                                      # Generate gates  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits('out', 'o');                                                # Point mask

    for my $i(0..$B)
     {my %m = $c->setBits('m', eval '0b'.(1 x $i).('0' x ($B-$i)));

      my $s = $c->simulate({%m}, $i == 2 ? (svg=>q(svg/monotoneMaskToPointMask)) : ());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply($s->steps, 2);
      is_deeply($s->bInt('out'), $i ? (1<<($B-1)) / (1<<($i-1)) : 0);
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/monotoneMaskToPointMask.svg">


=head3 integerToMonotoneMask   ($chip, $output, $input, %options)

Convert an integer B<i> of specified width to a monotone mask B<m>. If the input integer is B<0> then the mask is all zeroes.  Otherwise the mask has B<i-1> leading zeroes followed by all ones thereafter.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  %options   Options

B<Example:>


  if (1)
   {my $B = 4;
    my $N = 2**$B-1;

    my $c = Silicon::Chip::newChip(title=><<"END");
  Convert $B bit integer to $N bit monotone mask
  END
       $c->inputBits            ('i', $B);                                        # Input gates

       $c->integerToMonotoneMask(qw(m i));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits           (qw(o m));                                        # Output gates

    for my $i(0..$N)                                                              # Each position of mask
     {my %i = setBits($c, 'i', $i);                                               # The number to convert
      my $s = $c->simulate(\%i, $i == 2 ? (svg=>q(svg/integerToMontoneMask)):());
      is_deeply($s->steps, 4);
      is_deeply($s->bInt('o'), $i > 0 ? ((1<<$N)-1)>>($i-1)<<($i-1) : 0);         # Expected mask
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/integerToMontoneMask.svg">


=head3 chooseWordUnderMask ($chip, $output, $input, $mask, %options)

Choose one of a specified number of words B<w>, each of a specified width, using a point mask B<m> placing the selected word in B<o>.  If no word is selected then B<o> will be zero.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output
  3  $input     Inputs
  4  $mask      Mask
  5  %options   Options

B<Example:>


  if (1)
   {my $B = 3; my $W = 4;

    my $c = Silicon::Chip::newChip(title=><<"END");
  Choose one of $W words of $B bits
  END
       $c->inputWords         ('w',       $W, $B);
       $c->inputBits          ('m',       $W);

       $c->chooseWordUnderMask(qw(W w m));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits         (qw(o W));

    my %i = setWords($c, 'w', 0b000, 0b001, 0b010, 0b0100);
    my %m = setBits ($c, 'm', 1<<2);                                              # Choose the third word

    my $s = $c->simulate({%i, %m}, svg=>q(svg/choose));

    is_deeply($s->steps, 3);
    is_deeply($s->bInt('o'), 0b010);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/choose.svg">


=head3 findWord($chip, $output, $key, $words, %options)

Choose one of a specified number of words B<w>, each of a specified width, using a key B<k>.  Return a point mask B<o> indicating the locations of the key if found or or a mask equal to all zeroes if the key is not present.

     Parameter  Description
  1  $chip      Chip
  2  $output    Found point mask
  3  $key       Key
  4  $words     Words to search
  5  %options   Options

B<Example:>


  if (1)
   {my $B = 3; my $W = 2**$B-1;

    my $c = Silicon::Chip::newChip(title=><<END);
  Search $W words of $B bits
  END
       $c->inputBits ('k',       $B);                                             # Search key
       $c->inputWords('w',       2**$B-1, $B);                                    # Words to search

       $c->findWord  (qw(m k w));                                                 # Find the word  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits(qw(M m));                                                   # Output mask

    my %w = setWords($c, 'w', reverse 1..$W);

    for my $k(0..$W)                                                              # Each possible key
     {my %k = setBits($c, 'k', $k);

      my $s = $c->simulate({%k, %w}, $k == 3 ? (svg=>q(svg/findWord)) : ());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply($s->steps, 3);
      is_deeply($s->bInt('M'),$k ? 2**($W-$k) : 0);
     }
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/findWord.svg">


=head1 Simulate

Simulate the behavior of the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> given a set of values on its input gates.

=head2 setBits ($chip, $name, $value, %options)

Set an array of input gates to a number prior to running a simulation.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of input gates
  3  $value     Number to set to
  4  %options   Options

B<Example:>


  if (1)                                                                           # Compare two 4 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
   {my $B = 4;                                                                    # Number of bits
    my $c = Silicon::Chip::newChip(title=><<"END");
  $B Bit Compare
  END
    $c->inputBits("a", $B);                                                       # First number
    $c->inputBits("b", $B);                                                       # Second number
    $c->nxor (n(e,$_), n(a,$_), n(b,$_)) for 1..$B-1;                             # Test each bit for equality
    $c->gt   (n(g,$_), n(a,$_), n(b,$_)) for 1..$B;                               # Test each bit pair for greater

    for my $b(2..$B)
     {$c->and(n(c,$b), [(map {n(e, $_)} 1..$b-1), n(g,$b)]);                      # Greater on one bit and all preceding bits are equal
     }
    $c->or    ("or",  [n(g,1), (map {n(c, $_)} 2..$B)]);                          # Any set bit indicates that 'a' is more than 'b'
    $c->output("out", "or");                                                      # Output 1 if a > b else 0


    my %a = $c->setBits('a', 0);                                                  # Number a  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my %b = $c->setBits('b', 0);                                                  # Number b  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my $s = $c->simulate({%a, %b, n(a,2)=>1, n(b,2)=>1}, svg=>q(svg/equals));     # Two equal numbers
    is_deeply($s->value("out"), 0);

    my $t = $c->simulate({%a, %b, n(a,2)=>1});
    is_deeply($t->value("out"), 1);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/equals.svg">

  if (1)
   {my $B = 3; my $W = 4;

    my $c = Silicon::Chip::newChip(title=><<"END");
  Choose one of $W words of $B bits
  END
       $c->inputWords         ('w',       $W, $B);
       $c->inputBits          ('m',       $W);
       $c->chooseWordUnderMask(qw(W w m));
       $c->outputBits         (qw(o W));

    my %i = setWords($c, 'w', 0b000, 0b001, 0b010, 0b0100);

    my %m = setBits ($c, 'm', 1<<2);                                              # Choose the third word  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my $s = $c->simulate({%i, %m}, svg=>q(svg/choose));

    is_deeply($s->steps, 3);
    is_deeply($s->bInt('o'), 0b010);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/choose.svg">


=head2 setWords($chip, $name, @values)

Set an array of arrays of gates to an array of numbers prior to running a simulation.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of input gates
  3  @values    Number of bits in each array element

B<Example:>


  if (1)
   {my $B = 3; my $W = 4;

    my $c = Silicon::Chip::newChip(title=><<"END");
  Choose one of $W words of $B bits
  END
       $c->inputWords         ('w',       $W, $B);
       $c->inputBits          ('m',       $W);
       $c->chooseWordUnderMask(qw(W w m));
       $c->outputBits         (qw(o W));


    my %i = setWords($c, 'w', 0b000, 0b001, 0b010, 0b0100);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my %m = setBits ($c, 'm', 1<<2);                                              # Choose the third word

    my $s = $c->simulate({%i, %m}, svg=>q(svg/choose));

    is_deeply($s->steps, 3);
    is_deeply($s->bInt('o'), 0b010);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/choose.svg">


=head2 connectBits ($oc, $o, $ic, $i, %options)

Create a connection list connecting a set of output bits on the one chip to a set of input bits on another chip.

     Parameter  Description
  1  $oc        First chip
  2  $o         Name of gates on first chip
  3  $ic        Second chip
  4  $i         Names of gates on second chip
  5  %options   Options

B<Example:>


  if (1)                                                                            # Install one chip inside another chip, specifically one chip that performs NOT is installed once to flip a value
   {my $i = newChip(name=>"not");
       $i-> inputBits('i',     1);
       $i->   notBits(qw(n i));
       $i->outputBits(qw(o n));

    my $o = newChip(name=>"outer");
       $o->inputBits('i', 1); $o->outputBits(qw(n i));
       $o->inputBits('I', 1); $o->outputBits(qw(N I));


    my %i = connectBits($i, 'i', $o, 'n');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my %o = connectBits($i, 'o', $o, 'I');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $o->install($i, {%i}, {%o});
    my %d = $o->setBits('i', 1);
    my $s = $o->simulate({%d}, svg=>q(svg/notb1));

    is_deeply($s->steps,  2);
    is_deeply($s->values, {"(not 1 n_1)"=>0, "i_1"=>1, "N_1"=>0 });
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/notb1.svg">


=head2 connectWords($oc, $o, $ic, $i, $words, $bits, %options)

Create a connection list connecting a set of words on the outer chip to a set of words on the inner chip.

     Parameter  Description
  1  $oc        First chip
  2  $o         Name of gates on first chip
  3  $ic        Second chip
  4  $i         Names of gates on second chip
  5  $words     Number of words to connect
  6  $bits      Options
  7  %options

B<Example:>


  if (1)                                                                           # Install one chip inside another chip, specifically one chip that performs NOT is installed three times sequentially to flip a value
   {my $i = newChip(name=>"not");
       $i-> inputWords('i', 1, 1);
       $i->   notWords(qw(n i));
       $i->outputWords(qw(o n));

    my $o = newChip(name=>"outer");
       $o->inputWords('i', 1, 1); $o->output(nn('n', 1, 1), nn('i', 1, 1));
       $o->inputWords('I', 1, 1); $o->output(nn('N', 1, 1), nn('I', 1, 1));


    my %i = connectWords($i, 'i', $o, 'n', 1, 1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my %o = connectWords($i, 'o', $o, 'I', 1, 1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $o->install($i, {%i}, {%o});
    my %d = $o->setWords('i', 1);
    my $s = $o->simulate({%d}, svg=>q(svg/notw1));

    is_deeply($s->steps,  2);
    is_deeply($s->values, { "(not 1 n_1_1)" => 0, "i_1_1" => 1, "N_1_1" => 0 });
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/notw1.svg">


=head2 Silicon::Chip::Simulation::value($simulation, $name, %options)

Get the value of a gate as seen in a simulation.

     Parameter    Description
  1  $simulation  Chip
  2  $name        Gate
  3  %options     Options

B<Example:>


  if (1)                                                                          # Internal input gate
   {my $c = newChip();
       $c->input ('i');                                                           # Input
       $c->input ('j');                                                           # Internal input which we will connect to later
       $c->output(qw(o j));                                                       # Output

       $c->connectInput(qw(j i));

    my $s = $c->simulate({i=>1}, svg=>q(svg/connectInput));
    is_deeply($s->steps, 1);
    is_deeply($s->value("j"), undef);
    is_deeply($s->value("o"), 1);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/connectInput.svg">

  if (1)                                                                           # Internal input gate
   {my @n = qw(3 2 1 2 3);
    my $c = newChip();
       $c->words('i', 2, @n);                                                     # Input
       $c->outputWords(qw(o i));                                                  # Output
    my $s = $c->simulate({}, svg=>q(svg/words));
    is_deeply($s->steps, 2);
    is_deeply([$s->wInt("i")], [@n]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/words.svg">


=head2 Silicon::Chip::Simulation::bInt ($simulation, $output, %options)

Represent the state of bits in the simulation results as an unsigned binary integer.

     Parameter    Description
  1  $simulation  Chip
  2  $output      Name of gates on bus
  3  %options     Options

B<Example:>


  if (1)
   {my $W = 8;
    my $i = newChip(name=>"not");
       $i->inputBits('i', $W);
       $i->notBits   (qw(n i));
       $i->outputBits(qw(o n));

    my $o = newChip(name=>"outer");
       $o->inputBits ('a', $W);
       $o->outputBits(qw(A a));
       $o->inputBits ('b', $W);
       $o->outputBits(qw(B b));

    my %i = connectBits($i, 'i', $o, 'A');
    my %o = connectBits($i, 'o', $o, 'b');
    $o->install($i, {%i}, {%o});

    my %d = setBits($o, 'a', 0b10110);
    my $s = $o->simulate({%d}, svg=>q(svg/not));
    is_deeply($s->bInt('B'), 0b11101001);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/not.svg">


=head2 Silicon::Chip::Simulation::wInt ($simulation, $output, %options)

Represent the state of words in the simulation results as an array of unsigned binary integer.

     Parameter    Description
  1  $simulation  Chip
  2  $output      Name of gates on bus
  3  %options     Options

B<Example:>


  if (1)
   {my @b = ((my $W = 4), (my $B = 3));

    my $c = newChip();
       $c->inputWords ('i',      @b);
       $c->outputWords(qw(o i));

    my %d = setWords($c, 'i', 0b000, 0b001, 0b010, 0b011);
    my $s = $c->simulate({%d}, svg=>q(svg/words$W));

    is_deeply([$s->wInt('o')], [0..3]);
    is_deeply([$s->wordXToInteger('o')], [10, 12, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/words$W.svg">


=head2 Silicon::Chip::Simulation::wordXToInteger   ($simulation, $output, %options)

Represent the state of words in the simulation results as an array of unsigned binary integer.

     Parameter    Description
  1  $simulation  Chip
  2  $output      Name of gates on bus
  3  %options     Options

B<Example:>


  if (1)
   {my @b = ((my $W = 4), (my $B = 3));

    my $c = newChip();
       $c->inputWords ('i',      @b);
       $c->outputWords(qw(o i));

    my %d = setWords($c, 'i', 0b000, 0b001, 0b010, 0b011);
    my $s = $c->simulate({%d}, svg=>q(svg/words$W));

    is_deeply([$s->wInt('o')], [0..3]);
    is_deeply([$s->wordXToInteger('o')], [10, 12, 0]);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/words$W.svg">


=head2 simulate($chip, $inputs, %options)

Simulate the action of the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> for a given set of inputs until the output value of each L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> stabilizes.

     Parameter  Description
  1  $chip      Chip
  2  $inputs    Hash of input names to values
  3  %options   Options

B<Example:>


  if (1)                                                                           # 4 bit equal
   {my $B = 4;                                                                    # Number of bits

    my $c = Silicon::Chip::newChip(title=><<"END");                               # Create chip
  $B Bit Equals
  END
    $c->input ("a$_")                 for 1..$B;                                  # First number
    $c->input ("b$_")                 for 1..$B;                                  # Second number

    $c->nxor  ("e$_", "a$_", "b$_")   for 1..$B;                                  # Test each bit for equality
    $c->and   ("and", {map{$_=>"e$_"}     1..$B});                                # And tests together to get total equality

    $c->output("out", "and");                                                     # Output gate


    my $s = $c->simulate({a1=>1, a2=>0, a3=>1, a4=>0,                             # Input gate values  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                          b1=>1, b2=>0, b3=>1, b4=>0},
                          svg=>q(svg/Equals));                                    # Svg drawing of layout

    is_deeply($s->steps,        3);                                               # Three steps
    is_deeply($s->value("out"), 1);                                               # Out is 1 for equals
    is_deeply(substr(md5_hex(readFile $s->svg), 0, 4), '9ff8');


    my $t = $c->simulate({a1=>1, a2=>1, a3=>1, a4=>0,  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                          b1=>1, b2=>0, b3=>1, b4=>0});
    is_deeply($t->value("out"), 0);                                               # Out is 0 for not equals
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Equals.svg">



=head1 Hash Definitions




=head2 Silicon::Chip Definition


Simulation results




=head3 Output fields


=head4 busEnd

Bus Line end

=head4 busLine

Bus line

=head4 busStart

Bus line start

=head4 changed

Last time this gate changed

=head4 chip

Chip being simulated

=head4 fibers

Fibers after collapse

=head4 gate

Gate

=head4 gateSeq

Gate sequence number - this allows us to display the gates in the order they were defined ti simplify the understanding of drawn layouts

=head4 gates

Gates in chip

=head4 height

Height of drawing

=head4 inPlay

Squares in play for collapsing

=head4 inputs

Outputs of outer chip to inputs of inner chip

=head4 installs

Chips installed within the chip

=head4 io

Whether an input/output gate or not

=head4 name

Name of chip

=head4 output

Output name which is used as the name of the gate as well

=head4 outputs

Outputs of inner chip to inputs of outer chip

=head4 positionsArray

Position array

=head4 positionsHash

Position hash

=head4 seq

Sequence number for this gate

=head4 sizeBits

Sizes of buses

=head4 sizeWords

Sizes of buses

=head4 steps

Number of steps to reach stability

=head4 svg

Name of file containing svg drawing if requested

=head4 thickness

Width of the thickest fiber bundle

=head4 title

Title if known

=head4 type

Gate type

=head4 values

Values of every output at point of stability

=head4 width

Width of drawing

=head4 x

X position of gate

=head4 y

Y position of gate



=head1 Private Methods

=head2 AUTOLOAD($chip, @options)

Autoload by L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> name to provide a more readable way to specify the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  $chip      Chip
  2  @options   Options

=head2 Silicon::Chip::Layout::draw ($layout, %options)

Draw a mask for the gates.

     Parameter  Description
  1  $layout    Layout
  2  %options   Options


=head1 Index


1 L<andBits|/andBits> - B<and> a bus made of bits.

2 L<andWords|/andWords> - B<and> a bus made of words to produce a single word.

3 L<andWordsX|/andWordsX> - B<and> a bus made of words by and-ing the corresponding bits in each word to make a single word.

4 L<AUTOLOAD|/AUTOLOAD> - Autoload by L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> name to provide a more readable way to specify the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

5 L<bits|/bits> - Create a bus set to a specified number.

6 L<chooseFromTwoWords|/chooseFromTwoWords> - Choose one of two words based on a bit.

7 L<chooseWordUnderMask|/chooseWordUnderMask> - Choose one of a specified number of words B<w>, each of a specified width, using a point mask B<m> placing the selected word in B<o>.

8 L<compareEq|/compareEq> - Compare two unsigned binary integers of a specified width returning B<1> if they are equal else B<0>.

9 L<compareGt|/compareGt> - Compare two unsigned binary integers and return B<1> if the first integer is more than B<b> else B<0>.

10 L<compareLt|/compareLt> - Compare two unsigned binary integers B<a>, B<b> of a specified width.

11 L<connectBits|/connectBits> - Create a connection list connecting a set of output bits on the one chip to a set of input bits on another chip.

12 L<connectInput|/connectInput> - Connect a previously defined input gate to the output of another gate on the same chip.

13 L<connectInputBits|/connectInputBits> - Connect a previously defined input bit bus to another bit bus provided the two buses have the same size.

14 L<connectInputWords|/connectInputWords> - Connect a previously defined input word bus to another word bus provided the two buses have the same size.

15 L<connectWords|/connectWords> - Create a connection list connecting a set of words on the outer chip to a set of words on the inner chip.

16 L<enableWord|/enableWord> - Output a word or zeros depending on a choice bit.

17 L<findWord|/findWord> - Choose one of a specified number of words B<w>, each of a specified width, using a key B<k>.

18 L<gate|/gate> - A L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> chosen from B<and|continue|gt|input|lt|nand|nor|not|nxor|one|or|output|xor|zero>.

19 L<inputBits|/inputBits> - Create an B<input> bus made of bits.

20 L<inputWords|/inputWords> - Create an B<input> bus made of words.

21 L<install|/install> - Install a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> within another L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> specifying the connections between the inner and outer L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

22 L<integerToMonotoneMask|/integerToMonotoneMask> - Convert an integer B<i> of specified width to a monotone mask B<m>.

23 L<integerToPointMask|/integerToPointMask> - Convert an integer B<i> of specified width to a point mask B<m>.

24 L<monotoneMaskToInteger|/monotoneMaskToInteger> - Convert a monotone mask B<i> to an output number B<r> representing the location in the mask of the bit set to B<1>.

25 L<monotoneMaskToPointMask|/monotoneMaskToPointMask> - Convert a monotone mask B<i> to a point mask B<o> representing the location in the mask of the first bit set to B<1>.

26 L<n|/n> - Gate name from single index.

27 L<nandBits|/nandBits> - B<nand> a bus made of bits.

28 L<newChip|/newChip> - Create a new L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

29 L<nn|/nn> - Gate name from double index.

30 L<norBits|/norBits> - B<nor> a bus made of bits.

31 L<notBits|/notBits> - Create a B<not> bus made of bits.

32 L<notWords|/notWords> - Create a B<not> bus made of words.

33 L<orBits|/orBits> - B<or> a bus made of bits.

34 L<orWords|/orWords> - B<or> a bus made of words to produce a single word.

35 L<orWordsX|/orWordsX> - B<or> a bus made of words by or-ing the corresponding bits in each word to make a single word.

36 L<outputBits|/outputBits> - Create an B<output> bus made of bits.

37 L<outputWords|/outputWords> - Create an B<output> bus made of words.

38 L<pointMaskToInteger|/pointMaskToInteger> - Convert a mask B<i> known to have at most a single bit on - also known as a B<point mask> - to an output number B<a> representing the location in the mask of the bit set to B<1>.

39 L<print|/print> - Dump the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> present on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

40 L<printSvg|/printSvg> - Mask the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> onto a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> as an L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> drawing to help visualize the structure of the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> using a condensed input bus.

41 L<setBits|/setBits> - Set an array of input gates to a number prior to running a simulation.

42 L<setSizeBits|/setSizeBits> - Set the size of a bits bus.

43 L<setSizeWords|/setSizeWords> - Set the size of a bits bus.

44 L<setWords|/setWords> - Set an array of arrays of gates to an array of numbers prior to running a simulation.

45 L<Silicon::Chip::Layout::draw|/Silicon::Chip::Layout::draw> - Draw a mask for the gates.

46 L<Silicon::Chip::Simulation::bInt|/Silicon::Chip::Simulation::bInt> - Represent the state of bits in the simulation results as an unsigned binary integer.

47 L<Silicon::Chip::Simulation::print|/Silicon::Chip::Simulation::print> - Print simulation results as text.

48 L<Silicon::Chip::Simulation::printSvg|/Silicon::Chip::Simulation::printSvg> - Print simulation results as svg.

49 L<Silicon::Chip::Simulation::value|/Silicon::Chip::Simulation::value> - Get the value of a gate as seen in a simulation.

50 L<Silicon::Chip::Simulation::wInt|/Silicon::Chip::Simulation::wInt> - Represent the state of words in the simulation results as an array of unsigned binary integer.

51 L<Silicon::Chip::Simulation::wordXToInteger|/Silicon::Chip::Simulation::wordXToInteger> - Represent the state of words in the simulation results as an array of unsigned binary integer.

52 L<simulate|/simulate> - Simulate the action of the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> for a given set of inputs until the output value of each L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> stabilizes.

53 L<words|/words> - Create a word bus set to specified numbers.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Silicon::Chip

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



#D0 Tests                                                                       # Tests and examples
goto finish if caller;                                                          # Skip testing if we are being called as a module
clearFolder(q(svg), 99);                                                        # Clear the output svg folder
eval "use Test::More tests=>545";
eval "Test::More->builder->output('/dev/null')" if -e q(/home/phil/);
eval {goto latest};

#svg https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/

if (1)                                                                          #Tn #Tnn
 {is_deeply( n(a,1),   "a_1");
  is_deeply(nn(a,1,2), "a_1_2");
 }

if (1)                                                                          # Unused output
 {my $c = Silicon::Chip::newChip;
  $c->input( "i1");
  eval {$c->simulate({i1=>1})};
  ok($@ =~ m(Output from gate 'i1' is never used)i);
 }

if (1)                                                                          # Gate already specified
 {my $c = Silicon::Chip::newChip;
        $c->input("i1");
  eval {$c->input("i1")};
  ok($@ =~ m(Gate: 'i1' has already been specified));
 }

#latest:;
if (1)                                                                          # Check all inputs have values
 {my $c = Silicon::Chip::newChip;
  $c->input ("i1");
  $c->input ("i2");
  $c->and   ("and", [qw(i1 i2)]);
  $c->output("o",   q(and));
  eval {$c->simulate({i1=>1, i22=>1})};
  ok($@ =~ m(No input value for input gate: i2)i);
 }

#latest:;
if (1)                                                                          # Check each input to each gate receives output from another gate
 {my $c = Silicon::Chip::newChip;
  $c->input("i1");
  $c->input("i2");
  $c->and  ("and1", [qw(i1 i2)]);
  $c->output( "o", q(an1));
  eval {$c->simulate({i1=>1, i2=>1})};
  ok($@ =~ m(No output driving input 'an1' on 'output' gate 'o')i);
 }

#latest:;
if (1)                                                                          #Tzero
 {my $c = Silicon::Chip::newChip;
  $c->zero  ("z");
  $c->output("o", "z");
  my $s = $c->simulate({}, svg=>q(svg/zero));
  is_deeply($s->steps,      2);
  is_deeply($s->value("o"), 0);
 }

#latest:;
if (1)                                                                          #Tone
 {my $c = Silicon::Chip::newChip;
  $c->one ("o");
  $c->output("O", "o");
  my $s = $c->simulate({}, svg=>q(svg/one));
  is_deeply($s->steps      , 2);
  is_deeply($s->value("O"), 1);
 }

#latest:;
if (1)                                                                          #TnewChip
 {my $c = Silicon::Chip::newChip;
  $c->one ("one");
  $c->zero("zero");
  $c->or  ("or",   [qw(one zero)]);
  $c->and ("and",  [qw(one zero)]);
  $c->output("o1", "or");
  $c->output("o2", "and");
  my $s = $c->simulate({}, svg=>q(svg/oneZero));
  is_deeply($s->steps       , 3);
  is_deeply($s->value("o1"), 1);
  is_deeply($s->value("o2"), 0);
 }

#latest:;
if (1)                                                                          #Tbits
 {my $N = 4;
  for my $i(0..2**$N-1)
   {my $c = Silicon::Chip::newChip;
    $c->bits      ("c", $N, $i);
    $c->outputBits("o", "c");
    my $s = $c->simulate({}, $i == 3 ? (svg=>q(svg/bits)) : ());
    is_deeply($s->steps, 2);
    is_deeply($s->bInt("o"), $i);
   }
 }

#latest:;
if (1)                                                                          #TnewChip # Single AND gate
 {my $c = Silicon::Chip::newChip;
  $c->input ("i1");
  $c->input ("i2");
  $c->and   ("and1", [qw(i1 i2)]);
  $c->output("o", "and1");
  my $s = $c->simulate({i1=>1, i2=>1}, svg=>q(svg/and));
  ok($s->steps         == 2);
  ok($s->value("and1") == 1);
 }

#latest:;
if (1)                                                                          #TSilicon::Chip::Simulation::print #Tprint #TSilicon::Chip::Simulation::printSvg #TprintSvg
 {my $c = Silicon::Chip::newChip(title=>"And gate");
  $c->input ("i1");
  $c->input ("i2");
  $c->and   ("and1", [qw(i1 i2)]);
  $c->output("o", "and1");
  my $s = $c->simulate({i1=>1, i2=>1});

  is_deeply($c->print, <<END);
i1                              :     input                           i1
i2                              :     input                           i2
and1                            :     and                             i1 i2
o                               :     output                          and1
END

  is_deeply($s->print, <<END);
i1                              :   1 input                           i1
i2                              :   1 input                           i2
and1                            :   1 and                             i1 i2
o                               :   1 output                          and1
END

  ok($s->printSvg ne $c->printSvg);
 }

#latest:;
if (1)                                                                          # Three AND gates in a tree
 {my $c = Silicon::Chip::newChip;
  $c->input( "i11");
  $c->input( "i12");
  $c->and(    "and1", [qw(i11 i12)]);
  $c->input( "i21");
  $c->input( "i22");
  $c->and(    "and2", [qw(i21   i22)]);
  $c->and(    "and",  [qw(and1 and2)]);
  $c->output( "o", "and");
  my $s = $c->simulate({i11=>1, i12=>1, i21=>1, i22=>1}, svg=>q(svg/and3));
  ok($s->steps        == 3);
  ok($s->value("and") == 1);
     $s = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>1});
  ok($s->steps        == 3);
  ok($s->value("and") == 0);
 }

#latest:;
if (1)                                                                          #Tgate # Two AND gates driving an OR gate
 {my $c = newChip;
  $c->input ("i11");
  $c->input ("i12");
  $c->and   ("and1", [qw(i11   i12)]);
  $c->input ("i21");
  $c->input ("i22");
  $c->and   ("and2", [qw(i21   i22 )]);
  $c->or    ("or",   [qw(and1  and2)]);
  $c->output( "o", "or");
  my $s = $c->simulate({i11=>1, i12=>1, i21=>1, i22=>1}, svg=>q(svg/andOr));
  ok($s->steps        == 3);
  ok($s->value("or")  == 1);
     $s  = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>1});
  ok($s->steps        == 3);
  ok($s->value("or")  == 1);
     $s  = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>0});
  ok($s->steps        == 3);
  ok($s->value("o")   == 0);
 }

#latest:;
if (1)                                                                          #Tsimulate # 4 bit equal #TnewChip
 {my $B = 4;                                                                    # Number of bits

  my $c = Silicon::Chip::newChip(title=><<"END");                               # Create chip
$B Bit Equals
END
  $c->input ("a$_")                 for 1..$B;                                  # First number
  $c->input ("b$_")                 for 1..$B;                                  # Second number

  $c->nxor  ("e$_", "a$_", "b$_")   for 1..$B;                                  # Test each bit for equality
  $c->and   ("and", {map{$_=>"e$_"}     1..$B});                                # And tests together to get total equality

  $c->output("out", "and");                                                     # Output gate

  my $s = $c->simulate({a1=>1, a2=>0, a3=>1, a4=>0,                             # Input gate values
                        b1=>1, b2=>0, b3=>1, b4=>0},
                        svg=>q(svg/Equals));                                    # Svg drawing of layout

  is_deeply($s->steps,        3);                                               # Three steps
  is_deeply($s->value("out"), 1);                                               # Out is 1 for equals
  is_deeply(substr(md5_hex(readFile $s->svg), 0, 4), '9ff8');

  my $t = $c->simulate({a1=>1, a2=>1, a3=>1, a4=>0,
                        b1=>1, b2=>0, b3=>1, b4=>0});
  is_deeply($t->value("out"), 0);                                               # Out is 0 for not equals
 }

#latest:;
if (1)                                                                          #TsetBits # Compare two 4 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
 {my $B = 4;                                                                    # Number of bits
  my $c = Silicon::Chip::newChip(title=><<"END");
$B Bit Compare
END
  $c->inputBits("a", $B);                                                       # First number
  $c->inputBits("b", $B);                                                       # Second number
  $c->nxor (n(e,$_), n(a,$_), n(b,$_)) for 1..$B-1;                             # Test each bit for equality
  $c->gt   (n(g,$_), n(a,$_), n(b,$_)) for 1..$B;                               # Test each bit pair for greater

  for my $b(2..$B)
   {$c->and(n(c,$b), [(map {n(e, $_)} 1..$b-1), n(g,$b)]);                      # Greater on one bit and all preceding bits are equal
   }
  $c->or    ("or",  [n(g,1), (map {n(c, $_)} 2..$B)]);                          # Any set bit indicates that 'a' is more than 'b'
  $c->output("out", "or");                                                      # Output 1 if a > b else 0

  my %a = $c->setBits('a', 0);                                                  # Number a
  my %b = $c->setBits('b', 0);                                                  # Number b

  my $s = $c->simulate({%a, %b, n(a,2)=>1, n(b,2)=>1}, svg=>q(svg/equals));     # Two equal numbers
  is_deeply($s->value("out"), 0);

  my $t = $c->simulate({%a, %b, n(a,2)=>1});
  is_deeply($t->value("out"), 1);
 }

#latest:;
if (1)                                                                          #TcompareEq # Compare unsigned integers
 {my $B = 2;

  my $c = Silicon::Chip::newChip(title=><<"END");
$B Bit Compare Equal
END
  $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers
  $c->compareEq(qw(o a b));                                                     # Compare equals
  $c->output   (qw(out o));                                                     # Comparison result

  for   my $i(0..2**$B-1)                                                       # Each possible number
   {for my $j(0..2**$B-1)                                                       # Each possible number
     {my %a = $c->setBits('a', $i);                                             # Number a
      my %b = $c->setBits('b', $j);                                             # Number b

      my $s = $c->simulate({%a, %b}, $i==1&&$j==1?(svg=>q(svg/CompareEq)):());  # Svg drawing of layout

      is_deeply($s->value("out"), $i == $j ? 1 : 0);                            # Equal
      is_deeply($s->steps, 3);                                                  # Number of steps to stability
     }
   }
 }

#latest:;
if (1)                                                                          #TcompareGt # Compare 8 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
 {my $B = 3;
  my $c = Silicon::Chip::newChip(title=><<END);
$B Bit Compare more than
END
  $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers
  $c->compareGt(qw(o a b));                                                     # Compare more than
  $c->output   (qw(out o));                                                     # Comparison result

  for   my $i(0..2**$B-1)                                                       # Each possible number
   {for my $j(0..2**$B-1)                                                       # Each possible number
     {#$i = 2; $j = 1;
      my %a = $c->setBits('a', $i);                                             # Number a
      my %b = $c->setBits('b', $j);                                             # Number b

      my $s = $c->simulate({%a, %b}, $i==2&&$j==1?(svg=>q(svg/CompareGt)):());  # Svg drawing of layout
      is_deeply($s->value("out"), $i > $j ? 1 : 0);                             # More than
      is_deeply($s->steps, 4);                                                  # Number of steps to stability
     }
   }
 }

#latest:;
if (1)                                                                          #TcompareLt # Compare 8 bit unsigned integers 'a' < 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
 {my $B = 3;
  my $c = Silicon::Chip::newChip(title=><<"END");
$B Bit Compare Less Than
END
  $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers
  $c->compareLt(qw(o a b));                                                     # Compare less than
  $c->output   (qw(out o));                                                     # Comparison result

  for   my $i(0..2**$B-1)                                                       # Each possible number
   {for my $j(0..2**$B-1)                                                       # Each possible number
     {my %a = $c->setBits('a', $i);                                             # Number a
      my %b = $c->setBits('b', $j);                                             # Number b

      my $s = $c->simulate({%a, %b}, $i==1&&$j==2?(svg=>q(svg/CompareLt)):());  # Svg drawing of layout
      is_deeply($s->value("out"), $i < $j ? 1 : 0);                             # More than
      is_deeply($s->steps, 4);                                                  # Number of steps to stability
     }
   }
 }

#latest:;
if (1)                                                                          # Masked multiplexer: copy B bit word selected by mask from W possible locations
 {my $B = 4; my $W = 4;
  my $c = newChip;
  for my $w(1..$W)                                                              # Input words
   {$c->input("s$w");                                                           # Selection mask
    for my $b(1..$B)                                                            # Bits of input word
     {$c->input("i$w$b");
      $c->and(   "s$w$b", ["i$w$b", "s$w"]);
     }
   }
  for my $b(1..$B)                                                              # Or selected bits together to make output
   {$c->or    ("c$b", [map {"s$b$_"} 1..$W]);                                   # Combine the selected bits to make a word
    $c->output("o$b", "c$b");                                                   # Output the word selected
   }
  my $s = $c->simulate(
   {s1 =>0, s2 =>0, s3 =>1, s4 =>0,
    i11=>0, i12=>0, i13=>0, i14=>1,
    i21=>0, i22=>0, i23=>1, i24=>0,
    i31=>0, i32=>1, i33=>0, i34=>0,
    i41=>1, i42=>0, i43=>0, i44=>0}, svg=>q(svg/maskedMultiplexor));

  is_deeply([@{$s->values}{qw(o1 o2 o3 o4)}], [qw(0 0 1 0)]);                   # Number selected by mask
  is_deeply($s->steps, 3);
 }

#latest:;
if (1)                                                                          # Rename a gate
 {my $i = newChip(name=>"inner");
          $i->input ("i");
  my $n = $i->not   ("n",  "i");
          $i->output("io", "n");

  my $ci = cloneGate $i, $n;
  renameGate $i, $ci, "aaa";
  is_deeply($ci->inputs,   { n => "i" });
  is_deeply($ci->output,  "(aaa n)");
  is_deeply($ci->io, 0);
 }

#latest:;
if (1)                                                                          #Tinstall #TconnectBits # Install one chip inside another chip, specifically one chip that performs NOT is installed once to flip a value
 {my $i = newChip(name=>"not");
     $i-> inputBits('i',     1);
     $i->   notBits(qw(n i));
     $i->outputBits(qw(o n));

  my $o = newChip(name=>"outer");
     $o->inputBits('i', 1); $o->outputBits(qw(n i));
     $o->inputBits('I', 1); $o->outputBits(qw(N I));

  my %i = connectBits($i, 'i', $o, 'n');
  my %o = connectBits($i, 'o', $o, 'I');
  $o->install($i, {%i}, {%o});
  my %d = $o->setBits('i', 1);
  my $s = $o->simulate({%d}, svg=>q(svg/notb1));

  is_deeply($s->steps,  2);
  is_deeply($s->values, {"(not 1 n_1)"=>0, "i_1"=>1, "N_1"=>0 });
 }

#latest:;
if (1)                                                                          #TconnectWords # Install one chip inside another chip, specifically one chip that performs NOT is installed three times sequentially to flip a value
 {my $i = newChip(name=>"not");
     $i-> inputWords('i', 1, 1);
     $i->   notWords(qw(n i));
     $i->outputWords(qw(o n));

  my $o = newChip(name=>"outer");
     $o->inputWords('i', 1, 1); $o->output(nn('n', 1, 1), nn('i', 1, 1));
     $o->inputWords('I', 1, 1); $o->output(nn('N', 1, 1), nn('I', 1, 1));

  my %i = connectWords($i, 'i', $o, 'n', 1, 1);
  my %o = connectWords($i, 'o', $o, 'I', 1, 1);
  $o->install($i, {%i}, {%o});
  my %d = $o->setWords('i', 1);
  my $s = $o->simulate({%d}, svg=>q(svg/notw1));

  is_deeply($s->steps,  2);
  is_deeply($s->values, { "(not 1 n_1_1)" => 0, "i_1_1" => 1, "N_1_1" => 0 });
 }

#latest:;
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

  my $s = $o->simulate({Oi1=>1}, svg=>q(svg/not3));
  is_deeply($s->value("Oo"), 0);
  is_deeply($s->steps,       4);

  my $t = $o->simulate({Oi1=>0});
  is_deeply($t->value("Oo"), 1);
  is_deeply($t->steps,       4);
 }

#latest:;
if (1)                                                                          #TpointMaskToInteger
 {my $B = 4;
  my $N = 2**$B-1;

  my $c = Silicon::Chip::newChip(title=><<"END");
$B bits point mask to integer
END
  $c->inputBits         (qw(    i), $N);                                        # Mask with no more than one bit on
  $c->pointMaskToInteger(qw(o   i));                                            # Convert
  $c->outputBits        (qw(out o));                                            # Mask with no more than one bit on

  for my $i(0..$N)                                                              # Each position of mask
   {my %i = setBits($c, 'i', $i ? 1<<($i-1) : 0);                               # Point in each position with zero representing no position
    my $s = $c->simulate(\%i, $i == 5 ? (svg=>q(svg/point)) : ());
    is_deeply($s->steps, 2);
    my %o = $s->values->%*;                                                     # Output bits
    my $n = eval join '', '0b', map {$o{n(o,$_)}} reverse 1..$B;                # Output bits as number
    is_deeply($n, $i);
   }
 }

#latest:;
if (1)                                                                          #TintegerToPointMask
 {my $B = 3;
  my $N = 2**$B-1;

  my $c = Silicon::Chip::newChip(title=><<"END");
$B bit integer to $N bit monotone mask.
END
     $c->inputBits         (qw(  i), $B);                                       # Input bus
     $c->integerToPointMask(qw(m i));
     $c->outputBits        (qw(o m));
  for my $i(0..$N)                                                              # Each position of mask
   {my %i = setBits($c, 'i', $i);
    my $s = $c->simulate(\%i, $i == 5 ? (svg=>q(svg/integerToPointMask)):());
    is_deeply($s->steps, 3);

    my $r = $s->bInt('o');                                                      # Mask values
    is_deeply($r, $i ? 1<<($i-1) : 0);                                          # Expected mask
   }
 }

#latest:;
if (1)                                                                          #TmonotoneMaskToInteger
 {my $B = 4;
  my $N = 2**$B-1;

  my $c = Silicon::Chip::newChip(title=><<"END");
$N bit monotone mask to $B bit integer
END
     $c->inputBits            ('i',     $N);
     $c->monotoneMaskToInteger(qw(m i));
     $c->outputBits           (qw(o m));

  for my $i(0..$N-1)                                                            # Each monotone mask
   {my %i = setBits($c, 'i', $i > 0 ? 1<<$i-1 : 0);
    my $s = $c->simulate(\%i,
      $i == 5 ? (svg=>q(svg/monotoneMaskToInteger)) : ());

    is_deeply($s->steps, 4);
    is_deeply($s->bInt('m'), $i);
   }
 }

#latest:;
if (1)                                                                          #TintegerToMonotoneMask
 {my $B = 4;
  my $N = 2**$B-1;

  my $c = Silicon::Chip::newChip(title=><<"END");
Convert $B bit integer to $N bit monotone mask
END
     $c->inputBits            ('i', $B);                                        # Input gates
     $c->integerToMonotoneMask(qw(m i));
     $c->outputBits           (qw(o m));                                        # Output gates

  for my $i(0..$N)                                                              # Each position of mask
   {my %i = setBits($c, 'i', $i);                                               # The number to convert
    my $s = $c->simulate(\%i, $i == 2 ? (svg=>q(svg/integerToMontoneMask)):());
    is_deeply($s->steps, 4);
    is_deeply($s->bInt('o'), $i > 0 ? ((1<<$N)-1)>>($i-1)<<($i-1) : 0);         # Expected mask
   }
 }

#latest:;
if (1)                                                                          #TchooseWordUnderMask #TsetBits #TsetWords
 {my $B = 3; my $W = 4;

  my $c = Silicon::Chip::newChip(title=><<"END");
Choose one of $W words of $B bits
END
     $c->inputWords         ('w',       $W, $B);
     $c->inputBits          ('m',       $W);
     $c->chooseWordUnderMask(qw(W w m));
     $c->outputBits         (qw(o W));

  my %i = setWords($c, 'w', 0b000, 0b001, 0b010, 0b0100);
  my %m = setBits ($c, 'm', 1<<2);                                              # Choose the third word

  my $s = $c->simulate({%i, %m}, svg=>q(svg/choose));

  is_deeply($s->steps, 3);
  is_deeply($s->bInt('o'), 0b010);
 }

#latest:;
if (1)                                                                          #TfindWord
 {my $B = 3; my $W = 2**$B-1;

  my $c = Silicon::Chip::newChip(title=><<END);
Search $W words of $B bits
END
     $c->inputBits ('k',       $B);                                             # Search key
     $c->inputWords('w',       2**$B-1, $B);                                    # Words to search
     $c->findWord  (qw(m k w));                                                 # Find the word
     $c->outputBits(qw(M m));                                                   # Output mask

  my %w = setWords($c, 'w', reverse 1..$W);

  for my $k(0..$W)                                                              # Each possible key
   {my %k = setBits($c, 'k', $k);
    my $s = $c->simulate({%k, %w}, $k == 3 ? (svg=>q(svg/findWord)) : ());
    is_deeply($s->steps, 3);
    is_deeply($s->bInt('M'),$k ? 2**($W-$k) : 0);
   }
 }

#latest:;
if (1)                                                                          #TinputBits #ToutputBits #TnotBits #TSilicon::Chip::Simulation::bInt
 {my $W = 8;
  my $i = newChip(name=>"not");
     $i->inputBits('i', $W);
     $i->notBits   (qw(n i));
     $i->outputBits(qw(o n));

  my $o = newChip(name=>"outer");
     $o->inputBits ('a', $W);
     $o->outputBits(qw(A a));
     $o->inputBits ('b', $W);
     $o->outputBits(qw(B b));

  my %i = connectBits($i, 'i', $o, 'A');
  my %o = connectBits($i, 'o', $o, 'b');
  $o->install($i, {%i}, {%o});

  my %d = setBits($o, 'a', 0b10110);
  my $s = $o->simulate({%d}, svg=>q(svg/not));
  is_deeply($s->bInt('B'), 0b11101001);
 }

#latest:;
if (1)                                                                          #TandBits #TorBits #TnandBits #TnorBits
 {my $W = 8;

  my $c = newChip();
     $c-> inputBits('i', $W);
     $c->   andBits(qw(and  i));
     $c->    orBits(qw(or   i));
     $c->  nandBits(qw(nand i));
     $c->   norBits(qw(nor  i));
     $c->output    (qw(And  and));
     $c->output    (qw(Or   or));
     $c->output    (qw(nAnd nand));
     $c->output    (qw(nOr  nor));

  my %d = setBits($c, 'i', 0b10110);
  my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));

  is_deeply($s->value("And"),  0);
  is_deeply($s->value("Or"),   1);
  is_deeply($s->value("nAnd"), 1);
  is_deeply($s->value("nOr"),  0);
 }

#latest:;
if (1)                                                                          #TandWords #TandWordsX #TorWords #TorWordsX #ToutputBits #TnotWords
 {my @B = ((my $W = 4), (my $B = 2));

  my $c = newChip();
     $c->inputWords ('i', @B);
     $c->andWords   (qw(and  i));
     $c->andWordsX  (qw(andX i));
     $c-> orWords   (qw( or  i));
     $c-> orWordsX  (qw( orX i));
     $c->notWords   (qw(n    i));
     $c->outputBits (qw(And  and));
     $c->outputBits (qw(AndX andX));
     $c->outputBits (qw(Or   or));
     $c->outputBits (qw(OrX  orX));
     $c->outputWords(qw(N    n));
  my %d = setWords($c, 'i', 0b00, 0b01, 0b10, 0b11);
  my $s = $c->simulate({%d}, svg=>q(svg/andOrWords));

  is_deeply($s->bInt('And'),  0b1000);
  is_deeply($s->bInt('AndX'), 0b0000);

  is_deeply($s->bInt('Or'),  0b1110);
  is_deeply($s->bInt('OrX'), 0b11);
  is_deeply([$s->wInt('N')], [3, 2, 1, 0]);
 }

#latest:;
if (1)                                                                          #TandWords #TorWords #TSilicon::Chip::Simulation::wordXToInteger #TSilicon::Chip::Simulation::wInt  #TinputWords #ToutputWords
 {my @b = ((my $W = 4), (my $B = 3));

  my $c = newChip();
     $c->inputWords ('i',      @b);
     $c->outputWords(qw(o i));

  my %d = setWords($c, 'i', 0b000, 0b001, 0b010, 0b011);
  my $s = $c->simulate({%d}, svg=>q(svg/words$W));

  is_deeply([$s->wInt('o')], [0..3]);
  is_deeply([$s->wordXToInteger('o')], [10, 12, 0]);
 }

#latest:;
if (1)
 {my $B = 4;

  my $c = newChip();
     $c->inputBits('i', 4);
     $c->not   (n('n',  1), n('i', 2));  $c->output(n('o',  1), n('n', 1));
     $c->not   (n('n',  2), n('i', 3));  $c->output(n('o',  2), n('n', 2));
     $c->not   (n('n',  3), n('i', 4));  $c->output(n('o',  3), n('n', 3));
     $c->not   (n('n',  4), n('i', 1));  $c->output(n('o',  4), n('n', 4));

  my %a = setBits($c, 'i', 0b0011);

  my $s = $c->simulate({%a}, svg=>q(svg/collapseLeftSimple));
  is_deeply($s->steps, 2);
 }

#latest:;
if (1)                                                                          #TchooseFromTwoWords
 {my $B = 4;

  my $c = newChip();
     $c->inputBits('a', $B);                                                    # First word
     $c->inputBits('b', $B);                                                    # Second word
     $c->input    ('c');                                                        # Chooser
     $c->chooseFromTwoWords(qw(o a b c));                                       # Generate gates
     $c->outputBits('out', 'o');                                                # Result

  my %a = setBits($c, 'a', 0b0011);
  my %b = setBits($c, 'b', 0b1100);

  my $s = $c->simulate({%a, %b, c=>1}, svg=>q(svg/chooseFromTwoWords));
  is_deeply($s->steps,               4);
  is_deeply($s->bInt('out'), 0b1100);

  my $t = $c->simulate({%a, %b, c=>0});
  is_deeply($t->steps,               4);
  is_deeply($t->bInt('out'), 0b0011);
 }

#latest:;
if (1)                                                                          #TenableWord
 {my $B = 4;

  my $c = newChip();
     $c->inputBits ('a', $B);                                                   # Word
     $c->input     ('c');                                                       # Choice bit
     $c->enableWord(qw(o a c));                                                 # Generate gates
     $c->outputBits(qw(out o));                                                 # Result

  my %a = setBits($c, 'a', 3);

  my $s = $c->simulate({%a, c=>1}, svg=>q(svg/enableWord));
  is_deeply($s->steps,       2);
  is_deeply($s->bInt('out'), 3);

  my $t = $c->simulate({%a, c=>0});
  is_deeply($t->steps,       2);
  is_deeply($t->bInt('out'), 0);
 }

#latest:;
if (1)                                                                          #TmonotoneMaskToPointMask
 {my $B = 4;

  my $c = newChip();
     $c->inputBits('m', $B);                                                    # Monotone mask
     $c->monotoneMaskToPointMask(qw(o m));                                      # Generate gates
     $c->outputBits('out', 'o');                                                # Point mask

  for my $i(0..$B)
   {my %m = $c->setBits('m', eval '0b'.(1 x $i).('0' x ($B-$i)));
    my $s = $c->simulate({%m}, $i == 2 ? (svg=>q(svg/monotoneMaskToPointMask)) : ());
    is_deeply($s->steps, 2);
    is_deeply($s->bInt('out'), $i ? (1<<($B-1)) / (1<<($i-1)) : 0);
   }
 }

#latest:;
if (1)                                                                          # Internal input gate  #TconnectInput #TSilicon::Chip::Simulation::value
 {my $c = newChip();
     $c->input ('i');                                                           # Input
     $c->input ('j');                                                           # Internal input which we will connect to later
     $c->output(qw(o j));                                                       # Output

     $c->connectInput(qw(j i));

  my $s = $c->simulate({i=>1}, svg=>q(svg/connectInput));
  is_deeply($s->steps, 1);
  is_deeply($s->value("j"), undef);
  is_deeply($s->value("o"), 1);
 }

#latest:;
if (1)                                                                          #Twords # Internal input gate  #TconnectInput #TSilicon::Chip::Simulation::value
 {my @n = qw(3 2 1 2 3);
  my $c = newChip();
     $c->words('i', 2, @n);                                                     # Input
     $c->outputWords(qw(o i));                                                  # Output
  my $s = $c->simulate({}, svg=>q(svg/words));
  is_deeply($s->steps, 2);
  is_deeply([$s->wInt("i")], [@n]);
 }

#latest:;
if (1)                                                                          #TsetSizeBits #TsetSizeWords
 {my $c = newChip();
  $c->setSizeBits ('i', 2);
  $c->setSizeWords('j', 3, 2);
  is_deeply($c->sizeBits,  {i => 2, j_1 => 2, j_2 => 2, j_3 => 2});
  is_deeply($c->sizeWords, {j => [3, 2]});
 }

#latest:;
if (1)                                                                          #TconnectInputBits
 {my $N = 5; my $B = 5;
   my $c = newChip();
  $c->bits      ('a', $B, $N);
  $c->inputBits ('i', $N);
  $c->outputBits(qw(o i));
  $c->connectInputBits(qw(i a));
  my $s = $c->simulate({}, svg=>q(svg/connectInputBits));
  is_deeply($s->steps, 2);
  is_deeply($s->bInt("o"), $N);
 }

#latest:;
if (1)                                                                          #TconnectInputWords
 {my $W = 6; my $B = 5;
  my $c = newChip();
  $c->words      ('a',     $B, 1..$W);
  $c->inputWords ('i', $W, $B);
  $c->outputWords(qw(o i));
  $c->connectInputWords(qw(i a));
  my $s = $c->simulate({}, svg=>q(svg/connectInputWords));
  is_deeply($s->steps, 2);
  is_deeply([$s->wInt("o")], [1..$W]);
 }

#latest:;
if (1)                                                                          #TcanBothFitOnSameLine
 {is_deeply([firstLastOne "10"],    [1,1]);
  is_deeply([firstLastOne "01010"], [2,4]);
 }

#latest:;
if (1)                                                                          #TcanBothFitOnSameLine
 {is_deeply([layoutInputBus qw(1000 1100 0010 0001)],                 [1,2,1,1]);
  is_deeply([layoutInputBus qw(1100 1100 0011 0011)],                 [1,2,1,2]);
  is_deeply([layoutInputBus qw(11000 10100 01000 00011)],             [1,2,3,1]);
  is_deeply([layoutInputBus qw(11000 10100 01000 00011 00010)],       [1, 2, 3, 1, 2]);
  is_deeply([layoutInputBus qw(11000 10100 01000 00011 00010 00010)], [1, 2, 3, 1, 2, 3]);
 }

#latest:;
if (1)                                                                          # Collapse left
 {my $c = Silicon::Chip::newChip;
  $c->input ('a');
  $c->input (             n('ia', $_)) for 1..8;
  $c->and   ('aa',  [map {n('ia', $_)}     1..8]);
  $c->output('oa', 'aa');
  $c->not   ('n1', 'a'); $c->output('o1', 'n1');
  $c->input (             n('ib', $_)) for 1..8;
  $c->and   ('ab',  [map {n('ib', $_)}     1..8]);
  $c->output('ob', 'ab');
  $c->not   ('n2', 'a'); $c->output('o2', 'n2');
  my %a = map {(n('ia', $_)=>1)} 1..8;
  my %b = map {(n('ib', $_)=>1)} 1..8;
  my $s = $c->simulate({%a, %b, a=>0}, svg=>q(svg/collapseLeft));
  is_deeply(substr(md5_hex(readFile $s->svg), 0, 4), q(850e));
 }

done_testing();
finish: 1;
