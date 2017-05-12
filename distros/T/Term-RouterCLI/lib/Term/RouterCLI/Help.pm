#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Help                                                 #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Help;

use 5.8.8;
use strict;
use warnings;
use Term::RouterCLI::Debugger;
use Log::Log4perl;

use parent qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw( PrintHelp _GetCommandHelp _GetCommandSummaries _GetCommandSummary);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );
our $VERSION     = '1.00';
$VERSION = eval $VERSION;


my $oDebugger = new Term::RouterCLI::Debugger();


# ----------------------------------------
# Public Methods 
# ----------------------------------------

sub PrintHelp
{
    # This method will print out a short description or long description depending on whether 
    # or not an argument "topic" is passed in.  If there is a command argument, then we will
    # print the detailed help topics.
    # Required:
    #   array_ref ($self->{'_aCommandArguments'})
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $OUT = $self->{OUT};

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');

    # If there is an argument passed to the help function, then lets process those arguments 
    # finding the corresponding command and its help directives.  If there is no argument
    # passed in, then we will just print out all of the help summaries
    my $iNumberOfArguments =  @{$self->{'_aCommandArguments'}};
    $logger->debug("$self->{'_sName'} - ", "iNumberOfArguments: $iNumberOfArguments");
    if ($iNumberOfArguments > 0) 
    {
        $logger->debug("$self->{'_sName'} - ", "Step 2");
        my $sHelpAboutACommand = $self->_GetCommandHelp();
        $logger->debug("$self->{'_sName'} - ", "sHelpAboutACommand: $$sHelpAboutACommand");

        print $OUT $$sHelpAboutACommand;
        print $OUT "\n";
    } 
    else 
    {
        $logger->debug("$self->{'_sName'} - ", "Step 3");
        unless (exists($self->{'_hCommandDirectives'}->{cmds})) {$self->{'_hCommandTreeAtLevel'} = $self->GetFullCommandTree();}
        print $OUT $self->_GetCommandSummaries();
    }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}


# ----------------------------------------
# Private Methods 
# ----------------------------------------

sub _GetCommandHelp
{
    # This method will get the command details from the help directive 
    # Required:
    #   hash_ref ($self->{'_hCommandTreeAtLevel'})   
    #   hash_ref ($self->{'_hCommandDirectives'})
    # Return:
    #   string_ref(help details for the command in question)
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $sHelpDetails = "";

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    # Lets get the current data for the tree location that we are now at
    $self->_FindCommandInCommandTree(); 

    # If their are no command directives then lets look for a default command
    if (!$self->{'_hCommandDirectives'}) 
    {
        $logger->debug("$self->{'_sName'} - ", "Step 1");
        if (exists $self->{'_hCommandTreeAtLevel'}->{''}) { $self->{'_hCommandDirectives'} = $self->{'_hCommandTreeAtLevel'}->{''}; } 
        else 
        { 
            my ($sCommandName) = $self->_GetFullCommandName();
            $sHelpDetails = "$sCommandName doesn't exist.\n"; 
        }
    }
    else
    {
        $logger->debug("$self->{'_sName'} - ", "Step 2");
        if ($self->{display_summary_in_help}) 
        {
            my ($sCommand) = $self->_GetFullCommandName();
            $logger->debug("$self->{'_sName'} - ", "Step 2.1");
            $logger->debug("$self->{'_sName'} - ", "sCommand: $sCommand");

            # We need to take in to account if the desc or help is not in the translated lanugage pack
            if (exists($self->{'_hCommandDirectives'}->{'desc'}) && (defined $self->{'_hCommandDirectives'}->{'desc'})) 
            {
                $sHelpDetails = "$sCommand: " . $self->{'_hCommandDirectives'}->{'desc'} . "\n"; 
            } 
            else { $sHelpDetails = "$sCommand: Command description not found\n"; }
        }
        
        if (exists($self->{'_hCommandDirectives'}->{'help'}) && (defined $self->{'_hCommandDirectives'}->{'help'})) 
        { 
            $sHelpDetails .= $self->{'_hCommandDirectives'}->{'help'}; 
            $sHelpDetails .= "\n";
        } 
        else { $sHelpDetails = "No additional help found\n"; }

        if ($self->{'display_subcommands_in_help'} && exists($self->{'_hCommandDirectives'}->{'cmds'})) 
        { 
            $sHelpDetails .= "\nSubcommands available:\n";
            $sHelpDetails .= $self->_GetCommandSummaries(); 
        }
    }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return \$sHelpDetails;
}

sub _GetCommandSummaries
{
    # This method will return the command summaries for all commands at the current level of a command tree
    # Required:
    #   hash_ref ($self->{'_hCommandTreeAtLevel'}) 
    # Optional:
    #   array_ref (commands)
    my $self = shift;
    my $aCommands = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    
    # This was added to support "?" mark tab completion when there is nothing yet entered on the command prompt
    unless (exists $aCommands->[0]) 
    {
        unless ( defined $self->{'_hCommandTreeAtLevel'} ) { $self->{'_hCommandTreeAtLevel'} = $self->GetCurrentCommandTree(); }
        foreach (sort(keys(%{$self->{'_hCommandTreeAtLevel'}})))
        {
            push @$aCommands, $_;
        }
    }

    $logger->debug("$self->{'_sName'} - ", "_hCommandTreeAtLevel: ", ${$oDebugger->DumpHashKeys($self->{'_hCommandTreeAtLevel'})});
    $logger->debug("$self->{'_sName'} - ", "aCommands: ", ${$oDebugger->DumpArray($aCommands)});    

    my $sAllCommandSummaries = "";

    # We need to push values in to this string for the following use cases:
    # 1) There is a code directive found on the command, meaning it can be ran by itself
    #    ()example "show interface" and "show interface brief")
    # 2) An actual argument is possible, we should print out some helper text so that the user will know what
    #    they should be entering
    
    if ( exists $self->{'_hCommandDirectives'}->{'maxargs'} && $self->{'_hCommandDirectives'}->{'maxargs'} >= 1 ) 
    {
        my $sArgDescription = "unknown";
        if (exists $self->{'_hCommandDirectives'}->{'argdesc'} && defined $self->{'_hCommandDirectives'}->{'argdesc'}) { $sArgDescription = $self->{'_hCommandDirectives'}->{'argdesc'}; } 
        $sAllCommandSummaries .= sprintf("  %-20s $sArgDescription\n", "WORD"); 
    }
    
    foreach (sort(@$aCommands)) 
    {
        # We now exclude synonyms from the command summaries.
        next if exists $self->{'_hCommandTreeAtLevel'}->{$_}->{'alias'} || exists $self->{'_hCommandTreeAtLevel'}->{$_}->{'syn'};
        # Lets not show the default command in any summaries
        next if $_ eq '';
        # Lets not show "hidden" options in any summaries
        next if exists $self->{'_hCommandTreeAtLevel'}->{$_}->{'hidden'};

        $sAllCommandSummaries .= $self->_GetCommandSummary("$_");
    }
    if ( exists $self->{'_hCommandDirectives'}->{'code'} ) { $sAllCommandSummaries .= sprintf("  %-20s\n", "<cr>"); }

    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return $sAllCommandSummaries;
}

sub _GetCommandSummary
{
    # This method returns the command summary for a specific command at a certain command tree level
    # Required:
    #   hash_ref ($self->{'_hCommandTreeAtLevel'})
    #   string (command name)
    # Return:
    #   string (command summary line)
    my $self = shift;
    my $sCommandName = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $sCommandSummary;

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    $sCommandSummary = $self->{'_hCommandTreeAtLevel'}->{$sCommandName}->{'desc'} || "(no description)";
    
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return sprintf("  %-20s $sCommandSummary\n", $sCommandName);
}

return 1;
