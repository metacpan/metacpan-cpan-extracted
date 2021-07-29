package Net::Z3950::FOLIO::ResultSet;

use strict;
use warnings;

use Net::Z3950::FOLIO::Record;

sub new {
    my $class = shift();
    my($session, $setname, $cql) = @_;

    my $barcode = _extractBarcode($cql);

    return bless {
	session => $session, # back-reference
	setname => $setname,
	cql => $cql,
	barcode => $barcode,
	totalCount => undef,
	records => [],
	id2record => {},
    }, $class;
}

sub session {
    my $this = shift();
    return $this->{session};
}

sub totalCount {
    my $this = shift();
    my($newVal) = @_;

    my $old = $this->{totalCount};
    $this->{totalCount} = $newVal if defined $newVal;
    return $old;
}

sub barcode {
    my $this = shift();
    return $this->{barcode};
}

sub insertRecords {
    my $this = shift();
    my($offset, $records) = @_;

    for (my $i = 0; $i < @$records; $i++) {
	my $rec = new Net::Z3950::FOLIO::Record($this, $offset + $i, $records->[$i]);
	$this->{records}->[$offset + $i] = $rec;
	my $id = $rec->id();
	$this->{id2record}->{$id} = $rec;
    }
}

sub record {
    my $this = shift();
    my($index0) = @_;

    return $this->{records}->[$index0];
}

sub recordById {
    my $this = shift();
    my($id) = @_;

    return $this->{id2record}->{$id};
}

# If the $cql query is a search for a barcode, return that barcode;
# otherwise return undefined. We could do this the sophisticated way,
# by parsing the CQL and examing every node, but in practice it
# probably suffices to do a simple string check.
#
sub _extractBarcode {
    my ($cql) = @_;

    if ($cql =~ /^item.barcode[\t ]*=+[\t ]*(.*)/) {
	return $1;
    }

    return undef;
}

1;
