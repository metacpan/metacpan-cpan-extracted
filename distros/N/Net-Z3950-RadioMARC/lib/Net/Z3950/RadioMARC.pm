# $Id: RadioMARC.pm,v 1.35 2005/11/14 10:35:26 mike Exp $

package Net::Z3950::RadioMARC;

use 5.008;
use strict;
use warnings;

use Net::Z3950;
use MARC::File::USMARC;
use Net::Z3950::IndexMARC;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(set add dumpindex test);
our $VERSION = '0.07';


=head1 NAME

Net::Z3950::RadioMARC - Perl extension for testing Z39.50 servers

=head1 SYNOPSIS

 use Net::Z3950::RadioMARC;

 $t = new Net::Z3950::RadioMARC();
 $t->set(host => 'z3950.loc.gov', port => '7090', db => 'voyager');
 $t->set(delay => 3);
 $t->add("filename.marc");
 $t->test('@attr 1=4 01245a01', { ok => '245$a is searchable as 1=4',
                                  notfound => 'This server is broken' });
 # -- or --
 set host => 'z3950.loc.gov', port => '7090', db => 'voyager';
 set delay => 3;
 add "filename.marc";
 test '@attr 1=4 01245a01', { ok => '245$a is searchable as 1=4',
                              notfound => 'This server is broken' };

=head1 DESCRIPTION

This module provides the harness in which test-scripts can be written
for detecting the presence of a ``radioactive MARC record'' in a
Z39.50-compliant database, and determining how that database indexes
the record.  Its key provision is the C<test()> method, which runs a
search for some well-known term that is known to occur in a
``radioactive'' record, and generates different output dependent on
whether the record is found or not.

This module may be used in two different ways: the first approach is
to use a rigorous object-oriented syntax in which a test-harness
method is explicitly created, and methods are invoked on it.  The
other is a simpler syntax in which a test-harness object is
transparently created behind the scenes when it's first needed, and
subsequently referenced by function calls.  These two styles are
exemplified by the two code-fragments in the synopsis above.

For most purposes, the simple syntax will be preferable.  The
object-oriented synatx is useful primarily when it is necessary for a
single script to run tests against two or more different databases.

=head2 EXPORT

=over 4

=item The C<set()> method

=item The C<add()> method

=item The C<dumpindex()> method

=item The C<test()> method

=back

=cut


=head1 METHODS

=cut


=head2 new()

 $testHarness = new Net::Z3950::RadioMARC();

Creates a new test-harness for checking the searchability of
``radioactive MARC records'' in a database available via Z39.50.
There are no argument; the new object is returned.

Before the new test-harness can be used by the C<test()> method, at
least its
C<host>
property must be set, and often its
C<port>,
C<db>
and
C<format>
as well.  See the documentation for the <set()> method for details on
how this is done and what the argument mean.

It is not necessary to explicitly create a test-harness object in
order to use this module.  See the describe above of the ``simple
syntax'' approach, in which a test-harness object is implicitly
created.

=cut

sub new {
    my $class = shift();

    return bless {
	properties => {
	    host => undef,
	    port => 210,
	    db => "Default",
	    format => "USMARC",		### or "MARC21": doesn't seem to matter
	    delay => 1,
	    messages => {},
	    verbosity => 1,
	    report => 1,
	    identityField => undef,
	},
	index => new Net::Z3950::IndexMARC(),
	conn => undef,
	query => undef,
	timestamp => undef,
	status => undef,
	errmsg => undef,
	addinfo => undef,
    }, $class;
}


=head2 set()

 $t->set(host => 'z3950.loc.gov', port => '7090', db => 'voyager');
 $t->set(delay => 3);
 # -- or --
 set host => 'z3950.loc.gov', port => '7090', db => 'voyager';
 set delay => 3;

Sets one or more properties of the specified test-harness, or of the
implicit test-harness if none is specified (i.e. when the simple
syntax is used instead of the object-oriented syntax).

Each pair of arguments is taken to be a pair consisting of a property
name and the corresponding new value.  It is an error to provide an
odd number of argument.

The following properties are defined.

=over 4

=item C<host> [no default]

The name or IP address of the Internet host where the Z39.50 server to
be tested resides.  The connection to the host will be forged when the
first test-case is run by means of the C<test()> method.

=item C<port> [default: C<210>]

The port number where the Z39.50 server to be tested resides on the
specified host.

=item C<db> [default: C<"Default">]

The name of the database to be searched.

=item C<format> [default: C<"USMARC">]

The record syntax to be used when fetching records from result sets to
be compared with the known radioactive records.

=item C<delay> [default: C<1>]

The delay, in seconds, between issuing one test search and the next.
This delay is a courtesy to the server, to prevent it from being
overrun by a large test-script.

=item C<messages> [default: an empty hash]

A reference to a hash which maps test status values to message
templates.  These are used to generate the reporting output for tests,
depending on the status returned by the test, except when overridden
by the messages specified for that particular test (see below).

The interpretation of message templates is described in the
documentation of the C<test()> method.  Status values for which no
message template is provided (i.e. all status value initially) are not
reported at all, except for the status C<fail> which is reported using
a simple, explicit default format.

=item C<verbosity> [default: C<1>]

The level at which debugging and other output is emitted.  This may be
set to any integer; all messages at the nominated value I<and less>
are emitted.  These messages, by level, are as follows:

=over 4

=item 0

No debugging output at all.

=item 1

Messages are emitted if a query is used that either matches none of
the records that have been nominated using the C<add()> method, or
matches more than one of these records (in which case the first one to
have been added is used).

Level 1 is the default, since these messages are arguably reporting
configuration errors, whereas the higher levels generate chit-chit
that is is probably only useful for debugging.

=item 2

Messages indicating when the number of hits a query generates in the
remote database is not one, as expected.

=item 3

Messages indicating how many hits each query generated in the remote
database being tested, however many there are.

=item 4

Messages showing each query before it is tested.

=back

=item C<report> [default: C<1>]

A boolean indicating whether or not reporting output (as opposed to
debuggin output) should be emitted for tests.  This should nearly
always be true: the principal use of this property is as an
additional, one-shot property used for a single test, like this:

 ($status, $errmsg, $addinfo) = test '@attr 1=4 fruit', { report => 0 };

which allows the test-script to explicitly check the status and
make whatever choices it deems appropriate without side-effects.

=item C<identityField> [no default]

An indication of what MARC field or subfield is taken to convey the
identity of a 
record for the purposes of comparison.  If a record in a result-set
has the same identity-field value as the radioactive record being
tested, then they are regarded as the same record.

It may take the form I<tag> for control fields (for example C<001> to
specify the local identifier) or I<tag>C<$>I<subfield> (for example
C<245$a> to specify the title field).

Multiple candidate identity fields may be specified, separated by
commas, like this: C<100,035$a>.  In this case, each such candidate
subfield is tried in turn, and the first one that exists in both
records being compared is used.

If no identity field is specified, then two records are considered to
be the same only if they are byte-for-byte identical.

=back

It is an error to try to set a property other than those described
here.

=cut

sub set {
    my $this = shift();
    if (!defined $this || ref($this) ne "Net::Z3950::RadioMARC") {
	unshift @_, $this;
	$this = _defaultSession();
    }

    my $p = $this->{properties};
    while (@_ > 1) {
	my $name = shift();
	my $value = shift();

	die "can't set unknown property '$name' (value '$value')"
	    if !exists $p->{$name};

	$p->{$name} = $value;
    }

    if (@_) {
	warn "extra argument to set(): '" . $_[0] . "'";
    }
}


=head2 add()

 $t->add("filename.marc");
 # -- or --
 add "filename.marc";

Adds one or more MARC records to the set that are to be tested for.
Records are loaded from the file whose name is specified.  Any number
of records may be added to the test-set, but using many such records
may be self-defeating, since then the radioactive tokens to be
searched for are less likely to be unique.

Behind the scenes, this module builds an inverted index of all the
words occurring in all the subfields of all the non-control fields in
all the records that are added.  This is used when C<test()> is called
to identify which of the C<add()>ed records is the one that should be
retrieved from the server.

C<add()> returns a list of opaque tokens representing the newly added
records.  These tokens may be passed as the C<token> parameter into
the C<test()> method to indicate explicitly which of the test-set
records a particular query is intended to find.

=cut

sub add {
    my $this = shift();
    if (!defined $this || ref($this) ne "Net::Z3950::RadioMARC") {
	unshift @_, $this;
	$this = _defaultSession();
    }

    my($filename) = @_;
    my @tokens;

    my $file = MARC::File::USMARC->in($filename);
    die "can't open MARC file '$filename': " . $MARC::File::ERROR
	if !defined $file;
    while (my $marc = $file->next()) {
	my $token = $this->{index}->add($marc);
	push @tokens, $token;
    }

    $file->close();
    return @tokens;
}


=head2 dumpindex()

 $t->dumpindex();

Dumps to standard output the inverted index generated for the MARC
records have been added to the test-set by the C<add()> method.

Never call this method.

=cut

sub dumpindex {
    my $this = shift();
    if (!defined $this || ref($this) ne "Net::Z3950::RadioMARC") {
	unshift @_, $this;
	$this = _defaultSession();
    }

    $this->{index}->dump(\*STDOUT);
}


=head2 test()

 $t->test('@attr 1=4 01245a01', { ok => '245$a is searchable as 1=4',
                                  notfound => 'This server is broken',
                                  token => $token });
 $t->test('@attr 1=4 thrickbrutton');
 # -- or --
 test '@attr 1=4 01245a01', { ok => '245$a is searchable as 1=4',
                              notfound => 'This server is broken',
                              token => $token };
 test '@attr 1=4 thrickbrutton';

Runs a single test against the server that has been nominated for the
specified test-harness.  The first argument is a query in PQF (Prefix
Query Format) as described in the YAZ manual at
http://indexdata.com/yaz/doc/tools.tkl#PQF
and the second (optional) is a reference to hash of parameters, some
of which are used for mapping status values to message templates.

The query is analysed to see which of the test-set records it should
find.  For maximally indicative results, it should match exactly one
such record - no more, no less.  If it matches more than one, the the
first one is used for the subsequent matching process: that is, the
one that occurred earliest in MARC file that first C<add()>ed to the
test-set.  If the parameter C<token> is provided, then its value is
used as the opaque token of the test-set record to be used and the
query is not used for this purpose.

The query is submitted to the server, and returns some number of
hit-set records.  Again, the most significant test results are
obtained when there is exactly one such record.

Each of the candidate hits is compared with the chosen test-set record
to see whether there is match or not - that is, whether the search
retrieved the nominated radioactive record.

The result of this process is that a status is generated, being one of
the following short strings:

=over 4

=item C<ok>

The query succeeded, and a record in the hit-set was the same as the
record chosen from the test-set.

=item C<notfound>

The query succeeded, but no record in the hit-set was the same as the
record chosen from the test-set.  This may occur for several different
reasons: because the query matched no record in the test-set (which is
probably a configuration error); because it matched no record in the
database (which means either that the radioactive record is not in the
database or that it is not indexed in the way being tested for) or
because it found some record in the database, but none of them is the
one that was expected (for the same reasons).

=item C<fail>

The query could not be executed, or the records could not be fetched.

=back

The C<test()> method returns a triple, (C<$status>, C<$errmsg>,
C<$addinfo>), with C<$errmsg> being the human-readable string
corresponding to the BIB-1 diagnostic code returned by the server in
the case of an error, and C<$addinfo> being any additional information
returned by the server along with such a diagnostic.

If the C<report> property of the test-harness is true (as it is by
default), then a report is emitted describing the outcome of the test.
Under some circumstances, it is useful to inhibit this behaviour by
setting C<report> false and testing the explicitly returned values
instead.

The reporting output is generated from a template.  The template is
found by looking up the status of the test in the hash-reference
argument, if this is supplied.  If it is not supplied, or if the
relevant element is missing, it is looked up in the hash that is the
value of the C<message> property.  If the relevant element is not in
this hash either, a default template is used for C<notfound> and
C<fail> tests, but NO OUTPUT AT ALL is emitted for C<ok> test.  This
makes it possible to write silent-on-success test scripts.  If you
want commentary on successful tests, then, you must explicitly specify
an C<ok> message template, either in the C<message> property or in the
hash-reference passed into C<test()>.

Report-generating templates are strings which may contain the
following escape sequences, which are substituted the the appropriate
values:

=over 4

=item %{query}

The query that was run for this test.

=item %{status}

The status of the test.

=item %{errmsg}

The human-readable error message returned from the test, if any.

=item %{addinfo}

The additional information returned from the test, if any.

=back

=cut

sub test {
    my $this = shift();
    if (!defined $this || ref($this) ne "Net::Z3950::RadioMARC") {
	unshift @_, $this;
	$this = _defaultSession();
    }

    my($query, $params) = @_;
    $this->_log(4, "'$query' testing");

    my $delay = $this->_property("delay", $params);
    my $timestamp = $this->{timestamp};
    if (defined $delay && defined $timestamp) {
	my $waituntil = $delay + $timestamp;
	my $now = time();
	sleep ($waituntil-$now) if $waituntil > $now;
    }

    my($token, $entry) = $this->_choose_testset_record($query, $params);
    my($status, $errmsg, $addinfo) =
	$this->_run_query($query, $token, $entry);
    $this->{timestamp} = time();
    $this->{status} = $status;
    $this->{errmsg} = $errmsg;
    $this->{addinfo} = $addinfo;

    if ($this->_property("report", $params)) {
	my $msg = $params->{$status};
	my $defaultmsg = $this->_property("messages")->{$status};

	if (defined $msg) {
	    print $this->_render($msg), "\n";
	} elsif (defined $defaultmsg) {
	    print $this->_render($defaultmsg), "\n";
	} elsif ($status eq "fail") {
	    print "failed";
	    print ", errmsg='$errmsg'" if defined $errmsg;
	    print ", addinfo='$addinfo'" if defined $addinfo;
	    print "\n";
	} else {
	    # In the common special case that the test was run without
	    # error and the message corresponding to the status ("ok"
	    # or "notfound") is undefined, we emit no output at all.
	}
    }

    return wantarray ? ($status, $errmsg, $addinfo): $status;
}


sub _choose_testset_record {
    my $this = shift();
    my($query, $params) = @_;

    my $token = $this->_property("token", $params);
    return ($token, undef)
	if defined $token;

    my $expected = $this->{index}->find($query);
    my $count = keys %$expected;

    if ($count == 0) {
	$this->_log(1, "'$query' matches no record in expected set");
	return (undef, undef);
    }

    $this->_log(1, "'$query' matches $count records in ",
		"expected set - using first")
	if $count > 1;

    my @keys = sort { $a <=> $b } keys %$expected;
    $token = $keys[0];
    return ($token, $expected->{$token});
}


sub _run_query {
    my $this = shift();
    my($query, $token, $entry) = @_;

    my $conn = $this->_connection();
    $this->{query} = $query;
    my $rs = $conn->search($query)
	or return ("fail", $conn->errmsg(), $conn->addinfo());

    ### No way to recognise a "non-diagnostic failure", e.g. timeout

    ### No way to recognise null, test couldn't even be tried

    my $size = $rs->size();
    $this->_log(2, "'$query' found no records")
	if $size == 0;
    $this->_log(2, "'$query' found multiple records ($size)")
	if $size > 1;
    $this->_log(3, "'$query' found $size record", $size == 1 ? "" : "s");

    return "notfound" if !defined $token;
    my $marc = $this->{index}->fetch($token);

    for (my $i = 1; $i <= $size; $i++) {
	my $rec = $rs->record($i)
	    or return ("fail", $conn->errmsg(), $conn->addinfo());
	return ("ok")
	    if $this->_same_record($marc, $rec);
    }
    
    return ("notfound");
}


# PRIVATE to _run_query()
sub _same_record {
    my $this = shift();
    my($marc, $nzrec) = @_;

    my $idfields = $this->_property("identityField");
    if (!defined $idfields) {
	return ($nzrec->render() eq $marc->as_formatted());
    }

    foreach my $idfield (split /,/, $idfields) {
	my $same = $this->_same_field($marc, $nzrec, $idfield);
	return $same if defined $same;
    }

    die("none of the candidate identity fields ".
	join(", ", map { "'$_'" } split /,/, $idfields),
	" exist in both the test-set record and retrieved record");
}


sub _same_field {
    my $this = shift();
    my($marc, $nzrec, $idfield) = @_;

    my($tag, $subtag) = split /\$/, $idfield;
    my $marc2 = MARC::Record->new_from_usmarc($nzrec->rawdata());
    if (!defined $subtag) {
	my $field = $marc->field($tag) or return undef;
	my $field2 = $marc2->field($tag) or return undef;
	return $field->data() eq $field2->data();
    } else {
	my $field = $marc->subfield($tag, $subtag) or return undef;
	my $field2 = $marc2->subfield($tag, $subtag) or return undef;
	return $field eq $field2;
    }
}


# PRIVATE to _defaultSession().  This will be created on demand if the
# non-method version of any of the public methods is called.
use vars qw($_defaultSession);
$_defaultSession = undef;

sub _defaultSession {
    if (!defined $_defaultSession) {
	$_defaultSession = new Net::Z3950::RadioMARC();
    }

    return $_defaultSession;
}


sub _connection {
    my $this = shift();

    if (!defined $this->{conn}) {
	my $host = $this->_property("host");
	my $port = $this->_property("port");
	my $db = $this->_property("db");
	my $format = $this->_property("format");

	die "no host specified" if !defined $host;
	die "no port specified" if !defined $port;
	die "no database specified" if !defined $db;

	$this->{conn} = new Net::Z3950::Connection($host, $port)
	    or die "$host:$port - $!";
	$this->{conn}->option(databaseName => $db);
	$this->{conn}->option(preferredRecordSyntax => $format)
	    if defined $format;
	$this->{conn}->option(elementSetName => 'F');
    }

    return $this->{conn};
}


sub _render {
    my $this = shift();
    my($msg) = @_;

    my $res = "";
    while ($msg =~ s/(.*?)%{(.*?)}//) {
	my $data;
	if ($2 eq 'query') {
	    $data = $this->{query};
	} elsif ($2 eq 'status') {
	    $data = $this->{status};
	} elsif ($2 eq 'errmsg') {
	    $data = $this->{errmsg};
	} elsif ($2 eq 'addinfo') {
	    $data = $this->{addinfo};
	} else {
	    die "message-string uses unrecognised escape %{$2}";
	}

	$res .= $1 . $data;
    }

    return $res . $msg;
}


sub _log {
    my $this = shift();
    my($level, @text) = @_;

    print "log($level): ", @text, "\n"
	if $this->_property("verbosity") >= $level;
}


sub _property {
    my $this = shift();
    my($name, $hashref) = @_;

    if (defined $hashref && defined $hashref->{$name}) {
	return $hashref->{$name};
    }

    return $this->{properties}->{$name};
}


=head1 SEE ALSO

The RadioMARC mailing list, at
http://www.indexdata.dk/mailman/listinfo/radiomarc

I<###>
There ought to be an academic paper giving an overview of the whole
``Radioactive Record'' approach.

I<Creating Radioactive MARC Records and Z Queries Using the MARCdocs Database>
at
http://www.unt.edu/zinterop/Zinterop2Drafts/MARCdocsExtensionForRadMARCQueries22Nov2004.pdf

I<###>
any other information UNT have published on the Web.


=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;
