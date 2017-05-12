package Outthentic::DSL::Context::TextBlock;
use Data::Dumper;


sub new { 

    bless { succeeded => [] }, __PACKAGE__
}

sub change_context {

    my $self        = shift;
    my $cur_ctx     = shift; # current search context
    my $orig_ctx    = shift; # original search context
    my $succ        = shift; # latest succeeded items

    #warn Dumper($cur_ctx);
    #warn Dumper($succ);

    my $new_ctx  = []; # new context

    if (scalar @{$succ}){

       for my $c (@{$succ}){
            push @$new_ctx, $orig_ctx->[$c->[1]] if defined($orig_ctx->[$c->[1]]);
        }
    }else{
        $new_ctx = $cur_ctx; 
    }

    $new_ctx;

}


sub update_stream {

    print "\n\nxxxx start of text block update stream \n \n \n" if $ENV{OUTH_DBG}; 

    my $self        = shift;
    my $cur_ctx     = shift; # current search context
    my $orig_ctx    = shift; # original search context
    my $succ        = shift; # latest succeeded items
    my $stream_ref  = shift; # reference to stream object to update

    use Data::Dumper;

    my %live_chains = ();


    if (scalar @{$succ}) {

       unless ($self->{chains}){ # chain initialization
            for my $c ( @{$succ} ){
                print "[OTX_DEBUG] init chain $c[0]($c[1]) )...\n" if $ENV{OUTH_DBG};
                $self->{chains}->{$c->[1]} = [$c];
            }
       };



       for my $c (@{$succ}){
            my @k = keys %{$self->{chains}};
            CHAIN: for my $cid (sort { $a <=> $b } @k ){

                next CHAIN if $live_chains{$cid};

                print "[OTX_DEBUG] chain end at ".($self->{chains}->{$cid}->[-1]->[1])."\n" if $ENV{OUTH_DBG};
                
                if ( $self->{chains}->{$cid}->[-1]->[1] == $c->[1]-1 ){
                  $live_chains{$cid} = 1;
                  push @{$self->{chains}->{$cid}}, $c;
                  print "[OTX_DEBUG] push $c->[0]($c->[1]) to chain $cid  ...\n" if $ENV{OUTH_DBG};
                  print "[OTX_DEBUG] new chain end at ".($self->{chains}->{$cid}->[-1]->[0])."\n" if $ENV{OUTH_DBG};
                  last CHAIN;
                }elsif  ( $self->{chains}->{$cid}->[-1]->[1] == $c->[1] ) {
                  $live_chains{$cid} = 1;
                  print "[OTX_DEBUG] keep chain $cid  ...\n" if $ENV{OUTH_DBG};
                  last CHAIN;
                }else{
                  print "[OTX_DEBUG] skip $c->[0] [ $c->[1] ]  ...\n" if $ENV{OUTH_DBG};
                }  
            }
        }
    }

    #warn Dumper([sort { $a <=> $b } keys %live_chains]) if $ENV{OUTH_DBG};

    # delete failed chains

    ${$stream_ref} = {};

     print "\n\nxxxx generating text block stream xxxx \n \n \n" if $ENV{OUTH_DBG}; 

     for my $cid (sort { $a <=> $b } keys %{$self->{chains}}){
      if ($live_chains{$cid}) {        
          ${$stream_ref}->{$cid} = $self->{chains}->{$cid};
          print "[OTX_DEBUG] chain end at ".($self->{chains}->{$cid}->[-1]->[1])."\n" if $ENV{OUTH_DBG};
      } else {
          delete @{$self->{chains}}{$cid};
      }
    }

     print "\n\nxxxx end of text block update stream \n \n \n" if $ENV{OUTH_DBG}; 

}


1;

