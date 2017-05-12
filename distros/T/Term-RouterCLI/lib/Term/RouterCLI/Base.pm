#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Base                                                 #
# Description: Methods for building a router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-10-06                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Base;

use 5.8.8;
use strict;
use warnings;
use Term::RouterCLI::Config;
use Term::RouterCLI::Debugger;

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

sub _initDebugger
{
    my $self = shift;
    # Create an object to the debugger class
    $self->{'_oDebugger'} = new Term::RouterCLI::Debugger();
}

sub _initConfig
{
    my $self = shift;
    # Create an object to the debugger class
    $self->{'_oConfig'} = new Term::RouterCLI::Config();
}


sub _ExpandTildes
{
    my $self = shift;
    my $parameter = shift;
    
    $parameter =~ s/^~([^\/]*)/$1?(getpwnam($1))[7]:$ENV{HOME}||$ENV{LOGDIR}||(getpwuid($>))[7]/e;
    return $parameter;
}


return 1;
