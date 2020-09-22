# $Id: ResultSet.pm,v 1.21 2009-03-05 17:49:33 mike Exp $

package Net::Z3950::DBIServer::ResultSet;
use  Net::Z3950::DBIServer::Exception;
use strict;

=head1 NAME

Net::Z3950::DBIServer::ResultSet - in-progress result set objects for DBIServer

=head1 SYNOPSIS

	$rs = new Net::Z3950::DBIServer::ResultSet($server, $SQLcond, $config);
	$n = $rs->count();
	for ($i = 0; $i < $n; $i++) {
	    $hashref = $rs->fetch($i);
	}

=head1 DESCRIPTION

Represents a result set in the process of being inspected by a client.
The initial search is executed at construction time, and the number of
record satisfying the condition stored and made available.
Thereafter, records may be fetched via a random-access interface.

In truth, records must be fetched in order - that's how the DBI
interface, and RDBMSs in general work - and that's how we expect
ResultSets to be used most of the time; but we give the illusion
of random access by reading ahead to the required record if asked for
one further ahead than the next in sequence; and by caching a few of the more
recently-read records after reading them, to support requests for
earlier records.  The upshot is that code like

	for ($i = $n-1; $i >= 0; $i--) {
	    $hashref = $rs->fetch($i);
	}

will work provided that I<$n> is not ``too large'', which means larger
than the record cache associated with the result set.  This may be
configured using the configuration file's C<cachesize> directive: the
default value is 10.  If the value is set to zero, this means never to
discard records.

=head1 METHODS

=head2 new()

	$rs = new Net::Z3950::DBIServer::ResultSet($server, $config, $cond);

Creates and returns a new C<ResultSet> on behalf of the DBIServer
object I<$server>, using that server's DBI connection handle,
satisfying the condition I<$cond> and interpreted by the
database-specific configuration segment I<$config>,

I<$config> must be a reference to a
C<Net::Z3950::DBIServer::Config::PerDB> object - one of the objects in
the array returned as a C<Net::Z3950::DBIServer::Config> object from
that class's constructor.

=cut

sub new {
    my $class = shift();
    my($server, $config, $cond) = @_;
    my $dbh = $server->{dbh};
    #warn "server='$server', dbh", defined $dbh ? "='$dbh'" : " undefined";
    my $table = $config->tablename();

    my $aux = $config->auxiliary();
    foreach my $auxspec (@$aux) {
	my $join = $config->join();
	if (defined $join && $join eq "outer") {
	    $table .= (" LEFT OUTER JOIN " . $auxspec->tableName() .
		       " ON " . $auxspec->cond());
	} else {
	    $table .= ", " . $auxspec->tableName();
	    $cond = "($cond) AND (" . $auxspec->cond() . ")";
	}
    }

    # It would be nice to optimise _count() by selecting from a subset
    # of tables and using only those parts of the condition necessary
    # to join the main table to whichever ones are being searched.  In
    # the common case of searching only in the main table, of course,
    # that would mean no linked tables (and no linking conditions).
    # But to do this generally would mean parsing the initial $cond to
    # see which tables are referenced and adding in all the necessary
    # links: complex and error-prone just for an optimisation.  So
    # we'll just use the full condition/links for now.

    #warn "counting '$table' WHERE $cond";
    my $count = _count($server, $table, $cond);

    my @cols = $config->columns();
    #print "*** cols = {\n", join("", map { "\t'$_'\n" } @cols), "}\n";
    my $columns = join(', ', @cols);
    my $sql = "SELECT $columns FROM $table WHERE $cond";
    warn "$sql\n";
    my $sth;
    if (!$server->{noop}) {
	$sth = $dbh->prepare($sql);
	$sth->execute() or
	    die new Net::Z3950::DBIServer::Exception(108, $dbh->errstr(). ": $sql");
    }

    return bless {
	server => $server,
	config => $config,
	count => $count,
	sth => $sth,
	cache => [],
    }, $class;
}


# Here we attempt to discover the number of records satisfying the
# query in as efficient a way as possible.  There's no standard way to
# do this (is there?) so we have to pox about with driver-specific
# code.
#
sub _count {
    my($server, $tables, $cond) = @_;
    my $dbh = $server->{dbh};

    return 9999 if $server->{noop};

    if ($server->dbi_driver() eq "CSV") {
	return _count_by_hand(@_);
    }

    my $sql = "SELECT COUNT(*) FROM $tables WHERE $cond";
    warn $sql;
    my $countref = $dbh->selectall_arrayref($sql);
    if (!defined $countref) {
	# Might be a relatively benign condition like searching for a
	# string value in a numeric field, so be tolerant.  229 (Term
	# type not supported) is appealing, but not really legit,
	# since we don't truthfully know what's gone wrong.
	warn "count: $sql";
	die new Net::Z3950::DBIServer::Exception(108,
						 $dbh->errstr(). ": $sql");
    }

    return $countref->[0]->[0];
}


# Some really brain-dead back-ends -- notably the Nearly Wonderful
# DBD::CSV -- don't support SELECT COUNT(); so we just do the actual
# query twice and damned well count the records.  Obviously very
# inefficient.  So it goes: it'll never happen on a Real Database.
#
sub _count_by_hand {
    my($dbh, $tables, $cond) = @_;

    my $sql = "SELECT * FROM $tables WHERE $cond";
    my $sth = $dbh->prepare($sql);
    if (!defined $sth || !$sth->execute()) {
	die new Net::Z3950::DBIServer::Exception(1, $dbh->errstr());
    }

    my $count = 0;
    while ($sth->fetchrow_array()) {
	$count++;
    }
    return $count;
}


=head2 config()

	$config = $rs->config();

Returns the database-specific configuration segment with which the
result set was created.

=cut

sub config {
    my $this = shift();

    return $this->{config};
}


=head2 count()

	$config = $rs->count();

Returns the number of records in the result set.

=cut

sub count {
    my $this = shift();

    return $this->{count};
}


=head2 fetch()

	$hashref = $rs->fetch($offset);
	foreach $key (keys %$hashref) {
		print($key, "->", $hashref->{$key}, "\n");
	}

Returns a reference to hash mapping fieldnames to values for record
number I<$offset> (counting starts at 0), if that information is
known.  If it can't be obtained (most likely because the underlying
DBI statement handle has already read past the requested record, and
it's fallen out of the result set's cache), then an Exception is
thrown representing BIB-1 diagnostic 33 (``Resources exhausted - valid
subset of results available'').

=cut

sub fetch {
    my $this = shift();
    my($offset) = @_;

    if ($offset < 0 || $offset >= $this->{count}) {
	die new Net::Z3950::DBIServer::Exception(13);
    }

    if ($this->{server}->{noop}) {
	# Sample record knows about specific table structure -- ugh
	return {
	    "author.name" => "T. H. White",
	    "name" => "The Once and Future King",
	};
    }

    my $cache = $this->{cache};
    my $hashref = $cache->[$offset];
    return $hashref
	if defined $hashref;	### INVALID if the configuration has changed

    if ($offset < @$cache) {
	# Request for a record earlier in the set that the last one.
	# We must have had it earlier, but discarded it because the
	# cache was getting too big.  The only way to get it back now
	# would be by re-executing the query, which might yield
	# different results this time around.  Diagnostic 33
	# (Resources exhausted - valid subset of results available) is
	# not perfect, but it's the best I can find.
	die new Net::Z3950::DBIServer::Exception(33);
    }

    my $config = $this->config();
    my $tablename = $config->tablename();
    my $sth = $this->{sth};
    while (@$cache <= $offset) {
	my @columns = $config->columns();
	my @values = $sth->fetchrow_array();
	#warn "got values: " . join('; ', map { DBI::data_string_desc($_) . (defined $_ ? " '$_'" : "") } @values);
	my $hashref;
	while (@columns) {
	    my $col = shift @columns;
	    $col =~ s/^$tablename\.//; # canonicalise fieldnames
	    $hashref->{$col} = shift @values;
	}

	push @$cache, $hashref;

	my $cacheSize = $this->config()->dataSpec()->cacheSize();
	if ($cacheSize != 0 && @$cache > $cacheSize) {
	    my $dropIndex = @$cache-$cacheSize-1;
	    undef $cache->[$dropIndex];
	}
    }

    return $cache->[$offset];
}


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Saturday 23rd February 2002.

=head1 SEE ALSO

C<Net::Z3950::DBIServer>
is the module that uses this.

=cut


1;
