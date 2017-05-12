use strict;
use warnings;
use IO::File;
use Net::Z3950::ZOOM;


package ZOOM;

# Member naming convention: hash-element names which begin with an
# underscore represent underlying ZOOM-C object descriptors; those
# which lack them represent Perl's ZOOM objects.  (The same convention
# is used in naming local variables where appropriate.)
#
# So, for example, the ZOOM::Connection class has an {_conn} element,
# which is a pointer to the ZOOM-C Connection object; but the
# ZOOM::ResultSet class has a {conn} element, which is a reference to
# the Perl-level Connection object by which it was created.  (It may
# be that we find we have no need for these references, but for now
# they are retained.)
#
# To get at the underlying ZOOM-C connection object of a result-set
# (if you ever needed to do such a thing, which you probably don't)
# you'd use $rs->{conn}->_conn().

# ----------------------------------------------------------------------------

# The "Error" package contains constants returned as error-codes.
package ZOOM::Error;
sub NONE { Net::Z3950::ZOOM::ERROR_NONE }
sub CONNECT { Net::Z3950::ZOOM::ERROR_CONNECT }
sub MEMORY { Net::Z3950::ZOOM::ERROR_MEMORY }
sub ENCODE { Net::Z3950::ZOOM::ERROR_ENCODE }
sub DECODE { Net::Z3950::ZOOM::ERROR_DECODE }
sub CONNECTION_LOST { Net::Z3950::ZOOM::ERROR_CONNECTION_LOST }
sub ZINIT { Net::Z3950::ZOOM::ERROR_INIT }
sub INTERNAL { Net::Z3950::ZOOM::ERROR_INTERNAL }
sub TIMEOUT { Net::Z3950::ZOOM::ERROR_TIMEOUT }
sub UNSUPPORTED_PROTOCOL { Net::Z3950::ZOOM::ERROR_UNSUPPORTED_PROTOCOL }
sub UNSUPPORTED_QUERY { Net::Z3950::ZOOM::ERROR_UNSUPPORTED_QUERY }
sub INVALID_QUERY { Net::Z3950::ZOOM::ERROR_INVALID_QUERY }
sub CQL_PARSE { Net::Z3950::ZOOM::ERROR_CQL_PARSE }
sub CQL_TRANSFORM { Net::Z3950::ZOOM::ERROR_CQL_TRANSFORM }
sub CCL_CONFIG { Net::Z3950::ZOOM::ERROR_CCL_CONFIG }
sub CCL_PARSE { Net::Z3950::ZOOM::ERROR_CCL_PARSE }
# The following are added specifically for this OO interface
sub CREATE_QUERY { 20001 }
sub QUERY_CQL { 20002 }
sub QUERY_PQF { 20003 }
sub SORTBY { 20004 }
sub CLONE { 20005 }
sub PACKAGE { 20006 }
sub SCANTERM { 20007 }
sub LOGLEVEL { 20008 }

# Separate space for CCL errors.  Great.
package ZOOM::CCL::Error;
sub OK { Net::Z3950::ZOOM::CCL_ERR_OK }
sub TERM_EXPECTED { Net::Z3950::ZOOM::CCL_ERR_TERM_EXPECTED }
sub RP_EXPECTED { Net::Z3950::ZOOM::CCL_ERR_RP_EXPECTED }
sub SETNAME_EXPECTED { Net::Z3950::ZOOM::CCL_ERR_SETNAME_EXPECTED }
sub OP_EXPECTED { Net::Z3950::ZOOM::CCL_ERR_OP_EXPECTED }
sub BAD_RP { Net::Z3950::ZOOM::CCL_ERR_BAD_RP }
sub UNKNOWN_QUAL { Net::Z3950::ZOOM::CCL_ERR_UNKNOWN_QUAL }
sub DOUBLE_QUAL { Net::Z3950::ZOOM::CCL_ERR_DOUBLE_QUAL }
sub EQ_EXPECTED { Net::Z3950::ZOOM::CCL_ERR_EQ_EXPECTED }
sub BAD_RELATION { Net::Z3950::ZOOM::CCL_ERR_BAD_RELATION }
sub TRUNC_NOT_LEFT { Net::Z3950::ZOOM::CCL_ERR_TRUNC_NOT_LEFT }
sub TRUNC_NOT_BOTH { Net::Z3950::ZOOM::CCL_ERR_TRUNC_NOT_BOTH }
sub TRUNC_NOT_RIGHT { Net::Z3950::ZOOM::CCL_ERR_TRUNC_NOT_RIGHT }

# The "Event" package contains constants returned by last_event()
package ZOOM::Event;
sub NONE { Net::Z3950::ZOOM::EVENT_NONE }
sub CONNECT { Net::Z3950::ZOOM::EVENT_CONNECT }
sub SEND_DATA { Net::Z3950::ZOOM::EVENT_SEND_DATA }
sub RECV_DATA { Net::Z3950::ZOOM::EVENT_RECV_DATA }
sub TIMEOUT { Net::Z3950::ZOOM::EVENT_TIMEOUT }
sub UNKNOWN { Net::Z3950::ZOOM::EVENT_UNKNOWN }
sub SEND_APDU { Net::Z3950::ZOOM::EVENT_SEND_APDU }
sub RECV_APDU { Net::Z3950::ZOOM::EVENT_RECV_APDU }
sub RECV_RECORD { Net::Z3950::ZOOM::EVENT_RECV_RECORD }
sub RECV_SEARCH { Net::Z3950::ZOOM::EVENT_RECV_SEARCH }
sub ZEND { Net::Z3950::ZOOM::EVENT_END }

# ----------------------------------------------------------------------------

package ZOOM;

sub diag_str {
    my($code) = @_;

    # Special cases for error specific to the OO layer
    if ($code == ZOOM::Error::CREATE_QUERY) {
	return "can't create query object";
    } elsif ($code == ZOOM::Error::QUERY_CQL) {
	return "can't set CQL query";
    } elsif ($code == ZOOM::Error::QUERY_PQF) {
	return "can't set prefix query";
    } elsif ($code == ZOOM::Error::SORTBY) {
	return "can't set sort-specification";
    } elsif ($code == ZOOM::Error::CLONE) {
	return "can't clone record";
    } elsif ($code == ZOOM::Error::PACKAGE) {
	return "can't create package";
    } elsif ($code == ZOOM::Error::SCANTERM) {
	return "can't retrieve term from scan-set";
    } elsif ($code == ZOOM::Error::LOGLEVEL) {
	return "unregistered log-level";
    }

    return Net::Z3950::ZOOM::diag_str($code);
}

sub diag_srw_str {
    my($code) = @_;

    return Net::Z3950::ZOOM::diag_srw_str($code);
}

sub event_str {
    return Net::Z3950::ZOOM::event_str(@_);
}

sub event {
    my($connsref) = @_;

    my @_connsref = map { $_->_conn() } @$connsref;
    return Net::Z3950::ZOOM::event(\@_connsref);
}

sub _oops {
    my($code, $addinfo, $diagset) = @_;

    die new ZOOM::Exception($code, undef, $addinfo, $diagset);
}

# ----------------------------------------------------------------------------

package ZOOM::Exception;

sub new {
    my $class = shift();
    my($code, $message, $addinfo, $diagset) = @_;

    $diagset ||= "ZOOM";
    if (uc($diagset) eq "ZOOM" || uc($diagset) eq "BIB-1") {
	$message ||= ZOOM::diag_str($code);
    } elsif (lc($diagset) eq "info:srw/diagnostic/1") {
	$message ||= ZOOM::diag_srw_str($code);
    } else {
	# Should fill in messages for any other known diagsets.
	$message ||= "(unknown error)";
    }

    return bless {
	code => $code,
	message => $message,
	addinfo => $addinfo,
	diagset => $diagset,
    }, $class;
}

sub code {
    my $this = shift();
    return $this->{code};
}

sub message {
    my $this = shift();
    return $this->{message};
}

sub addinfo {
    my $this = shift();
    return $this->{addinfo};
}

sub diagset {
    my $this = shift();
    return $this->{diagset};
}

sub render {
    my $this = shift();

    my $res = "ZOOM error " . $this->code();
    $res .= ' "' . $this->message() . '"' if $this->message();
    $res .= ' (addinfo: "' . $this->addinfo() . '")' if $this->addinfo();
    $res .= " from diag-set '" . $this->diagset() . "'" if $this->diagset();
    return $res;
}

# This means that untrapped exceptions render nicely.
use overload '""' => \&render;

# ----------------------------------------------------------------------------

package ZOOM::Options;

sub new {
    my $class = shift();
    my($p1, $p2) = @_;

    my $opts;
    if (@_ == 0) {
	$opts = Net::Z3950::ZOOM::options_create();
    } elsif (@_ == 1) {
	$opts = Net::Z3950::ZOOM::options_create_with_parent($p1->_opts());
    } elsif (@_ == 2) {
	$opts = Net::Z3950::ZOOM::options_create_with_parent2($p1->_opts(),
							      $p2->_opts());
    } else {
	die "can't make $class object with more than 2 parents";
    }

    return bless {
	_opts => $opts,
    }, $class;
}

# PRIVATE to this class and ZOOM::Connection::create() and
# ZOOM::Connection::package()
#
sub _opts {
    my $this = shift();

    my $_opts = $this->{_opts};
    die "{_opts} undefined: has this Options block been destroy()ed?"
	if !defined $_opts;

    return $_opts;
}

sub option {
    my $this = shift();
    my($key, $value) = @_;

    my $oldval = Net::Z3950::ZOOM::options_get($this->_opts(), $key);
    Net::Z3950::ZOOM::options_set($this->_opts(), $key, $value)
	if defined $value;

    return $oldval;
}

sub option_binary {
    my $this = shift();
    my($key, $value) = @_;

    my $dummylen = 0;
    my $oldval = Net::Z3950::ZOOM::options_getl($this->_opts(),
						$key, $dummylen);
    Net::Z3950::ZOOM::options_setl($this->_opts(), $key,
				   $value, length($value))
	if defined $value;

    return $oldval;
}

# This is a bit stupid, since the scalar values that Perl returns from
# option() can be used as a boolean; but it's just possible that some
# applications will rely on ZOOM_options_get_bool()'s idiosyncratic
# interpretation of what constitutes truth.
#
sub bool {
    my $this = shift();
    my($key, $default) = @_;

    return Net::Z3950::ZOOM::options_get_bool($this->_opts(), $key, $default);
}

# .. and the next two are even more stupid
sub int {
    my $this = shift();
    my($key, $default) = @_;

    return Net::Z3950::ZOOM::options_get_int($this->_opts(), $key, $default);
}

sub set_int {
    my $this = shift();
    my($key, $value) = @_;

    Net::Z3950::ZOOM::options_set_int($this->_opts(), $key, $value);
}

#   ###	Feel guilty.  Feel very, very guilty.  I've not been able to
#	get the callback memory-management right in "ZOOM.xs", with
#	the result that the values of $function and $udata passed into
#	this function, which are on the stack, have sometimes been
#	freed by the time they're used by __ZOOM_option_callback(),
#	with hilarious results.  To avoid this, I copy the values into
#	module-scoped globals, and pass _those_ into the extension
#	function.  To avoid overwriting those globals by subsequent
#	calls, I keep all the old ones, pushed onto the @_function and
#	@_udata arrays, which means that THIS FUNCTION LEAKS MEMORY
#	LIKE IT'S GOING OUT OF FASHION.  Not nice.  One day, I should
#	fix this, but for now there's more important fish to fry.
#
my(@_function, @_udata);
sub set_callback {
    my $o1 = shift();
    my($function, $udata) = @_;

    push @_function, $function;
    push @_udata, $udata;
    Net::Z3950::ZOOM::options_set_callback($o1->_opts(),
					   $_function[-1], $_udata[-1]);
}

sub destroy {
    my $this = shift();

    Net::Z3950::ZOOM::options_destroy($this->_opts());
    $this->{_opts} = undef;
}


# ----------------------------------------------------------------------------

package ZOOM::Connection;

sub new {
    my $class = shift();
    my($host, $port, @options) = @_;

    my $conn = $class->create(@options);
    $conn->{host} = $host;
    $conn->{port} = $port;

    Net::Z3950::ZOOM::connection_connect($conn->_conn(), $host, $port || 0);
    $conn->_check();

    return $conn;
}

# PRIVATE to this class, to ZOOM::event() and to ZOOM::Query::CQL2RPN::new()
sub _conn {
    my $this = shift();

    my $_conn = $this->{_conn};
    die "{_conn} undefined: has this Connection been destroy()ed?"
	if !defined $_conn;

    return $_conn;
}

sub _check {
    my $this = shift();
    my($always_die_on_error) = @_;

    my($errcode, $errmsg, $addinfo, $diagset) = (undef, "x", "x", "x");
    $errcode = Net::Z3950::ZOOM::connection_error_x($this->_conn(), $errmsg,
						    $addinfo, $diagset);
    if ($errcode) {
	my $exception = new ZOOM::Exception($errcode, $errmsg, $addinfo,
					    $diagset);
	if (!$this->option("async") || $always_die_on_error) {
	    ZOOM::Log::log("zoom_check", "throwing error $exception");
	    die $exception;
	} else {
	    ZOOM::Log::log("zoom_check", "not reporting error $exception");
	}
    }
}

# This wrapper for _check() is called only from outside the ZOOM
# module, and therefore only in situations where an asynchronous
# application is actively asking for an exception to be thrown if an
# error has been detected.  So it passed always_die_on_error=1 to the
# underlying _check() method.
#
sub check {
    my $this = shift();
    return $this->_check(1);
}

sub create {
    my $class = shift();
    my(@options) = @_;

    my $_opts;
    if (@_ == 1) {
	$_opts = $_[0]->_opts();
    } else {
	$_opts = Net::Z3950::ZOOM::options_create();
	while (@options >= 2) {
	    my $key = shift(@options);
	    my $val = shift(@options);
	    Net::Z3950::ZOOM::options_set($_opts, $key, $val);
	}

	die "Odd number of options specified"
	    if @options;
    }

    my $_conn = Net::Z3950::ZOOM::connection_create($_opts);
    my $conn = bless {
	host => undef,
	port => undef,
	_conn => $_conn,
    }, $class;
    return $conn;
}

sub error_x {
    my $this = shift();

    my($errcode, $errmsg, $addinfo, $diagset) = (undef, "dummy", "dummy", "d");
    $errcode = Net::Z3950::ZOOM::connection_error_x($this->_conn(), $errmsg,
						    $addinfo, $diagset);
    return wantarray() ? ($errcode, $errmsg, $addinfo, $diagset) : $errcode;
}

sub exception {
    my $this = shift();

    my($errcode, $errmsg, $addinfo, $diagset) = $this->error_x();
    return undef if $errcode == 0;
    return new ZOOM::Exception($errcode, $errmsg, $addinfo, $diagset);
}

sub errcode {
    my $this = shift();
    return Net::Z3950::ZOOM::connection_errcode($this->_conn());
}

sub errmsg {
    my $this = shift();
    return Net::Z3950::ZOOM::connection_errmsg($this->_conn());
}

sub addinfo {
    my $this = shift();
    return Net::Z3950::ZOOM::connection_addinfo($this->_conn());
}

sub diagset {
    my $this = shift();
    return Net::Z3950::ZOOM::connection_diagset($this->_conn());
}

sub connect {
    my $this = shift();
    my($host, $port) = @_;

    $port = 0 if !defined $port;
    Net::Z3950::ZOOM::connection_connect($this->_conn(), $host, $port);
    $this->_check();
    # No return value
}

sub option {
    my $this = shift();
    my($key, $value) = @_;

    my $oldval = Net::Z3950::ZOOM::connection_option_get($this->_conn(), $key);
    Net::Z3950::ZOOM::connection_option_set($this->_conn(), $key, $value)
	if defined $value;

    return $oldval;
}

sub option_binary {
    my $this = shift();
    my($key, $value) = @_;

    my $dummylen = 0;
    my $oldval = Net::Z3950::ZOOM::connection_option_getl($this->_conn(),
							  $key, $dummylen);
    Net::Z3950::ZOOM::connection_option_setl($this->_conn(), $key,
					     $value, length($value))
	if defined $value;

    return $oldval;
}

sub search {
    my $this = shift();
    my($query) = @_;

    my $_rs = Net::Z3950::ZOOM::connection_search($this->_conn(),
						  $query->_query());
    $this->_check();
    return _new ZOOM::ResultSet($this, $query, $_rs);
}

sub search_pqf {
    my $this = shift();
    my($pqf) = @_;

    my $_rs = Net::Z3950::ZOOM::connection_search_pqf($this->_conn(), $pqf);
    $this->_check();
    return _new ZOOM::ResultSet($this, $pqf, $_rs);
}

sub scan_pqf {
    my $this = shift();
    my($startterm) = @_;

    my $_ss = Net::Z3950::ZOOM::connection_scan($this->_conn(), $startterm);
    $this->_check();
    return _new ZOOM::ScanSet($this, $startterm, $_ss);
}

sub scan {
    my $this = shift();
    my($query) = @_;

    my $_ss = Net::Z3950::ZOOM::connection_scan1($this->_conn(),
						 $query->_query());
    $this->_check();
    return _new ZOOM::ScanSet($this, $query, $_ss);
}

sub package {
    my $this = shift();
    my($options) = @_;

    my $_o = defined $options ? $options->_opts() :
	Net::Z3950::ZOOM::options_create();
    my $_p = Net::Z3950::ZOOM::connection_package($this->_conn(), $_o)
	or ZOOM::_oops(ZOOM::Error::PACKAGE);

    return _new ZOOM::Package($this, $options, $_p);
}

sub last_event {
    my $this = shift();

    return Net::Z3950::ZOOM::connection_last_event($this->_conn());
}

sub is_idle {
    my $this = shift();

    return Net::Z3950::ZOOM::connection_is_idle($this->_conn());
}

sub peek_event {
    my $this = shift();

    return Net::Z3950::ZOOM::connection_peek_event($this->_conn());
}

sub destroy {
    my $this = shift();

    Net::Z3950::ZOOM::connection_destroy($this->_conn());
    $this->{_conn} = undef;
}


# ----------------------------------------------------------------------------

package ZOOM::Query;

sub new {
    my $class = shift();
    die "You can't create $class objects: it's a virtual base class";
}

# PRIVATE to this class and ZOOM::Connection::search()
sub _query {
    my $this = shift();

    my $_query = $this->{_query};
    die "{_query} undefined: has this Query been destroy()ed?"
	if !defined $_query;

    return $_query;
}

sub sortby {
    my $this = shift();
    my($sortby) = @_;

    Net::Z3950::ZOOM::query_sortby($this->_query(), $sortby) == 0
	or ZOOM::_oops(ZOOM::Error::SORTBY, $sortby);
}

sub sortby2 {
    my $this = shift();
    my($strategy, $sortby) = @_;

    Net::Z3950::ZOOM::query_sortby2($this->_query(), $strategy, $sortby) == 0
	or ZOOM::_oops(ZOOM::Error::SORTBY, $sortby);
}

sub destroy {
    my $this = shift();

    Net::Z3950::ZOOM::query_destroy($this->_query());
    $this->{_query} = undef;
}


package ZOOM::Query::CQL;
our @ISA = qw(ZOOM::Query);

sub new {
    my $class = shift();
    my($string) = @_;

    my $q = Net::Z3950::ZOOM::query_create()
	or ZOOM::_oops(ZOOM::Error::CREATE_QUERY);
    Net::Z3950::ZOOM::query_cql($q, $string) == 0
	or ZOOM::_oops(ZOOM::Error::QUERY_CQL, $string);

    return bless {
	_query => $q,
    }, $class;
}


package ZOOM::Query::CQL2RPN;
our @ISA = qw(ZOOM::Query);

sub new {
    my $class = shift();
    my($string, $conn) = @_;

    my $q = Net::Z3950::ZOOM::query_create()
	or ZOOM::_oops(ZOOM::Error::CREATE_QUERY);
    # check() throws the exception we want; but we only want it on failure!
    Net::Z3950::ZOOM::query_cql2rpn($q, $string, $conn->_conn()) == 0
	or $conn->_check();

    return bless {
	_query => $q,
    }, $class;
}


# We have to work around the retarded ZOOM_query_ccl2rpn() API
package ZOOM::Query::CCL2RPN;
our @ISA = qw(ZOOM::Query);

sub new {
    my $class = shift();
    my($string, $conn) = @_;

    my $q = Net::Z3950::ZOOM::query_create()
	or ZOOM::_oops(ZOOM::Error::CREATE_QUERY);

    my $config = $conn->option("cclqual");
    if (!defined $config) {
	my $cclfile = $conn->option("cclfile")
	    or ZOOM::_oops(ZOOM::Error::CCL_CONFIG,
			   "no 'cclqual' or 'cclfile' specified");
	my $fh = new IO::File("<$cclfile")
	    or ZOOM::_oops(ZOOM::Error::CCL_CONFIG,
			   "can't open cclfile '$cclfile': $!");
	$config = join("", <$fh>);
	$fh->close();
    }

    my($ccl_errcode, $ccl_errstr, $ccl_errpos) = (0, "", 0);
    if (Net::Z3950::ZOOM::query_ccl2rpn($q, $string, $config,
					$ccl_errcode, $ccl_errstr,
					$ccl_errpos) < 0) {
	# We have no use for $ccl_errcode or $ccl_errpos
	ZOOM::_oops(ZOOM::Error::CCL_PARSE, $ccl_errstr);
    }

    return bless {
	_query => $q,
    }, $class;
}


package ZOOM::Query::PQF;
our @ISA = qw(ZOOM::Query);

sub new {
    my $class = shift();
    my($string) = @_;

    my $q = Net::Z3950::ZOOM::query_create()
	or ZOOM::_oops(ZOOM::Error::CREATE_QUERY);
    Net::Z3950::ZOOM::query_prefix($q, $string) == 0
	or ZOOM::_oops(ZOOM::Error::QUERY_PQF, $string);

    return bless {
	_query => $q,
    }, $class;
}


# ----------------------------------------------------------------------------

package ZOOM::ResultSet;

sub new {
    my $class = shift();
    die "You can't create $class objects directly";
}

# PRIVATE to ZOOM::Connection::search() and ZOOM::Connection::search_pqf()
sub _new {
    my $class = shift();
    my($conn, $query, $_rs) = @_;

    return bless {
	conn => $conn,
	query => $query,	# This is not currently used, which is
				# just as well since it could be
				# either a string (when the RS is
				# created with search_pqf()) or a
				# ZOOM::Query object (when it's
				# created with search())
	_rs => $_rs,
    }, $class;
}

# PRIVATE to this class
sub _rs {
    my $this = shift();

    my $_rs = $this->{_rs};
    die "{_rs} undefined: has this ResultSet been destroy()ed?"
	if !defined $_rs;

    return $_rs;
}

sub option {
    my $this = shift();
    my($key, $value) = @_;

    my $oldval = Net::Z3950::ZOOM::resultset_option_get($this->_rs(), $key);
    Net::Z3950::ZOOM::resultset_option_set($this->_rs(), $key, $value)
	if defined $value;

    return $oldval;
}

sub size {
    my $this = shift();

    return Net::Z3950::ZOOM::resultset_size($this->_rs());
}

sub record {
    my $this = shift();
    my($which) = @_;

    my $_rec = Net::Z3950::ZOOM::resultset_record($this->_rs(), $which);
    $this->{conn}->_check();

    # Even if no error has occurred, I think record() might
    # legitimately return undef if we're running in asynchronous mode
    # and the record just hasn't been retrieved yet.  This goes double
    # for record_immediate().
    return undef if !defined $_rec;

    # For some reason, I have to use the explicit "->" syntax in order
    # to invoke the ZOOM::Record constructor here, even though I don't
    # have to do the same for _new ZOOM::ResultSet above.  Weird.
    return ZOOM::Record->_new($this, $which, $_rec);
}

sub record_immediate {
    my $this = shift();
    my($which) = @_;

    my $_rec = Net::Z3950::ZOOM::resultset_record_immediate($this->_rs(),
							    $which);
    $this->{conn}->_check();
    # The record might legitimately not be there yet
    return undef if !defined $_rec;

    return ZOOM::Record->_new($this, $which, $_rec);
}

sub cache_reset {
    my $this = shift();

    Net::Z3950::ZOOM::resultset_cache_reset($this->_rs());
}

sub records {
    my $this = shift();
    my($start, $count, $return_records) = @_;

    # If the request is out of range, ZOOM-C will currently (as of YAZ
    # 2.1.38) no-op: it understandably refuses to build and send a
    # known-bad APDU, but it doesn't set a diagnostic as it ought.  So
    # for now, we do it here.  It would be more polite to stash the
    # error-code in the ZOOM-C connection object for subsequent
    # discovery (which is what ZOOM-C will presumably do itself when
    # it's fixed) but since there is no API that allows us to do that,
    # we just have to throw the exception right now.  That's probably
    # OK for synchronous applications, but not really for
    # multiplexers.
    my $size = $this->size();
    if ($start + $count-1 >= $size) {
	# BIB-1 diagnostic 13 is "Present request out-of-range"
	ZOOM::_oops(13, undef, "BIB-1");
    }

    my $raw = Net::Z3950::ZOOM::resultset_records($this->_rs(), $start, $count,
						  $return_records);
    # By design, $raw may be undefined (if $return_records is true)
    return undef if !defined $raw;

    # We need to package up the returned records in ZOOM::Record objects
    my @res = ();
    for my $i (0 .. @$raw-1) {
	my $_rec = $raw->[$i];
	if (!defined $_rec) {
	    push @res, undef;
	} else {
	    push @res, ZOOM::Record->_new($this, $start+$i, $_rec);
	}
    }

    return \@res;
}

sub sort {
    my $this = shift();
    my($sort_type, $sort_spec) = @_;

    return Net::Z3950::ZOOM::resultset_sort1($this->_rs(),
					     $sort_type, $sort_spec);
}

sub destroy {
    my $this = shift();

    Net::Z3950::ZOOM::resultset_destroy($this->_rs());
    $this->{_rs} = undef;
}


# ----------------------------------------------------------------------------

package ZOOM::Record;

sub new {
    my $class = shift();
    die "You can't create $class objects directly";
}

# PRIVATE to ZOOM::ResultSet::record(),
# ZOOM::ResultSet::record_immediate(), ZOOM::ResultSet::records() and
# ZOOM::Record::clone()
#
sub _new {
    my $class = shift();
    my($rs, $which, $_rec) = @_;

    return bless {
	rs => $rs,
	which => $which,
	_rec => $_rec,
    }, $class;
}

# PRIVATE to this class
sub _rec {
    my $this = shift();

    my $_rec = $this->{_rec};
    die "{_rec} undefined: has this Record been destroy()ed?"
	if !defined $_rec;

    return $_rec;
}

sub error {
    my $this = shift();

    my($errcode, $errmsg, $addinfo, $diagset) = (undef, "dummy", "dummy", "d");
    $errcode = Net::Z3950::ZOOM::record_error($this->_rec(), $errmsg,
					      $addinfo, $diagset);

    return wantarray() ? ($errcode, $errmsg, $addinfo, $diagset) : $errcode;
}

sub exception {
    my $this = shift();

    my($errcode, $errmsg, $addinfo, $diagset) = $this->error();
    return undef if $errcode == 0;
    return new ZOOM::Exception($errcode, $errmsg, $addinfo, $diagset);
}


sub render {
    my $this = shift();

    return $this->get("render", @_);
}

sub raw {
    my $this = shift();

    return $this->get("raw", @_);
}

sub get {
    my $this = shift();
    my($type, $args) = @_;

    $type = "$type;$args" if defined $args;
    return Net::Z3950::ZOOM::record_get($this->_rec(), $type);
}

sub clone {
    my $this = shift();

    my $raw = Net::Z3950::ZOOM::record_clone($this->_rec())
	or ZOOM::_oops(ZOOM::Error::CLONE);

    # Arg 1 (rs) is undefined as the new record doesn't belong to an RS
    return _new ZOOM::Record(undef, undef, $raw);
}

sub destroy {
    my $this = shift();

    Net::Z3950::ZOOM::record_destroy($this->_rec());
    $this->{_rec} = undef;
}


# ----------------------------------------------------------------------------

package ZOOM::ScanSet;

sub new {
    my $class = shift();
    die "You can't create $class objects directly";
}

# PRIVATE to ZOOM::Connection::scan(),
sub _new {
    my $class = shift();
    my($conn, $startterm, $_ss) = @_;

    return bless {
	conn => $conn,
	startterm => $startterm,# This is not currently used, which is
				# just as well since it could be
				# either a string (when the SS is
				# created with scan()) or a
				# ZOOM::Query object (when it's
				# created with scan1())
	_ss => $_ss,
    }, $class;
}

# PRIVATE to this class
sub _ss {
    my $this = shift();

    my $_ss = $this->{_ss};
    die "{_ss} undefined: has this ScanSet been destroy()ed?"
	if !defined $_ss;

    return $_ss;
}

sub option {
    my $this = shift();
    my($key, $value) = @_;

    my $oldval = Net::Z3950::ZOOM::scanset_option_get($this->_ss(), $key);
    Net::Z3950::ZOOM::scanset_option_set($this->_ss(), $key, $value)
	if defined $value;

    return $oldval;
}

sub size {
    my $this = shift();

    return Net::Z3950::ZOOM::scanset_size($this->_ss());
}

sub term {
    my $this = shift();
    my($which) = @_;

    my($occ, $len) = (0, 0);
    my $term = Net::Z3950::ZOOM::scanset_term($this->_ss(), $which,
					      $occ, $len)
	or ZOOM::_oops(ZOOM::Error::SCANTERM);

    die "length of term '$term' differs from returned len=$len"
	if length($term) != $len;

    return ($term, $occ);
}

sub display_term {
    my $this = shift();
    my($which) = @_;

    my($occ, $len) = (0, 0);
    my $term = Net::Z3950::ZOOM::scanset_display_term($this->_ss(), $which,
						      $occ, $len)
	or ZOOM::_oops(ZOOM::Error::SCANTERM);

    die "length of display term '$term' differs from returned len=$len"
	if length($term) != $len;

    return ($term, $occ);
}

sub destroy {
    my $this = shift();

    Net::Z3950::ZOOM::scanset_destroy($this->_ss());
    $this->{_ss} = undef;
}


# ----------------------------------------------------------------------------

package ZOOM::Package;

sub new {
    my $class = shift();
    die "You can't create $class objects directly";
}

# PRIVATE to ZOOM::Connection::package(),
sub _new {
    my $class = shift();
    my($conn, $options, $_p) = @_;

    return bless {
	conn => $conn,
	options => $options,
	_p => $_p,
    }, $class;
}

# PRIVATE to this class
sub _p {
    my $this = shift();

    my $_p = $this->{_p};
    die "{_p} undefined: has this Package been destroy()ed?"
	if !defined $_p;

    return $_p;
}

sub option {
    my $this = shift();
    my($key, $value) = @_;

    my $oldval = Net::Z3950::ZOOM::package_option_get($this->_p(), $key);
    Net::Z3950::ZOOM::package_option_set($this->_p(), $key, $value)
	if defined $value;

    return $oldval;
}

sub send {
    my $this = shift();
    my($type) = @_;

    Net::Z3950::ZOOM::package_send($this->_p(), $type);
    $this->{conn}->_check();
}

sub destroy {
    my $this = shift();

    Net::Z3950::ZOOM::package_destroy($this->_p());
    $this->{_p} = undef;
}


# There follows trivial support for YAZ logging.  This is wired out
# into the Net::Z3950::ZOOM package, and we here provide wrapper
# functions -- nothing more than aliases, really -- in the ZOOM::Log
# package.  There really is no point in inventing an OO interface.
#
# Passing @_ directly to the underlying Net::Z3950::ZOOM::* functions
# doesn't work, for reasons that I can't begin to fathom, and that
# don't particularly interest me.  Unpacking into scalars and passing
# those _does_ work, so that's what we do.

package ZOOM::Log;

sub mask_str      { my($a) = @_; Net::Z3950::ZOOM::yaz_log_mask_str($a); }
sub module_level  { my($a) = @_; Net::Z3950::ZOOM::yaz_log_module_level($a); }
sub init          { my($a, $b, $c) = @_;
		    Net::Z3950::ZOOM::yaz_log_init($a, $b, $c) }
sub init_file     { my($a) = @_; Net::Z3950::ZOOM::yaz_log_init_file($a) }
sub init_level    { my($a) = @_; Net::Z3950::ZOOM::yaz_log_init_level($a) }
sub init_prefix   { my($a) = @_; Net::Z3950::ZOOM::yaz_log_init_prefix($a) }
sub time_format   { my($a) = @_; Net::Z3950::ZOOM::yaz_log_time_format($a) }
sub init_max_size { my($a) = @_; Net::Z3950::ZOOM::yaz_log_init_max_size($a) }

sub log {
    my($level, @message) = @_;

    if ($level !~ /^(0x)?\d+$/) {
	# Assuming its log-level name, we look it up.
	my $num = module_level($level);
	ZOOM::_oops(ZOOM::Error::LOGLEVEL, $level)
	    if $num == 0;
	$level = $num;
    }

    Net::Z3950::ZOOM::yaz_log($level, join("", @message));
}

BEGIN { ZOOM::Log::mask_str("zoom_check"); }

1;
