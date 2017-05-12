package Net::Z3950::UDDI::Database;
use strict;
use warnings;

=head1 NAME

Net::Z3950::UDDI::Database - back-end independent database for z2uddi

=head1 SYNOPSIS

 $db = new Net::Z3950::UDDI::Database($dbconfig);
 $map = $db->config()->property("indexmap"); 
 $rs = $db->search($rpn);

=head1 DESCRIPTION

C<Net::Z3950::UDDI::Database> objects represent a connection to
backend database of some kind or another, but hide the details of
whether that database is a SOAP service or a UDDI repostory (or
something else again) by presenting a simple, generic API.

=head1 METHODS

=head2 new()

 $session = new Net::Z3950::UDDI::Database($dbname, $config)

Creates and returns a new session object for the specied user, using
the specified password.  These authentication credentials are optional
if not required by the back-ends accessed by subsequent searches.

The returned object will not be of the C<Database> base-class, but of
one of the subclasses such as C<Database::soap> or C<Database::uddi>.
This selection is made on the basis of the C<type> parameter specified
in the database's C<$config>: a module corresponding to that type is
loaded and invoked.

=cut

sub new {
    my $class = shift();
    my($session, $dbname, $config) = @_;

    my $type = $config->property("type")
	or $session->_throw(1, "no 'type' specified for database '$dbname'");

    eval {
	require "Net/Z3950/UDDI/plugins/$type.pm";
    }; if ($@ && !ref $@ && $@ =~ /^Can.t locate /) {
	$session->_throw(1,
		"no implementation for database type '$type' (db '$dbname')");
    } elsif ($@) {
	die $@;
    }

    my $this = bless {
	session => $session,
	dbname => $dbname,
	config => $config,
    }, $class;

    "Net::Z3950::UDDI::Database::$type"->rebless($this);
    return $this;
}


### Document these

sub session { shift()->{session} }
sub dbname { shift()->{dbname} }
sub config { shift()->{config} }


# Delegate
sub _throw {
    my $this = shift();
    return $this->session()->_throw(@_);
}


=head2 search()

 $rs = $db->search($rpn);

Searches the specified database using the query C<$rpn>, which is a
structure representing a Z39.50 Type-1 query, of the kind passed into
search callback functions by Index Data's SimpleServer.  (That's
convenient!)

Returns a result-set, and object of a subclass of
C<Net::Z3950::UDDI::ResultSet> corresponding to C<$db>'s particular
subclass of C<Net::Z3950::UDDI::Database>

=cut

# Of course, search() is not implemented in this class at all, but
# only by the subclasses.


=head1 SUBCLASSING

I<###> to be written

=head1 SEE ALSO

C<Net::Z3950::UDDI::Session>
is the module that immediately uses this, as it maintains a mapping of
Z39.50 database-names to C<Database> objects.

=head1 AUTHOR, COPYRIGHT AND LICENSE

As for C<Net::Z3950::UDDI>.

=cut

1;
