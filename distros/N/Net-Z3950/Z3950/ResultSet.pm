# $Header: /home/cvsroot/NetZ3950/Z3950/ResultSet.pm,v 1.22 2005/04/21 11:41:23 mike Exp $

package Net::Z3950::ResultSet;
use strict;


=head1 NAME

Net::Z3950::ResultSet - result set received in response to a Z39.50 search

=head1 SYNOPSIS

	if ($conn->op() == Net::Z3950::Op::Search) {
		$rs = $conn->resultSet();
		$size = $rs->size();

=head1 DESCRIPTION

A ResultSet object represents the set of records found by a Z39.50
server in response to a search.  At any given time, none, some or all
of the records may have been physcially transferred to the client; a
cache is maintained.

Note that there is no constructor for this class (or at least, none
that I'm going to tell you about :-)  ResultSet objects are always
created by the Net::Z3950 module itself, and are returned to the caller
via the C<Net::Z3950::Connection> class's C<resultSet()> method.

=head1 METHODS

=cut


# The key data member of Result Sets is $this->{records}, which is a
# hash mapping element-set names to caches of records represented in
# that element set.  Each such cache is an array, the elements of
# which may contain any of the following values:
#	an undefined value (or not there at all -- off the end of the
#		array) if we don't have the record, and it's not been
#		requested yet.
#	CALLER_REQUESTED if the caller has asked for the record but we
#		don't have it and have not yet issued a Present
#		request for it.
#	RS_REQUESTED if the caller has asked for the record and we
#		don't have it, but we have issued a Present request
#		and are awaiting a response.
#	a record reference if we have the record.
#	a surrogate diagnostic if we fetched the record
#		unsuccessfully.
# We use the slots in $this->{records} corresponding to 1-based record
# numbers; that is, slot zero is not used at all.
sub CALLER_REQUESTED { 1 }
sub RS_REQUESTED { 2 }

# PRIVATE to the Net::Z3950::Connection class's _dispatch() method
sub _new {
    my $class = shift();
    my($conn, $rsName, $searchResponse) = @_;

    if (!$searchResponse->searchStatus()) {
	# Search failed: set $conn's error indicators and return undef
	my $records = $searchResponse->records();

	if (defined $records) {
	    ref $records eq 'Net::Z3950::APDU::DefaultDiagFormat'
		or die "non-default diagnostic format";
	    ### $rec->diagnosticSetId() is not used
	    $conn->{errcode} = $records->condition();
	    $conn->{addinfo} = $records->addinfo();
	} else {
	    # Some servers don't return diag records, even though
	    # that's illegal.  So fake an error.
	    $conn->{errcode} = 3; # unsupported search -- near enough
	    $conn->{addinfo} = "no diagnostic records supplied by server";
	}
	return undef;
    }

    my $this = bless {
	conn => $conn,
	rsName => $rsName,
	searchResponse => $searchResponse,
	records => {},
    }, $class;

    ### Should also check presentStatus where relevant
    my $rawrecs = $searchResponse->records();
    $this->_insert_records($searchResponse, 1, 1)
	if defined $rawrecs;

    return $this;
}


=head2 size()

	$nrecords = $rs->size();

Returns the number of records in the result set I<$rs>

=cut

sub size {
    my $this = shift();

    return $this->{searchResponse}->resultCount();
}


=head2 subqueryCount()

    $subquery = $rs->subqueryCount();

Returns hit count of subquery terms as a hash reference containing
(term, count) pairs, if the server returned this information.  If the
information is not available, an undefined value is returned.

=cut

sub subqueryCount {
    my $this = shift();

    my $info = $this->{searchResponse}->additionalSearchInfo();
    return undef if !$info;

    my $subquery = {};
    foreach my $unit (@{$info}) {
	if ($unit->which() ==
	    Net::Z3950::OtherInformationUnit::ExternallyDefinedInfo) {
	    if (my $reports = $unit->externallyDefinedInfo()) {
		foreach my $report (@{$reports}) {
		    if (my $expr = $report->subqueryExpression()) {
			if ($expr->which() ==
			    Net::Z3950::QueryExpression::Term) {
			    my $term = $expr->term()->queryTerm()->general();
			    $subquery->{$term} = $report->subqueryCount()
				if $term;
			}
		    }
		}
            }
        }
    }

    return $subquery;
}

=head2 present()

    $rs->present($start, $count) or die "failed: $rs->{errcode}\n";

Causes any records in the specified range that are not yet in the
cache to be retrieved from the server.  By calling this method before
retrieving individual records with C<record()>, you avoid sending lots
of small requests for single records across the network.  In
asynchronous mode, C<present()> just schedules the records for
retrieval.

Note that C<$start> is indexed from 1.

In synchronous mode, returns 1 if the records were successfully
retrieved, 0 if an error occurred.  In asynchronous mode, returns 1 if
new requests were queued, 0 if all of the requested records had
already been queued.

=cut

sub present {
    my ($this, $start, $count) = @_;

    my $esn = $this->option('elementSetName');
    ### Shouldn't this cache also have a record-syntax dimension?
    if (!defined $this->{records}->{$esn}) {
	$this->{records}->{$esn} = [];
    }
    my $records = $this->{records}->{$esn};

    # quietly ignore presents past the last record - this stops
    # prefetch causing errors

    my $size = $this->size;
    my $last = $start+$count-1;
    $last = $size if $last > $size;

    my $seen_new;
    for (my $i=$start; $i <= $last; $i++) {
	if (not defined $records->[$i]) {
	    # It hasn't even been requested: mark for Present-request
	    $records->[$i] = CALLER_REQUESTED;
	    $seen_new = 1;
	}
    }
    $this->{conn}->{idleWatcher}->start() if $seen_new;
    return undef
	if $this->option('async');

    # Synchronous-mode request for a record that we don't yet have.
    # As soon as we're idle -- in the wait() call -- the _idle()
    # watcher will send a presentRequest; we then wait for its
    # response to arrive.
    if (!$this->{conn}->expect(Net::Z3950::Op::Get, "get")) {
	# Error code and addinfo are in the connection: copy them across
	$this->{errcode} = $this->{conn}->{errcode};
	$this->{addinfo} = $this->{conn}->{addinfo};
	return 0;
    }
    return 1;
}


=head2 record()

	$rec = $rs->record($n);

Returns a reference to I<$n>th record in the result set I<$rs>, if the
content of that record is known.  Valid values of I<$n> range from 1
to the return value of the C<size()> method.

If the record is not available, an undefined value is returned, and
diagnostic information made available via I<$rs>'s C<errcode()> and
C<addinfo()> methods.

As a special case, when the connection is anychronous, the
C<errcode()> may be zero, indicating simply that the record has not
yet been fetched from the server.  In this case, the calling code
should try again later.  (How much later?  As a rule of thumb, after
it's done ``something else'', such as request another record or issue
another search.)  This can never happen in synchronous mode.

=cut

sub record {
    my $this = shift();
    my($which) = @_;

    # autovivifies if necessary
    my $rec = $this->{records}{$this->option('elementSetName')}[$which];

    if (!defined $rec or not ref $rec) {
	# Record not in place yet

	my $status = $this->present($which, $this->option('prefetch') || 1);
	if ($this->option('async')) {
	    # request was merely queued
	    $this->{errcode} = 0;
	    return undef;
	} elsif (!$status) {
	    # An actual error: the code/addInfo have already been set
	    return undef;
	}

	# The _add_records() callback invoked by the event loop should now
	# have inserted the requested record into our array, so we should
	# just be able to return it.  Sanity-check first, though.
	$rec = $this->{records}{$this->option('elementSetName')}[$which];
	if (!defined $rec) {
	    die "record(): impossible: didn't get record";
	} elsif (!ref $rec) {
	    # Why would we ever get back a record that is not a
	    # reference?  I think only because something is very badly
	    # wrong.  We wrap it up as a reference so it can be
	    # render()ed without breaking the application.
	    use Net::Z3950::Record;
	    my $errmsg = "THIS IS NOT A USMARC RECORD.  " .
		"Something has gone badly wrong.  " .
		"The internal record object has value '$rec'";
	    return bless \$errmsg, 'Net::Z3950::Record::USMARC';
	}
    }

    if (ref $rec && $rec->isa('Net::Z3950::APDU::DefaultDiagFormat')) {
	# Set error information from record into the result set
	### $rec->diagnosticSetId() is not used
	$this->{errcode} = $rec->condition();
	$this->{addinfo} = $rec->addinfo();
	return undef;
    }
    # We have it, and it's presumably a legitmate record
    return $rec;
}


# PRIVATE to the Net::Z3950::Connection module's new() method, invoked as
# an Event->idle callback
sub _idle {
    my($event) = @_;
    my $watcher = $event->w();
    my $conn = $watcher->data();

    foreach my $rs ($conn->resultSets()) {
	next if !$rs;		# a pending slot, awaiting search response
	$rs->_checkRequired();
    }

    # Don't fire again until more records are requested
    $watcher->stop();
}


# PRIVATE to the _request_records() method
sub _checkRequired {
    my $this = shift();

    my $esn = $this->option('elementSetName');
    my $records = $this->{records}->{$esn};
    return unless defined $records;
    my $n = @$records;

    ###	If our interface to the C function makePresentRequest allowed
    #	us to generate multiple ranges (using the Present Request
    #	APDU's additionalRange parameter), we could consider using
    #	that and making a single big present request instead of
    #	(potentially) several little ones; but it's slightly tricky to
    #	do, and it's not clear that it would be more efficient, so
    #	let's not lose any sleep over it for now.

    my($first, $howmany);
    for (my $i = 1; $i <= $n; $i++) {
	my $rec = $records->[$i];
	if (!defined $first) {
	    # We've not yet seen a record we want to fetch
	    if (defined $rec && $rec == CALLER_REQUESTED) {
		# ... but now we have!  Start a new range
		$first = $i;
		$records->[$i] = RS_REQUESTED;
	    }
	} else {
	    # We're already gathering a range
	    if (defined $rec && $rec == CALLER_REQUESTED) {
		# Range continues: mark that we're requesting this record
		$records->[$i] = RS_REQUESTED;
	    } else {
		# This record is one past the end of the range we want
		$howmany = $i-$first;
		$this->_send_presentRequest($first, $i-$first);
		$first = undef;	# prepare for next range
	    }
	}
    }
}


# PRIVATE to the _checkRequired() method
#
#   ###	Instead of sending these out immediately, we should put them
#	on a queue to be sent out when the connection is quiet (which
#	may be immediately): in this way we work with broken (but
#	compliant!) servers which may throw away anything after the
#	first APDU in their connection's input queue.  In Real Life,
#	the current version will Nearly Always(tm) work, but this is a
#	good place to look if we get bug reports in this area.
#
sub _send_presentRequest {
    my $this = shift();
    my($first, $howmany) = @_;

    my $refId = _bind_refId($this->{rsName}, $first, $howmany);
    my $errmsg = '';
    my $pr = Net::Z3950::makePresentRequest($refId,
				       $this->option('namedResultSets') ?
					$this->{rsName} : 'default',
				       $first, $howmany,
				       $this->option('elementSetName'),
				       $this->preferredRecordSyntax(),
				       $errmsg);
    die "can't make present request: $errmsg" if !defined $pr;
    $this->{conn}->_enqueue($pr);
}


# PRIVATE to the Net::Z3950::Connection class's _dispatch() method
sub _add_records {
    my $this = shift();
    my($presentResponse) = @_;

    my($rsName, $first, $howmany) =
	_unbind_refId($presentResponse->referenceId());
    ### Should check presentStatus
    my $n = $presentResponse->numberOfRecordsReturned();

    # Sanity checks
    if ($rsName ne $this->{rsName}) {
	die "rs '" . $this->{rsName} . "' was sent records for '$rsName'";
    }
    if ($n > $howmany) {
	die "rs '$rsName' got $n records but only asked for $howmany";
    }

    if ($this->_insert_records($presentResponse, $first, $howmany)) {
	my $esn = $this->option('elementSetName');
	my $records = $this->{records}->{$esn};
	for (my $i = $n; $i < $howmany; $i++) {
	    # We asked for this record but didn't get it, for whatever
	    # reason.  Mark the record down to "requested by the user
	    # but no present request outstanding" so that it gets
	    # requested again.
	    ###	This might not always be The Right Thing -- if the
	    #	error is a permanent one, we'll end up looping, asking
	    #	for it again and again.  We could further overload the
	    #	meaning of numbers in the {records}->{$esn} array to
	    #	count how many times we've tried, and bomb out after
	    #	"too many" tries.
	    $this->_check_slot($records->[$first+$i], $first+$i);
	    $records->[$first+$i] = CALLER_REQUESTED;
	}
    }

    if ($n < $howmany) {
	# We're missing at least one record, which we've marked
	# CALLER_REQUESTED; restart the idle watcher so it issues a
	# new present request at an appropriate point.
	$this->{conn}->{idleWatcher}->start();
    }
}


# PRIVATE to the _new() and _add_record() methods
sub _insert_records {
    my $this = shift();
    my($apdu, $first, $howmany) = @_;
    # $first is 1-based; $howmany is used only when storing NSDs.

    my $esn = $this->option('elementSetName'); ### might this have changed?
    my $records = $this->{records}->{$esn};
    my $rawrecs = $apdu->records();

    # Some badly-behaved servers claim records but don't include any.
    # Fake up an error in this case.
    unless (defined $rawrecs) {
	$rawrecs = bless {
	    diagnosticSetId => '1.2.840.10003.4.1', # BIB-1 diagnostic set
	    condition => 14, # System error in presenting records
	    addinfo => 'No records supplied by server',
	}, 'Net::Z3950::APDU::DefaultDiagFormat';
    }

    if ($rawrecs->isa('Net::Z3950::APDU::DefaultDiagFormat')) {
	# Now what?  We want to report the error back to the caller,
	# but we got here from a callback from the event loop, and
	# we're now miles away from any notional "flow of control"
	# where we could pop up with an error.  Instead, we lodge a
	# copy of this error in the slots for each record requested,
	# so that when the caller invokes record(), we can arrange
	# that we set appropriate error information.
	for (my $i = 0; $i < $howmany; $i++) {
	    $records->[$first+$i] = $rawrecs;
	}
	return 0;
    }

    {
	#   ###	Should deal more gracefully with multiple
	#	non-surrogate diagnostics (Z_Records_multipleNSD)
	my $type = 'Net::Z3950::APDU::NamePlusRecordList';
	if (!$rawrecs->isa($type)) {
	    die "expected $type, got " . ref($rawrecs);
	}
    }

    my $n = @$rawrecs;
    for (my $i = 0; $i < $n; $i++) {
	$this->_check_slot($records->[$first+$i], $first+$i)
	    if $first > 1;		# > 1 => it's a present response

	my $record = $rawrecs->[$i];
	{
	    # Merely a redundant sanity check
	    my $type = 'Net::Z3950::APDU::NamePlusRecord';
	    if (!$record->isa($type)) {
		die "expected $type, got " . ref($record);
	    }
	}

	### We're ignoring databaseName -- do we have any use for it?
	my $which = $record->which();
	if ($which == Net::Z3950::NamePlusRecord::DatabaseRecord) {
	    $records->[$first+$i] = $this->_tweak($record->databaseRecord());
	} elsif ($which == Net::Z3950::NamePlusRecord::SurrogateDiagnostic) {
	    $records->[$first+$i] = $record->surrogateDiagnostic();
	} else {
	    ### Should deal with segmentation fragments
	    die "expected DatabaseRecord, got record-type $which";
	}
    }

    return 1;
}


# PRIVATE to _insert_records()
sub _tweak {
    my($this, $rec) = @_;

    # Ninety-nine times out of a hundred, all we need to do here is
    # return the $rec argument directly, so that the application gets
    # precisely the record returned from the server.  However, a small
    # but significant set of very badly-behaved servers sometimes take
    # it upon themselves to return USMARC records when OPAC records
    # have been requested but there is no holdings information.  For
    # the benefit of those misbegotten monstrosities, we wrap such
    # unwanted USMARC records in an otherwise empty OPAC-record
    # structure.  <sigh>
    if ($this->preferredRecordSyntax() == Net::Z3950::RecordSyntax::OPAC &&
	$rec->isa("Net::Z3950::Record::USMARC")) {
	return bless {
	    bibliographicRecord => $rec,
	    num_holdingsData => 0,
	    holdingsData => [],
	}, "Net::Z3950::Record::OPAC";
    }

    return $rec;
}


# The code is the as for the Connection class's same-named method
sub preferredRecordSyntax {
    return Net::Z3950::Connection::preferredRecordSyntax(@_);
}


# PRIVATE to the _add_records() and _insert_records() methods
sub _check_slot {
    my $this = shift();
    my($rec, $which) = @_;

    if (ref $rec && $rec->isa('Net::Z3950::APDU::DefaultDiagFormat')) {
        my $diag = $rec->condition();
	# Error codes:
	# 238 Record not available in requested syntax
	# 239 Record syntax not supported
	# If this has happened, we don't want to prevent the caller
        # from trying again with a different record syntax.
        return if $diag == 238 || $diag == 239;
	die "re-fetching a record that's already had an error";
    }
    die "presented record $rec already loaded"
	if ref $rec;
    die "server was never asked for presented record"
	if $rec == CALLER_REQUESTED;
    die "user never asked for presented record"
	if !defined $rec;
    die "record is defined but false, which is impossible"
	if !$rec;
    die "weird slot-value $rec"
	if $rec != RS_REQUESTED;
}


# PRIVATE to the _send_presentRequest() and _add_records() methods
#
# These functions encapsulate the scheme used for binding a result-set
# name, the first record requested and the number of records requested
# into a single opaque string, which we then use as a reference Id so
# that it gets passed back to us when the present response arrives
# (otherwise there's no way to know from the response what we asked
# for, and therefore where in the result set to insert the records.)
#
sub _bind_refId {
    my($rsName, $first, $howmany) = @_;
    return $rsName . '-' . $first . '-' . $howmany;
}

sub _unbind_refId {
    my($refId) = @_;
    $refId =~ /(.*)-(.*)-(.*)/;
    return ($1, $2, $3);
}


=head2 records()

	@records = $rs->records();
	foreach $rec (@records) {
	    print $rec->render();
	}

This utility method returns a list of all the records in the result
set I$<rs>.  Because Perl arrays are indexed from zero, the first
record is C<$records[0]>, the second is C<$records[1]>, I<etc.>

If not all the records associated with I<$rs> have yet been
transferred from the server, then they need to be transferred at this
point.  This means that the C<records()> method may block, and so is
not recommended for use in applications that interact with multiple
servers simultaneously.  It does also have the side-effect that
subsequent invocations of the C<record()> method will always
immediately return either a legitimate record or a ``real error''
rather than a ``not yet'' indicator.

If an error occurs, an empty list is returned.  Since this is also
what's returned when the search had zero hits, well-behaved
applications will consult C<$rs->size()> in these circumstances to
determine which of these two conditions pertains.  After an error has
occurred, details may be obtained via the result set's C<errcode()>
and C<addinfo()> methods.

If a non-empty list is returned, then individual elements of that list
may still be undefined, indicating that corresponding record could not
be fetched.  In order to get more information, it's necessary to
attempt to fetch the record using the C<record()> method, then consult
the C<errcode()> and C<addinfo()> methods.

B<Unwarranted personal opinion>: all in all, this method is a pleasant
short-cut for trivial programs to use, but probably carries too many
caveats to be used extensively in serious applications. You may want to
take a look at C<present()> and the C<prefetch> option instead.

B<AS OF RELEASE 0.31, THIS METHOD IS NOW DEPRECATED.
PLEASE USE record() INSTEAD.>

=cut

# We'd like to do this by just returning {records}->{$esn} of course, but
# we can't do that because (A) it's 1-based, and (B) we need undefined
# slots where errors occur rather than error-information APDUs.  So we
# make a copy.
#
#   ###	It would be nice to come up with some cuter logic for when we
#	can fall out of our calling-wait()-to-get-more-records loop,
#	but for now, the trivial keep-going-till-we-have-them-all
#	approach is adequate.
#
#   ###	Does this work?  Does anyone use it?
#
sub records {
    my $this = shift();
    warn "DEPRECATED method records() called on $this";

    my $size = $this->size();
    my $esn = $this->option('elementSetName');
    my $records = $this->{records}->{$esn};

    # Issue requests for any records not already available or requested.
    for (my $i = 0; $i < $size; $i++) {
	if (!defined $records->[$i+1]) {
	    $this->record($i+1); # discard result
	}
    }

    # Wait until all the records are in (or at least errors)
    while (1) {
	my $done = 1;
	for (my $i = 0; $i < $size; $i++) {
	    if (!ref $records->[$i+1]) {
		$done = 0;
		last;
	    }
	}
	last if $done;

	# OK, we have at least one slot in $records which is not a
	# reference either to a legitimate record or to an error
	# APDU, so we need to wait for another server response.
	my $conn = $this->{conn};
	my $c2 = $conn->manager()->wait();
	die "wait() yielded wrong connection"
	    if $c2 ne $conn;
    }

    my @res;
    for (my $i = 0; $i < $size; $i++) {
	my $tmp = $this->record($i+1);
	$res[$i] = $tmp;
    }

    return @res;
}


=head2 delete()

	$ok = $rs->delete();
	if (!$ok) {
		print "can't delete: ", $rs->errmsg(), "\n";
	}

Requests the server to delete the result set corresponding to C<$rs>.
Return non-zero on success, zero on failure.

=cut

sub delete {
    my $this = shift();

    my $errmsg = '';
    my $refId = _bind_refId($this->{rsName}, "delete", 0);
    my $dr = Net::Z3950::makeDeleteRSRequest($refId,
					     $this->{rsName},
					     $errmsg);
    die "can't make delete-RS request: $errmsg" if !defined $dr;
    my $conn = $this->{conn};
    $conn->_enqueue($dr);

    ### The remainder of this method enforces synchronousness
    if (!$conn->expect(Net::Z3950::Op::DeleteRS, "deleteRS")) {
	return undef;
    }

    return $conn->{deleteStatus};
}


=head2 errcode(), addinfo(), errmsg()

	if (!defined $rs->record($i)) {
		print "error ", $rs->errcode(), " (", $rs->errmsg(), ")\n";
		print "additional info: ", $rs->addinfo(), "\n";
	}

When a result set's C<record()> method returns an undefined value,
indicating an error, it also sets into the result set the BIB-1 error
code and additional information returned by the server.  They can be
retrieved via the C<errcode()> and C<addinfo()> methods.

As a convenience, C<$rs->errmsg()> is equivalent to
C<Net::Z3950::errstr($rs->errcode())>.

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


=head2 option()

	$value = $rs->option($type);
	$value = $rs->option($type, $newval);

Returns I<$rs>'s value of the standard option I<$type>, as registered
in I<$rs> itself, in the connection across which it was created, in
the manager which controls that connection, or in the global defaults.

If I<$newval> is specified, then it is set as the new value of that
option in I<$rs>, and the option's old value is returned.

=cut

sub option {
    my $this = shift();
    my($type, $newval) = @_;

    my $value = $this->{options}->{$type};
    if (!defined $value) {
	$value = $this->{conn}->option($type);
    }
    if (defined $newval) {
	$this->{options}->{$type} = $newval;
    }
    return $value
}


=head1 AUTHOR

Mike Taylor E<lt>mike@indexdata.comE<gt>

First version Sunday 28th May 2000.

=cut

1;
