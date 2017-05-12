package TM::Easy::Map;

sub new {
    my $class = shift;
    my $tm    = shift; die unless $tm->isa ('TM');
    my %self;
    tie %self, 'TM::Tied::Map', $tm;
    return bless \%self, $class;
}

sub map {
    my $self = shift;
    return $self->{__tm};
}
1;
