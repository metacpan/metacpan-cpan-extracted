#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term                                                 #
# Class:       RouterCLI                                            #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# This class is a fork and major rewrite of Term::ShellUI v0.98     #
# which was written by Scott Bronson.                               #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI;

use 5.8.8;
use strict;
use warnings;
use parent qw(Term::RouterCLI::Base);

use Term::RouterCLI::Debugger;
use Term::RouterCLI::Auth;
use Term::RouterCLI::Log::History;
use Term::RouterCLI::Log::Audit;
use Term::RouterCLI::Config;
use Term::RouterCLI::CommandTree qw(:all);
use Term::RouterCLI::Help qw(:all);
use Term::RouterCLI::Prompt qw(:all);

use Term::ReadLine();
use Text::Shellwords::Cursor;
use Config::General;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Env qw(SSH_TTY);
use Log::Log4perl;

our $VERSION     = '1.00';
$VERSION = eval $VERSION;


my $oDebugger = new Term::RouterCLI::Debugger();
my $oConfig = new Term::RouterCLI::Config();


sub _init    
{
    my $self = shift;
    my %hParameters = @_;
    
    # Application data
    $self->{_sConfigFilename}                   = './etc/RouterCLI.conf';
    $self->{_sDebuggerConfigFilename}           = './etc/log4perl.conf';
    $self->{_sCurrentPrompt}                    = "Router> ";
    $self->{_sCurrentPromptLevel}               = '> ';
    $self->{_sActiveLoggedOnUser}               = "";
    $self->{_sTTYInUse}                         = "localhost";
    $self->{_iExit}                             = 0;
    $self->{OUT}                                = undef;

    # Options
    $self->{blank_repeats_cmd}                  = 0;
    $self->{backslash_continues_command}        = 1;        # This allows commands to be entered across multiple lines
    $self->{display_summary_in_help}            = 1;
    $self->{display_subcommands_in_help}        = 1;
    $self->{suppress_completion_escape}         = 0;

    # Text::Shellwords::Cursor module options
    $self->{_sTokenCharacters}                  = '';
    $self->{_iKeepQuotes}                       = 1;

    # Lets overwrite any defaults with values that are passed in
    if (%hParameters)
    {
        foreach (keys (%hParameters)) { $self->{$_} = $hParameters{$_}; }
    }

    # We need to make sure the debugger always starts, and starts really before everything else 
    # so lets start it here in the _init script
    $oDebugger->SetFilename( $self->{_sDebuggerConfigFilename} );
    $oDebugger->StartDebugger();

    # Load the current configuration in to memory, this has to be done before we load command trees
    $oConfig->SetFilename( $self->{_sConfigFilename} );
    $oConfig->LoadConfig();


    # Objects
    $self->{_oAuditLog}                         = new Term::RouterCLI::Log::Audit(   _oParent => $self, _sFilename => './logs/.cli-auditlog' );
    $self->{_oHistory}                          = new Term::RouterCLI::Log::History( _oParent => $self, _sFilename => './logs/.cli-history' );
    $self->{_oTerm}                             = new Term::ReadLine("$0");
    $self->{_oParser} = Text::Shellwords::Cursor->new(
        token_chars => $self->{_sTokenCharacters},
        keep_quotes => $self->{_iKeepQuotes},
        debug => 0,
        error => sub { shift; $self->error(@_); },
        );

    # Create object for terminal and define some initial values
    $self->{_oTerm}->MinLine(0);
    $self->{_oTerm}->parse_and_bind("\"?\": complete");
    $self->{_oTerm}->Attribs->{completion_function} = sub { _CompletionFunction($self, @_); };
    $self->SetOutput("term");

    # Setup Data structure
    $self->{_hFullCommandTree}                  = undef;    # Full command tree for active session
    $self->RESET();

    # Lets capture the tty that they used to connected to the CLI
    if (defined $SSH_TTY) { $self->{_sTTYInUse} = $SSH_TTY; }
}

sub RESET
{
    # This method will reset the data structure
    my $self = shift;
    # Data structure
    $self->{_hCommandTreeAtLevel}               = undef;    # Command tree at current level for searching for a command
    $self->{_hCommandDirectives}                = undef;    # Directives of command found at deepest level
    $self->{_aFullCommandName}                  = undef;    # Full name of deepest command
    $self->{_aCommandArguments}                 = undef;    # All remaining arguments once command is determined

    # Data structure helper values
    $self->{_sStringToComplete}                 = "";       # The exact string that needs to be tab completed
    $self->{_sCompleteRawline}                  = "";       # Pre-tokenized command line
    $self->{_iStringToCompleteTextStartPosition} = 0;       # Position in _sCompleteRawline of the start of _sStringToComplete
    $self->{_iCurrentCursorLocation}            = 0;        # Position in _sCompleteRawline of the cursor (end of _sStringToComplete)
    $self->{_aCommandTokens}                    = undef;    # Tokenized command-line
    $self->{_iTokenNumber}                      = 0;        # The index of the token containing the cursor
    $self->{_iTokenOffset}                      = 0;        # the character offset of the cursor in $tokno.
    $self->{_iArgumentNumber}                   = 0;        # The argument number containing the cursor
    $self->{_iNumberOfContinuedLines}           = 0;        # The number of lines that have been entered in wrapped line continue mode
    $self->{_sPreviousCommand}                  = ""; 
}


# ----------------------------------------
# Public Convenience Methods
# ----------------------------------------
sub EnableAuditLog          { shift->{_oAuditLog}->Enable();            }
sub DisableAuditLog         { shift->{_oAuditLog}->Disable();           }
sub SetAuditLogFilename     { shift->{_oAuditLog}->SetFilename(@_);     }
sub SetAuditLogFileLength   { shift->{_oAuditLog}->SetFileLength(@_);   }

sub EnableHistory           { shift->{_oHistory}->Enable();             }
sub DisableHistory          { shift->{_oHistory}->Disable();            }
sub SetHistoryFilename      { shift->{_oHistory}->SetFilename(@_);      }
sub SetHistoryFileLength    { shift->{_oHistory}->SetFileLength(@_);    }
sub PrintHistory            { shift->{_oHistory}->PrintHistory(@_);     }



# ----------------------------------------
# Public Methods
# ----------------------------------------
sub SaveConfig 
{
    # This method is used for saving the current running configuration
    my $self = shift;
    $oConfig->SaveConfig();
}

sub ClearScreen
{
    # This method will clear the screen from all login information
    my $self = shift;
    print `clear`;
}

sub PrintMOTD
{
    # This method will print out a welcome message
    my $self = shift;
    my $config = $oConfig->GetRunningConfig();
    print "\n\n$config->{motd}->{text}\n";
}

sub SetHostname
{
    # This method will set the hostname
    my $self = shift;
    my $parameter = shift;
    my $config = $oConfig->GetRunningConfig();
    
    unless (defined $parameter) { $parameter = $self->{_aCommandArguments}->[0]; }
    $config->{hostname} = $parameter;
    # When ever the hostname is changes, we need to refresh the prompt
    $self->SetPrompt($parameter);
}

sub StartCLI
{
    # This method will start the actual processing of the CLI
    my $self = shift;
    my $config = $oConfig->GetRunningConfig();
    $self->{_oAuditLog}->StartAuditLog() if ($self->{_oAuditLog}->{_bEnabled} == 1 );
    
    unless (defined $self->{_hFullCommandTree}) { die "Please load an initial command tree\n"; }
    
    # Set prompt from configuration file
    $self->ClearPromptOrnaments();
    $self->SetPrompt($config->{hostname});
    
    
    # Load the previous command history in to memory
    $self->{_oHistory}->LoadCommandHistoryFromFile() if ($self->{_oHistory}->{_bEnabled} == 1 );

    while($self->{_iExit} == 0) 
    {
        $self->_ProcessCommands();
    }
    
    # Close AuditLog and save command History
    $self->{_oHistory}->SaveCommandHistoryToFile() if ($self->{_oHistory}->{_bEnabled} == 1 );
    $self->{_oHistory}->CloseFileHandle();
    $self->{_oAuditLog}->CloseFileHandle();
}

sub SetOutput
{
    # This method will define where the output goes
    # Required:
    #   string (term/stdout)
    my $self = shift;
    my $parameter = shift || "";
    if ($parameter eq "term") {$self->{OUT} = $self->{_oTerm}->OUT || \*STDOUT;}
    else { $self->{OUT} = \*STDOUT; }
}

sub Exit 
{ 
    # This method will cause the CLI to exit
    shift->{_iExit} = 1; 
}

sub PreventEscape
{
    # This method will capture the various signals and prevent termination and esacpe through control characters
    # Turn off the following CTRLs
    my $self = shift;
    $self->{_oTerm}->Attribs->{'catch_signals'} = 0;
    system("stty eof \"?\"");    # CTRL-D
    $SIG{"INT"}  = 'IGNORE';     # CTRL-C
    $SIG{"TSTP"} = 'IGNORE';     # CTRL-Z
    $SIG{"QUIT"} = 'IGNORE';     # CTRL-\
    $SIG{"TERM"} = 'IGNORE';
    $SIG{"ABRT"} = 'IGNORE';
    $SIG{"SEGV"} = 'IGNORE';
    $SIG{"ILL"} = 'IGNORE';
}

sub TabCompleteArguments
{
    # This method will provide tab completion for the "help" arguments and "no" arguments
    # Required:
    #   hash_ref (full data structure)
    my $self = shift;

    # Lets backup the data structure before we run the _CompleteFunction again
    my $sStringToCompleteBackup = $self->{_sStringToComplete};
    my $sCompleteRawlineBackup = $self->{_sCompleteRawline};
    my $aFullCommandNameBackup = $self->{_aFullCommandName};
    my $hCommandTreeAtLevelBackup = $self->{_hCommandTreeAtLevel};
    my $hCommandDirectivesBackup = $self->{_hCommandDirectives};
    
    my ($sArgsToComplete) = $self->_GetFullArgumentsName();
    $self->_CompletionFunction("NONE", $sArgsToComplete) unless ($sArgsToComplete eq "");

    # Lets grab what came back, which is really arguments, and put it in the arguments array
    $self->{_aCommandArguments} = $self->{_aFullCommandName};
    
    # Lets now restore the command name from the beginning along with the command directives
    $self->{_sStringToComplete} = $sStringToCompleteBackup;
    $self->{_sCompleteRawline} = $sCompleteRawlineBackup;
    $self->{_aFullCommandName} = $aFullCommandNameBackup;
    $self->{_hCommandTreeAtLevel} = $hCommandTreeAtLevelBackup;
    $self->{_hCommandDirectives} = $hCommandDirectivesBackup;

    # TODO look at this and see if I need it
    # without this we'd complete with $shCommandTreeAtLevel for all further args
    #return [] if $self->{_iArgumentNumber} >= @{$self->{_aFullCommandName}};
}

sub error
{
    my $self = shift;
    print STDERR @_;
}





# ----------------------------------------
# Private Methods 
# ----------------------------------------
sub _ProcessCommands
{
    # This method prompts for and returns the results from a single command. Returns undef if no command was called.
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $config = $oConfig->GetRunningConfig();
    
    # Before we get started, lets clear out the data structure from the last command we processed
    $self->RESET();    

    my $iSaveToHistory = 1;
    my $sPrompt;

    my $OUT = $self->{'OUT'};

	
	# Setup an infinte loop to catch all of the commands entered on the console makeing sure
	# to watch for "\" continue to next line characters
	for(;;) 
	{
		$sPrompt = $self->GetPrompt();

        # This next command is where we jump to the _CompletionFunction method and it does not come
        # back to this fucntion until the enter key is pressed
        # TODO we need to make sure the readline is returning a valid option with "?" is pressed
		my $sNewline = $self->{_oTerm}->readline($sPrompt);
		
		if (defined $sNewline)
		{
            $logger->debug("$self->{'_sName'} - Newline returned from readline: $sNewline");    
		}

        # In the off chance that the readline module does not return anything, lets just print a new line and go on.
        unless (defined $sNewline) 
        {
            if (!exists $self->{_aFullCommandName}->[0] || $self->{_aFullCommandName}->[0] eq "")
            {
                # Print out possible options for the matches that were found. This was added once 
                # "?" based completion was added
                print $OUT "\n";
                print $OUT $self->_GetCommandSummaries();
    
                # We need to redraw the prompt and command line options since we are going to output text via _GetCommandSummaries
                $self->{_oTerm}->rl_on_new_line();
                return;            
            }
            else 
            {
                print $OUT "\n";
                $self->{_oTerm}->rl_on_new_line();
                return;
            }
        }

        # If there is any white space at the start or end of the command lets remove it just to be safe 
        $sNewline =~ s/^\s+//g;  
        $sNewline =~ s/\s+$//g;


        # Search for a "\" at the end as a continue character and remove it along with any white space
        # if one was found lets set bContinued to TRUE so we know that we need more commands.  Lets
        # also keep track of the number of lines that are continued.  This makes the logic easier down
        # below.
        my $bContinued = 0;
        if ($self->{backslash_continues_command} == 1)
        {
            $bContinued = ($sNewline =~ s/\s*\\$/ /);
            if ($bContinued == 1) { $self->{_iNumberOfContinuedLines} = $self->{_iNumberOfContinuedLines} + $bContinued; }
        }
        
        
        $logger->debug("$self->{'_sName'} - _iNumberOfContinuedLines: $self->{_iNumberOfContinuedLines}");
        $logger->debug("$self->{'_sName'} - bContinued: $bContinued");

        # Lets concatenate the lines together to form a single command
        if (($self->{backslash_continues_command} == 1) && ($self->{_iNumberOfContinuedLines} > 0))
        {
            $self->{_sCompleteRawline} = $self->{_sCompleteRawline} . $sNewline;
            if ($bContinued == 1) { next; }
        }
        else { $self->{_sCompleteRawline} = $sNewline; }

        # This will allow us to enter partial commands on the command line and have them completed
        $logger->debug("$self->{'_sName'} - _sCompleteRawline: $self->{_sCompleteRawline}");
        $self->_CompletionFunction("NONE", $self->{_sCompleteRawline}, "0") unless ($self->{_sCompleteRawline} eq ""); 
        last; 
	} 

    # Is this a blank line?  If so, then we might need to repeat the last command
    if ($self->{_sCompleteRawline} =~ /^\s*$/) 
    {
        if ($self->{blank_repeats_cmd} && $self->{_sPreviousCommand} ne "") 
        {
            $self->{_oTerm}->rl_forced_update_display();
            print $OUT $self->{_sPreviousCommand};
            $self->_CompletionFunction("NONE", $self->{_sPreviousCommand}); 
        }
        else { $self->{_sCompleteRawline} = undef; }
        return unless ((defined $self->{_sCompleteRawline}) && ($self->{_sCompleteRawline} !~ /^\s*$/));
    }

    my $sCommandString = undef;

    if (exists $self->{_aFullCommandName}) 
    {
        my ($sCommandName) = $self->_GetFullCommandName();
        my ($sCommandArgs) = $self->_GetFullArgumentsName();
        $sCommandString = $sCommandName . $sCommandArgs;

        $self->_RunCodeDirective();


        # TODO we need to make sure that sub commands can inherit the hidden flag from the parent
        # If the command has an exclude from history or hidden option attached to it, lets NOT record it in the history file
		if (exists $self->{_hCommandDirectives}->{exclude_from_history} || exists $self->{_hCommandDirectives}->{hidden}) 
		{
			$iSaveToHistory = 0;
		}
    }

    # Add to history unless it's a dupe of the previous command.
	if (($iSaveToHistory == 1) && ($sCommandString ne $self->{_sPreviousCommand}) && ($self->{_oHistory}->{_bEnabled} == 1 ))
	{
		$self->{_oTerm}->addhistory($sCommandString);
	}
    $self->{_sPreviousCommand} = $sCommandString;
    

    
    # Lets save the typed in command to the audit log if the audit log is enabled and after the 
    # commands have been tab completed
    if ($self->{_oAuditLog}->{_bEnabled} == 1) 
    {
        my $hAuditData = { "username" => $self->{_sActiveLoggedOnUser}, "tty" => $self->{_sTTYInUse}, "prompt" => $sPrompt, "commands" => $sCommandString};
        $self->{_oAuditLog}->RecordToLog($hAuditData); 
    }
    
    # TODO build a logger that all of this will go in to
    # TODO add support to send history to RADIUS in the form of RADIUS account records
    # TODO add support for sending history to syslog server
#    if (($iSaveToHistory == 1) && ($config->{syslog} == 1))
#    {
#        setlogsock('udp');
#        $Sys::Syslog::host = $config->{syslog_server};
#        my $sTimeStamp = strftime "%Y-%b-%e %a %H:%M:%S", localtime;  # I removed the use POSIX that imported the strftime function
#        openlog("RouterCLI", 'ndelay', 'user');
#        syslog('info', "($sTimeStamp) \[$sPrompt\] $sCommandString");
#        closelog;
#    }

    return;
}

sub _GetFullCommandName
{
    # This method will take in an array reference of the commands and return a single string value and the 
    # length of the string as an array
    # Required:
    #   $self->{_aFullCommandName} array_ref (commands typed in on the CLI)
    # Return:
    #   string  (full command name)
    #   int     (length of command name)
    my $self = shift;
    my $sCommandName = join(" ", @{$self->{_aFullCommandName}});
    $sCommandName = $sCommandName . " ";
    $sCommandName =~ s/^\s+//g;
    my $iCommandLength = length($sCommandName);
    return ($sCommandName, $iCommandLength);
}

sub _GetFullArgumentsName
{
    # This method will take in an array reference of the command arguments and return a single string value
    # and the length of the string as an array
    # Required:
    #   $self->{_aCommandArguments} array_ref (command arguments typed in on the CLI)
    # Return:
    #   string  (full command argument name minus the space at the end as you want to leave the cursor at the end)
    #   int     (length of argument name)
    my $self = shift;
    my $sArgumentName = join(" ", @{$self->{_aCommandArguments}});
    $sArgumentName =~ s/^\s+//g;
    my $iArgumentNameLength = length($sArgumentName);
    return ($sArgumentName, $iArgumentNameLength);
}

sub _FindCommandInCommandTree
{
    # This method will attempt to looks up the supplied commands from the $self->{_aCommandTokens}
    # array_ref in the command tree hash.  It will follows all synonyms and subcommands in an effort 
    # to find the command that the user typed in.  After it finds all of the commands it can
    # find, it will store the remaining data in to the _aCommandArgument array.
    # Required:
    #   hash_ref    $self->{_hCommandTreeAtLevel} (command tree)
    #   array_ref   $self->{_aCommandTokens} (typed in commands/tokens) these have already been 
    #               split on whitespace by Text::Shellwords::Cursor
    #
    # Variables set in the object:
    #   _hCurrentCommandTreeAtLevel:    The deepest command tree set found.  Always returned.
    #   _hCommandDirectives:            The command directives hash for the command.  Sets an empty hash if 
    #                                   no command was found.
    #   _aFullCommandName:              The full name of the command.  This is an array of tokens,
    #                                   i.e. ('show', 'info').  Returns as deep as it could find commands.  
    #   _aCommandArguments:             The command's arguments (all remaining tokens after the command is found).

    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
   
    my $aCommandTokens      = $self->{_aCommandTokens};
    my $hCommandTree        = $self->GetFullCommandTree();
    my $hCommandDirectives  = undef;
    my $iCurrentToken       = 0;
    my $iNumberOfTokens     = @$aCommandTokens;
    my @aFullCommandName;
    my @aCommandArguments;


    $logger->debug("$self->{'_sName'} - --DEBUG FIND 0-- Initial variable values");
    $logger->debug("$self->{'_sName'} - \thCommandTree: ", ${$oDebugger->DumpHashKeys($hCommandTree)});
    $logger->debug("$self->{'_sName'} - \taCommandTokens: ", ${$oDebugger->DumpArray($aCommandTokens)});
    $logger->debug("$self->{'_sName'} - \tiCurrentToken: $iCurrentToken");
    $logger->debug("$self->{'_sName'} - \tiNumberOfTokens: $iNumberOfTokens\n");

    foreach my $sToken (@$aCommandTokens)
    {
        # If the user has already gone beyond the number of args, then lets not complete and lets return 
        # an empty array so that things stop
        # TODO write a unit test for this and we need to figure out how to track if the show has a maxargs of 3 but
        # int does not a maxargs entry.
#        my $iMaxArgCheck = 0;
#        my $iCurrentTokenInMaxArgCheck = $iCurrentToken;
#        foreach (@$aCommandTokens)
#        {
#            $iMaxArgCheck = 1 if ((exists($self->{hCommandTree}->{$_}->{maxargs})) && ($iCurrentTokenInMaxArgCheck >= $self->{hCommandTree}->{$_}->{maxargs}));
#            $iCurrentTokenInMaxArgCheck--;
#        }
#        $logger->debug("$self->{'_sName'} - Maximum argument limit reached for token: $sToken'}");
#        last if ($iMaxArgCheck == 1);

        $logger->debug("$self->{'_sName'} - --DEBUG FIND 1--");
        $logger->debug("$self->{'_sName'} - \tWorking with token ($iCurrentToken): $sToken");
        
        # If the token is NOT currently found then it might be a partial command or an abbreviation
        # so let try and expand the token if we can with what we know.  
        my @aAllCommandsAtThisLevel;
        my @aCommandsAtThisLevel;
        my $iNumberOfCommandMatches = 0;
        if (!exists $hCommandTree->{$sToken})
        {
            @aAllCommandsAtThisLevel = keys(%$hCommandTree);
           
            $logger->debug("$self->{'_sName'} - --DEBUG FIND 2--");
            $logger->debug("$self->{'_sName'} - \taAllCommandsAtThisLevel: ", ${$oDebugger->DumpArray(\@aAllCommandsAtThisLevel)});
            
            # We need to grab just the command in this list that match the data/token that was typed in on the command line
            @aAllCommandsAtThisLevel = grep {/^$sToken/} @aAllCommandsAtThisLevel;

            $logger->debug("$self->{'_sName'} - \taAllCommandsAtThisLevel: ", ${$oDebugger->DumpArray(\@aAllCommandsAtThisLevel)});


            # We need to stip out any commands that are "hidden" so they do not mess up the tab completion by the system
            # thinking there is more options at that level then there really is. 
            foreach (@aAllCommandsAtThisLevel)
            {
                unless (exists $hCommandTree->{$_}->{hidden})
                {
                    push(@aCommandsAtThisLevel, $_);
                }
            }
           
            $logger->debug("$self->{'_sName'} - \taCommandsAtThisLevel: ", ${$oDebugger->DumpArray(\@aCommandsAtThisLevel)});
           
            # If there is only one option in the array, then it must be the right one.  If not
            # then we have an ambiguous command situation.  Also we need to make sure that the
            # command is not set be excluded from completion or flagged as hidden.
            $iNumberOfCommandMatches = @aCommandsAtThisLevel;
            $logger->debug("$self->{'_sName'} - \tiNumberOfCommandMatches: $iNumberOfCommandMatches");
            if (($iNumberOfCommandMatches == 1) && (!exists ($hCommandTree->{$aCommandsAtThisLevel[0]}->{exclude_from_completion})) && (!exists ($hCommandTree->{$aCommandsAtThisLevel[0]}->{hidden}))) 
            {
                $logger->debug("$self->{'_sName'} - \tSetting sToken to $aCommandsAtThisLevel[0]");
                $sToken = $aCommandsAtThisLevel[0]; 
            }
        }
        
        # Lets loop through all synonyms to find the actual command and then update the token
        while (exists($hCommandTree->{$sToken}) && exists($hCommandTree->{$sToken}->{'alias'})) 
        {
            $logger->debug("$self->{'_sName'} - --DEBUG FIND 3--");
            $logger->debug("$self->{'_sName'} - \tChecking aliases");
            $sToken = $hCommandTree->{$sToken}->{'alias'};
        }
        
        # If the command exists we need to capture the current directives for it and we need to add
        # the command to the aFullCommandName array.  If it does not exist, then we should put the 
        # remaining arguments in the aCommandArgument array and return.  This first one will also
        # match a blank line entered if a default command is enabled.  So we need to watch for that
        # when the rest of the default commands will match in the else statement below.
        if (exists $hCommandTree->{$sToken} )
        {
            $logger->debug("$self->{'_sName'} - --DEBUG FIND 4--");
            $logger->debug("$self->{'_sName'} - \tCommand $sToken found");

            $hCommandDirectives = $hCommandTree->{$sToken};
            push(@aFullCommandName, $sToken);
            
            # We need to zero out the hCommandTree if their is no subcommands so that we do not get 
            # in to a state where we can continue completing the last command over and over again.
            # Example: 'sh'<TAB> 'hist'<TAB> 'hist'<TAB>
            if (exists($hCommandDirectives->{cmds})) { $hCommandTree   = $hCommandDirectives->{cmds}; }
            elsif ($sToken eq "") { }
            else { $hCommandTree   = {}; }
        }
        else 
        {
            # Lets check to see if the command is a default command.  Which means if they typed in 
            # something that was not found in the command list, then there should be no _hCommandDirectives.  
            # But we also need to make sure that a default command option was defined in the configuration file
            if (!defined $hCommandDirectives && exists $hCommandTree->{''} && $iNumberOfCommandMatches < 1) 
            {
                $logger->debug("$self->{'_sName'} - --DEBUG FIND 5--");
                $logger->debug("$self->{'_sName'} - \tDefault command found");

                $hCommandDirectives = $hCommandTree->{''};
                push(@aFullCommandName, $sToken);

                # Since we are using the active token as a command, a default command, then lets not include that
                # in the arguments.  Thus the +1
                foreach ($iCurrentToken+1..$iNumberOfTokens-1) 
                {
                    $logger->debug("$self->{'_sName'} - Command to be added to arguments array is $aCommandTokens->[$_]"); 
                    unless ($aCommandTokens->[$_] eq "") { push(@aCommandArguments, $aCommandTokens->[$_]); } 
                }
                last;
            }
            else 
            {
                # We need to grab the remaining tokens, once a command is not found, and add them to the 
                # aCommandArguments array
                $logger->debug("$self->{'_sName'} - --DEBUG FIND 6--");
                $logger->debug("$self->{'_sName'} - \tCommand $sToken NOT found");
                foreach ($iCurrentToken..$iNumberOfTokens-1) 
                {
                    $logger->debug("$self->{'_sName'} - Command to be added to arguments array is $aCommandTokens->[$_]"); 
                    unless ($aCommandTokens->[$_] eq "") { push(@aCommandArguments, $aCommandTokens->[$_]); } 
                }
                last;
            }

        }

        $logger->debug("$self->{'_sName'} - --DEBUG FIND 7--");
        $logger->debug("$self->{'_sName'} - \tVariables defined for iCurrentToken: $iCurrentToken");

        $logger->debug("$self->{'_sName'} - \thCommandTree: ", ${$oDebugger->DumpHashKeys($hCommandTree)});
        if (defined $hCommandDirectives)
        {
            $logger->debug("$self->{'_sName'} - \thCommandDirectives: ", ${$oDebugger->DumpHashKeys($hCommandDirectives)});
        }
        else
        {
            $logger->debug("$self->{'_sName'} - \thCommandDirectives: NOT DEFINED");
        }
        $logger->debug("$self->{'_sName'} - \taCommandTokens: ", ${$oDebugger->DumpArray($aCommandTokens)});
        $logger->debug("$self->{'_sName'} - \taFullCommandName: ", ${$oDebugger->DumpArray(\@aFullCommandName)});
        $logger->debug("$self->{'_sName'} - \taCommandArguments: ", ${$oDebugger->DumpArray(\@aCommandArguments)});

        $iCurrentToken++;
    }
 
    $self->{_hCommandTreeAtLevel}   = $hCommandTree;
    $self->{_hCommandDirectives}    = $hCommandDirectives || {};
    $self->{_aFullCommandName}      = \@aFullCommandName;
    $self->{_aCommandArguments}     = \@aCommandArguments;

    # Escape the completions so they're valid on the command line
    # I am not sure if this is the right place yet for this to be done.  Need to write some unit
    # tests to verify
    $self->{_oParser}->parse_escape($self->{_aFullCommandName}) unless $self->{suppress_completion_escape};
    $self->{_oParser}->parse_escape($self->{_aCommandArguments}) unless $self->{suppress_completion_escape};
    
    
    $logger->debug("$self->{'_sName'} - --DEBUG FIND 8--");
    $logger->debug("$self->{'_sName'} - \tFinal variables set by _FindCommandInCommandTree function");
    $logger->debug("$self->{'_sName'} - \t_hCommandTreeAtLevel: ", ${$oDebugger->DumpHashKeys($self->{_hCommandTreeAtLevel})});
    $logger->debug("$self->{'_sName'} - \t_hCommandDirectives: ", ${$oDebugger->DumpHashKeys($self->{_hCommandDirectives})});
    $logger->debug("$self->{'_sName'} - \t_aFullCommandName: ", ${$oDebugger->DumpArray($self->{_aFullCommandName})});
    $logger->debug("$self->{'_sName'} - \t_aCommandArguments: ", ${$oDebugger->DumpArray($self->{_aCommandArguments})});

    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return 1;
}

sub _RunCodeDirective
{
    # This method will execute the code directives when called.  It performs some sanity checking
    # before it actually runs the commands
    # Required:
    #   $self->{_hCommandTreeAtLevel}   hash_ref
    #   $self->{_hCommandDirectives}    hash_ref
    #   $self->{_aCommandArguments}     array_ref
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    
    
    if(!$self->{_hCommandDirectives}) 
    {
        # This is for processing a default command at each level
        if ((exists $self->{_hCommandTreeAtLevel}->{''}) && (exists $self->{_hCommandTreeAtLevel}->{''}->{code}))
        {
            # The default command exists and has a code directive
#            my $save = $self->{_hCommandDirectives};
            $self->{_hCommandDirectives} = $self->{_hCommandTreeAtLevel}->{''};
#            $self->_RunCommand();
#            $self->{_hCommandDirectives} = $save;
#            return;
        }
        my ($sCommandName) = $self->_GetFullCommandName();
        $self->error( "$sCommandName: unknown command\n");
        return undef;
    }

    # Lets check and verify the max and min values for number of arguments if they exist
    # TODO Instead of printing an error, we should print the command syntax 
    if (exists($self->{_hCommandDirectives}->{minargs}) && @{$self->{_aCommandArguments}} < $self->{_hCommandDirectives}->{minargs}) 
    {
        $self->error("Too few args!  " . $self->{_hCommandDirectives}->{minargs} . " minimum.\n");
        return undef;
    }
    if (exists($self->{_hCommandDirectives}->{maxargs}) && @{$self->{_aCommandArguments}} > $self->{_hCommandDirectives}->{maxargs}) 
    {
        $self->error("Too many args!  " . $self->{_hCommandDirectives}->{maxargs} . " maximum.\n");
        return undef;
    }

    # Lets add support for authenticated commands
    if ( exists $self->{_hCommandDirectives}->{auth} && $self->{_hCommandDirectives}->{auth} == 1 )
    {
        my $iSuccess = $self->_AuthCommand();
        if ( $iSuccess == 1 ) { $self->_RunCommand(); }
    }
    else { $self->_RunCommand(); }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return;
}

sub _AuthCommand
{
    # This method will perform authentication for a command.  
    # Return:
    #   1 = successful authentication
    #   0 = failed authentication
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $config = $oConfig->GetRunningConfig();
    my $OUT = $self->{OUT};

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');

    my $bAuthStatus = 0;
    my $iAttempt = 1;
    my $sStoredUsername = "";
    my $sStoredPassword = "";
    my $sStoredSalt = "";
    my $iCryptID;

    my $oAuth = new Term::RouterCLI::Auth();
    
    my $iMaxAttempt = 3;
    if ( exists $config->{auth}->{max_attempts} ) { $iMaxAttempt = $config->{auth}->{max_attempts}; }
    
    my $sAuthMode = "shared";
    if ( exists $config->{auth}->{mode} ) { $sAuthMode = $config->{auth}->{mode}; }
    
    $logger->debug("$self->{'_sName'} - iMaxAttempt: $iMaxAttempt");
    $logger->debug("$self->{'_sName'} - sAuthMode: $sAuthMode");
    
    if ($sAuthMode eq "shared")
    {
        if ( exists $config->{auth}->{password} ) 
        { 
            $sStoredPassword = $config->{auth}->{password};
            ($iCryptID, $sStoredSalt, $sStoredPassword) = $oAuth->SplitPasswordString(\$sStoredPassword);
        }   
        
        # Lets not prompt for a password if the password is blank in the configuration file or does not exist
        # in the configuration file
        if ( $$sStoredPassword eq "" )
        {
            $logger->debug("$self->{'_sName'} - No password found for shared auth mode, exiting");
            $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
            # Return code 1 = "success"
            return 1;
        }

        while ($iAttempt <= $iMaxAttempt) 
        {
            $self->ChangeActivePrompt("Password: ");
            my $sPassword = $oAuth->PromptForPassword();
            $logger->debug("$self->{'_sName'} - sPassword: $$sPassword");
                
            my $sEncryptedPassword = $oAuth->EncryptPassword($iCryptID, $sPassword, $sStoredSalt);
            $logger->debug("$self->{'_sName'} - sEncryptedPassword: $$sEncryptedPassword");
    
            # TODO Need to provide a way for users to change the password
            if ($$sEncryptedPassword eq $$sStoredPassword) 
            {
                $logger->debug("$self->{'_sName'} - Match Found");
                $bAuthStatus = 1;
                last;
            }
            if ($iAttempt == $iMaxAttempt) 
            {
                $logger->debug("$self->{'_sName'} - Too many failed authentication attempts!");
                $bAuthStatus = 0;
                last;
            }
            $iAttempt++;
        }
    }
    elsif ($sAuthMode eq "user")
    {
        my $sUserAuthMode = "local";
        
        while ($iAttempt <= $iMaxAttempt) 
        {
            $self->ChangeActivePrompt("Username: ");
            my $sUsername = ${$oAuth->PromptForUsername()};
            $logger->debug("$self->{'_sName'} - sUsername: $sUsername");
            
            $self->ChangeActivePrompt("Password: ");
            my $sPassword = $oAuth->PromptForPassword();
            $logger->debug("$self->{'_sName'} - sPassword: $$sPassword");

            unless ( exists $config->{auth}->{user}->{$sUsername} ) 
            { 
                $logger->debug("$self->{'_sName'} - iAttempt: $iAttempt");
                $iAttempt++;
                next;
            }
            
            # This is where we add support for things like RADIUS or TACACS from the configuration file
            if ( exists $config->{auth}->{user}->{$sUsername}->{authmode} )
            {
                $sUserAuthMode = $config->{auth}->{user}->{$sUsername}->{authmode};
            }

            # We do not allow undefined passwords
            unless ( exists $config->{auth}->{user}->{$sUsername}->{password} ) 
            { 
                $logger->debug("$self->{'_sName'} - iAttempt: $iAttempt");
                $iAttempt++;
                next;
            }  
            $sStoredPassword = $config->{auth}->{user}->{$sUsername}->{password};
            ($iCryptID, $sStoredSalt, $sStoredPassword) = $oAuth->SplitPasswordString(\$sStoredPassword);

            my $sEncryptedPassword = $oAuth->EncryptPassword($iCryptID, $sPassword, $sStoredSalt);
            $logger->debug("$self->{'_sName'} - sEncryptedPassword: $$sEncryptedPassword");
            
            if ($$sEncryptedPassword eq $$sStoredPassword) 
            {
                $logger->debug("$self->{'_sName'} - Match Found");
                $self->{_sActiveLoggedOnUser} = $sUsername;
                
                # We need to clear and load the new command history file for this user
                if ($self->{_oHistory}->{_bEnabled} == 1 )
                {
                    $self->{_oHistory}->SaveCommandHistoryToFile();
                    $self->{_oHistory}->ClearHistory();
                    my $sNewHistoryFilename = './logs/.cli-history-' . $sUsername;
                    $self->{_oHistory}->SetFilename($sNewHistoryFilename);
                    $self->{_oHistory}->LoadCommandHistoryFromFile();
                }
                
                $bAuthStatus = 1;
                last;
            }

            if ($iAttempt == $iMaxAttempt) 
            {
                print $OUT "Too many failed authentication attempts!\n\n";
                $bAuthStatus = 0;
                last;
            }
            $iAttempt++;
        }
    }

    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return $bAuthStatus;
}

sub _RunCommand
{
    # This method will actually run the commands called out in the code directives
    # Required:
    #   $self->{_hCommandDirectives}    hash_ref
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $OUT = $self->{OUT};

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    if (exists $self->{_hCommandDirectives}->{code}) 
    {
        my $oCode = $self->{_hCommandDirectives}->{code};
        # If oCode is a code ref, call it, else it's a string, print it.
        if (ref($oCode) eq 'CODE') 
        {
            # This is where we actually run the code. All commands and arguments are in the object
            eval { &$oCode($self) };
            $self->error($@) if $@;
        } 
        else { print $OUT $oCode; }
    } 
    else 
    {
        if (exists $self->{_hCommandDirectives}->{cmds}) 
        { 
            print $OUT $self->_GetCommandSummaries(); 
        } 
        else 
        {
            my ($sCommandName) = $self->_GetFullCommandName();
            $self->error("The $sCommandName command has no code directive to call!\n"); 
        }
    }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return;
}

sub _CompletionFunction
{
    # This method is the entry point to the ReadLine completion callback and will complete a string
    # of data against the command tree.
    # Required:
    #   string (The word directly to the left of the cursor)
    #   string (The entire line)
    #   int (the position in the line of the beginning of $text)

    my $self = shift;
    $self->{_sStringToComplete} = shift; 
    $self->{_sCompleteRawline} = shift; 
    $self->{_iStringToCompleteTextStartPosition} = shift;
    my $OUT = $self->{OUT};
    my $logger = $oDebugger->GetLogger($self);

    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');

    # Lets figure out where the cursor is currently at and thus how long the original line is
    $self->{_iCurrentCursorLocation} = $self->{_oTerm}->Attribs->{'point'};

    $logger->debug("$self->{'_sName'} - Values passed in to the function and computed from those values");
    $logger->debug("$self->{'_sName'} - \t_sStringToComplete: $self->{_sStringToComplete}");
    $logger->debug("$self->{'_sName'} - \t_sCompleteRawline: $self->{_sCompleteRawline}");
    $logger->debug("$self->{'_sName'} - \t_iStringToCompleteTextStartPosition: $self->{_iStringToCompleteTextStartPosition}");
    $logger->debug("$self->{'_sName'} - \t_iCurrentCursorLocation: $self->{_iCurrentCursorLocation}");

    # If there is any white space at the start or end of the command lets remove it just to be safe 
    $self->{_sCompleteRawline} =~ s/^\s+//g;  
    $self->{_sCompleteRawline} =~ s/\s+$//g; 


    # Parse the _sCompleteRawline in to a series of command line tokens
    ($self->{_aCommandTokens}, $self->{_iTokenNumber}, $self->{_iTokenOffset}) = $self->{_oParser}->parse_line(
        $self->{_sCompleteRawline},
        messages=>0, 
        cursorpos=>$self->{_iCurrentCursorLocation}, 
        fixclosequote=>1
    );
    
    $logger->debug("$self->{'_sName'} - Data returned from the parser function");
    $logger->debug("$self->{'_sName'} - \t_aCommandTokens: ", ${$oDebugger->DumpArray($self->{_aCommandTokens})});
    $logger->debug("$self->{'_sName'} - \t_iTokenNumber: $self->{_iTokenNumber}") if (defined $self->{_iTokenNumber});
    $logger->debug("$self->{'_sName'} - \t_iTokenOffset: $self->{_iTokenOffset}") if (defined $self->{_iTokenOffset});
    
    # Punt if nothing comes back from the parser
    unless (defined($self->{_aCommandTokens})) { $logger->fatal("ERROR 1001"); return; }

    # Lets try and find the command in the command tree
    $self->_FindCommandInCommandTree();



    # --------------------------------------------------------------------------------
    # Process Arguments
    # --------------------------------------------------------------------------------
    # Lets check to see if there are any arguments returned from the Find function. The three use cases are:
    # 1) There are no arguments, meaning everything is a command found in the command tree
    # 2) There are multiple matches found for the command abbreviation that was entered
    # 3) No match was found
    #   3a) The command was typed in wrong
    #   3b) The values typed in are in fact arguments and not part of the command at all
    #   3c) The values need to be passed to a method defined in the args directive to see if they are commands
    #   3d) There was nothing entered on the command line
    my $iNumberOfArguments = @{$self->{_aCommandArguments}};
    $logger->debug("$self->{'_sName'} - iNumberOfArguments: $iNumberOfArguments");
    if ($iNumberOfArguments > 0)
    {
        # Use Cases 2 and 3
        # Lets figure out how many matches there are for that first argument that could not be completed
        my @aCommandsThatMatchAtThisLevel = keys(%{$self->{_hCommandTreeAtLevel}});
        @aCommandsThatMatchAtThisLevel = grep {/^$self->{_aCommandArguments}->[0]/ } @aCommandsThatMatchAtThisLevel;
        my $iNumberOfCommandsThatMatchAtThisLevel = @aCommandsThatMatchAtThisLevel;
        
        $logger->debug("$self->{'_sName'} - Entering Use Case 2 and 3");
        $logger->debug("$self->{'_sName'} - \tiNumberOfCommandsThatMatchAtThisLevel: $iNumberOfCommandsThatMatchAtThisLevel");
        if ($iNumberOfCommandsThatMatchAtThisLevel > 1)
        {
            # Use Case 2: There was more than one match found.  So we need to print out the options for just these commmands
            $logger->debug("$self->{'_sName'} - Entering Use Case 2");
            $self->_RewriteLine();

            # Print out possible options for the matches that were found
            print $OUT "\n";
            print $OUT $self->_GetCommandSummaries(\@aCommandsThatMatchAtThisLevel);

            # We need to redraw the prompt and command line options since we are going to output text via _GetCommandSummaries
            $self->{_oTerm}->rl_on_new_line();
            return;
        }
        else
        {
            # Use Case 3: There were no matches found for this argument, meaning that the argument is not found in the 
            # command tree so the arguments must truely be arguments or they are incorrectly entered commands.  
            # But before we can know this for sure, lets check for an args directive.
            
            $logger->debug("$self->{'_sName'} - Entering Use Case 3");
            if (exists $self->{_hCommandDirectives}->{args} && !exists $self->{_hCommandDirectives}->{minargs})
            {
                # Use Case 3c: This is for something like "help" or "no" that needs to restart the completion at the
                # beginning of the command tree.  So we will need to check the args directive
                $logger->debug("$self->{'_sName'} - Entering Use Case 3c");

                if (ref($self->{_hCommandDirectives}->{args}) eq 'CODE') 
                {
                    # This is where we call the subroutine listed in the args directive
                    eval { &{$self->{_hCommandDirectives}->{args}}($self) };
                } 
                
                $self->_RewriteLine();
            }
            elsif (!exists $self->{_hCommandDirectives}->{args} && (exists $self->{_hCommandDirectives}->{minargs} && $self->{_hCommandDirectives}->{minargs} > 0))
            {
                # Use Case 3b: The arguments are in fact arguments
                $logger->debug("$self->{'_sName'} - Entering Use Case 3b");
                $self->_RewriteLine();
                return;
            }
            else
            {
                # Use Case 3a: The command was typed in wrong
                $logger->debug("$self->{'_sName'} - Entering Use Case 3a");
                $self->_RewriteLine();
            }
            
        }
    }
    else
    {
        if (!exists $self->{_aFullCommandName}->[0] || $self->{_aFullCommandName}->[0] eq "")
        {
            # Use Case 3d: There was nothing entered on the command line.  So we need to print out all options at that level
            $logger->debug("$self->{'_sName'} - Entering Use Case 3d");
            $self->_RewriteLine();

            # Print out possible options for the matches that were found
            print $OUT "\n";
            print $OUT $self->_GetCommandSummaries();

            # We need to redraw the prompt and command line options since we are going to output text via _GetCommandSummaries
            $self->{_oTerm}->rl_on_new_line();
            return;            
        }
        else
        {
            # Use Case 1: There were no arguments found, so everything is a full blown command
            $logger->debug("$self->{'_sName'} - Entering Use Case 1");
            $self->_RewriteLine();            
        }
    }
    # --------------------------------------------------------------------------------
    
    # These next two lines will make the screen scroll up like it does on a router
    # If we are in a internal loop, like processing the args directive lets not scroll 
    # the screen as that will just add extra lines when we do not want them
    if ($self->{_sStringToComplete} ne "NONE")
    {
        print $OUT "\n";
        $self->{_oTerm}->rl_on_new_line();
    }
    
    # If there is nothing to do, meaning, there is no command to complete, then lets print out 
    # the command options at that level.  If there are no options at that level, print <cr>.
    # If there are currently no commands found, then lets not print either
    my $iNumberOfCommands = @{$self->{_aFullCommandName}};
    if ($self->{_sStringToComplete} eq "" && $iNumberOfCommands > 0)
    {
        $logger->debug("$self->{'_sName'} - Lets get the data from _GetCommandSummaries");
        print $OUT $self->_GetCommandSummaries(); 
    }

    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return;
}

sub _RewriteLine
{
    # This method will do the actual rewriting of the command line during command completion
    # Required:
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###');
    
    my ($sCommands, $iCommandsLength) = $self->_GetFullCommandName();
    my ($sArguments, $iArgumentLength) = $self->_GetFullArgumentsName();
    my $iCurrentPoint = $self->{_iCurrentCursorLocation};

    # We need to set the cursor to the end of the new fully completed line
    my $iNewPointLocation = $iCommandsLength + $iArgumentLength;
        
        
    $logger->debug("$self->{'_sName'} - iCurrentPoint: $iCurrentPoint");
    $logger->debug("$self->{'_sName'} - sCommands: $sCommands");
    $logger->debug("$self->{'_sName'} - iCommandsLength: $iCommandsLength");
    $logger->debug("$self->{'_sName'} - sArguments: $sArguments");
    $logger->debug("$self->{'_sName'} - iArgumentLength: $iArgumentLength");
    $logger->debug("$self->{'_sName'} - iNewPointLocation: $iNewPointLocation");
    
    $self->{_oTerm}->Attribs->{'line_buffer'} = $sCommands . $sArguments;
    $self->{_oTerm}->Attribs->{'point'} = $iNewPointLocation;

    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}


return 1;
