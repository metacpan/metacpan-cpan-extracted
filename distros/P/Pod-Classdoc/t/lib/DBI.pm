# $Id: DBI.pm 9678 2007-06-25 21:49:03Z timbo $
# vim: ts=8:sw=4
#
# Copyright (c) 1994-2007  Tim Bunce  Ireland
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#

require 5.006_00;

BEGIN {
$DBI::VERSION = "1.58"; # ==> ALSO update the version in the pod text below!
}

=pod

=begin classdoc

Perl Database Interface. Base class for Perl's standard database access
API.

@author <a href='http://www.linkedin.com/in/timbunce'>Tim Bunce</a>
@since 1994-01-01
@see  <a href='http://dbi.perl.org/'>DBI Homepage</a>
@see <a href='http://books.perl.org/book/154'>Programming the Perl DBI</a> by Alligator Descartes and Tim Bunce.


@exports :sql_types		List of standard SQL type names, mapped to their ISO-XXX values
@exports :sql_cursor_types List of standard SQL cursor types, mapped to the ISO-XXX values
@member $DBI::err	Equivalent to <code>$h-&gt;err</code>.
@member $DBI::errstr Equivalent to <code>$h-&gt;errstr</code>.
@member $DBI::state Equivalent to <code>$h-&gt;state</code>.
@member $DBI::rows Equivalent to <code>$h-&gt;rows</code>.
@member $DBI::lasth DBI object handle used for the most recent DBI method call.
	If the last DBI method call was DESTROY, returns the destroyed handle's parent.

=end classdoc

=cut

package DBI;

use Carp();
use DynaLoader ();
use Exporter ();

BEGIN {
@ISA = qw(Exporter DynaLoader);

# Make some utility functions available if asked for
@EXPORT    = ();		    # we export nothing by default
@EXPORT_OK = qw(%DBI %DBI_methods hash); # also populated by export_ok_tags:
%EXPORT_TAGS = (
   sql_types => [ qw(
	SQL_GUID
	SQL_WLONGVARCHAR
	SQL_WVARCHAR
	SQL_WCHAR
	SQL_BIGINT
	SQL_BIT
	SQL_TINYINT
	SQL_LONGVARBINARY
	SQL_VARBINARY
	SQL_BINARY
	SQL_LONGVARCHAR
	SQL_UNKNOWN_TYPE
	SQL_ALL_TYPES
	SQL_CHAR
	SQL_NUMERIC
	SQL_DECIMAL
	SQL_INTEGER
	SQL_SMALLINT
	SQL_FLOAT
	SQL_REAL
	SQL_DOUBLE
	SQL_DATETIME
	SQL_DATE
	SQL_INTERVAL
	SQL_TIME
	SQL_TIMESTAMP
	SQL_VARCHAR
	SQL_BOOLEAN
	SQL_UDT
	SQL_UDT_LOCATOR
	SQL_ROW
	SQL_REF
	SQL_BLOB
	SQL_BLOB_LOCATOR
	SQL_CLOB
	SQL_CLOB_LOCATOR
	SQL_ARRAY
	SQL_ARRAY_LOCATOR
	SQL_MULTISET
	SQL_MULTISET_LOCATOR
	SQL_TYPE_DATE
	SQL_TYPE_TIME
	SQL_TYPE_TIMESTAMP
	SQL_TYPE_TIME_WITH_TIMEZONE
	SQL_TYPE_TIMESTAMP_WITH_TIMEZONE
	SQL_INTERVAL_YEAR
	SQL_INTERVAL_MONTH
	SQL_INTERVAL_DAY
	SQL_INTERVAL_HOUR
	SQL_INTERVAL_MINUTE
	SQL_INTERVAL_SECOND
	SQL_INTERVAL_YEAR_TO_MONTH
	SQL_INTERVAL_DAY_TO_HOUR
	SQL_INTERVAL_DAY_TO_MINUTE
	SQL_INTERVAL_DAY_TO_SECOND
	SQL_INTERVAL_HOUR_TO_MINUTE
	SQL_INTERVAL_HOUR_TO_SECOND
	SQL_INTERVAL_MINUTE_TO_SECOND
   ) ],
   sql_cursor_types => [ qw(
	 SQL_CURSOR_FORWARD_ONLY
	 SQL_CURSOR_KEYSET_DRIVEN
	 SQL_CURSOR_DYNAMIC
	 SQL_CURSOR_STATIC
	 SQL_CURSOR_TYPE_DEFAULT
   ) ], # for ODBC cursor types
   utils     => [ qw(
	neat neat_list $neat_maxlen dump_results looks_like_number
	data_string_diff data_string_desc data_diff
   ) ],
   profile   => [ qw(
	dbi_profile dbi_profile_merge dbi_profile_merge_nodes dbi_time
   ) ], # notionally "in" DBI::Profile and normally imported from there
);

$DBI::dbi_debug = 0;
$DBI::neat_maxlen = 400;

# If you get an error here like "Can't find loadable object ..."
# then you haven't installed the DBI correctly. Read the README
# then install it again.
if ( $ENV{DBI_PUREPERL} ) {
    eval { bootstrap DBI } if       $ENV{DBI_PUREPERL} == 1;
    require DBI::PurePerl  if $@ or $ENV{DBI_PUREPERL} >= 2;
    $DBI::PurePerl ||= 0; # just to silence "only used once" warnings
}
else {
    bootstrap DBI;
}

$EXPORT_TAGS{preparse_flags} = [ grep { /^DBIpp_\w\w_/ } keys %{__PACKAGE__."::"} ];

Exporter::export_ok_tags(keys %EXPORT_TAGS);

}

=pod

=begin classdoc

@xs trace

Set the <i>global default</i> trace settings. 
Also can be used to change where trace output is sent.
<p>
A similar method, <code>$h-&gt;trace</code>, sets the trace
settings for the specific handle it's called on.

@see <cpan>DBI</cpan> manual TRACING section for full details about DBI's
tracing facilities.

@param $trace_setting	a numeric value indicating a trace level. Valid trace levels are:
<ul>
<li>0 - Trace disabled.
<li>1 - Trace DBI method calls returning with results or errors.
<li>2 - Trace method entry with parameters and returning with results.
<li>3 - As above, adding some high-level information from the driver
      and some internal information from the DBI.
<li>4 - As above, adding more detailed information from the driver.
<li>5 to 15 - As above but with more and more obscure information.
</ul>

@optional $trace_file	either a string filename, or a Perl filehandle reference, to which
	trace output is to be appended. If not spcified, traces are sent to <code>STDOUT</code>.

@return the previous $trace_setting value

=end classdoc

=begin classdoc

@xs trace_msg

Write a message to the trace output.

@param $message_text message to be written
$optional $min_level	the minimum trace level at which the message is written; default 1

@see <cpan>DBI</cpan> manual TRACING section for full details about DBI's
tracing facilities.

=end classdoc

=begin classdoc

@xs neat

Return a string containing a neat (and tidy) representation of the
supplied value.
<p>
Strings will be quoted, although internal quotes will <i>not</i> be escaped.
Values known to be numeric will be unquoted. Undefined (NULL) values
will be shown as <code>undef</code> (without quotes).
<p>
If the string is flagged internally as UTF-8 then double quotes will
be used, otherwise single quotes are used and unprintable characters
will be replaced by dot (.).
<p>
This function is designed to format values for human consumption.
It is used internally by the DBI for <method>trace</method> output. It should
typically <i>not</i> be used for formatting values for database use.
(See also <method>quote</method>.)

@static
@param $value	the string to be formatted
@optional $maxlen	if specified, the result string will be
	truncated to <code>$maxlen-4</code> and "<code>...'</code>" will be appended.  If <code>$maxlen</code> is 0
	or <code>undef</code>, it defaults to <code>$DBI::neat_maxlen</code> which, in turn, defaults to 400.
@return the neatly formatted string

=end classdoc

=begin classdoc

@xs looks_like_number

Do the parameter values look like numbers ?

@static
@param @array	array of values to check for numbers
@returnlist true for each element that looks like a number,
	false for each element that does not look like a number, and
	<code>undef</code> for each element that is undefined or empty.

=end classdoc

=begin classdoc

@xs hash

Return a 32-bit integer 'hash' value computed over the contents of $buffer
using the $type hash algorithm.

@static
@param $buffer		buffer over which the hash is computed
@optional $type		hash algorithm to use. Valid values are
<ul>
<li>0 - (the default) based on the Perl 5.1 hash, except that the value
is forced to be negative (for obscure historical reasons).
<li>1 - the better "Fowler / Noll / Vo" (FNV) hash. 
</ul>

@see <a href='http://www.isthe.com/chongo/tech/comp/fnv/'>Type 1 hash information</a>.
@return the hashvalue

=end classdoc

=cut

# Alias some handle methods to also be DBI class methods
for (qw(trace_msg set_err parse_trace_flag parse_trace_flags)) {
  no strict;
  *$_ = \&{"DBD::_::common::$_"};
}

use strict;

DBI->trace(split /=/, $ENV{DBI_TRACE}, 2) if $ENV{DBI_TRACE};

$DBI::connect_via ||= "connect";

# check if user wants a persistent database connection ( Apache + mod_perl )
if ($INC{'Apache/DBI.pm'} && $ENV{MOD_PERL}) {
    $DBI::connect_via = "Apache::DBI::connect";
    DBI->trace_msg("DBI connect via $DBI::connect_via in $INC{'Apache/DBI.pm'}\n");
}

# check for weaken support, used by ChildHandles
my $HAS_WEAKEN = eval {
    require Scalar::Util;
    # this will croak() if this Scalar::Util doesn't have a working weaken().
    Scalar::Util::weaken( \my $test ); # same test as in t/72childhandles.t
    1;
};

%DBI::installed_drh = ();  # maps driver names to installed driver handles

=pod

=begin classdoc

Return a list of driver name and driver handle pairs for all drivers
'installed' (loaded) into the current process.  The driver name does not
include the 'DBD::' prefix.

@see <method>available_drivers</method> to get a list of all 
	<i>available</i> drivers in your perl installation.

@returnlist	driver name => driver handle pairs for installed drivers.

@since 1.49.

=end classdoc

=cut

sub installed_drivers { %DBI::installed_drh }

%DBI::installed_methods = (); # XXX undocumented, may change
sub installed_methods { %DBI::installed_methods }

# Setup special DBI dynamic variables. See DBI::var::FETCH for details.
# These are dynamically associated with the last handle used.
tie $DBI::err,    'DBI::var', '*err';    # special case: referenced via IHA list
tie $DBI::state,  'DBI::var', '"state';  # special case: referenced via IHA list
tie $DBI::lasth,  'DBI::var', '!lasth';  # special case: return boolean
tie $DBI::errstr, 'DBI::var', '&errstr'; # call &errstr in last used pkg
tie $DBI::rows,   'DBI::var', '&rows';   # call &rows   in last used pkg
sub DBI::var::TIESCALAR{ my $var = $_[1]; bless \$var, 'DBI::var'; }
sub DBI::var::STORE    { Carp::croak("Can't modify \$DBI::${$_[0]} special variable") }

{   # used to catch DBI->{Attrib} mistake
    sub DBI::DBI_tie::TIEHASH { bless {} }
    sub DBI::DBI_tie::STORE   { Carp::carp("DBI->{$_[1]} is invalid syntax (you probably want \$h->{$_[1]})");}
    *DBI::DBI_tie::FETCH = \&DBI::DBI_tie::STORE;
}
tie %DBI::DBI => 'DBI::DBI_tie';

# --- Driver Specific Prefix Registry ---

my $dbd_prefix_registry = {
  ad_      => { class => 'DBD::AnyData',	},
  ado_     => { class => 'DBD::ADO',		},
  amzn_    => { class => 'DBD::Amazon',		},
  best_    => { class => 'DBD::BestWins',	},
  csv_     => { class => 'DBD::CSV',		},
  db2_     => { class => 'DBD::DB2',		},
  dbi_     => { class => 'DBI',			},
  dbm_     => { class => 'DBD::DBM',		},
  df_      => { class => 'DBD::DF',		},
  f_       => { class => 'DBD::File',		},
  file_    => { class => 'DBD::TextFile',	},
  go_      => { class => 'DBD::Gofer',  	},
  ib_      => { class => 'DBD::InterBase',	},
  ing_     => { class => 'DBD::Ingres',		},
  ix_      => { class => 'DBD::Informix',	},
  jdbc_    => { class => 'DBD::JDBC',		},
  monetdb_ => { class => 'DBD::monetdb',	},
  msql_    => { class => 'DBD::mSQL',		},
  mysql_   => { class => 'DBD::mysql',		},
  mx_      => { class => 'DBD::Multiplex',	},
  nullp_   => { class => 'DBD::NullP',		},
  odbc_    => { class => 'DBD::ODBC',		},
  ora_     => { class => 'DBD::Oracle',		},
  pg_      => { class => 'DBD::Pg',		},
  plb_     => { class => 'DBD::Plibdata',	},
  proxy_   => { class => 'DBD::Proxy',		},
  rdb_     => { class => 'DBD::RDB',		},
  sapdb_   => { class => 'DBD::SAP_DB',		},
  solid_   => { class => 'DBD::Solid',		},
  sponge_  => { class => 'DBD::Sponge',		},
  sql_     => { class => 'SQL::Statement',	},
  syb_     => { class => 'DBD::Sybase',		},
  tdat_    => { class => 'DBD::Teradata',	},
  tmpl_    => { class => 'DBD::Template',	},
  tmplss_  => { class => 'DBD::TemplateSS',	},
  tuber_   => { class => 'DBD::Tuber',		},
  uni_     => { class => 'DBD::Unify',		},
  wmi_     => { class => 'DBD::WMI',		},
  x_       => { }, # for private use
  xbase_   => { class => 'DBD::XBase',		},
  xl_      => { class => 'DBD::Excel',		},
  yaswi_   => { class => 'DBD::Yaswi',		},
};

sub dump_dbd_registry {
    require Data::Dumper;
    local $Data::Dumper::Sortkeys=1;
    local $Data::Dumper::Indent=1;
    print Data::Dumper->Dump([$dbd_prefix_registry], [qw($dbd_prefix_registry)]);
}

# --- Dynamically create the DBI Standard Interface

my $keeperr = { O=>0x0004 };

%DBI::DBI_methods = ( # Define the DBI interface methods per class:

    common => {		# Interface methods common to all DBI handle classes
	'DESTROY'	=> { O=>0x004|0x10000 },
	'CLEAR'  	=> $keeperr,
	'EXISTS' 	=> $keeperr,
	'FETCH'		=> { O=>0x0404 },
	'FETCH_many'	=> { O=>0x0404 },
	'FIRSTKEY'	=> $keeperr,
	'NEXTKEY'	=> $keeperr,
	'STORE'		=> { O=>0x0418 | 0x4 },
	_not_impl	=> undef,
	can		=> { O=>0x0100 }, # special case, see dispatch
	debug 	 	=> { U =>[1,2,'[$debug_level]'],	O=>0x0004 }, # old name for trace
	dump_handle 	=> { U =>[1,3,'[$message [, $level]]'],	O=>0x0004 },
	err		=> $keeperr,
	errstr		=> $keeperr,
	state		=> $keeperr,
	func	   	=> { O=>0x0006	},
	parse_trace_flag   => { U =>[2,2,'$name'],	O=>0x0404, T=>8 },
	parse_trace_flags  => { U =>[2,2,'$flags'],	O=>0x0404, T=>8 },
	private_data	=> { U =>[1,1],			O=>0x0004 },
	set_err		=> { U =>[3,6,'$err, $errmsg [, $state, $method, $rv]'], O=>0x0010 },
	trace		=> { U =>[1,3,'[$trace_level, [$filename]]'],	O=>0x0004 },
	trace_msg	=> { U =>[2,3,'$message_text [, $min_level ]' ],	O=>0x0004, T=>8 },
	swap_inner_handle => { U =>[2,3,'$h [, $allow_reparent ]'] },
        private_attribute_info => { },
    },
    dr => {		# Database Driver Interface
	'connect'  =>	{ U =>[1,5,'[$db [,$user [,$passwd [,\%attr]]]]'], H=>3, O=>0x8000 },
	'connect_cached'=>{U=>[1,5,'[$db [,$user [,$passwd [,\%attr]]]]'], H=>3, O=>0x8000 },
	'disconnect_all'=>{ U =>[1,1], O=>0x0800 },
	data_sources => { U =>[1,2,'[\%attr]' ], O=>0x0800 },
	default_user => { U =>[3,4,'$user, $pass [, \%attr]' ] },
    },
    db => {		# Database Session Class Interface
	data_sources	=> { U =>[1,2,'[\%attr]' ], O=>0x0200 },
	take_imp_data	=> { U =>[1,1], O=>0x10000 },
	clone   	=> { U =>[1,2,'[\%attr]'] },
	connected   	=> { U =>[1,0], O => 0x0004 },
	begin_work   	=> { U =>[1,2,'[ \%attr ]'], O=>0x0400 },
	commit     	=> { U =>[1,1], O=>0x0480|0x0800 },
	rollback   	=> { U =>[1,1], O=>0x0480|0x0800 },
	'do'       	=> { U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x3200 },
	last_insert_id	=> { U =>[5,6,'$catalog, $schema, $table_name, $field_name [, \%attr ]'], O=>0x2800 },
	preparse    	=> {  }, # XXX
	prepare    	=> { U =>[2,3,'$statement [, \%attr]'],                    O=>0xA200 },
	prepare_cached	=> { U =>[2,4,'$statement [, \%attr [, $if_active ] ]'],   O=>0xA200 },
	selectrow_array	=> { U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectrow_arrayref=>{U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectrow_hashref=>{ U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectall_arrayref=>{U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectall_hashref=>{ U =>[3,0,'$statement, $keyfield [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectcol_arrayref=>{U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	ping       	=> { U =>[1,1], O=>0x0404 },
	disconnect 	=> { U =>[1,1], O=>0x0400|0x0800|0x10000 },
	quote      	=> { U =>[2,3, '$string [, $data_type ]' ], O=>0x0430 },
	quote_identifier=> { U =>[2,6, '$name [, ...] [, \%attr ]' ],    O=>0x0430 },
	rows       	=> $keeperr,

	tables          => { U =>[1,6,'$catalog, $schema, $table, $type [, \%attr ]' ], O=>0x2200 },
	table_info      => { U =>[1,6,'$catalog, $schema, $table, $type [, \%attr ]' ],	O=>0x2200|0x8800 },
	column_info     => { U =>[5,6,'$catalog, $schema, $table, $column [, \%attr ]'],O=>0x2200|0x8800 },
	primary_key_info=> { U =>[4,5,'$catalog, $schema, $table [, \%attr ]' ],	O=>0x2200|0x8800 },
	primary_key     => { U =>[4,5,'$catalog, $schema, $table [, \%attr ]' ],	O=>0x2200 },
	foreign_key_info=> { U =>[7,8,'$pk_catalog, $pk_schema, $pk_table, $fk_catalog, $fk_schema, $fk_table [, \%attr ]' ], O=>0x2200|0x8800 },
	statistics_info => { U =>[6,7,'$catalog, $schema, $table, $unique_only, $quick, [, \%attr ]' ], O=>0x2200|0x8800 },
	type_info_all	=> { U =>[1,1], O=>0x2200|0x0800 },
	type_info	=> { U =>[1,2,'$data_type'], O=>0x2200 },
	get_info	=> { U =>[2,2,'$info_type'], O=>0x2200|0x0800 },
    },
    st => {		# Statement Class Interface
	bind_col	=> { U =>[3,4,'$column, \\$var [, \%attr]'] },
	bind_columns	=> { U =>[2,0,'\\$var1 [, \\$var2, ...]'] },
	bind_param	=> { U =>[3,4,'$parameter, $var [, \%attr]'] },
	bind_param_inout=> { U =>[4,5,'$parameter, \\$var, $maxlen, [, \%attr]'] },
	execute		=> { U =>[1,0,'[@args]'], O=>0x1040 },

	bind_param_array  => { U =>[3,4,'$parameter, $var [, \%attr]'] },
	bind_param_inout_array => { U =>[4,5,'$parameter, \\@var, $maxlen, [, \%attr]'] },
	execute_array     => { U =>[2,0,'\\%attribs [, @args]'],         O=>0x1040|0x4000 },
	execute_for_fetch => { U =>[2,3,'$fetch_sub [, $tuple_status]'], O=>0x1040|0x4000 },

	fetch    	  => undef, # alias for fetchrow_arrayref
	fetchrow_arrayref => undef,
	fetchrow_hashref  => undef,
	fetchrow_array    => undef,
	fetchrow   	  => undef, # old alias for fetchrow_array

	fetchall_arrayref => { U =>[1,3, '[ $slice [, $max_rows]]'] },
	fetchall_hashref  => { U =>[2,2,'$key_field'] },

	blob_read  =>	{ U =>[4,5,'$field, $offset, $len [, \\$buf [, $bufoffset]]'] },
	blob_copy_to_file => { U =>[3,3,'$field, $filename_or_handleref'] },
	dump_results => { U =>[1,5,'$maxfieldlen, $linesep, $fieldsep, $filehandle'] },
	more_results => { U =>[1,1] },
	finish     => 	{ U =>[1,1] },
	cancel     => 	{ U =>[1,1], O=>0x0800 },
	rows       =>	$keeperr,

	_get_fbav	=> undef,
	_set_fbav	=> { T=>6 },
    },
);

while ( my ($class, $meths) = each %DBI::DBI_methods ) {
    my $ima_trace = 0+($ENV{DBI_IMA_TRACE}||0);
    while ( my ($method, $info) = each %$meths ) {
	my $fullmeth = "DBI::${class}::$method";
	if ($DBI::dbi_debug >= 15) { # quick hack to list DBI methods
	    # and optionally filter by IMA flags
	    my $O = $info->{O}||0;
	    printf "0x%04x %-20s\n", $O, $fullmeth
	        unless $ima_trace && !($O & $ima_trace);
	}
	DBI->_install_method($fullmeth, 'DBI.pm', $info);
    }
}

{
    package DBI::common;
    @DBI::dr::ISA = ('DBI::common');
    @DBI::db::ISA = ('DBI::common');
    @DBI::st::ISA = ('DBI::common');
}

# End of init code


END {
    return unless defined &DBI::trace_msg; # return unless bootstrap'd ok
    local ($!,$?);
    DBI->trace_msg(sprintf("    -- DBI::END (\$\@: %s, \$!: %s)\n", $@||'', $!||''), 2);
    # Let drivers know why we are calling disconnect_all:
    $DBI::PERL_ENDING = $DBI::PERL_ENDING = 1;	# avoid typo warning
    DBI->disconnect_all() if %DBI::installed_drh;
}


sub CLONE {
    my $olddbis = $DBI::_dbistate;
    _clone_dbis() unless $DBI::PurePerl; # clone the DBIS structure
    DBI->trace_msg(sprintf "CLONE DBI for new thread %s\n",
	$DBI::PurePerl ? "" : sprintf("(dbis %x -> %x)",$olddbis, $DBI::_dbistate));
    while ( my ($driver, $drh) = each %DBI::installed_drh) {
	no strict 'refs';
	next if defined &{"DBD::${driver}::CLONE"};
	warn("$driver has no driver CLONE() function so is unsafe threaded\n");
    }
    %DBI::installed_drh = ();	# clear loaded drivers so they have a chance to reinitialize
}

=pod

=begin classdoc

Breaks apart a DBI Data Source Name (DSN) and returns the individual
parts.

@since 1.43.

@param $dsn	Data Source Name to be parsed

@returnlist undef on failure, otherwise, <code>($scheme, $driver, $attr_string, $attr_hash, $driver_dsn)</code>,
	where
	<ul>
	<li>$scheme is the first part of the DSN and is currently always 'dbi'.
	<li>$driver is the driver name, possibly defaulted to $ENV{DBI_DRIVER},	and may be undefined.
	<li>$attr_string is the contents of the optional attribute string, which may be undefined. 
	<li>$attr_hash is a reference to a hash containing the parsed attribute names and values if $attr_string is not empty.
	<li>$driver_dsn is any trailing part of the DSN string
	</ul>

=end classdoc

=cut

sub parse_dsn {
    my ($class, $dsn) = @_;
    $dsn =~ s/^(dbi):(\w*?)(?:\((.*?)\))?://i or return;
    my ($scheme, $driver, $attr, $attr_hash) = (lc($1), $2, $3);
    $driver ||= $ENV{DBI_DRIVER} || '';
    $attr_hash = { split /\s*=>?\s*|\s*,\s*/, $attr, -1 } if $attr;
    return ($scheme, $driver, $attr, $attr_hash, $dsn);
}


# --- The DBI->connect Front Door methods

=pod

=begin classdoc

Establish a database connection using a cached connection (if available).
Behaves identically to <method>connect</method>, except that the database handle
returned is also stored in a hash associated with the given parameters and attribute values.
If another call is made to <code>connect_cached</code> with the same parameter and attribute values, a
corresponding cached <code>$dbh</code> will be returned if it is still valid.
The cached database handle is replaced with a new connection if it
has been disconnected or if the <code>ping</code> method fails.
<p>
Caching connections can be useful in some applications, but it can
also cause problems, such as too many connections, and so should
be used with care. In particular, avoid changing the attributes of
a database handle created via connect_cached() because it will affect
other code that may be using the same handle.
<p>
The connection cache can be accessed (and cleared) via the <code>CachedKids</code> attribute:
<pre>
  my $CachedKids_hashref = $dbh->{Driver}->{CachedKids};
  %$CachedKids_hashref = () if $CachedKids_hashref;
</pre>

@param $data_source	a Data Source String <i>aka</i> DSN specifying the driver and
	associated driver-specific attributes to use for the connection. There is <i>no standard</i> 
	for the text following the driver name in the <code>$data_source</code>
	DSN string. Refer to each driver's documentation for its DSN syntax.
@param $username	the username to connect with; some drivers may accept an empty string
@param $password	the password used to authenticate the user; some drivers may accept an empty string
@optional \%attr	hashref of DBI and driver-specific attributes to be applied to the connection. Supported attributes include
<ul>
<li>AutoCommit - if true (the default), forces commit after each executed statement.
<li>PrintError - if true (the default), errors generated during the life of the connection will be printed
<li>RaiseError - if true (default false), errors cause the current execution context to die.
<li>Username - overrides the <code>$username</code> parameter
<li>Password - overrides the <code>$password</code> parameter
<li>dbi_connect_method - specify the driver method used to establish the connection. Acceptable
values are 'connect', 'connect_cached', or 'Apache::DBI::connect' (the default when running within Apache).
<li><i>driver_specific_attribute</i> - a driver-specific attribute
</ul>
<p>
Connection attributes may also be specified within the <code>$data_source</code>
parameter. For example:
<pre>
  dbi:DriverName(PrintWarn=>1,PrintError=>0,Taint=>1):...
</pre>

@return a DBI::_::db object (<i>aka</i> database handle) if the connection succeeds; otherwise, undef
	and sets both <code>$DBI::err</code> and <code>$DBI::errstr</code>.

=end classdoc

=cut

sub connect_cached {
    # For library code using connect_cached() with mod_perl
    # we redirect those calls to Apache::DBI::connect() as well
    my ($class, $dsn, $user, $pass, $attr) = @_;
    my $dbi_connect_method = ($DBI::connect_via eq "Apache::DBI::connect")
	    ? 'Apache::DBI::connect' : 'connect_cached';
    $attr = {
        $attr ? %$attr : (), # clone, don't modify callers data
        dbi_connect_method => $dbi_connect_method,
    };
    return $class->connect($dsn, $user, $pass, $attr);
}

=pod

=begin classdoc

Establishes a database connection.
<p>
If <code>$username</code> or <code>$password</code> are undefined (rather than just empty),
then the DBI will substitute the values of the <code>DBI_USER</code> and <code>DBI_PASS</code>
environment variables, respectively.  The DBI will warn if the
environment variables are not defined.  However, the everyday use
of these environment variables is not recommended for security
reasons. The mechanism is primarily intended to simplify testing.
See below for alternative way to specify the username and password.

@param $data_source	a Data Source String <i>aka</i> DSN specifying the driver and
	associated driver-specific attributes to use for the connection. There is <i>no standard</i> 
	for the text following the driver name in the <code>$data_source</code>
	DSN string. Refer to each driver's documentation for its DSN syntax.
@param $username	the username to connect with; some drivers may accept an empty string
@param $password	the password used to authenticate the user; some drivers may accept an empty string
@optional \%attr	hashref of DBI and driver-specific attributes to be applied to the connection. Supported attributes include
<ul>
<li>AutoCommit - if true (the default), forces commit after each executed statement.
<li>PrintError - if true (the default), errors generated during the life of the connection will be printed
<li>RaiseError - if true (default false), errors cause the current execution context to die.
<li>Username - overrides the <code>$username</code> parameter
<li>Password - overrides the <code>$password</code> parameter
<li>dbi_connect_method - specify the driver method used to establish the connection. Acceptable
values are 'connect', 'connect_cached', or 'Apache::DBI::connect' (the default when running within Apache).
<li><i>driver_specific_attribute</i> - a driver-specific attribute
</ul>
<p>
Connection attributes may also be specified within the <code>$data_source</code>
parameter. For example:
<pre>
  dbi:DriverName(PrintWarn=>1,PrintError=>0,Taint=>1):...
</pre>

@return a DBI::_::db object (<i>aka</i> database handle) if the connection succeeds; otherwise, undef
	and sets both <code>$DBI::err</code> and <code>$DBI::errstr</code>.

=end classdoc

=cut

sub connect {
    my $class = shift;
    my ($dsn, $user, $pass, $attr, $old_driver) = my @orig_args = @_;
    my $driver;

    if ($attr and !ref($attr)) { # switch $old_driver<->$attr if called in old style
	Carp::carp("DBI->connect using 'old-style' syntax is deprecated and will be an error in future versions");
        ($old_driver, $attr) = ($attr, $old_driver);
    }

    my $connect_meth = $attr->{dbi_connect_method};
    $connect_meth ||= $DBI::connect_via;	# fallback to default

    $dsn ||= $ENV{DBI_DSN} || $ENV{DBI_DBNAME} || '' unless $old_driver;

    if ($DBI::dbi_debug) {
	local $^W = 0;
	pop @_ if $connect_meth ne 'connect';
	my @args = @_; $args[2] = '****'; # hide password
	DBI->trace_msg("    -> $class->$connect_meth(".join(", ",@args).")\n");
    }
    Carp::croak('Usage: $class->connect([$dsn [,$user [,$passwd [,\%attr]]]])')
	if (ref $old_driver or ($attr and not ref $attr) or ref $pass);

    # extract dbi:driver prefix from $dsn into $1
    $dsn =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i
			or '' =~ /()/; # ensure $1 etc are empty if match fails
    my $driver_attrib_spec = $2 || '';

    # Set $driver. Old style driver, if specified, overrides new dsn style.
    $driver = $old_driver || $1 || $ENV{DBI_DRIVER}
	or Carp::croak("Can't connect to data source '$dsn' "
            ."because I can't work out what driver to use "
            ."(it doesn't seem to contain a 'dbi:driver:' prefix "
            ."and the DBI_DRIVER env var is not set)");

    my $proxy;
    if ($ENV{DBI_AUTOPROXY} && $driver ne 'Proxy' && $driver ne 'Sponge' && $driver ne 'Switch') {
	my $dbi_autoproxy = $ENV{DBI_AUTOPROXY};
	$proxy = 'Proxy';
	if ($dbi_autoproxy =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i) {
	    $proxy = $1;
	    $driver_attrib_spec = join ",",
                ($driver_attrib_spec) ? $driver_attrib_spec : (),
                ($2                 ) ? $2                  : ();
	}
	$dsn = "$dbi_autoproxy;dsn=dbi:$driver:$dsn";
	$driver = $proxy;
	DBI->trace_msg("       DBI_AUTOPROXY: dbi:$driver($driver_attrib_spec):$dsn\n");
    }
    # avoid recursion if proxy calls DBI->connect itself
    local $ENV{DBI_AUTOPROXY};

    my %attributes;	# take a copy we can delete from
    if ($old_driver) {
	%attributes = %$attr if $attr;
    }
    else {		# new-style connect so new default semantics
	%attributes = (
	    PrintError => 1,
	    AutoCommit => 1,
	    ref $attr           ? %$attr : (),
	    # attributes in DSN take precedence over \%attr connect parameter
	    $driver_attrib_spec ? (split /\s*=>?\s*|\s*,\s*/, $driver_attrib_spec, -1) : (),
	);
    }
    $attr = \%attributes; # now set $attr to refer to our local copy

    my $drh = $DBI::installed_drh{$driver} || $class->install_driver($driver)
	or die "panic: $class->install_driver($driver) failed";

    # attributes in DSN take precedence over \%attr connect parameter
    $user = $attr->{Username} if defined $attr->{Username};
    $pass = $attr->{Password} if defined $attr->{Password};
    delete $attr->{Password}; # always delete Password as closure stores it securely
    if ( !(defined $user && defined $pass) ) {
        ($user, $pass) = $drh->default_user($user, $pass, $attr);
    }
    $attr->{Username} = $user; # force the Username to be the actual one used

    my $connect_closure = sub {
	my ($old_dbh, $override_attr) = @_;

        #use Data::Dumper;
        #warn "connect_closure: ".Data::Dumper::Dumper([$attr,\%attributes, $override_attr]);

	my $dbh;
	unless ($dbh = $drh->$connect_meth($dsn, $user, $pass, $attr)) {
	    $user = '' if !defined $user;
	    $dsn = '' if !defined $dsn;
	    # $drh->errstr isn't safe here because $dbh->DESTROY may not have
	    # been called yet and so the dbh errstr would not have been copied
	    # up to the drh errstr. Certainly true for connect_cached!
	    my $errstr = $DBI::errstr;
            # Getting '(no error string)' here is a symptom of a ref loop
	    $errstr = '(no error string)' if !defined $errstr;
	    my $msg = "$class connect('$dsn','$user',...) failed: $errstr";
	    DBI->trace_msg("       $msg\n");
	    # XXX HandleWarn
	    unless ($attr->{HandleError} && $attr->{HandleError}->($msg, $drh, $dbh)) {
		Carp::croak($msg) if $attr->{RaiseError};
		Carp::carp ($msg) if $attr->{PrintError};
	    }
	    $! = 0; # for the daft people who do DBI->connect(...) || die "$!";
	    return $dbh; # normally undef, but HandleError could change it
	}

        # merge any attribute overrides but don't change $attr itself (for closure)
        my $apply = { ($override_attr) ? (%$attr, %$override_attr ) : %$attr };

        # handle basic RootClass subclassing:
        my $rebless_class = $apply->{RootClass} || ($class ne 'DBI' ? $class : '');
        if ($rebless_class) {
            no strict 'refs';
            if ($apply->{RootClass}) { # explicit attribute (ie not static methd call class)
                delete $apply->{RootClass};
                DBI::_load_class($rebless_class, 0);
            }
            unless (@{"$rebless_class\::db::ISA"} && @{"$rebless_class\::st::ISA"}) {
                Carp::carp("DBI subclasses '$rebless_class\::db' and ::st are not setup, RootClass ignored");
                $rebless_class = undef;
                $class = 'DBI';
            }
            else {
                $dbh->{RootClass} = $rebless_class; # $dbh->STORE called via plain DBI::db
                DBI::_set_isa([$rebless_class], 'DBI');     # sets up both '::db' and '::st'
                DBI::_rebless($dbh, $rebless_class);        # appends '::db'
            }
        }

	if (%$apply) {

            if ($apply->{DbTypeSubclass}) {
                my $DbTypeSubclass = delete $apply->{DbTypeSubclass};
                DBI::_rebless_dbtype_subclass($dbh, $rebless_class||$class, $DbTypeSubclass);
            }
	    my $a;
	    foreach $a (qw(Profile RaiseError PrintError AutoCommit)) { # do these first
		next unless  exists $apply->{$a};
		$dbh->{$a} = delete $apply->{$a};
	    }
	    while ( my ($a, $v) = each %$apply) {
		eval { $dbh->{$a} = $v } or $@ && warn $@;
	    }
	}

        # confirm to driver (ie if subclassed) that we've connected sucessfully
        # and finished the attribute setup. pass in the original arguments
	$dbh->connected(@orig_args); #if ref $dbh ne 'DBI::db' or $proxy;

	DBI->trace_msg("    <- connect= $dbh\n") if $DBI::dbi_debug;

	return $dbh;
    };

    my $dbh = &$connect_closure(undef, undef);

    $dbh->{dbi_connect_closure} = $connect_closure if $dbh;

    return $dbh;
}

=pod

=begin classdoc

Disconnect all connections on all installed DBI drivers.

=end classdoc

=cut

sub disconnect_all {
    keys %DBI::installed_drh; # reset iterator
    while ( my ($name, $drh) = each %DBI::installed_drh ) {
	$drh->disconnect_all() if ref $drh;
    }
}


sub disconnect {		# a regular beginners bug
    Carp::croak("DBI->disconnect is not a DBI method (read the DBI manual)");
}


sub install_driver {		# croaks on failure
    my $class = shift;
    my($driver, $attr) = @_;
    my $drh;

    $driver ||= $ENV{DBI_DRIVER} || '';

    # allow driver to be specified as a 'dbi:driver:' string
    $driver = $1 if $driver =~ s/^DBI:(.*?)://i;

    Carp::croak("usage: $class->install_driver(\$driver [, \%attr])")
		unless ($driver and @_<=3);

    # already installed
    return $drh if $drh = $DBI::installed_drh{$driver};

    $class->trace_msg("    -> $class->install_driver($driver"
			.") for $^O perl=$] pid=$$ ruid=$< euid=$>\n")
	if $DBI::dbi_debug;

    # --- load the code
    my $driver_class = "DBD::$driver";
    eval qq{package			# hide from PAUSE
		DBI::_firesafe;		# just in case
	    require $driver_class;	# load the driver
    };
    if ($@) {
	my $err = $@;
	my $advice = "";
	if ($err =~ /Can't find loadable object/) {
	    $advice = "Perhaps DBD::$driver was statically linked into a new perl binary."
		 ."\nIn which case you need to use that new perl binary."
		 ."\nOr perhaps only the .pm file was installed but not the shared object file."
	}
	elsif ($err =~ /Can't locate.*?DBD\/$driver\.pm in \@INC/) {
	    my @drv = $class->available_drivers(1);
	    $advice = "Perhaps the DBD::$driver perl module hasn't been fully installed,\n"
		     ."or perhaps the capitalisation of '$driver' isn't right.\n"
		     ."Available drivers: ".join(", ", @drv).".";
	}
	elsif ($err =~ /Can't load .*? for module DBD::/) {
	    $advice = "Perhaps a required shared library or dll isn't installed where expected";
	}
	elsif ($err =~ /Can't locate .*? in \@INC/) {
	    $advice = "Perhaps a module that DBD::$driver requires hasn't been fully installed";
	}
	Carp::croak("install_driver($driver) failed: $err$advice\n");
    }
    if ($DBI::dbi_debug) {
	no strict 'refs';
	(my $driver_file = $driver_class) =~ s/::/\//g;
	my $dbd_ver = ${"$driver_class\::VERSION"} || "undef";
	$class->trace_msg("       install_driver: $driver_class version $dbd_ver"
		." loaded from $INC{qq($driver_file.pm)}\n");
    }

    # --- do some behind-the-scenes checks and setups on the driver
    $class->setup_driver($driver_class);

    # --- run the driver function
    $drh = eval { $driver_class->driver($attr || {}) };
    unless ($drh && ref $drh && !$@) {
	my $advice = "";
        $@ ||= "$driver_class->driver didn't return a handle";
	# catch people on case in-sensitive systems using the wrong case
	$advice = "\nPerhaps the capitalisation of DBD '$driver' isn't right."
		if $@ =~ /locate object method/;
	Carp::croak("$driver_class initialisation failed: $@$advice");
    }

    $DBI::installed_drh{$driver} = $drh;
    $class->trace_msg("    <- install_driver= $drh\n") if $DBI::dbi_debug;
    $drh;
}

*driver = \&install_driver;	# currently an alias, may change


sub setup_driver {
    my ($class, $driver_class) = @_;
    my $type;
    foreach $type (qw(dr db st)){
	my $class = $driver_class."::$type";
	no strict 'refs';
	push @{"${class}::ISA"},     "DBD::_::$type"
	    unless UNIVERSAL::isa($class, "DBD::_::$type");
	my $mem_class = "DBD::_mem::$type";
	push @{"${class}_mem::ISA"}, $mem_class
	    unless UNIVERSAL::isa("${class}_mem", $mem_class)
	    or $DBI::PurePerl;
    }
}


sub _rebless {
    my $dbh = shift;
    my ($outer, $inner) = DBI::_handles($dbh);
    my $class = shift(@_).'::db';
    bless $inner => $class;
    bless $outer => $class; # outer last for return
}


sub _set_isa {
    my ($classes, $topclass) = @_;
    my $trace = DBI->trace_msg("       _set_isa([@$classes])\n");
    foreach my $suffix ('::db','::st') {
	my $previous = $topclass || 'DBI'; # trees are rooted here
	foreach my $class (@$classes) {
	    my $base_class = $previous.$suffix;
	    my $sub_class  = $class.$suffix;
	    my $sub_class_isa  = "${sub_class}::ISA";
	    no strict 'refs';
	    if (@$sub_class_isa) {
		DBI->trace_msg("       $sub_class_isa skipped (already set to @$sub_class_isa)\n")
		    if $trace;
	    }
	    else {
		@$sub_class_isa = ($base_class) unless @$sub_class_isa;
		DBI->trace_msg("       $sub_class_isa = $base_class\n")
		    if $trace;
	    }
	    $previous = $class;
	}
    }
}


sub _rebless_dbtype_subclass {
    my ($dbh, $rootclass, $DbTypeSubclass) = @_;
    # determine the db type names for class hierarchy
    my @hierarchy = DBI::_dbtype_names($dbh, $DbTypeSubclass);
    # add the rootclass prefix to each ('DBI::' or 'MyDBI::' etc)
    $_ = $rootclass.'::'.$_ foreach (@hierarchy);
    # load the modules from the 'top down'
    DBI::_load_class($_, 1) foreach (reverse @hierarchy);
    # setup class hierarchy if needed, does both '::db' and '::st'
    DBI::_set_isa(\@hierarchy, $rootclass);
    # finally bless the handle into the subclass
    DBI::_rebless($dbh, $hierarchy[0]);
}


sub _dbtype_names { # list dbtypes for hierarchy, ie Informix=>ADO=>ODBC
    my ($dbh, $DbTypeSubclass) = @_;

    if ($DbTypeSubclass && $DbTypeSubclass ne '1' && ref $DbTypeSubclass ne 'CODE') {
	# treat $DbTypeSubclass as a comma separated list of names
	my @dbtypes = split /\s*,\s*/, $DbTypeSubclass;
	$dbh->trace_msg("    DbTypeSubclass($DbTypeSubclass)=@dbtypes (explicit)\n");
	return @dbtypes;
    }

    # XXX will call $dbh->get_info(17) (=SQL_DBMS_NAME) in future?

    my $driver = $dbh->{Driver}->{Name};
    if ( $driver eq 'Proxy' ) {
        # XXX Looking into the internals of DBD::Proxy is questionable!
        ($driver) = $dbh->{proxy_client}->{application} =~ /^DBI:(.+?):/i
		or die "Can't determine driver name from proxy";
    }

    my @dbtypes = (ucfirst($driver));
    if ($driver eq 'ODBC' || $driver eq 'ADO') {
	# XXX will move these out and make extensible later:
	my $_dbtype_name_regexp = 'Oracle'; # eg 'Oracle|Foo|Bar'
	my %_dbtype_name_map = (
	     'Microsoft SQL Server'	=> 'MSSQL',
	     'SQL Server'		=> 'Sybase',
	     'Adaptive Server Anywhere'	=> 'ASAny',
	     'ADABAS D'			=> 'AdabasD',
	);

        my $name;
	$name = $dbh->func(17, 'GetInfo') # SQL_DBMS_NAME
		if $driver eq 'ODBC';
	$name = $dbh->{ado_conn}->Properties->Item('DBMS Name')->Value
		if $driver eq 'ADO';
	die "Can't determine driver name! ($DBI::errstr)\n"
		unless $name;

	my $dbtype;
        if ($_dbtype_name_map{$name}) {
            $dbtype = $_dbtype_name_map{$name};
        }
	else {
	    if ($name =~ /($_dbtype_name_regexp)/) {
		$dbtype = lc($1);
	    }
	    else { # generic mangling for other names:
		$dbtype = lc($name);
	    }
	    $dbtype =~ s/\b(\w)/\U$1/g;
	    $dbtype =~ s/\W+/_/g;
	}
	# add ODBC 'behind' ADO
	push    @dbtypes, 'ODBC' if $driver eq 'ADO';
	# add discovered dbtype in front of ADO/ODBC
	unshift @dbtypes, $dbtype;
    }
    @dbtypes = &$DbTypeSubclass($dbh, \@dbtypes)
	if (ref $DbTypeSubclass eq 'CODE');
    $dbh->trace_msg("    DbTypeSubclass($DbTypeSubclass)=@dbtypes\n");
    return @dbtypes;
}

sub _load_class {
    my ($load_class, $missing_ok) = @_;
    DBI->trace_msg("    _load_class($load_class, $missing_ok)\n", 2);
    no strict 'refs';
    return 1 if @{"$load_class\::ISA"};	# already loaded/exists
    (my $module = $load_class) =~ s!::!/!g;
    DBI->trace_msg("    _load_class require $module\n", 2);
    eval { require "$module.pm"; };
    return 1 unless $@;
    return 0 if $missing_ok && $@ =~ /^Can't locate \Q$module.pm\E/;
    die $@;
}


sub init_rootclass {	# deprecated
    return 1;
}


*internal = \&DBD::Switch::dr::driver;


=pod

=begin classdoc

Return a list of all available drivers.
Searches for <code>DBD::*</code> modules
within the directories in <code>@INC</code>.
<p>
By default, a warning is issued if some drivers are hidden by others of the same name in earlier
directories. Passing a true value for <code>$quiet</code> will inhibit the warning.

@optional $quiet if true, silences the duplicate driver name warning.

@returnlist	a list of all available DBI driver modules.

=end classdoc

=cut

sub available_drivers {
    my($quiet) = @_;
    my(@drivers, $d, $f);
    local(*DBI::DIR, $@);
    my(%seen_dir, %seen_dbd);
    my $haveFileSpec = eval { require File::Spec };
    foreach $d (@INC){
	chomp($d); # Perl 5 beta 3 bug in #!./perl -Ilib from Test::Harness
	my $dbd_dir =
	    ($haveFileSpec ? File::Spec->catdir($d, 'DBD') : "$d/DBD");
	next unless -d $dbd_dir;
	next if $seen_dir{$d};
	$seen_dir{$d} = 1;
	# XXX we have a problem here with case insensitive file systems
	# XXX since we can't tell what case must be used when loading.
	opendir(DBI::DIR, $dbd_dir) || Carp::carp "opendir $dbd_dir: $!\n";
	foreach $f (readdir(DBI::DIR)){
	    next unless $f =~ s/\.pm$//;
	    next if $f eq 'NullP';
	    if ($seen_dbd{$f}){
		Carp::carp "DBD::$f in $d is hidden by DBD::$f in $seen_dbd{$f}\n"
		    unless $quiet;
            } else {
		push(@drivers, $f);
	    }
	    $seen_dbd{$f} = $d;
	}
	closedir(DBI::DIR);
    }

    # "return sort @drivers" will not DWIM in scalar context.
    return wantarray ? sort @drivers : @drivers;
}

=pod

=begin classdoc

Returns a list of available drivers and their current installed versions.
Note that this loads <b>all</b> available drivers.
<p>
When called in a void context the installed_versions() method will
print out a formatted list of the hash contents, one per line.
<p>
Due to the potentially high memory cost and unknown risks of loading
in an unknown number of drivers that just happen to be installed
on the system, this method is not recommended for general use.
Use <method>available_drivers</method> instead.
<p>
The installed_versions() method is primarily intended as a quick
way to see from the command line what's installed. For example:
<pre>
  perl -MDBI -e 'DBI->installed_versions'
</pre>

@return in scalar context, a hash reference mapping driver names (without the 'DBD::' prefix) to versions,
	as well as other entries for the <code>DBI</code> version, <code>OS</code> name, etc.

@returnlist the list of successfully loaded drivers (without the 'DBD::' prefix)
@since 1.38.

=end classdoc

=cut

sub installed_versions {
    my ($class, $quiet) = @_;
    my %error;
    my %version = ( DBI => $DBI::VERSION );
    $version{"DBI::PurePerl"} = $DBI::PurePerl::VERSION
	if $DBI::PurePerl;
    for my $driver ($class->available_drivers($quiet)) {
	next if $DBI::PurePerl && grep { -d "$_/auto/DBD/$driver" } @INC;
	my $drh = eval {
	    local $SIG{__WARN__} = sub {};
	    $class->install_driver($driver);
	};
	($error{"DBD::$driver"}=$@),next if $@;
	no strict 'refs';
	my $vers = ${"DBD::$driver" . '::VERSION'};
	$version{"DBD::$driver"} = $vers || '?';
    }
    if (wantarray) {
       return map { m/^DBD::(\w+)/ ? ($1) : () } sort keys %version;
    }
    if (!defined wantarray) {	# void context
	require Config;		# add more detail
	$version{OS}   = "$^O\t($Config::Config{osvers})";
	$version{Perl} = "$]\t($Config::Config{archname})";
	$version{$_}   = (($error{$_} =~ s/ \(\@INC.*//s),$error{$_})
	    for keys %error;
	printf "  %-16s: %s\n",$_,$version{$_}
	    for reverse sort keys %version;
    }
    return \%version;
}


=pod

=begin classdoc

Return a list of data sources (databases) available via the named
driver.
<p>
Data sources are returned in a form suitable for passing to the
<method>connect</method> method with the "<code>dbi:$driver:</code>" prefix.
<p>
Note that many drivers have no way of knowing what data sources might
be available for it. These drivers return an empty or incomplete list
or may require driver-specific attributes.

@see <method>DBD::_::db::data_sources</method> for database handles.

@optional  name of the driver to search. If <code>$driver</code> is empty or <code>undef</code>, 
	then the value of the <code>DBI_DRIVER</code> environment variable is used.
@optional \%attr any supporting attributes required to locate databases for the specified driver.

@returnlist a list of complete DSN strings available via the specified driver.

=end classdoc

=cut

sub data_sources {
    my ($class, $driver, @other) = @_;
    my $drh = $class->install_driver($driver);
    my @ds = $drh->data_sources(@other);
    return @ds;
}


=pod

=begin classdoc

Calls <code>neat()</code> on each element of a list, 
returning a single string of the results joined with <code>$field_sep</code>. 

@static
@param \@listref	arrayref of strings to "neaten"
@optional $maxlen	the maximum length of each neaten'ed string; default 400
@optional $field_sep the string separator used to join the neatened strings; default ", "

@return a single string of the neatened strings joined with <code>$field_sep</code>. 

=end classdoc

=cut

sub neat_list {
    my ($listref, $maxlen, $sep) = @_;
    $maxlen = 0 unless defined $maxlen;	# 0 == use internal default
    $sep = ", " unless defined $sep;
    join($sep, map { neat($_,$maxlen) } @$listref);
}


sub dump_results {	# also aliased as a method in DBD::_::st
    my ($sth, $maxlen, $lsep, $fsep, $fh) = @_;
    return 0 unless $sth;
    $maxlen ||= 35;
    $lsep   ||= "\n";
    $fh ||= \*STDOUT;
    my $rows = 0;
    my $ref;
    while($ref = $sth->fetch) {
	print $fh $lsep if $rows++ and $lsep;
	my $str = neat_list($ref,$maxlen,$fsep);
	print $fh $str;	# done on two lines to avoid 5.003 errors
    }
    print $fh "\n$rows rows".($DBI::err ? " ($DBI::err: $DBI::errstr)" : "")."\n";
    $rows;
}


=pod

=begin classdoc

Return an informal description of the difference between two strings.
Calls <method>data_string_desc</method> and <method>data_string_diff</method>
and returns the combined results as a multi-line string.
<p>
For example, <code>data_diff("abc", "ab\x{263a}")</code> will return:
<pre>
  a: UTF8 off, ASCII, 3 characters 3 bytes
  b: UTF8 on, non-ASCII, 3 characters 5 bytes
  Strings differ at index 2: a[2]=c, b[2]=\x{263A}
</pre>
If $a and $b are identical in both the characters they contain <i>and</i>
their physical encoding then data_diff() returns an empty string.
If $logical is true then physical encoding differences are ignored
(but are still reported if there is a difference in the characters).

@since 1.46
@static
@param	$a	first string
@param	$b	string to compare to the first string
@optional $logical	if true, ignore physical encoding differences
@returns a string describing the differences between the input strings

=end classdoc

=cut

sub data_diff {
    my ($a, $b, $logical) = @_;

    my $diff   = data_string_diff($a, $b);
    return "" if $logical and !$diff;

    my $a_desc = data_string_desc($a);
    my $b_desc = data_string_desc($b);
    return "" if !$diff and $a_desc eq $b_desc;

    $diff ||= "Strings contain the same sequence of characters"
    	if length($a);
    $diff .= "\n" if $diff;
    return "a: $a_desc\nb: $b_desc\n$diff";
}


=pod

=begin classdoc

Return an informal description of the first character difference
between two strings. For example:
<pre>
 Params a & b     Result
 ------------     ------
 'aaa', 'aaa'     ''
 'aaa', 'abc'     'Strings differ at index 2: a[2]=a, b[2]=b'
 'aaa', undef     'String b is undef, string a has 3 characters'
 'aaa', 'aa'      'String b truncated after 2 characters'
</pre>
Unicode characters are reported in <code>\x{XXXX}</code> format. Unicode
code points in the range U+0800 to U+08FF are unassigned and most
likely to occur due to double-encoding. Characters in this range
are reported as <code>\x{08XX}='C'</code> where <code>C</code> is the corresponding
latin-1 character.
<p>
The data_string_diff() function only considers logical <i>characters</i>
and not the underlying encoding. See <method>data_diff</method> for an alternative.

@since 1.46
@static
@param	$a	first string
@param	$b	string to compare to the first string
@return If both $a and $b contain the same sequence of characters, an empty string. Otherwise,
	a description of the first difference between the strings.

=end classdoc

=cut

sub data_string_diff {
    # Compares 'logical' characters, not bytes, so a latin1 string and an
    # an equivalent unicode string will compare as equal even though their
    # byte encodings are different.
    my ($a, $b) = @_;
    unless (defined $a and defined $b) {             # one undef
	return ""
		if !defined $a and !defined $b;
	return "String a is undef, string b has ".length($b)." characters"
		if !defined $a;
	return "String b is undef, string a has ".length($a)." characters"
		if !defined $b;
    }

    require utf8;
    # hack to cater for perl 5.6
    *utf8::is_utf8 = sub { (DBI::neat(shift)=~/^"/) } unless defined &utf8::is_utf8;

    my @a_chars = (utf8::is_utf8($a)) ? unpack("U*", $a) : unpack("C*", $a);
    my @b_chars = (utf8::is_utf8($b)) ? unpack("U*", $b) : unpack("C*", $b);
    my $i = 0;
    while (@a_chars && @b_chars) {
	++$i, shift(@a_chars), shift(@b_chars), next
	    if $a_chars[0] == $b_chars[0];# compare ordinal values
	my @desc = map {
	    $_ > 255 ?                    # if wide character...
	      sprintf("\\x{%04X}", $_) :  # \x{...}
	      chr($_) =~ /[[:cntrl:]]/ ?  # else if control character ...
	      sprintf("\\x%02X", $_) :    # \x..
	      chr($_)                     # else as themselves
	} ($a_chars[0], $b_chars[0]);
	# highlight probable double-encoding?
        foreach my $c ( @desc ) {
	    next unless $c =~ m/\\x\{08(..)}/;
	    $c .= "='" .chr(hex($1)) ."'"
	}
	return sprintf "Strings differ at index $i: a[$i]=$desc[0], b[$i]=$desc[1]";
    }
    return "String a truncated after $i characters" if @b_chars;
    return "String b truncated after $i characters" if @a_chars;
    return "";
}

=pod

=begin classdoc

Return an informal description of the string. For example:
<pre>
  UTF8 off, ASCII, 42 characters 42 bytes
  UTF8 off, non-ASCII, 42 characters 42 bytes
  UTF8 on, non-ASCII, 4 characters 6 bytes
  UTF8 on but INVALID encoding, non-ASCII, 4 characters 6 bytes
  UTF8 off, undef
</pre>
The initial <code>UTF8</code> on/off refers to Perl's internal UTF8 flag.
If $string has the UTF8 flag set but the sequence of bytes it
contains are not a valid UTF-8 encoding then data_string_desc()
will report <code>UTF8 on but INVALID encoding</code>.
<p>
The <code>ASCII</code> vs <code>non-ASCII</code> portion shows <code>ASCII</code> if <i>all</i> the
characters in the string are ASCII (have code points <= 127).

@param $string	string to be described

@return a string describing the properties of the string 

@since 1.46

@static

=end classdoc

=cut

sub data_string_desc {	# describe a data string
    my ($a) = @_;
    require bytes;
    require utf8;

    # hacks to cater for perl 5.6
    *utf8::is_utf8 = sub { (DBI::neat(shift)=~/^"/) } unless defined &utf8::is_utf8;
    *utf8::valid   = sub {                        1 } unless defined &utf8::valid;

    # Give sufficient info to help diagnose at least these kinds of situations:
    # - valid UTF8 byte sequence but UTF8 flag not set
    #   (might be ascii so also need to check for hibit to make it worthwhile)
    # - UTF8 flag set but invalid UTF8 byte sequence
    # could do better here, but this'll do for now
    my $utf8 = sprintf "UTF8 %s%s",
	utf8::is_utf8($a) ? "on" : "off",
	utf8::valid($a||'') ? "" : " but INVALID encoding";
    return "$utf8, undef" unless defined $a;
    my $is_ascii = $a =~ m/^[\000-\177]*$/;
    return sprintf "%s, %s, %d characters %d bytes",
	$utf8, $is_ascii ? "ASCII" : "non-ASCII",
	length($a), bytes::length($a);
}


sub connect_test_perf {
    my($class, $dsn,$dbuser,$dbpass, $attr) = @_;
	Carp::croak("connect_test_perf needs hash ref as fourth arg") unless ref $attr;
    # these are non standard attributes just for this special method
    my $loops ||= $attr->{dbi_loops} || 5;
    my $par   ||= $attr->{dbi_par}   || 1;	# parallelism
    my $verb  ||= $attr->{dbi_verb}  || 1;
    my $meth  ||= $attr->{dbi_meth}  || 'connect';
    print "$dsn: testing $loops sets of $par connections:\n";
    require "FileHandle.pm";	# don't let toke.c create empty FileHandle package
    local $| = 1;
    my $drh = $class->install_driver($dsn) or Carp::croak("Can't install $dsn driver\n");
    # test the connection and warm up caches etc
    $drh->connect($dsn,$dbuser,$dbpass) or Carp::croak("connect failed: $DBI::errstr");
    my $t1 = dbi_time();
    my $loop;
    for $loop (1..$loops) {
	my @cons;
	print "Connecting... " if $verb;
	for (1..$par) {
	    print "$_ ";
	    push @cons, ($drh->connect($dsn,$dbuser,$dbpass)
		    or Carp::croak("connect failed: $DBI::errstr\n"));
	}
	print "\nDisconnecting...\n" if $verb;
	for (@cons) {
	    $_->disconnect or warn "disconnect failed: $DBI::errstr"
	}
    }
    my $t2 = dbi_time();
    my $td = $t2 - $t1;
    printf "$meth %d and disconnect them, %d times: %.4fs / %d = %.4fs\n",
        $par, $loops, $td, $loops*$par, $td/($loops*$par);
    return $td;
}


# Help people doing DBI->errstr, might even document it one day
# XXX probably best moved to cheaper XS code if this gets documented
sub err    { $DBI::err    }
sub errstr { $DBI::errstr }


# --- Private Internal Function for Creating New DBI Handles

# XXX move to PurePerl?
*DBI::dr::TIEHASH = \&DBI::st::TIEHASH;
*DBI::db::TIEHASH = \&DBI::st::TIEHASH;


# These three special constructors are called by the drivers
# The way they are called is likely to change.

our $shared_profile;

sub _new_drh {	# called by DBD::<drivername>::driver()
    my ($class, $initial_attr, $imp_data) = @_;
    # Provide default storage for State,Err and Errstr.
    # Note that these are shared by all child handles by default! XXX
    # State must be undef to get automatic faking in DBI::var::FETCH
    my ($h_state_store, $h_err_store, $h_errstr_store) = (undef, 0, '');
    my $attr = {
	# these attributes get copied down to child handles by default
	'State'		=> \$h_state_store,  # Holder for DBI::state
	'Err'		=> \$h_err_store,    # Holder for DBI::err
	'Errstr'	=> \$h_errstr_store, # Holder for DBI::errstr
	'TraceLevel' 	=> 0,
	FetchHashKeyName=> 'NAME',
	%$initial_attr,
    };
    my ($h, $i) = _new_handle('DBI::dr', '', $attr, $imp_data, $class);

    # XXX DBI_PROFILE unless DBI::PurePerl because for some reason
    # it kills the t/zz_*_pp.t tests (they silently exit early)
    if ($ENV{DBI_PROFILE} && !$DBI::PurePerl) {
	# The profile object created here when the first driver is loaded
	# is shared by all drivers so we end up with just one set of profile
	# data and thus the 'total time in DBI' is really the true total.
	if (!$shared_profile) {	# first time
	    $h->{Profile} = $ENV{DBI_PROFILE};
	    $shared_profile = $h->{Profile};
	}
	else {
	    $h->{Profile} = $shared_profile;
	}
    }
    return $h unless wantarray;
    ($h, $i);
}

sub _new_dbh {	# called by DBD::<drivername>::dr::connect()
    my ($drh, $attr, $imp_data) = @_;
    my $imp_class = $drh->{ImplementorClass}
	or Carp::croak("DBI _new_dbh: $drh has no ImplementorClass");
    substr($imp_class,-4,4) = '::db';
    my $app_class = ref $drh;
    substr($app_class,-4,4) = '::db';
    $attr->{Err}    ||= \my $err;
    $attr->{Errstr} ||= \my $errstr;
    $attr->{State}  ||= \my $state;
    _new_handle($app_class, $drh, $attr, $imp_data, $imp_class);
}

sub _new_sth {	# called by DBD::<drivername>::db::prepare)
    my ($dbh, $attr, $imp_data) = @_;
    my $imp_class = $dbh->{ImplementorClass}
	or Carp::croak("DBI _new_sth: $dbh has no ImplementorClass");
    substr($imp_class,-4,4) = '::st';
    my $app_class = ref $dbh;
    substr($app_class,-4,4) = '::st';
    _new_handle($app_class, $dbh, $attr, $imp_data, $imp_class);
}


# end of DBI package



# --------------------------------------------------------------------
# === The internal DBI Switch pseudo 'driver' class ===

{   package	# hide from PAUSE
	DBD::Switch::dr;
    DBI->setup_driver('DBD::Switch');	# sets up @ISA

    $DBD::Switch::dr::imp_data_size = 0;
    $DBD::Switch::dr::imp_data_size = 0;	# avoid typo warning
    my $drh;

    sub driver {
	return $drh if $drh;	# a package global

	my $inner;
	($drh, $inner) = DBI::_new_drh('DBD::Switch::dr', {
		'Name'    => 'Switch',
		'Version' => $DBI::VERSION,
		'Attribution' => "DBI $DBI::VERSION by Tim Bunce",
	    });
	Carp::croak("DBD::Switch init failed!") unless ($drh && $inner);
	return $drh;
    }
    sub CLONE {
	undef $drh;
    }

    sub FETCH {
	my($drh, $key) = @_;
	return DBI->trace if $key eq 'DebugDispatch';
	return undef if $key eq 'DebugLog';	# not worth fetching, sorry
	return $drh->DBD::_::dr::FETCH($key);
	undef;
    }
    sub STORE {
	my($drh, $key, $value) = @_;
	if ($key eq 'DebugDispatch') {
	    DBI->trace($value);
	} elsif ($key eq 'DebugLog') {
	    DBI->trace(-1, $value);
	} else {
	    $drh->DBD::_::dr::STORE($key, $value);
	}
    }
}


# --------------------------------------------------------------------
# === OPTIONAL MINIMAL BASE CLASSES FOR DBI SUBCLASSES ===

# We only define default methods for harmless functions.
# We don't, for example, define a DBD::_::st::prepare()

{   package		# hide from PAUSE
	DBD::_::common; # ====== Common base class methods ======
    use strict;

    # methods common to all handle types:

    sub _not_impl {
	my ($h, $method) = @_;
	$h->trace_msg("Driver does not implement the $method method.\n");
	return;	# empty list / undef
    }

    # generic TIEHASH default methods:
    sub FIRSTKEY { }
    sub NEXTKEY  { }
    sub EXISTS   { defined($_[0]->FETCH($_[1])) } # XXX undef?
    sub CLEAR    { Carp::carp "Can't CLEAR $_[0] (DBI)" }

    sub FETCH_many {    # XXX should move to C one day
        my $h = shift;
        return map { $h->FETCH($_) } @_;
    }

    *dump_handle = \&DBI::dump_handle;

    sub install_method {
	# special class method called directly by apps and/or drivers
	# to install new methods into the DBI dispatcher
	# DBD::Foo::db->install_method("foo_mumble", { usage => [...], options => '...' });
	my ($class, $method, $attr) = @_;
	Carp::croak("Class '$class' must begin with DBD:: and end with ::db or ::st")
	    unless $class =~ /^DBD::(\w+)::(dr|db|st)$/;
	my ($driver, $subtype) = ($1, $2);
	Carp::croak("invalid method name '$method'")
	    unless $method =~ m/^([a-z]+_)\w+$/;
	my $prefix = $1;
	my $reg_info = $dbd_prefix_registry->{$prefix};
	Carp::carp("method name prefix '$prefix' is not associated with a registered driver") unless $reg_info;

	my $full_method = "DBI::${subtype}::$method";
	$DBI::installed_methods{$full_method} = $attr;

	my (undef, $filename, $line) = caller;
	# XXX reformat $attr as needed for _install_method
	my %attr = %{$attr||{}}; # copy so we can edit
	DBI->_install_method("DBI::${subtype}::$method", "$filename at line $line", \%attr);
    }

    sub parse_trace_flags {
	my ($h, $spec) = @_;
	my $level = 0;
	my $flags = 0;
	my @unknown;
	for my $word (split /\s*[|&,]\s*/, $spec) {
	    if (DBI::looks_like_number($word) && $word <= 0xF && $word >= 0) {
		$level = $word;
	    } elsif ($word eq 'ALL') {
		$flags = 0x7FFFFFFF; # XXX last bit causes negative headaches
		last;
	    } elsif (my $flag = $h->parse_trace_flag($word)) {
		$flags |= $flag;
	    }
	    else {
		push @unknown, $word;
	    }
	}
	if (@unknown && (ref $h ? $h->FETCH('Warn') : 1)) {
	    Carp::carp("$h->parse_trace_flags($spec) ignored unknown trace flags: ".
		join(" ", map { DBI::neat($_) } @unknown));
	}
	$flags |= $level;
	return $flags;
    }

    sub parse_trace_flag {
	my ($h, $name) = @_;
	#      0xddDDDDrL (driver, DBI, reserved, Level)
	return 0x00000100 if $name eq 'SQL';
	return;
    }

    sub private_attribute_info {
        return undef;
    }

}

{   

=pod

=begin classdoc

Driver handle. The parent object for database handles; acts as a factory
for database handles.

@member Kids (integer, read-only) the number of currently existing database
	handles created from that driver handle.
	
@member CachedKids (hash ref) a reference to the cache (hash) of database handles created by 
	the <method>DBI::connect_cached</method> method.

@member Warn	(boolean, inherited) enables useful warnings (which
	can be intercepted using the <code>$SIG{__WARN__}</code> hook) for certain bad practices;

@member Type (scalar, read-only) "dr" (the type of this handle object)

@member ChildHandles (array ref, read-only) a reference to an array of all
	connection handles created by this handle which are still accessible.  The
	contents of the array are weak-refs and will become undef when the
	handle goes out of scope. <code>undef</code> if your Perl version does not support weak
	references (check the <cpan>Scalar::Util|Scalar::Util</cpan> module).

@member CompatMode (boolean, inherited) used by emulation layers (such as
	Oraperl) to enable compatible behaviour in the underlying driver (e.g., DBD::Oracle) for this handle. 
	Not normally set by application code. Disables the 'quick FETCH' of attribute
	values from this handle's attribute cache so all attribute values
	are handled by the drivers own FETCH method.

@member PrintWarn (boolean, inherited) controls printing of warnings issued
	by this handle.  When true, DBI checks method calls to see if a warning condition has 
	been set. If so, DBI effectively does a <code>warn("$class $method warning: $DBI::errstr")</code>
	where <code>$class</code> is the driver class and <code>$method</code> is the name of
	the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintWarn</code> "on" if $^W is true.
	<p>
	Warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.
	<p>
	See also <method>set_err</method> for how warnings are recorded and <member>HandleSetErr</member>
	for how to influence it.

@member PrintError (boolean, inherited) forces errors to generate warnings (using
	<code>warn</code>) in addition to returning error codes in the normal way.  When true,
	any method which results in an error causes DBI to effectively do a 
	<code>warn("$class $method failed: $DBI::errstr")</code> where <code>$class</code>
	is the driver class and <code>$method</code> is the name of the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintError</code> "on".
	<p>
	If desired, the warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.

@member PrintError (boolean, inherited) When true, forces errors to generate warnings 
	(in addition to returning error codes in the normal way)
	via a <code>warn("$class $method failed: $DBI::errstr")</code>, where <code>$class</code>
	is the driver class and <code>$method</code> is the name of the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintError</code> "on".
	<p>
	If desired, the warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.

@member RaiseError (boolean, inherited) When true (default false), errors raise exceptions rather
	than simply returning error codes in the normal way.
	Exceptions are raised via a <code>die("$class $method failed: $DBI::errstr")</code>,
	where <code>$class</code> is the driver class and <code>$method</code> is the name of the method
	that failed.
	<p>
	If <code>PrintError</code> is also on, the <code>PrintError</code> is done first.
	<p>
	Typically <code>RaiseError</code> is used in conjunction with <code>eval { ... }</code>
	to catch the exception that's been thrown and followed by an
	<code>if ($@) { ... }</code> block to handle the caught exception.
	For example:
<pre>
  eval {
    ...
    $sth->execute();
    ...
  };
  if ($@) {
    # $sth->err and $DBI::err will be true if error was from DBI
    warn $@; # print the error
    ... # do whatever you need to deal with the error
  }
</pre>

@member HandleError (code ref, inherited) When set to a subroutine reference, provides
	alternative behaviour in case of errors. The subroutine reference is called when an 
	error is detected (at the same point that <code>RaiseError</code> and <code>PrintError</code> are handled).
	<p>
	The subroutine is called with three parameters: the error message
	string, this handle object, and the first value returned by
	the method that failed (typically undef).
	<p>
	If the subroutine returns a false value, the <code>RaiseError</code>
	and/or <code>PrintError</code> attributes are checked and acted upon as normal.
	<p>
	For example, to <code>die</code> with a full stack trace for any error:
<pre>
  use Carp;
  $h->{HandleError} = sub { confess(shift) };
</pre>
	Or to turn errors into exceptions:
<pre>
  use Exception; # or your own favourite exception module
  $h->{HandleError} = sub { Exception->new('DBI')->raise($_[0]) };
</pre>
	It is possible to 'stack' multiple HandleError handlers by using closures:
<pre>
  sub your_subroutine {
    my $previous_handler = $h->{HandleError};
    $h->{HandleError} = sub {
      return 1 if $previous_handler and &$previous_handler(@_);
      ... your code here ...
    };
  }
</pre>
	The error message that will be used by <code>RaiseError</code> and <code>PrintError</code>
	can be altered by changing the value of <code>$_[0]</code>.
	<p>
	Errors may be suppressed, to a limited extent, by using <method>set_err</method> to 
	reset $DBI::err and $DBI::errstr, and altering the return value of the failed method:
<pre>
  $h->{HandleError} = sub {
    return 0 unless $_[0] =~ /^\S+ fetchrow_arrayref failed:/;
    return 0 unless $_[1]->err == 1234; # the error to 'hide'
    $h->set_err(undef,undef);	# turn off the error
    $_[2] = [ ... ];	# supply alternative return value
    return 1;
  };
</pre>

@member HandleSetErr (code ref, inherited) When set to a subroutien reference, intercepts
	the setting of this handle's <code>err</code>, <code>errstr</code>, and <code>state</code> values.
	<p>
	The subroutine is called the arguments that	were passed to set_err(): the handle, 
	the <code>err</code>, <code>errstr</code>, and <code>state</code> values being set, 
	and the method name. These can be altered by changing the values in the @_ array. 
	The return value affects set_err() behaviour, see <method>set_err</method> for details.
	<p>
	It is possible to 'stack' multiple HandleSetErr handlers by using
	closures. See <member>HandleError</member> for an example.
	<p>
	The <code>HandleSetErr</code> and <code>HandleError</code> subroutines differ in that
	HandleError is only invoked at the point where DBI is about to return to the application 
	with <code>err</code> set true; it is not invoked by the failure of a method that's 
	been called by another DBI method.  HandleSetErr is called
	whenever set_err() is called with a defined <code>err</code> value, even if false.
	Thus, the HandleSetErr subroutine may be called multiple
	times within a method and is usually invoked from deep within driver code.
	<p>
	A driver can use the return value from HandleSetErr via
	set_err() to decide whether to continue or not. If set_err() returns
	an empty list, indicating that the HandleSetErr code has 'handled'
	the 'error', the driver might continue instead of failing. 

@member ErrCount (unsigned integer) the count of calls to set_err() on this handle that recorded an error
	(excluding warnings or information states). It is not reset by the DBI at any time.

@member TraceLevel (integer, inherited) the trace level and flags for this handle. May be used
	to set the trace level and flags. 

@member FetchHashKeyName (string, inherited) Specifies the case conversion applied to the 
	the field names used for the hash keys returned by fetchrow_hashref().
	Defaults to '<code>NAME</code>' but it is recommended to set it to either '<code>NAME_lc</code>'
	or '<code>NAME_uc</code>'.

@member ChopBlanks (boolean, inherited) When true (default false), trailing space characters are 
	trimmed from returned fixed width character (CHAR) fields. No other field types are affected, 
	even where field values have trailing spaces.

@member LongReadLen (unsigned integer, inherited) Sets the maximum
	length of 'long' type fields (LONG, BLOB, CLOB, MEMO, etc.) which the driver will
	read from the database automatically when it fetches each row of data.
	The <code>LongReadLen</code> attribute only relates to fetching and reading
	long values; it is not involved in inserting or updating them.
	<p>
	A value of 0 means not to automatically fetch any long data.
	Drivers may return undef or an empty string for long fields when
	<code>LongReadLen</code> is 0.
	<p>
	The default is typically 0 (zero) bytes but may vary between drivers.
	Applications fetching long fields should set this value to slightly
	larger than the longest long field value to be fetched.
	<p>
	Some databases return some long types encoded as pairs of hex digits.
	For these types, <code>LongReadLen</code> relates to the underlying data
	length and not the doubled-up length of the encoded string.
	<p>
	Changing the value of <code>LongReadLen</code> for a statement handle after it
	has been <code>prepare</code>'d will typically have no effect, so it's common to
	set <code>LongReadLen</code> on the database or driver handle before calling <code>prepare</code>.

@member LongTruncOk (boolean, inherited) When false (the default), fetching a long value that
	needs to be truncated (usually due to exceeding <code>LongReadLen</code>) will cause the fetch to fail.
	(Applications should always be sure to
	check for errors after a fetch loop in case an error, such as a divide
	by zero or long field truncation, caused the fetch to terminate
	prematurely.)
	<p>
	If a fetch fails due to a long field truncation when <code>LongTruncOk</code> is
	false, many drivers will allow you to continue fetching further rows.

@member TaintIn (boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then all the arguments
	to most DBI method calls are checked for being tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.

@member TaintOut (boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then most data fetched
	from the database is considered tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.
	<p>
	Currently only fetched data is tainted. It is possible that the results
	of other DBI method calls, and the value of fetched attributes, may
	also be tainted in future versions.

@member Taint (boolean, inherited) Sets both <member>TaintIn</member> and <member>TaintOut</member>;
	returns a true value if and only if <member>TaintIn</member> and <member>TaintOut</member> are
	both set to true values.

@member ReadOnly (boolean, inherited) When true, indicates that this handle and it's children will 
	not make any changes to the database.
	<p>
	The exact definition of 'read only' is rather fuzzy. See individual driver documentation for specific details.
	<p>
	If the driver can make the handle truly read-only (by issuing a statement like
	"<code>set transaction read only</code>", for example) then it should.
	Otherwise the attribute is simply advisory.
	<p>
	A driver can set the <code>ReadOnly</code> attribute itself to indicate that the data it
	is connected to cannot be changed for some reason.
	<p>
	Library modules and proxy drivers can use the attribute to influence their behavior.
	For example, the DBD::Gofer driver considers the <code>ReadOnly</code> attribute when
	making a decison about whether to retry an operation that failed.
	<p>
	The attribute should be set to 1 or 0 (or undef). Other values are reserved.

=end classdoc

=cut

	package		# hide from PAUSE
	DBD::_::dr;	# ====== DRIVER ======
    @DBD::_::dr::ISA = qw(DBD::_::common);
    use strict;

=pod

=begin classdoc 

@xs err

Return the error code from the last driver method called. 

@return the <i>native</i> database engine error code; may be zero
	to indicate a warning condition. May be an empty string
	to indicate a 'success with information' condition. In both these
	cases the value is false but not undef. The errstr() and state()
	methods may be used to retrieve extra information in these cases.

@see <method>set_err</method>

=end classdoc

=begin classdoc 

@xs errstr

Return the error message from the last driver method called.
<p>
Should not be used to test for errors as some drivers may return 
'success with information' or warning messages via errstr() for 
methods that have not 'failed'.

@return One or more native database engine error messages as a single string;
	multiple messages are separated by newline characters.
	May be an empty string if the prior driver method returned successfully.

@see <method>set_err</method>

=end classdoc

=begin classdoc 

@xs state

Return the standard SQLSTATE five character format code for the prior driver
method.
The success code <code>00000</code> is translated to any empty string
(false). If the driver does not support SQLSTATE (and most don't),
then state() will return <code>S1000</code> (General Error) for all errors.
<p>
The driver is free to return any value via <code>state</code>, e.g., warning
codes, even if it has not declared an error by returning a true value
via the err() method described above.
<p>
Should not be used to test for errors as drivers may return a 
'success with information' or warning state code via state() for 
methods that have not 'failed'.

@return if state is currently successful, an empty string; else,
	a five character SQLSTATE code.

=end classdoc

=begin classdoc 

@xs set_err

Set the <code>err</code>, <code>errstr</code>, and <code>state</code> values for the handle.
If the <member>HandleSetErr</member> attribute holds a reference to a subroutine
it is called first. The subroutine can alter the $err, $errstr, $state,
and $method values. See <member>HandleSetErr</member> for full details.
If the subroutine returns a true value then the handle <code>err</code>,
<code>errstr</code>, and <code>state</code> values are not altered and set_err() returns
an empty list (it normally returns $rv which defaults to undef, see below).
<p>
Setting <code>$err</code> to a <i>true</i> value indicates an error and will trigger
the normal DBI error handling mechanisms, such as <code>RaiseError</code> and
<code>HandleError</code>, if they are enabled, when execution returns from
the DBI back to the application.
<p>
Setting <code>$err</code> to <code>""</code> indicates an 'information' state, and setting
it to <code>"0"</code> indicates a 'warning' state. Setting <code>$err</code> to <code>undef</code>
also sets <code>$errstr</code> to undef, and <code>$state</code> to <code>""</code>, irrespective
of the values of the $errstr and $state parameters.
<p>
The $method parameter provides an alternate method name for the
<code>RaiseError</code>/<code>PrintError</code>/<code>PrintWarn</code> error string instead of
the fairly unhelpful '<code>set_err</code>'.
<p>
Some special rules apply if the <code>err</code> or <code>errstr</code>
values for the handle are <i>already</i> set.
<p>
If <code>errstr</code> is true then: "<code> [err was %s now %s]</code>" is appended if $err is
true and <code>err</code> is already true and the new err value differs from the original
one. Similarly "<code> [state was %s now %s]</code>" is appended if $state is true and <code>state</code> is
already true and the new state value differs from the original one. Finally
"<code>\n</code>" and the new $errstr are appended if $errstr differs from the existing
errstr value. Obviously the <code>%s</code>'s above are replaced by the corresponding values.
<p>
The handle <code>err</code> value is set to $err if: $err is true; or handle
<code>err</code> value is undef; or $err is defined and the length is greater
than the handle <code>err</code> length. The effect is that an 'information'
state only overrides undef; a 'warning' overrides undef or 'information',
and an 'error' state overrides anything.
<p>
The handle <code>state</code> value is set to $state if $state is true and
the handle <code>err</code> value was set (by the rules above).
<p>
This method is typically only used by DBI drivers and DBI subclasses.

@param $err an error code, or "" to indicate success with information, or 0 to indicate warning
@param $errstr a descriptive error message
@optional $state an associated five character SQLSTATE code; defaults to "S1000" if $err is true.
@optional \&method method name included in the
	<code>RaiseError</code>/<code>PrintError</code>/<code>PrintWarn</code> error string
@optional $rv the value to return from this method; default undef
@return the $rv value, if specified; else undef.

=end classdoc

=begin classdoc 

@xs trace

Set the trace settings for the handle object. 
Also can be used to change where trace output is sent.
<p>
A similar method, <code>DBI-&gt;trace</code>, sets the global default trace
settings.

@see <cpan>DBI</cpan> manual TRACING section for full details about DBI's
tracing facilities.

@param $trace_setting	a numeric value indicating a trace level. Valid trace levels are:
<ul>
<li>0 - Trace disabled.
<li>1 - Trace DBI method calls returning with results or errors.
<li>2 - Trace method entry with parameters and returning with results.
<li>3 - As above, adding some high-level information from the driver
      and some internal information from the DBI.
<li>4 - As above, adding more detailed information from the driver.
<li>5 to 15 - As above but with more and more obscure information.
</ul>

@optional $trace_file	either a string filename, or a Perl filehandle reference, to which
	trace output is to be appended. If not spcified, traces are sent to <code>STDOUT</code>.

@return the previous $trace_setting value

=end classdoc

=begin classdoc 

@xs trace_msg

Write a trace message to the handle object's current trace output.

@param $message_text message to be written
$optional $min_level	the minimum trace level at which the message is written; default 1

@see <cpan>DBI</cpan> manual TRACING section for full details about DBI's
tracing facilities.

=end classdoc

=begin classdoc 

@xs func

Call the specified driver private method.
<p>
Note that the function
name is given as the <i>last</i> argument.
<p>
Also note that this method does not clear
a previous error ($DBI::err etc.), nor does it trigger automatic
error detection (RaiseError etc.), so the return
status and/or $h->err must be checked to detect errors.

@param @func_arguments	any arguments to be passed to the function
@param $func the name of the function to be called
@see <code>install_method()</code> in <cpan>DBI::DBD</cpan>
	for directly installing and accessing driver-private methods.

@return any value(s) returned by the specified function

=end classdoc

=begin classdoc 

@xs can

Does this driver or the DBI implement this method ?

@param $method_name name of the method being tested
@return true if $method_name is implemented by the driver or a non-empty default method is provided by DBI;
	otherwise false (i.e., the driver hasn't implemented the method and DBI does not
	provide a non-empty default).

=end classdoc

=begin classdoc 

@xs parse_trace_flags

Parse a string containing trace settings.
Uses the parse_trace_flag() method to process
trace flag names.

@param $trace_settings a string containing a trace level between 0 and 15 and/or 
	trace flag names separated by vertical bar ("<code>|</code>") or comma 
	("<code>,</code>") characters. For example: <code>"SQL|3|foo"</code>.

@return the corresponding integer value used internally by the DBI and drivers.

@since 1.42

=end classdoc

=begin classdoc 

@xs parse_trace_flag

Return the bit flag value for the specified trace flag name.
<p>
Drivers should override this method and
check if $trace_flag_name is a driver specific trace flag and, if
not, then call the DBI's default parse_trace_flag().

@param $trace_flag_name the name of a (possibly driver-specific) trace flag as a string

@return if $trace_flag_name is a valid flag name, the corresponding bit flag; otherwise, undef

@since 1.42

=end classdoc

=begin classdoc 

@xs swap_inner_handle

Swap the internals of 2 handle objects.
Brain transplants for handles. You don't need to know about this
unless you want to become a handle surgeon.
<p>
A DBI handle is a reference to a tied hash. A tied hash has an
<i>inner</i> hash that actually holds the contents.  This
method swaps the inner hashes between two handles. The $h1 and $h2
handles still point to the same tied hashes, but what those hashes
are tied to is swapped.  In effect $h1 <i>becomes</i> $h2 and
vice-versa. This is powerful stuff, expect problems. Use with care.
<p>
As a small safety measure, the two handles, $h1 and $h2, have to
share the same parent unless $allow_reparent is true.
<p>
Here's a quick kind of 'diagram' as a worked example to help think about what's
happening:
<pre>
    Original state:
            dbh1o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh2o -> dbh2i

    swap_inner_handle dbh1o with dbh2o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i

    create new sth from dbh1o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthBo -> sthBi(dbh2i)

    swap_inner_handle sthAo with sthBo:
            dbh2o -> dbh1i
            sthBo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthAo -> sthBi(dbh2i)
</pre>

@param $h2	the handle object to swap with this handle
@optional $allow_reparent	if true, permits the two handles to have
	different parent objects; default is false

@return true if the swap succeeded; otherwise, undef
@since 1.44

=end classdoc

=cut

    sub default_user {
	my ($drh, $user, $pass, $attr) = @_;
	$user = $ENV{DBI_USER} unless defined $user;
	$pass = $ENV{DBI_PASS} unless defined $pass;
	return ($user, $pass);
    }

    sub connect { # normally overridden, but a handy default
	my ($drh, $dsn, $user, $auth) = @_;
	my ($this) = DBI::_new_dbh($drh, {
	    'Name' => $dsn,
	});
	# XXX debatable as there's no "server side" here
	# (and now many uses would trigger warnings on DESTROY)
	# $this->STORE(Active => 1);
        # so drivers should set it in their own connect
	$this;
    }


    sub connect_cached {
        my $drh = shift;
	my ($dsn, $user, $auth, $attr) = @_;

	my $cache = $drh->{CachedKids} ||= {};

	my @attr_keys = $attr ? sort keys %$attr : ();
	my $key = do { local $^W; # silence undef warnings
	    join "~~", $dsn, $user, $auth, $attr ? (@attr_keys,@{$attr}{@attr_keys}) : ()
	};
	my $dbh = $cache->{$key};
        $drh->trace_msg(sprintf("    connect_cached: key '$key', cached dbh $dbh\n", DBI::neat($key), DBI::neat($dbh)))
            if $DBI::dbi_debug >= 4;
        my $cb = $attr->{Callbacks}; # take care not to autovivify
	if ($dbh && $dbh->FETCH('Active') && eval { $dbh->ping }) {
            # If the caller has provided a callback then call it
            if ($cb and $cb = $cb->{"connect_cached.reused"}) {
		local $_ = "connect_cached.reused";
		$cb->($dbh, $dsn, $user, $auth, $attr);
            }
	    return $dbh;
	}

	# If the caller has provided a callback then call it
	if ($cb and $cb = $cb->{"connect_cached.new"}) {
	    local $_ = "connect_cached.new";
	    $cb->($dbh, $dsn, $user, $auth, $attr);
	}

	$dbh = $drh->connect(@_);
	$cache->{$key} = $dbh;	# replace prev entry, even if connect failed
	return $dbh;
    }

}

{

=pod

=begin classdoc

Database <i>(aka Connection)</i> handle. Represents a single logical connection
to a database. Acts as a factory for Statement handle objects. Provides
methods for 
<ul>
<li>preparing queries to create Statement handles
<li>immediately executing queries (without a prepared Statement handle)
<li>transaction control
<li>metadata retrieval
</ul>

@member Active (boolean, read-only) when true, indicates this handle object is "active". 
	The exact meaning of active is somewhat vague at the moment. Typically means that this handle is
	connected to a database

@member Executed (boolean) when true, this handle object has been "executed".
	Only the do() method sets this attribute. When set, also sets the parent driver
	handle's Executed attribute. Cleared by commit() and rollback() methods (even if they fail). 

@member Kids (integer, read-only) the number of currently existing statement handles
	created from this handle.

@member ActiveKids (integer, read-only) the number of currently existing statement handles
	created from this handle that are <code>Active</code>.

@member CachedKids (hash ref) a reference to the cache (hash) of
	statement handles created by the <method>prepare_cached</method> method.

@member Warn	(boolean, inherited) enables useful warnings (which
	can be intercepted using the <code>$SIG{__WARN__}</code> hook) for certain bad practices;

@member Type (scalar, read-only) "db" (the type of this handle object)

@member ChildHandles (array ref, read-only) a reference to an array of all
	statement handles created by this handle which are still accessible.  The
	contents of the array are weak-refs and will become undef when the
	handle goes out of scope. <code>undef</code> if your Perl version does not support weak
	references (check the <cpan>Scalar::Util|Scalar::Util</cpan> module).

@member CompatMode (boolean, inherited) used by emulation layers (such as
	Oraperl) to enable compatible behaviour in the underlying driver (e.g., DBD::Oracle) for this handle. 
	Not normally set by application code. Disables the 'quick FETCH' of attribute
	values from this handle's attribute cache so all attribute values
	are handled by the drivers own FETCH method.

@member InactiveDestroy (boolean) when false (the default),this handle will be fully destroyed
	as normal when the last reference to it is removed. If true, this handle will be treated by 
	DESTROY as if it was no longer Active, and so the <i>database engine</i> related effects of 
	DESTROYing this handle will be skipped. Does not disable an <i>explicit</i>
	call to the disconnect method, only the implicit call from DESTROY
	that happens if the handle is still marked as <code>Active</code>. Designed for use in Unix applications
	that "fork" child processes: Either the parent or the child process
	(but not both) should set <code>InactiveDestroy</code> true on all their shared handles.
	(Note that some databases, including Oracle, don't support passing a
	database connection across a fork.)
	<p>
	To help tracing applications using fork the process id is shown in
	the trace log whenever a DBI or handle trace() method is called.
	The process id also shown for <i>every</i> method call if the DBI trace
	level (not handle trace level) is set high enough to show the trace
	from the DBI's method dispatcher, e.g. >= 9.

@member PrintWarn (boolean, inherited) controls printing of warnings issued
	by this handle.  When true, DBI checks method calls to see if a warning condition has 
	been set. If so, DBI effectively does a <code>warn("$class $method warning: $DBI::errstr")</code>
	where <code>$class</code> is the driver class and <code>$method</code> is the name of
	the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintWarn</code> "on" if $^W is true.
	<p>
	Warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.
	<p>
	See also <method>set_err</method> for how warnings are recorded and <member>HandleSetErr</member>
	for how to influence it.

@member PrintError (boolean, inherited) When true, forces errors to generate warnings 
	(in addition to returning error codes in the normal way)
	via a <code>warn("$class $method failed: $DBI::errstr")</code>, where <code>$class</code>
	is the driver class and <code>$method</code> is the name of the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintError</code> "on".
	<p>
	If desired, the warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.

@member RaiseError (boolean, inherited) When true (default false), errors raise exceptions rather
	than simply returning error codes in the normal way.
	Exceptions are raised via a <code>die("$class $method failed: $DBI::errstr")</code>,
	where <code>$class</code> is the driver class and <code>$method</code> is the name of the method
	that failed.
	<p>
	If <code>PrintError</code> is also on, the <code>PrintError</code> is done first.
	<p>
	Typically <code>RaiseError</code> is used in conjunction with <code>eval { ... }</code>
	to catch the exception that's been thrown and followed by an
	<code>if ($@) { ... }</code> block to handle the caught exception.
	For example:
<pre>
  eval {
    ...
    $sth->execute();
    ...
  };
  if ($@) {
    # $sth->err and $DBI::err will be true if error was from DBI
    warn $@; # print the error
    ... # do whatever you need to deal with the error
  }
</pre>

@member HandleError (code ref, inherited) When set to a subroutine reference, provides
	alternative behaviour in case of errors. The subroutine reference is called when an 
	error is detected (at the same point that <code>RaiseError</code> and <code>PrintError</code> are handled).
	<p>
	The subroutine is called with three parameters: the error message
	string, this handle object, and the first value returned by
	the method that failed (typically undef).
	<p>
	If the subroutine returns a false value, the <code>RaiseError</code>
	and/or <code>PrintError</code> attributes are checked and acted upon as normal.
	<p>
	For example, to <code>die</code> with a full stack trace for any error:
<pre>
  use Carp;
  $h->{HandleError} = sub { confess(shift) };
</pre>
	Or to turn errors into exceptions:
<pre>
  use Exception; # or your own favourite exception module
  $h->{HandleError} = sub { Exception->new('DBI')->raise($_[0]) };
</pre>
	It is possible to 'stack' multiple HandleError handlers by using closures:
<pre>
  sub your_subroutine {
    my $previous_handler = $h->{HandleError};
    $h->{HandleError} = sub {
      return 1 if $previous_handler and &$previous_handler(@_);
      ... your code here ...
    };
  }
</pre>
	The error message that will be used by <code>RaiseError</code> and <code>PrintError</code>
	can be altered by changing the value of <code>$_[0]</code>.
	<p>
	Errors may be suppressed, to a limited extent, by using <method>set_err</method> to 
	reset $DBI::err and $DBI::errstr, and altering the return value of the failed method:
<pre>
  $h->{HandleError} = sub {
    return 0 unless $_[0] =~ /^\S+ fetchrow_arrayref failed:/;
    return 0 unless $_[1]->err == 1234; # the error to 'hide'
    $h->set_err(undef,undef);	# turn off the error
    $_[2] = [ ... ];	# supply alternative return value
    return 1;
  };
</pre>

@member HandleSetErr (code ref, inherited) When set to a subroutien reference, intercepts
	the setting of this handle's <code>err</code>, <code>errstr</code>, and <code>state</code> values.
	<p>
	The subroutine is called the arguments that	were passed to set_err(): the handle, 
	the <code>err</code>, <code>errstr</code>, and <code>state</code> values being set, 
	and the method name. These can be altered by changing the values in the @_ array. 
	The return value affects set_err() behaviour, see <method>set_err</method> for details.
	<p>
	It is possible to 'stack' multiple HandleSetErr handlers by using
	closures. See <member>HandleError</member> for an example.
	<p>
	The <code>HandleSetErr</code> and <code>HandleError</code> subroutines differ in that
	HandleError is only invoked at the point where DBI is about to return to the application 
	with <code>err</code> set true; it is not invoked by the failure of a method that's 
	been called by another DBI method.  HandleSetErr is called
	whenever set_err() is called with a defined <code>err</code> value, even if false.
	Thus, the HandleSetErr subroutine may be called multiple
	times within a method and is usually invoked from deep within driver code.
	<p>
	A driver can use the return value from HandleSetErr via
	set_err() to decide whether to continue or not. If set_err() returns
	an empty list, indicating that the HandleSetErr code has 'handled'
	the 'error', the driver might continue instead of failing. 

@member ErrCount (unsigned integer) the count of calls to set_err() on this handle that recorded an error
	(excluding warnings or information states). It is not reset by the DBI at any time.

@member ShowErrorStatement (boolean, inherited) When true, causes the relevant
	Statement text to be appended to the error messages generated by <code>RaiseError</code>, <code>PrintError</code>, 
	and <code>PrintWarn</code> attributes. Only applies to errors occuring on
	the prepare(), do(), and the various <code>select*()</code> methods.
	<p>
	If <code>$h-&gt;{ParamValues}</code> returns a hash reference of parameter
	(placeholder) values then those are formatted and appended to the
	end of the Statement text in the error message.


@member TraceLevel (integer, inherited) the trace level and flags for this handle. May be used
	to set the trace level and flags. 

@member FetchHashKeyName (string, inherited) Specifies the case conversion applied to the 
	the field names used for the hash keys returned by fetchrow_hashref().
	Defaults to '<code>NAME</code>' but it is recommended to set it to either '<code>NAME_lc</code>'
	or '<code>NAME_uc</code>'.

@member ChopBlanks (boolean, inherited) When true (default false), trailing space characters are 
	trimmed from returned fixed width character (CHAR) fields. No other field types are affected, 
	even where field values have trailing spaces.

@member LongReadLen (unsigned integer, inherited) Sets the maximum
	length of 'long' type fields (LONG, BLOB, CLOB, MEMO, etc.) which the driver will
	read from the database automatically when it fetches each row of data.
	The <code>LongReadLen</code> attribute only relates to fetching and reading
	long values; it is not involved in inserting or updating them.
	<p>
	A value of 0 means not to automatically fetch any long data.
	Drivers may return undef or an empty string for long fields when
	<code>LongReadLen</code> is 0.
	<p>
	The default is typically 0 (zero) bytes but may vary between drivers.
	Applications fetching long fields should set this value to slightly
	larger than the longest long field value to be fetched.
	<p>
	Some databases return some long types encoded as pairs of hex digits.
	For these types, <code>LongReadLen</code> relates to the underlying data
	length and not the doubled-up length of the encoded string.
	<p>
	Changing the value of <code>LongReadLen</code> for a statement handle after it
	has been <code>prepare</code>'d will typically have no effect, so it's common to
	set <code>LongReadLen</code> on the database or driver handle before calling <code>prepare</code>.

@member LongTruncOk (boolean, inherited) When false (the default), fetching a long value that
	needs to be truncated (usually due to exceeding <code>LongReadLen</code>) will cause the fetch to fail.
	(Applications should always be sure to
	check for errors after a fetch loop in case an error, such as a divide
	by zero or long field truncation, caused the fetch to terminate
	prematurely.)
	<p>
	If a fetch fails due to a long field truncation when <code>LongTruncOk</code> is
	false, many drivers will allow you to continue fetching further rows.

@member TaintIn (boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then all the arguments
	to most DBI method calls are checked for being tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.

@member TaintOut (boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then most data fetched
	from the database is considered tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.
	<p>
	Currently only fetched data is tainted. It is possible that the results
	of other DBI method calls, and the value of fetched attributes, may
	also be tainted in future versions.

@member Taint (boolean, inherited) Sets both <member>TaintIn</member> and <member>TaintOut</member>;
	returns a true value if and only if <member>TaintIn</member> and <member>TaintOut</member> are
	both set to true values.

@member ReadOnly (boolean, inherited) When true, indicates that this handle and it's children will 
	not make any changes to the database.
	<p>
	The exact definition of 'read only' is rather fuzzy. See individual driver documentation for specific details.
	<p>
	If the driver can make the handle truly read-only (by issuing a statement like
	"<code>set transaction read only</code>", for example) then it should.
	Otherwise the attribute is simply advisory.
	<p>
	A driver can set the <code>ReadOnly</code> attribute itself to indicate that the data it
	is connected to cannot be changed for some reason.
	<p>
	Library modules and proxy drivers can use the attribute to influence their behavior.
	For example, the DBD::Gofer driver considers the <code>ReadOnly</code> attribute when
	making a decison about whether to retry an operation that failed.
	<p>
	The attribute should be set to 1 or 0 (or undef). Other values are reserved.

@member AutoCommit  (boolean) When true (the usual default), database changes executed by this handle 
	cannot be rolled-back (undone).	If false, database changes automatically occur within a "transaction", which
	must explicitly be committed or rolled back using the <code>commit</code> or <code>rollback</code>
	methods.
	<p>
	See <method>commit</method>, <method>rollback</method>, and <method>disconnect</method>
	for additional information regarding use of AutoCommit.

@member Driver  (handle) the parent driver handle object.

@member Name  (string) the "name" of the database. Usually (and recommended to be) the
	same as the DSN string used to connect to the database
	with the leading "<code>dbi:DriverName:</code>" removed.

@member Statement  (string, read-only) the statement string passed to the most 
	recent <method>prepare</method> method call by this database handle, 
	even if that method failed. 

@member RowCacheSize  (integer) A hint to the driver indicating the size of the local row cache that the
	application would like the driver to use for data returning statements.
	Ignored (returning <code>undef</code>) if a row cache is not implemented.
	<p>
	The following values have special meaning:
	<ul>
	<li>0 - Automatically determine a reasonable cache size for each data returning
	<li>1 - Disable the local row cache
	<li>&gt;1 - Cache this many rows
 	<li>&lt;0 - Cache as many rows that will fit into this much memory for each data returning.
	</ul>
	Note that large cache sizes may require a very large amount of memory
	(<i>cached rows * maximum size of row</i>). Also, a large cache will cause
	a longer delay not only for the first fetch, but also whenever the
	cache needs refilling.
	<p>
	See <member>DBD::_::st::RowsInCache</member>.

@member Username  (string) the username used to connect to the database.

=end classdoc

=cut


	package		# hide from PAUSE
	DBD::_::db;	# ====== DATABASE ======
    @DBD::_::db::ISA = qw(DBD::_::common);
    use strict;

=pod

=begin classdoc 

@xs err

Return the error code from the last driver method called. 

@return the <i>native</i> database engine error code; may be zero
	to indicate a warning condition. May be an empty string
	to indicate a 'success with information' condition. In both these
	cases the value is false but not undef. The errstr() and state()
	methods may be used to retrieve extra information in these cases.

@see <method>set_err</method>

=end classdoc

=begin classdoc 

@xs errstr

Return the error message from the last driver method called.
<p>
Should not be used to test for errors as some drivers may return 
'success with information' or warning messages via errstr() for 
methods that have not 'failed'.

@return One or more native database engine error messages as a single string;
	multiple messages are separated by newline characters.
	May be an empty string if the prior driver method returned successfully.

@see <method>set_err</method>

=end classdoc

=begin classdoc 

@xs state

Return the standard SQLSTATE five character format code for the prior driver
method.
The success code <code>00000</code> is translated to any empty string
(false). If the driver does not support SQLSTATE (and most don't),
then state() will return <code>S1000</code> (General Error) for all errors.
<p>
The driver is free to return any value via <code>state</code>, e.g., warning
codes, even if it has not declared an error by returning a true value
via the err() method described above.
<p>
Should not be used to test for errors as drivers may return a 
'success with information' or warning state code via state() for 
methods that have not 'failed'.

@return if state is currently successful, an empty string; else,
	a five character SQLSTATE code.

=end classdoc

=begin classdoc 

@xs set_err

Set the <code>err</code>, <code>errstr</code>, and <code>state</code> values for the handle.
If the <member>HandleSetErr</member> attribute holds a reference to a subroutine
it is called first. The subroutine can alter the $err, $errstr, $state,
and $method values. See <member>HandleSetErr</member> for full details.
If the subroutine returns a true value then the handle <code>err</code>,
<code>errstr</code>, and <code>state</code> values are not altered and set_err() returns
an empty list (it normally returns $rv which defaults to undef, see below).
<p>
Setting <code>$err</code> to a <i>true</i> value indicates an error and will trigger
the normal DBI error handling mechanisms, such as <code>RaiseError</code> and
<code>HandleError</code>, if they are enabled, when execution returns from
the DBI back to the application.
<p>
Setting <code>$err</code> to <code>""</code> indicates an 'information' state, and setting
it to <code>"0"</code> indicates a 'warning' state. Setting <code>$err</code> to <code>undef</code>
also sets <code>$errstr</code> to undef, and <code>$state</code> to <code>""</code>, irrespective
of the values of the $errstr and $state parameters.
<p>
The $method parameter provides an alternate method name for the
<code>RaiseError</code>/<code>PrintError</code>/<code>PrintWarn</code> error string instead of
the fairly unhelpful '<code>set_err</code>'.
<p>
Some special rules apply if the <code>err</code> or <code>errstr</code>
values for the handle are <i>already</i> set.
<p>
If <code>errstr</code> is true then: "<code> [err was %s now %s]</code>" is appended if $err is
true and <code>err</code> is already true and the new err value differs from the original
one. Similarly "<code> [state was %s now %s]</code>" is appended if $state is true and <code>state</code> is
already true and the new state value differs from the original one. Finally
"<code>\n</code>" and the new $errstr are appended if $errstr differs from the existing
errstr value. Obviously the <code>%s</code>'s above are replaced by the corresponding values.
<p>
The handle <code>err</code> value is set to $err if: $err is true; or handle
<code>err</code> value is undef; or $err is defined and the length is greater
than the handle <code>err</code> length. The effect is that an 'information'
state only overrides undef; a 'warning' overrides undef or 'information',
and an 'error' state overrides anything.
<p>
The handle <code>state</code> value is set to $state if $state is true and
the handle <code>err</code> value was set (by the rules above).
<p>
This method is typically only used by DBI drivers and DBI subclasses.

@param $err an error code, or "" to indicate success with information, or 0 to indicate warning
@param $errstr a descriptive error message
@optional $state an associated five character SQLSTATE code; defaults to "S1000" if $err is true.
@optional \&method method name included in the
	<code>RaiseError</code>/<code>PrintError</code>/<code>PrintWarn</code> error string
@optional $rv the value to return from this method; default undef
@return the $rv value, if specified; else undef.

=end classdoc

=begin classdoc 

@xs trace

Set the trace settings for the handle object. 
Also can be used to change where trace output is sent.
<p>
A similar method, <code>DBI-&gt;trace</code>, sets the global default trace
settings.

@see <cpan>DBI</cpan> manual TRACING section for full details about DBI's
tracing facilities.

@param $trace_setting	a numeric value indicating a trace level. Valid trace levels are:
<ul>
<li>0 - Trace disabled.
<li>1 - Trace DBI method calls returning with results or errors.
<li>2 - Trace method entry with parameters and returning with results.
<li>3 - As above, adding some high-level information from the driver
      and some internal information from the DBI.
<li>4 - As above, adding more detailed information from the driver.
<li>5 to 15 - As above but with more and more obscure information.
</ul>

@optional $trace_file	either a string filename, or a Perl filehandle reference, to which
	trace output is to be appended. If not spcified, traces are sent to <code>STDOUT</code>.

@return the previous $trace_setting value

=end classdoc

=begin classdoc 

@xs trace_msg

Write a trace message to the handle object's current trace output.

@param $message_text message to be written
$optional $min_level	the minimum trace level at which the message is written; default 1

@see <cpan>DBI</cpan> manual TRACING section for full details about DBI's
tracing facilities.

=end classdoc

=begin classdoc 

@xs func

Call the specified driver private method.
<p>
Note that the function
name is given as the <i>last</i> argument.
<p>
Also note that this method does not clear
a previous error ($DBI::err etc.), nor does it trigger automatic
error detection (RaiseError etc.), so the return
status and/or $h->err must be checked to detect errors.

@param @func_arguments	any arguments to be passed to the function
@param $func the name of the function to be called
@see <code>install_method</code> in <cpan>DBI::DBD</cpan>
	for directly installing and accessing driver-private methods.

@return any value(s) returned by the specified function

=end classdoc

=begin classdoc 

@xs can

Does this driver or the DBI implement this method ?

@param $method_name name of the method being tested
@return true if $method_name is implemented by the driver or a non-empty default method is provided by DBI;
	otherwise false (i.e., the driver hasn't implemented the method and DBI does not
	provide a non-empty default).

=end classdoc

=begin classdoc 

@xs parse_trace_flags

Parse a string containing trace settings.
Uses the parse_trace_flag() method to process
trace flag names.

@param $trace_settings a string containing a trace level between 0 and 15 and/or 
	trace flag names separated by vertical bar ("<code>|</code>") or comma 
	("<code>,</code>") characters. For example: <code>"SQL|3|foo"</code>.

@return the corresponding integer value used internally by the DBI and drivers.

@since 1.42

=end classdoc

=begin classdoc 

@xs parse_trace_flag

Return the bit flag value for the specified trace flag name.
<p>
Drivers should override this method and
check if $trace_flag_name is a driver specific trace flag and, if
not, then call the DBI's default parse_trace_flag().

@param $trace_flag_name the name of a (possibly driver-specific) trace flag as a string

@return if $trace_flag_name is a valid flag name, the corresponding bit flag; otherwise, undef

@since 1.42

=end classdoc

=begin classdoc 

@xs swap_inner_handle

Swap the internals of 2 handle objects.
Brain transplants for handles. You don't need to know about this
unless you want to become a handle surgeon.
<p>
A DBI handle is a reference to a tied hash. A tied hash has an
<i>inner</i> hash that actually holds the contents.  This
method swaps the inner hashes between two handles. The $h1 and $h2
handles still point to the same tied hashes, but what those hashes
are tied to is swapped.  In effect $h1 <i>becomes</i> $h2 and
vice-versa. This is powerful stuff, expect problems. Use with care.
<p>
As a small safety measure, the two handles, $h1 and $h2, have to
share the same parent unless $allow_reparent is true.
<p>
Here's a quick kind of 'diagram' as a worked example to help think about what's
happening:
<pre>
    Original state:
            dbh1o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh2o -> dbh2i

    swap_inner_handle dbh1o with dbh2o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i

    create new sth from dbh1o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthBo -> sthBi(dbh2i)

    swap_inner_handle sthAo with sthBo:
            dbh2o -> dbh1i
            sthBo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthAo -> sthBi(dbh2i)
</pre>

@param $h2	the handle object to swap with this handle
@optional $allow_reparent	if true, permits the two handles to have
	different parent objects; default is false

@return true if the swap succeeded; otherwise, undef
@since 1.44

=end classdoc

=begin classdoc

@xs last_insert_id

Return the database server assigned unique identifier for the
prior inserted row.
<p>
NOTE:
<ul>
<li>For some drivers the value may only available immediately after
the insert statement has executed (e.g., mysql, Informix).

<li>For some drivers the $catalog, $schema, $table, and $field parameters
are required, for others they are ignored (e.g., mysql).

<li>Drivers may return an indeterminate value if no insert has
been performed yet.

<li>For some drivers the value may only be available if placeholders
have <i>not</i> been used (e.g., Sybase, MS SQL). In this case the value
returned would be from the last non-placeholder insert statement.

<li>Some drivers may need driver-specific hints about how to get
the value. For example, being told the name of the database 'sequence'
object that holds the value. Any such hints are passed as driver-specific
attributes in the \%attr parameter.

<li>If the underlying database offers nothing better, some
drivers may attempt to implement this method by executing
"<code>select max($field) from $table</code>". Drivers using any approach
like this should issue a warning if <code>AutoCommit</code> is true because
it is generally unsafe - another process may have modified the table
between your insert and the select. For situations where you know
it is safe, such as when you have locked the table, you can silence
the warning by passing <code>Warn</code> => 0 in \%attr.

<li>If no insert has been performed yet, or the last insert failed,
then the value is implementation defined.
</ul>

@param $catalog	the catalog name string for the inserted row; <code>undef</code> if not required
@param $schema	the schema  name string for the inserted row; <code>undef</code> if not required
@param $table	the table  name string for the inserted row; <code>undef</code> if not required
@param $field	the column  name string containing the insert identifier field for the inserted row; <code>undef</code> if not required
@optional \%attr	any required attributes. DBI specifies the <code>Warn =&gt; 0 </code>
	attribute to silence possible warnings emitted as described above.

@return a value 'identifying' the row just inserted. Typically a value assigned by 
	the database server to a column with an <i>auto_increment</i> or <i>serial</i> type.
	Returns undef if the driver does not support the method or can't determine the value.

@since 1.38.

=end classdoc

=begin classdoc

@xs prepare

Prepare a statement for later execution by the database
engine. Creates a Statement handle object ot be used to execute and
manage the resulting query.
<p>
Drivers for databases which cannot prepare a
statement will typically store the statement in the returned
handle and process it when on a later Statement handle <code>execute</code> call. Such drivers are
unlikely to provide statement metadata until after <code>execute()</code>
has been called.
<p>
Portable applications should not assume that a new statement can be
prepared and/or executed while still fetching results from a previous
statement.
<p>
Some command-line SQL tools require statement terminators, like a semicolon,
to indicate the end of a statement; such terminators should not normally
be required with the DBI.
<p>
The returned statement handle can be used to get the
statement metadata and invoke the <method>DBD::_::st::execute</method> method. 

@see <a href='DBI.pod.html#Statement_Handle_Methods'>Statement Handle Methods</a>.
@see <package>DBD::_::st</package> package

@param $statement	the query string to be prepared.
@optional \%attr	a hash reference of attributes to be applied to the resulting prepared Statement handle
@return on success, a Statement handle object; otherwise, <code>undef</code>, with error information
	available via the err(), errstr(), and state() methods.

=end classdoc

=begin classdoc

@xs commit

Commit (make permanent) the most recent series of database changes
if the database supports transactions and AutoCommit is off.
<p>
If <code>AutoCommit</code> is on, issues
a "commit ineffective with AutoCommit" warning.

@return true on success, <code>undef</code> on failure.
@see <a href='DBI.pod.html#Transactions'>Transactions</a> in the DBI manual.

=end classdoc

=begin classdoc

@xs rollback

Rollback (undo) the most recent series of uncommitted database
changes if the database supports transactions and AutoCommit is off.
<p>
If <code>AutoCommit</code> is on, issues a "rollback ineffective with AutoCommit" warning.

@return true on success, <code>undef</code> on failure.
@see <a href='DBI.pod.html#Transactions'>Transactions</a> in the DBI manual.

=end classdoc

=begin classdoc

@xs disconnect

Disconnects the database from the database handle. Typically only used
before exiting the program. The handle is of little use after disconnecting.
<p>
The transaction behaviour of the <code>disconnect</code> method is
undefined.  Some database systems will
automatically commit any outstanding changes; others will rollback any outstanding changes.
Applications not using <code>AutoCommit</code> should explicitly call <code>commit</code> or 
<code>rollback</code> before calling <code>disconnect</code>.
<p>
The database is automatically disconnected by the <code>DESTROY</code> method if
still connected when there are no longer any references to the handle.
<p>
A warning is issued if called while some statement handles are active
(e.g., SELECT statement handles that have more data to fetch), 
The warning may indicate that a fetch loop terminated early, perhaps due to an uncaught error.
To avoid the warning, call the <code>finish</code> method on the active handles.

@return true on success, <code>undef</code> on failure.

=end classdoc

=begin classdoc

@xs get_info

Return metadata about the driver and data source capabilities, restrictions etc. 
For example
<pre>
  $database_version  = $dbh->get_info(  18 ); # SQL_DBMS_VER
  $max_select_tables = $dbh->get_info( 106 ); # SQL_MAXIMUM_TABLES_IN_SELECT
</pre>
The <cpan>DBI::Const::GetInfoType</cpan> module exports a <code>%GetInfoType</code>
hash that can be used to map info type names to numbers. For example:
<pre>
  use DBI::Const::GetInfoType qw(%GetInfoType);
  $database_version = $dbh->get_info( $GetInfoType{SQL_DBMS_VER} );
</pre>
The names are a merging of the ANSI and ODBC standards (which differ
in some cases).

@param $info_type the type code for the information to be returned
@return a type and driver specific value, or <code>undef</code> for
	unknown or unimplemented information types.
@see <a href='DBI.pod.html#Standards_Reference_Information'>Standards Reference Information</a>
@see <cpan>DBI::Const::GetInfoType</cpan>

=end classdoc

=begin classdoc

@xs table_info

Create an active statement handle to return table metadata.
<p>
The arguments $catalog, $schema and $table may accept search patterns
according to the database/driver, for example: $table = '%FOO%';
The underscore character ('<code>_</code>') matches any single character,
while the percent character ('<code>%</code>') matches zero or more
characters.
<p>
Some drivers may return additional information:
<ul>
<li>If the value of $catalog is '%' and $schema and $table name
are empty strings, the result set contains a list of catalog names.
For example:
<pre>
  $sth = $dbh->table_info('%', '', '');
</pre>

<li>If the value of $schema is '%' and $catalog and $table are empty
strings, the result set contains a list of schema names.

<li>If the value of $type is '%' and $catalog, $schema, and $table are all
empty strings, the result set contains a list of table types.
</ul>

Drivers which do not support one or more of the selection filter
parameters may return metadata for more tables than requested, which may
require additional filtering by the application.
<p>
Note that this method can be expensive, and may return a large amount of data.
Best practice is to apply the most specific filters possible.
Also, some database might not return rows for all tables, and,
if the search criteria do not match any tables, the returned statement handle may return no rows.

@param $catalog	search pattern for catalogs to be queried; <code>undef</code> if not required
@param $schema	search pattern for schemas to be queried; <code>undef</code> if not required
@param $table	search pattern for tables to be queried; <code>undef</code> if not required
@param $type	a comma-separated list of one or more types of tables for which metadata is to be returned.
	Each value may optionally be quoted.
@optional \%attr	any required additional attributes

@return <code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present):
<ol>
<li>TABLE_CAT: Table catalog identifier. This field is NULL (<code>undef</code>) if not
applicable to the data source, which is usually the case. This field
is empty if not applicable to the table.

<li>TABLE_SCHEM: The name of the schema containing the TABLE_NAME value.
This field is NULL (<code>undef</code>) if not applicable to data source, and
empty if not applicable to the table.

<li>TABLE_NAME: Name of the table (or view, synonym, etc).

<li>TABLE_TYPE: One of the following: "TABLE", "VIEW", "SYSTEM TABLE",
"GLOBAL TEMPORARY", "LOCAL TEMPORARY", "ALIAS", "SYNONYM" or a type
identifier that is specific to the data source.

<li>REMARKS: A description of the table. May be NULL (<code>undef</code>).
</ol>

@see <method>tables</method>
@see <a href='DBI.pod.html#Catalog_Methods'>Catalog Methods</a> in the DBI manual
@see <a href='DBI.pod.html#Standards_Reference_Information'>Standards Reference Information</a> in the DBI manual

=end classdoc

=begin classdoc

@xs column_info

Create an active statement handle to return column metadata.
<p>
The arguments $catalog, $schema, $table, and column may accept search patterns
according to the database/driver, for example: $table = '%FOO%';
The underscore character ('<code>_</code>') matches any single character,
while the percent character ('<code>%</code>') matches zero or more
characters.
<p>
Drivers which do not support one or more of the selection filter
parameters may return metadata for more tables than requested, which may
require additional filtering by the application.
<p>
If the search criteria do not match any columns, the returned statement handle may return no rows.
<p>
Some drivers may provide additional metadata beyond that listed below.
using lowercase field names with the driver-specific prefix. 
Such fields should be accessed by name, not by column number.
<p>
Note: There is some overlap with statement attributes (in Perl) and
SQLDescribeCol (in ODBC). However, SQLColumns provides more metadata.


@param $catalog	search pattern for catalogs to be queried; <code>undef</code> if not required
@param $schema	search pattern for schemas to be queried; <code>undef</code> if not required
@param $table	search pattern for tables to be queried; <code>undef</code> if not required
@param $column	search pattern for columns to be queried; <code>undef</code> if not required

@return <code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present),
	ordered by TABLE_CAT, TABLE_SCHEM, TABLE_NAME, and ORDINAL_POSITION:

<ol>
<li>TABLE_CAT: The catalog identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>TABLE_SCHEM: The schema identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>TABLE_NAME: The table identifier.
Note: A driver may provide column metadata not only for base tables, but
also for derived objects like SYNONYMS etc.

<li>COLUMN_NAME: The column identifier.

<li>DATA_TYPE: The concise data type code.

<li>TYPE_NAME: A data source dependent data type name.

<li>COLUMN_SIZE: The column size.
This is the maximum length in characters for character data types,
the number of digits or bits for numeric data types or the length
in the representation of temporal types.
See the relevant specifications for detailed information.

<li>BUFFER_LENGTH: The length in bytes of transferred data.

<li>DECIMAL_DIGITS: The total number of significant digits to the right of
the decimal point.

<li>NUM_PREC_RADIX: The radix for numeric precision.
The value is 10 or 2 for numeric data types and NULL (<code>undef</code>) if not
applicable.

<li>NULLABLE: Indicates if a column can accept NULLs.
The following values are defined:
<ul>
<li>SQL_NO_NULLS (0)
<li>SQL_NULLABLE (1)
<li>SQL_NULLABLE_UNKNOWN (2)
</ul>

<li>REMARKS: A description of the column.

<li>COLUMN_DEF: The default value of the column.

<li>SQL_DATA_TYPE: The SQL data type.

<li>SQL_DATETIME_SUB: The subtype code for datetime and interval data types.

<li>CHAR_OCTET_LENGTH: The maximum length in bytes of a character or binary
data type column.

<li>ORDINAL_POSITION: The column sequence number (starting with 1).

<li>IS_NULLABLE: Indicates if the column can accept NULLs.
Possible values are: 'NO', 'YES' and ''.
</ol>

SQL/CLI defines the following additional columns:
<pre>
  CHAR_SET_CAT
  CHAR_SET_SCHEM
  CHAR_SET_NAME
  COLLATION_CAT
  COLLATION_SCHEM
  COLLATION_NAME
  UDT_CAT
  UDT_SCHEM
  UDT_NAME
  DOMAIN_CAT
  DOMAIN_SCHEM
  DOMAIN_NAME
  SCOPE_CAT
  SCOPE_SCHEM
  SCOPE_NAME
  MAX_CARDINALITY
  DTD_IDENTIFIER
  IS_SELF_REF
</pre>
Drivers capable of supplying any of those values should do so in
the corresponding column and supply undef values for the others.

@see <a href='DBI.pod.html#Catalog_Methods'>Catalog Methods</a> in the DBI manual
@see <a href='DBI.pod.html#Standards_Reference_Information'>Standards Reference Information</a> in the DBI manual

=end classdoc

=begin classdoc

@xs primary_key_info

Create an active statement handle to return metadata about columns that 
make up the primary key for a table.
The arguments don't accept search patterns (unlike table_info()).
<p>
The statement handle will return one row per column.
If there is no primary key, the statement handle will fetch no rows.
<p>
Note: The support for the selection criteria, such as $catalog, is
driver specific.  If the driver doesn't support catalogs and/or
schemas, it may ignore these criteria.

@param $catalog	the catalog name string for the table to be queried; <code>undef</code> if not required
@param $schema	the schema name string for the table to be queried; <code>undef</code> if not required
@param $table	the name string of the table to be queried

@return <code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present),
	ordered by TABLE_CAT, TABLE_SCHEM, TABLE_NAME, and KEY_SEQ:

<ol>
<li>TABLE_CAT: The catalog identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>TABLE_SCHEM: The schema identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>TABLE_NAME: The table identifier.

<li>COLUMN_NAME: The column identifier.

<li>KEY_SEQ: The column sequence number (starting with 1).
Note: This field is named B<ORDINAL_POSITION> in SQL/CLI.

<li>PK_NAME: The primary key constraint identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source.
</ol>

@see <a href='DBI.pod.html#Catalog_Methods'>Catalog Methods</a>
@see <a href='DBI.pod.html#Standards_Reference_Information'>Standards Reference Information</a>

=end classdoc

=begin classdoc

@xs foreign_key_info

Create an active statement handle to return metadata
about foreign keys in and/or referencing the specified table(s).
The arguments don't accept search patterns (unlike table_info()).
<p>
If both the primary key and foreign key table parameters are specified,
the resultset contains the foreign key metadata, if
any, in foreign key table that refers to the primary (unique) key of primary key table.
(Note: In SQL/CLI, the result is implementation-defined.)
<p>
If only primary key table parameters are specified, the result set contains 
the primary key metadata of that table and all foreign keys that refer to it.
<p>
If only foreign key table parameters are specified, the result set contains 
all foreign keys metadata in that table and the primary keys to which they refer.
(Note: In SQL/CLI, the result includes unique keys too.)
<p>
Note: The support for the selection criteria, such as <code>$catalog</code>, is
driver specific.  If the driver doesn't support catalogs and/or
schemas, it may ignore these criteria.

@param $pk_catalog name of the primary key table's catalog; may be <code>undef</code>
@param $pk_schema name of the primary key table's schema; may be <code>undef</code>
@param $pk_table name of the primary key table; may be <code>undef</code>
@param $fk_catalog name of the foreign key table's catalog; may be <code>undef</code>
@param $fk_schema name of the foreign key table's schema; may be <code>undef</code>
@param $fk_table name of the foreign key table; may be <code>undef</code>
@optional \%attr a hash reference of any attributes required by the driver or database

@return <code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present):
	(Because ODBC never includes unique keys, they define different columns in the
	result set than SQL/CLI. SQL/CLI column names are shown in parentheses)
<ol>
<li>PKTABLE_CAT    ( UK_TABLE_CAT      ):

The primary (unique) key table catalog identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>PKTABLE_SCHEM  ( UK_TABLE_SCHEM    ):

The primary (unique) key table schema identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>PKTABLE_NAME   ( UK_TABLE_NAME     ):

The primary (unique) key table identifier.

<li>PKCOLUMN_NAME  (UK_COLUMN_NAME    ):

The primary (unique) key column identifier.

<li>FKTABLE_CAT    ( FK_TABLE_CAT      ):

The foreign key table catalog identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>FKTABLE_SCHEM  ( FK_TABLE_SCHEM    ):

The foreign key table schema identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>FKTABLE_NAME   ( FK_TABLE_NAME     ):

The foreign key table identifier.

<li>FKCOLUMN_NAME  ( FK_COLUMN_NAME    ):

The foreign key column identifier.

<li>KEY_SEQ        ( ORDINAL_POSITION  ):

The column sequence number (starting with 1).

<li>UPDATE_RULE    ( UPDATE_RULE       ):

The referential action for the UPDATE rule.
The following codes are defined:
<ul>
<li>CASCADE (0)
<li>RESTRICT (1)
<li>SET NULL (2)
<li>NO ACTION (3)
<li>SET DEFAULT (4)
</ul>

<li>DELETE_RULE    ( DELETE_RULE       ):

The referential action for the DELETE rule.
The codes are the same as for UPDATE_RULE.

<li>FK_NAME        ( FK_NAME           ):

The foreign key name.

<li>PK_NAME        ( UK_NAME           ):

The primary (unique) key name.

<li>DEFERRABILITY  ( DEFERABILITY      ):

The deferrability of the foreign key constraint.
The following codes are defined:

<ul>
<li>INITIALLY DEFERRED   (5)
<li>INITIALLY IMMEDIATE  (6)
<li>NOT DEFERRABLE       (7)
</ul>

<li>               ( UNIQUE_OR_PRIMARY ):

This column is necessary if a driver includes all candidate (i.e. primary and
alternate) keys in the result set (as specified by SQL/CLI).
The value of this column is UNIQUE if the foreign key references an alternate
key and PRIMARY if the foreign key references a primary key, or it
may be undefined if the driver doesn't have access to the information.
</ol>

@see <a href='DBI.pod.html#Catalog_Methods'>Catalog Methods</a>
@see <a href='DBI.pod.html#Standards_Reference_Information'>Standards Reference Information</a>

=end classdoc

=begin classdoc

@xs statistics_info

Create an active statement handle returning statistical
information about a table and its indexes.
<p>
<b>Warning:</b> This method is experimental and may change.
<p>
The arguments don't accept search patterns (unlike <method>table_info</method>).
<p>
The statement handle will return at most one row per column name per index,
plus at most one row for the entire table itself, ordered by NON_UNIQUE, TYPE,
INDEX_QUALIFIER, INDEX_NAME, and ORDINAL_POSITION.
<p>
Note: The support for the selection criteria, such as $catalog, is
driver specific.  If the driver doesn't support catalogs and/or
schemas, it may ignore these criteria.

@param $catalog	the catalog name string for the table to be queried; <code>undef</code> if not required
@param $schema	the schema name string for the table to be queried; <code>undef</code> if not required
@param $table	the name string of the table to be queried
@param $unique_only if true, only UNIQUE indexes will be
	returned in the result set; otherwise all indexes will be returned.
@param $quick if true, the actual statistical information
	columns (CARDINALITY and PAGES) will only be returned if they are readily
	available from the server, and might not be current.  Some databases may
	return stale statistics or no statistics at all with this flag set true.

@return <code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present):

<ol>
<li>TABLE_CAT: The catalog identifier.

This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>TABLE_SCHEM: The schema identifier.

This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>TABLE_NAME: The table identifier.

<li>NON_UNIQUE: Unique index indicator.

Returns 0 for unique indexes, 1 for non-unique indexes

<li>INDEX_QUALIFIER: Index qualifier identifier.

The identifier that is used to qualify the index name when doing a
<code>DROP INDEX</code>; NULL (<code>undef</code>) is returned if an index qualifier is not
supported by the data source.
If a non-NULL (defined) value is returned in this column, it must be used
to qualify the index name on a <code>DROP INDEX</code> statement; otherwise,
the TABLE_SCHEM should be used to qualify the index name.

<li>INDEX_NAME: The index identifier.

<li>TYPE: The type of information being returned.  Can be any of the
following values: 'table', 'btree', 'clustered', 'content', 'hashed',
or 'other'.

In the case that this field is 'table', all fields
other than TABLE_CAT, TABLE_SCHEM, TABLE_NAME, TYPE,
CARDINALITY, and PAGES will be NULL (<code>undef</code>).

<li>ORDINAL_POSITION: Column sequence number (starting with 1).

<li>COLUMN_NAME: The column identifier.

<li>ASC_OR_DESC: Column sort sequence.

<code>A</code> for Ascending, <code>D</code> for Descending, or NULL (<code>undef</code>) if
not supported for this index.

<li>CARDINALITY: Cardinality of the table or index.

For indexes, this is the number of unique values in the index.
For tables, this is the number of rows in the table.
If not supported, the value will be NULL (<code>undef</code>).

<li>PAGES: Number of storage pages used by this table or index.

If not supported, the value will be NULL (<code>undef</code>).

<li>FILTER_CONDITION: The index filter condition as a string.

If the index is not a filtered index, or it cannot be determined
whether the index is a filtered index, this value is NULL (<code>undef</code>).
If the index is a filtered index, but the filter condition
cannot be determined, this value is the empty string <code>''</code>.
Otherwise it will be the literal filter condition as a string,
such as <code>SALARY <= 4500</code>.
</ol>

@see <a href='DBI.pod.html#Catalog_Methods'>Catalog Methods</a>
@see <a href='DBI.pod.html#Standards_Reference_Information'>Standards Reference Information</a>

=end classdoc

=begin classdoc

@xs type_info_all

Return metadata for all supported data types.
<p>
The type_info_all() method is not normally used directly.
The <method>type_info</method> method provides a more usable and useful interface
to the data.

@return an (read-only) array reference containing information about each data
	type variant supported by the database and driver.
	The array element is a reference to an 'index' hash of <code>Name =</code>&gt; <code>Index</code> pairs.
	Subsequent array elements are references to arrays, one per supported data type variant. 
	The leading index hash defines the names and order of the fields within the arrays that follow it.
	For example:
<pre>
  $type_info_all = [
    {   TYPE_NAME         => 0,
	DATA_TYPE         => 1,
	COLUMN_SIZE       => 2,     # was PRECISION originally
	LITERAL_PREFIX    => 3,
	LITERAL_SUFFIX    => 4,
	CREATE_PARAMS     => 5,
	NULLABLE          => 6,
	CASE_SENSITIVE    => 7,
	SEARCHABLE        => 8,
	UNSIGNED_ATTRIBUTE=> 9,
	FIXED_PREC_SCALE  => 10,    # was MONEY originally
	AUTO_UNIQUE_VALUE => 11,    # was AUTO_INCREMENT originally
	LOCAL_TYPE_NAME   => 12,
	MINIMUM_SCALE     => 13,
	MAXIMUM_SCALE     => 14,
	SQL_DATA_TYPE     => 15,
	SQL_DATETIME_SUB  => 16,
	NUM_PREC_RADIX    => 17,
	INTERVAL_PRECISION=> 18,
    },
    [ 'VARCHAR', SQL_VARCHAR,
	undef, "'","'", undef,0, 1,1,0,0,0,undef,1,255, undef
    ],
    [ 'INTEGER', SQL_INTEGER,
	undef,  "", "", undef,0, 0,1,0,0,0,undef,0,  0, 10
    ],
  ];
</pre>
Multiple elements may use the same <code>DATA_TYPE</code> value
if there are different ways to spell the type name and/or there
are variants of the type with different attributes (e.g., with and
without <code>AUTO_UNIQUE_VALUE</code> set, with and without <code>UNSIGNED_ATTRIBUTE</code>, etc).
<p>
The datatype entries are ordered by <code>DATA_TYPE</code> value first, then by how closely each
type maps to the corresponding ODBC SQL data type, closest first.
<p>
The meaning of the fields is described in the documentation for
the <method>type_info</method> method.
<p>
An 'index' hash is provided so you don't need to rely on index
values defined above.  However, using DBD::ODBC with some old ODBC
drivers may return older names, shown as comments in the example above.
Another issue with the index hash is that the lettercase of the
keys is not defined. It is usually uppercase, as show here, but
drivers may return names with any lettercase.
<p>
Drivers may return extra driver-specific data type entries.

=end classdoc

=begin classdoc

@xs take_imp_data

Leaves this Database handle object in an almost dead, zombie-like, state.
Detaches the underlying database API connection data from the DBI handle.
After calling this method, all other methods except <code>DESTROY</code>
will generate a warning and return undef.
<p>
Why would you want to do this? You don't, forget I even mentioned it.
Unless, that is, you're implementing something advanced like a
multi-threaded connection pool. See <cpan>DBI::Pool</cpan>.
<p>
The returned value can be passed as a <code>dbi_imp_data</code> attribute
to a later <method>DBI::connect</method> call, even in a separate thread in the same
process, where the driver can use it to 'adopt' the existing
connection that the implementation data was taken from.
<p>
Some things to keep in mind...
<ul>
<li>the returned value holds the only reference to the underlying
database API connection data. That connection is still 'live' and
won't be cleaned up properly unless the value is used to create
a new database handle object which is then allowed to disconnect() normally.

<li>using the same returned value to create more than one other new
database handle object at a time may well lead to unpleasant problems. Don't do that.

<li>Any child statement handles are effectively destroyed when take_imp_data() is
called.
</ul>

@return a binary string of raw implementation data from the driver which
	describes the current database connection. 

@since 1.36

=end classdoc

=begin classdoc

Duplicate this database handle object's connection by connecting
with the same parameters as used to create this database handle object.
<p>
The attributes for the cloned connect are the same as those used
for the original connect, with some other attribute merged over
them depending on the \%attr parameter.
<p>
If \%attr is given then the attributes it contains are merged into
the original attributes and override any with the same names.
<p>
If \%attr is not given then it defaults to a hash containing all
the attributes in the attribute cache of this database handle object,
excluding any non-code references, plus the main boolean attributes (RaiseError, PrintError,
AutoCommit, etc.). This behaviour is subject to change.
<p>
This method can be used even if the database handle is disconnected.

@optional \%attr hash reference of attribute values to merge with or override
	this object's connection attributes

@since 1.33

=end classdoc

=cut

    sub clone {
	my ($old_dbh, $attr) = @_;
	my $closure = $old_dbh->{dbi_connect_closure} or return;
	unless ($attr) {
	    # copy attributes visible in the attribute cache
	    keys %$old_dbh;	# reset iterator
	    while ( my ($k, $v) = each %$old_dbh ) {
		# ignore non-code refs, i.e., caches, handles, Err etc
		next if ref $v && ref $v ne 'CODE'; # HandleError etc
		$attr->{$k} = $v;
	    }
	    # explicitly set attributes which are unlikely to be in the
	    # attribute cache, i.e., boolean's and some others
	    $attr->{$_} = $old_dbh->FETCH($_) for (qw(
		AutoCommit ChopBlanks InactiveDestroy
		LongTruncOk PrintError PrintWarn Profile RaiseError
		ShowErrorStatement TaintIn TaintOut
	    ));
	}
	# use Data::Dumper; warn Dumper([$old_dbh, $attr]);
	my $new_dbh = &$closure($old_dbh, $attr);
	unless ($new_dbh) {
	    # need to copy err/errstr from driver back into $old_dbh
	    my $drh = $old_dbh->{Driver};
	    return $old_dbh->set_err($drh->err, $drh->errstr, $drh->state);
	}
	return $new_dbh;
    }

=pod

=begin classdoc

Quote a database object identifier (table name etc.) for use in an SQL statement.
Special characters (such as double quotation marks) are escaped,
and the required type of outer quotation mark are added.
<p>
Undefined names are ignored and the remainder are quoted and then
joined together, typically with a dot (<code>.</code>) character.
<p>
If three names are supplied, the first is assumed to be a
catalog name and special rules may be applied based on what <method>get_info</method>
returns for SQL_CATALOG_NAME_SEPARATOR (41) and SQL_CATALOG_LOCATION (114).

@param $catalog	a database object identifier to be quoted
@optional $schema a schema identifier to be included in the returned quoted string; causes $catalog to be interpretted as a catalog name
@optional $table a table identifier to be included in the returned quoted string
@optional \%attr

@return the properly quoted/escaped object identifier string

=end classdoc

=cut

    sub quote_identifier {
	my ($dbh, @id) = @_;
	my $attr = (@id > 3 && ref($id[-1])) ? pop @id : undef;

	my $info = $dbh->{dbi_quote_identifier_cache} ||= [
	    $dbh->get_info(29)  || '"',	# SQL_IDENTIFIER_QUOTE_CHAR
	    $dbh->get_info(41)  || '.',	# SQL_CATALOG_NAME_SEPARATOR
	    $dbh->get_info(114) ||   1,	# SQL_CATALOG_LOCATION
	];

	my $quote = $info->[0];
	foreach (@id) {			# quote the elements
	    next unless defined;
	    s/$quote/$quote$quote/g;	# escape embedded quotes
	    $_ = qq{$quote$_$quote};
	}

	# strip out catalog if present for special handling
	my $catalog = (@id >= 3) ? shift @id : undef;

	# join the dots, ignoring any null/undef elements (ie schema)
	my $quoted_id = join '.', grep { defined } @id;

	if ($catalog) {			# add catalog correctly
	    $quoted_id = ($info->[2] == 2)	# SQL_CL_END
		    ? $quoted_id . $info->[1] . $catalog
		    : $catalog   . $info->[1] . $quoted_id;
	}
	return $quoted_id;
    }

=pod

=begin classdoc

Quote a string literal for use as a literal value in an SQL statement.
Special characters (such as quotation marks) are escaped,
and the required type of outer quotation marks are added.
<p>
Quote will probably <i>not</i> be able to deal with all possible input
(such as binary data or data containing newlines), and is not related in
any way with escaping or quoting shell meta-characters.
<p>
It is valid for the quote() method to return an SQL expression that
evaluates to the desired string. For example:
<pre>
  $quoted = $dbh->quote("one\ntwo\0three")
</pre>
may return something like:
<pre>
  CONCAT('one', CHAR(12), 'two', CHAR(0), 'three')
</pre>
The quote() method should <i>not</i> be used with placeholders and bind values.

@param $value the value to be escaped/quoted
@optional $data_type an SQL type code value to be used to determine the required
	quoting behaviour by using the information returned by <method>type_info</method>.
	As a special case, the standard numeric types are optimized to return
	<code>$value</code> without calling <code>type_info()</code>.

@return the properly quoted/escaped version of hte input parameter; if the input
	parameter was <code>undef</code>, the string <code>NULL</code> (without
	single quotation marks)

=end classdoc

=cut

    sub quote {
	my ($dbh, $str, $data_type) = @_;

	return "NULL" unless defined $str;
	unless ($data_type) {
	    $str =~ s/'/''/g;		# ISO SQL2
	    return "'$str'";
	}

	my $dbi_literal_quote_cache = $dbh->{'dbi_literal_quote_cache'} ||= [ {} , {} ];
	my ($prefixes, $suffixes) = @$dbi_literal_quote_cache;

	my $lp = $prefixes->{$data_type};
	my $ls = $suffixes->{$data_type};

	if ( ! defined $lp || ! defined $ls ) {
	    my $ti = $dbh->type_info($data_type);
	    $lp = $prefixes->{$data_type} = $ti ? $ti->{LITERAL_PREFIX} || "" : "'";
	    $ls = $suffixes->{$data_type} = $ti ? $ti->{LITERAL_SUFFIX} || "" : "'";
	}
	return $str unless $lp || $ls; # no quoting required

	# XXX don't know what the standard says about escaping
	# in the 'general case' (where $lp != "'").
	# So we just do this and hope:
	$str =~ s/$lp/$lp$lp/g
		if $lp && $lp eq $ls && ($lp eq "'" || $lp eq '"');
	return "$lp$str$ls";
    }

    sub rows { -1 }	# here so $DBI::rows 'works' after using $dbh

=pod

=begin classdoc

Prepare and immediately execute a single statement. 
Typically used for <i>non</i>-data returning statements that
either cannot be prepared in advance (due to a limitation of the
driver) or do not need to be executed repeatedly. It should not
be used for data returning statements because it does not return a statement
handle (so you can't fetch any data).
<p>
Using placeholders and <code>@bind_values</code> with the <code>do</code> method can be
useful because it avoids the need to correctly quote any variables
in the <code>$statement</code>. Statements that will be executed many
times should <code>prepare()</code> it once and call
<code>execute()</code> many times instead.

@param $statement the SQL statement to be executed immediately. Either a string, or a Statement handle object
	previously returned from a <code>prepare()</code> on this database handle object.
@optional \%attr	a hash reference of any desired statement attributes to apply to the $statement
@optional @bind_values any bind values to be supplied for placeholders within the $statement

@return the number of rows affected by the statement execution,
	or <code>undef</code> on error. A return value of <code>-1</code> means the
	number of rows is not known, not applicable, or not available.

=end classdoc

=cut

    sub do {
	my($dbh, $statement, $attr, @params) = @_;
	my $sth = $dbh->prepare($statement, $attr) or return undef;
	$sth->execute(@params) or return undef;
	my $rows = $sth->rows;
	($rows == 0) ? "0E0" : $rows;
    }

    sub _do_selectrow {
	my ($method, $dbh, $stmt, $attr, @bind) = @_;
	my $sth = ((ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr))
	    or return;
	$sth->execute(@bind)
	    or return;
	my $row = $sth->$method()
	    and $sth->finish;
	return $row;
    }

=pod

=begin classdoc

Immediately execute a data returning statement, returning the first row of results
as a hash reference.
Combines <method>prepare</method>, <method>DBD::_::st::execute</method> and
<method>DBD::_::st::fetchrow_hashref</method> into a single call.

@param $statement the SQL statement to be executed as either a string, or a Statement handle object
	previously returned from a <code>prepare()</code> on this database handle object.
@optional \%attr	a hash reference of any desired statement attributes to apply to the $statement
@optional @bind_values any bind values to be supplied for placeholders within the $statement

@return on failure, <code>undef</code>; otherwise, a hash reference mapping field names to their row values.	
	Note that the hash may be empty if no rows were returned.

=end classdoc

=cut

    sub selectrow_hashref {  return _do_selectrow('fetchrow_hashref',  @_); }

    # XXX selectrow_array/ref also have C implementations in Driver.xst

=pod

=begin classdoc

Immediately execute a data returning statement, returning the first row of results
as an array reference.
Combines <method>prepare</method>, <method>DBD::_::st::execute</method> and
<method>DBD::_::st::fetchrow_arrayref</method> into a single call.

@param $statement the SQL statement to be executed as either a string, or a Statement handle object
	previously returned from a <code>prepare()</code> on this database handle object.
@optional \%attr	a hash reference of any desired statement attributes to apply to the $statement
@optional @bind_values any bind values to be supplied for placeholders within the $statement

@return on failure, <code>undef</code>; otherwise, an array reference of the row values.	
	Note that the array may be empty if no rows were returned.

=end classdoc

=cut

    sub selectrow_arrayref { return _do_selectrow('fetchrow_arrayref', @_); }

=pod

=begin classdoc

Immediately execute a data returning statement, returning the first row of results
as an array.
Combines <method>prepare</method>, <method>DBD::_::st::execute</method> and
<method>DBD::_::st::fetchrow_array</method> into a single call.

@param $statement the SQL statement to be executed as either a string, or a Statement handle object
	previously returned from a <code>prepare()</code> on this database handle object.
@optional \%attr	a hash reference of any desired statement attributes to apply to the $statement
@optional @bind_values any bind values to be supplied for placeholders within the $statement

@returnlist on failure, <code>undef</code>; otherwise, an array reference of the row values.	
	Note that the array may be empty if no rows were returned.

@return either the value of the first or last column of the first returned row (don't do that);
	<code>undef</code> if there are no more rows <b>OR</B> if an error occurred. 
	As those <code>undef</code> cases can't be distinguished from an <code>undef</code> returned as
	a NULL first(or last) field value, this method should not be used in scalar context.

=end classdoc

=cut

    sub selectrow_array {
	my $row = _do_selectrow('fetchrow_arrayref', @_) or return;
	return $row->[0] unless wantarray;
	return @$row;
    }

    # XXX selectall_arrayref also has C implementation in Driver.xst
    # which fallsback to this if a slice is given
=pod

=begin classdoc

Immediately execute a data returning statement, returning all result rows
as an array reference.
Combines <method>prepare</method>, <method>DBD::_::st::execute</method> and
<method>DBD::_::st::fetchall_arrayref</method> into a single call.

@param $statement the SQL statement to be executed as either a string, or a Statement handle object
	previously returned from a <code>prepare()</code> on this database handle object.
@optional \%attr	a hash reference of any desired statement attributes to apply to the $statement.
	In addition, the following attributes may be supplied:
	<ul>
	<li><code>MaxRows</code> =&gt; $max_rows
	
	Specifies a <code>$max_rows</code> value to supply to the 
	<method>DBD::_::st::fetchall_arrayref</method> method called by this method, and
	calls <method>DBD::_::st::finish</method> after <method>DBD::_::st::fetchall_arrayref</method> returns.

	<li><code>Slice</code> =&gt; $slice <i>or</i> <code>Columns</code> =&gt; $slice

	Specifies a <code>$slice</code> value to supply to the 
	<method>DBD::_::st::fetchall_arrayref</method> method called by this method.
	If <code>Slice</code> is not defined and <code>Columns</code> is an array ref, 
	the array is assumed to contain column index values (which count from 1), rather than 
	Perl array index values, so that the array is copied and each value decremented before
	passing to <method>DBD::_::st::fetchall_arrayref</method>.
	<p>
	If the <code>Slice</code> attribute is specified as an empty hash reference, 
	the results will be returned as a hash reference mapping column names as keys to
	arrayrefs of their associated values.
	</ul>

@optional @bind_values any bind values to be supplied for placeholders within the $statement

@return <code>undef</code> on failure; otherwise, an array reference containing an array reference
	(or hash reference, if the <code>Slice</code> attribute is specified as an empty hash reference)
	for each row of data fetched. If <method>DBD::_::st::fetchall_arrayref</method> fails, returns with whatever data
	has been fetched thus far. Check <code>$sth-&gt;err</code>
	afterwards (or use the <member>RaiseError</member> attribute) to discover if the data is
	complete or was truncated due to an error.

@see <method>DBD::_::st::fetchall_arrayref</method>

=end classdoc

=cut

    sub selectall_arrayref {
	my ($dbh, $stmt, $attr, @bind) = @_;
	my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr)
	    or return;
	$sth->execute(@bind) || return;
	my $slice = $attr->{Slice}; # typically undef, else hash or array ref
	if (!$slice and $slice=$attr->{Columns}) {
	    if (ref $slice eq 'ARRAY') { # map col idx to perl array idx
		$slice = [ @{$attr->{Columns}} ];	# take a copy
		for (@$slice) { $_-- }
	    }
	}
	my $rows = $sth->fetchall_arrayref($slice, my $MaxRows = $attr->{MaxRows});
	$sth->finish if defined $MaxRows;
	return $rows;
    }

=pod

=begin classdoc

Immediately execute a data returning statement, returning all result rows
as a hash reference.
Combines <method>prepare</method>, <method>DBD::_::st::execute</method> and
<method>DBD::_::st::fetchall_hashref</method> into a single call.

If a row has the same key as an earlier row then it replaces the earlier row.

@param $statement the SQL statement to be executed as either a string, or a Statement handle object
	previously returned from a <code>prepare()</code> on this database handle object.
@param $key_field a scalar key field name, or an array reference of key field names,
	Specifies which column(s) are used as keys in the returned hash. 
@optional \%attr	a hash reference of any desired statement attributes to apply to the $statement.
@optional @bind_values any bind values to be supplied for placeholders within the $statement

@return <code>undef</code> on failure; on success, a hash reference containing one entry, 
	at most, for each row, as returned by <method>DBD::_::st::fetchall_hashref</method>.
	If <method>DBD::_::st::fetchall_hashref</method> fails and
	<member>RaiseError</member> is not set, returns with whatever data it
	has fetched thus far, with the error indication in <code>$DBI::err</code>.
	If multiple <code>$key_fields</code> were specified, the returned hash is a tree of
	nested hashes.

@see <method>DBD::_::st::fetchall_hashref</method>

=end classdoc

=cut

    sub selectall_hashref {
	my ($dbh, $stmt, $key_field, $attr, @bind) = @_;
	my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr);
	return unless $sth;
	$sth->execute(@bind) || return;
	return $sth->fetchall_hashref($key_field);
    }

=pod

=begin classdoc

Immediately execute a data returning statement, returning all result rows
as a hash reference.
Combines <method>prepare</method>, <method>DBD::_::st::execute</method>, and 
<method>DBD::_::st::fetchrow_array</method> (fetching only one column from all the rows),
into a single call.
<p>
This method defaults to pushing a single column
value (the first) from each row into the result array. However, 
if the '<code>Columns</code>' attribute is specified, it can
also push additional columns per row into the result array.

@param $statement the SQL statement to be executed as either a string, or a Statement handle object
	previously returned from a <code>prepare()</code> on this database handle object.

@optional \%attr	a hash reference of any desired statement attributes to apply to the $statement.
	In addition, the following attributes may be supplied:
	<ul>
	<li><code>MaxRows</code> =&gt; $max_rows
	
	Specifies the maximum number of rows to fetch.

	<li><code>Columns</code> =&gt; \@columns

	Specifies an array reference containing the column number(s) to be fetched into the result array.
	</ul>

@optional @bind_values any bind values to be supplied for placeholders within the $statement

@return <code>undef</code> on failure; on success, an array reference containing the values 
	of the first column from each row. If <method>DBD::_::st::fetchrow_array</method> fails and
	<member>RaiseError</member> is not set, returns with whatever data it
	has fetched thus far, with the error indication in <code>$DBI::err</code>.

=end classdoc

=cut

    sub selectcol_arrayref {
	my ($dbh, $stmt, $attr, @bind) = @_;
	my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr);
	return unless $sth;
	$sth->execute(@bind) || return;
	my @columns = ($attr->{Columns}) ? @{$attr->{Columns}} : (1);
	my @values  = (undef) x @columns;
	my $idx = 0;
	for (@columns) {
	    $sth->bind_col($_, \$values[$idx++]) || return;
	}
	my @col;
	if (my $max = $attr->{MaxRows}) {
	    push @col, @values while @col<$max && $sth->fetch;
	}
	else {
	    push @col, @values while $sth->fetch;
	}
	return \@col;
    }

=pod

=begin classdoc

Locate a matching statement handle object in this object's
statement handle cache; if no match is found, prepare the statement 
and store the resulting statement handle object in
this database handle's statement cache.
<p>
If another call is made to <code>prepare_cached</code> with the same 
<code>$statement</code> and <code>%attr</code> parameter values,
the corresponding cached statement handle object will be returned without 
contacting the database server.
<p>
<i>Caveat emptor:</i> This caching can be useful in some applications,
but it can also cause problems and should be used with care.

@param $statement the SQL statement text to be prepared
@optional \%attr	a hash reference of any desired statement attributes to apply to the $statement.
@optional $if_active adjusts the behaviour if an already cached statement handle is still 
	<member>DBD::_::st::Active</member>. Acceptable values are:
	<ul>
	<li><b>0</b> (the default): A warning will be generated, and <method>DBD::_::st::finish</method> will be called on
	the statement handle before it is returned.

	<li><b>1</b>: <method>DBD::_::st::finish</method>finish</method> will be called on the statement handle, but the
	warning is suppressed.

	<li><b>2</b>: Disables any checking.

	<li><b>3</b>: The existing active statement handle will be removed from the
	cache and a new statement handle prepared and cached in its place.
	This is the safest option because it doesn't affect the state of the
	old handle, it just removes it from the cache. [Added in DBI 1.40]

	</ul>

@return on success, a statement handle object; on failure, <code>undef</code>, with the error
	indication available via <method>err</method>, <method>errstrr</method>, and <method>state</method>.

@see <a href='DBI;pod.html#prepare_cached'>prepare_cached()</a> in the DBI manual

=end classdoc

=cut

    sub prepare_cached {
	my ($dbh, $statement, $attr, $if_active) = @_;
	# Needs support at dbh level to clear cache before complaining about
	# active children. The XS template code does this. Drivers not using
	# the template must handle clearing the cache themselves.
	my $cache = $dbh->{CachedKids} ||= {};
	my @attr_keys = ($attr) ? sort keys %$attr : ();
	my $key = ($attr) ? join("~~", $statement, @attr_keys, @{$attr}{@attr_keys}) : $statement;
	my $sth = $cache->{$key};
	if ($sth) {
	    return $sth unless $sth->FETCH('Active');
	    Carp::carp("prepare_cached($statement) statement handle $sth still Active")
		unless ($if_active ||= 0);
	    $sth->finish if $if_active <= 1;
	    return $sth  if $if_active <= 2;
	}
	$sth = $dbh->prepare($statement, $attr);
	$cache->{$key} = $sth if $sth;
	return $sth;
    }

=pod

=begin classdoc

Is this database handle still connected to the database server ?
<p>
Attempts to determine, in a reasonably efficient way, if the database
server is still running and the connection to it is still working.
Individual drivers should implement this function in the most suitable
manner for their database engine.
<p>
The <i>default</i> implementation always returns true without
actually doing anything. Actually, it returns "<code>0 but true</code>" which is
true but zero. That way you can tell if the return value is genuine or
just the default.

@return true if the connection is still usable; otherwise, false.

@see <cpan>Apache::DBI</cpan> one example usage.

=end classdoc

=cut

    sub ping {
	my $dbh = shift;
	$dbh->_not_impl('ping');
	# "0 but true" is a special kind of true 0 that is used here so
	# applications can check if the ping was a real ping or not
	($dbh->FETCH('Active')) ?  "0 but true" : 0;
    }

=pod

=begin classdoc

Start a transaction on this database handle.
Enables transaction (by turning <member>AutoCommit</member> off) until the next call
to <method>commit</method> or <method>rollback</method>. After the next 
<method>commit</method> or <method>rollback</method>,
<member>AutoCommit</member> will automatically be turned on again.
<p>

@return <code>undef</code> if <member>AutoCommit</member> is already off when this method is called,
	or the driver does not support transactions; otherwise, returns true.

@see <a href='DBI.pod.html#Transactions'>Transactions</a> in the DBI manual.

=end classdoc

=cut

    sub begin_work {
	my $dbh = shift;
	return $dbh->set_err(1, "Already in a transaction")
		unless $dbh->FETCH('AutoCommit');
	$dbh->STORE('AutoCommit', 0); # will croak if driver doesn't support it
	$dbh->STORE('BegunWork',  1); # trigger post commit/rollback action
	return 1;
    }

=pod

=begin classdoc

Get the column names that comprise the primary key of the specified table.
A simple interface to <method>primary_key_info</method>. 

@param $catalog	the catalog name string for the table to be queried; <code>undef</code> if not required
@param $schema	the schema name string for the table to be queried; <code>undef</code> if not required
@param $table	the name string of the table to be queried

@returnlist the column names that comprise the primary key of the specified table.
	The list is in primary key column sequence order.
	If there is no primary key, an empty list is returned.

=end classdoc

=cut

    sub primary_key {
	my ($dbh, @args) = @_;
	my $sth = $dbh->primary_key_info(@args) or return;
	my ($row, @col);
	push @col, $row->[3] while ($row = $sth->fetch);
	Carp::croak("primary_key method not called in list context")
		unless wantarray; # leave us some elbow room
	return @col;
    }

=pod

=begin classdoc

Get the list of matching table names.
A simple interface to <method>table_info</method>. 
<p>
If <code>$dbh-&gt;get_info(SQL_IDENTIFIER_QUOTE_CHAR)</code> returns true,
the table names are constructed and quoted by <method>quote_identifier</method>
to ensure they are usable even if they contain whitespace or reserved
words etc.; therefore. the returned table names  may include quote characters.

@param $catalog	search pattern for catalogs to be queried; <code>undef</code> if not required
@param $schema	search pattern for schemas to be queried; <code>undef</code> if not required
@param $table	search pattern for tables to be queried; <code>undef</code> if not required
@param $type	a comma-separated list of one or more types of tables for which metadata is to be returned.
	Each value may optionally be quoted.

@returnlist the matching table names, possibly including a catalog/schema prefix.

=end classdoc

=cut

    sub tables {
	my ($dbh, @args) = @_;
	my $sth    = $dbh->table_info(@args[0,1,2,3,4]) or return;
	my $tables = $sth->fetchall_arrayref or return;
	my @tables;
	if ($dbh->get_info(29)) { # SQL_IDENTIFIER_QUOTE_CHAR
	    @tables = map { $dbh->quote_identifier( @{$_}[0,1,2] ) } @$tables;
	}
	else {		# temporary old style hack (yeach)
	    @tables = map {
		my $name = $_->[2];
		if ($_->[1]) {
		    my $schema = $_->[1];
		    # a sad hack (mostly for Informix I recall)
		    my $quote = ($schema eq uc($schema)) ? '' : '"';
		    $name = "$quote$schema$quote.$name"
		}
		$name;
	    } @$tables;
	}
	return @tables;
    }

=pod 

=begin classdoc

Get the data type metadata for the specified <code>$data_type</code>.

@param $data_type either a scalar data type code, or
	an array reference of type codes

@return  the first (best) matching metadata element is returned as a hash reference

@returnlist the hash references containing metadata about one or more
	variants of the specified type. The list is ordered by <code>DATA_TYPE</code> first and
	then by how closely each type maps to the corresponding ODBC SQL data
	type, closest first. If <code>$data_type</code> is <code>undef</code> or <code>SQL_ALL_TYPES</code>, 
	all data type variants supported by the database and driver are returned.
	If <code>$data_type</code> is an array reference, returns the metadata for the <i>first</i> 
	type in the array that has any matches.
	The keys of the returned hash follow the same letter case conventions as the
	rest of the DBI 
	(see <a href='DBI.pod.html#Naming_Conventions_and_Name_Space'>Naming Conventions and Name Space</a>). The
	following uppercase items should always exist, though may be undef:
	<ul>
	<li>TYPE_NAME (string)

	Data type name for use in CREATE TABLE statements etc.

	<li>DATA_TYPE (integer)

	SQL data type number.

	<li>COLUMN_SIZE (integer)

	For numeric types, this is either the total number of digits (if the
	NUM_PREC_RADIX value is 10) or the total number of bits allowed in the
	column (if NUM_PREC_RADIX is 2).
	<p>
	For string types, this is the maximum size of the string in characters.
	<p>
	For date and interval types, this is the maximum number of characters
	needed to display the value.

	<li>LITERAL_PREFIX (string)

	Characters used to prefix a literal. A typical prefix is "<code>'</code>" for characters,
	or possibly "<code>0x</code>" for binary values passed as hexadecimal.  NULL (<code>undef</code>) is
	returned for data types for which this is not applicable.

	<li>LITERAL_SUFFIX (string)

	Characters used to suffix a literal. Typically "<code>'</code>" for characters.
	NULL (<code>undef</code>) is returned for data types where this is not applicable.

	<li>CREATE_PARAMS (string)

	Parameter names for data type definition. For example, <code>CREATE_PARAMS</code> for a
	<code>DECIMAL</code> would be "<code>precision,scale</code>" if the DECIMAL type should be
	declared as <code>DECIMAL(</code><i>precision,scale</i><code>)</code> where <i>precision</i> and <i>scale</i>
	are integer values.  For a <code>VARCHAR</code> it would be "<code>max length</code>".
	NULL (<code>undef</code>) is returned for data types for which this is not applicable.

	<li>NULLABLE (integer)

	Indicates whether the data type accepts a NULL value:
	<ul>
	<li>0 or an empty string = no
	<li>1 = yes
	<li>2  = unknown
	</ul>

	<li>CASE_SENSITIVE (boolean)

	Indicates whether the data type is case sensitive in collations and
	comparisons.

	<li>SEARCHABLE (integer)

	Indicates how the data type can be used in a WHERE clause, as
	follows:
	<ul>
	<li>0 - Cannot be used in a WHERE clause
	<li>1 - Only with a LIKE predicate
	<li>2 - All comparison operators except LIKE
	<li>3 - Can be used in a WHERE clause with any comparison operator
	</ul>

	<li>UNSIGNED_ATTRIBUTE (boolean)

	Indicates whether the data type is unsigned.  NULL (<code>undef</code>) is returned
	for data types for which this is not applicable.

	<li>FIXED_PREC_SCALE (boolean)

	Indicates whether the data type always has the same precision and scale
	(such as a money type).  NULL (<code>undef</code>) is returned for data types
	for which this is not applicable.

	<li>AUTO_UNIQUE_VALUE (boolean)

	Indicates whether a column of this data type is automatically set to a
	unique value whenever a new row is inserted.  NULL (<code>undef</code>) is returned
	for data types for which this is not applicable.

	<li>LOCAL_TYPE_NAME (string)

	Localized version of the <code>TYPE_NAME</code> for use in dialog with users.
	NULL (<code>undef</code>) is returned if a localized name is not available (in which
	case <code>TYPE_NAME</code> should be used).

	<li>MINIMUM_SCALE (integer)

	The minimum scale of the data type. If a data type has a fixed scale,
	then <code>MAXIMUM_SCALE</code> holds the same value.  NULL (<code>undef</code>) is returned for
	data types for which this is not applicable.

	<li>MAXIMUM_SCALE (integer)

	The maximum scale of the data type. If a data type has a fixed scale,
	then <code>MINIMUM_SCALE</code> holds the same value.  NULL (<code>undef</code>) is returned for
	data types for which this is not applicable.

	<li>SQL_DATA_TYPE (integer)

	This column is the same as the <code>DATA_TYPE</code> column, except for interval
	and datetime data types.  For interval and datetime data types, the
	<code>SQL_DATA_TYPE</code> field will return <code>SQL_INTERVAL</code> or <code>SQL_DATETIME</code>, and the
	<code>SQL_DATETIME_SUB</code> field below will return the subcode for the specific
	interval or datetime data type. If this field is NULL, then the driver
	does not support or report on interval or datetime subtypes.

	<li>SQL_DATETIME_SUB (integer)

	For interval or datetime data types, where the <code>SQL_DATA_TYPE</code>
	field above is <code>SQL_INTERVAL</code> or <code>SQL_DATETIME</code>, this field will
	hold the <i>subcode</i> for the specific interval or datetime data type.
	Otherwise it will be NULL (<code>undef</code>).
	<p>
	Although not mentioned explicitly in the standards, it seems there
	is a simple relationship between these values:
	<pre>
	DATA_TYPE == (10 * SQL_DATA_TYPE) + SQL_DATETIME_SUB
	</pre>

	<li>NUM_PREC_RADIX (integer)

	The radix value of the data type. For approximate numeric types,
	<code>NUM_PREC_RADIX</code>
	contains the value 2 and <code>COLUMN_SIZE</code> holds the number of bits. For
	exact numeric types, <code>NUM_PREC_RADIX</code> contains the value 10 and <code>COLUMN_SIZE</code> holds
	the number of decimal digits. NULL (<code>undef</code>) is returned either for data types
	for which this is not applicable or if the driver cannot report this information.

	<li>INTERVAL_PRECISION (integer)

	The interval leading precision for interval types. NULL is returned
	either for data types for which this is not applicable or if the driver
	cannot report this information.
	</ul>

@see <a href='DBI.pod.html#Standards_Reference_Information'>Standards Reference Information</a> in the DBI manual

=end classdoc

=cut

    sub type_info {	# this should be sufficient for all drivers
	my ($dbh, $data_type) = @_;
	my $idx_hash;
	my $tia = $dbh->{dbi_type_info_row_cache};
	if ($tia) {
	    $idx_hash = $dbh->{dbi_type_info_idx_cache};
	}
	else {
	    my $temp = $dbh->type_info_all;
	    return unless $temp && @$temp;
	    # we cache here because type_info_all may be expensive to call
	    # (and we take a copy so the following shift can't corrupt
	    # the data that may be returned by future calls to type_info_all)
	    $tia      = $dbh->{dbi_type_info_row_cache} = [ @$temp ];
	    $idx_hash = $dbh->{dbi_type_info_idx_cache} = shift @$tia;
	}

	my $dt_idx   = $idx_hash->{DATA_TYPE} || $idx_hash->{data_type};
	Carp::croak("type_info_all returned non-standard DATA_TYPE index value ($dt_idx != 1)")
	    if $dt_idx && $dt_idx != 1;

	# --- simple DATA_TYPE match filter
	my @ti;
	my @data_type_list = (ref $data_type) ? @$data_type : ($data_type);
	foreach $data_type (@data_type_list) {
	    if (defined($data_type) && $data_type != DBI::SQL_ALL_TYPES()) {
		push @ti, grep { $_->[$dt_idx] == $data_type } @$tia;
	    }
	    else {	# SQL_ALL_TYPES
		push @ti, @$tia;
	    }
	    last if @ti;	# found at least one match
	}

	# --- format results into list of hash refs
	my $idx_fields = keys %$idx_hash;
	my @idx_names  = map { uc($_) } keys %$idx_hash;
	my @idx_values = values %$idx_hash;
	Carp::croak "type_info_all result has $idx_fields keys but ".(@{$ti[0]})." fields"
		if @ti && @{$ti[0]} != $idx_fields;
	my @out = map {
	    my %h; @h{@idx_names} = @{$_}[ @idx_values ]; \%h;
	} @ti;
	return $out[0] unless wantarray;
	return @out;
    }

=pod

=begin classdoc

Get the list of data sources (databases) available via this database
handle object. 

@returnlist the names of data sources (databases) in a form suitable for passing to the
	<method>DBI::connect</method> method (including the "<code>dbi:$driver:</code>" prefix).
	The list is the result of the parent driver object's <method>DBD::_::dr::data_sources</method>, plus 
	any extra data sources the driver can discover via this connected database handle.

@since 1.38

=end classdoc

=cut

    sub data_sources {
	my ($dbh, @other) = @_;
	my $drh = $dbh->{Driver}; # XXX proxy issues?
	return $drh->data_sources(@other);
    }

}

{

=pod

=begin classdoc

Statement handle object. Provides methods and members
for executing and fetching the results of prepared statements.

@member Active (boolean, read-only) when true, indicates this handle object is "active". 
	The exact meaning of active is somewhat vague at the moment. Typically means this handle is a 
	data returning statement that may have more data to fetch.

@member Executed (boolean) when true, this handle object has been "executed".
	Currently only execute(), execute_array(), and execute_for_fetch() methods set 
	this attribute. When set, also sets the parent connection handle Executed attribute
	at the same time. Never cleared by the DBI under any circumstances.

@member Kids (integer, read-only) always zero.

@member ActiveKids (integer, read-only) always zero

@member Warn	(boolean, inherited) enables useful warnings (which
	can be intercepted using the <code>$SIG{__WARN__}</code> hook) for certain bad practices;

@member Type (scalar, read-only) "st" (the type of this handle object)

@member CompatMode (boolean, inherited) used by emulation layers (such as
	Oraperl) to enable compatible behaviour in the underlying driver (e.g., DBD::Oracle) for this handle. 
	Not normally set by application code. Disables the 'quick FETCH' of attribute
	values from this handle's attribute cache so all attribute values
	are handled by the drivers own FETCH method.

@member InactiveDestroy (boolean) when false (the default),this handle will be fully destroyed
	as normal when the last reference to it is removed. If true, this handle will be treated by 
	DESTROY as if it was no longer Active, and so the <i>database engine</i> related effects of 
	DESTROYing this handle will be skipped. Designed for use in Unix applications
	that "fork" child processes: Either the parent or the child process
	(but not both) should set <code>InactiveDestroy</code> true on all their shared handles.
	(Note that some databases, including Oracle, don't support passing a
	database connection across a fork.)
	<p>
	To help tracing applications using fork the process id is shown in
	the trace log whenever a DBI or handle trace() method is called.
	The process id also shown for <i>every</i> method call if the DBI trace
	level (not handle trace level) is set high enough to show the trace
	from the DBI's method dispatcher, e.g. >= 9.

@member PrintWarn (boolean, inherited) controls printing of warnings issued
	by this handle.  When true, DBI checks method calls to see if a warning condition has 
	been set. If so, DBI effectively does a <code>warn("$class $method warning: $DBI::errstr")</code>
	where <code>$class</code> is the driver class and <code>$method</code> is the name of
	the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintWarn</code> "on" if $^W is true.
	<p>
	Warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.
	<p>
	See also <method>set_err</method> for how warnings are recorded and <member>HandleSetErr</member>
	for how to influence it.

@member PrintError (boolean, inherited) When true, forces errors to generate warnings 
	(in addition to returning error codes in the normal way)
	via a <code>warn("$class $method failed: $DBI::errstr")</code>, where <code>$class</code>
	is the driver class and <code>$method</code> is the name of the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintError</code> "on".
	<p>
	If desired, the warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.

@member RaiseError (boolean, inherited) When true (default false), errors raise exceptions rather
	than simply returning error codes in the normal way.
	Exceptions are raised via a <code>die("$class $method failed: $DBI::errstr")</code>,
	where <code>$class</code> is the driver class and <code>$method</code> is the name of the method
	that failed.
	<p>
	If <code>PrintError</code> is also on, the <code>PrintError</code> is done first.
	<p>
	Typically <code>RaiseError</code> is used in conjunction with <code>eval { ... }</code>
	to catch the exception that's been thrown and followed by an
	<code>if ($@) { ... }</code> block to handle the caught exception.
	For example:
<pre>
  eval {
    ...
    $sth->execute();
    ...
  };
  if ($@) {
    # $sth->err and $DBI::err will be true if error was from DBI
    warn $@; # print the error
    ... # do whatever you need to deal with the error
  }
</pre>

@member HandleError (code ref, inherited) When set to a subroutine reference, provides
	alternative behaviour in case of errors. The subroutine reference is called when an 
	error is detected (at the same point that <code>RaiseError</code> and <code>PrintError</code> are handled).
	<p>
	The subroutine is called with three parameters: the error message
	string, this handle object, and the first value returned by
	the method that failed (typically undef).
	<p>
	If the subroutine returns a false value, the <code>RaiseError</code>
	and/or <code>PrintError</code> attributes are checked and acted upon as normal.
	<p>
	For example, to <code>die</code> with a full stack trace for any error:
<pre>
  use Carp;
  $h->{HandleError} = sub { confess(shift) };
</pre>
	Or to turn errors into exceptions:
<pre>
  use Exception; # or your own favourite exception module
  $h->{HandleError} = sub { Exception->new('DBI')->raise($_[0]) };
</pre>
	It is possible to 'stack' multiple HandleError handlers by using closures:
<pre>
  sub your_subroutine {
    my $previous_handler = $h->{HandleError};
    $h->{HandleError} = sub {
      return 1 if $previous_handler and &$previous_handler(@_);
      ... your code here ...
    };
  }
</pre>
	The error message that will be used by <code>RaiseError</code> and <code>PrintError</code>
	can be altered by changing the value of <code>$_[0]</code>.
	<p>
	Errors may be suppressed, to a limited extent, by using <method>set_err</method> to 
	reset $DBI::err and $DBI::errstr, and altering the return value of the failed method:
<pre>
  $h->{HandleError} = sub {
    return 0 unless $_[0] =~ /^\S+ fetchrow_arrayref failed:/;
    return 0 unless $_[1]->err == 1234; # the error to 'hide'
    $h->set_err(undef,undef);	# turn off the error
    $_[2] = [ ... ];	# supply alternative return value
    return 1;
  };
</pre>

@member HandleSetErr (code ref, inherited) When set to a subroutien reference, intercepts
	the setting of this handle's <code>err</code>, <code>errstr</code>, and <code>state</code> values.
	<p>
	The subroutine is called the arguments that	were passed to set_err(): the handle, 
	the <code>err</code>, <code>errstr</code>, and <code>state</code> values being set, 
	and the method name. These can be altered by changing the values in the @_ array. 
	The return value affects set_err() behaviour, see <method>set_err</method> for details.
	<p>
	It is possible to 'stack' multiple HandleSetErr handlers by using
	closures. See <member>HandleError</member> for an example.
	<p>
	The <code>HandleSetErr</code> and <code>HandleError</code> subroutines differ in that
	HandleError is only invoked at the point where DBI is about to return to the application 
	with <code>err</code> set true; it is not invoked by the failure of a method that's 
	been called by another DBI method.  HandleSetErr is called
	whenever set_err() is called with a defined <code>err</code> value, even if false.
	Thus, the HandleSetErr subroutine may be called multiple
	times within a method and is usually invoked from deep within driver code.
	<p>
	A driver can use the return value from HandleSetErr via
	set_err() to decide whether to continue or not. If set_err() returns
	an empty list, indicating that the HandleSetErr code has 'handled'
	the 'error', the driver might continue instead of failing. 

@member ErrCount (unsigned integer) the count of calls to set_err() on this handle that recorded an error
	(excluding warnings or information states). It is not reset by the DBI at any time.

@member ShowErrorStatement (boolean, inherited) When true, causes the relevant
	Statement text to be appended to the error messages generated by <code>RaiseError</code>, <code>PrintError</code>, 
	and <code>PrintWarn</code> attributes.
	<p>
	If <code>$h-&gt;{ParamValues}</code> returns a hash reference of parameter
	(placeholder) values then those are formatted and appended to the
	end of the Statement text in the error message.

@member TraceLevel (integer, inherited) the trace level and flags for this handle. May be used
	to set the trace level and flags. 

@member FetchHashKeyName (string, inherited, read-only) Specifies the case conversion applied to the 
	the field names used for the hash keys returned by fetchrow_hashref().
	Defaults to '<code>NAME</code>' but it is recommended to set it to either '<code>NAME_lc</code>'
	or '<code>NAME_uc</code>'.

@member ChopBlanks (boolean, inherited) When true (default false), trailing space characters are 
	trimmed from returned fixed width character (CHAR) fields. No other field types are affected, 
	even where field values have trailing spaces.

@member LongReadLen (unsigned integer, inherited) Sets the maximum
	length of 'long' type fields (LONG, BLOB, CLOB, MEMO, etc.) which the driver will
	read from the database automatically when it fetches each row of data.
	The <code>LongReadLen</code> attribute only relates to fetching and reading
	long values; it is not involved in inserting or updating them.
	<p>
	A value of 0 means not to automatically fetch any long data.
	Drivers may return undef or an empty string for long fields when
	<code>LongReadLen</code> is 0.
	<p>
	The default is typically 0 (zero) bytes but may vary between drivers.
	Applications fetching long fields should set this value to slightly
	larger than the longest long field value to be fetched.
	<p>
	Some databases return some long types encoded as pairs of hex digits.
	For these types, <code>LongReadLen</code> relates to the underlying data
	length and not the doubled-up length of the encoded string.
	<p>
	Changing the value of <code>LongReadLen</code> on this handle will typically have no effect, so it's common to
	set <code>LongReadLen</code> on the database or driver handle before calling <code>prepare</code>.

@member LongTruncOk (boolean, inherited) When false (the default), fetching a long value that
	needs to be truncated (usually due to exceeding <code>LongReadLen</code>) will cause the fetch to fail.
	(Applications should always be sure to
	check for errors after a fetch loop in case an error, such as a divide
	by zero or long field truncation, caused the fetch to terminate
	prematurely.)
	<p>
	If a fetch fails due to a long field truncation when <code>LongTruncOk</code> is
	false, many drivers will allow you to continue fetching further rows.

@member TaintIn (boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then all the arguments
	to most DBI method calls are checked for being tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.

@member TaintOut (boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then most data fetched
	from the database is considered tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.
	<p>
	Currently only fetched data is tainted. It is possible that the results
	of other DBI method calls, and the value of fetched attributes, may
	also be tainted in future versions.

@member Taint (boolean, inherited) Sets both <member>TaintIn</member> and <member>TaintOut</member>;
	returns a true value if and only if <member>TaintIn</member> and <member>TaintOut</member> are
	both set to true values.

@member Profile (inherited) Enables the collection and reporting of method call timing statistics.
	See the <cpan>DBI::Profile</cpan> module documentation for <i>much</i> more detail.

@member ReadOnly (boolean, inherited) When true, indicates that this handle and it's children will 
	not make any changes to the database.
	<p>
	The exact definition of 'read only' is rather fuzzy. See individual driver documentation for specific details.
	<p>
	If the driver can make the handle truly read-only (by issuing a statement like
	"<code>set transaction read only</code>", for example) then it should.
	Otherwise the attribute is simply advisory.
	<p>
	A driver can set the <code>ReadOnly</code> attribute itself to indicate that the data it
	is connected to cannot be changed for some reason.
	<p>
	Library modules and proxy drivers can use the attribute to influence their behavior.
	For example, the DBD::Gofer driver considers the <code>ReadOnly</code> attribute when
	making a decison about whether to retry an operation that failed.
	<p>
	The attribute should be set to 1 or 0 (or undef). Other values are reserved.

@member NUM_OF_FIELDS  (integer, read-only) number of fields (columns) the prepared statement may return.
	Returns zero for statements that don't return data (e.g., <code>DELETE</code>, <code>CREATE</code>, etc. statements)
	(some drivers may return <code>undef</undef>).

@member NUM_OF_PARAMS  (integer, read-only) number of parameters (placeholders) in the prepared statement.

@member NAME  (array-ref, read-only) an array reference of names for each returned column. The
	names may contain spaces but should not be truncated or have any
	trailing space. Note that the names have the letter case (upper, lower
	or mixed) as returned by the driver being used. Portable applications
	should use <member>NAME_lc</member> or <member>NAME_uc</member>.

@member NAME_lc  (array-ref, read-only) an array reference of lowercased names for each returned column. The
	names may contain spaces but should not be truncated or have any
	trailing space.

@member NAME_uc  (array-ref, read-only) an array reference of uppercased names for each returned column. The
	names may contain spaces but should not be truncated or have any
	trailing space.

@member NAME_hash  (hash-ref, read-only) a hash reference of column name information.
	Keys of the hash are the (possibly mixed case) names of the columns.
	Values are the Perl index number of the corresponding column (counting from 0).

@member NAME_lc_hash  (hash-ref, read-only) a hash reference of column name information.
	Keys of the hash are the lowercased names of the columns.
	Values are the Perl index number of the corresponding column (counting from 0).

@member NAME_uc_hash  (hash-ref, read-only) a hash reference of column name information.
	Keys of the hash are the uppercased names of the columns.
	Values are the Perl index number of the corresponding column (counting from 0).

@member TYPE  (array-ref, read-only) an array reference of integer values for each
	column. Each value indicates the data type of the corresponding column.
	The values correspond to the international standards (ANSI X3.135
	and ISO/IEC 9075) which, in general terms, means ODBC. Driver-specific
	types that don't exactly match standard types will generally return
	the same values as an ODBC driver supplied by the makers of the
	database, which might include private type numbers in ranges the vendor
	has officially registered with the <a href='ftp://sqlstandards.org/SC32/SQL_Registry/'>ISO working group</a>.
	<p>
	If there is no compatible vendor-supplied ODBC driver,
	the driver may return type numbers in the range
	reserved for use by the DBI: -9999 to -9000.
	<p>
	All <code>TYPE</code> values returned by a driver should be described in the
	output of the <method>DBD::_::db::type_info_all</method> method.

@member PRECISION  (array-ref, read-only) an array reference of integer values for each column.
	For numeric columns, the value is the maximum number of displayed digits
	(without considering a sign character or decimal point). Note that
	the "display size" for floating point types (REAL, FLOAT, DOUBLE)
	can be up to 7 characters greater than the precision (for the
	sign + decimal point + the letter E + a sign + 2 or 3 digits).
	<p>
	For character type columns, the value is the OCTET_LENGTH,
	in other words the number of <b>bytes</b>, <b>not</b> characters.

@member SCALE  (array-ref, read-only) an array reference containing the integer scale values for each column.
	<code>undef</code> values indicate columns where scale is not applicable.

@member NULLABLE  (array-ref, read-only) an array reference indicating the "nullability" of each
	column returning a null.  Possible values are 
	<ul>
	<li>0 (or an empty string) = the column is never NULL
	<li>1 = the column may return NULL values
	<li>2 = unknown
	</ul>

@member CursorName  (string, read-only) the name of the cursor associated with this statement handle
	(if available); <code>undef</code> if not available or if the database driver does not support the
	<code>"where current of ..."</code> SQL syntax.

@member Database  (dbh, read-only) the parent database handle of this statement handle.

@member ParamValues  (hash ref, read-only) a hash reference containing values currently bound
	to placeholders (or <code>undef</code> if not supported by the driver).
	The keys of the hash are the 'names' of the placeholders, typically integers starting at 1.  
	When no values have been bound, all the values will be undef
	(some drivers may return a ref to an empty hash in that instance).
	<p>
	Values in the hash may not be <i>exactly</i> the same as those passed to bind_param() or execute(),
	as the driver may modify values based on the bound TYPE specificication.
	The hash values can be passed to another bind_param() method with the same TYPE and will be seen by the
	database as the same value.
	Similary, depending on the driver's parameter naming requirements, keys in the hash may not 
	be exactly the same as those implied by the prepared statement.

@member ParamArrays  (hash ref, read-only) a reference to a hash containing the values currently bound to
	placeholders via <method>execute_array</method> or <method>bind_param_array</method>.
	The keys of the hash are the 'names' of the placeholders, typically integers starting at 1.  
	May be undef if not supported by the driver or no arrays of parameters are bound.
	<p>
	Each key value is an array reference containing a list of the bound
	parameters for that column. For example:
<pre>
  $sth = $dbh->prepare("INSERT INTO staff (id, name) values (?,?)");
  $sth->execute_array({},[1,2], ['fred','dave']);
  if ($sth->{ParamArrays}) {
      foreach $param (keys %{$sth->{ParamArrays}}) {
	  printf "Parameters for %s : %s\n", $param,
	  join(",", @{$sth->{ParamArrays}->{$param}});
      }
  }
</pre>
	The values in the hash may not be <i>exactly</i> the same as those passed to 
	<method>bind_param_array</method> or	<method>execute_array</method>, as
	the driver may use modified values in some way based on the bound TYPE value.
	Similarly, depending on the driver's parameter naming requirements, keys in the hash may not be 
	exactly the same as those implied by the prepared statement.

@member ParamTypes  (hash ref, read-only) a reference to a hash containing the type information
	currently bound to placeholders.  The keys of the hash are the 'names' of the placeholders: 
	either integers starting at 1, or, for drivers that support named placeholders, the actual parameter
	name string. The hash values are hashrefs of type information in the same form as that provided 
	to bind_param() methods (See <method>bind_param</method>), plus anything else that was passed 
	as the third argument to bind_param().
	<p>
	If no values have been bound yet, returns a hash with the placeholder name
	keys, but all the values undef (some drivers may return
	a ref to an empty hash, or, provide type information supplied by the database.
	If not supported by the driver, returns <code>undef</code>.
	<p>
	The values in the hash may not be <i>exactly</i> the same as those passed to bind_param() or execute(),
	as the driver may modify type information based	on the bound values, other hints provided by the prepare()'d
	SQL statement, or alternate type mappings required by the driver or target database system.
	Similarly, depending on the driver's parameter naming requirements, keys in the hash may not be 
	exactly the same as those implied by the prepared statement

@member Statement  (string, read-only) the statement string passed to the <method>DBD::_::db::prepare</method> method.

@member RowsInCache  (integer, read-only) the number of un-fetched rows in the local row cache; <code>undef</code>
	if the driver doesn't support a local row cache. See <member>DBD::_::db::RowCacheSize</member>.

=end classdoc

=cut

	package		# hide from PAUSE
	DBD::_::st;	# ====== STATEMENT ======
    @DBD::_::st::ISA = qw(DBD::_::common);
    use strict;

=pod

=begin classdoc

Bind a copy of <code>$bind_value</code>
to the specified placeholder in this statement object.
Placeholders within a statement string are normally indicated with 
a question mark character (<code>?</code>); some drivers may support alternate
placeholder syntax.
<p>
The data type for a placeholder cannot be changed after the first
<code>bind_param</code> call, after which the driver
may ignore the $bind_type parameter for that placeholder.
<p>
Perl only has string and number scalar data types. All database types
that aren't numbers are bound as strings and must be in a format the
database will understand except where the bind_param() TYPE attribute
specifies a type that implies a particular format.
<p>
As an alternative to specifying the data type in the <code>bind_param</code> call,
consider using the default type (<code>VARCHAR</code>) and
use an SQL function to convert the type within the statement.
For example:
<pre>
  INSERT INTO price(code, price) VALUES (?, CONVERT(MONEY,?))
</pre>

@param $p_num a positional placeholder number; some drivers may support
	alternate "named" placeholder syntax
@param $bind_value the value to be bound; <code>undef</code> is used for NULL. The bound value
	may be overridden by values provided to the <method>execute</method> method; however,
	any <code>$bind_type</code> specified by this method call will still apply.
@optional $bind_type either a scalar SQL type code (from the <code>DBI :sql_types</code> export list),
	or a hash reference of type information, which may include the following keys:
	<ul>
	<li>TYPE =&gt; $sql_type 	- the SQL type code
	<li>PRECISION =&gt; $precision 	- the precision of the supplied value
	<li>SCALE =&gt; $scale 	- the scale of the supplied value
	</ul>
	If not specified, the default <code>VARCHAR</code> type will be assumed.

@see <a href='DBI.pod.html#DBI_Constants'>DBI Constants</a>
@see <a href='DBI.pod.html#Placeholders_and_Bind_Values'>Placeholders and Bind Values</a> for more information.

=end classdoc

=cut

    sub bind_param { Carp::croak("Can't bind_param, not implement by driver") }

#
# ********************************************************
#
#	BEGIN ARRAY BINDING
#
#	Array binding support for drivers which don't support
#	array binding, but have sufficient interfaces to fake it.
#	NOTE: mixing scalars and arrayrefs requires using bind_param_array
#	for *all* params...unless we modify bind_param for the default
#	case...
#
#	2002-Apr-10	D. Arnold

=pod

=begin classdoc

Bind an array of values to the specified placeholder in this statement object
for use with a subsequent <method>execute_array</method>.
<p>
Placeholders within a statement string are normally indicated with 
a question mark character (<code>?</code>); some drivers may support alternate
placeholder syntax.
<p>
The data type for a placeholder cannot be changed after the first
<code>bind_param_array</code> call, after which the driver
may ignore the $bind_type parameter for that placeholder.
<p>
Perl only has string and number scalar data types. All database types
that aren't numbers are bound as strings and must be in a format the
database will understand except where the bind_param() TYPE attribute
specifies a type that implies a particular format.
<p>
As an alternative to specifying the data type in the <code>bind_param</code> call,
consider using the default type (<code>VARCHAR</code>) and
use an SQL function to convert the type within the statement.
For example:
<pre>
  INSERT INTO price(code, price) VALUES (?, CONVERT(MONEY,?))
</pre>
<p>
Note that bind_param_array() can <i>not</i> be used to expand a
placeholder into a list of values for a statement like "SELECT foo
WHERE bar IN (?)".  A placeholder can only ever represent one value
per execution.
<p>
Scalar values, including <code>undef</code>, may also be bound by
<code>bind_param_array</code>, in which case the same value will be used for each
<method>execute</method> call. Driver-specific implementations may behave
differently, e.g., when binding to a stored procedure call, some
databases may permit mixing scalars and arrays as arguments.
<p>
The default implementation provided by DBI (for drivers that have
not implemented array binding) is to iteratively call <method>execute</method> for
each parameter tuple provided in the bound arrays.  Drivers may
provide optimized implementations using any bulk operation
support the database API provides. The default driver behaviour should
match the default DBI behaviour. Refer to the driver's
documentation for any related driver specific issues.
<p>
The default implementation currently only supports non-data
returning statements (e.g., INSERT, UPDATE, but not SELECT). Also,
<code>bind_param_array</code> and <method>bind_param</method> cannot be mixed in the same
statement execution, and <code>bind_param_array</code> must be used with
<method>execute_array</method>; using <code>bind_param_array</code> will have no effect
for <method>execute</method>.

@param $p_num a positional placeholder number; some drivers may support
	alternate "named" placeholder syntax
@param $array_ref_or_value either an array reference to contain the placeholder values, or
	a scalar value containing a single value to be applied for all placeholder tuples.
	<code>undef</code> is used for NULL. The bound variable
	may be overridden by values provided to the <method>execute_array</method> method; however,
	any <code>$bind_type</code> specified by this method call will still apply.
@optional $bind_type either a scalar SQL type code (from the <code>DBI :sql_types</code> export list),
	or a hash reference of type information, which may include the following keys:
	<ul>
	<li>TYPE =&gt; $sql_type 	- the SQL type code
	<li>PRECISION =&gt; $precision 	- the precision of the supplied value
	<li>SCALE =&gt; $scale 	- the scale of the supplied value
	</ul>
	If not specified, the default <code>VARCHAR</code> type will be assumed.

@see <method>bind_param</method> for general details on using placeholders.
@see <a href='DBI.pod.html#DBI_Constants'>DBI Constants</a>
@see <a href='DBI.pod.html#Placeholders_and_Bind_Values'>Placeholders and Bind Values</a> for more information.

@since 1.22

=end classdoc

=cut

    sub bind_param_array {
	my $sth = shift;
	my ($p_id, $value_array, $attr) = @_;

	return $sth->set_err(1, "Value for parameter $p_id must be a scalar or an arrayref, not a ".ref($value_array))
	    if defined $value_array and ref $value_array and ref $value_array ne 'ARRAY';

	return $sth->set_err(1, "Can't use named placeholder '$p_id' for non-driver supported bind_param_array")
	    unless DBI::looks_like_number($p_id); # because we rely on execute(@ary) here

	return $sth->set_err(1, "Placeholder '$p_id' is out of range")
	    if $p_id <= 0; # can't easily/reliably test for too big

	# get/create arrayref to hold params
	my $hash_of_arrays = $sth->{ParamArrays} ||= { };

	# If the bind has attribs then we rely on the driver conforming to
	# the DBI spec in that a single bind_param() call with those attribs
	# makes them 'sticky' and apply to all later execute(@values) calls.
	# Since we only call bind_param() if we're given attribs then
	# applications using drivers that don't support bind_param can still
	# use bind_param_array() so long as they don't pass any attribs.

	$$hash_of_arrays{$p_id} = $value_array;
	return $sth->bind_param($p_id, undef, $attr)
		if $attr;
	1;
    }

    sub bind_param_inout_array {
	my $sth = shift;
	# XXX not supported so we just call bind_param_array instead
	# and then return an error
	my ($p_num, $value_array, $attr) = @_;
	$sth->bind_param_array($p_num, $value_array, $attr);
	return $sth->set_err(1, "bind_param_inout_array not supported");
    }

=pod

=begin classdoc

Calls <method>bind_col</method> for each column of the data returning statement.
<p>
For maximum portability between drivers, this method should be called
<b>after</b> <method>execute</method>.

@param @list_of_refs_to_vars_to_bind a list of scalar references to recieve the returned
	fields values for the column at the corresponding position.
	The list of references should have the same number of elements as the number of
	columns in the data returning statement. If it doesn't then <code>bind_columns</code> will
	bind the elements given, upto the number of columns, and then return an error.
	For compatibility with old scripts, the first parameter will be
	ignored if it is <code>undef</code> or a hash reference.

=end classdoc

=cut

    sub bind_columns {
	my $sth = shift;
	my $fields = $sth->FETCH('NUM_OF_FIELDS') || 0;
	if ($fields <= 0 && !$sth->{Active}) {
	    return $sth->set_err(1, "Statement has no result columns to bind"
		    ." (perhaps you need to successfully call execute first)");
	}
	# Backwards compatibility for old-style call with attribute hash
	# ref as first arg. Skip arg if undef or a hash ref.
	my $attr;
	$attr = shift if !defined $_[0] or ref($_[0]) eq 'HASH';

	my $idx = 0;
	$sth->bind_col(++$idx, shift, $attr) or return
	    while (@_ and $idx < $fields);

	return $sth->set_err(1, "bind_columns called with ".($idx+@_)." values but $fields are needed")
	    if @_ or $idx != $fields;

	return 1;
    }

=pod

=begin classdoc

Execute the prepared statement once for each parameter tuple
(group of values) provided either in <code>@bind_values</code>, or by prior
calls to <method>bind_param_array</method>, or via a reference passed in 
<code>\%attr</code>.
<p>
Bind values are supplied column-wise in the <code>@bind_values</code> argument, or via prior calls to
<method>bind_param_array</method>.
Alternately, bind values may be supplied row-wise via the <code>ArrayTupleFetch</code> attribute.
<p>
Where column-wise binding is used, the maximum number of elements in
any one of the bound value arrays determines the number of tuples
executed. Placeholders with fewer values in their parameter arrays
are treated as if padded with undef (NULL) values.
If a scalar value (rather than array reference) is bound, it is
treated as a <i>variable</i> length array with all elements having the
same value. It does not influence the number of tuples executed;
if all bound arrays have zero elements then zero tuples will
be executed. If <i>all</i> bound values are scalars, one tuple
will be executed, making execute_array() act like execute().
<p>
The <code>ArrayTupleFetch</code> attribute can be used to specify a reference
to a subroutine that will be called to provide the bind values for
each tuple execution. The subroutine should return a reference to
an array which contains the appropriate number of bind values, or
return an undef if there is no more data to execute.
<p>
As a convienience, the <code>ArrayTupleFetch</code> attribute can also 
specify a statement handle, in which case the <method>fetchrow_arrayref</method>
method will be called on the given statement handle to retrieve
bind values for each tuple execution.
<p>
The values specified via <method>bind_param_array</method> or the @bind_values
parameter may be either scalars, or arrayrefs.  If any <code>@bind_values</code>
are given, then <code>execute_array</code> will effectively call <method>bind_param_array</method>
for each value before executing the statement.  Values bound in
this way are usually treated as <code>SQL_VARCHAR</code> types unless the
driver can determine the correct type, or unless
<method>bind_param</method>, <method>bind_param_inout</method>, <method>bind_param_array</method>, or
<method>bind_param_inout_array</method> has already been used to specify the type.
<p>
The <code>ArrayTupleStatus</code> attribute can be used to specify a
reference to an array which will receive the execute status of each
executed parameter tuple. Note the <code>ArrayTupleStatus</code> attribute was
mandatory until DBI 1.38.
<p>
For tuples which are successfully executed, the element at the same
ordinal position in the status array is the resulting rowcount.
If the execution of a tuple causes an error, the corresponding
status array element will be set to an array reference containing
the error code and error string set by the failed execution.
<p>
If <b>any</b> tuple execution returns an error, <method>execute_array</method> will
return <code>undef</code>. In that case, the application should inspect the
status array to determine which parameter tuples failed.
Some databases may not continue executing tuples beyond the first
failure, in which case the status array will either hold fewer
elements, or the elements beyond the failure will be undef.
<p>
Support for data returning statements such as SELECT is driver-specific
and subject to change. At present, the default implementation
provided by DBI only supports non-data returning statements.
<p>
Transaction semantics when using array binding are driver and
database specific.  If <member>DBD::_::db::AutoCommit</member> is on, the default DBI
implementation will cause each parameter tuple to be inidividually
committed (or rolled back in the event of an error). If <member>DBD::_::db::AutoCommit</member>
is off, the application is responsible for explicitly committing
the entire set of bound parameter tuples.  Note that different
drivers and databases may have different behaviours when some
parameter tuples cause failures. In some cases, the driver or
database may automatically rollback the effect of all prior parameter
tuples that succeeded in the transaction; other drivers or databases
may retain the effect of prior successfully executed parameter
tuples.
<p>
Note that performance will usually be better with
<member>DBD::_::db::AutoCommit</member> turned off, and using explicit 
<method>DBD::_::db::commit</method> after each
<method>execute_array</method> call.

@param \%attr a hash reference providing execution control attributes, including:
	<ul>
	<li><code>ArrayTupleStatus</code> =&gt; \@status - an array reference to receive 
		the execution status of each parameter tuple.
	<li><code>ArrayTupleFetch</code> =&gt; \$sub_or_sth - provides either a
		subroutine reference, or a statement handle, from which parameter tuples
		are retrieved in row-wise fashion, as an alternative to the column-wise
		@bind_values parameter specification.
	</ul>
	At present, both attributes are considered optional.
@optional @bind_values a list of placeholder values, either as scalars, or array references,
	similar to those provided to <method>bind_param_array</method>. Provided values
	override any parameters previously bound via <method>bind_param_array</method>.

@return returns the number of tuples executed, or <code>undef</code> if an error occured.
	Like <method>execute</method>, a successful execute_array() always returns true regardless
	of the number of tuples executed, even if it's zero. Any
	errors are reported in the <code>ArrayTupleStatus</code> array.

@returnlist the number of tuples executed (as for calling in scalar context), 
	and the sum of the number of rows affected for each tuple, if available, or -1 
	if the driver cannot determine this.
	Note that certain operations (e.g., UPDATE, DELETE) may report multiple 
	affected rows for one or more of the supplied parameter tuples. 
	Some drivers may not yet support the list context
	call, in which case the reported rowcount will be <code>undef</code>; 
	if a driver is not be able to provide 
	the number of rows affected when performing this batch operation, 
	the returned rowcount will be -1.

@see <method>bind_param_array</method>
@since 1.22

=end classdoc

=cut

    sub execute_array {
	my $sth = shift;
	my ($attr, @array_of_arrays) = @_;
	my $NUM_OF_PARAMS = $sth->FETCH('NUM_OF_PARAMS'); # may be undef at this point

	# get tuple status array or hash attribute
	my $tuple_sts = $attr->{ArrayTupleStatus};
	return $sth->set_err(1, "ArrayTupleStatus attribute must be an arrayref")
		if $tuple_sts and ref $tuple_sts ne 'ARRAY';

	# bind all supplied arrays
	if (@array_of_arrays) {
	    $sth->{ParamArrays} = { };	# clear out old params
	    return $sth->set_err(1,
		    @array_of_arrays." bind values supplied but $NUM_OF_PARAMS expected")
		if defined ($NUM_OF_PARAMS) && @array_of_arrays != $NUM_OF_PARAMS;
	    $sth->bind_param_array($_, $array_of_arrays[$_-1]) or return
		foreach (1..@array_of_arrays);
	}

	my $fetch_tuple_sub;

	if ($fetch_tuple_sub = $attr->{ArrayTupleFetch}) {	# fetch on demand

	    return $sth->set_err(1,
		    "Can't use both ArrayTupleFetch and explicit bind values")
		if @array_of_arrays; # previous bind_param_array calls will simply be ignored

	    if (UNIVERSAL::isa($fetch_tuple_sub,'DBI::st')) {
		my $fetch_sth = $fetch_tuple_sub;
		return $sth->set_err(1,
			"ArrayTupleFetch sth is not Active, need to execute() it first")
		    unless $fetch_sth->{Active};
		# check column count match to give more friendly message
		my $NUM_OF_FIELDS = $fetch_sth->{NUM_OF_FIELDS};
		return $sth->set_err(1,
			"$NUM_OF_FIELDS columns from ArrayTupleFetch sth but $NUM_OF_PARAMS expected")
		    if defined($NUM_OF_FIELDS) && defined($NUM_OF_PARAMS)
		    && $NUM_OF_FIELDS != $NUM_OF_PARAMS;
		$fetch_tuple_sub = sub { $fetch_sth->fetchrow_arrayref };
	    }
	    elsif (!UNIVERSAL::isa($fetch_tuple_sub,'CODE')) {
		return $sth->set_err(1, "ArrayTupleFetch '$fetch_tuple_sub' is not a code ref or statement handle");
	    }

	}
	else {
	    my $NUM_OF_PARAMS_given = keys %{ $sth->{ParamArrays} || {} };
	    return $sth->set_err(1,
		    "$NUM_OF_PARAMS_given bind values supplied but $NUM_OF_PARAMS expected")
		if defined($NUM_OF_PARAMS) && $NUM_OF_PARAMS != $NUM_OF_PARAMS_given;

	    # get the length of a bound array
	    my $maxlen;
	    my %hash_of_arrays = %{$sth->{ParamArrays}};
	    foreach (keys(%hash_of_arrays)) {
		my $ary = $hash_of_arrays{$_};
		next unless ref $ary eq 'ARRAY';
		$maxlen = @$ary if !$maxlen || @$ary > $maxlen;
	    }
	    # if there are no arrays then execute scalars once
	    $maxlen = 1 unless defined $maxlen;
	    my @bind_ids = 1..keys(%hash_of_arrays);

	    my $tuple_idx = 0;
	    $fetch_tuple_sub = sub {
		return if $tuple_idx >= $maxlen;
		my @tuple = map {
		    my $a = $hash_of_arrays{$_};
		    ref($a) ? $a->[$tuple_idx] : $a
		} @bind_ids;
		++$tuple_idx;
		return \@tuple;
	    };
	}
	# pass thru the callers scalar or list context
	return $sth->execute_for_fetch($fetch_tuple_sub, $tuple_sts);
    }

=pod

=begin classdoc

Perform a bulk operation using parameter tuples collected from the
supplied subroutine reference or statement handle.
Most often used via the <method>execute_array</method> method, not directly.
<p>
If the driver detects an error that it knows means no further tuples can be
executed then it may return with an error status, even though $fetch_tuple_sub
may still have more tuples to be executed.
<p>
Although each tuple returned by $fetch_tuple_sub is effectively used
to call <method>execute</method>, the exact timing may vary.
Drivers are free to accumulate sets of tuples to pass to the
database server in bulk group operations for more efficient execution.
However, the $fetch_tuple_sub is specifically allowed to return
the same array reference each time (as <method>fetchrow_arrayref</method>
usually does).

@param $fetch_tuple_sub a fetch subroutine which
	returns a reference to an array (known as a 'tuple') or undef.
	$fetch_tuple_sub is repeatedly called without any
	parameters, until it returns a false value. Each returned tuple is
	used to provide bind values for an <method>execute</method> call.
@optional \@tuple_status an array reference to receive the execution
	status of each executed parameter tuple. If the corresponding <method>execute</method>
	did not fail, the element contains the <method>execute</method> return value (typically
	a row count). If the <method>execute</method> failed. the element contains an
	array reference containing the error code, error message string, and SQLSTATE
	value.

@return <code>undef</code> if there were any errors; otherwise,
	the number of tuples executed. Like <method>execute<method> and
	<method>execute_array<method>, a zero tuple count is returned as 
	"0E0". If there were any errors, the @tuple_status array
	can be used to discover which tuples failed and with what errors.

@returnlist the tuple execution count, and the sum of the number of rows 
	affected for each tuple, if available, or -1 if the driver cannot determine the
	affected rowcount.
	Certain operations (e.g., UPDATE, DELETE) may cause multiple affected rows
	for a single parameter tuple.
	Some drivers may not yet support list context, in which case
	the returned rowcount will be undef.

@since 1.38

=end classdoc

=cut

    sub execute_for_fetch {
	my ($sth, $fetch_tuple_sub, $tuple_status) = @_;
	# start with empty status array
	($tuple_status) ? @$tuple_status = () : $tuple_status = [];

        my $rc_total = 0;
	my $err_count;
	while ( my $tuple = &$fetch_tuple_sub() ) {
	    if ( my $rc = $sth->execute(@$tuple) ) {
		push @$tuple_status, $rc;
		$rc_total = ($rc >= 0 && $rc_total >= 0) ? $rc_total + $rc : -1;
	    }
	    else {
		$err_count++;
		push @$tuple_status, [ $sth->err, $sth->errstr, $sth->state ];
                # XXX drivers implementing execute_for_fetch could opt to "last;" here
                # if they know the error code means no further executes will work.
	    }
	}
        my $tuples = @$tuple_status;
        return $sth->set_err(1, "executing $tuples generated $err_count errors")
            if $err_count;
	$tuples ||= "0E0";
	return $tuples unless wantarray;
	return ($tuples, $rc_total);
    }


=pod

=begin classdoc

Fetch all the data (or a slice of all the data) to be returned from this statement handle. 
<p>
A standard <code>while</code> loop with column binding is often faster because
the cost of allocating memory for the batch of rows is greater than
the saving by reducing method calls. It's possible that the DBI may
provide a way to reuse the memory of a previous batch in future, which
would then shift the balance back towards this method.

@optional $slice either an array or hash reference.
	If an array reference, this method uses <method>fetchrow_arrayref</method>
	to fetch each row as an array ref. If the $slice array is not empty,
	it is used to select individual columns by Perl array index number 
	(starting at 0, unlike column and parameter numbers which start at 1).
	If $slice is undefined, acts as if passed an empty array ref.
	<p>
	If $slice is a hash reference, this method uses <method>fetchrow_hashref</method>
	to fetch each row as a hash reference. If the $slice hash is empty,
	<method>fetchrow_hashref</method> is repeatedly called and the keys in the hashes
	have whatever name lettercase is returned by default.
	(See the <member>FetchHashKeyName</member> attribute.) If the $slice hash is not
	empty, it is used to select individual columns by name.  The values of the hash 
	should be set to 1.  The key names of the returned hashes match the letter case 
	of the names in the parameter hash, regardless of the <member>FetchHashKeyName</member> attribute
	value.

@optional $max_rows an positive integer value used to limit the number of returned rows.

@return an array reference containing one array reference per row.
	If there are no rows to return, returns a reference
	to an empty array. If an error occurs, returns the data fetched thus far, 
	which may be none, with the error indication available via the
	<method>err</method> method (or use the <member>RaiseError</member> attribute).


=end classdoc

=cut

    sub fetchall_arrayref {	# ALSO IN Driver.xst
	my ($sth, $slice, $max_rows) = @_;
	$max_rows = -1 unless defined $max_rows;
	my $mode = ref($slice) || 'ARRAY';
	my @rows;
	my $row;
	if ($mode eq 'ARRAY') {
	    # we copy the array here because fetch (currently) always
	    # returns the same array ref. XXX
	    if ($slice && @$slice) {
		$max_rows = -1 unless defined $max_rows;
		push @rows, [ @{$row}[ @$slice] ]
		    while($max_rows-- and $row = $sth->fetch);
	    }
	    elsif (defined $max_rows) {
		$max_rows = -1 unless defined $max_rows;
		push @rows, [ @$row ]
		    while($max_rows-- and $row = $sth->fetch);
	    }
	    else {
		push @rows, [ @$row ]          while($row = $sth->fetch);
	    }
	}
	elsif ($mode eq 'HASH') {
	    $max_rows = -1 unless defined $max_rows;
	    if (keys %$slice) {
		my @o_keys = keys %$slice;
		my @i_keys = map { lc } keys %$slice;
		while ($max_rows-- and $row = $sth->fetchrow_hashref('NAME_lc')) {
		    my %hash;
		    @hash{@o_keys} = @{$row}{@i_keys};
		    push @rows, \%hash;
		}
	    }
	    else {
		# XXX assumes new ref each fetchhash
		push @rows, $row
		    while ($max_rows-- and $row = $sth->fetchrow_hashref());
	    }
	}
	else { Carp::croak("fetchall_arrayref($mode) invalid") }
	return \@rows;
    }

=pod

=begin classdoc

Fetch all the data returned by this statement handle. 
Normally used only where the key fields values for each row are unique.  
If multiple rows are returned with the same values for the key fields, then 
later rows overwrite earlier ones.
<p>
<method>err</method> can be called to discover if the returned data is 
complete or was truncated due to an error.

@param $key_field	the name of the field that holds the value to be used for the key for the returned hash.
	May also be specified as an integer column number (counting from 1). If the specified name doesn't 
	match any column in the statement, as a name or number, an error is returned.
	May also be specified as an array reference containing one or more key column names (or index numbers)
	for a multicolumn key.

@return a hash reference mapping each distinct returned value of the $key_field column(s) to
	a hash reference containing all the selected columns and their values (as returned by 
	<method>fetchrow_hashref</method>). If there are no rows to return,
	returns an empty hash reference. If an error occurs, returns the
	data fetched thus far, which may be none. If $key_field was specified as a multicolumn
	key, the returned hash reference values will be a hash reference keyed by
	the next column value in the key, iterating until the key is completely specified,
	with the final key column hash reference containing the selected columns hash.

=end classdoc

=cut

    sub fetchall_hashref {
	my ($sth, $key_field) = @_;

        my $hash_key_name = $sth->{FetchHashKeyName} || 'NAME';
        my $names_hash = $sth->FETCH("${hash_key_name}_hash");
        my @key_fields = (ref $key_field) ? @$key_field : ($key_field);
        my @key_indexes;
        my $num_of_fields = $sth->FETCH('NUM_OF_FIELDS');
        foreach (@key_fields) {
           my $index = $names_hash->{$_};  # perl index not column
           $index = $_ - 1 if !defined $index && DBI::looks_like_number($_) && $_>=1 && $_ <= $num_of_fields;
           return $sth->set_err(1, "Field '$_' does not exist (not one of @{[keys %$names_hash]})")
                unless defined $index;
           push @key_indexes, $index;
        }
        my $rows = {};
        my $NAME = $sth->FETCH($hash_key_name);
        my @row = (undef) x $num_of_fields;
        $sth->bind_columns(\(@row));
        while ($sth->fetch) {
            my $ref = $rows;
            $ref = $ref->{$row[$_]} ||= {} for @key_indexes;
            @{$ref}{@$NAME} = @row;
        }
        return $rows;
    }

    *dump_results = \&DBI::dump_results;

    sub blob_copy_to_file {	# returns length or undef on error
	my($self, $field, $filename_or_handleref, $blocksize) = @_;
	my $fh = $filename_or_handleref;
	my($len, $buf) = (0, "");
	$blocksize ||= 512;	# not too ambitious
	local(*FH);
	unless(ref $fh) {
	    open(FH, ">$fh") || return undef;
	    $fh = \*FH;
	}
	while(defined($self->blob_read($field, $len, $blocksize, \$buf))) {
	    print $fh $buf;
	    $len += length $buf;
	}
	close(FH);
	$len;
    }

    sub more_results {
	shift->{syb_more_results};	# handy grandfathering
    }

=pod

=begin classdoc 

@xs err

Return the error code from the last driver method called. 

@return the <i>native</i> database engine error code; may be zero
	to indicate a warning condition. May be an empty string
	to indicate a 'success with information' condition. In both these
	cases the value is false but not undef. The errstr() and state()
	methods may be used to retrieve extra information in these cases.

@see <method>set_err</method>

=end classdoc

=begin classdoc 

@xs errstr

Return the error message from the last driver method called.
<p>
Should not be used to test for errors as some drivers may return 
'success with information' or warning messages via errstr() for 
methods that have not 'failed'.

@return One or more native database engine error messages as a single string;
	multiple messages are separated by newline characters.
	May be an empty string if the prior driver method returned successfully.

@see <method>set_err</method>

=end classdoc

=begin classdoc 

@xs state

Return the standard SQLSTATE five character format code for the prior driver
method.
The success code <code>00000</code> is translated to any empty string
(false). If the driver does not support SQLSTATE (and most don't),
then state() will return <code>S1000</code> (General Error) for all errors.
<p>
The driver is free to return any value via <code>state</code>, e.g., warning
codes, even if it has not declared an error by returning a true value
via the err() method described above.
<p>
Should not be used to test for errors as drivers may return a 
'success with information' or warning state code via state() for 
methods that have not 'failed'.

@return if state is currently successful, an empty string; else,
	a five character SQLSTATE code.

=end classdoc

=begin classdoc 

@xs set_err

Set the <code>err</code>, <code>errstr</code>, and <code>state</code> values for the handle.
If the <member>HandleSetErr</member> attribute holds a reference to a subroutine
it is called first. The subroutine can alter the $err, $errstr, $state,
and $method values. See <member>HandleSetErr</member> for full details.
If the subroutine returns a true value then the handle <code>err</code>,
<code>errstr</code>, and <code>state</code> values are not altered and set_err() returns
an empty list (it normally returns $rv which defaults to undef, see below).
<p>
Setting <code>$err</code> to a <i>true</i> value indicates an error and will trigger
the normal DBI error handling mechanisms, such as <code>RaiseError</code> and
<code>HandleError</code>, if they are enabled, when execution returns from
the DBI back to the application.
<p>
Setting <code>$err</code> to <code>""</code> indicates an 'information' state, and setting
it to <code>"0"</code> indicates a 'warning' state. Setting <code>$err</code> to <code>undef</code>
also sets <code>$errstr</code> to undef, and <code>$state</code> to <code>""</code>, irrespective
of the values of the $errstr and $state parameters.
<p>
The $method parameter provides an alternate method name for the
<code>RaiseError</code>/<code>PrintError</code>/<code>PrintWarn</code> error string instead of
the fairly unhelpful '<code>set_err</code>'.
<p>
Some special rules apply if the <code>err</code> or <code>errstr</code>
values for the handle are <i>already</i> set.
<p>
If <code>errstr</code> is true then: "<code> [err was %s now %s]</code>" is appended if $err is
true and <code>err</code> is already true and the new err value differs from the original
one. Similarly "<code> [state was %s now %s]</code>" is appended if $state is true and <code>state</code> is
already true and the new state value differs from the original one. Finally
"<code>\n</code>" and the new $errstr are appended if $errstr differs from the existing
errstr value. Obviously the <code>%s</code>'s above are replaced by the corresponding values.
<p>
The handle <code>err</code> value is set to $err if: $err is true; or handle
<code>err</code> value is undef; or $err is defined and the length is greater
than the handle <code>err</code> length. The effect is that an 'information'
state only overrides undef; a 'warning' overrides undef or 'information',
and an 'error' state overrides anything.
<p>
The handle <code>state</code> value is set to $state if $state is true and
the handle <code>err</code> value was set (by the rules above).
<p>
This method is typically only used by DBI drivers and DBI subclasses.

@param $err an error code, or "" to indicate success with information, or 0 to indicate warning
@param $errstr a descriptive error message
@optional $state an associated five character SQLSTATE code; defaults to "S1000" if $err is true.
@optional \&method method name included in the
	<code>RaiseError</code>/<code>PrintError</code>/<code>PrintWarn</code> error string
@optional $rv the value to return from this method; default undef
@return the $rv value, if specified; else undef.

=end classdoc

=begin classdoc 

@xs trace

Set the trace settings for the handle object. 
Also can be used to change where trace output is sent.
<p>
A similar method, <code>DBI-&gt;trace</code>, sets the global default trace
settings.

@see <cpan>DBI</cpan> manual TRACING section for full details about DBI's
tracing facilities.

@param $trace_setting	a numeric value indicating a trace level. Valid trace levels are:
<ul>
<li>0 - Trace disabled.
<li>1 - Trace DBI method calls returning with results or errors.
<li>2 - Trace method entry with parameters and returning with results.
<li>3 - As above, adding some high-level information from the driver
      and some internal information from the DBI.
<li>4 - As above, adding more detailed information from the driver.
<li>5 to 15 - As above but with more and more obscure information.
</ul>

@optional $trace_file	either a string filename, or a Perl filehandle reference, to which
	trace output is to be appended. If not spcified, traces are sent to <code>STDOUT</code>.

@return the previous $trace_setting value

=end classdoc

=begin classdoc 

@xs trace_msg

Write a trace message to the handle object's current trace output.

@param $message_text message to be written
$optional $min_level	the minimum trace level at which the message is written; default 1

@see <cpan>DBI</cpan> manual TRACING section for full details about DBI's
tracing facilities.

=end classdoc

=begin classdoc 

@xs func

Call the specified driver private method.
<p>
Note that the function
name is given as the <i>last</i> argument.
<p>
Also note that this method does not clear
a previous error ($DBI::err etc.), nor does it trigger automatic
error detection (RaiseError etc.), so the return
status and/or $h->err must be checked to detect errors.

@param @func_arguments	any arguments to be passed to the function
@param $func the name of the function to be called
@see <code>install_method</code> in <cpan>DBI::DBD</cpan>
	for directly installing and accessing driver-private methods.

@return any value(s) returned by the specified function

=end classdoc

=begin classdoc 

@xs can

Does this driver or the DBI implement this method ?

@param $method_name name of the method being tested
@return true if $method_name is implemented by the driver or a non-empty default method is provided by DBI;
	otherwise false (i.e., the driver hasn't implemented the method and DBI does not
	provide a non-empty default).

=end classdoc

=begin classdoc 

@xs parse_trace_flags

Parse a string containing trace settings.
Uses the parse_trace_flag() method to process
trace flag names.

@param $trace_settings a string containing a trace level between 0 and 15 and/or 
	trace flag names separated by vertical bar ("<code>|</code>") or comma 
	("<code>,</code>") characters. For example: <code>"SQL|3|foo"</code>.

@return the corresponding integer value used internally by the DBI and drivers.

@since 1.42

=end classdoc

=begin classdoc 

@xs parse_trace_flag

  $bit_flag = $h->parse_trace_flag($trace_flag_name);

Return the bit flag value for the specified trace flag name.
<p>
Drivers should override this method and
check if $trace_flag_name is a driver specific trace flag and, if
not, then call the DBI's default parse_trace_flag().

@param $trace_flag_name the name of a (possibly driver-specific) trace flag as a string

@return if $trace_flag_name is a valid flag name, the corresponding bit flag; otherwise, undef

@since 1.42

=end classdoc

=begin classdoc 

@xs private_attribute_info

Return the list of driver private attributes for this handle object.

@return a hash reference mapping attribute name as keys to <code>undef</code>
	(the attribute's current values may be supplied in future)

=end classdoc

=begin classdoc 

@xs swap_inner_handle

Swap the internals of 2 handle objects.
Brain transplants for handles. You don't need to know about this
unless you want to become a handle surgeon.
<p>
A DBI handle is a reference to a tied hash. A tied hash has an
<i>inner</i> hash that actually holds the contents.  This
method swaps the inner hashes between two handles. The $h1 and $h2
handles still point to the same tied hashes, but what those hashes
are tied to is swapped.  In effect $h1 <i>becomes</i> $h2 and
vice-versa. This is powerful stuff, expect problems. Use with care.
<p>
As a small safety measure, the two handles, $h1 and $h2, have to
share the same parent unless $allow_reparent is true.
<p>
Here's a quick kind of 'diagram' as a worked example to help think about what's
happening:
<pre>
    Original state:
            dbh1o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh2o -> dbh2i

    swap_inner_handle dbh1o with dbh2o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i

    create new sth from dbh1o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthBo -> sthBi(dbh2i)

    swap_inner_handle sthAo with sthBo:
            dbh2o -> dbh1i
            sthBo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthAo -> sthBi(dbh2i)
</pre>

@param $h2	the handle object to swap with this handle
@optional $allow_reparent	if true, permits the two handles to have
	different parent objects; default is false

@return true if the swap succeeded; otherwise, undef
@since 1.44

=end classdoc

=begin classdoc

@xs bind_param_inout

Bind (<i>aka, associate</i>) a scalar reference of <code>$bind_value</code>
to the specified placeholder in this statement object.
Placeholders within a statement string are normally indicated with question
mark character (<code>?</code>); some drivers permit alternate placeholder
syntax.
<p>
This method acts like <method>bind_param</method>, but enables values to be
updated by the statement. The statement is typically
a call to a stored procedure. The <code>$bind_value</code> must be passed as a
reference to the actual value to be used.
Undefined values or <code>undef</code> are used to indicate null values.
<p>
Note that unlike <method>bind_param</method>, the <code>$bind_value</code> variable is not
copied when <code>bind_param_inout</code> is called. Instead, the value in the
variable is read at the time <method>execute</method> is called.
<p>
The data type for a placeholder cannot be changed after the first
<code>bind_param</code> call, after which the driver
may ignore the $bind_type parameter for that placeholder.
<p>
Perl only has string and number scalar data types. All database types
that aren't numbers are bound as strings and must be in a format the
database will understand except where the bind_param() TYPE attribute
specifies a type that implies a particular format.
<p>
As an alternative to specifying the data type in this call,
consider using the default type (<code>VARCHAR</code>) and
use an SQL function to convert the type within the statement.
For example:
<pre>
  INSERT INTO price(code, price) VALUES (?, CONVERT(MONEY,?))
</pre>

@param $p_num	the number of the placeholder to be bound. Some drivers support an alternate
	named placeholder syntax, in which case $p_num may be a string.
@param \$bind_value	scalar reference bound to the placeholder
@optional $max_len the minimum amount of memory to allocate to <code>$bind_value</code> for 
	the output value. If the size of the output value exceeds this value, the subsequent
	<method>execute</method> should fail.
@optional $bind_type either a scalar SQL type code (from the <code>DBI :sql_types</code> export list),
	or a hash reference of type information, which may include the following keys:
	<ul>
	<li>TYPE =&gt; $sql_type 	- the SQL type code
	<li>PRECISION =&gt; $precision 	- the precision of the supplied value
	<li>SCALE =&gt; $scale 	- the scale of the supplied value
	</ul>
	If not specified, the default <code>VARCHAR</code> type will be assumed.

@see <a href='DBI.pod.html#DBI_Constants'>DBI Constants</a>
@see <a href='DBI.pod.html#Placeholders_and_Bind_Values'>Placeholders and Bind Values</a> for more information.

=end classdoc

=begin classdoc

@xs execute

Execute this statement object's statement.
<p>
If any <code>@bind_value</code> arguments are given, this method will effectively call
<method>bind_param</method> for each value before executing the statement. Values
bound in this way are usually treated as <code>SQL_VARCHAR</code> types unless
the driver can determine the correct type, or unless a prior call to
<code>bind_param</code> (or <code>bind_param_inout</code>) has been used to
specify the type.
<p>
If called on a statement handle that's still active,
(<member>Active</member> is true), the driver should effectively call 
<method>finish</method> to tidy up the previous execution results before starting the new
execution.
<p>
For data returning statements, this method starts the query within the
database engine. Use one of the fetch methods to retrieve the data after
calling <code>execute</code>.  This method does <i>not</i> return the number of
rows that will be returned by the query, because most databases can't
tell in advance.
<p>
The <member>NUM_OF_FIELDS</member> attribute can be used to determine if the 
statement is a data returning statement (it should be greater than zero).

@optional @bind_values a list of values to be bound to any placeholders
	in the statement. 

@return <code>undef</code> on failure. On success, returns true regardless of the 
	number of rows affected, even if it's zero. For a <i>non</i>-data returning statement, 
	returns the number of rows affected, if known. If no rows were affected, returns
	"<code>0E0</code>", which Perl will treat as 0 but will regard as true.
	If the number of rows affected is not known, returns -1.
	For data returning statements, returns a true (but not meaningful) value.
	<p>
	The error, warning, or informational status of this method is available 
	via the <method>err</method>, <method>errstr</method>,
	and <method>state</method> methods.

=end classdoc

=begin classdoc

@xs fetchrow_arrayref

Fetch the next row of data.
This is the fastest way to fetch data, particularly if used with
<method>bind_columns</method>.
<p>
Note that the same array reference is returned for each fetch, and so 
should not be stores and reused after a later fetch.  Also, the
elements of the array are also reused for each row, so take care if you
want to take a reference to an element.

@return an array reference containing the current row's field values.
	Null fields are returned as <code>undef</code> values in the array.
	If there are no more rows or if an error occurs, returns <code>undef</code>.
	Any error indication is available via the <method>err</method> method.

@see <method>bind_columns</method>

=end classdoc

=begin classdoc

@xs fetch

Fetch the next row of data.
<p>
This is a deprecated alias for <method>fetchrow_arrayref</method>.

@deprecated

=end classdoc

=begin classdoc

@xs fetchrow_array

Fetch the next row of data.
An alternative to <method>fetchrow_arrayref</method>.

@returnlist the row's field values.  Null fields
	are returned as <code>undef</code> values in the list.
	If there are no more rows or if an error occurs, returns an empty list. 
	Any error indication is available via the <method>err</method> method.

@return the value of the first column or the last column (depending on the driver).
	Returns <code>undef</code> if there are no more rows or if an error occurred,
	which is indistinguishable from a NULL returned field value.
	For these reasons, <b>avoid calling this method in scalar context.</b>

=end classdoc

=begin classdoc

@xs fetchrow_hashref

Fetch the next row of data.
An alternative to <code>fetchrow_arrayref</code>.
<p>
This method is not as efficient as <code>fetchrow_arrayref</code> or <code>fetchrow_array</code>.

@optional $name  the name of the statement handle attribute to use as the source for the
	field names used as keys in the returned hash.
	For historical reasons it defaults to "<code>NAME</code>", however using either
	"<code>NAME_lc</code>" or "<code>NAME_uc</code>" is recomended for portability.

@return a hash reference mapping the statement's field names to the row's field
	values.  Null fields are returned as <code>undef</code> values in the hash.
	If there are no more rows or if an error occurs, returns <code>undef</code>. 
	Any error indication is available via the <method>err</method> method.
	<p>
	The keys of the hash are the same names returned by <code>$sth-&gt;{$name}</code>. If
	more than one field has the same name, there will only be one entry in
	the returned hash for those fields.
	<p>
	By default a reference to a new hash is returned for each row.
	It is likely that a future version of the DBI will support an
	attribute which will enable the same hash to be reused for each
	row. This will give a significant performance boost, but it won't
	be enabled by default because of the risk of breaking old code.

=end classdoc

=begin classdoc

@xs finish

Indicate that no more data will be fetched from this statement handle
before it is either executed again or destroyed.  This method
is rarely needed, and frequently overused, but can sometimes be
helpful in a few very specific situations to allow the server to free
up resources (such as sort buffers).
<p>
When all the data has been fetched from a data returning statement, the
driver should automatically call this method; therefore, calling this
method explicitly should not be needed, <i>except</i> when all rows
have not benn fetched from this statement handle.
<p>
Resets the <member>Active</member> attribute for this statement, and
may also make some statement handle attributes (such as <member>NAME</member> and <member>TYPE</member>)
unavailable if they have not already been accessed (and thus cached).
<p>
This method does not affect the transaction status of the
parent database connection.  

@see <method>DBD::_::db::disconnect</method>
@see <member>Active</member>

=end classdoc

=begin classdoc

@xs rows

Get the number of rows affected by the last row affecting command.
Generally, you can only rely on a row count after a <i>non</i>-data-returning
<method>execute</method> (for some specific operations like <code>UPDATE</code> and <code>DELETE</code>), or
after fetching all the rows of a data returning statement.
<p>
For data returning statements, it is generally not possible to know how many
rows will be returned except by fetching them all.  Some drivers will
return the number of rows the application has fetched so far, but
others may return -1 until all rows have been fetched; therefore, use of this
method (or <code>$DBI::rows</code>) with data returning statements is not
recommended.
<p>
An alternative method to get a row count for a data returning statement is to execute a
<code>"SELECT COUNT(*) FROM ..."</code> SQL statement with the same predicate, grouping, etc.
as this statement's query.

@return the number of rows affected by the last row affecting command.

=end classdoc

=begin classdoc

@xs bind_col

Bind a Perl variable to an output column(field) of a data returning statement.
<p>
Note that columns do not need to be bound in order to fetch data.
For maximum portability between drivers, bind_col() should be called
<b>after</b> execute().
<p>
Whenever a row is fetched from this statement handle, <code>$var_to_bind</code> appears
to be automatically updated,
The binding is performed at a low level using Perl aliasing,
so that the bound variable refers to the same
memory location as the corresponding column value, thereby making
bound variables very efficient.
<p>
Binding a tied variable is not currently supported.
<p>
The data type for a bind variable cannot be changed after the first
<code>bind_col</code> call.

@param $column_number	the positional column number (counting from 1) to which the variable
	is to be bound
@param \$var_to_bind	the scalar reference to receive the specified column's return value.
	May also be <code>undef</code>, which causes the corresponding column to be
	returned (via future fetch method calls) in a format compatible with the specifed $bind_type.
@optional $bind_type	either a scalar SQL type code, or a hash reference of detailed
	type information. Supported type information includes
	<ul>
	<li>TYPE =&gt; $sql_type - the SQL type code
	<li>PRECISION =&gt; $precision - the precision of the returned value
	<li>SCALE =&gt; $scale - the scale of the returned value
	</ul>
	If not specified, defaults to the driver's default return type (usually 
	the same as specified in the corresponding <member>TYPE</member>, <member>PRECISION</member>, 
	and <member>SCALE</member> attributes).

@see <method>bind_columns</method>
@see <a href='DBI.pod.html#DBI_Constants'>DBI Constants</a> for more information.

=end classdoc

=begin classdoc

@xs dump_results

Dump all the rows from this statement in a human-readable format.
Fetches all the rows, calling <method>DBI::neat_list</method> for each row, and
printing the formatted rows to <code>$fh</code> separated by <code>$lsep</code>, with
fields separated by <code>$fsep</code>.
<p>
This method is a handy utility for prototyping and
testing queries. Since it uses <method>neat_list</method> to
format and edit the string for reading by humans, it is not recomended
for data transfer applications.

@optional $maxlen the maximum number of rows to dump (defaults to 35)
@optional $lsep the row separator string (default <code>"\n"</code>)
@optional $fsep the field separator string (defaults to <code>", "</code>)
@optional $fh the filehandle to which to print the formatted rows (defaults to <code>STDOUT</code>) 

@return the number of rows dumped

=end classdoc

=cut

}

unless ($DBI::PurePerl) {   # See install_driver
    { @DBD::_mem::dr::ISA = qw(DBD::_mem::common);	}
    { @DBD::_mem::db::ISA = qw(DBD::_mem::common);	}
    { @DBD::_mem::st::ISA = qw(DBD::_mem::common);	}
    # DBD::_mem::common::DESTROY is implemented in DBI.xs
}

1;
__END__

