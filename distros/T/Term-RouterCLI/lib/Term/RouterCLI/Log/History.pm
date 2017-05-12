#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI::Log                                 #
# Class:       History                                              #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Log::History;

use 5.8.8;
use strict;
use warnings;
use parent qw(Term::RouterCLI::Log);
use Term::RouterCLI::Debugger;
use Log::Log4perl;

our $VERSION     = '1.00';
$VERSION = eval $VERSION;


my $oDebugger = new Term::RouterCLI::Debugger();


sub ClearHistory
{
    # This method will clear the history out of the terminal.
    my $self = shift;
    $self->{'_oParent'}->{_oTerm}->clear_history();
    $self->ClearExistingLogData();
}

sub GetHistory
{
    # This method will get the current history from the terminal
    # Return:
    #   array_ref(command history)
    my $self = shift;
    my @aHistoryCommandBuffer = $self->{'_oParent'}->{_oTerm}->GetHistory();
    return \@aHistoryCommandBuffer;
}

sub LoadCommandHistoryFromFile
{
    # This method will read in the content of the local history file if it exists
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    
    $self->ReadLogFile();

    foreach (@{$self->{'_aCurrentLogData'}}) 
    {
        $logger->debug("$self->{'_sName'} - _aCurrentLogData: $_");
        chomp();
        next unless /\S/;
        $self->{'_oParent'}->{_oTerm}->addhistory($_);
    }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub SaveCommandHistoryToFile
{
    # This method will save the current command history to a text file or other sources as defined
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');

    return unless ((defined $self->{'_sFilename'}) && ($self->{'_iFileLength'} > 0));
    return unless $self->{'_oParent'}->{_oTerm}->can('GetHistory');
    
    $self->{'_aCurrentLogData'} = $self->GetHistory();
    
    # Let store the current size of the log data
    $self->SetCurrentLogSize();
    
    
    $logger->debug("$self->{'_sName'} - _aCurrentLogData:\n", ${$oDebugger->DumpArray($self->{'_aCurrentLogData'})});
    
    $self->WriteExistingLogData();
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub PrintHistory
{
    # This method will print out the command history from the terminal.  You can pass in an 
    # integer to tell it how many lines of history to print out.
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);

    my $iNumberOfLinesToPrint = -1;
    
    # Lets grab the number of lines to print from the passed in values, but only if it is an integer
    my $parameter = $self->{'_oParent'}->{_aCommandArguments}->[0];
    if((defined $parameter) && ($parameter =~ /^(\d+)$/)) 
    {
        $iNumberOfLinesToPrint = $1;
    }

    my $aHistoryCommandBuffer = $self->GetHistory();
    
    # What is the current number of lines in the history buffer
    my $iHistoryBufferSize = @$aHistoryCommandBuffer;
    
    # Lets only print out the number of records requested up to the size of the history buffer
    if ($iNumberOfLinesToPrint == -1 || $iNumberOfLinesToPrint > $iHistoryBufferSize) 
    { 
        $iNumberOfLinesToPrint = $iHistoryBufferSize; 
    }
    
    # Set a starting point for the array so that we will only print the last X number of history items if requested
    my $iArrayOffsetNumber = $iHistoryBufferSize - $iNumberOfLinesToPrint;
    
    # Print out the lines of the history buffer
    foreach ($iArrayOffsetNumber..$iHistoryBufferSize-1) 
    { 
        print "\($_\) $aHistoryCommandBuffer->[$_]\n"; 
    }
}

return 1;
