#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Hardware                                             #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-04-27                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Hardware;

use 5.8.8;
use strict;
use warnings;

our $VERSION     = '1.00';
$VERSION = eval $VERSION;


sub new
{
    my $pkg = shift;
    my $class = ref($pkg) || $pkg;  

    my $self = {};
    $self->{'_sName'}                 = $pkg;        # Lets set the object name so we can use it in debugging
    bless ($self, $class);

    # Lets send any passed in arguments to the _init method
    $self->_init(@_);
    return $self;
}

sub DESTROY
{
    my $self = shift;
    $self = {};
} 

sub _init
{
    my $self = shift;
    my %hParameters = @_;
    
    # Lets overwrite any defaults with values that are passed in
    if (%hParameters)
    {
        foreach (keys (%hParameters)) { $self->{$_} = $hParameters{$_}; }
    }
}

return 1;
