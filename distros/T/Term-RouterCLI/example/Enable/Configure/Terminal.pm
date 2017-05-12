#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Enable::Configure::Terminal                          #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-07-01                                           #
##################################################################### 
#
#
#
#
package Enable::Configure::Terminal;

use strict;
use Term::RouterCLI::Config;
use Term::RouterCLI::Languages;
use Enable;

my $oConfig = new Term::RouterCLI::Config();


sub CommandTree {
    my $self = shift;
    my $config = $oConfig->GetRunningConfig();
    my $lang = new Term::RouterCLI::Languages();
    my $strings = $lang->LoadStrings("Enable/Configure/Terminal");
    my $hash_ref = {};

    $hash_ref = {
        "exit" => {
            desc    => $strings->{exit_d},
            help    => $strings->{exit_h},
            maxargs => 0,
            code    => sub {
                my $self = shift;
                $self->SetPromptLevel('# ');
                $self->SetPrompt($config->{hostname});
                $self->CreateCommandTree(&Enable::CommandTree($self));
            },
        },
        "hostname"  => {
            desc    => $strings->{hostname_d},
            help    => $strings->{hostname_h},
            maxargs => 1,
            minargs => 1,
            code    => sub { shift->SetHostname(); }
        },
        "lang"  => {
            desc    => $strings->{lang_d},
            help    => $strings->{lang_h},
            maxargs => 1,
            minargs => 1,
            code    => sub { 
                my $self = shift; 
                $lang->SetLanguage($self->{'_aCommandArguments'}->[0]); 
                $self->CreateCommandTree(&Enable::Configure::Terminal::CommandTree($self));
            } 
        },
        "password"  => {
            desc    => $strings->{password_d},
            help    => $strings->{password_h},
            maxargs => 1,
            minargs => 1,
            code    => sub { 
                my $self = shift; 
                $lang->SetLanguage(); 
                $self->CreateCommandTree(&Enable::Configure::Terminal::CommandTree($self));
            } 
        },
    };

    return($hash_ref);
}

return 1;

