#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Enable::No                                           #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-09-16                                           #
##################################################################### 
#
#
#
#
package Enable::No;

use strict;
use Term::RouterCLI::Languages;
use Enable::Debug;

sub CommandTree {
    my $self = shift;
    my $lang = new Term::RouterCLI::Languages();
    my $strings = $lang->LoadStrings("Enable/No");
    my $hash_ref = {};

    $hash_ref = {
        "debug"  => {
            desc    => $strings->{debug_d},
            help    => $strings->{debug_h},
            cmds    => &Enable::Debug::CommandTree($self)
        },
    };
    return($hash_ref);
}

return 1;
