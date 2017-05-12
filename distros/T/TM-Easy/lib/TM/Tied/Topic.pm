package TM::Tied::Topic;

use strict;
use Data::Dumper;

use Tie::Hash;
use base qw(Tie::StdHash);

sub STORE {
    my ($self, $key, $value) = @_;
    warn "STORE topic $key, not implemented";
    return FETCH ($self, $key);
} 
sub FETCH {
    my ($self, $key) = @_;
#    warn "FETCH topic '$key'";

    if ($key =~ /^__/) {                                                              # internal information
	return undef ;                                                                # will not be passed on

    } elsif ($key eq '!') {                                                           # just the id
	return $self->{__tid};

    } elsif ($key eq '=') {                                                           # subject address
	return $self->{__tm}->toplet ($self->{__tid})->[TM->ADDRESS];

    } elsif ($key eq '~') {                                                           # all indicators
	return [ @{ $self->{__tm}->toplet ($self->{__tid})->[TM->INDICATORS] } ];     # as copy

    } elsif ($key =~ /<->\s*(.+)/) {                                                  # we want to jump over assocs

	my $type = $self->{__tm}->tids ($1) || return undef;
	return [
	    map  { new TM::Easy::Topic ($_, $self->{__tm}) }                          # create a new topic for ...
	    grep { $_ ne $self->{__tid} }                                             # ... those which are not me
	    map  { $self->{__tm}->get_players ($_) }                                  # .... in all the players of ..
	    $self->{__tm}->match (TM->FORALL, type => $type,                          # ... the assocs of this type ...
				  iplayer => $self->{__tid} )                         # I play in
		];

    } elsif ($key =~ /^-(.*)_s$/ || $key =~ /\s*<-\s*(.*)_s$/) {                      # we follow a role towards an assoc, PLURAL
	my $role = $self->{__tm}->tids ($1) || return undef;

	return [
		map { new TM::Easy::Association ($_->[TM->LID], $self->{__tm}) }
		$self->{__tm}->match (TM->FORALL,
				      irole => $role, iplayer => $self->{__tid} )     # look for the assocs
		];

    } elsif ($key =~ /^-(.*)$/ || $key =~ /\s*<-\s*(.*)$/) {                          # we follow a role towards an assoc
	my $role = $self->{__tm}->tids ($1) || return undef;

	my ($a) = $self->{__tm}->match (TM->FORALL,
					irole => $role, iplayer => $self->{__tid} );  # look for the assocs
	return new TM::Easy::Association ($a->[TM->LID], $self->{__tm});

    } elsif ($key =~ /^(.*)_s/) {                                                     # list of characteristics of this type, PLURAL
	my $type = $self->{__tm}->tids ($1) || return undef;
	return [
		map { $_->[0] }                                                       # only the literals
		map { $_->[TM->PLAYERS]->[1] }                                        # find the values
		$self->{__tm}->match (TM->FORALL, type => $type,
				      irole => 'thing', iplayer => $self->{__tid} )
		];                                                                    # look for the items
    } else {                                                                          # singular interest
	my $type = $self->{__tm}->tids ($key) || return undef;
	my ($v) = 
	         map { $_->[0] }                                                      # only the literals
		 map { $_->[TM->PLAYERS]->[1] }                                       # find the values
		 $self->{__tm}->match (TM->FORALL, type => $type,
				     irole => 'thing', iplayer => $self->{__tid} );   # look for the items
	return $v;
    }
} 
sub EXISTS {
    return FETCH @_;
} 
sub DEFINED {
    die "not implemented";
} 
sub TIEHASH  {
    my $self = bless {}, shift;
    $self->{__tid} = shift;
    $self->{__tm}  = shift;
    return $self;
}

1;
