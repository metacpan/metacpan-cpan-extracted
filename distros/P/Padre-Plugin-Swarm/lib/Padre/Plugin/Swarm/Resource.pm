package Padre::Plugin::Swarm::Resource;
use strict;
use warnings;
use Padre::Logger;
use Time::HiRes 'time';
use Digest::JHash 'jhash';

use Class::XSAccessor 
    accessors => [qw(
        id
        zerotime
        zerohash
        sequence
        body
        project
        path
        history
    )];
    
my $MAX_HISTORY = 200;

sub new {
    my ($class,@args) = @_;
    my $self = bless {@args} , ref($class)||$class;
    $self->zerotime( time() );
    $self->zerohash( jhash($self->body) );
    $self->history( [] );
    $self->sequence( 1 ) unless $self->sequence;
    
    
    return $self;
}

sub _add_history {
    my ($self,$edit) = @_;
    my $dtime = time() - $self->zerotime;
    unshift @{ $self->history } , [ $self->sequence, $dtime , $edit ];

}

sub _merge_history {
    my ($self,$edit) = @_;
    my $r_delta = $edit->delta_time;
    my $r_sequence = $edit->sequence;
    
    my $history = $self->history;
    my $i = $#{ $history };
    my @consider;
    for (0..$i) {
        my $h = $history->[$i];
        if (
              $h->[0] >= $r_sequence
              and
              $h->[1] <= $r_delta
           ) {
            push @consider, $i;
        }
    }
    
    

}

sub perform_edit {
    my ($self,$edit) = @_;
    
    my $sequence = $self->sequence;
    $sequence++;
    $self->sequence($sequence);
    
    $self->_add_history( $edit );
    
    

}

sub perform_remote_edit {
    my ($self,$edit) = @_;
    my $r_deltatime = $edit->delta_time;
    my $r_sequence = $edit->sequence;
    if ( $r_sequence <= $self->sequence ) {
        TRACE( 'Out of sequence edit arrived late' );
        # find all edits that 'beat' this one
        # where sequence is equal or greater AND
        # delta_time is less than this edit
        ##
        # step through each of the 'winning' edits
        # and transform the position of this rogue edit
        # based on inserts or deletes that have occurred
        # earlier in the document stream
        $self->_merge_history($edit);
        
        
    } elsif ( $r_sequence > 1 + $self->sequence ) {
        TRACE( 'Out of sequence edit arrived AHEAD of our sequence' );
        # WTF do we do now? - we're missing some of the edit stream.
        die \"SYNC";
    } else {
        # just apply the damn edit.
        $self->sequence( $edit->sequence );
        $self->_add_history($edit);
        
    }
    
    
}


1;
