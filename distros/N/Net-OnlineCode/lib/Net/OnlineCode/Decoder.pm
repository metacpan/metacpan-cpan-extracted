package Net::OnlineCode::Decoder;

use strict;
use warnings;

use Carp;

use Net::OnlineCode;
use Net::OnlineCode::GraphDecoder;
use Net::OnlineCode::Bones;

require Exporter;

use vars qw(@ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $VERSION);

# Inherit from base class
@ISA = qw(Net::OnlineCode Exporter);
@EXPORT_OK = qw();

$VERSION = '0.04';

use constant DEBUG => 0;

sub new {

  my $class = shift;

  my %opts = (
              # decoder-specific arguments:
              expand_aux  => 0,    # override parent class's default
              expand_msg  => 1,    # expand_* options used by expansion()
              initial_rng => undef,
              # user-supplied arguments:
              @_
             );
  unless (ref($opts{initial_rng})) {
    carp "$class->new requires an initial_rng => \$rng parameter\n";
    return undef;
  }

  # Send all arguments to the base class. It does basic parameter
  # handling/mangling, calculates the number of auxiliary blocks based
  # on them and generates a probability distribution.

  my $self = $class->SUPER::new(@_);

  # Our subclass includes extra data/options
  $self->{expand_msg}=$opts{expand_msg};
  my $graph = Net::OnlineCode::GraphDecoder->new
    (
     $self->{mblocks},
     $self->{ablocks},
     $self->auxiliary_mapping($opts{initial_rng}),
    );
  $self->{graph} = $graph;

  # print "Decoder: returning from constructor\n";
  return $self;

}

sub accept_check_block {
  my $self = shift;
  my $rng  = shift;

  # print "Decoder: calling checkblock_mapping\n";
  my $composite_blocks = $self->checkblock_mapping($rng);

  print "Decoder check block: " . (join " ", @$composite_blocks)
    . "\n" if DEBUG;

  # print "Decoder: Adding check block to graph\n";
  my $check_node = $self->{graph}->add_check_block($composite_blocks);

  ++($self->{chblocks});

  # Caller will now have to call resolve manually ...
  # print "Decoder: Resolving graph\n";
  # ($self->{graph}->resolve($check_node));

  # caller probably won't use return value, but if they do it makes
  # sense to return zero-based array index
   
  return $check_node - $self->get_coblocks;

}

# pass calls to resolve onto graph decoder object
sub resolve {
  my ($self,@args) = @_;

  $self->{graph}->resolve(@args);
}

# new routine to replace xor_list; does "lazy" expansion of node lists
# from graph object, honouring the expand_aux and (new) expand_msg
# flags.
sub expansion {

  my ($self, $bone_or_node) = @_;

  my ($bone, $node);

  if (ref($bone_or_node)) {
    $bone = $bone_or_node;
    $node = $bone->[1];
  } else {
    $node = $bone_or_node;
    $bone = $self->{graph}->{solution}->[$node];
  }

  # pull out frequently-used variables (using hash slice)
  my ($expand_aux,$expand_msg) = @{$self}{"expand_aux","expand_msg"};
  my ($mblocks,$coblocks)      = @{$self}{"mblocks","coblocks"};


  # Stage 1: collect list of nodes in the expansion, honouring flags
  my ($min, $max) = $bone->knowns_range;
  my $in = [ @{$bone}[$min .. $max] ];
  my ($out,$expanded,$done) = ([],0,0);

  if (DEBUG) {
    print "Expander got initial bone " . $bone->pp . "\n";
    print "It has known range of [$min,$max]\n";
    print "The values are " . (join ", ", @{$bone}[$min .. $max]) . "\n";
    print "Expansion: node ${node}'s input list is " . (join " ", @$in) . "\n";
  }

  until ($done) {
    # we may need several loops to expand everything since aux blocks
    # may appear in the expansion of message blocks and vice-versa.
    # It's possible to do the expansion with just one loop, but the
    # code is more messy/complicated.

    for my $i (@$in) {
      if ($expand_msg and $i < $mblocks) {
        ++$expanded;
	$bone = $self->{solution}->[$i];
	($min, $max) = $bone->knowns_range;
        push @$out, ($bone->[$min .. $max]);
      } elsif ($expand_aux and $i >= $mblocks and $i < $coblocks) {
        ++$expanded;
	$bone = $self->{solution}->[$i];
	($min, $max) = $bone->knowns_range;
        push @$out, ($bone->[$min .. $max]);
      } else {
        push @$out, $i;
      }
    }
    $done = 1 unless $expanded;
  } continue {
    ($in,$out) = ($out,[]);
    $expanded = 0;
  }

  # test expansion after stage 1
  if (0) {
    for my $i (@$in) {
      if ($expand_aux) {
	die "raw expanded list had aux blocks after stage 1\n" 
	  if $i >= $mblocks and $i < $coblocks;
      }
      if ($expand_msg) {
	die "raw expanded list had msg blocks after stage 1\n" 
	  if $i < $mblocks;
      }
    }
  }

  if (DEBUG) {
    print "Expansion: list after expand_* is " . (join " ", @$in) . "\n";
  }

  # Stage 2: sort the list
  my @sorted = sort { $a <=> $b } @$in;

  # Stage 3: create output list containing only nodes that appear an
  # odd number of times
  die "expanded list was empty\n" unless @sorted;

  my ($previous, $runlength) = ($sorted[0], 0);
  my @output = ();

  foreach my $i (@sorted, -1) {	# -1 is a sentinel
    if ($i == $previous) {
      ++$runlength;
    } else {
      push @output, $previous if $runlength & 1;
      $previous = $i;
      $runlength = 1;
    }
  }

  # test expansion after stage 3
  if (0) {
    for my $i (@output) {
      if ($expand_aux) {
	die "raw expanded list had aux blocks after stage 3\n" 
	  if $i >= $mblocks and $i < $coblocks;
      }
      if ($expand_msg) {
	die "raw expanded list had msg blocks after stage 3\n" 
	  if $i < $mblocks;
      }
    }
  }

  # Finish: return list
  return @output;

}

# expand_aux already handled in graph object (DELETEME)
sub xor_list {
  my $self = shift;
  my $i = shift;

  return ($self->{graph}->xor_list($i));

  # algorithm will no longer return just composite blocks


  my $coblocks = $self->get_coblocks;

  # the graph object assigns check blocks indexes after the composite
  # blocks, but the user would prefer to count them from zero:

  my @list = map { $_ - $coblocks } ($self->{graph}->xor_list($i));

  foreach (@list) { die "xor_list: $_ is negative!\n" if $_ < 0; }

  return @list;
}

1;

__END__

=head1 NAME

Net::OnlineCode::Decoder - Rateless Forward Error Correction Decoder

=head1 SYNOPSIS

  use Net::OnlineCode::Decoder;
  use strict;

  # variables received from encoder:
  my ($msg_id, $e, $q, $msg_size, $blocksize);

  # calculated/local variables
  my (@check_blocks,@aux_blocks,$message,$block_id);
  my $mblocks = int(0.5 + ($msg_size / $blocksize));
  my $rng     = Net::OnlineCode::RNG->new($msg_id);


  my $decoder = Net::OnlineCode::Decoder->new(
    mblocks     => $mblocks,
    initial_rng => $rng,
    # ... pass e and q if they differ from defaults
  );
  my $ablocks = $decoder->{ablocks};
  @aux_blocks = ( ( "\0" x $blocksize) x $ablocks);

  my ($done,@decoded) = (0);
  until ($done) {
    my ($block_id,$contents) = ...; # receive data from encoder
    push @check_blocks, $contents;

    $rng->seed($block_id);
    $decoder->accept_check_block($rng);

    # keep calling resolve until it solves no more nodes or we've
    # decoded all the message blocks
    while(1) {
      ($done,@decoded) = $decoder->resolve;
      last unless @decoded;

      # resolve returns a Bone object, which can be treated as an
      # array (see Net::OnlineCode::Bone for details):
      # $bone -> [0]     always 1
      # $bone -> [1]     ID of node that was solved
      # $bone -> [2.. ]  ID of nodes that need to be XORed

      # XOR check/aux blocks together to decode message/aux block
      foreach my $bone (@decoded) {
        my $block        = "\0" x $blocksize;
        my $nodes        = scalar(@$bone);
        my $decoded_node = $bone->[1];

        # XOR all component blocks
        foreach my $node (@{$bone}[2..$nodes - 1)) {
          if ($node < $mblocks) {                 # message block
            fast_xor_strings(\$block, 
              substr($message, $node * $blocksize, $blocksize))
          } elsif ($node < $mblocks + $ablocks) { # auxiliary block
            fast_xor_strings(\$block, 
              $aux_blocks[$node - $mblocks]);
          } else {                                # check block
            fast_xor_strings(\$block, 
              $check_blocks[$node - ($mblocks + $ablocks)]);
          }
        }

        # save newly-decoded message/aux block
        if ($decoded_block < $mblocks) {          # message block
          substr($message, $decoded_node * $blocksize, $blocksize) = $block;
        } else {                                  # auxiliary block
          $aux_blocks[$decoded_node - $mblocks] = $block;
        }
      }
      last if $done;
    }
  }
  $message = substr($message, 0, $msg_size);  # truncate to correct size
  print $message;                             # Done!

=head1 DESCRIPTION

This module implements the "decoder" side of the Online Code algorithm
for rateless forward error correction. Refer to the L<the
Net::OnlineCode documentation|Net::OnlineCode> for the technical
background


=head1 SEE ALSO

See L<Net::OnlineCode> for background information on Online Codes.

This module is part of the GnetRAID project. For project development
page, see:

  https://sourceforge.net/projects/gnetraid/develop

=head1 AUTHOR

Declan Malone, E<lt>idablack@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of the "GNU General Public License" ("GPL").

The C code at the core of this Perl module can additionally be
redistributed and/or modified under the terms of the "GNU Library
General Public License" ("LGPL"). For the purpose of that license, the
"library" is defined as the unmodified C code in the clib/ directory
of this distribution. You are permitted to change the typedefs and
function prototypes to match the word sizes on your machine, but any
further modification (such as removing the static modifier for
non-exported function or data structure names) are not permitted under
the LGPL, so the library will revert to being covered by the full
version of the GPL.

Please refer to the files "GNU_GPL.txt" and "GNU_LGPL.txt" in this
distribution for details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

