#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       UserExec                                             #
# Description: Example UserExec command tree for building a Router  #
#              (Stanford) style CLI                                 #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package UserExec;

use strict;
use Term::RouterCLI::Config;
use Term::RouterCLI::Languages;
use UserExec::Show;
use Enable;

my $oConfig = new Term::RouterCLI::Config();


sub CommandTree {
    my $self = shift;
    my $config = $oConfig->GetRunningConfig();
    my $lang = new Term::RouterCLI::Languages();
    my $strings = $lang->LoadStrings("UserExec");
    my $hash_ref = {};


    $hash_ref = {
        "" => { 
            desc => "test",
            code    => "This is default\n",
        },
        "help"  => {
            desc    => $strings->{help_d},
            help    => $strings->{help_h},
            args    => sub { shift->TabCompleteArguments(); }, 
            code    => sub { shift->PrintHelp(); },
        },
        "h"     =>      { alias => "help", exclude_from_completion=>1},
        "exit"  => {
            desc    => $strings->{exit_d},
            help    => $strings->{exit_h},
            maxargs => 0,
            code    => sub { shift->Exit(); },
        },
        "show"  => {
            desc    => $strings->{show_d},
            help    => $strings->{show_h},
            cmds    => &UserExec::Show::CommandTree($self),
        },
        "enable" => {
            desc    => $strings->{enable_d},
            help    => $strings->{enable_h},
            maxargs => 0,
            auth    => 1,
            authDB  => 'user',
            code  => sub {
                my $self = shift;
                $self->SetPromptLevel('# ');
                $self->SetPrompt($config->{hostname});
                $self->CreateCommandTree(&Enable::CommandTree($self));
            },
        },
        "support" => {
            desc    => $strings->{support_d},
            help    => $strings->{support_h},
            hidden  => 1,
            cmds => {
                "eth0" => { code => "eth0 is better\n" },
                "wan0" => { code => "wan0 is fun\n" },
            },
        },
    };
    return($hash_ref);
}

return 1;
