#!/usr/local/bin/perl

##########################################################################
# CreateDef: Create a table definition file for use with the MsqlCGI
# package.
#
# NOTE: PLEASE ONLY EDIT THE "USER EDIT" SECTION.  Everything else should
#       be either dynamic or configurable in the "MsqlCGI.conf" file.
#
# This file creates a table definition file for use with MsqlCGI.  The
# Table Definition file is documented in the web page:
# http://petrified.cic.net/MsqlCGI/TableDefinition.html
#
# This program should be run with no arguments for now.  It interactively
# asks you for information about the table you're creating the Table
# Definition file for.  
#
# This is part of the MsqlCGI package.
# Author: Alex Tang <altitude@cic.net>
# Copyright 1996 Alex Tang and CICNet, Inc.   All Rights Reserved.
##########################################################################

#########################################################################
# USER EDIT SECTION:
#########################################################################

	# The following variable is the name of the MsqlCGI.conf file.
	# Please edit it accordingly.  
$MSQLCGI_CONF = "/home/info/local/cgi-common/MsqlCGI/MsqlCGI.conf";


#########################################################################
# On with the show...
#
# OK, this script is REALLY FREGGIN CRUSTY.  I know that and I'm really
# sorry about it.  I just watned to whip something together to create a
# Table Definition file.  Hopefully this will be fixed soon.  If you need
# to go looking through this code, have a bottle of Pepto Bismol handy...
#
# The global variables are used throughout the whole program.  They are
# defined in the file MsqlCGI.conf.  You probably should edit the
# following line to include the FULL PATHNAME to the MsqlCGI.conf file.
#
# Edit those variables in that file.  We use the "require" statement to
# read in the variables.  We're using a full path name because we don't
# yet know where the MsqlCGI Directory is...
#########################################################################
require "$MSQLCGI_CONF";



$cgi = 0;
$version = "0.8";
unshift ( @INC, $msqlCGIDir );
use Msql;
#require "MsqlCGI.pm";

&Clear();
print <<EOF;

    Welcome to CreateDef.  This will create a table definition file for
    use with the MsqlCGI package.  
    
    Fow now, I'm going to assume that you already have created the
    database and table that you're going to work with, and that the table
    has a primary key.  If you haven't, you can not go on.

    If you have questions about this program, or the file that this
    program is going to create, please see the documentation at:

    	http://petrified.cic.net/MsqlCGI/TableDefinition.html

EOF

&GetReturn();

####################
# This really sucks to have to do all this checking.  But hey, i'm trying
# to make a robust application...well sorta.  Anyway.  Try to get the name
# of the output file.
####################
$outFile = &GetOutFileName();

print OUT <<EOF;
# $outFile
# This is the table definition file for use with the MsqlCGI package.
# For more information about MsqlCGI, see
# http://petrified.cic.net/MsqlCGI/
#
# Version $version.
EOF
  

	# Make sure that we flush the data that goes into this file as
	# soon as we write it.  It may be helpful later.

######################
# Now get the name of the host to connect to.
######################
( $host, $DBPort ) = GetDBHostName();
print "$host, $DBPort\n";

print OUT "DBHost = $host\n";
print OUT "DBPort = $DBPort\n" if ( $DBPort );


##################
# Now try to get the name of the Database
##################
$dbName = &GetDBName();
print OUT "DBName = $dbName\n";

##################
# Now try to get the Table.
##################
$fieldName = &GetTableName();
print OUT "TableName = $TableName\n";


( $sth = $dbh->Query ( "SELECT * from $TableName" ) ) || 
	&Error ( "Failed Query.  $Msql::db_errstr" );
$nRows = $sth->numrows;
$nFields = $sth->numfields;

	# Do a quick check to make sure that the table has a primary key.
$priKeyExists = 0;
for ( $i = 0; $i < $nFields; $i++ ) {
  if ( $sth->is_pri_key->[$i] ) {
    $priKeyExists = 1;
    last;
  }
}

if ( ! $priKeyExists ) {
  $msg = <<"  EOF";

    Sorry, It appears that this table doesn't have a Primary Key.  MsqlCGI
    will not work on tables that do not have a Primary Key.  

  EOF
  die ( $msg );
}
######################
# Get information about the table itself, allowModify, allowCreate, etc.
######################
&Clear();
print <<EOF;

      Now I'm going to ask you 4 questions regarding whether or not you
      want yourself (or others) to be able to perform the four basic
      functions: 
      	Create
	Search
      	Modify
	Delete 

EOF
&GetReturn();
$allowCreate = &GetAllow ( "create" );
$allowDisplay = &GetAllow ( "display" );
$allowModify = &GetAllow ( "modify" );
$allowDelete = &GetAllow ( "delete" );
$allowSearch = ( ( $allowDisplay eq "Yes" ) ||
                 ( $allowModify eq "Yes" ) || 
                 ( $allowDelete eq "Yes" ) ) ? "Yes" : "No";

print OUT <<EOF;
	# AllowSearch is dependent on AllowDisplay, AllowModify, and
	# AllowDelete.  If any of those three keys is "Yes", AllowSearch
	# MUST be "Yes".  In fact, the AllowSearch key may disappear
	# sometime soon.
AllowSearch = $allowSearch
AllowCreate = $allowCreate
AllowDisplay = $allowDisplay
AllowModify = $allowModify
AllowDelete = $allowDelete

EOF
&GetReturn();

######################
# Template file questions.
######################
&Clear();
print <<EOF;
    The next section is about HTML Template files.  >PLEASE< take a look
    at the web page on HTML Template files at

    	http://petrified.cic.net/MsqlCGI/Templates.html
    
    If this is your first time using MsqlCGI, you should probably choose
    the default "No Template" answer.  Once you've familiarized yourself
    with MsqlCGI a bit more, you can go back and write your own HTML
    Template files.

    If you're not sure what Template files are used where, please see the
    Data Flow page at 
    
    	http://petrified.cic.net/MsqlCGI/DataFlow.html

EOF
&GetReturn();
&Clear();

print <<EOF;

    The first thing I need to know is the default HTML Template directory.
    This directory will be prepended to the rest of the template file
    names IF the specified filename is not a Full pathname, or a "~" name.

    This directory MUST be either a full Uniix pathname or a "~"
    directory.

EOF
print "Default HTML Template Directory:\n";
$tmpl{'Z-TemplateDir'} = &GetInput ( "No Template" );

print <<EOF;

    Ok, the rest of the template questions may or may not be a full unix
    pathname or "~" filename.  If the filename IS NOT a full unix pathname
    or a "~" filename, the TemplateDir key will be prepended to filename.

EOF
print "\nOperations Menu Template: \n";
$tmpl{'a-OperationsMenuTemplate'} = &GetInput ( "No Template" );

print "\nRecord Search Template: \n";
$tmpl{'b-RecordSearchTemplate'} = &GetInput ( "No Template" );

print "\nPreliminary Results Template: \n";
$tmpl{'c-PreliminaryResultsTemplate'} = &GetInput ( "No Template" );

print "\nRecord Display Template: \n";
$tmpl{'d-RecordDisplayTemplate'} = &GetInput ( "No Template" );

print "\nRecord Modify Setup Template: \n";
$tmpl{'e-RecordModifySetupTemplate'} = &GetInput ( "No Template" );

print "\nRecord Modify Success Template: \n";
$tmpl{'f-RecordModifySuccessTemplate'} = &GetInput ( "No Template" );

print "\nRecord Create Setup Template: \n";
$tmpl{'g-RecordCreateSetupTemplate'} = &GetInput ( "No Template" );

print "\nRecord Create Success Template: \n";
$tmpl{'h-RecordCreateSuccessTemplate'} = &GetInput ( "No Template" );

print "\nRecord Delete Success Template: \n";
$tmpl{'i-RecordDeleteSuccessTemplate'} = &GetInput ( "No Template" );

print "\nError Template: \n";
$tmpl{'j-ErrorTemplate'} = &GetInput ( "No Template" );

print "\nHTML Footer Template: \n";
$tmpl{'k-HTMLFooter'} = &GetInput ( "No Template" );

foreach $key ( sort ( keys ( %tmpl ) ) ) {
  $tmplName = substr ( $key, 2 );
  if ( $tmpl{$key} eq "No Template" ) {
    print OUT "# $tmplName =\n";
  } else {
    print OUT "$tmplName = $tmpl{$key}\n";
  }
}




######################
# Now on to the good stuff....the field definitions. 
######################
&Clear();
  print <<EOF;

    Ok.  Now we need to get information about each of the individiual
    fields.  This may prove to be a long and tedious task, so please be
    patient.  

    For each field, I'm going to ask you a series of questions about that
    field. 

EOF
&GetReturn();

( $sth = $dbh->Query ( "SELECT * from $TableName" ) ) || 
	&Error ( "Failed Query.  $Msql::db_errstr" );
$nRows = $sth->numrows;
$nFields = $sth->numfields;


    
for ( $i = 0; $i < $nFields; $i++ ) {

  ( $fieldName, $fieldType, $notNull, $primaryKey, $tableLength ) =
  	&GetFieldInfo ( $i );

  $nCount = $i + 1;
  &Clear();
  print <<EOF;

This is the information I can retrieve about the Current Field.  Please
answer the following questions regarding this field:

Field Number:                $nCount
Field Name:                  $fieldName
Field Type:                  $fieldType
NotNull?                     $notNull
Primary Key?                 $primaryKey
Table Size:                  $tableLength

EOF

  print "Full Text Description of the field:\n";
  $desc = &GetInput ();

    print OUT <<EOF;

# This section is for the table element: $desc ($fieldName)
NewField
description = 		$desc
fieldName = 		$fieldName
fieldType = 		$fieldType
notNull = 		$notNull
primaryKey = 		$primaryKey
fieldSize = 		$tableLength
EOF

	######################
	# Get information about the field when Displaying a record.
	######################
  if ( $allowDisplay ) {
    print <<EOF;

      Should I display this field when DISPLAYING the whole entry to the
      user?

EOF
    $dispFieldWhenDisplay = &GetYN();
    print OUT "dispFieldWhenDisplay =\t$dispFieldWhenDisplay\n";
  }


	######################
	# Get information about the field when Creating a record.
	######################
  if ( $allowCreate ) {
    print <<EOF;

      Should I display this field when CREATING a record?

EOF
    $dispFieldWhenCreate = &GetYN();
    print OUT "dispFieldWhenCreate =\t$dispFieldWhenCreate\n";

    if ( $dispFieldWhenCreate eq "Yes" ) {
      print <<EOF;
      
      Should I allow modification of this field when CREATING a record?

EOF
      $modFieldWhenCreate = &GetYN();
      print OUT "modFieldWhenCreate =\t$modFieldWhenCreate\n";
    }
  }


	######################
	# Get information about the field when Modifying a record.
	######################
  if ( $allowModify ) {
    print <<EOF;

      Should I display this field when MODIFYING a record?

EOF
    $dispFieldWhenModify = &GetYN();
    print OUT "dispFieldWhenModify =\t$dispFieldWhenModify\n";

    if ( $dispFieldWhenModify eq "Yes" ) {
      print <<EOF;
      
      Should I allow modification of this field when MODIFYING a record?

EOF
      $modFieldWhenModify = &GetYN();
      print OUT "modFieldWhenModify =\t$modFieldWhenModify\n";
    }
  }

    
	######################
	# Get information about the field when Performing a Search
	######################
  print <<EOF;

      When performing a search, should this field be available as one of
      the search criteria?

EOF
  $searchable = &GetYN();
  print OUT "searchable =\t\t$searchable\n";

  print <<"  EOF";

      Should this field be one of the "Summary Fields" that appears on the
      Preliminary Results Page?  See the web page

http://petrified.cic.net/MsqlCGI/Templates.html#tokens-specific-prelimresults

      for more information about the Preliminary Results Page.
  EOF
  $summary = &GetYN();
  print OUT "summary =\t\t$summary\n";


	# We only need to find out the CGI information if we're going to
	# display the entry at some point.
  if ( ( $modFieldWhenCreate eq "Yes" ) || ( $modFieldWhenModify eq "Yes" ) ) {

    	# First find out what type of CGI field it is...
    $good = 0;
    $try = 0;
    while ( $good == 0 ) {
      if ( $try ) {
        print "I'm sorry.  You didn't make a valid selection.\n";
	print "Please try again.\n\n";
      }
      print <<EOF; 

What type of CGI form element is this?  Your choices are:
  text, textarea, password, radio, checkbox, select
EOF
    $cgiType = &GetInput ( );
    $try++;
    $good = 1 if ( $cgiType =~ /^(text|textarea|password|radio|checkbox|select)$/i );
    }
    print OUT "cgiType = 		$cgiType\n";

	# Depending on what type of cgi element it is, we need to get more
	# information...
    if ( $cgiType =~ /^(text|password)$/i ) {
      print <<EOF;

Text and Password elements have 2 extra fields:

  * Size:      The size of the text entry field
  * MaxLength: The maximum number of characters that the field can be.

EOF
      print "Size? \n";
      if ( $fieldType =~ /^char/i ) {
        $cgiSize = &GetInput ( "$tableLength" );
      } else {
        $cgiSize = &GetInput ();
      }

      print "MaxLength? \n";
      if ( $fieldType =~ /^char/i ) {
        $cgiMaxLength = &GetInput ( "$tableLength" );
      } else {
        $cgiMaxLength = &GetInput ();
      }

      print OUT "cgiSize = 		$cgiSize\n";
      print OUT "cgiMaxLength = 		$cgiMaxLength\n";

    } elsif ( $cgiType =~ /^textarea$/ ) {
      print <<EOF;

Textarea fields need row and column information.  Please enter the number
of rows and columns that should be displayed in the CGI form.

EOF
      print "Rows?\n";
      $cgiRows = &GetInput ( );
      print "Columns?\n";
      $cgiCols = &GetInput ();
      print OUT "cgiCols = 		$cgiCols\n";
      print OUT "cgiRows = 		$cgiRows\n";

    } elsif ( $cgiType =~ /^(radio|checkbox)$/i ) {
      print <<EOF;

There can be many Radio and Checkbox fields per database item.  I'm going
to ask you for 2 pieces of information for each radio button or checkbox:

  * Value:        value of the field that gets passed to the CGI handler
  * Descrioption: The textual description of the filed.

When you're done with all the fields, enter a blank line for the "Value"
to finish.

EOF
      $nButtonCount = 0;
      do {
        $nButtonCount++;
        print "\nValue (for Button $nButtonCount)?\n";
	$option[$nButtonCount]->{'value'} = &GetInput ();

	if ( $option[$nButtonCount]->{'value'} ) {
          print "Description (for Button $nButtonCount)?\n";
	  $option[$nButtonCount]->{'desc'} = &GetInput ();
	  print OUT <<EOF;
option = 		$option[$nButtonCount]->{'value'}:$option[$nButtonCount]->{'desc'}
EOF
	}
      } while ( $option[$nButtonCount]->{'value'} );

    } elsif ( $cgiType =~ /^select$/i ) {
      print <<EOF;

There can be many Options within a select field.  Please enter what the
value is for each option.

When you're done with all the options, enter a blank line to finish.

EOF
      $nButtonCount = 0;
      do {
        $nButtonCount++;
        print "\nValue (for Option $nButtonCount)?\n";
	$option[$nButtonCount]->{'value'} = &GetInput ();
	print OUT <<EOF;
option = 		$option[$nButtonCount]->{'value'}\n";
EOF
      } while ( $option[$nButtonCount]->{'value'} );

    } # end of conditional cgiType block.
  } # end of CGI input block
  print <<EOF;

      Lastly, the "Special" field is a directive which tells MsqlCGI to
      perform certain actions.  Right now, I've only implemented
      "CryptPW", which will setup a crypted password field,  and "date",
      which will convert the date from seconds since 1-1-70 to an
      intelligible string.

EOF
  $special = &GetInput();
  print OUT "special =\t\t$special\n";

  if ( $special ) {
    print <<EOF;

      Would you like any parameters for the Special field?  This parameter
      is a string that will be decoded by the Special functions.  If
      you're writing a special function, you can have the data encoded any
      way you like.  The only restriction is that leading and trailing
      whitespace will be deleted.

EOF
    $specialArgs = &GetInput();
    print OUT "specialArgs =\t$specialArgs\n";
  }


}

	######################
	# We're done now. 
	######################
print <<EOF;

      OK, That's all the information that I need.  You can now pass the
      data file (currently called "$outFile") into the MsqlCGI program.  

      Remember, if you need more information about MsqlCGI, look at
      http://petrified.cic.net/MsqlCGI

      Good Luck!

      ...alex...
      <altitude\@cic.net>

EOF

exit;




###########################################################################
# GetReturn.  Prompt for a return and get it from STDIN
###########################################################################
sub GetReturn {
  print "Press Return To Continue. ";
  <STDIN>;
}


###########################################################################
# GetInput: Get some input from the user.  the first argument is the
# default entry.   It removes leading and trailing whitespace.
###########################################################################
sub GetInput {
  local ( $default ) = @_;
  if ( $default ) {
    print "(Default: \"$default\") --> ";
  } else {
    print "(No default) --> ";
  }
  $in = <STDIN>;
  chop ( $in );
  $in =~ s/^\s*//;
  $in =~ s/\s*$//;
  $in = ( $in ) ? $in : $default;
  return ( $in );
}

###########################################################################
# GetYN, Get a yes or No answer.
###########################################################################
sub GetYN {
  $good = 0;
  while ( $good == 0 ) {
    print "(Answer Y or N) --> ";
    $in = <STDIN>;
    chop ( $in );
    if ( $in !~ /^[yYnN]/ ) {
      print "\nYou must enter \"Y\" or \"N\"\n\n";
    } else {
      $good = 1;
    }
  }
  if ( $in =~ /^[yY]/ ) {
    return ( "Yes" );
  } else {
    return ( "No" );
  }
}

sub Clear {
  system "clear";
}

sub GetOutFileName {

  &Clear();
  $try = 0;
  $good = 0;
  while ( $good == 0 ) {
    if ( $try ) {
      print <<EOF;

      I'm sorry.  I couldn't open the file "$outFile" for writing.
  Please try again.
EOF
    }
    print <<EOF;

      Please tell me the name of the output table definition file for this
      table.  This file will be where I store the data you tell me.  
      
      This file should go in the directory which you specified in the
      "\$defaultTableDefDir" variable of the MsqlCGI.conf file:

      	$defaultTableDefDir
      
      Would you like me to put the file into that directory?
EOF
    $bPutInDir = GetYN();

    print "\nOK, now what would you like me to name the file?\n";
    $outFile = &GetInput ( "table.def" );

    if ( $bPutInDir == "Yes" ) {
      $outFile = "$defaultTableDefDir/$outFile";
    }
    $try++;
    if ( open ( OUT, ">$outFile" ) ) {

      $good = 1;
      $oldFH = select ( OUT );
      $| = 1;
      select ( $oldFH );
    }
  }
  print "Using $outFile as the output file.\n";
  return $outFile;
}

sub GetDBHostName {

  &Clear();
  $try = 0;
  $good = 0;
  while ( $good == 0 ) {

    if ( $try ) {
      print <<EOF;

  I'm sorry.  I wasn't able to connect to the host: "$host".  
  The MSQL Error is: "$Msql::db_errstr".
  Please try again.
EOF
    }

    print <<EOF;

      Please tell me what host the database lives on.  Enter "localhost" if
      the database resides on this machine, and you want to access the
      database via a UNIX domain socket:

EOF

    $host = &GetInput ( "localhost" );
    $connectHost = ( $host eq "localhost" ) ? "" : $host;
    $try++;

    if ( $host !~ /^localhost/i ) {
      print <<EOF;

	I see that you're connecting to a remote database host.  Please tell
	me which TCP Port you would like to use.  
     
EOF
      $DBPort = &GetInput ( "1112" );
      $ENV{'MSQL_TCP_PORT'} = $DBPort;
    } else {
      $DBPort = undef;
    }

    $good = 1 if ( $dbh = Msql->Connect ( $connectHost ) );
  }
  print "Connect to host \"$host\" succeeded.\n";
  return ( $host, $DBPort );
}


##################
# GetDBName: This gets the database name...
##################
sub GetDBName {

  &Clear();
  $try = 0;
  $good = 0;
  while ( $good == 0 ) {
    if ( $try ) {
      print <<EOF;

  I'm sorry.  I wasn't able to access the database "$DBName".
  The MSQL Error is: "$Msql::db_errstr".
  Please try again.
EOF
    }
    print <<EOF;

      Please tell me the Database you'd like to select, a list is included
      below:

EOF
    ( @dbs = $dbh->ListDBs() ) || &Error ( "Couldn't do ListDBs: $Msql::db_errstr" );
    foreach $DBName ( @dbs ) {
      print "        (DB): $DBName\n";
    }
    print "\n";
    $DBName = &GetInput ();
    $try++;
  $good = 1 if ( $dbh->SelectDB ( $DBName ) );
  }
  print "Connect to database \"$DBName\" succeeded.\n";
  return $DBName;
}


sub GetTableName {
  &Clear();
  $try = 0;
  $good = 0;
  while ( $good == 0 ) {
    if ( $try ) {
      print <<EOF;

      I'm sorry.  The table "$tableSel" doesn't exist within the 
      database "$DBName".
  Please try again.
EOF
    }
    print <<EOF;

      Please tell me which table you want to select.  A list is included
      below:

EOF

    ( @tables = $dbh->ListTables() ) || 
	  &Error ( "Coudln't do ListTables: $Msql::db_errstr" );
    foreach $TableName ( @tables ) {
      print "        (Table): $TableName\n";
    }
    print "\n";
    $tableSel = &GetInput ();
    $try++;
    foreach $TableName ( @tables ) {
      if ( $tableSel eq $TableName ) {
	$good = 1;
	last;
      }
    }
    $TableName = $tableSel;
  }
  print "Using table \"$TableName\".\n";
}


sub GetAllow {
  
  ( $type ) = @_;

  %msg = ( 
    "display", 
    "Would you like users to be able to Display (browse) through the table?",
	   
    "modify",
    "Would you like users to be able to modify entries in this table?",

    "delete",
    "Would you like users to be able to delete entries from this table?",
     
    "create",
    "Would you like users to be able to create new entries in this table?" );

  print <<EOF;

      $msg{$type}

EOF
     
  $allow = &GetYN ();
  return $allow;
}


sub GetFieldInfo {
  local ( $i ) = @_;
  	# Get as much data from Msql as possible (name, type, primary key,
	# not null, etc...)
  $fieldName = $sth->name->[$i];
  if ( $sth->type->[$i] == &Msql::CHAR_TYPE ) {
    $fieldType = "char";

  } elsif ( $sth->type->[$i] == &Msql::INT_TYPE ) {
    $fieldType = "int";

  } elsif ( $sth->type->[$i] == &Msql::REAL_TYPE ) {
    $fieldType = "real";
  }

  $notNull = ( $sth->is_not_null->[$i] ) ? "Yes" : "No";
  $primaryKey = ( $sth->is_pri_key->[$i] ) ? "Yes" : "No";
  $tableLength = $sth->length->[$i];

  return ( $fieldName, $fieldType, $notNull, $primaryKey, $tableLength );

}
