#!/usr/local/bin/perl 

#########################################################################
# MsqlCGI
#
# This is the main program file for MsqlCGI.   There isn't much to this
# file because most of the functionality is shelled out to various other
# files.
#
# You should edit the two variables in the "USER EDIT SECTION", 
# and then take a look at the # "MsqlCGI.conf" file.
#
# Also, please take a look at the documentation at
# 
#	http://petrified.cic.net/MsqlCGI/
#
# Author: Alex Tang <altitude@cic.net>
# Copyright 1996, CICNet Inc. and Alex Tang.
#########################################################################

#########################################################################
# USER_EDIT SECTION:
#########################################################################

	# The following variable is the name of the MsqlCGI.conf file.
	# Please edit it accordingly.  
$MSQLCGI_CONF = "/home/info/local/cgi-common/MsqlCGI/MsqlCGI.conf";


#########################################################################
# END OF USER_EDIT SECTION:  
# There should be no user editable information below this line.
#########################################################################

#########################################################################
# Variables:
#
# The global variables have been moved to the $MSQLCGI_CONF File.
#
# Edit those variables in that file.  We use the "require" statement to
# read in the variables.  We're using a full path name because we don't
# yet know where the MsqlCGI Directory is...
#########################################################################
require $MSQLCGI_CONF;


#########################################################################
# Start of main program.
#########################################################################
unshift ( @INC, $msqlCGIDir );
require "cgi-lib.pl";
use Msql;
use MsqlCGI;

$cgi=1;

print &PrintHeader;

##############
# Error checking.
##############
&ReadParse();

	# This does a quick check to see if we were just passed a filename
	# in the QUERY_STRING variable.  If so, we set the $defFile
	# Variable to it.
$in{'_MsqlCGI_defFile'} = $ENV{'QUERY_STRING'} 
  if ( ( $ENV{'QUERY_STRING'} ) && ( $ENV{'QUERY_STRING'} !~ /=/ ) );

$actionReq = ( $in{'_MsqlCGI_actionReq'} ) ? 
	       $in{'_MsqlCGI_actionReq'} : $defaultAction;

$in{'_MsqlCGI_defFile'} = ( $in{'_MsqlCGI_defFile'} ) ? 
			    $in{'_MsqlCGI_defFile'} : $defaultFile;

$CONFIG_FILE = $in{'_MsqlCGI_defFile'};
		
print &PrintVariables() if ( $debug );
&main::DPrint ( "doing file: $in{'_MsqlCGI_defFile'}, action: $defaultAction" );

&main::DPrint ( "ABout to do gettableConfig" );
( $tableInfo, $tData ) = &MsqlCGI::GetTableConfig();
&main::DPrint ( "Just did gettableConfig, $tableInfo, $tData" );

if ( $actionReq =~ /^RecordSearchSetup$/i ) {
  &RecordSearchSetup::RecordSearchSetup ( $main::{'_MsqlCGI_defFile'} );

} elsif ( $actionReq =~ /^RecordCreateReq$/i ) {
  &RecordCreateSetup::DoRecCreateSetup  ( $in{'_MsqlCGI_defFile'} );

} elsif ( $actionReq =~ /^RecordSearchReq$/i ) {
  &DoRecSearchSetup  ( $in{'_MsqlCGI_defFile'} );
  
} elsif ( $actionReq =~ /^OpsMenu$/i ) {
  &main::DPrint ( "Doign OpsMenu" );
  &SetupOpsMenu ( $in{'_MsqlCGI_defFile'} );

} elsif ( $actionReq =~ /^OpsMenuReq$/i ) {
  &DoOpsMenuReq ( $in{'_MsqlCGI_defFile'} );

} elsif ( $actionReq =~ /^RecCreateReq$/i ) {
  &main::DPrint ( "<b>" );
  &main::DPrint ( $tableInfo .
  $tableInfo->{'RecordCreateSuccessTemplate'} );
  &main::DPrint ( "</b>" );

  &RecCreateReq ();

} elsif ( $actionReq =~ /^PreliminaryResults$/i ) {
  &PreliminaryResults::StartPreliminaryResults();

} elsif ( $actionReq =~ /^RecActions$/i ) {
  &DoRecAction();

} elsif ( $actionReq =~ /^RecModify$/i ) {
  &DPrint ( "In RecModify" );
  &DoModRec ();
} else {
  &DPrint ( "Didn't understand Request: \"$actionReq\"" );
  &Error ( "Sorry, The Request: $actionReq isn't understood." );
}

#&MsqlCGI::PrintHTMLFooter();

print &PrintVariables() if ( $debug );
exit;

