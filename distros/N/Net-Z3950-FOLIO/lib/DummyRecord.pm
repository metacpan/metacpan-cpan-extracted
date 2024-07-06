# USED ONLY FOR TESTING


package DummyResultSet;

sub new {
    my $class = shift();    
    my($cfg) = @_;
    return bless {
	cfg => $cfg,
    }, $class;
}

sub session {
    my $this = shift();
    return {
	cfg => $this->{cfg},
    };
}


package DummyRecord;

use Net::Z3950::FOLIO::HoldingsRecords qw(makeHoldingsRecords);

sub new {
    my $class = shift();
    my($folioHoldings, $marc, $cfg) = @_;

    return bless {
	rs => new DummyResultSet($cfg),
	folioHoldings => $folioHoldings,
	marc => $marc,
    }, $class;
}

sub rs { return shift()->{rs} }
sub jsonStructure { return shift()->{folioHoldings} }
sub marcRecord { return shift()->{marc} }

sub holdings {
    my $this = shift();
    my($marc) = @_;

    return makeHoldingsRecords($this, $marc)
};


1;
