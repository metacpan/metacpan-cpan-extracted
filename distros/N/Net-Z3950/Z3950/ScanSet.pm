# $Id: ScanSet.pm,v 1.1 2004/05/07 16:57:48 mike Exp $

package Net::Z3950::ScanSet;
use strict;
use warnings;


=head1 NAME

Net::Z3950::ScanSet - set of terms received in response to a Z39.50 scan

=head1 SYNOPSIS

	$ss = $conn->scan('@attr 1=4 fish');
	die $conn->errmsg() if !defined $ss;
	$size = $ss->size();
	for ($i = 0; $i < $size; $i++) {
		$term = $ss->term($i);
		$count = $ss->field($i, "freq");
		$displayTerm = $ss->field($i, "display");
		print "$displayTerm ($count)  [$term]\n";
	}

=head1 DESCRIPTION

A ScanSet object represents the set of terms found by a Z39.50 scan.

There is no public constructor for this class.  ScanSet objects are
always created by the Net::Z3950 module itself, and are returned to
the caller via the C<Net::Z3950::Connection> class's C<scan()> or
C<scanResult()> method.

=head1 METHODS

=cut


# PRIVATE to the Net::Z3950::Connection class's _dispatch() method
sub _new {
    my $class = shift();
    my($conn, $scanResponse) = @_;

    if ($scanResponse->scanStatus() == Net::Z3950::ScanStatus::Failure) {
	my $diag = $scanResponse->diag();
	$conn->{errcode} = $diag->condition();
	$conn->{addinfo} = $diag->addinfo();
	return undef;
    }

    return bless {
	conn => $conn,
	scanResponse => $scanResponse,
    }, $class;
}


sub status { shift()->{scanResponse}->scanStatus() }
sub position { shift()->{scanResponse}->positionOfTerm() }
sub stepSize { shift()->{scanResponse}->stepSize() }
sub size { shift()->{scanResponse}->numberOfEntriesReturned() }


sub term {
    my $this = shift();
    my($i) = @_;

    if ($i < 0 || $i >= $this->size()) {
	# There is no BIB-1 error for "scan-set index out of range"
	$this->{errcode} = 100;
	$this->{addinfo} = "scan-set index $i out of range 0-" . $this->size();
	return undef;
    }

    my $entry = $this->{scanResponse}->entries()->[$i];
    die "Oops!  No entry $i in scanSet $this" if !defined $entry;
    my $info = $entry->termInfo();
    if (!defined $info) {
	# Must be a surrogate diagnostic
	my $diag = $entry->surrogateDiagnostic();
	# This is a diagRec which might be defaultFormat or EXTERNAL.
	ref $diag eq 'Net::Z3950::APDU::DefaultDiagFormat'
	    or die "non-default diagnostic format";
	### $diag->diagnosticSetId() is not used
	$this->{errcode} = $diag->condition();
	$this->{addinfo} = $diag->addinfo();
	return undef;
    }

    ### We wrongly assume that the term will always be of type general
    return($info->term()->general(), $info->globalOccurrences);
}


sub field {
    my $this = shift();
    my($i, $what) = @_;

    die "$this: field() not yet implemented";
}


=head2 errcode(), addinfo(), errmsg()

	if (!defined $ss->term($i)) {
		print "error ", $ss->errcode(), " (", $ss->errmsg(), ")\n";
		print "additional info: ", $ss->addinfo(), "\n";
	}

When the C<term()> or <field()> method returns an undefined value,
indicating an error, it also sets into the scan-set the BIB-1 error
code and additional information returned by the server.  They can be
retrieved via the C<errcode()> and C<addinfo()> methods.

As a convenience, C<$ss->errmsg()> is equivalent to
C<Net::Z3950::errstr($ss->errcode())>.

=cut

sub errcode {
    my $this = shift();
    return $this->{errcode};
}

sub addinfo {
    my $this = shift();
    return $this->{addinfo};
}

sub errmsg {
    my $this = shift();
    return Net::Z3950::errstr($this->errcode());
}


=head1 AUTHOR

Mike Taylor E<lt>mike@indexdata.comE<gt>

First version Friday 7th May 2004.

=cut

1;
