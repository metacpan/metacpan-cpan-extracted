=head1 NAME

Postgres::Handler::HTML - HTML Component for PostgreSQL data.

=head1 DESCRIPTION

Accessors for PostgreSQL data.  Simplifies data access through a series of standard class methods.

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

=head1 EXAMPLE

 #!/usr/bin/perl
 #
 # Connect to the postgres XYZ database owned by user1/mypass
 # Set the primary key field for the abc table to the field named pkid
 # Print the contents of the fldone field in the abc table where the pkid=123
 #
 use Postgres::Handler::HTML;
 our $STORE = Postgres::Handler::HTML->new(dbname=>'xyz', dbuser=>'user1', dbpass=>'mypass');
 $STORE->data('abc!PGHkeyfld'=>'pkid');
 $STORE->ShowThe('abc!fldone',123);
 exit(1);

=head1 REQUIRES

	Subclass of Postgres::Handler

	Postgres::Handler
 		 +- CGI::Carp
		 +- CGI::Util
		 +- Class::Struct
		 +- DBI

=cut
#==============================================================================


#==============================================================================
#
# Package Preparation
# Sets up global variables and invokes required libraries.
#
#==============================================================================

package Postgres::Handler::HTML;
use base ("Postgres::Handler");


#require Postgres::Handler;
#@ISA=qw(Postgres::Handler);
$VERSION = 1.0;

#==============================================================================

=head1 METHODS
 
=cut
#==============================================================================

#--------------------------------------------------------------------

=head2 CheckBox()

 Produce an HTML Checkbox for the specified boolean field

 Parameters
	TABLE			=>	name of table to get data from
	CBNAME		=>	name to put on the checkbox, defaults to VALUE
	VALUE			=> field that contains the t/f use to set the checkmark
	LABEL			=> what to put next to the checkbox as a label (defaults to field name)
	KEY			=>	value of the key used to lookup the data in the database
	CHECKED		=> set to '1' to check by default if KEY not found
	SCRIPT		=> script tags (or class tags) to add to checkbox HTML
	NOLABEL		=> set to '1' to skip printing of label

 Action
 prints out the HTML Checkbox, checked if field is true

 Return
 0 = failure, sets error message, get with lasterror()
 1 = success

=cut
#----------------------------
sub CheckBox() {
	my $self = shift;
	my %options = @_;

	# These options must be defined
	#
	if (
			! exists $options{TABLE} ||
			! exists $options{VALUE} ||
			! exists $options{KEY}
		) { 
		$self->data(ERRMSG,qq[Postgres::Handler::HTML::Checkbox TABLE '$options{TABLE}' VALUE '$options{VALUE}' and KEY '$options{KEY}' must be defined.]);
		return; 
	}

	# Set defaults if not present
	#
	$options{CBNAME} 	||= $options{VALUE};
	$options{LABEL}	||= $options{VALUE} if (!$options{NOLABEL});

	# Get Data If Not Set
	#
	my $val = $self->Field(DATA=>"$options{TABLE}!$options{VALUE}", KEY=>$options{KEY});
	$val = 1 if (!$val && $options{CHECKED} && !$options{KEY});

	# Script/Class Optional HTML tag elements
	#
	my $tagmod = $options{SCRIPT};

	my $selector = ($val ? 'checked' : '');
   print qq[<input type="checkbox" value="t" name="$options{CBNAME}" $selector $tagmod> $options{LABEL}];
	return 1;
}



#--------------------------------------------------------------------

=head2 Pulldown()

 Produce an HTML pulldown menu for the specified table/fields

 Parameters
	TABLE			=>	 name of table to get data from
	PDNAME		=>	 name to put on the pulldown, defaults to VALUE
	VALUE			=>  which field we stick into the option values
	SHOW			=>  which field we spit out on the selection menu, defaults to VALUE
	SELECT		=>  mark the one with this VALUE as selected
	ALLOWBLANK 	=> set to 1 to allow blank selection (noted as ---)
	ORDERBY		=> special ordering, defaults to SHOW field
	WHERE			=> filtering selection clause (without WHERE, i.e. pdclass='class1')
	SCRIPT		=> event script, such as 'onChange="DoSumthin();"'
	PREADD		=> address to hashref of Add-ons for begining of list
	                  key     = the value
							content = show
	GROUP			=> group the data

 Action
 prints out the HTML pulldown

=cut
#----------------------------
sub Pulldown() {
	my $self = shift;
	my %options = @_;

	# These options must be defined
	#
	if (
			! exists $options{TABLE} ||
			! exists $options{VALUE}
		) { return; }


	# Set defaults if not present
	#
	$options{PDNAME} 	||= $options{VALUE};
	$options{SHOW}		||= $options{VALUE};
	$options{ORDERBY} ||= $options{SHOW};
	my $where			= ($options{WHERE} ? "WHERE $options{WHERE}" : '');
	my $group			= ($options{GROUP} ? "GROUP BY $options{GROUP}" : '');

	print qq[<select size="1" name="$options{PDNAME}" $options{SCRIPT}>];
	print qq[<option value="">---</option>] if ($options{ALLOWBLANK});

	my $selector;
	if ( $self->PrepLEX(qq[SELECT $options{VALUE}, $options{SHOW} FROM $options{TABLE} $where $group ORDER BY $options{ORDERBY}]) ) {
		while (my ($value,$show) = $self->GetRecord(-rtype=>'ARRAY')) {
			$selector = (($value eq $options{SELECT}) ? 'selected' : '');
			print qq[<option value="$value" $selector>$show</option>];
		}
	} else {
		print $self->lasterror();
	}
	print qq[</select>];
}

#--------------------------------------------------------------------

=head2 RadioButtons()

 Produce an HTML Radio Button menu for the specified table/fields

 Parameters
	TABLE			=>	 name of table to get data from
	RBNAME		=>	 name to put on the pulldown, defaults to VALUE
	VALUE			=>  which field we stick into the option values
	SHOW			=>  which field we spit out on the menu, defaults to VALUE
	SELECT		=>  mark the one with this VALUE as selected
	ORDERBY		=> special ordering, defaults to SHOW field
	WHERE			=> filtering selection clause (without WHERE, i.e. rbclass='class1')

 Action
 prints out the HTML Radio Buttons

=cut
#----------------------------
sub RadioButtons() {
	my $self = shift;
	my %options = @_;

	# These options must be defined
	#
	if (
			! exists $options{TABLE} ||
			! exists $options{VALUE}
		) { return; }

	# Set defaults if not present
	#
	$options{RBNAME} 	||= $options{VALUE};
	$options{SHOW}		||= $options{VALUE};
	$options{ORDERBY} ||= $options{SHOW};
	my $where			= ($options{WHERE} ? "WHERE $options{WHERE}" : '');

	my $selector;
	$self->PrepLEX(qq[SELECT $options{VALUE}, $options{SHOW} FROM $options{TABLE} $where ORDER BY $options{ORDERBY}]);
	while (my ($value,$show) = $self->GetRecord(-rtype=>'ARRAY')) {
		$selector = (($value eq $options{SELECT}) ? 'checked' : '');
      print qq[<input type="radio" value="$value" name="$options{RBNAME}" $selector>$show];
	}
}

#--------------------------------------------------------------------

=head2 ShowHeader()

 Display header for retrieved records in an HTML <table> row

 One of these 2 id required
 DATAREF		=> reference to hash storing record 
 DISPCOLS	=> reference to array of columns to show, defaults to hash key names

 Optional parameters
 FULLNAME	=> set to 1 to show full field name, otherwise we trunc up to first _
 SORT			=> set to 1 to sort keys

=cut
#----------------------------
sub ShowHeader(@) {
	my $self			= shift;
	my %options		= @_;
	my $dRef	= $options{DATAREF};
	my $key;
	my @keys;
	my $kref;
	my $disp;
	my $cols = 0;

	# Header Row
	#
	if ($options{DISPCOLS}) {
		$kref = $options{DISPCOLS};
	} else {
		@keys = $options{SORT} ? sort keys %{$dRef} : keys %{$dRef};
		$kref = \@keys;
	}

	print qq[<tr class="labelcolumn">];
	foreach $key (@{$kref}) {			
		$disp = $key;

		# Full Name or Trunc to first _?
		#
		if (!$options{FULLNAME}) {	$disp =~ s/(.*?)_//; }

		print qq[\n\t<td>$disp</td>];
		++$cols;
	}
	print qq[</tr>];
	return $cols;
}

#--------------------------------------------------------------------

=head2 ShowRecord()

 Display retrieved records in an HTML <table> row

 Parameters
 DATAREF		=> reference to hash storing record (required)

 DATAMODREF	=> reference to hash storing data modifiers
 						The field specified by the hash key is replaced
						with the data specified in the value.
						Use $Record{???} to place the record field ??? within 
						the substitution string.						

						If the modifier starts with ~eval(<blah>) then the modifier
						evaluates <blah> and returns it's result.  For example:
						$datmodref{THISFIELD} = '~eval(substr($Record{FIELD},0,10))';
						would display the first 10 characters of the field.

 DISPLAYREF	=> reference to hash storing special cell formats for
 						each data element. Key = element, value = <td> modifier

 DISPCOLS	=> reference to array of columns to show, defaults to hash key names

 TRIMDATES	=> set to 'minute' or 'day' to trim date fields
 						date fields are any ending in 'LASTUPDATE' 
 WRAP			=> set to 1 to allow data wrapping
 SORT			=> set to 1 to sort keys
 ASFORM		=> set to 1 to show data as input form fields
 NOTABLE		=> set to 1 to drop all table html tags
 OUTPUT		=> output file handle
 ROWMOD		=> modifier to <tr> row definition
 CELLMOD		=> modifier to each <td> Cell definition

=cut
#----------------------------
sub ShowRecord(@) {
	my $self			= shift;
	my %options		= @_;
	my $dRef			= $options{DATAREF};
	my $dModRef		= $options{DATAMODREF};
	my $DispRef		= $options{DISPLAYREF};
	my $wrap			= ($options{WRAP} ? '' : 'nowrap');
	my $key;
	my @keys;
	my $kref;
	my $data;
	my $temp;
	my $dval;
	my $fldname;
	$options{OUTPUT} = $options{OUTPUT} || STDOUT;

	# Display Order
	#
	if ($options{DISPCOLS}) {
		$kref = $options{DISPCOLS};
	} else {
		@keys = $options{SORT} ? sort keys %{$dRef} : keys %{$dRef};
		$kref = \@keys;
	}

	# Data Row
	#
	if (!$options{NOTABLE}) { print {$options{OUTPUT}} qq[<tr $options{ROWMOD}>]; }
	foreach $key (@{$kref}) {			
		$data = $dRef->{$key};

		# Date field & Trim Set
		#
		if ($options{TRIMDATES} && ($key =~ /LASTUPDATE$/)) {				
			$data = (
						$options{TRIMDATES} =~ /^minute$/i 	? substr($dRef->{$key},0,16) :  
						$options{TRIMDATES} =~ /^day$/i		? substr($dRef->{$key},0,10) :  
						$dRef->{$key}
						);
		}

		# Setup Input Modifiers For "ASFORM"
		#
		if ($options{ASFORM}) { $dModRef->{$key} = qq[<input type="text" name="$key" value="\$Record{$key}">];	}

		# Modifier?
		#
		if ( $dModRef->{$key} ) {
			$data = $dModRef->{$key};

			# Evaluate
			#
			if ($data =~ /^~eval\(.*\)/o) {
				$data =~ s/^~eval\((.*)\)/$1/;

				# Replace RECORD{} with field info
				#
				while ($data =~ /\$Record{(.*?)}/) {
					$fldname = $1;
					$dval = $dRef->{$fldname};
					$dval =~ s/'/\\'/gs;
					$data =~ s/\$Record{$fldname}/'$dval'/gs;
				}

				# Evaluate the expression
				#
				$data = eval $data;

				# Convert ' in data back to '
				#
				$data =~ s/\\'/'/gs;

			# Plain Old Data Substitution
			#
			} else {
				$data =~ s/\$Record{(.*?)}/$dRef->{$1}/gs;
			}
		}

		# Show The Formatted Data
		#
		if (!$options{NOTABLE}) { print {$options{OUTPUT}} qq[\n\t<td $options{CELLMOD} $wrap $DispRef->{$key}>];	}
		print {$options{OUTPUT}} $data;
		if (!$options{NOTABLE}) { print {$options{OUTPUT}} qq[</td>];	}
	}
	if (!$options{NOTABLE}) { print {$options{OUTPUT}} qq[</tr>]; }
}


#--------------------------------------------------------------------

=head2 ValOrZero()

 Set these CGI parameters to 0 if not defined.  Used for checkbox
 form variables when we want to ensure the value is set to 0 (false)
 if they are not set via the CGI interface.

 HTML checkboxes are NOT passed to the CGI module if they are not
 checked, so this function helps us out by forcing the assumption
 that the CGI parameters passed here should be 0 if the are not
 received.

 Parameters
 [0] - the CGI variable
 [1] - an array of CGI parameters to be set

 Action
 Sets the named CGI parameters to 0 if they are not set, otherwise
 leaves the original value intact.

=cut
sub ValOrZero(@) {
	my $self  = shift;
	my $objCGI= shift;
	my @parms = @_;

	foreach (@parms) { $objCGI->param($_ , $objCGI->param($_) || 0);	}
}

#--------------------------------------------------------------------

=head2 ShowThe

 Load the DB record and spit out the value of the specified field

=over

=item Parameters 

 Parameters are positional.

 Required
 <0> field name to be displayed in "table!field" format

 <1> key, lookup the record based on the Postgres::Handler key
          that has been set for this field.   Reference the
			 Postgres::Handler->Field method for more info.

 Optional
 [2] trim to this many characters

=back

=cut
sub ShowThe(@) {
	my $self 	= shift;
	my $retval = $self->Field(DATA=>$_[0], KEY=>$_[1]) || '';
	$retval = substr($retval,0,$_[2]) if ($_[2] && ($retval ne ''));
	print $retval;
}




1;
__END__

#==============================================================================
#
# Closing Documentation
#
#==============================================================================

=head1 AUTHOR

 Cyber Sprocket Labs, Advanced Internet Technology Consultants
 Contact info@cybersprocket.com for more info.

=head1 ABOUT CSL

 Cyber Sprocket Labs (CSL) is and advanced internet technology
 consulting firm based in Charleston South Carolina.   We provide custom
 software, database, and consulting services for small to mid-sized
 businesses.

 For more information, or to schedule a consult, visit our website at
 www.cybersprocket.com

=head1 CONTRIBUTIONS

 Like the script and want to contribute?  
 You can send payments via credit card or bank transfer using
 PayPal and sending money to our paypal@cybersprocket.com PayPal address.

=head1 COPYRIGHT

 (c) 2008, Cyber Sprocket Labs
 This script is covered by the GNU GENERAL PUBLIC LICENSE.
 View the license at http://www.gnu.org/copyleft/gpl.html


=head1 REVISION HISTORY

 v1.0 - May 2008
      Attach to Postgres::Handler via use base() construct
      Cleaned up perldocs
      Build new distro so we can do routine updates

 v0.9 - January 2006
      GROUP option on Pulldown()
		Added some docs, minor code cleanup

 v0.8 - September 2005
 		PREADD option on Pulldown()

 v0.7 - August 2005
      minor updates

 v0.6 - Jun 13 2005
      added script option to checkbox type
		added no label option to checkbox type

 v0.5 - Jun 09 2005
      moved under Postgres::Handler:: namespace
		initial CPAN release

 v0.4 - Apr 28 2005
		pod updates
		Updated CheckBox() w/ default 'checked' option
		Added ShowThe() method

 v0.1 - Dec/2004
      Initial private release

=cut
