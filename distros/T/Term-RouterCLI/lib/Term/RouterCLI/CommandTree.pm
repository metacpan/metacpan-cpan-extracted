#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       CommandTree                                          #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-04-09                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::CommandTree;

use 5.8.8;
use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw( CreateCommandTree GetCurrentCommandTree GetFullCommandTree AddToCommandTree AuthenticateCommandTree );
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );
our $VERSION     = '1.00';
$VERSION = eval $VERSION;



# ----------------------------------------
# Public Functions
# ----------------------------------------

sub CreateCommandTree
{ 
    # This method will take in a hash reference and create a command tree
    # Required:
    #   hash_ref (command tree)
    my $self = shift;
    my $hCommandTree = shift;
    
    $self->{'_hFullCommandTree'} = $hCommandTree;
}

sub GetCurrentCommandTree
{
    # This method will return the a hash ref to the current command tree of all avaliable commands
    # Return:
    #   hash_ref (command tree)
    my $self = shift;
    
    # If there is no _hCommandTreeAtLevel yet, then lets use the _hFullCommandTree as this means
    # we are just starting at the top
    return $self->{'_hCommandTreeAtLevel'} || $self->GetFullCommandTree();
}

sub GetFullCommandTree
{
    # This method will return the a hash ref to the full command tree of all avaliable commands
    # Return:
    #   hash_ref (command tree)
    my $self = shift;
    
    # If there is no _hCommandTreeAtLevel yet, then lets use the _hFullCommandTree as this means
    # we are just starting at the top
    return $self->{'_hFullCommandTree'};
}

sub AddToCommandTree
{
    # This method will add commands to the current command tree
    # Required:
    #   hashref (command tree)
    my $self = shift;
    my $hAdditionalCommandTree = shift;

    my $hCurrentCommandTree = $self->{'_hFullCommandTree'} || {};
    foreach (keys %$hAdditionalCommandTree) 
    {
        $hCurrentCommandTree->{$_} = $hAdditionalCommandTree->{$_};
    }
}

return 1;
