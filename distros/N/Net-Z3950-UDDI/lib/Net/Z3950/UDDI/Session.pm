package Net::Z3950::UDDI::Session;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use Net::Z3950::UDDI::Database;


=head1 NAME

Net::Z3950::UDDI::Session - client session for z2uddi

=head1 SYNOPSIS

 use Net::Z3950::UDDI::Session;
 $session = new Net::Z3950::UDDI::Session($uddi, $user, $password);
 $nhits = $session->search($config, $dbname, $rpn);

=head1 DESCRIPTION

C<Net::Z3950::UDDI::Session> objects represent the state of a single
client session, i.e. a Z39.50 connection to the gateway.  They are
created when the client's Init request is received, and updated by
subsequent client requests and back-end responses.

=head1 METHODS

=head2 new()

 $session = new Net::Z3950::UDDI::Session($uddi, $user, $password);

Creates and returns a new session object for the specied user, using
the specified password, on behalf of the specified UDDI object.  The
authentication credentials are optional if not required by the
back-ends accessed by subsequent searches.

=cut

sub new {
    my $class = shift();
    my($uddi, $user, $pass) = @_;

    return bless {
	uddi => $uddi,
	connections => {}, # Maps dbname to back-end connection
	resultsets => {},  # Maps result-set name to result-set
	user => $user,
	pass => $pass,
    }, $class;
}


=head2 search()

 $rs = $session->search($dbname, $config, $setname, $rpn);

Performs a search in database named C<$dbname> in the session
C<$session>, reusing an existing database connection if one has
already been created for this session, and creating and caching a new
one otherwise.  In the latter case, C<$config> is used to determine
the type of back-end database to create, among other things.  The
search is for the query specified by the SimpleServer-like RPN
structure C<$rpn>.

Returns a new C<Net::Z3950::ResultSet> object.  Well, actually an
object of one of the back-end-specific subclasses of that class, but
the invoker should not worry about that.  The result is cached under
the specified C<$setname> and can subsequently be retrieved using
C<resultset_by_name()>.

=cut

sub search {
    my $this = shift();
    my($dbname, $config, $setname, $rpn) = @_;

    my $db = $this->database_by_name($dbname, $config);
    my $rs = $db->search($rpn);
    $this->{resultsets}->{$setname} = $rs;
    return $rs;
}


sub database_by_name {
    my $this = shift();
    my($dbname, $config) = @_;

    # Reuse connection objects that have already been made.
    my $db = $this->{connections}->{$dbname};
    if (defined $db) {
	# assert(deep_eq($config, $db->config());
	return $db;
    }

    my $dbconfig = $config->{contents}->{databases}->{$dbname}
	or $this->_throw(235, $dbname);

    $db = new Net::Z3950::UDDI::Database($this, $dbname, $dbconfig);
    $this->{connections}->{$dbname} = $db;
    return $db;
}


=head2 resultset_by_name()

 $rs = $session->resultset_by_name($setname);

Returns the previously generated result-set with the specified name,
or an undefined value if no such result-set exists.

=cut

sub resultset_by_name {
    my $this = shift();
    my($setname) = @_;

    return $this->{resultsets}->{$setname};
}


# Delegate
sub _throw {
    my $this = shift();
    return $this->{uddi}->_throw(@_);
}


=head1 SEE ALSO

C<Net::Z3950::UDDI>
is the module that uses this.

C<z2uddi> is the gateway program that uses C<Net::Z3950::UDDI>.

=head1 AUTHOR, COPYRIGHT AND LICENSE

As for C<Net::Z3950::UDDI>.

=cut

1;
