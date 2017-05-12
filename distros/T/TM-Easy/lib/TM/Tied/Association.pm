package TM::Tied::Association;

use strict;
use Data::Dumper;

use Tie::Hash;
use base qw(Tie::StdHash);

sub STORE {
    my ($self, $key, $value) = @_;
    warn "STORE assoc $key";
    return $self->{lc $key} = $value;
} 
sub FETCH {
    my ($self, $key) = @_;

    if ($key =~ /\s*->\s*(.*)_s$/ || $key =~ /(.*)_s/) {              # if it looks -> xxx_s or just xxx_s => pluralized
	my $role = $self->{__tm}->tids ($1);
	my $a    = $self->{__tm}->retrieve ($self->{__aid});
	return [
		map { new TM::Easy::Topic ($_, $self->{__tm}) }
		$self->{__tm}->get_players ($a, $role)                # take all
		];
    } elsif ($key =~ /\s*->\s*(.*)/ || $key =~ /(.*)/) {              # if it looks -> xxx or just xxx
	my $role = $self->{__tm}->tids ($1);
	my $a    = $self->{__tm}->retrieve ($self->{__aid});
	my ($p)  = $self->{__tm}->get_players ($a, $role);            # take ONE
	return new TM::Easy::Topic ($p, $self->{__tm});
    }
} 
sub EXISTS {
    my ($self, $key) = @_;
    return exists $self->{lc $key};
} 
sub DEFINED {
    my ($self, $key) = @_;
    return defined $self->{lc $key};
} 
sub TIEHASH  {
    my $self = bless {}, shift;
    $self->{__aid} = shift;
    $self->{__tm}  = shift;
    return $self;
}
sub FIRSTKEY {
    my $self = shift;
    my $a  = $self->{__tm}->retrieve ($self->{__aid});
    $self->{__rs} = [ @{ $self->{__tm}->get_role_s ($a) } ];    # this is a list copy
    return shift @{ $self->{__rs} };
}
sub NEXTKEY {
    my $self = shift;
    return shift @{ $self->{__rs} };
}

1;
