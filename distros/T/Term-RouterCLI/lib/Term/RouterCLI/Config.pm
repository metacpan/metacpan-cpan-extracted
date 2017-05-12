#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Config                                               #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Config;

use 5.8.8;
use strict;
use warnings;
use Term::RouterCLI::Debugger;
use Config::General();
use File::Copy;
use Log::Log4perl;

our $VERSION     = '1.00';
$VERSION = eval $VERSION;

our $hRunningConfig;
our $hStartupConfig;
my $oDebugger = new Term::RouterCLI::Debugger();


sub new
{
    my $pkg = shift;
    my $class = ref($pkg) || $pkg;  
    
    my $self = {};
    $self->{'_sName'}                 = $pkg;        # Lets set the object name so we can use it in debugging
    bless ($self, $class);

    # Lets send any passed in arguments to the _init method
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self = shift;
    my %hParameters = @_;

    $self->{'_sFilename'}               = undef;
    
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
sub SetFilename 
{ 
    # This method is for setting the filename for the configuration file
    # Required:
    #   string(file name)
    my $self = shift;
    my $parameter = shift;
    if (defined $parameter) { $self->{'_sFilename'} = $parameter; }
}

sub LoadConfig
{
    # This method will load the current configuration in to a hash that can be used
    my $self = shift;

    my $oConfig = new Config::General
    (
        -ConfigFile => "$self->{'_sFilename'}",
        -LowerCaseNames => 0,
        -MergeDuplicateOptions => 1,
        -AutoTrue => 0,
        -ExtendedAccess => 1,
        -SaveSorted => 1
    );
    
    # Lets get all of the configuration in one pass to save disk IO then lets save the data in to the object 
    my %hStartupConfiguration = $oConfig->getall();
    my %hRunningConfiguration = %hStartupConfiguration;
    $hStartupConfig = \%hStartupConfiguration;
    $hRunningConfig = \%hRunningConfiguration;
}

sub GetStartupConfig
{
    # This method will return the global object for the Startup Configuration
    my $self = shift;
    return $hStartupConfig;
}

sub GetRunningConfig
{
    # This method will return the global object for the Running Configuration
    my $self = shift;
    return $hRunningConfig;
}

sub ReloadConfig
{
    # This method will reload the current configuration
    my $self = shift;
    
    $hStartupConfig = undef;
    $hRunningConfig = undef;
    $self->LoadConfig();
}

sub SaveConfig
{
    # This method will save out the hash of the configuration back to the same file.  It will make a backup first
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');

    # Backup configuration first
    $self->BackupConfig();
    
    my $oConfig = new Config::General
    (
        -ConfigFile => "$self->{'_sFilename'}",
        -LowerCaseNames => 0,
        -MergeDuplicateOptions => 1,
        -AutoTrue => 0,
        -ExtendedAccess => 1,
        -SaveSorted => 1
    );
    
    # Save current configuration
    $oConfig->save_file("$self->{'_sFilename'}", $hRunningConfig);
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub BackupConfig
{
    # This method will make a backup of the current configuration file
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');    
    my $sOriginalFile = $self->{'_sFilename'};
    my $sBackupFile = $self->{'_sFilename'} . ".bak";
    copy ($sOriginalFile, $sBackupFile);
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

return 1;
