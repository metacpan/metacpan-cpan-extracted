package TM::Easy::Association;

sub new {
    my $class = shift;
    my $aid   = shift;
    my $tm    = shift;
    my %self;
    tie %self, 'TM::Tied::Association', $aid, $tm;
    return bless \%self, $class;
}

1;
