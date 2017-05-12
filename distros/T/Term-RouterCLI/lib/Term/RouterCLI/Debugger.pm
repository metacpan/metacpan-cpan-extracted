#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Debugger                                             #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-08-24                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Debugger;

use 5.8.8;
use strict;
use warnings;
use Config::General;
use Log::Log4perl;

our $VERSION     = '1.00';
$VERSION = eval $VERSION;

our $hDebugConfig;


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

    $self->{'_iDebug'}              = 0;            # This is for internal debugger debugging
    $self->{'_sFilename'}           = undef;

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

sub StartDebugger
{
    # This method will load the log4perl configuration file
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
    my %hConfiguration = $oConfig->getall();
    $hDebugConfig = \%hConfiguration;

    Log::Log4perl::init($hDebugConfig);
}

sub ReloadDebuggerConfiguration
{
    # This method will reload the current debugger configuration that is in memory allowing us to turn
    # debugging on and off on the fly.
    my $self = shift;
    Log::Log4perl::init($hDebugConfig);
}

sub GetDebugConfig
{
    # This method will return the global object for the Debug Configuration so that it can be edited on the fly
    my $self = shift;
    return $hDebugConfig;
}

sub GetLogger
{
    # This method is a helper method to get the Log4perl logger object
    my $self = shift;
    my $object = shift;
    my $package = ref($object);
    my @data = caller(1);
    my $caller = (split "::", $data[3])[-1];
    my $sLoggerName = $package . "::" . $caller;

    print "+++ DEBUGGER +++ $sLoggerName\n" if ($self->{'_iDebug'} == 1);

    return Log::Log4perl->get_logger("$sLoggerName");
}

sub DumpArray
{
    # This method is for dumping the contents of an array
    # Required:
    #   array_ref   (array of values)
    # Return:
    #   string_ref  (data from array)
    my $self = shift;
    my $parameter = shift;
    my $sStringData = "";
    
    $sStringData .= "\t";
    foreach (@$parameter)
    {
        $sStringData .= "$_, ";
    }
    $sStringData .= "\n";
    return \$sStringData;
}

sub DumpHashKeys
{
    # This method is for dumping the contents of an array
    # Required:
    #   hash_ref   (array of values)
    # Return:
    #   string_ref  (data from array)
    my $self = shift;
    my $parameter = shift;
    my $sStringData = "";
    
    $sStringData .= "\t";
    foreach (keys(%$parameter))
    {
        $sStringData .= "$_, ";
    }
    $sStringData .= "\n";
    return \$sStringData;
}


return 1;
