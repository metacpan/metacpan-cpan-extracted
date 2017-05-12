#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       UserExec::Show                                       #
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
package UserExec::Show;

use strict;
use Term::RouterCLI::Config;
use Term::RouterCLI::Languages;
use Term::RouterCLI::Hardware::Net::Interface;

my $oConfig = new Term::RouterCLI::Config();


sub CommandTree {
    my $self = shift;
    my $config = $oConfig->GetRunningConfig();
    my $lang = new Term::RouterCLI::Languages();
    my $strings = $lang->LoadStrings("UserExec/Show");
    my $hash_ref = {};
    
    # These commands should only show up in the UserExec show menu
    $hash_ref = {
        "history" => {
            desc    => $strings->{history_d},
            help    => $strings->{history_h},
            minargs => 0,
            maxargs => 1,
            code  => sub { shift->PrintHistory(); }
        },
        "interface" => {
            desc    => $strings->{show_interface_d},
            help    => $strings->{show_interface_h},
            argdesc => $strings->{show_interface_a},
            minargs => 0,
            maxargs => 1,
            code    => sub { 
                my $self = shift;
                my $int = new Term::RouterCLI::Hardware::Net::Interface();
                $int->ShowInterface("normal", $self->{_aCommandArguments}->[0]);
            },
            cmds => {
                "brief" => { 
                    minargs => 0,
                    maxargs => 1,
                    code    => sub { 
                        my $self = shift;
                        my $int = new Term::RouterCLI::Hardware::Net::Interface();
                        $int->ShowInterface("brief", $self->{_aCommandArguments}->[0]);
                    },
                },
            },
        },
    };
    return($hash_ref);
}

return 1;
