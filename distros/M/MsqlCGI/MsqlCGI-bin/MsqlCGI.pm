############################################################################
# Administrative tool for mSQL.  
#
# Author: Alex Tang <altitude@cic.net>
# Copyright 1996 CICNet, Inc. All Rights Reserved.
############################################################################

package MsqlCGI;

require "sub.RecordSearchSetup";
require "sub.RecordActions";
require "sub.OperationsMenu";
require "sub.RecordCreateProcess";
require "sub.RecordCreateSetup";
require "sub.RecordDisplay";
require "sub.PreliminaryResults";
require "sub.RecordModifySetup";
require "sub.RecordModifyProcess";
require "sub.RecordDeleteProcess";
require "sub.Template";
require "sub.Error";


############################################################################
# GetTableConfig
# This reads the table config file and stores it in a bunch of arrays.
############################################################################
sub GetTableConfig {
  my ( $file ) = $main::CONFIG_FILE;

  $file = &MsqlCGI::ConvertFileName ( $file, $main::defaultTableDefDir );

  open ( F, $file ) || 
  	&main::Error ( "Couldn't open file \"$file\".  Perhaps it doesn't exist" );
  $nCount = -1;
  $nLine = 0;

  	# First Initialize some variables.
  $tableInfo{'priKeyArrNum'} = -1;

  while ( <F> ) {
    $nLine++;
    chop;
    next if ( ( $_ =~ /^\s*#/ ) || ( $_ =~ /^\s*$/ ) );

    ( $key, $value ) = split ( /\s*=\s*/, $_, 2 );
    #&main::DPrint ( "\"$key\" = \"$value\"\n" );

    	# These are the table wide host variables

    if ( $key =~ /^DBHost$/i ) {
      $tableInfo{'DBHost'} = $value;

    } elsif ( $key =~ /^DBName$/i ) {
      $tableInfo{'DBName'} = $value;

    } elsif ( $key =~ /^TableName$/i ) {
      $tableInfo{'TableName'} = $value;

    } elsif ( $key =~ /^DBPort$/i ) {
      $tableInfo{'DBPort'} = $value;

	# Logical Section 2 as defined in the file
	# http://petrified.cic.net/MsqlCGI/TableDefinition.html

    } elsif ( $key =~ /^AllowModify$/i ) {
      $tableInfo{'AllowModify'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

    } elsif ( $key =~ /^AllowDelete$/i ) {
      $tableInfo{'AllowDelete'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;
    
    } elsif ( $key =~ /^AllowCreate$/i ) {
      $tableInfo{'AllowCreate'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;
    
    } elsif ( $key =~ /^AllowSearch$/i ) {

    } elsif ( $key =~ /^AllowDisplay$/i ) {
      $tableInfo{'AllowDisplay'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

	# Logical Section 3 as defined in the file
	# http://petrified.cic.net/MsqlCGI/TableDefinition.html

    } elsif ( $key =~ /^TemplateDir$/i ) {
      $tableInfo{'TemplateDir'} = $value;

    } elsif ( $key =~ /^HTMLFooterFile$/i ) {
      $tableInfo{'HTMLFooterFile'} = $value;

    } elsif ( $key =~ /^OperationsMenuTemplate$/i ) {
      $tableInfo{'OperationsMenuTemplate'} = $value;

    } elsif ( $key =~ /^RecordSearchTemplate$/i ) {
      $tableInfo{'RecordSearchTemplate'} = $value;

    } elsif ( $key =~ /^RecordDisplayTemplate$/i ) {
      $tableInfo{'RecordDisplayTemplate'} = $value;

    } elsif ( $key =~ /^PreliminaryResultsTemplate$/i ) {
      $tableInfo{'PreliminaryResultsTemplate'} = $value;

    } elsif ( $key =~ /^ErrorTemplate$/i ) {
      $tableInfo{'ErrorTemplate'} = $value;

    } elsif ( $key =~ /^RecordCreateSuccessTemplate$/i ) {
      $tableInfo{'RecordCreateSuccessTemplate'} = $value;

    } elsif ( $key =~ /^RecordModifySuccessTemplate$/i ) {
      $tableInfo{'RecordModifySuccessTemplate'} = $value;

    } elsif ( $key =~ /^RecordDeleteSuccessTemplate$/i ) {
      $tableInfo{'RecordDeleteSuccessTemplate'} = $value;

    } elsif ( $key =~ /^RecordModifySetupTemplate$/i ) {
      $tableInfo{'RecordModifySetupTemplate'} = $value;

    } elsif ( $key =~ /^RecordCreateSetupTemplate$/i ) {
      $tableInfo{'RecordCreateSetupTemplate'} = $value;

	# These are all variables that are keyed in for a field.
    } elsif ( $key =~ /^newField$/i ) {
      $nCount++;
      $nOption = 0;
      		# setup some defaults.	
      $element[$nCount]->{'displayEntry'} = "y";
      $element[$nCount]->{'displayValue'} = "y";

    } elsif ( $key =~ /^fieldName$/i ) {
      $element[$nCount]->{'fieldName'} = $value;

    } elsif ( $key =~ /^description$/i ) {
      $element[$nCount]->{'description'} = $value;

    } elsif ( $key =~ /^special$/i ) {
      $element[$nCount]->{'special'} = $value;

    } elsif ( $key =~ /^specialArgs$/i ) {
      $element[$nCount]->{'specialArgs'} = $value;

    } elsif ( $key =~ /^dispFieldWhenCreate$/i ) {
      $element[$nCount]->{'dispFieldWhenCreate'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

    } elsif ( $key =~ /^modFieldWhenCreate$/i ) {
      $element[$nCount]->{'modFieldWhenCreate'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

    } elsif ( $key =~ /^dispFieldWhenModify$/i ) {
      $element[$nCount]->{'dispFieldWhenModify'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

    } elsif ( $key =~ /^dispFieldWhenDisplay$/i ) {
      $element[$nCount]->{'dispFieldWhenDisplay'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

    } elsif ( $key =~ /^displayValue$/i ) {
      $element[$nCount]->{'displayValue'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;
    
    } elsif ( $key =~ /^modFieldWhenModify$/i ) {
      $element[$nCount]->{'modFieldWhenModify'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;
    
    } elsif ( $key =~ /^modFieldWhenCreate$/i ) {
      $element[$nCount]->{'modFieldWhenCreate'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

    } elsif ( $key =~ /^searchable$/i ) {
      $element[$nCount]->{'searchable'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

    } elsif ( $key =~ /^summary$/i ) {
      $element[$nCount]->{'summary'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

    } elsif ( $key =~ /^cgiType$/i ) {
      $element[$nCount]->{'cgiType'} = $value;
    
    } elsif ( $key =~ /^fieldType$/i ) {
      $element[$nCount]->{'fieldType'} = $value;
    
    } elsif ( $key =~ /^fieldSize$/i ) {
      $element[$nCount]->{'fieldSize'} = $value;

    } elsif ( $key =~ /^notNull$/i ) {
      $element[$nCount]->{'notNull'} = $value;
    
    } elsif ( $key =~ /^primaryKey$/i ) {
      if ( ( $value =~ /^y/i ) || ( $value == 1 ) ) {
        $element[$nCount]->{'primaryKey'} = 1;
	$tableInfo{'priKeyArrNum'} = $nCount;
      } else {
        $element[$nCount]->{'primaryKey'} = 0;
      }
    
    } elsif ( $key =~ /^nonNull$/i ) {
      $element[$nCount]->{'nonNull'} = 
      	( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;

    } elsif ( $key =~ /^cgiChecked$/ ) {
      if ( ( $value ) && 
	   ( $element[$nCount]->{cgiType} !~ /(checkbox|radio)/i ) ) {
	&TError ( " can't have a checked flag.  it's not a
	          checkbox or a radio button element" );
      } else {
        $element[$nCount]->{'cgiChecked'} = 
      	  ( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;
      }

    } elsif ( $key =~ /^cgiSize$/ ) {
      if ( ( $value ) && 
	   ( $element[$nCount]->{'cgiType'} !~ /(text|password|select)/i ) ) {
	&TError ( " can't have a cgiSize.  it's not a
		  text or password element" );
      } else {
        $element[$nCount]->{'cgiSize'} = $value;
      }

    } elsif ( $key =~ /^cgiMaxLength$/ ) {
      if ( ( $value ) && 
	   ( $element[$nCount]->{'cgiType'} !~ /(text|password)/i ) ) {
	&TError ( " can't have a cgiSize.  it's not a
		  text or password element" );
      } else {
        $element[$nCount]->{'cgiMaxLength'} = $value;
      }

    } elsif ( $key =~ /^value$/ ) {
        $element[$nCount]->{'value'} = $value;

    } elsif ( $key =~ /^cgiRows$/ ) {
      if ( ( $value ) && 
	   ( $element[$nCount]->{'cgiType'} !~ /textarea/i ) ) {
	&TError ( " can't have a Rows tag.  it's not a
		  TextArea element" );
      } else {
	$element[$nCount]->{'cgiRows'} = $value;
      }

    } elsif ( $key =~ /^cgiCols$/ ) {
      if ( ( $value ) && 
	   ( $element[$nCount]->{'cgiType'} !~ /textarea/i ) ) {
	&TError ( " can't have a Cols tag.  it's not a
		  TextArea element" );
      } else {
	$element[$nCount]->{'cgiCols'} = $value;
      }

    } elsif ( $key =~ /^cgiMultiple$/ ) {
      if ( ( $value ) &&
	   ( $element[$nCount]->{'cgiType'} !~ /select/i ) ) {
	&TError ( " can't have a cgiMultiple tag.  it's not a
		  Select element" );
      } else {
	$element[$nCount]->{'cgiMultiple'} = 
      	  ( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;
      }

    } elsif ( $key =~ /^cgiSelected$/ ) {
      if ( ( $value ) && 
	   ( $element[$nCount]->{'cgiType'} !~ /option/i ) ) {
	&TError ( " can't have a cgiSelected tag.  it's not a
		  Option element" );
      } else {
	$element[$nCount]->{'cgiSelected'} = 
      	  ( ( $value =~ /^y/i ) || ( $value == 1 ) ) ? 1 : 0 ;
      }

    } elsif ( $key =~ /^option$/i ) {
      ( $optionValue, $optionName ) = split ( /:/, $value, 2 );
      $element[$nCount]->{option}[$nOption]->{name} = $optionName;
      $element[$nCount]->{option}[$nOption]->{value} = $optionValue;
      $nOption++;

    } else {
      &TError ( "the Key \"$key\" isn't recognized" );
    }

  }
  &main::DPrint ( "There were $nCount entries in the table Def file." );

  	# More Error checking.  We need to make sure these variables have
	# been defined.
  if ( $tableInfo{priKeyArrNum} == -1 ) {
    &main::Error ( "Sorry, it appears that this table does not have a
    	            Primary Key.   MsqlCGI will not function on tables
		    that do not have a primary Key." );
  }

  return ( \%tableInfo, \@element );
}

# Just an error Wrapper. 
sub TError {
  ( $msg ) = @_;
  &main::Error ( "File: $file<br>Line $nLine<br>Element $nCount<p>$msg" );
}


#############################################################################
# CreateCGIString 
# 
# This creates a CGI string.  this function is getting pretty ugly.  There
# are so many different combinations of type and "Display"/"Modify".
#############################################################################
sub CreateCGIString {
  ( $pData, $type, $value ) = @_;

  if ( $type !~ /^(SEARCH|MODIFY|CREATE)$/ ) {
    &main::Error ( "The second parameter to CreateCGIString ($type) must 
                   be one of SEARCH, MODIFY, or CREATE." );
  }

  #&main::DPrint ( "$pData, $type, $value, $pData->{'modFieldWhenModify'}" );

  $modStr = "_MsqlCGI_modify-" .  $pData->{'fieldName'};

  #$strMod = <<EOF;
  #		<input type=radio name="$modStr" value="Yes"> Yes<br>
#		<input type=radio name="$modStr" value="No" Checked> No
  $strMod = "<input type=hidden name=\"$modStr\" value=\"Yes\">";

#EOF

	# Here's a tricky one.  We want to parse $value for any HTML
	# references (basically only http:// and ftp:// directives).  But
	# we can't just replace the $value string with the link becausae
	# we don't want to do that when we edit the field.  To cheat, The
	# function "ConvertValue" will return the link string but we will
	# only use it when we're not modifying the field.
  $strConvValue = &ConvertValue ( $value, $pData );


  	# Here's where we're going to intercept the data flow to make room
	# for the "Special" flags.  If the element has a "special" flag,
	# We MUST look for the sub.<name> file in the
	# appropriate directory

  if ( $pData->{'special'} ) {
	# We're just creating the function name to call here.
    $funcName = &GetSpecialFunctionName ( $pData, "CreateCGIString" );
    ( $strMod, $strCGI ) = &{$funcName}( $main::tableInfo, $pData, $type, $value );
  } 

  if ( ( ( $pData->{'special'} ) && ( $strCGI eq "_MsqlCGI_Defer" ) ) ||
       ( ! $pData->{'special'} ) ) {


	  # It's not a special field, so we're going to proceed as normal.
   
    $strCGI = "";

	  #
	  # TEXT OR PASSWORD
	  #
    if ( $pData->{'cgiType'} =~ /^(text|password)$/i ) {
      if ( $type =~ /^modify$/i ) {
	if ( $pData->{'modFieldWhenModify'}  ) {
	  $strCGI .= "<INPUT TYPE=\"$pData->{'cgiType'}\" ";
	  $strCGI .= "NAME=\"$pData->{'fieldName'}\" ";
	  $strCGI .= "SIZE=$pData->{'cgiSize'} " if ( $pData->{'cgiSize'} );
	  $strCGI .= "MAXLENGTH=$pData->{'cgiMaxLength'} " 
	      if ( $pData->{'cgiMaxLength'} );
	  $strCGI .= "VALUE=\"$value\" " if ( $value );
	  $strCGI .= ">";
	} else {
	  $strCGI = $strConvValue;
	  $strMod = "&nbsp;";
	}
      
      } elsif ( $type =~ /^search$/i ) {
	$strCGI .= "<INPUT TYPE=\"$pData->{'cgiType'}\" ";
	$strCGI .= "NAME=\"$pData->{'fieldName'}\" ";
	$strCGI .= "SIZE=$pData->{'cgiSize'} " if ( $pData->{'cgiSize'} );
	$strCGI .= "MAXLENGTH=$pData->{'cgiMaxLength'} " 
	    if ( $pData->{'cgiMaxLength'} );
	$strCGI .= ">";

      } elsif ( $type =~ /^create$/i ) {
	if ( $pData->{'modFieldWhenCreate'} ) {
	  $strCGI .= "<INPUT TYPE=\"$pData->{'cgiType'}\" ";
	  $strCGI .= "NAME=\"$pData->{'fieldName'}\" ";
	  $strCGI .= "SIZE=$pData->{'cgiSize'} " if ( $pData->{'cgiSize'} );
	  $strCGI .= "MAXLENGTH=$pData->{'cgiMaxLength'} " 
	    if ( $pData->{'cgiMaxLength'} );
	  $strCGI .= "VALUE=\"$value\" " if ( $value );
	  $strCGI .= ">";

	} else {
	  $strCGI = "Not Modifiable.";
	}

      } #end of type text/password


	  #
	  # TEXTAREA
	  #
    } elsif ( $pData->{'cgiType'} =~ /^textarea$/i ) {
      if ( $type =~ /^search/i ) {
	$strCGI .= "<INPUT TYPE=\"text\" ";
	$strCGI .= "NAME=\"$pData->{'fieldName'}\" ";
	$strCGI .= "SIZE=30>";

      } elsif ( $type =~ /^create$/i ) {
	if ( $pData->{'modFieldWhenCreate'} ) {
	  $strCGI .= "<TEXTAREA NAME=\"$pData->{'fieldName'}\" ";
	  $strCGI .= "ROWS=$pData->{'cgiRows'} " 
		if ( int ( $pData->{'cgiRows'} ) );
	  $strCGI .= "COLS=$pData->{'cgiCols'} " 
		if ( int ( $pData->{'cgiCols'} ) );
	  $strCGI .= ">$value</TEXTAREA>";

	} else {
	  $strCGI = "Not Modifiable.";
	}

      } elsif ( $type =~ /^modify$/i ) {
	if ( $pData->{'modFieldWhenModify'} ) {
	  $strCGI .= "<TEXTAREA NAME=\"$pData->{'fieldName'}\" ";
	  $strCGI .= "ROWS=$pData->{'cgiRows'} " 
		if ( int ( $pData->{'cgiRows'} ) );
	  $strCGI .= "COLS=$pData->{'cgiCols'} " 
		if ( int ( $pData->{'cgiCols'} ) );
	  $strCGI .= ">$value</TEXTAREA>";
	} else {
	  $strCGI = $strConvValue;
	  $strMod = "&nbsp;";
	}

      } #end of type Textarea


	  #
	  # RADIO or CHECKBOX
	  #
    } elsif ( $pData->{'cgiType'} =~ /^(radio|checkbox)$/i ) {
      $typeStr = ( $type eq "search" ) ? "checkbox" : $pData->{'cgiType'};

      for ( $i = 0; $i <= $#{$pData->{'option'}}; $i++ ) {
        $strCGI .= <<EOF;
	  <input	type="$typeStr"
		  name="$pData->{'fieldName'}"
EOF
	if ( ( $type =~ /^modify$/i ) && ( $pData->{'modFieldWhenModify'} ) &&
	     ( $value eq $pData->{'option'}[$i]->{'value'} ) ) {
	  $strCGI .= "Checked ";
	}
	$strCGI .= <<EOF;
		  value="$pData->{'option'}[$i]->{'value'}">
		  $pData->{'option'}[$i]->{'name'}<br>
EOF
      }

	  #
	  # SELECT
	  #
    } elsif ( $pData->{'cgiType'} =~ /^select$/i ) {
      $strSize = "size=$pData->{'cgiSize'}" if ( $pData->{'cgiSize'} );
      $strMult = "Multiple" if ( $pData->{'cgiMultiple'} );
      $strCGI = <<EOF;
	  <SELECT name="$pData->{'fieldName'}" 
		  $strSize $strMult>
EOF

      if ( $type eq "search" ) {
	$strCGI .= <<EOF;
	  <option></option>
EOF
      }

      for ( $i = 0; $i <= $#{$pData->{'option'}}; $i++ ) {
	$strCGI .= "<option";

	if ( ( $type =~ /^modify$/i ) && ( $pData->{'modFieldWhenModify'} ) &&
	     ( $value eq $pData->{'option'}[$i]->{'value'} ) ) {
	  $strCGI .= " Selected";
	}
	$strCGI .= ">$pData->{'option'}[$i]->{'value'}\n";
EOF
      }
      $strCGI .= "</SELECT>\n";

    }

  }
  return ( $strMod, $strCGI );

}

#############################################################################
# ConvertValue
#
# This function creates a new string based on the parameter it's given.
# It looks for:
#	* Special fields, and calls the associated "ConvertValue" function
#	* "<" and ">" characters and replaces them with valid HTML ("&lt;"
#	  and "&gt;" respectively
# 	* hypertext link text (anything with "://") and converts it into a
# 	  link of the form "<a href=...>text</a>"
#	* returns (\n) and converts them to "<br>".
#	* Converts radio and checkbox values into their 'name' components
#############################################################################
sub ConvertValue {
  local ( $newValue, $pData ) = @_;

  	# Here's where we're going to intercept the data flow to make room
	# for the "Special" flags.  If the element has a "special" flag,
	# We MUST look for the sub.<name> file in the
	# appropriate directory
  if ( $pData->{'special'} ) {
    $funcName = &GetSpecialFunctionName ( $pData, "ConvertValue" );
    ( $newValue, $bContinue ) = &{$funcName}( $newValue, $pData );
    if ( ! $bContinue ) {
      return $newValue;
    }
  } 

  	# This loop converts a radio button "value" into it's associated
	# "name".  
  if ( $pData->{'cgiType'} =~ /^(radio|checkbox)$/i ) {
    for ( $i = 0; $i <= $#{$pData->{'option'}}; $i++ ) {
      if ( $newValue eq $pData->{'option'}[$i]->{'value'} ) {
	$newValue = $pData->{'option'}[$i]->{'name'};
	last;
      }
    }
  }

  $newValue =~ s/</&lt;/gi;
  $newValue =~ s/>/&gt;/gi;
  $newValue =~ s/\n/<br>\n/gi;
    	# look for a "://".  If it is, make a link out of the value
  $newValue =~ s/(\S*:\/\/\S*)/<a href=\"$1\">$1<\/a>/gi;
  $newValue =~ s/(\S*@\S*)/<a href=\"mailto:$1\">$1<\/a>/gi;

  return $newValue;
}


#############################################################################
# GetSpecialFunctionName
#
# This function returns the name of the "special" function.  It takes the
# current Data Element and a string denoting the "type" of function.
# Currently, the only "type"s that are allowed are:
#
#	* CreateCGIString: Convert a DB value to a cgi form element or set
#	                   of form elements
#	* ConvertValue:    Convert from a db Value to a NON-Modifiable 
#			   text string that will be displayed to the user.
#	* CreateQueryPart_Create:	   Convert values passed back from the CGI form to
#			   a data element which can be put in the DB.
#			   This is used when Creating a New record.
#	* CreateQueryPart_Modify:	   Convert values passed back from the CGI form to
#			   a data element which can be put in the DB
#			   This is used when Modifying a New record.
# Data Elem
#############################################################################
sub GetSpecialFunctionName {
  local ( $pData, $type ) = @_;

  if ( $type !~ /^(CreateCGIString|ConvertValue|CreateQueryPart_Create|CreateQueryPart_Modify|CreateQueryPart_Search)$/ ) {
    &main::Error ( "The Type: \"$type\" wasn't recognized in
    		    GetSpecialFunctionName" );
  }

  &main::DPrint ( "In GetSpecialFunctionName, $type, $pData->{'fieldName'}" );
  $specialName = $pData->{'special'};
  $subFileName = $main::pluginDir . "/sub." . $specialName;
  if ( -e $subFileName ) {
    require "$subFileName";
  } else {
    &main::Error ( "The special subroutine file $subFileName doesn't
    exist." );
  }
  $funcName = 
  $funcName = $specialName . "::" .  $type;
  return $funcName;
}


#############################################################################
# Get ElementStruct
#
# This routine returns a hash reference to the form element structure
# who's fieldName matches the first argument.  the second argument should
# be an array reference containing the array of element structs.
#############################################################################
sub GetElementStruct {
  ( $key ) = @_;
  for ( $nCount = 0; $nCount <= $#{$main::tData}; $nCount++ ) {
    if ( $main::tData->[$nCount]->{'fieldName'} eq $key ) {
      return $main::tData->[$nCount];
    }
  }
  return undef;
}

#############################################################################
# Get ElementStructNumber
#
# This routine returns the array number reference to the element structure
# who's fieldName matches the first argument.  the second argument should
# be an array reference containing the array of element structs.
#############################################################################
sub GetElementStructNumber {
  ( $key ) = @_;
  for ( $nCount = 0; $nCount <= $#{$main::tData}; $nCount++ ) {
    if ( $main::tData->[$nCount]->{'fieldName'} eq $key ) {
      &main::DPrint ( "<b>Returning: $nCount</b>" );
      return $nCount;
    }
  }
  &main::DPrint ( "<b>Returning: undef</b>" );
  return undef;
}

#############################################################################
# GetElementValue
#
# This routine returns a value of a certain part of a record structure.
# The field name is the first parameter.
#############################################################################
sub GetElementValue {
  ( $fieldName, $param ) = @_;
  $pData = &GetElementStruct ( $fieldName, $main::tData );
  return $pData->{$param};
}


#############################################################################
# SetupMsqlConnection
#
# This just sets up the msql connection with the proper host and whatnot.
# it returns a database handle.
#############################################################################
sub SetupMsqlConnection {
  $DBHost = $main::tableInfo->{'DBHost'};
  $DBPort = $main::tableInfo->{'DBPort'};
  $DBName = $main::tableInfo->{'DBName'};


  if ( $DBHost =~ /^localhost$/i ) {
    &main::DPrint ( "Connecting to db (local)" );
    $dbh = Msql->Connect() || 
    	&main::Error ( "Couldn't connect to the Database.  $Msql::db_errstr" );

  } else {
    &main::DPrint ( "Connecting to db $DBHost on port $DBPort" );
    $ENV{'MSQL_TCP_PORT'} = $DBPort;
    $dbh = Msql->Connect ( $DBHost ) ||
    	&main::Error ( "Couldn't connect to db Host $DBHost on Port
	$DBPort" );
  }

  &main::DPrint ( "Selecting db: $DBName" );

  $dbh->SelectDB ( $DBName ) ||
  	&main::Error ( "Couldn't Select db $DBName" );

  return $dbh;
}

#############################################################################
# StrToQueryStr
#
# This function takes a regular text string, the field type, and the type
# of query we're modifying as it's arguments.  If the type is "char" it
# makes a valid Msql Search string out of it.  If it's "int" or "real", it
# makes sure that the number is valid.  It returns the new value.
#############################################################################
sub StrToQueryStr {
  local ( $strValue, $fieldType, $queryType ) = @_;

&main::DPrint ( "<b>$strValue, $fieldType</b>" );
  if ( $queryType !~ /^(SEARCH|CREATE|MODIFY)$/ ) {
    &main::Error ( "Programmer Error: in StrToQueryStr, queryType must
    be either 'SEARCH', 'MODIFY', or 'CREATE'" );
  }
  
  if ( $fieldType eq "char" ) {

    	# We need to do some extra escaping if the type is a character and
	# the query type is "search"
    if ( ( $queryType eq "SEARCH" ) ||
         ( $queryType eq "MODIFY" ) ) {
      if ( $strValue =~ /[\%\\\^]/ ) {
	&main::Error ( "Sorry, you cannot use the characters <pre>
		% \\ ^ </pre> in your query" );
      }

      #$strValue =~ s/([\$\(\)?\[\|\]])/[$1]/gi;
      #$strValue =~ s/([\$?\[\|\]])/[$1]/gi;
      #$strValue =~ s/([_])/\\\\$1/gi;
    }

&main::DPrint ( "<b>$strValue</b>" );
    $strValue =~ s/(['])/\\$1/gi;
&main::DPrint ( "<b>$strValue</b>" );
    $strValue = "'$strValue'";

    if ( $strValue eq "''" ) {
      $strValue = "NULL";
    }

  } elsif ( $fieldType eq "int" ) {
    if ( $strValue =~ /\D/ ) {
      &main::Error ( "You must enter only a number in the numeric fields.");
    }

  } elsif ( $fieldType eq "real" ) {
    if ( $strValue !~ /[\d\.]/ ) {
      &main::Error ( "You must enter only a Real Numbers in the real
      number fields.");
    }
  }
  return $strValue;
}

#############################################################################
# ConvertFileName
#
# Just do expansions on a file name.  
#   First see if the first character is a "/" or a "~".  If it's not
#     either, prepend the DefDir variable on to it.
#   Then see if the first character is a "~".  If so, substitute the name
#     with a the directory as returned by "getpwnam";
#############################################################################
sub ConvertFileName {
  my ( $fileName, $defDir ) = @_;

  &main::DPrint ( "In ConvertFileName, file is; $fileName, defDir is $defDir" );
  $fileName = $defDir . "/" . $fileName 
  	if ( ( substr ( $fileName, 0, 1 ) ) !~ /[~\/]/ ) ;

  &main::DPrint ( "After first substitution: $fileName" );

  $fileName =~ s/^~(\w*)/
    if ( $1 ) {
      ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell) = 
      getpwnam ( $1 ); $dir
    } else {
      ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell) = 
      getpwuid ( $< ); $dir
    }/ge;
  &main::DPrint ( "After second substitution.  Returning: $fileName" );
  return $fileName;
}



#######################################################################
# DPrint
#
# A Debug print mechanism.  If the variable "main::debug" is turned on, it
# will print.
#######################################################################
sub main::DPrint {
  if ( $main::debug == 1 ) {
    print "DEBUG: $_[0]<br>\n";
  }
  return;
}


1;


