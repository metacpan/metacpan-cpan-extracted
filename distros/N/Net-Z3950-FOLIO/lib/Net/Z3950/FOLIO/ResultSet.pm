package Net::Z3950::FOLIO::ResultSet;

use strict;
use warnings;

sub new {
    my $class = shift();
    my($setname, $cql) = @_;

    return bless {
	setname => $setname,
	cql => $cql,
	total_count => undef,
	records => [],
	marcRecords => {},
    }, $class;
}

sub total_count {
    my $this = shift();
    my($newVal) = @_;

    my $old = $this->{total_count};
    $this->{total_count} = $newVal if defined $newVal;
    return $old;
}

sub insert_records {
    my $this = shift();
    my($offset, $records) = @_;

    for (my $i = 0; $i < @$records; $i++) {
	# The records are data structures obtained by decoding the JSON
	$this->{records}->[$offset + $i] = $records->[$i];
    }
}

sub record {
    my $this = shift();
    my($index0) = @_;

    return $this->{records}->[$index0];
}

sub insert_marcRecords {
    my $this = shift();
    my($marcRecords) = @_;

    foreach my $instanceId (keys %$marcRecords)  {
	# The records are passed in and stored as MARC::Record objects
	$this->{marcRecords}->{$instanceId} = $marcRecords->{$instanceId};
    }
}

sub marcRecord {
    my $this = shift();
    my($instanceId) = @_;

    my $mr = $this->{marcRecords};
    return $mr->{$instanceId};
}

1;
