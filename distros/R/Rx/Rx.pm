package Rx;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Data::Dumper;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();
@EXPORT = qw(instrument);
$VERSION = '0.53';
our($DEBUG) = 0;
our($O_DEBUG) = 0;              # Offset generation debugging
our($U_DEBUG) = 0;              # Bytecode generation debugging

our($MULTIMATCH) = 0;

bootstrap Rx $VERSION;

my %is_instrumentable = set_of(qw(EXACT END));

sub _the_instrument {
  my ($id);                     # Dummy variable 
  _setup_and_call_callback($id);
}

# Not used any more
sub _setup_and_call_callback {
  my ($id) = @_;
  print "In setup_and_call_callback ID=$id\n";
  my @items = ($`, $&, $');
  for (my $i = 1; $i <= $#-; ++$i) {
    push @items, ${$i};
  }
  local $" = ', ';
  print "   Items: @items\n";
  _xs_callback_glue($id, \@items);
}

sub do_match {
  my ($s) = @_;
  $s =~ /(?{"dummy"})/; # This regex gets replaced by Rx
}

sub do_repeated_match {
  my ($s) = @_;
  1 while $s =~ /dummy/g; # This regex gets replaced by Rx
}

my %quant_type = ('*' => 'curlyx',
                  '+' => 'curlyx',
                  '?' => 'curlyx',
                  '|' => 'branch',
                  );

my %skippable_node = map { $_ => 1 } 
  qw(match_succeeds breakpoint 
     optimized nothing
     succeed whilem
    );



# Given a deparesed regex structure and an offset structure,
# insert the offset and length information into the regex structure
sub _fixup_offsets {
}

# Copy a deparsed regex structure and insert instrumentation nodes
sub _add_instruments {
  my ($h) = @_;
  my %seen;
#  my ($max_offset) = $h->{MAX_OFFSET};
#  croak("Couldn't find MAX_OFFSET in hash data structure")
#    unless defined $max_offset;

  # Initialize result structure: copy metainformation.
# Bug?: Forgot to copy REGEX.
#  my $hi = {map {$_ => $h->{$_}} grep {substr($_,0,2)eq'__'} keys %$h};
#  $hi->{REGEX} = $h->{REGEX};
  my $hi = {%$h};                  # Just copy the whole thing

  my $instrument_number = 1;
  my @queue = (0);
  while (@queue) {
    my $n = shift @queue;
    if ($seen{$n}++) {
      print "Node $n already seen; skipping.\n";
      next;
    }
    print "Node $n\n";
    my $hc = {%{$hi->{$n}}};     # copy of current node
    my $t = uc $hi->{$n}{TYPE};

    # Special case: bust up long strings into single characters
    # with a breakpoint before each character
    if ($t eq 'EXACT' && length($hi->{$n}{STRING}) > 1) {
      my $target = $hi->{$n}{NEXT};
      my @chars = split //, $hi->{$n}{STRING};
      my $c1 = shift @chars;
      my $i = 1;
      $hi->{$n} = _new_instrument($n.'e', $instrument_number++);
      $hi->{$n . 'e'} = _new_char("${n}s${i}", $c1);
      for my $c (@chars) {
        my $ii = $i+1;
        $hi->{"${n}s${i}"}  = _new_instrument("${n}s${i}e", 
                                              $instrument_number++);
        $hi->{"${n}s${i}e"} = _new_char("${n}s${ii}", $c);
        ++$i;
      }
      --$i;
      $hi->{"${n}s${i}e"}{NEXT} = $target;
      $n = $n . 'e';

    # Special cases: change X* to X{0,32767} to defeat optimizations
    } elsif ($t eq 'STAR' || $t eq 'PLUS' 
             || $t eq 'CURLY' || $t eq 'CURLYN' || $t eq 'CURLYM') {
      my ($min, $max);
      if ($t eq 'STAR') { ($min, $max) = (0, 32767) }
      elsif ($t eq 'PLUS') { ($min, $max) = (1, 32767) }
      elsif ($t =~ /^CURLY/) { ($min, $max) = @{$hi->{$n}{ARGS}} }
      else { die "Unknown quantifier type $t" }
      @{$hi->{$n}}{'TYPE','TYPEn','FLAGS','ARGS'} 
        = ('CURLYX',opcode('CURLYX'),1,[$min,$max]);
      my $last_node = $hi->{$n}{CHILD};
      while (defined $hi->{$last_node}{NEXT}) {
        $last_node = $hi->{$last_node}{NEXT};
      }
      $hi->{$last_node}{NEXT} = $n . 'w';
      $hi->{$n . 'w'} = { TYPE => 'WHILEM',
                          TYPEn => opcode('WHILEM'),
                          FLAGS => 17,
                        };
      $hi->{$n . 'n'} = { TYPE => 'NOTHING',
                          TYPEn => opcode('NOTHING'),
                          FLAGS => 222,
                          NEXT => $hi->{$n}{NEXT},
                        };
      $hi->{$n}{NEXT} = $n . 'n';
      
     # Otherwise just add a single instrument here if appropriate
    } elsif ($is_instrumentable{$t}) {
      $hi->{$n.'e'} = $hc;
      if ($hi->{$n}{TYPE} eq 'END') {
        $hi->{$n} = _end_instrument($n.'e');
      } else {
        $hi->{$n} = _new_instrument($n.'e', $instrument_number++);
      }
      $n = $n . 'e';

    # If it's *not* approriate, simply copy the input to the output.
    } else {
      $hi->{$n} = $hc;
    }

    # BUG: Should handle TRUE and FALSE also.
    push @queue, grep {defined} @{$hi->{$n}}{'CHILD', 'NEXT'};
  }
  $hi;
}

# Construct new 'single character' node
sub _new_char {
  return { TYPE => 'EXACT', TYPEn => opcode('EXACT'), NEXT => $_[0], 
           STRING => $_[1], FLAGS => length($_[1]), # should be 1
         };  
}

# Construct new instrument node
sub _new_instrument {
  return { TYPE => 'BREAKPOINT', NEXT => $_[0], ID => $_[1],
           TYPEn => opcode('EVAL'), 
           ARGS => $_[1] * 3     # this points to the compiled code 
         };  
}

# Construct new 'match was successful' node
sub _end_instrument {
  return { TYPE => 'MATCH_SUCCEEDS', NEXT => $_[0], ID => 0,
           TYPEn => opcode('EVAL'),
           ARGS => 0
         };  
}

my $REG_MAGIC = 0234;           # dec 156

my $regnode_fmt      = "CCS";        # flags, type, next
my $regnode_next_fmt = "S"  ;        # just 'next'


sub undump {
  my ($hrx) = @_;
  $DEBUG and print Dumper($hrx);
  my $res = pack "I", $REG_MAGIC;
  my $ends = '';
  my $n_tails = 0;
  
  my ($n_instruments, $node_map) = _undump_map($hrx);
  my %done;
  
  my $offsets = _undump_nodes($hrx, 0, \$res, $node_map);
  _undump_fix_next($hrx, \$res, $offsets);

  $U_DEBUG && print_bytecode($res);

  # Append trailer that forces backtracking.
  if ($MULTIMATCH) {
    for (;;) {
      my ($f, $c, $n) = unpack $regnode_fmt, substr($res, -4);
      if ($c == 0) {
        $ends .= substr($res, -4);
        substr($res, -4) = '';
        ++$n_tails;
        last;
      } else {
        if ($n_tails == 0) {
          die "Last node in regex bytecode is ($c) instead of 'end'\n";
        }
        my ($f, $c, $n) = unpack $regnode_fmt, substr($res, -4);
        last;
      }
    }
    
    $res .= pack($regnode_fmt,   0, opcode('UNLESSM'), 0);
    $res .= pack("L",            5); # Skip next 5
    $res .= pack($regnode_fmt, 222, opcode('NOTHING'), 1);  # match nothing
    $res .= pack($regnode_fmt, 222,  opcode('SUCCEED'), 0);  # succeed
    $res .= pack($regnode_fmt, 222, opcode('TAIL'), 0);  
    #  $res .= pack($regnode_fmt, 222,  opcode('END'), 0);  # end node for (?!)
    #  $res .= pack($regnode_fmt,  41,  opcode('END'), 0);  # real end node
    $res .= $ends;
  }

  wantarray ? ($res, $n_instruments+1) : [$res, $n_instruments+1];
}

   # These sorts of nodes have two branches.
   # The hash value is the key into the hash node under which is stored
   # the node name for the *secondary* branch, which is the one
   # that appears in the bytecode *immediately after* the 
my %branch = qw(STAR CHILD 
                PLUS CHILD
                CURLYX CHILD
                CURLYM CHILD
                CURLYN CHILD
                BRANCH CHILD
               )
   ;


# Make map that says for each node how many other nodes have NEXT
# pointing into it.  Then when we construct the byte code, we can be
# sure that we postpone each node until all its predecessors have been
# done.  Returns hash with keys = node names, values = lists of
# predecessor node names.
sub _undump_map {
  my ($hrx) = @_;
  my $n_instruments = 0;
  my @queue = (0);
  my %map;
  my %seen;
  while (@queue) { 
    my $nn = shift @queue;
    next if $seen{$nn}++;       # Only do each node once.
    my $node = $hrx->{$nn};
    my $t = uc $node->{TYPE};
    ++$n_instruments if $t eq 'BREAKPOINT' || $t eq 'MATCH_SUCCEEDS';
    my $next = $node->{NEXT};
    next unless defined $next;
    push @{$map{$next}}, $nn;
    # BUG: Should handle TRUE and FALSE also.
    push @queue, grep {defined} @{$node}{'CHILD', 'NEXT'};
  }
  ($n_instruments, \%map);
}

sub _undump_fix_next {
  my ($hrx, $rr, $offset) = @_;
  
  for my $k (keys %$hrx) {
    next if substr($k, 0, 2) eq '__' || $k eq 'REGEX' || $k eq 'LENGTHS' || $k eq 'OFFSETS';
    my $node = $hrx->{$k};
    my $next = $node->{NEXT};
    my $pos  = $offset->{$k};
    if (defined $next) {
      substr($$rr, $pos+2, 2) = pack "S", ($offset->{$next}-$pos)/4;
    } else {
      substr($$rr, $pos+2, 2) = pack "S", 0;
    }
  }
}

# To do a star:
# put the head in
# insert child data.  return value is new string length
# set 'next' field  to point to new string end
# 

sub _undump_nodes {
  my ($hrx, $nn, $rr, $pred, $seen) = @_;
  $seen = {} unless defined $seen;

  for (;;) {
    $DEBUG && print_bytecode($$rr);

    return $seen if $seen->{$nn};       # Did this one already.
    my $n =  $hrx->{$nn};
    my $t = uc $n->{TYPE};
    my $a = $n->{ARGS};
    my $pos = length($$rr);           # Length of code at start 

    # If the current node has predecessors that haven't been visited yet,
    # skip it; we will do it later.
    for my $prednode (@{$pred->{$nn}}) {
      return $seen unless $seen->{$prednode};
    }

    $DEBUG && print "Now adding '$n->{TYPE}' (node $nn)\n\n";
    $seen->{$nn} = length($$rr);

    # The 119*257 here is a dummy value.  It should be overwritten later
    my $node = pack $regnode_fmt, $n->{FLAGS}, $n->{TYPEn}, 119*257;
    $$rr .= $node;

    # Now do ARGS
    # Here we cheat a little.  We assume there are only three
    # arg formats: No args, a 4-byte integer, and two 2-byte integers.
    # We can deduce which from looking at the ->{ARGS} item.
    if (defined $n->{ARGS}) {
      my $arg;
      if (ref $n->{ARGS}) {     # pair of 2-byte ints
        $arg = pack "SS", @{$n->{ARGS}};
      } else {                  # 4-byte int
        $arg = pack "L", $n->{ARGS};
      }
      $$rr .= $arg;
    }

#    # remind the caller how many instruments there are
#    # so it can return this at the end.
#    if (defined($n->{ID}) && $n->{ID} > $$n_instruments) {
#      $$n_instruments = $n->{ID};
#    }

    # now do any special stuff that is necessary
    # such as the STRING part of an 'exact' node.
    if ($t eq 'EXACT' || $t eq 'EXACTF' ||$t eq 'EXACTFL') {
      my $s = $n->{STRING};
      $s .= "\0" until length($s)%4 == 0;
      $$rr .= $s;
    } elsif ($t eq 'ANYOF') {
      $$rr .= $n->{BITMAP}
    } elsif ($t eq 'BREAKPOINT' || $t eq 'MATCH_SUCCEEDS') {
      # This actually installs the instrument into the bytecode
      substr($$rr, -8, 4) = 
        # special 222 flags, 75=EVAL, 119*257 = same overwritten dummy value
        pack($regnode_fmt, 222, opcode('EVAL'), 119 * 257);
    } 


    # Now if there's a branch, such as CHILD, TRUE, LOOKFOR, etc.,
    # append that (recursive call)
    if ($branch{$t}) {
      _undump_nodes($hrx, $n->{$branch{$t}}, $rr, $pred, $seen);
    }

#    # Now adjust the 'next' field
#    # This overwrites the dummy value
#    if (defined $n->{NEXT}) {    #  Only if it has one!
#      substr($$rr, $pos+2, 2) = pack $regnode_next_fmt, (length($$rr)-$pos)/4;
#    } else {
#      # Otherwise set it to zero.
#      substr($$rr, $pos+2, 2) = pack $regnode_next_fmt, 0;
#    }

    # Now continue with the ->{NEXT} node if there is one
    if (defined $n->{NEXT}) {
      $nn = $n->{NEXT};
    } else {
      return $seen;
    }
  } # Infinite loop
}

my %opcode;
sub opcode {
  my $name = shift;
  unless (exists $opcode{$name}) {
    my $n = $opcode{$name} = opname_to_num($name);
    die "Bad opcode name $name" if $n < 0;
  }
  $opcode{$name};
}

sub print_bytecode {
  my ($bc) = @_;
  my $i = 0;
  for my $c (split //, $bc) {
    printf "%6d  ", $i/4 if $i % 4 == 0;
    printf "%3d ", ord($c);
    print "\n" if ++$i % 4 == 0;
  }
}


sub set_of {
  my %h;
  $h{$_} = 1 for @_;
  wantarray ? %h : \%h;
}

sub croak {
  require Carp;
  goto &Carp::croak;
}

sub carp {
  require Carp;
  *carp = \&Carp::Carp;
  goto &carp;
}

1;
__END__

=head1 NAME

Rx - Regex debugger module

=head1 SYNOPSIS

  use Rx;

  $rx = instrument('regex', 'flags');
  $rx->start($target, $callback);

=head1 DESCRIPTION


=head1 AUTHOR

Mark-Jason Dominus (mjd-perl-rx+@plover.com)

=head1 SEE ALSO

perl(1), perlre.

=cut

