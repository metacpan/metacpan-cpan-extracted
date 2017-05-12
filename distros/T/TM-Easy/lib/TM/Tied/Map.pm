package TM::Tied::Map;

use strict;

use Tie::Hash;
use base qw(Tie::StdHash);

sub STORE {
    my ($self, $key, $value) = @_;
    warn "STORE $key";
    return $self->{lc $key} = $value;
} 
sub FETCH {
    my ($self, $key) = @_;

    if ($key =~ /^__/) {
	return $self->{$key};

    } elsif ($key =~ /(.*?)\s*=\s*$/) {                         # subject address
	my $url = $1;                                          # why do I need this?
	my $tid = $self->{__tm}->tids ($url) || die "topic with subject address '$1' does not exist";
	return new TM::Easy::Topic ($tid, $self->{__tm});

    } elsif ($key =~ /(.*?)\s*~\s*$/) {                         # subject identifier
	my $url = $1;                                          # why do I need this?
	my $tid = $self->{__tm}->tids (\ $url) || die "topic with subject identifier '$1' does not exist";
	return new TM::Easy::Topic ($tid, $self->{__tm});

    } elsif ($key =~ /((http|ftp|mailto):.*)/) {               # subject identifier
	my $url = $1;                                          # why do I need this?
	my $tid = $self->{__tm}->tids (\ $url) || die "topic with subject identifier '$1' does not exist";
	return new TM::Easy::Topic ($tid, $self->{__tm});

    } else {                                                   # id
	my $tid = $self->{__tm}->tids ($key) || die "topic with local identifier '$key' does not exist";
	return new TM::Easy::Topic ($tid, $self->{__tm});
    }
} 
sub EXISTS {
    my ($self, $key) = @_;

    if ($key =~ /^__/) {
	return exists $self->{$key};

    } elsif ($key =~ /(.*?)\s*=\s*$/) {                        # subject address
	my $url = $1;                                          # why do I need this?
	return $self->{__tm}->tids ($url);

    } elsif ($key =~ /(.*?)\s*~\s*$/) {                        # subject identifier
	my $url = $1;
	return $self->{__tm}->tids (\ $url);

    } elsif ($key =~ /((http|ftp|mailto):.*)/) {               # subject identifier
	my $url = $1;
	return $self->{__tm}->tids (\ $url);

    } else {                                                   # id
	return $self->{__tm}->tids ($key);
    }
} 
sub DEFINED {
    my ($self, $key) = @_;
    return defined $self->{lc $key};
} 
sub TIEHASH  {
    my $self = bless {}, shift;
    $self->{__tm} = shift;
    return $self;
}
sub FIRSTKEY {
    my $self = shift;
    return each %{$self->{__tm}->{mid2iid}};
}
sub NEXTKEY {
    my $self = shift;
    my $thiskey = shift;
    return each %{$self->{__tm}->{mid2iid}};
}


1;
