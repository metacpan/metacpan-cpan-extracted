=head1 NAME

Postgres::Handler - Builds upon DBD::Pg for advanced CGI web apps

=head1 DESCRIPTION

Postgres::Handler builds upon the foundation set by
DBI and DBD::Pg to create a superset of methods for tying together
some of the basic interface concepts of DB management when used
in a web server environment. Postgres::Handler is meant to build 
upon the strengths of DBD::Pg and DBI and add common usability 
features for a variety of Internet applications.

Postgres::Handler encapsulates error message handling, information
message handling, simple caching of requests through a complete
iteration of a server CGI request.  You will also find some key
elements that hook the CGI class to the DBI class to simplify
data IO to & from web forms and dynamic pages.

=head1 SYNOPSIS

 # Instantiate Object
 #
 use Postgres::Handler;
 my $DB = Postgres::Handler->new(dbname=>'products',dbuser=>'postgres',dbpass=>'pgpassword');
 
 # Retrieve Data & List Records
 #
 $DB->PrepLEX('SELECT * FROM products');
 while ($item=$DB->GetRecord()) {
     print "$item->{PROD_ID}\t$item->{PROD_TITLE}\t$item->{PROD_QTY}\n";
 }
 
 # Add / Update Record based on CGI Form
 # assuming objCGI is an instatiated CGI object
 # if the CGI param 'prod_id' is set we update
 # if it is not set we add
 #
 my %cgimap;
 foreach ('prod_id','prod_title','prod_qty') { $cgimap{$_} = $_; }
 $DB->AddUpdate( CGI=>$objCGI     , CGIKEY=>'prod_id', 
                 TABLE=>'products', DBKEY=>'prod_id',
                 hrCGIMAP=>\%cgimap
                );

=head1 REQUIRES

 CGI::Carp
 CGI::Util
 Class::Struct
 DBD::Pg 1.43 or greater (fixes a bug when fetching Postgres varchar[] array data)
 DBI

=head1 EXPORT

None by default.

=cut
#==============================================================================


#==============================================================================
#
# Package Preparation
# Sets up global variables and invokes required libraries.
#
#==============================================================================

use CGI::Carp;
package Postgres::Handler;									# Define the package name
use CGI::Util qw(rearrange);
use Class::Struct;
use DBI;

use constant cPGNoRecs	=> '0E0';

#==============================================================================

=head1 DATA ACCESS METHODS

=head2 new()

 Create a new Postgres::Handler object.

=over

=item Parameters

 dbname => name of the database to connect to

 dbuser => postgres user

 dbpass => password for that user

=back

=head2 data()

 Get/set the data hash - this is where data fields are stored
 for the active record.   

=head2 dbh()

 Returns the database handle for the DB connection.

=head2 dbpass()

 Get/set postgres user's password.

=head2 dbname()

 Get/set database name.
 Simple string name of the database.

=head2 dbuser()

 Get/set postgres username.

=head2 sth()

 Returns the statement handle for the active record selection.
 
=cut
#==============================================================================

our $VERSION 				= 2.2;							# Set our version
our $BUILD					= '2006-04-13 11:22';		# BUILD

struct (
		dbname	=> '$',
		dbuser	=> '$',
		dbpass	=> '$',
		dbh		=> '$',
		sth		=> '$',
		data		=> '%'
);

#==============================================================================

=head1 PUBLIC METHODS

=cut

#==============================================================================

#--------------------------------------------------------------------

=head2 AddUpdate()

 Adds a new record or updates an existing record in the database
 depending on whether or not a specific CGI parameter has been set.

 Useful for processing a posted form that contains form fields
 that match data fields.   Pre-populate the form field that contains
 the database key field and an update occurs.  Set it to blank and
 a new record is added.

 Your database key field should have a default value that is unique
 and should be set as type 'PRIMARY KEY'.  We always use serial primary 
 key to auto-increment our keys when adding new records.

=over

=item example

 --
 -- Table: xyz
 --
 
 CREATE TABLE xyz (
    xyz_pkid    serial       primary key,
	 xyz_update  timestamp    default now(),
	 xyz_ipadd   char(32)
	 );

=back

 If a key is provided but is doesn't match anything in the existing
 data then the update fails, UNLESS... CHECKKEY=> 1 in which case it
 will attempt to add the record.

 Your CGI->DB key hash reference should look something like this:
 %mymap = ( tablefld_name => 'form_name', tablefld_ssn => 'htmlform_ssn' );
 And is passed with a simple \%mymap as the hrCGIMAP parameter to this function.
 -or-
 Even better, name your CGI form fields the same thing as your Postgres DB field
 names.  Then you can skip the map altogether and just provide the CGISTART
 variable.  All fields that start with the the CGISTART string will be mapped.
 Want to map every field?  Set CGISTART = '.'.

=over

=item Parameters (Required)

 CGI       => a CGI object from the CGI:: module

 DBKEY     => the name of the key field within the table
              defaults to Postgres::Handler Object Property <table>!PGHkeyfld
              must be provided 
				  - or -
			     the <table>!PGHkeyfld option must have
              been setup when creating a new Postgres::Handler object

 TABLE     => the name of the table to play with

 CGISTART or hrCGIMAP must be set (see below)

=item Parameters (Optional)

 CGISTART  => map all CGI object fields starting with this string
              into equivalently named database fields
				  only used when hrCGIMAP is not set

 CGIKEY    => the CGI parameter name that stores the data key
              defaults to DBKEY


 CHECKKEY  => set to 1 to perform ADD if the DBKEY is not found in the
              database.

 DBSTAMP   => the name of the timestamp field within the table
              defaults to Postgres::Handler Object Property <table>!PGHtimestamp

 DONTSTAMP => set to 1 to stop timestamping
              timestamp field must be set

 hrCGIMAP  => a reference to a hash that contains CGI params as keys and
              DB field names as values

 MD5   	  => the name of the md5 encrypted field within the table
              defaults to Postgres::Handler Object Property <table>!PGHmd5

 REQUIRED  => array reference pointing to array that holds list of CGI
              params that must contain data

 VERBOSE   => set to 1 to set lastinfo() = full command string
              otherwise returns 'INSERT' or 'UPDATE' on succesful execution

 BOOLEANS  => array reference pointing to the array that holds the list
              of database field booleans that we want to force to false
				  if not set by the equivalently named CGI field

 RTNSEQ    => set to a sequence name and AddUpdate will return the value of this
              sequence for the newly added record.  Useful for getting keys back
				  from new records.

=item Action

 Either adds or updates a record in the specified table.

 Record is added if CGI data key [1] is blank or if CHECKKEY is set
 and the value of the key is not already in the database.

 Record is updated if CGI data key [2] contains a value.

=item Returns

 1 for success, get message with lastinfo()
 0 for failure, get message with lasterror()

=back

=cut
#----------------------------
sub AddUpdate() {
	my $self = shift;
	my %options = @_;
	my @values;
	my $cmdstr;
	my $data;
	my $forceAdd;

	# CGI Map If Not Defined
	#
	if (! defined $options{hrCGIMAP}) {	
		if ($options{CGISTART} eq '') { 
			$self->data(ERRMSG,"PGH AddUpdate - parameter CGISTART or hrCGIMAP is required.");			
			return; 
		}
		my %map;
		$options{hrCGIMAP} = \%map;
		$self->CGIMap(%options); 
	}

	# Set Defaults
	#
	$options{DBKEY} 	||= $self->data("$options{TABLE}!PGHkeyfld");
	$options{DBSTAMP} ||= $self->data("$options{TABLE}!PGHtimestamp") || '';
	$options{MD5} 		||= $self->data("$options{TABLE}!PGHmd5");
	$options{CGIKEY}  ||= $options{DBKEY};

	if (!$options{DONTSTAMP} && $options{DBSTAMP}) 	{  $options{hrCGIMAP}->{$options{DBSTAMP}} = $options{DBSTAMP}; }

	# Check Mandatory Parameters
	#
	foreach (CGI, TABLE, DBKEY) { 
		if (!defined $options{$_}) { 
			$self->data(ERRMSG,"PGH AddUpdate - parameter $_ is required for table $options{TABLE}.");			
			return 0; 
		} 
	}

	# Setup Field Mapper
	#
	my @inflds = sort keys %{$options{hrCGIMAP}};


	# Check Required Data Fields
	#
	if ($options{REQUIRED}) {
		foreach (@{$options{REQUIRED}}) {
			if ($options{CGI}->param($options{hrCGIMAP}->{$_}) eq '') {
				$self->data(ERRMSG,"PGH AddUpdate - CGI parameter $_ must contain data.");			
				return 0;
			}
		}		
	}

	# Check Key Set
	# 
	if ($options{CHECKKEY}) {
		$self->PrepLEX(qq[SELECT $options{DBKEY} FROM $options{TABLE} WHERE $options{DBKEY} = ] . $self->Quote($options{CGI}->param($options{CGIKEY})));
		$forceAdd = ($self->sth->fetchrow ne $options{CGI}->param($options{CGIKEY}));
	}

	# Add To DB
	#
	if (($forceAdd) || ($options{CGI}->param($options{CGIKEY}) eq '')) {		
		INFLD: foreach (@inflds) { 
			$data = $options{CGI}->param($options{hrCGIMAP}->{$_});

			# Timestamp
			#
			if ($_ eq $options{DBSTAMP}) {
				$data = 'now()';			

			# MD5 Encryption
			#
			} elsif ($_ eq $options{MD5}) {
				$data = qq[md5('$data')];

			# NULL Data
			#
			} else {
				if   ($data eq '') 	{ $data = 'NULL'; }
				else { $data	= $self->Quote($data);	}
			}

			push(@values, $data); 
		}

		$cmdstr = qq[INSERT INTO $options{TABLE} (] . join(',',@inflds) . qq[) VALUES (] . join(',',@values) . qq[)];
	
	# Update Existing Type
	#
	} else {
		foreach (@inflds) { 
			$data = $options{CGI}->param($options{hrCGIMAP}->{$_});

			DATAMOD: {
				# Timestamper
				#
				if (!$options{DONTSTAMP} && $options{DBSTAMP} && ($_ eq $options{DBSTAMP})) 	
												{ $data = 'now()';					last DATAMOD; }

				# MD5 Encryption
				#
				if ($_ eq $options{MD5}) { $data = qq[md5('$data')];		last DATAMOD; }

				# NULL Data
				#
				if ($data eq '')			{ $data = 'NULL';						last DATAMOD; }
				else							{ $data	= $self->Quote($data);	last DATAMOD; }
			}

			push(@values, qq[ $_ = $data]);	
		}
		$cmdstr = qq[UPDATE $options{TABLE} SET	] . join(',',@values) . qq[ WHERE $options{DBKEY} = ] . $self->Quote($options{CGI}->param($options{CGIKEY}));
	}

	# Need To Get un-interupted Inserted Key
	# Turn off autocommit for transation based processing
	#
	$DBH->{AutoCommit} = 0 if (($options{RTNSEQ} ne '') && ($cmdstr =~ /^INSERT/o));

	# Execute The Command
	#
	$self->data(INFOMSG, ($options{VERBOSE} ? $cmdstr : substr($cmdstr,0,8)) );
	my $rv = $self->DoLE($cmdstr);
	
	# Execute OK, RTNSEQ Set - Return sequence #
	#
	if ($rv && ($options{RTNSEQ} ne '')) {
		if ($cmdstr =~ /^INSERT/o) {
			$rv = $self->dbh()->last_insert_id(undef,undef,$options{TABLE},undef);
		} else {
			$rv = $options{CGI}->param($options{CGIKEY});
		}
	}

	# Need To Get un-interupted Inserted Key
	# Commit & reset autocommit
	#
	if (($options{RTNSEQ} ne '') && ($cmdstr =~ /^INSERT/o)) {
			$self->dbh()->commit;
			$DBH->{AutoCommit} = 1;
	}
	return $rv;
}



#--------------------------------------------------------------------

=head2 DoLE()

 Do DBH Command and log any errors to the log file.
	[0] = SQL command
	[1] = Die on error
	[2] = return error on 0 records affected
	[3] = quiet mode (don't log via carp)

 Set the object 'errortype' data element to 'simple' for short error messages.
 i.e.
 $self->data('errortype') = 'simple';

=over

=item Returns

 1 for success
 0 for failure, get message with lasterror

=back

=cut
#----------------------------
sub DoLE {
	my $self			= shift;
	my $cmdstr 		= shift;
	my $dienow		= shift;
	my $zeroerror	= shift;
	my $quiet		= shift;
	my $err			= '';
	my $retval 		= 1;

	$self->SetDH() if (!$self->dbh());


	if ($self->dbh())		{	
		$retval = $self->dbh()->do($cmdstr);
		$retval = 0 if ($zeroerror && ($rv eq cPGNoRecs));
	 	if (!$retval) { 
			$err = (($self->data('errortype') ne 'simple') ? $cmdstr . "\n\t" : '') . $DBI::errstr; 
		}
	} else 					{	
		$err 		= 'Could not obtain data handle'; 
		$retval 	= 0;
	}

	if ( !$retval ) {	
		$self->data(ERRMSG,$err);
		if 	($dienow) 	{ croak($err);	}
		elsif	(!$quiet)	{ carp($err);	}
	} else {
		$self->data(ERRMSG,'');
	}

	return $retval;
}


#--------------------------------------------------------------------

=head2 Field()

 Retreive a field from the specified table.

=over

=item  Parameters (required)

 DATA     => Which data item to return, must be of form "table!field"

 KEY      => The table key to lookup in the database
               Used to determine if our current record is still valid.
               Also used as default for WHERE, key value is searched for 
               in the PGHkeyfld that has been set for the Postgres::Handler object.

=item Parameters (optional)

 WHERE	 => Use this where clause to select the record instead of the key

 FORCE	 => Force Reload

=item Returns

 The value of the field.

 Returns 0 and lasterror() is set to a value if an error occurs
               lasterror() is blank if there was no error

=item Example

 my $objPGDATA = new Postgres::Handler::HTML ('mytable!PGHkeyfld' => 'id');
 my $lookupID = '01123';
 my $data = $objPGDATA->Field(DATA=>'mytable!prod_title', KEY=>$lookupID);

 my $lookupSKU = 'SKU-MYITEM-LG';
 my $data = $objPGDATA->Field(DATA=>'mytable!prod_title', WHERE=>"sku=$lookupSKU");

=back

=cut
#----------------------------------------------------------
sub Field {
	my $self 	= shift;
	my %options	= @_;
	my ($table, $field) = split(/\!/,$options{DATA});
	my $keyfld;
	my $retval;
	my $nokey;

	$options{DATA} ||= '';
	$options{KEY}  ||= '';
	$options{FORCE}||= 0;
	$options{WHERE}||= '';

	# Table And Field Set
	#
	if ($table && $field) {

		# Data Not Set 
		# Or set with outdated key
		# Reload
		#
		if (!$self->data($options{DATA}) || ($options{KEY} ne $self->data("$table!key")) || $options{FORCE}) {

			# Key & Where Not Set - set value to blank
			#
			if (($options{KEY} eq '') and ($options{WHERE} eq '')) { 
				$self->data($options{DATA}, '');
				$nokey=1;

			# Key or Where Set - Get Value From DB
			#
			} else {
	
				# Grab the record & return the specified field
				#		
				if (($options{KEY} && ($options{KEY} ne ($self->data("$table!key") || ''))) || ($options{WHERE} ne '')) {

					my $where = (($options{WHERE} ne '') ? qq[WHERE $options{WHERE}] : 'WHERE ' . $self->data("$table!PGHkeyfld") . qq[ = $options{KEY}]);
					$retval = $self->PrepLEX( -cmd => qq[SELECT * FROM $table $where], -name => "$table!PGHfield" );
					if ($retval) {
						$self->data(ERRMSG,'');
						$self->data("$table!PGHfhr", $self->GetRecord("$table!PGHfield"));
						if ($self->data("$table!PGHfhr")) {
							my $keyfld = uc($self->data("$table!PGHkeyfld"));
							$self->data("$table!key", $self->data("$table!PGHfhr")->{$keyfld});
						}
					}
				}		
			}		
		}

		# Load The Field
		#
		if (!$nokey) {
			my $data = ($self->data("$table!PGHfhr") ? $self->data("$table!PGHfhr")->{uc($field)} : '');
			$self->data($options{DATA}, $data);
		}
		$retval = $self->data($options{DATA});

	} else {
		carp("Table and field must be passed to Postgres::Handler->Field() got $options{DATA} = '$table' '$field'");
	}

	return $retval;
}


#--------------------------------------------------------------------

=head2 GetRecord()

 Retrieves the record in a hash reference with uppercase field names.

 rtype not set or set to 'HASHREF',
 Calls fetchrow_hashref('NAME_uc') from the specified SQL statement.

 rtype not set or set to 'ARRAY',
 Calls fetchrow_array() from the specified SQL statement.

 rtype not set or set to 'ITEM',
 Calls fetchrow() from the specified SQL statement.


=over

=item  Parameters

 [0] or -name     select from the named statement handle,
                  if not set defaults to the last active statement handle

 [1] or -rtype    'HASHREF' (default) or 'ARRAY' or 'ITEM' - type of structure to return data in

 [2] or -finish   set to '1' to close the named statement handle after returning the data

=item Returns

 the hashref or array or scaler on success
 0 for failure, get message with lasterror

=back

=cut
#----------------------------
sub GetRecord {
	my ($self, @p)	= @_;
	my ($name,$rtype, $finish) = rearrange([NAME,RTYPE,FINISH],@p);
	my $retval		= 1;

	$rtype 		||= 'HASHREF';

	my $sth = ($name ? $self->nsth($name) : $self->sth);

	if ($sth) {
		$self->data(ERRMSG,'');
		if ($rtype eq 'HASHREF') {	
			$retval  = $sth->fetchrow_hashref('NAME_uc'); 
			return $retval if (!$DBI::errstr);
		} elsif ($rtype eq 'ARRAY'  ) { 
			my @retarry = $sth->fetchrow_array(); 
			return @retarry if (!$DBI::errstr);
		} elsif ($rtype eq 'ITEM'  ) { 
			$retval = $sth->fetchrow(); 
			return $retval if (!$DBI::errstr);
		}
	
		# Error Handling
		#
		if ($DBI::errstr ne '') {	
			$self->data(ERRMSG, 'GetRecord() ' . $DBI::errstr);
			carp('GetRecord() ' . $DBI::errstr);	
		}

		# Close the statement if requested
		#
		$sth->finish if ($finish);

	} else {
		$self->data(ERRMSG,'GetRecord() Statement handle not active.');
	}

	return undef;
}

#--------------------------------------------------------------------

=head2 lasterror()

 Retrieve the latest error produced by a Postgres::Handler object.

=over

=item Returns

 The error message

=back

=cut
#----------------------------
sub lasterror {	return shift->data(ERRMSG);	}

#--------------------------------------------------------------------

=head2 lastinfo()

 Retrieve the latest info message produced by a Postgres::Handler object.

=over

=item  Returns

 The info message

=back

=cut
#----------------------------
sub lastinfo {	return shift->data(INFOMSG);	}

#--------------------------------------------------------------------

=head2 nsth()

 Retrieve a named statement handle

=over

=item  Returns

 The handle, as requested.

=back

=cut
#----------------------------
sub nsth {	
	my ($self,$name) = @_;
	return $self->data("$name!sth");	
}



#--------------------------------------------------------------------

=head2 PrepLE()

 Prepare an SQL statement and returns the statement handle, log errors if any.

=over

=item Parameters (positional or named)

	[0] or -cmd 	- required -statement
	[1] or -exec	- execute flag (PREPLE) or die flag (PREPLEX)
	[2] or -die		- die flag     (PREPLE) or null     (PREPLEX)
	[3] or -param	- single parameter passed to execute 
	[4] or -name	- store the statement handle under this name

=item Returns

 1 for success

=back

=cut
#----------------------------
sub PrepLE () {
	my ($self,@p)	= @_;
	my ($cmdstr, $execit, $dienow, $param, $name) = rearrange([CMD,EXEC,DIE,PARAM,NAME],@p);

	my $err 		= '';	
	my $retval 	= 1;
	my $theSTH	= 0;
		$param ||= '';

	# Prepare/Execute Data Handle
	#
	if (!$self->dbh()) 	{ 	$self->SetDH(); }

	# Datahandle Valid
	#
	if ($self->dbh()) {
		$theSTH		= $self->dbh()->prepare($cmdstr) or $err = "$cmdstr\n\t".$DBI::errstr;
		if ($execit) { 
			if (($param ne '') && ($cmdstr =~ /\?/)) 	{ 	$theSTH->execute($param) or $err = "EXECUTE: $cmdstr\n\t".$DBI::errstr; }
			else													{ 	$theSTH->execute()       or $err = "EXECUTE: $cmdstr\n\t".$DBI::errstr; }
		}

	# Datahandle Non-existant
	#
	} else {
		$err = "Could not create data handle for '$cmdstr'";
	}

	if ($err) {
		$self->data(ERRMSG,$err);
		if ($dienow) 	{ croak($err); }
		else				{ carp($err);	$retval = 0; }
	}
	
	if ($name) {	$self->data("$name!sth",$theSTH); }		# -name set - store sth in named data element as well
	$self->sth($theSTH);												# Most recent statement handle goes in sth()

	return $retval;
}


#--------------------------------------------------------------------

=head2 PrepLEX()

 Same as PrepLE but also executes the SQL statement

=over

=item  Parameters (positional or named)

	[0] or -cmd 	- required -statement
	[1] or -die		- die flag     (PREPLE) or null     (PREPLEX)
	[2] or -param	- single parameter passed to execute 
	[3] or -name	- store the statement handle under this name

=item Returns

 1 for success

=back

=cut
#----------------------------
sub PrepLEX() { 
	my ($self,@p)	= @_;
	my ($cmdstr, $dienow, $param, $name) = rearrange([CMD,DIE,PARAM,NAME],@p);

	return $self->PrepLE($cmdstr,1,$dienow,$param,$name);
}

#--------------------------------------------------------------------

=head2 Quote()

 Quote a parameter for SQL processing via
 the DBI::quote() function

 Sets the data handle if necessary.

=cut
#----------------------------
sub Quote() {
	my $self = shift;
	if (!$self->dbh()) 	{	$self->SetDH(); }
	return $self->dbh()->quote(shift);
}

#==============================================================================

=head1 SEMI-PUBLIC METHODS

 Using these methods without understanding the implications of playing with their
 values can wreak havoc on the code.  Use with caution...

=cut
#==============================================================================

#--------------------------------------------------------------------

=head2 SetDH()

 Internal function to set data handles
 Returns Data Handle

 If you don't want the postgres username and password
 littering your perl code, create a subclass that
 overrides SetDH with DB specific connection info.

=cut
#----------------------------
sub SetDH() {
	my $self = shift;
	my $DBH = $self->dbh();

	if (!$DBH) {
		$DBH = DBI->connect(
							'dbi:Pg:dbname=' . $self->dbname(), 
							$self->dbuser(),
							$self->dbpass()
							) or croak($DBI::errstr); 	
		$DBH->{AutoCommit} = 1;
		$DBH->{ChopBlanks} = 1;	
		$self->dbh($DBH);
	}

}

#--------------------------------------------------------------------

=head2 SetMethodParms()

 Allows for either ordered or positional parameters in
 a method call AND allows the method to be called as EITHER
 an instantiated object OR as an direct class call.

=over

=item  Parameters

 [0] - self, the instantiated object
 [1] - the class we are looking to instantiate if necessary
 [2] - reference to hash that will get our named parameters
 [3] - an array of the names of named parameters 
       IN THE ORDER that the positional parameters are expected to appear
 [4] - extra parameters, positional or otherwise

=item Action

 Populates the hash refered to in the first param with keys & values

=item Returns

 An object of type class, newly instantiated if necessary.

=item Example

 sub MyMethod() {
 	my $self = shift;
	my %options;
		$self = SetMethodParms($self,'MYCLASS::SUBCLASS', \%options, [PARM1,PARM2,PARM3], @_ );
	print $options{PARM1} if ($options{PARM2} ne '');
	print $options{PARM3};
 }



=back

=cut
#----------------------------
sub SetMethodParms(@) {
	my ($self, $class, $hr, $order, @p) = @_;

	my $sclass	= ref($self) || $self;		# Allows either an object or class name to invoke
	if ($sclass ne $class) { 
		unshift @p, $self;
	}

	my $keynum = 0;
	foreach (rearrange($order,@p)) {		
		$hr->{@{$order}[$keynum]} = $_;
		++$keynum;
	}	

	return eval "new $class";
}

#--------------------------------------------------------------------

=head2 CGIMap()

 Prepare a hash reference for mapping CGI parms to DB fields
 typically used with AddUpdate() from Postgres::Handler.

=over

=item Parameters

 hrCGIMAP 	- reference to hash that contains the map
 CGI 			- the CGI object
 CGISTART 	- map all fields starting with this text
 CGIKEY 		- the cgi key field
 BOOLEANS 	- address to list of boolean fields

=item Example

 @boolist = qw(form_field1 form_field2);
 $item->CGIMap(CGI => $objCGI, hrCGIMAP=>\%cgimap, CGISTART=>'cont_', CGIKEY=>'cont_id', BOOLEANS=>\@boolist);

=back

=cut
#----------------------------
sub CGIMap(@) {
	my ($self, %options) = @_;

	# Booleans (not passed if not checked, force them to 0 here)
	#
	foreach (@{$options{BOOLEANS}}) { 
		$options{hrCGIMAP}->{$_} = $options{CGI}->param($_); 
		$options{CGI}->param($_ , $options{CGI}->param($_) || 'f');
	}

	foreach ($options{CGI}->param()) {	
		if ($_ =~ /^$options{CGISTART}/) { 
			if (($_ ne $options{CGIKEY}) || ($options{CGI}->param($options{CGIKEY}) ne '')) {
				$options{hrCGIMAP}->{$_} = $_; 
			}
		} 
	}
}


1;
__END__

#==============================================================================
#
# Closing Documentation
#
#==============================================================================

=head1 NOTES

 Some methods allow for parameters to be passed in via both positional and named formats.
 If you decide to use named parameters with these "bi-modal" methods you must prefix the
 parameter with a hyphen.

 # Positional Example
 #
 use Postgres::Handler;
 my $DB = Postgres::Handler->new(dbname=>'products',dbuser=>'postgres',dbpass=>'pgpassword');
 $DB->PrepLEX('SELECT * FROM products');

 # Named Example
 #
 use Postgres::Handler;
 my $DB = Postgres::Handler->new(dbname=>'products',dbuser=>'postgres',dbpass=>'pgpassword');
 $DB->PrepLEX(	-cmd	=>	'SELECT * FROM products'	);

 
=head1 EXAMPLES

 # Instantiate Object
 #
 use Postgres::Handler;
 my $DB = Postgres::Handler->new(dbname=>'products',dbuser=>'postgres',dbpass=>'pgpassword');

 # Retrieve Data & List Records
 #
 $DB->PrepLEX('SELECT * FROM products');
 while ($item=$DB->GetRecord()) {
 	print $item->{PROD_ID}\t$item->{PROD_TITLE}\t$item->{PROD_QTY}\n";
 }

 # Add / Update Record based on CGI Form
 # assuming objCGI is an instatiated CGI object
 # if the CGI param 'prod_id' is set we update
 # if it is not set we add
 #
 my %cgimap;
 foreach ('prod_id','prod_title','prod_qty') { $cgimap{$_} = $_; }
 $DB->AddUpdate( CGI=>$objCGI     , CGIKEY=>'prod_id', 
                 TABLE=>'products', DBKEY=>'prod_id',
                 hrCGIMAP=>\%cgimap
               );

=head1 AUTHOR

 Lance Cleveland, Advanced Internet Technology Consultant
 Contact info@charlestonsw.com for more info.

=head1 ABOUT CSA

 Charleston Software Associates (CSA) is and advanced internet technology
 consulting firm based in Charleston South Carolina.   We provide custom
 software, database, and consulting services for small to mid-sized
 businesses.

 For more information, or to schedule a consult, visit our website at
 www.CharlestonSW.com

=head1 CONTRIBUTIONS

 Like the script and want to contribute?  
 You can send payments via credit card or bank transfer using
 PayPal and sending money to our info@charlestonsw.com PayPal address.

=head1 COPYRIGHT

 (c) 2005, Charleston Software Associates
 This script is covered by the GNU GENERAL PUBLIC LICENSE.
 View the license at http://www.charlestonsw.com/community/gpl.txt
 or at http://www.gnu.org/copyleft/gpl.html

=head1 REVISION HISTORY

 v2.2 - Apr 2006
      Fixed problem with SetDH database handle management


 v2.1 - Mar 2006
      Added RTNSEQ feature to AddUpdate so we can get back the key of a newly added record


 v2.0 - Feb 2006
      Moved CGI::Carp outside of the package to prevent perl -w warnings

 v1.9 - Feb 2006
      Update Field() to prevent SIGV error when WHERE clause causes error on statement
		Field() now returns 0 + lasterror() set to value if failed execute
		            returns fldval + lasterror() is blank if execution OK

 v1.8 - Jan 2006
      Bug fix on PrepLE and PrepLEX for perl -w compatability
		Added DoLE param to return error status (0) if the command affects 0 records '0E0'
		Added DoLE param to keep quiet on errors (do not log to syslog via carp)
		Documentation updates

 v1.5 - Nov 2005
 		Fixed @BOOLEANS on AddUpdate to force 'f' setting instead of NULL if blank or 0

 v1.5 - Oct 2005
 		Fixed return value error on AddUpdate()

 v1.4 - Aug 2005
      Minor patches

 v1.3 - Jul 17 2005
      Minor patches
		Now requires DBD::Pg version 1.43 or greater

 v1.2 - Jun 10 2005
      GetRecord() mods, added 'ITEM'
		test file fix in distribution
		created yml file for added requisites on CPAN


 v1.1 - Jun 9 2005
      pod updates
		Field() cache bug fix
		GetRecord() expanded, added finish option
		Moved from root "PGHandler" namespace to better-suited "Postgres::Handler"

 v0.9 - May 2 2005
      pod updates
		AddUpdate() updated, CGIKEY optional - defaults to DBKEY
		AddUpdate() updated, BOOLEANS feature added
		GetRecord() updated, added check for sth active before executing
		Field()	fixed hr cache bug and data bug and trap non-set hr issue

 v0.8 - Apr 26 2005
      Fixed GetRecord() (again) - needed to check $DBI::errstr not $err

 v0.7 - Apr 25 2005
      Added error check on ->Field to ensure hashref returned from getrecord
      Added CGIMAP method
      Invoke CGIMAP from within AddUpdate if missing map
      Fixed GetRecord Return system

 v0.5 - Apr/2005
      Added DBI error trap on DoLE function
      Added named statement handles for multiple/nested PrepLE(X) capability
      Added VERBOSE mode to AddUpdate
      Added NAME to retrieved named statements via GetRecord
      Updated FIELD to use named statement handles 

 v0.4 - Apr/2005
 		Fixed some stuff

 v0.3 - Apr/2005
      Added REQUIRED optional parameter to AddUpdate
      Improved documentation
      Quoted DBKEY on add/update to handle non-numeric keys

 v0.2 - Mar/2005 - 
      Added error messages to object
      Fixed issues with Class:Struct and the object properties
      Updated AddUpdate to use named parameters (hash) for clarity

 v0.1 - Dec/2004
      Initial private release

=cut
