package TM::Easy::Topic;

sub new {
    my $class = shift;
    my $tid   = shift;
    my $tm    = shift;
    my %self;
    tie %self, 'TM::Tied::Topic', $tid, $tm;
    return bless \%self, $class;
}

1;
