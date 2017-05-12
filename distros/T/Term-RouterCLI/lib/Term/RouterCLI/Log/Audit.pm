#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI::Log                                 #
# Class:       Audit                                                #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Log::Audit;

use 5.8.8;
use strict;
use warnings;
use parent qw(Term::RouterCLI::Log);
use Term::RouterCLI::Debugger;
use Log::Log4perl;
use POSIX qw(strftime);

our $VERSION     = '1.00';
$VERSION = eval $VERSION;


my $oDebugger = new Term::RouterCLI::Debugger();


# TODO Work out how to rotate files and keep data longer instead of just pruning it

sub StartAuditLog
{
    # This method is for starting the audit log. 
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    my $retval = $self->ReadLogFile();
    
    if ($retval == 1) { $self->WriteExistingLogData(); }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub RecordToLog
{
	# This method will record an event in to the audit log
	# Required:
	#  hash_ref (prompt=>current prompt, commands=>command to be logged)
	my $self = shift;
	my $hParameter = shift;
    my $logger = $oDebugger->GetLogger($self);
    	 
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
	
    unless (defined $self->{'_oFileHandle'}) { $self->OpenFileHandle("A"); }
    my $FILE = ${$self->{'_oFileHandle'}};
    $logger->debug("$self->{'_sName'} - File Handle: $FILE");
    
    my $sTimeStamp = strftime "%Y-%b-%e %a %H:%M:%S", localtime;
    
    my $sOutput = "($sTimeStamp) \[$hParameter->{username}\@$hParameter->{tty}\] \[$hParameter->{prompt}\] $hParameter->{commands}";
    $logger->debug("$self->{'_sName'} - sOutput: $sOutput");
    
    print $FILE "$sOutput\n";
    $FILE->sync;
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

return 1;
