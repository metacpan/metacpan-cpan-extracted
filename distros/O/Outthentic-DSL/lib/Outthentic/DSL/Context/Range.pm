package Outthentic::DSL::Context::Range;

use strict;

sub new { 

    my $class   = shift;
    my $expr    = shift;

    my ($a, $b) = split /\s+/, $expr;

    s{\s+}[] for $a, $b;

    $a ||= '.*';
    $b ||= '.*';

    my $self = bless {}, $class;

    $self->{bound_l} = qr/$a/;
    $self->{bound_r} = qr/$b/;

    $self;
}

sub change_context {

    my $self        = shift;
    my $cur_ctx     = shift; # current search context
    my $orig_ctx    = shift; # original search context
    my $succ        = shift; # latest succeeded items

    my $bound_l = $self->{bound_l};
    my $bound_r = $self->{bound_r};

    my @new_ctx = (); # new context
    my @chunk;

    my $inside = 0;

    $self->{chains} ||= {};
    $self->{ranges} ||= []; # this is initial ranges object
    $self->{bad_ranges} ||={};  

    my $a_index;
    my $b_index;

    SUCC: for my $c (@{$cur_ctx}){

        if ( $inside and $c->[0] =~ $bound_r  ){


          push @new_ctx, @chunk;
  
          push @new_ctx, ["#dsl_note: end range"];
  
          @chunk = ();
  
          $inside = 0;
  
          $b_index = $c->[1];
  
          unless ($self->{chains}->{$a_index}){
              $self->{chains}->{$a_index} = [];
              push @{$self->{ranges}}, [$a_index, $b_index];
          }
  
          for my $j (@chunk) {
            push @new_ctx, $j;
          }
  
          @chunk = ();
  
          next SUCC;
        }

        if ($inside){

           push @chunk, $c;

        } elsif ( $c->[0] =~ $bound_l and ! defined($self->{bad_ranges}->{$c->[1]})){

            $inside = 1;
            $a_index = $c->[1];

            push @chunk, ["#dsl_note: start range"];

            next SUCC;
        }

    }

    if ($ENV{OUTH_DBG}){
      for my $c (@new_ctx){
        print "[OTX_DEBUG] @{$c}"
      }
    }
    return [@new_ctx];
}



sub update_stream {

    my $self        = shift;
    my $cur_ctx     = shift; # current search context
    my $orig_ctx    = shift; # original search context
    my $succ        = shift; # latest succeeded items
    my $stream_ref  = shift; # reference to stream object to update

    my %live_ranges;
 
    my $inside = 0;

    $self->{chains} ||= {}; # this is initial chains object
    $self->{seen}   ||= {};


    for my $c (@{$succ}){

       for my $r (@{$self->{ranges}}){

            my $a_index = $r->[0];

            my $b_index = $r->[1];

            if ($c->[1] > $a_index and $c->[1] < $b_index  ){
                push @{$self->{chains}->{$a_index}}, $c unless $self->{seen}->{$c->[1]}++;
                $live_ranges{$a_index} = 1;
            }

        }

    }

    ${$stream_ref} = {};

    my @k = sort { $b <=> $b } keys %{$self->{chains}};

    for my $cid ( @k ) {

      if ( exists $live_ranges{$cid} ) {
        ${$stream_ref}->{$cid} = [ sort { $a->[1] <=> $b->[1] } @{$self->{chains}->{$cid}} ];
      } else {
        delete ${$self->{chains}}{$cid};
        $self->{bad_ranges}->{$cid} = 1;
      }

    }

}

1;

