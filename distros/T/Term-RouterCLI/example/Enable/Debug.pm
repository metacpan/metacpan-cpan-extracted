#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Enable::Debug                                        #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-09-16                                           #
##################################################################### 
#
#
#
#
package Enable::Debug;

use strict;
use Term::RouterCLI::Languages;
use Term::RouterCLI::Debugger;

my $oDebugger = new Term::RouterCLI::Debugger();

sub CommandTree {
    my $self = shift;
    my $lang = new Term::RouterCLI::Languages();
    my $strings = $lang->LoadStrings("Enable/Debug");
    my $hCurrentDebugConfig = $oDebugger->GetDebugConfig();
    
    my $hash_ref = {};

    $hash_ref = {
        "find" => {
            desc    => $strings->{debug_find_d},
            help    => $strings->{debug_find_h},
            maxargs => 0,
            code    => sub {
                my $self = shift;
                my $sDebugKey = 'log4perl.logger.Term::RouterCLI::_FindCommandInCommandTree';
                my $sNewValue = "DEBUG, DEVSCREEN";
                
                # Lets check for a "no" command
                if ($self->{'_aFullCommandName'}->[0] eq 'no')
                {
                    if (exists $hCurrentDebugConfig->{"$sDebugKey"})
                    {
                        delete ($hCurrentDebugConfig->{"$sDebugKey"});
                    } 
                }
                else { $hCurrentDebugConfig->{"$sDebugKey"} = $sNewValue; }
                $oDebugger->ReloadDebuggerConfiguration();
            }
        },
        "complete" => {
            desc    => $strings->{debug_complete_d},
            help    => $strings->{debug_complete_h},
            maxargs => 0,
            code    => sub {
                my $self = shift;
                my $sDebugKey = 'log4perl.logger.Term::RouterCLI::_CompletionFunction';
                my $sNewValue = "DEBUG, DEVSCREEN";
                
                # Lets check for a "no" command
                if ($self->{'_aFullCommandName'}->[0] eq 'no')
                {
                    if (exists $hCurrentDebugConfig->{"$sDebugKey"})
                    {
                        delete ($hCurrentDebugConfig->{"$sDebugKey"});
                    } 
                }
                else { $hCurrentDebugConfig->{"$sDebugKey"} = $sNewValue; }
                $oDebugger->ReloadDebuggerConfiguration();
            }
        },
        "all" => {
            desc    => $strings->{debug_all_d},
            help    => $strings->{debug_all_h},
            maxargs => 0,
            code    => sub {
                my $self = shift;
                my $sDebugKey = 'log4perl.logger.Term::RouterCLI';
                my $sNewValue = "DEBUG, DEVSCREEN";
                
                # Lets check for a "no" command
                if ($self->{'_aFullCommandName'}->[0] eq 'no')
                {
                    $sNewValue = "FATAL, DEVSCREEN";
                }
                $hCurrentDebugConfig->{"$sDebugKey"} = $sNewValue;
                $oDebugger->ReloadDebuggerConfiguration();
            }
        },   
    };
    return($hash_ref);
}

return 1;
