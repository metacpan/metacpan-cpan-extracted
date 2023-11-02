#!/usr/bin/perl -I/home/phil/perl/cpan/SvgSimple/lib/
#-------------------------------------------------------------------------------
# Design a silicon chip by combining gates and sub chips.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.34;
package Silicon::Chip;
our $VERSION = 20231031;                                                        # Version
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
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

my $possibleTypes = q(and|continue|gt|input|lt|nand|nor|not|nxor|or|output|xor);# Possible gate types
sub xx {confess "XXXX"}
#D1 Construct                                                                   # Construct a L<silicon> L<chip> using standard L<lgs>.

sub newChip(%)                                                                  # Create a new L<chip>.
 {my (%options) = @_;                                                           # Options
  genHash(__PACKAGE__,                                                          # Chip description
    name    => $options{name} // $options{title}  // "Unnamed chip: ".timeStamp,# Name of chip
    gates   => $options{gates} // {},                                           # Gates in chip
    installs=> $options{installs} // [],                                        # Chips installed within the chip
    title   => $options{title},                                                 # Title if known
    gateSeq => 0,                                                               # Gate sequence number - this allows us to display the gates in the order they were defined ti simplify the understanding of drawn layouts
   );
 }

my sub newGate($$$$)                                                            # Make a L<lg>.
 {my ($chip, $type, $output, $inputs) = @_;                                     # Chip, gate type, output name, input names to output from another gate

  my $g = genHash("Silicon::Chip::Gate",                                        # Gate
   type     => $type,                                                           # Gate type
   output   => $output,                                                         # Output name which is used as the name of the gate as well
   inputs   => $inputs,                                                         # Input names to driving outputs
   io       => gateNotIO,                                                       # Whether an input/output gate or not
   seq      => ++$chip->gateSeq,                                                # Sequence number for this gate
  );
 }

sub gate($$$;$)                                                                 # A L<lg> of some sort to be added to the L<chip>.
 {my ($chip, $type, $output, $inputs) = @_;                                     # Chip, gate type, output name, input names to output from another gate
  my $gates = $chip->gates;                                                     # Gates implementing the chip

  $output =~ m(\A[a-z][a-z0-9_.:]*\Z)i or confess "Invalid gate name: '$output'\n";
  $$gates{$output} and confess "Gate: '$output' has already been specified\n";

  if ($type =~ m(\A(input)\Z)i)                                                 # Input gates input to themselves unless they have been connected to an output gate during sub chip expansion
   {defined($inputs) and confess "No input hash allowed for input gate: '$output'\n";
    $inputs = {$output=>$output};                                               # Convert convenient scalar name to hash for consistency with gates in general
   }
  elsif ($type =~ m(\A(output)\Z)i)                                             # Output has one optional scalar value naming its input if known at this point
   {if (defined($inputs))
     {ref($inputs) and confess "Scalar input name required for output gate: '$output'\n";
      $inputs = {$output=>$inputs};                                             # Convert convenient scalar name to hash for consistency with gates in general
     }
   }
  elsif ($type =~ m(\A(continue|not)\Z)i)                                       # These gates have one input expressed as a name rather than a hash
   {!defined($inputs) and confess "Input name required for gate: '$output'\n";
    $type =~ m(\Anot\Z)i and ref($inputs) =~ m(hash)i and confess "Scalar input name required for: '$output'\n";
    $inputs = {$output=>$inputs};                                               # Convert convenient scalar name to hash for consistency with gates in general
   }
  elsif ($type =~ m(\A(nxor|xor|gt|ngt|lt|nlt)\Z)i)                             # These gates must have exactly two inputs expressed as a hash mapping input pin name to connection to a named gate.  These operations are associative.
   {!defined($inputs) and confess "Input hash required for gate: '$output'\n";
    ref($inputs) =~ m(hash)i or confess "Inputs must be a hash of input names to outputs for gate: '$output' to show the output accepted by each input. Input gates have no inputs, they are supplied instead during simulation\n";
    keys(%$inputs) == 2 or confess "Two inputs required for gate: '$output'\n";
   }
  elsif ($type =~ m(\A(and|nand|nor|or)\Z)i)                                    # These gates must have two or more inputs expressed as a hash mapping input pin name to connection to a named gate.  These operations are associative.
   {!defined($inputs) and confess "Input hash required for gate: '$output'\n";
    ref($inputs) =~ m(hash)i or confess "Inputs must be a hash of input gate names to output gate names for: '$output' to show the output accepted by each input. Input gates have no inputs, they are supplied instead during simulation\n";
    keys(%$inputs) < 2 and confess "Two or more inputs required for gate: '$output'\n";
   }
  else                                                                          # Unknown gate type
   {confess "Unknown gate type: '$type' for gate: '$output', possible types are: '$possibleTypes'\n";
   }

  $chip->gates->{$output} = newGate($chip, $type, $output, $inputs);            # Construct gate, save it and return it
 }

our $AUTOLOAD;                                                                  # The method to be autoloaded appears here

sub AUTOLOAD($@)                                                                #P Autoload by L<lg> name to provide a more readable way to specify the L<lgs> on a L<chip>.
 {my ($chip, @options) = @_;                                                    # Chip, options
  my $type = $AUTOLOAD =~ s(\A.*::) ()r;
  confess "Unknown method: '$type'\n" unless $type =~ m(\A($possibleTypes|DESTROY)\Z);
  &gate($chip, $type, @options) if $type =~ m(\A($possibleTypes)\Z);
 }

my sub cloneGate($$)                                                            # Clone a L<lg> on a L<chip>.
 {my ($chip, $gate) = @_;                                                       # Chip, gate
  my %i = $gate->inputs ? $gate->inputs->%* : ();                               # Copy inputs
  newGate($chip, $gate->type, $gate->output, {%i})
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

sub install($$$$%)                                                              # Install a L<chip> within another L<chip> specifying the connections between the inner and outer L<chip>.  The same L<chip> can be installed multiple times as each L<chip> description is read only.
 {my ($chip, $subChip, $inputs, $outputs, %options) = @_;                       # Outer chip, inner chip, inputs of inner chip to to outputs of outer chip, outputs of inner chip to inputs of outer chip, options
  my $c = genHash("Chip::Install",                                              # Installation of a chip within a chip
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
           $o or confess "No connection specified to inner input gate: '$in' on sub chip: '$n'\n";
        my $O  = $outerGates{$o};
           $O or confess "No outer output gate '$o' to connect to inner input gate: '$in' on sub chip: '$n'\n";
        my $ot = $O->type;
        my $on = $O->output;
           $ot =~ m(\Aoutput\Z)i or confess "Output gate required for connection to: '$in' on sub chip $n, not: '$ot' gate: '$on'\n";
        $copy->inputs = {1 => $o};                                              # Connect inner input gate to outer output gate
        renameGate $chip, $copy, $newGateName;                                  # Add chip name to gate to disambiguate it from any other gates
        $copy->io = gateInternalInput;                                          # Mark this as an internal input gate
       }

      elsif ($copy->type =~ m(\Aoutput\Z)i)                                     # Output gate on inner chip - connect to corresponding input gate on containing chip
       {my $on = $copy->output;                                                 # Name of output gate on outer chip
        my $i  = $s->outputs->{$on};
           $i or confess "No connection specified to inner output gate: '$on' on sub chip: '$n'\n";
        my $I  = $outerGates{$i};
           $I or confess "No outer input gate: '$i' to connect to inner output gate: $on on sub chip: '$n'\n";
        my $it = $I->type;
        my $in = $I->output;
           $it =~ m(\Ainput\Z)i or confess "Input gate required for connection to '$in' on sub chip '$n', not gate '$in' of type '$it'\n";
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
    ##next unless $g->inputs;                                                   # Inputs are driven externally during simulation
    my %i = $g->inputs->%*;                                                     # Inputs for gate
    for my $i(sort keys %i)                                                     # Each input
     {my $o = $i{$i};                                                           # Output driving input
      my $O = $$gates{$o};
      defined($O) or  confess "No output driving input '$o' on gate '$G'\n";    # No driving output

      if ($g->io != gateOuterInput)                                             # The gate must inputs driven by the outputs of other gates
       {$o{$o}++;                                                               # Show that this output has been used
        my $T = $O->type;
        if ($g->type =~ m(\Ainput\Z)i)
         {$O->type =~ m(\Aoutput\Z)i or confess "Input gate: '$G' must connect to an output gate on pin: '$i' not to '$T' gate: '$o'\n";
         }
        elsif (!$g->io)                                                         # Not an io gate so it cannot have an input from an output gate
         {$O->type =~ m(\Aoutput\Z) and confess "Cannot drive a non io gate: '$G' using output gate: '$o'\n";
         }
       }
     }
   }

  for my $G(sort keys %$gates)                                                  # Check all inputs and outputs are being used
   {my $g = $$gates{$G};                                                        # Address gate
    next if $g->type =~ m(\Aoutput\Z)i;
    $o{$G} or confess "Output from gate '$G' is never used\n";
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

    if (!$u)                                                                    # All inputs defined
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
      elsif ($t =~ m(\A(gt|ngt)\Z)i)                                            # Elaborate B<a> greater than B<b> - the input pins are assumed to be sorted by name with the first pin as B<a> and the second as B<b>
       {@i == 2 or confess "$t gate: '$n' must have exactly two inputs\n";
        $r = $i[0] > $i[1] ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Angt\Z)i;
       }
      elsif ($t =~ m(\A(lt|nlt)\Z)i)                                            # Elaborate B<a> less than B<b> - the input pins are assumed to be sorted by name with the first pin as B<a> and the second as B<b>
       {@i == 2 or confess "$t gate: '$n' must have exactly two inputs\n";
        $r = $i[0] < $i[1] ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Anlt\Z)i;
       }
      else                                                                      # Unknown gate type
       {confess "Need implementation for '$t' gates";
       }
      $changes{$G} = $r unless defined($$values{$G}) and $$values{$G} == $r;    # Value computed by this gate
     }
   }
  %changes
 }

##D1 Visualize                                                                  # Visualize the L<chip> in various ways.

my sub orderGates($%)                                                           # Order the L<lgs> on a L<chip> so that input L<lg> are first, the output L<lgs> are last and the non io L<lgs> are in between. All L<lgs> are first ordered alphabetically. The non io L<lgs> are then ordered by the step number at which they last changed during simulation of the L<chip>.
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

my sub dumpGates($%)                                                            # Dump the L<lgs> present on a L<chip>.
 {my ($chip, %options) = @_;                                                    # Chip, gates, options
  my $gates = $chip->gates;                                                     # Gates on chip
  my @s;
  my ($i, $n, $o) = orderGates $chip, %options;                                 # Gates by type
  for my $G(@$i, @$n, @$o)                                                      # Dump each gate one per line
   {my $g = $$gates{$G};
    my %i = $g->inputs ? $g->inputs->%* : ();
    my $p = sprintf "%-12s: %2d %-8s", $g->output, $g->io, $g->type;            # Instruction name and type
    if (my @i = map {$i{$_}} sort keys %i)                                      # Add actual inputs in same line sorted in input pin name
     {$p .= join " ", @i;
     }
    push @s, $p;
   }
  owf fpe($options{dumpGates}, q(txt)), join "\n", @s;                          # Write representation of gates as text to the named file
 }

my sub newGatePosition(%)                                                       # Specify the position of a L<lg> on a drawing of the containing L<chip>.
 {my (%options) = @_;                                                           # Options

  genHash("Silicon::Chip::Gate::Position",                                      # Gate position
    gate  => $options{gate}  // undef,                                          # Gate
    x     => $options{x}     // undef,                                          # X position of gate
    y     => $options{y}     // undef,                                          # Y position of gate
    width => $options{width} // undef,                                          # Width of gate
   )
 }

my sub svgGates($%)                                                             # Dump the L<lgs> on a L<chip> as an L<svg> drawing to help visualize the structure of the L<chip>.
 {my ($chip, %options) = @_;                                                    # Chip, options
  my $gates   = $chip->gates;                                                   # Gates on chip
  my $title   = $chip->title;                                                   # Title of chip
  my $changed = $options{changed};                                              # Step at which gate last changed in simulation
  my $values  = $options{values};                                               # Values of each gate if known
  my $steps   = $options{steps};                                                # Number of steps to equilibrium

  my $fs = 0.2; my $fw = 0.02;                                                  # Font sizes
  my $Fs = 0.4; my $Fw = 0.04;
  my $op0 = q(transparent);

  my $s = Svg::Simple::new(defaults=>{stroke_width=>$fw, font_size=>$fs});      # Draw each gate via Svg

  my %p;                                                                        # Dimensions and drawing positions of gates
  my ($iG, $nG, $oG) = orderGates $chip, %options;                              # Gates by type

  for my $i(keys @$iG)                                                          # Index of each input gate
   {my $G = $$iG[$i];                                                           # Gate name
    my $g = $$gates{$G};                                                        # Gate
    $p{$G} = newGatePosition(gate=>$g, x=>0, y=>$i, width=>1);                  # Position input gate
   }

  my $W = 0;                                                                    # Number of inputs to all the non IO gates
  for my $i(keys @$nG)                                                          # Index of each non IO gate
   {my $G = $$nG[$i];                                                           # Gate name
    my $g = $$gates{$G};                                                        # Gate
    my %i = $g->inputs ? $g->inputs->%* : ();                                   # Inputs to gate
    my $w = keys %i;                                                            # Number of inputs
    $p{$G} = newGatePosition(gate=>$g, x=>$W+1, y=>@$iG+$i, width=>$w);         # Position non io gate
    $W   += $w;                                                                 # Width of area needed for non io gates
   }

  for my $i(keys @$oG)                                                          # Index of each output gate
   {my $G = $$oG[$i];                                                           # Gate name
    my $g = $$gates{$G};                                                        # Gate
    my %i = $g->inputs ? $g->inputs->%* : ();                                   # Inputs to gate
    my ($d) = values %i;                                                        # The one driver for this gate
    my $y = $p{$d}->y;
    $p{$G} = newGatePosition(gate=>$g, x=>1+$W, y=>$y, width=>1);               # Position output gate
   }

  my $pageWidth = $W + 2;                                                       # Width of input, output and non io gates as laid out.

  if (defined($title))                                                          # Title if known
   {$s->text(x=>$pageWidth, y=>0.5, fill=>"darkGreen", text_anchor=>"end",
      stroke_width=>$Fw, font_size=>$Fs,
      cdata=>$title);
   }

  if (defined($steps))                                                          # Number of steps taken if known
   {$s->text(x=>$pageWidth, y=>1.5, fill=>"darkGreen", text_anchor=>"end",
      stroke_width=>$Fw, font_size=>$Fs,
      cdata=>"$steps steps");
   }

  for my $P(sort keys %p)                                                       # Each gate with text describing it
   {my $p = $p{$P};
    my $x = $p->x; my $y = $p->y; my $w = $p->width; my $g = $p->gate;          # Position of gate

    my $color = sub
     {return "red"  if $g->io == gateOuterOutput;
      return "blue" if $g->io == gateOuterInput;
      "green"
     }->();

    if ($g->io)                                                                 # Circle for io pin
     {$s->circle(cx=>$x+1/2, cy=>$y+1/2, r=>1/2,   fill=>$op0, stroke=>$color);
     }
    else                                                                        # Rectangle for non io gate
     {$s->rect(x=>$x, y=>$y, width=>$w, height=>1, fill=>$op0, stroke=>$color);
     }

    if (defined(my $v = $$values{$g->output}))                                  # Value of gate if known
     {$s->text(
       x                 => $g->io != gateOuterOutput ? $x : $x + 1,
       y                 => $y,
       fill              =>"black",
       stroke_width      =>$Fw, font_size=>$Fs,
       text_anchor       => $g->io != gateOuterOutput ? "start": "end",
       dominant_baseline => "hanging",
       cdata             => $v ? "1" : "0");
     }

    $s->text(x=>$x+$w/2, y=>$y+5/12, fill=>"red",      text_anchor=>"middle", dominant_baseline=>"auto",    cdata=>$g->type);
    $s->text(x=>$x+$w/2, y=>$y+7/12, fill=>"darkblue", text_anchor=>"middle", dominant_baseline=>"hanging", cdata=>$g->output);

    if ($g->io != gateOuterInput)                                               # Not an input pin
     {my %i = $g->inputs ? $g->inputs->%* : ();
      my @i = sort values %i;                                                   # Connections to each gate

      for my $i(keys @i)                                                        # Connections to each gate
       {my $P = $p{$i[$i]};                                                     # Source gate
        defined($P) or confess "No such gate as: '$i[$i]'\n";
        my $X = $P->x; my $Y = $P->y; my $W = $P->width; my $G = $P->gate;      # Position of gate
        my $dx = $i + 1/2;
        my $dy = $Y < $y ?  0 : 1;
        my $dX = $X < $x ? $W : 0;
        my $dY = $Y < $y ?  0 : 0;
        my $cx = $x+$dx;                                                        # Horizontal line corner x
        my $cy = $Y+$dY+1/2;                                                    # Horizontal line corner y

        my $xc = $X < $x ? q(black) : q(darkBlue);                              # Horizontal line color
        my $x2 = $g->io == gateOuterOutput ? $cx - 1/2 : $cx;
        $s->line(x1=>$X+$dX, x2=>$x2, y1=>$cy, y2=>$cy,    stroke=>$xc);        # Outgoing value along horizontal lines

        my $yc = $Y < $y ? q(purple) : q(darkRed);                              # Vertical lines

        if ($g->io != gateOuterOutput)                                          # Incoming value along vertical line - not needed for outer output gates
         {$s->line(x1=>$cx,   x2=>$cx, y1=>$cy, y2=>$y+$dy, stroke=>$yc);
          $s->circle(cx=>$cx, cy=>$cy,    r=>0.06, fill=>"red");                # Line corner
          $s->circle(cx=>$x2, cy=>$y+$dy, r=>0.04, fill=>"blue");               # Line entering gate
         }
        else                                                                    # External output gate
         {$s->circle(cx=>$x2,   cy=>$y+$dy-1/2, r=>0.04, fill=>"blue");         # Line entering output
         }

        $s->circle(cx=>$X+$W, cy=>$cy,    r=>0.04, fill=>"red");                # Line exiting gate

        if (defined(my $v = $$values{$G->output}) and $g->io != gateOuterOutput)# Value of gate if known except for output gates written else where
         {$s->text(
            x           => $cx,
            y           => $y+$dy+($X < $x ? 0.1 : -0.1),
            fill        => "black", stroke_width=>$fw, font_size=>$fs,
            text_anchor => "middle",
            $X < $x ? (dominant_baseline=>"hanging") : (),
            cdata       =>  $v ? "1" : "0");
         }
       }
     }
   }
  my $f = owf(fpe($options{svg}, q(svg)), $s->print);
 }

#D1 Basic Circuits                                                              # Some well known basic circuits.

my sub n($$)                                                                    # Gate name from single index
 {my ($c, $i) = @_;
  "$c$i"
 }

my sub nn($$$)                                                                  # Gate name from double index
 {my ($c, $i, $j) = @_;
 "$c${i}_$j"
 }

#D2 Comparisons                                                                 # Compare unsigned binary integers of specified bit widths.

sub compareEq($%)                                                               # Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is B<1> if B<a> is equal to B<b> else B<0>.
 {my ($bits, %options) = @_;                                                    # Bits, options
  my $B = $bits;

  my $C = Silicon::Chip::newChip(name=>"eq", title=>"$B Bit Compare Equal");

  $C->input(n("a", $_))                                 for 1..$B;              # First number
  $C->input(n("b", $_))                                 for 1..$B;              # Second number
  $C->nxor (n("e", $_), {1=>n("a", $_), 2=>n("b", $_)}) for 1..$B;              # Test each bit pair for equality
  $C->and  ("and", {map {($_=>n("e", $_))}                  1..$B});            # All bits must be equal
  $C->output("out", "and");                                                     # Output B<1> if B<a> > B<b> else B<0>
  $C
 }

sub compareGt($%)                                                               # Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is  B<1> if B<a> is greater than B<b> else B<0>.
 {my ($bits, %options) = @_;                                                    # Bits, options
  my $B = $bits;

  my $C = Silicon::Chip::newChip(name=>"gt", title=>"$B Bit Compare Greater Than");

  $C->input(n("a", $_))                                 for 1..$B;              # First number
  $C->input(n("b", $_))                                 for 1..$B;              # Second number
  $C->nxor (n("e", $_), {1=>n("a", $_), 2=>n("b", $_)}) for 1..$B-1;            # Test each bit pair for equality
  $C->gt   (n("g", $_), {1=>n("a", $_), 2=>n("b", $_)}) for 1..$B;              # Test each bit pair for greater

  for my $b(2..$B)
   {$C->and(n("c", $b), {(map {$_=>n("e", $_)} 1..$b-1), $b=>n("g", $b)});      # Greater than on one bit and all preceding bits are equal
   }

  $C->or    ("or",  {1=>n("g", 1),  (map {$_=>n("c", $_)} 2..$B)});             # Any set bit indicates that B<a> is greater than B<b>
  $C->output("out", "or");                                                      # Output B<1> if B<a> > B<b> else B<0>

  $C
 }

sub compareLt($%)                                                               # Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is B<1> if B<a> is less than B<b> else B<0>.
 {my ($bits, %options) = @_;                                                    # Bits, options
  my $B = $bits;

  my $C = Silicon::Chip::newChip(name=>"lt", title=>"$B Bit Compare Less Than");

  $C->input(n("a", $_))                                 for 1..$B;              # First number
  $C->input(n("b", $_))                                 for 1..$B;              # Second number
  $C->nxor (n("e", $_), {1=>n("a", $_), 2=>n("b", $_)}) for 1..$B-1;            # Test each bit pair for equality
  $C->lt   (n("l", $_), {1=>n("a", $_), 2=>n("b", $_)}) for 1..$B;              # Test each bit pair for less than

  for my $b(2..$B)
   {$C->and(n("c", $b), {(map {$_=>n("e", $_)} 1..$b-1), $b=>n("l", $b)});      # Less than on one bit and all preceding bits are equal
   }
  $C->or    ("or",  {1=>n("l", 1),  (map {$_=>n("c", $_)} 2..$B)});             # Any set bit indicates that B<a> is greater than B<b>
  $C->output("out", "or");                                                      # Output B<1> if B<a> > B<b> else B<0>

  $C
 }

#D2 Masks                                                                       # Point masks and monotone masks. A point mask has a single B<1> in a sea of B<0>s as in B<00100>.  A monotone mask has zero or more B<0>s followed by all B<1>s as in: "00111".

sub pointMaskToInteger($%)                                                      # Convert a mask B<i> known to have at most a single bit on - also known as a B<point mask> - to an output number B<a> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point mask then output number B<a> is B<0>.
 {my ($bits, %options) = @_;                                                    # Bits, options
  my $B = 2**$bits-1;

  my %b;
  for my $b(1..$B)
   {my $s = sprintf "%b", $b;
    for my $p(1..length($s))
     {$b{$p}{$b}++ if substr($s, -$p, 1);
     }
   }

  my $C = Silicon::Chip::newChip(title=>"$bits bits point to integer");

  $C->input(n('i', $_)) for 1..$B;                                              # Mask with no more than one bit on
  for my $b(sort keys %b)
   {$C->or    (n('o', $b), {map {$_=>n('i', $_)} sort keys $b{$b}->%*});        # Bits needed to drive a bit in the resulting number
    $C->output(n('a', $b), n('o', $b));                                         # Output number
   }

  $C
 }

sub integerToPointMask($%)                                                      # Convert an integer B<i> of specified width to a point mask B<m>. If the input integer is B<0> then the mask is all zeroes as well.
 {my ($bits, %options) = @_;                                                    # Bits, options
  my $B = 2**$bits-1;

  my $C = Silicon::Chip::newChip(title=>"$bits bit integer to $B bits monotone mask");

  $C->input   (n('i', $_))             for 1..$bits;                            # Input gates
  $C->not     (n('n', $_), n('i', $_)) for 1..$bits;                            # Not of each input

  for my $b(1..$B)                                                              # Each bit of the mask
   {my @s = reverse split //, sprintf "%0${bits}b", $b;                         # Bits for this point in the mask
    my %a;
    for my $i(1..@s)
     {$a{$i} = n($s[$i-1] ? 'i' : 'n', $i);
     }
    $C->and   (n('a', $b), {%a});                                               # And to set this point n the mask
    $C->output(n('m', $b), n('a', $b));                                         # Output mask
   }

  $C
 }


sub monotoneMaskToInteger($%)                                                   # Convert a monotone mask B<i> to an output number B<r> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point then output in B<r> is B<0>.
 {my ($bits, %options) = @_;                                                    # Bits, options
  my $B = 2**$bits-1;

  my %b;
  for my $b(1..$B)
   {my $s = sprintf "%b", $b;
    for my $p(1..length($s))
     {$b{$p}{$b}++ if substr($s, -$p, 1);
     }
   }

  my $C = Silicon::Chip::newChip(title=>"$B bits monotone mask to $bits integer");

  $C->input   (n('i', $_))             for 1..$B;                               # Input gates
  $C->not     (n('n', $_), n('i', $_)) for 1..$B-1;                             # Not of each input
  $C->continue(n('a', 1),  n('i', 1));
  $C->and     (n('a', $_), {1=>n('n', $_-1), 2=>n('i', $_)}) for 2..$B;         # Look for trailing edge

  for my $b(sort keys %b)
   {$C->or    (n('o', $b), {map {$_=>n('a', $_)} sort keys $b{$b}->%*});        # Bits needed to drive a bit in the resulting number
    $C->output(n('r', $b),  n('o', $b));                                        # Output number
   }

  $C
 }
sub chooseWordUnderMask($$%)                                                    # Choose one of a specified number of words B<w>, each of a specified width, using a point mask B<m> placing the selected word in B<o>.  If no word is selected then B<o> will be zero.
 {my ($words, $bits, %options) = @_;                                            # Number of words, bits in each word, options

  my $C = Silicon::Chip::newChip(title=>"Choose a word from $words words of $bits bits");

  for   my $w(1..$words)                                                        # Input words
   {for my $b(1..$bits)                                                         # Bits in each word
     {$C->input(nn('w', $w, $b));
     }
   }

  for   my $w(1..$words)                                                        # Mask
   {$C->input(n('m', $w));
   }

  for   my $w(1..$words)                                                        # And each bit of each word with the mask
   {for my $b(1..$bits)                                                         # Bits in each word
     {$C->and(nn('a', $w, $b), {1=>n('m', $w), 2=>nn('w', $w, $b), });
     }
   }

  for   my $b(1..$bits)                                                         # Bits in each word
   {$C->or(n('p', $b), {map {($_=>nn('a', $_, $b))} 1..$words});
   }

  for my $b(1..$bits)                                                           # Output selected word
   {$C->output(n('o', $b), n('p', $b));
   }

  $C
 }

sub findWord($$%)                                                               # Choose one of a specified number of words B<w>, each of a specified width, using a key B<k>.  Return a point mask B<o> indicating the locations of the key if found or or a mask equal to all zeroes if the key is not present.
 {my ($words, $bits, %options) = @_;                                            # Number of words, bits in each word and key, options

  my $C = Silicon::Chip::newChip(title=>"Find a word in $words words of $bits bits");
  my $c = compareEq($bits, %options);                                           # Compare equals

  my %k;
  for my $b(1..$bits)                                                           # Key
   {                 $C->input (n('k', $b));
    $k{n("b", $b)} = $C->output(n('K', $b), n('k', $b))->output;
   }

  for   my $w(1..$words)                                                        # Input words
   {my %i;
    for my $b(1..$bits)                                                         # Bits in each word
     {                 $C->input (nn('w', $w, $b));                             # Each input is sent to compare equals
      $i{n('a', $b)} = $C->output(nn('W', $w, $b), nn('w', $w, $b))->output;    # The input words are immediately input into the comparators for comparison against the key
     }
    $C->input  (            n('c', $w));                                        # The result from the comparator will reenter the chip here
    $C->install($c, {%i, %k}, {out => n('c', $w)});
    $C->output (n('o', $w), n('c', $w));                                        # The results from the comparators are output as a point mask
   }

  $C
 }

#D1 Simulate                                                                    # Simulate the behavior of the L<chip>.

my sub merge($%)                                                                # Merge a L<chip> and all its sub L<chips> to make a single L<chip>.
 {my ($chip, %options) = @_;                                                    # Chip, options

  my $gates = getGates $chip;                                                   # Gates implementing the chip and all of its sub chips
  setOuterGates ($chip, $gates);                                                # Set the outer gates which are to be connected to in the real word
  removeExcessIO($chip, $gates);                                                # By pass and then remove all interior IO gates as they are no longer needed

  my $c = newChip %$chip, %options, gates=>$gates, installs=>[];                # Create the new chip with all installs expanded
  dumpGates($c, %options) if $options{dumpGates};                               # Print the gates
  svgGates ($c, %options) if $options{svg};                                     # Draw the gates using svg
  checkIO $c;                                                                   # Check all inputs are connected to valid gates and that all outputs are used

  $c
 }

my sub simulationResults($%)                                                    # Simulation results obtained by specifying the inputs to all the L<lgs> on the L<chip> and allowing its output L<lgs> to stabilize.
 {my ($chip, %options) = @_;                                                    # Chip, hash of final values for each gate, options

  genHash("Idc::Designer::Simulation::Results",                                 # Simulation results
    changed => $options{changed},                                               # Last time this gate changed
    steps   => $options{steps},                                                 # Number of steps to reach stability
    values  => $options{values},                                                # Values of every output at point of stability
    svg     => $options{svg},                                                   # Name of file containing svg drawing if requested
   );
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

sub simulate($$%)                                                               # Simulate the action of the L<lgs> on a L<chip> for a given set of inputs until the output values of each L<lg> stabilize.
 {my ($chip, $inputs, %options) = @_;                                           # Chip, Hash of input names to values, options
  my $c = merge($chip, %options);                                               # Merge all the sub chips to make one chip with no sub chips
  checkInputs($c, $inputs);                                                     # Confirm that there is an input value for every input to the chip

  my %values = %$inputs;                                                        # The current set of values contains just the inputs at the start of the simulation
  my %changed;                                                                  # Last step on which this gate changed.  We use this to order the gates on layout

  my $T = maxSimulationSteps;                                                   # Maximum steps
  for my $t(0..$T)                                                              # Steps in time
   {my %changes = simulationStep $c, \%values;                                  # Changes made

    if (!keys %changes)                                                         # Keep going until nothing changes
     {my $svg;
      if ($options{svg})                                                        # Draw the gates using svg with the final values attached
       {$svg = svgGates $c, values=>\%values, changed=>\%changed,
                        steps=>$t, %options;
       }
      return simulationResults $chip, values=>\%values, changed=>\%changed,     # Keep going until nothing changes
               steps=>$t, svg=>$svg;
     }

    for my $c(keys %changes)                                                    # Update state of circuit
     {$values{$c} = $changes{$c};
      $changed{$c} = $t;                                                        # Last time we changed this gate
     }
   }

  confess "Out of time after $T steps";                                         # Not enough steps available
 }

=pod

=encoding utf-8

=for html <p><a href="https://github.com/philiprbrenan/SiliconChip"><img src="https://github.com/philiprbrenan/SiliconChip/workflows/Test/badge.svg"></a>

=head1 Name

Silicon::Chip - Design a L<silicon|https://en.wikipedia.org/wiki/Silicon> L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> by combining L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> and sub L<chips|https://en.wikipedia.org/wiki/Integrated_circuit>.

=head1 Synopsis

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

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Compare4.svg">

Other circuit diagrams can be seen in folder: L<lib/Silicon/svg|https://github.com/philiprbrenan/SiliconChip/tree/main/lib/Silicon/svg>

=head1 Description

Design a L<silicon|https://en.wikipedia.org/wiki/Silicon> L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> by combining L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> and sub L<chips|https://en.wikipedia.org/wiki/Integrated_circuit>.


Version 20231030.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Construct

Construct a L<Silicon|https://en.wikipedia.org/wiki/Silicon> L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> using standard L<logic gates|https://en.wikipedia.org/wiki/Logic_gate>.

=head2 newChip(%options)

Create a new L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  %options   Options

B<Example:>


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


=head2 gate($chip, $type, $output, $inputs)

A L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> of some sort to be added to the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  $chip      Chip
  2  $type      Gate type
  3  $output    Output name
  4  $inputs    Input names to output from another gate

B<Example:>



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


=head2 install($chip, $subChip, $inputs, $outputs, %options)

Install a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> within another L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> specifying the connections between the inner and outer L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.  The same L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> can be installed multiple times as each L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> description is read only.

     Parameter  Description
  1  $chip      Outer chip
  2  $subChip   Inner chip
  3  $inputs    Inputs of inner chip to to outputs of outer chip
  4  $outputs   Outputs of inner chip to inputs of outer chip
  5  %options   Options

B<Example:>


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


=head1 Basic Circuits

Some well known basic circuits.

=head2 Comparisons

Compare unsigned binary integers of specified bit widths.

=head3 compareEq($bits, %options)

Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is B<1> if B<a> is equal to B<b> else B<0>.

     Parameter  Description
  1  $bits      Bits
  2  %options   Options

B<Example:>


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


=head3 compareGt($bits, %options)

Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is  B<1> if B<a> is greater than B<b> else B<0>.

     Parameter  Description
  1  $bits      Bits
  2  %options   Options

B<Example:>


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


=head3 compareLt($bits, %options)

Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is B<1> if B<a> is less than B<b> else B<0>.

     Parameter  Description
  1  $bits      Bits
  2  %options   Options

B<Example:>


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


=head2 Masks

Point masks and monotone masks. A point mask has a single B<1> in a sea of B<0>s as in B<00100>.  A monotone mask has zero or more B<0>s followed by all B<1>s as in: "00111".

=head3 pointMaskToInteger($bits, %options)

Convert a mask B<i> known to have at most a single bit on - also known as a B<point mask> - to an output number B<a> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point mask then output number B<a> is B<0>.

     Parameter  Description
  1  $bits      Bits
  2  %options   Options

B<Example:>


  if (1)
   {my $B = 4;
    my $N = 2**$B-1;

    my $c = pointMaskToInteger($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    for my $i(0..2**$B-1)                                                         # Each position of mask
     {my %i = map {("i$_"=> ($_ == $i ? 1 : 0))} 0..$N;
      my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/point$B") : ());
      is_deeply($s->steps, 2);
      my %o = $s->values->%*;                                                     # Output bits
      my $n = eval join '', '0b', map {$o{"o$_"}} reverse 1..$B;                  # Output bits as number
      is_deeply($n, $i);
     }
   }


=head3 integerToPointMask($bits, %options)

Convert an integer B<i> of specified width to a point mask B<m>. If the input integer is B<0> then the mask is all zeroes as well.

     Parameter  Description
  1  $bits      Bits
  2  %options   Options

B<Example:>


  if (1)
   {my $B = 3;

    my $c = integerToPointMask($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    for my $i(0..2**$B-1)                                                         # Each position of mask
     {my @n = reverse split //, sprintf "%0${B}b", $i;
      my %i = map {("i$_"=>$n[$_-1])} 1..@n;
      my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/integerToMontoneMask$B"):());
      is_deeply($s->steps, 3);

      my %v = $s->values->%*; delete $v{$_} for grep {!m/\Am/} keys %v;           # Mask values
      is_deeply({%v}, {map {("m$_"=> ($_ == $i ? 1 : 0))} 1..2**$B-1});           # Expected mask
     }
   }


=head3 monotoneMaskToInteger($bits, %options)

Convert a monotone mask B<i> to an output number B<r> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point then output in B<r> is B<0>.

     Parameter  Description
  1  $bits      Bits
  2  %options   Options

B<Example:>


  if (1)
   {my $B = 4;

    my $c = monotoneMaskToInteger($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my %i = map {("i$_"=>1)} 1..2**$B-1;
       $i{"i$_"} = 0 for 1..6;


    my $s = $c->simulate(\%i, svg=>"svg/monotoneMaskToInteger$B");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply($s->steps, 4);
    is_deeply($s->values->{o1}, 1);
    is_deeply($s->values->{o2}, 1);
    is_deeply($s->values->{o3}, 1);
    is_deeply($s->values->{o4}, 0);
   }


=head3 chooseWordUnderMask($words, $bits, %options)

Choose one of a specified number of words B<w>, each of a specified width, using a point mask B<m> placing the selected word in B<o>.  If no word is selected then B<o> will be zero.

     Parameter  Description
  1  $words     Number of words
  2  $bits      Bits in each word
  3  %options   Options

B<Example:>


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


=head3 findWord($words, $bits, %options)

Choose one of a specified number of words B<w>, each of a specified width, using a key B<k>.  Return a point mask B<o> indicating the locations of the key if found or or a mask equal to all zeroes if the key is not present.

     Parameter  Description
  1  $words     Number of words
  2  $bits      Bits in each word and key
  3  %options   Options

B<Example:>


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


=head1 Simulate

Simulate the behavior of the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

=head2 simulate($chip, $inputs, %options)

Simulate the action of the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> for a given set of inputs until the output values of each L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> stabilize.

     Parameter  Description
  1  $chip      Chip
  2  $inputs    Hash of input names to values
  3  %options   Options

B<Example:>


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



=head1 Hash Definitions




=head2 Silicon::Chip Definition


Chip description




=head3 Output fields


=head4 gateSeq

GAte squqnce number - this allows us to display the gates in the order they were defined ti simplify the understanding of drawn layouts

=head4 gates

Gates in chip

=head4 installs

Chips installed within the chip

=head4 name

Name of chip

=head4 title

Title if known



=head1 Private Methods

=head2 AUTOLOAD($chip, @options)

Autoload by L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> name to provide a more readable way to specify the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  $chip      Chip
  2  @options   Options


=head1 Index


1 L<AUTOLOAD|/AUTOLOAD> - Autoload by L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> name to provide a more readable way to specify the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

2 L<chooseWordUnderMask|/chooseWordUnderMask> - Choose one of a specified number of words B<w>, each of a specified width, using a point mask B<m> placing the selected word in B<o>.

3 L<compareEq|/compareEq> - Compare two unsigned binary integers B<a>, B<b> of a specified width.

4 L<compareGt|/compareGt> - Compare two unsigned binary integers B<a>, B<b> of a specified width.

5 L<compareLt|/compareLt> - Compare two unsigned binary integers B<a>, B<b> of a specified width.

6 L<findWord|/findWord> - Choose one of a specified number of words B<w>, each of a specified width, using a key B<k>.

7 L<gate|/gate> - A L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> of some sort to be added to the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

8 L<install|/install> - Install a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> within another L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> specifying the connections between the inner and outer L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

9 L<integerToPointMask|/integerToPointMask> - Convert an integer B<i> of specified width to a point mask B<m>.

10 L<monotoneMaskToInteger|/monotoneMaskToInteger> - Convert a monotone mask B<i> to an output number B<r> representing the location in the mask of the bit set to B<1>.

11 L<newChip|/newChip> - Create a new L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

12 L<pointMaskToInteger|/pointMaskToInteger> - Convert a mask B<i> known to have at most a single bit on - also known as a B<point mask> - to an output number B<a> representing the location in the mask of the bit set to B<1>.

13 L<simulate|/simulate> - Simulate the action of the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> for a given set of inputs until the output values of each L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> stabilize.

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
eval "use Test::More qw(no_plan);";
eval "Test::More->builder->output('/dev/null');" if -e q(/home/phil2/);
eval {goto latest};

clearFolder(q(svg), 99);                                                        # Clear the output svg folder

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
  $c->and   ("and", {1=>q(i1), 2=>q(i2)});
  $c->output("o",   q(and));
  eval {$c->simulate({i1=>1, i22=>1})};
  ok($@ =~ m(No input value for input gate: i2)i);
 }

#latest:;
if (1)                                                                          # Check each input to each gate receives output from another gate
 {my $c = Silicon::Chip::newChip;
  $c->input("i1");
  $c->input("i2");
  $c->and  ("and1", {1=>q(i1), i2=>q(i2)});
  $c->output( "o", q(an1));
  eval {$c->simulate({i1=>1, i2=>1})};
  ok($@ =~ m(No output driving input 'an1' on gate 'o')i);
 }

#latest:;
if (1)                                                                          #TnewChip # Single AND gate
 {my $c = Silicon::Chip::newChip;
  $c->input ("i1");
  $c->input ("i2");
  $c->and   ("and1", {1=>q(i1), 2=>q(i2)});
  $c->output("o", "and1");
  my $s = $c->simulate({i1=>1, i2=>1});
  ok($s->steps          == 2);
  ok($s->values->{and1} == 1);
 }

#latest:;
if (1)                                                                          # Three AND gates in a tree
 {my $c = Silicon::Chip::newChip;
  $c->input( "i11");
  $c->input( "i12");
  $c->and(    "and1", {1=>q(i11),  2=>q(i12)});
  $c->input( "i21");
  $c->input( "i22");
  $c->and(    "and2", {1=>q(i21),  2=>q(i22)});
  $c->and(    "and",  {1=>q(and1), 2=>q(and2)});
  $c->output( "o", "and");
  my $s = $c->simulate({i11=>1, i12=>1, i21=>1, i22=>1});
  ok($s->steps         == 3);
  ok($s->values->{and} == 1);
     $s = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>1});
  ok($s->steps         == 3);
  ok($s->values->{and} == 0);
 }

#latest:;
if (1)                                                                          #Tgate # Two AND gates driving an OR gate a tree
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

#latest:;
if (1)                                                                          # 4 bit equal
 {my $B = 4;
  my $c = Silicon::Chip::newChip(title=>"$B Bit Equals");
  $c->input ("a$_")                       for 1..$B;                            # First number
  $c->input ("b$_")                       for 1..$B;                            # Second number
  $c->nxor  ("e$_", {1=>"a$_", 2=>"b$_"}) for 1..$B;                            # Test each bit for equality
  $c->and   ("and", {map{$_=>"e$_"}           1..$B});                          # And tests together to get equality
  $c->output("out", "and");

  my $s = $c->simulate({a1=>1, a2=>0, a3=>1, a4=>0,                             # Input gate values
                        b1=>1, b2=>0, b3=>1, b4=>0},
                        svg=>"svg/Equals$B");                                   # Svg drawing of layout

  is_deeply($s->steps, 3);                                                      # Three steps
  is_deeply($s->values->{out}, 1);                                              # Result is 1

  is_deeply($c->simulate({a1=>1, a2=>1, a3=>1, a4=>0,
                          b1=>1, b2=>0, b3=>1, b4=>0})->values->{out}, 0);
 }

#latest:;
if (1)                                                                          # Compare two 4 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
 {my $B = 4;
  my $c = Silicon::Chip::newChip(title=>"$B Bit Compare");

  $c->input("a$_")                       for 1..$B;                             # First number
  $c->input("b$_")                       for 1..$B;                             # Second number
  $c->nxor ("e$_", {1=>"a$_", 2=>"b$_"}) for 1..$B-1;                           # Test each bit for equality
  $c->gt   ("g$_", {1=>"a$_", 2=>"b$_"}) for 1..$B;                             # Test each bit pair for greater

  for my $b(2..$B)
   {$c->and(  "c$b", {(map {$_=>"e$_"} 1..$b-1), $b=>"g$b"});                   # Greater on one bit and all preceding bits are equal
   }
  $c->or    ("or",  {1=>"g1",  (map {$_=>"c$_"} 2..$B)});                       # Any set bit indicates that 'a' is greater than 'b'
  $c->output("out", "or");                                                      # Output 1 if a > b else 0

  my %a = map {("a$_"=>0)} 1..$B;                                               # Number a
  my %b = map {("b$_"=>0)} 1..$B;                                               # Number b

  my $s = $c->simulate({%a, %b, "a2"=>1, "b2"=>1});                             # Two equal numbers
  is_deeply($s->values->{out}, 0);

  my $t = $c->simulate({%a, %b, "a2"=>1}, svg=>"svg/Compare$B");                # Svg drawing of layout
  is_deeply($t->values->{out}, 1);
 }

#latest:;
if (1)                                                                          #TcompareEq # Compare 8 bit unsigned integers 'a' == 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
 {my $B = 4;
  my $c = Silicon::Chip::compareEq($B);

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

#latest:;
if (1)                                                                          #TcompareGt # Compare 8 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
 {my $B = 8;
  my $c = Silicon::Chip::compareGt($B);

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

#latest:;
if (1)                                                                          #TcompareLt # Compare 8 bit unsigned integers 'a' < 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
 {my $B = 8;
  my $c = Silicon::Chip::compareLt($B);

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

#latest:;
if (1)                                                                          # Masked multiplexer: copy B bit word selected by mask from W possible locations
 {my $B = 4; my $W = 4;
  my $c = newChip;
  for my $w(1..$W)                                                              # Input words
   {$c->input("s$w");                                                           # Selection mask
    for my $b(1..$B)                                                            # Bits of input word
     {$c->input("i$w$b");
      $c->and(   "s$w$b", {1=>"i$w$b", 2=>"s$w"});
     }
   }
  for my $b(1..$B)                                                              # Or selected bits together to make output
   {$c->or    ("c$b", {map {$_=>"s$b$_"} 1..$W});                               # Combine the selected bits to make a word
    $c->output("o$b", "c$b");                                                   # Output the word selected
   }
  my $s = $c->simulate(
   {s1 =>0, s2 =>0, s3 =>1, s4 =>0,
    i11=>0, i12=>0, i13=>0, i14=>1,
    i21=>0, i22=>0, i23=>1, i24=>0,
    i31=>0, i32=>1, i33=>0, i34=>0,
    i41=>1, i42=>0, i43=>0, i44=>0});

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
# Oi1 -> Oo1-> Ii->In->Io -> Oi2 -> Oo

if (1)                                                                          #Tinstall # Install one inside another chip, specifically one chip that performs NOT is installed three times sequentially to flip a value
 {my $i = newChip(name=>"inner");
     $i->input ("Ii");
     $i->not   ("In", "Ii");
     $i->output("Io", "In");

  my $o = newChip(name=>"outer");
     $o->input ("Oi1");
     $o->output("Oo1", "Oi1");
     $o->input ("Oi2");
     $o->output("Oo", "Oi2");

  $o->install($i, {Ii=>"Oo1"}, {Io=>"Oi2"});
  my $s = $o->simulate({Oi1=>1}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");

  is_deeply($s, {steps  => 2,
    changed => { "(inner 1 In)" => 0,             "Oo" => 1 },
    values  => { "(inner 1 In)" => 0, "Oi1" => 1, "Oo" => 0 },
    svg     => "svg/not1.svg"});
 }

#latest:;
if (1)                                                                          #Tsimulate
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

  my $s = $o->simulate({Oi1=>1}, dumpGatesOff=>"dump/not3", svg=>"svg/not3");
  is_deeply($s->values->{Oo}, 0);
  is_deeply($s->steps,        4);
 }

#latest:;
if (1)                                                                          #TpointMaskToInteger
 {my $B = 4;
  my $N = 2**$B-1;
  my $c = pointMaskToInteger($B);
  for my $i(0..2**$B-1)                                                         # Each position of mask
   {my %i = map {("i$_"=> ($_ == $i ? 1 : 0))} 0..$N;
    my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/point$B") : ());
    is_deeply($s->steps, 2);
    my %o = $s->values->%*;                                                     # Output bits
    my $n = eval join '', '0b', map {$o{"o$_"}} reverse 1..$B;                  # Output bits as number
    is_deeply($n, $i);
   }
 }

#latest:;
if (1)                                                                          #TintegerToPointMask
 {my $B = 3;
  my $c = integerToPointMask($B);

  for my $i(0..2**$B-1)                                                         # Each position of mask
   {my @n = reverse split //, sprintf "%0${B}b", $i;
    my %i = map {("i$_"=>$n[$_-1])} 1..@n;
    my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/integerToMontoneMask$B"):());
    is_deeply($s->steps, 3);

    my %v = $s->values->%*; delete $v{$_} for grep {!m/\Am/} keys %v;           # Mask values
    is_deeply({%v}, {map {("m$_"=> ($_ == $i ? 1 : 0))} 1..2**$B-1});           # Expected mask
   }
 }

#latest:;
if (1)                                                                          #TmonotoneMaskToInteger
 {my $B = 4;
  my $c = monotoneMaskToInteger($B);
  my %i = map {("i$_"=>1)} 1..2**$B-1;
     $i{"i$_"} = 0 for 1..6;

  my $s = $c->simulate(\%i, svg=>"svg/monotoneMaskToInteger$B");

  is_deeply($s->steps, 4);
  is_deeply($s->values->{o1}, 1);
  is_deeply($s->values->{o2}, 1);
  is_deeply($s->values->{o3}, 1);
  is_deeply($s->values->{o4}, 0);
 }

#latest:;
if (1)                                                                          #TchooseWordUnderMask
 {my $B = 2; my $W = 2;
  my $c = chooseWordUnderMask($W, $B);
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

#latest:;
if (1)                                                                          #TfindWord
 {my $B = 2; my $W = 2;
  my $c = findWord($W, $B);

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

done_testing();
finish: 1;
