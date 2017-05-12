# $Id: Manager.pm,v 1.25 2004/11/01 09:12:23 mike Exp $

package Net::Z3950::Manager;
use Event;
use strict;


=head1 NAME

Net::Z3950::Manager - State manager for multiple Z39.50 connections.

=head1 SYNOPSIS

	$mgr = new Net::Z3950::Manager(async => 1);
	$conn = $mgr->connect($hostname, $port);
	# Set up some more connections, then:
	while ($conn = $mgr->wait()) {
		# Handle message on $conn
	}

=head1 DESCRIPTION

A manager object encapsulates the Net::Z3950 module's global state -
preferences for search parsing, preferred record syntaxes, compiled
configuration files, I<etc.> - as well as a list of references to all
the open connections.  It main role is to handle multiplexing between
the connections that are opened on it.

We would normally expect there to be just one manager object in a
program, but I suppose there's no reason why you shouldn't make more
if you want.

Simple programs - those which therefore have no requirement for
multiplexing, perhaps because they connect only to a single server -
do not need explicitly to create a manager at all: an anonymous
manager is implicitly created along with the connection.

=head1 METHODS

=cut


# PRIVATE for debugging
sub warnconns {
    return;			# Don't emit this debugging output
    my($this) = shift;
    my($label, @msg) = @_;

    my $c = $this->{connections};
    my $n = @$c;
    warn "$label: $this has $n connections ($c) = { " .
	join(", ", map { "'$_'" } @$c) . " } @msg";

}


=head2 new()

	$mgr = new Net::Z3950::Manager();

Creates and returns a new manager.  Any of the standard options may be
specified as arguments; in addition, the following manager-specific
options are recognised:

=over 4

=item async

This is 0 (false) by default, and may be set to 1 (true).  The mode
affects various details of subsequent behaviour - for example, see the
description of the C<Net::Z3950::Connection> class's C<new()> method.

=back

=cut

sub new {
    my $class = shift();
    # No additional arguments except options

    my $this = bless {
	connections => [],
	options => { @_ },
    }, $class;
    $this->warnconns("creation");
    return $this;
}


=head2 option()

	$value = $mgr->option($type);
	$value = $mgr->option($type, $newval);

Returns I<$mgr>'s value of the standard option I<$type>, as registered
in I<$mgr> or in the global defaults.

If I<$newval> is specified, then it is set as the new value of that
option in I<$mgr>, and the option's old value is returned.

=cut

sub option {
    my $this = shift();
    my($type, $newval) = @_;

    my $value = $this->{options}->{$type};
    if (!defined $value) {
	$value = _default($type);
    }
    if (defined $newval) {
	$this->{options}->{$type} = $newval;
    }
    return $value;
}

# PRIVATE to the option() method
#
# This function specifies the hard-wired global defaults used when
# constructors and the option() method do not override them.
#
#	### Should have POD documentation for these options.  At the
#	moment, the only place they're described is in the tutorial.
#
sub _default {
    my($type) = @_;

    # Used in Net::Z3950::Manager::wait()
    return undef if $type eq 'die_handler';
    return undef if $type eq 'timeout';

    # Used in Net::Z3950::ResultSet::record() to determine whether to wait
    return 0 if $type eq 'async';
    return 'sync' if $type eq 'mode'; # backward-compatible old option

    # Used in Net::Z3950::Connection::new() (for INIT request)
    # (Values are mostly derived from what yaz-client does.)
    return 1024*1024 if $type eq 'preferredMessageSize';
    return 1024*1024 if $type eq 'maximumRecordSize';
    return undef if $type eq 'user';
    return undef if $type eq 'pass';
    return undef if $type eq 'password'; # backward-compatible
    return undef if $type eq 'group';
    return undef if $type eq 'groupid'; # backward-compatible
    # (Compare the next three values with those in "yaz/zutil/zget.c".
    # The standard doesn't give much help, just saying:
    #	3.2.1.1.6 Implementation-id, Implementation-name, and
    #	Implementation-version -- The request or response may
    #	optionally include any of these three parameters. They are,
    #	respectively, an identifier (unique within the client or
    #	server system), descriptive name, and descriptive version, for
    #	the origin or target implementation. These three
    #	implementation parameters are provided solely for the
    #	convenience of implementors, for the purpose of distinguishing
    #	implementations.
    # )
    return 'Mike Taylor (id=169)' if $type eq 'implementationId';
    return 'Net::Z3950.pm (Perl)' if $type eq 'implementationName';
    return $Net::Z3950::VERSION if $type eq 'implementationVersion';
    return undef if $type eq 'charset';
    return undef if $type eq 'language';

    # Used in Net::Z3950::Connection::startSearch()
    return 'prefix' if $type eq 'querytype';
    return 'Default' if $type eq 'databaseName';
    return 0 if $type eq 'smallSetUpperBound';
    return 1 if $type eq 'largeSetLowerBound';
    return 0 if $type eq 'mediumSetPresentNumber';
    return 'F' if $type eq 'smallSetElementSetName';
    return 'B' if $type eq 'mediumSetElementSetName';
    return "GRS-1" if $type eq 'preferredRecordSyntax';

    # Used in Net::Z3950::Connection::startScan()
    return 1 if $type eq 'responsePosition';
    return 0 if $type eq 'stepSize';
    return 20 if $type eq 'numberOfEntries';

    # Used in Net::Z3950::ResultSet::makePresentRequest()
    return 'B' if $type eq 'elementSetName';

    # Assume the server's not brain-dead unless we're told otherwise
    return 1 if $type eq 'namedResultSets';

    # etc.

    # Otherwise it's an unknown option.
    return undef;
}


=head2 connect()

	$conn = $mgr->connect($hostname, $port);

Creates a new connection under the control of the manager I<$mgr>.
The connection will be forged to the server on the specified I<$port>
of <$hostname>.

Additional standard options may be specified after the I<$port>
argument.

(This is simply a sugar function to C<Net::Z3950::Connection->new()>)

=cut

sub connect {
    my $this = shift();
    my($hostname, $port, @other_args) = @_;

    # The "indirect object" notation "new Net::Z3950::Connection" fails if
    # we use it here, because we've not yet seen the Connection
    # module (Net::Z3950.pm use's Manager first, then Connection).  It gets
    # mis-parsed as an application of the new() function to the result
    # of the Connection() function in the Net::Z3950 package (I think) but
    # that error message is immediately further obfuscated by the
    # autoloader (thanks for that), which complains "Can't locate
    # auto/Net::Z3950/Connection.al in @INC".  It took me a _long_ time to
    # grok this ...
    return Net::Z3950::Connection->new($this, $hostname, $port, @other_args);
}


=head2 wait()

	$conn = $mgr->wait();

Waits for an event to occur on one of the connections under the
control of I<$mgr>, yielding control to any other event handlers that
may have been registered with the underlying event loop.

When a suitable event occurs - typically, a response is received to an
earlier INIT, SEARCH or PRESENT - the handle of the connection on
which it occurred is returned: the handle can be further interrogated
with its C<op()> and related methods.

If the wait times out (only possible if the manager's C<timeout>
option has been set), then C<wait()> returns an undefined value.

=cut

sub wait {
    my $this = shift();

    # The next line prevents the Event module from catching our die()
    # calls and turning them into warnings sans bathtub.  By
    # installing this handler, we can get proper death back.
    #
    ###	This is not really the right place to do this, but then where
    #	is?  There's no single main()-like entry-point to this
    #	library, so we may as well set Event's die()-handler just
    #	before we hand over control.
    my $handler = $this->option('die_handler');
    $Event::DIED = defined $handler ? $handler :
	\&Event::verbose_exception_handler;

    my $timeout = $this->option("timeout");
    # Stupid Event::loop() makes a distinction between undef and not there
    my $conn = defined $timeout ? Event::loop($timeout) : Event::loop();
    return ref $conn ? $conn : undef;
}


# PRIVATE to the Net::Z3950::Connection module's new() method
sub _register {
    my $this = shift();
    my($conn) = @_;

    $this->warnconns("pre-register", "adding $conn");
    push @{$this->{connections}}, $conn;
    $this->warnconns("post-register", "added $conn");
}


=head2 connections()

	@conn = $mgr->connections();

Returns a list of all the connections that have been opened under the
control of the manager I<$mgr> and have not subsequently been closed.

=cut

sub _UNUSED_connections {
    my $this = shift();

    return @{$this->{connections}};
}

=head2 resultSets()

	@rs = $mgr->resultSets();

Returns a list of all the result sets that have been created across
the connections associated with the manager I<$mgr> and have not
subsequently been deleted.

=cut

sub resultSets {
    my $this = shift();

    my @rs;

    foreach my $conn ($this->connections()) {
	push @rs, @{$conn->{resultSets}};
    }

    return @rs;
}


### PRIVATE to the Net::Z3950::Connection::close() method.
sub forget {
    my $this = shift();
    my($conn) = @_;

    my $connections = $this->{connections};
    my $n = @$connections;
    $this->warnconns("forget()", "looking for $conn");
    for (my $i = 0; $i < $n; $i++) {
	if (defined $connections->[$i] && $connections->[$i] eq $conn) {
	    $this->warnconns("pre-splice", "forgetting $i of $n");
	    splice @{ $this->{connections} }, $i, 1;
	    $this->warnconns("post-splice", "forgot $i of $n");
	    return;
	}
    }

    # This happens far too often (why?) to be allowed
    #die "$this can't forget $conn";
}


sub DESTROY {
    my $this = shift();

    #warn "destroying Net::Z3950 Connection $this";
}


=head1 AUTHOR

Mike Taylor E<lt>mike@indexdata.comE<gt>

First version Tuesday 23rd May 2000.

=head1 SEE ALSO

List of standard options.

Discussion of the Net::Z3950 module's use of the Event module.

=cut

1;
