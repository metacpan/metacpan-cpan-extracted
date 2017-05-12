#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Languages                                            #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Languages;

use 5.8.8;
use strict;
use warnings;
use parent qw(Term::RouterCLI::Base);
use Term::RouterCLI::Config;
use Term::RouterCLI::Debugger;
use Log::Log4perl;

our $VERSION     = '1.00';
$VERSION = eval $VERSION;


sub _init
{
    my $self = shift;
    my %hParameters = @_;

    $self->{'_hValidLanguages'}   = { 'en_us' => 1, 'fr' => 1 };
    $self->{'_sDirectoryTree'}    = undef;

    # Lets overwrite any defaults with values that are passed in
    if (%hParameters)
    {
        foreach (keys (%hParameters)) { $self->{$_} = $hParameters{$_}; }
    }
    $self->_initDebugger();
    $self->_initConfig();
}



# ----------------------------------------
# Public Methods
# ----------------------------------------
sub GetLanguageDirectory
{
    # This method will return the current language directory as defined in the configuration file
    my $self = shift;
    my $config = $self->{_oConfig}->GetRunningConfig();
    
    my $slangDir = './lang/';
    
    if (exists $config->{'system'}->{'language_directory'}) 
    { 
        $slangDir = $config->{'system'}->{'language_directory'};
    }
    return ($slangDir);
}

sub SetLangDirectory
{
    # this method will change the language directory field in the configuration data hash
    # Required:
    #   string (directory path, full or relative)
    my $self = shift;
    my $parameter = shift;
    my $logger = $self->{_oDebugger}->GetLogger($self);
    my $config = $self->{_oConfig}->GetRunningConfig();
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    $logger->debug("$self->{'_sName'} - Current Language Directory is: $config->{system}->{language_directory}");
    $logger->debug("$self->{'_sName'} - New Language Directory is: $parameter");

    unless (defined $parameter) { return; }
    $parameter = $self->_ExpandTildes($parameter);
    $config->{system}->{language_directory} = $parameter;

    $logger->debug("$self->{'_sName'} - Directory is now: $config->{system}->{language_directory}");
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub AddValidLanguage
{
    # This method will add a valid language to lists
    # Required:
    #   hash_ref (valid languages where keys are ISO values)
    my $self = shift;
    my $hParameter = shift;
    my $logger = $self->{_oDebugger}->GetLogger($self);
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    foreach (keys (%$hParameter)) { $self->{'_hValidLanguages'}->{$_} = $hParameter->{$_}; }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub SetLanguage
{
    # This method will set the current language
    my $self = shift;
    my $lang = shift;
    my $logger = $self->{_oDebugger}->GetLogger($self);
    my $config = $self->{_oConfig}->GetRunningConfig();

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    $logger->debug("$self->{'_sName'} - ", "lang: $lang");
    $logger->debug("$self->{'_sName'} - ", "_hValidLanguages:\n", ${$self->{_oDebugger}->DumpHashKeys($self->{'_hValidLanguages'})});        

    $logger->debug("$self->{'_sName'} - ", "recieved lang: $lang");
    
    # If the language is not found for this parameter, then lets reset to US english
    unless (exists ($self->{'_hValidLanguages'}->{$lang})) { $lang = "en_us"; }
    $logger->debug("$self->{'_sName'} - ", "using lang: $lang");
    
    $config->{'language'} = $lang;
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub LoadStrings
{
    # This method is for loading all of the strings based on language from the configuration file
    # Required:
    #   string (name of directory that holds languages file for this command tree)
    # Return:
    #   hash_ref (hash of strings)
    my $self = shift;
    my $sTree = shift;
    my $logger = $self->{_oDebugger}->GetLogger($self);
    my $config = $self->{_oConfig}->GetRunningConfig();
    
    # Lets add the directory tree to the object so we can use it again later with a reload strings method
    $self->{'_sDirectoryTree'} = $sTree;
    
    my $sLang;

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    
    my $sBaseLangDir = $self->GetLanguageDirectory();
    if (exists $config->{'language'}) 
    { 
        $sLang = $config->{'language'}; 
        $logger->debug("$self->{'_sName'} - ", "Using language: $sLang");
    }
    else 
    { 
        $logger->debug("$self->{'_sName'} - ", "Language not found, reverting to en_us");
        $sLang = "en_us"; 
    }
    
    # If the language file does not yet exist, then lets return an empty hash
    unless (-r "$sBaseLangDir/$sTree/$sLang.lang") 
    {
        $logger->debug("$self->{'_sName'} - ", "Language file $sBaseLangDir/$sTree/$sLang.lang does not exist, returning");
        return {};
    }
    
    my $sFullFilename = "$sBaseLangDir/$sTree/$sLang.lang";
    my $hLanguageSpecificStrings;

    $logger->debug("$self->{'_sName'} - ", "sFullFilename: $sFullFilename");
    
    if (-r $sFullFilename)
    {
        $logger->debug("$self->{'_sName'} - ", "Reading from file: $sFullFilename");
        my $oStrings = new Config::General
        (
            -ConfigFile => "$sFullFilename",
            -LowerCaseNames => 1,
            -MergeDuplicateOptions => 1,
            -AutoTrue => 0,
            -ExtendedAccess => 1,
            -UTF8 => 1
        ); 
        # By using the getall function, we limit the IO calls to the configuration file and get all of the data at once
        my %hAllSavedStrings = $oStrings->getall();
        $hLanguageSpecificStrings = $hAllSavedStrings{$sLang};        
    }
    else { $logger->debug("$self->{'_sName'} - ", "Could not find file to read from"); }
    
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return $hLanguageSpecificStrings;
}

sub ReloadStrings
{
    # This method is just a helper method for LoadStrings
    my $self = shift;
    $self->LoadStrings("$self->{'_sDirectoryTree'}");
}

return 1;

