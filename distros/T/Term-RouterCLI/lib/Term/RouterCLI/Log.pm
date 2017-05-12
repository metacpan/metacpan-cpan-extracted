#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Log                                                  #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-04-26                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Log;

use 5.8.8;
use strict;
use warnings;
use Term::RouterCLI::Debugger;
use Log::Log4perl;
use FileHandle;

our $VERSION     = '1.00';
$VERSION = eval $VERSION;


my $oDebugger = new Term::RouterCLI::Debugger();


sub new
{
    my $pkg = shift;
    my $class = ref($pkg) || $pkg;  

    my $self = {};
    $self->{'_sName'}               = $pkg;         # Lets set the object name so we can use it in debugging
    bless ($self, $class);
    
    # Lets send any passed in arguments to the _init method
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self = shift;
    my %hParameters = @_;

    $self->{'_bEnabled'}            = 1;
    $self->{'_oParent'}             = undef;
    $self->{'_sDirectory'}          = './logs/';
    $self->{'_sFilename'}           = undef;
    $self->{'_iFileLength'}         = 500;
    $self->{'_iMaxFileLength'}      = 50000;        # Define an upper bound for sanity sakes
    $self->{'_oFileHandle'}         = undef;
    $self->{'_aCurrentLogData'}     = undef;
    $self->{'_iCurrentLogSize'}     = undef;

    # Lets overwrite any defaults with values that are passed in
    if (%hParameters)
    {
        foreach (keys (%hParameters)) { $self->{$_} = $hParameters{$_}; }
    }
}

sub DESTROY
{
    my $self = shift;
    $self = {};
} 



# ----------------------------------------
# Public Methods
# ----------------------------------------
sub Enable
{
    # This method will enable this log method
    my $self = shift;
    $self->{'_bEnabled'} = 1;
}

sub Disable
{
    # This method will disable this log method
    my $self = shift;
    $self->{'_bEnabled'} = 0;
}

sub ExpandTildesInFilename
{
    # This method will expand any tildes that are in the file name so that it will work right
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    if (defined $self->{'_sFilename'}) 
    {
        $self->{'_sFilename'} =~ s/^~([^\/]*)/$1?(getpwnam($1))[7]:$ENV{HOME}||$ENV{LOGDIR}||(getpwuid($>))[7]/e;
    }    
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub SetFilename
{
    # This method will set the filename for this logging method
    # Required:
    #   string (filename)
    my $self = shift;
    my $parameter = shift;
    my $logger = $oDebugger->GetLogger($self);

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');  
    if (defined $parameter)
    {
        $self->{'_sFilename'} = $parameter;
        $self->ExpandTildesInFilename();
    }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');   
}

sub SetFileLength
{
    # This method will set the length of the history file on disk which is limited to 50000 for sanity reasons
    # Required:
    #   integer (length)
    my $self = shift;
    my $parameter = shift;
    my $logger = $oDebugger->GetLogger($self);

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    if (($parameter =~ /^\d+$/) && ($parameter > 0) && ($parameter < $self->{'_iMaxFileLength'}))
    {
        $self->{'_iFileLength'} = $parameter;
        if ($self->{'_iFileLength'} eq $parameter) { $logger->info("File length value set to $parameter");}
    } 
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub SetCurrentLogSize
{
    # This method will capture the current size of the logging data array
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    $self->{'_iCurrentLogSize'} = @{$self->{'_aCurrentLogData'}};
    
    $logger->debug("$self->{'_sName'} - _iCurrentLogSize: $self->{'_iCurrentLogSize'}");
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub OpenFileHandle
{
    # This method will create a file handle for the audit log
    # Required:
    #   string (handle type R=Read, W=Write, A=Append)
    my $self = shift;
    my $parameter = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $FILE = undef;

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    
    # Make sure the file name and size have been defined
    if ((defined $self->{'_sFilename'}) && ($self->{'_iFileLength'} > 0))
    {
        # Open file depending on what we need.  I tried to just use +>> but that does not truncate and clean
        # out the file so it makes it so I can not purge old data
        if ($parameter eq "W")
        {
            $logger->debug("$self->{'_sName'} - Opening file hand for writing");
            $FILE = new FileHandle(">$self->{'_sFilename'}") || warn "Can not open " . $self->{'_sFilename'} . " for writing $!\n";
        } 
        elsif ($parameter eq "A")
        {
            $logger->debug("$self->{'_sName'} - Opening file hand for appending");
            $FILE = new FileHandle(">>$self->{'_sFilename'}") || warn "Can not open " . $self->{'_sFilename'} . " for appending $!\n";
        }
        else
        {
            $logger->debug("$self->{'_sName'} - Opening file hand for reading");
            $FILE = new FileHandle("<$self->{'_sFilename'}") || warn "Can not open " . $self->{'_sFilename'} . " for reading $!\n";
        }
        $FILE->autoflush(1);
        $self->{'_oFileHandle'} = \$FILE;
        $logger->debug("$self->{'_sName'} - _oFileHandle: ${$self->{'_oFileHandle'}}");
    }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub CloseFileHandle
{
    # This method will close the file handle
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');

    if (defined $self->{'_oFileHandle'})
    {
        $logger->debug("$self->{'_sName'} - _oFileHandle: ${$self->{'_oFileHandle'}}");
        ${$self->{'_oFileHandle'}}->close;
    }
    $self->{'_oFileHandle'} = undef;
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub ReadLogFile
{
    # This method will read the current log file if it exists and we need to do this before
    # we open the standard file handle as it will be setup for writing, and this one is for reading.
    # Return:
    #   0 = nothing was read
    #   1 = a log file was read
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $retval = 0;
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    
    # If the log file is already on the system lets read its current contents in to memory
    if ((defined $self->{'_sFilename'}) && (-r $self->{'_sFilename'}))
    {
        $self->OpenFileHandle("R");
        my $FILE = ${$self->{'_oFileHandle'}};
        my @aCurrentLogData = <$FILE>;
        my @aNewLogData;
        foreach (@aCurrentLogData)
        {
            chomp();
            push(@aNewLogData,$_);
        }

        $self->{'_aCurrentLogData'} = \@aNewLogData;
        
        
        $logger->debug("$self->{'_sName'} - _aCurrentLogData: ", ${$oDebugger->DumpArray($self->{'_aCurrentLogData'})});

        # Lets capture the current log size so we have it
        $self->SetCurrentLogSize();

        $self->CloseFileHandle();
        $retval = 1;
    }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return $retval;
}

sub WriteExistingLogData
{
    # This method will write out the existing log data to the file making sure we keep in mind the
    # file lengths
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');

    $self->OpenFileHandle("W");
    my $FILE = ${$self->{'_oFileHandle'}};
    
    $logger->debug("$self->{'_sName'} - FILE: $FILE");
    
    my $iArrayOffsetNumber = 0;
    
    # If there are more lines in the log data than the max file length then we should only save so
    # many lines so lets back down from the end and set an offset from which to start so that we 
    # are not starting from array index 0. This is needed as the newest commands are at the end of 
    # the array/buffer
    if ($self->{'_iFileLength'} < $self->{'_iCurrentLogSize'})
    {
        $iArrayOffsetNumber = $self->{'_iCurrentLogSize'} - $self->{'_iFileLength'};
        $logger->debug("$self->{'_sName'} - iArrayOffsetNumber: $iArrayOffsetNumber");
    }
    
    # Since arrays start at zero, we need to minus one off the end of the History Buffer Size
    foreach ($iArrayOffsetNumber..$self->{'_iCurrentLogSize'}-1)
    {
        $logger->debug("$self->{'_sName'} - aCurrentLogData: $self->{'_aCurrentLogData'}->[$_]");
        print $FILE "$self->{'_aCurrentLogData'}->[$_]\n";
    }
    $self->CloseFileHandle();
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub ClearExistingLogData
{
    # This method will clear out all existing log data from the array_ref in memory
    my $self = shift;
    $self->{'_aCurrentLogData'} = undef;
}

return 1;
