#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Enable                                               #
# Description: Example Enable command tree for building a Router    #
#              (Stanford) style CLI                                 #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package Enable;

use strict;
use Term::RouterCLI::Config;
use Term::RouterCLI::Languages;
use UserExec;
use Enable::Debug;
use Enable::No;
use Enable::Show; 
use Enable::Configure::Terminal;

my $oConfig = new Term::RouterCLI::Config();

sub CommandTree {
    my $self = shift;
    my $config = $oConfig->GetRunningConfig();
    my $lang = new Term::RouterCLI::Languages();
    my $strings = $lang->LoadStrings("Enable");
    my $hash_ref = {};

    $hash_ref = {
        "no"  => {
            hidden  => 1,
            cmds    => &Enable::No::CommandTree($self)
        },
        "show"  => {
            desc    => $strings->{show_d},
            help    => $strings->{show_h},
            cmds    => &Enable::Show::CommandTree($self)
        },
        "exit"  => {
            desc    => $strings->{exit_d},
            help    => $strings->{exit_h},
            maxargs => 0,
            code    => sub { shift->Exit(); }
        },
        "end" => {
            desc    => $strings->{end_d},
            help    => $strings->{end_h},
            maxargs => 0,
            code    => sub {
                my $self = shift;
                $self->SetPromptLevel('> ');
                $self->SetPrompt($config->{hostname});
                $self->CreateCommandTree(&UserExec::CommandTree($self));
            }
        },
        "debug"  => {
            desc    => $strings->{debug_d},
            help    => $strings->{debug_h},
            cmds    => &Enable::Debug::CommandTree($self)
        },
        "configure" => {
            desc    => $strings->{configure_d},
            help    => $strings->{configure_h},
            cmds    => {
                "terminal" => { 
                    code => sub {
                        my $self = shift;
                        $self->SetPromptLevel('(config)# ');
                        $self->SetPrompt($config->{hostname});
                        $self->CreateCommandTree(&Enable::Configure::Terminal::CommandTree($self));
                    } 
                }
            }
        },
    };
    

    # UserExec level commands should also be avaliable in Enable Mode
    my $hash_ref_additional = &UserExec::CommandTree($self);

    # Remove certain keys as it does not make since that you could re-issue the enable command
    # once you are at the enable level
    delete $hash_ref_additional->{'enable'};
    
    # Enable level commands should take presidence over UserExec commands if they are duplicates
    my %hash = (%$hash_ref_additional, %$hash_ref);
    
    return(\%hash);
}


return 1;
