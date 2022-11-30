package Net::Z3950::FOLIO::Record;

use strict;
use warnings;

use Scalar::Util qw(blessed reftype);
use XML::Simple;

use Net::Z3950::FOLIO::HoldingsRecords qw(makeHoldingsRecords);
use Net::Z3950::FOLIO::MARCHoldings qw(insertMARCHoldings);
use Net::Z3950::FOLIO::PostProcess::MARC qw(postProcessMARCRecord);


sub new {
    my $class = shift();
    my($rs, $offset, $json) = @_;

    return bless {
	rs => $rs, # back-reference
	offset => $offset, # zero-based position within rs
	json => $json,
	holdingsStructure => undef,
	processed => 0,
    }, $class;
}

sub id {
    my $this = shift();
    my $id = $this->{json}->{id};
    return $id;
}

sub rs {
    my $this = shift();
    return $this->{rs};
}

sub jsonStructure {
    my $this = shift();
    return $this->{json};
}

sub prettyJSON {
    my $this = shift();
    return _formatJSON($this->{json});
}

sub prettyXML {
    my $this = shift();
    return _formatXML($this->{json});
}

sub holdings {
    my $this = shift();
    my($marc) = @_;

    if (!$this->{holdingsStructure}) {
	$this->{holdingsStructure} = makeHoldingsRecords($this, $marc);
    }

    return $this->{holdingsStructure};
}

sub _marc2folioId {
    my $marc = shift;

    my @fields999 = $marc->field(999);
    my $last999 = $fields999[-1];
    return $last999->subfield('i');
}

sub marcRecord {
    my $this = shift();
    my $rs = $this->{rs};
    my $session = $rs->session();
    my $marc = $this->{marc};

    if (!defined $marc) {
	# Fetch a chunk of records that contains the requested one.
	my $chunkSize = $session->{cfg}->{chunkSize} || 10;
	my $chunk = int($this->{offset} / $chunkSize);
	my @marcRecords = $session->_getSRSRecords($rs, $chunk * $chunkSize, $chunkSize);
	for (my $i = 0; $i < @marcRecords; $i++) {
	    my $marc = $marcRecords[$i];
	    my $id = _marc2folioId($marc);
	    my $rec = $rs->recordById($id);
	    $rec->{marc} = $marcRecords[$i];
	}

	$marc = $this->{marc};
	Net::Z3950::FOLIO::_throw(1, "missing MARC record") if !defined $marc;
    }

    if (!$this->{processed}) {
	insertMARCHoldings($this, $marc, $session->{cfg}, $rs->barcode());
	$marc = postProcessMARCRecord(($session->{cfg}->{postProcessing} || {})->{marc}, $marc);
	$this->{marc} = $marc;
	$this->{processed} = 1;
    }

    return $marc;
}


# ----------------------------------------------------------------------------

sub _formatJSON {
    my($obj) = @_;

    my $coder = Cpanel::JSON::XS->new->ascii->pretty->allow_blessed->space_before(0)->indent_length(2)->sort_by;
    return $coder->encode($obj);
}

sub _formatXML {
    my($json) = @_;

    my $xml;
    {
	# Sanitize output to remove JSON::PP::Boolean values, which XMLout can't handle
	_sanitizeTree($json);

	# I have no idea why this generates an "uninitialized value" warning
	local $SIG{__WARN__} = sub {};
	$xml = XMLout($json, NoAttr => 1);
    }
    $xml =~ s/<@/<__/;
    $xml =~ s/<\/@/<\/__/;
    return $xml;
}

# This code modified from https://www.perlmonks.org/?node_id=773738
sub _sanitizeTree {
    for my $node (@_) {
	if (!defined($node)) {
	    next;
	} elsif (ref($node) eq 'JSON::PP::Boolean') {
            $node += 0;
        } elsif (blessed($node)) {
	    use Data::Dumper;
            die('_sanitizeTree: unexpected ', ref($node), ' object: ', Dumper($node));
        } elsif (reftype($node)) {
            if (ref($node) eq 'ARRAY') {
                _sanitizeTree(@$node);
            } elsif (ref($node) eq 'HASH') {
                _sanitizeTree(values(%$node));
            } else {
                die('_sanitizeTree: unexpected reference type');
            }
        }
    }
}


1;
