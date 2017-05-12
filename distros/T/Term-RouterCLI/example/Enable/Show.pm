#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Enable::Show                                         #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package Enable::Show;

use strict;
use Term::RouterCLI::Languages;
use UserExec::Show;



sub CommandTree {
    my $self = shift;
    my $lang = new Term::RouterCLI::Languages();
    my $strings = $lang->LoadStrings("Enable/Show");
    my $hash_ref = {};

    $hash_ref = {};

    # These commands should only show up in the enable mode show menu
    my $hash_ref_additional = &UserExec::Show::CommandTree($self);

    # Lets makes sure that the Enable commands overright the UserExec commands if they are in duplicate
    my %hash = (%$hash_ref_additional, %$hash_ref);
    return(\%hash);
}

return 1;
