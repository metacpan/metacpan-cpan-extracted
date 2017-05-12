#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# Class:       Prompt                                               #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-02-21                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Prompt;

use 5.8.8;
use strict;
use warnings;
use Log::Log4perl;

use parent qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw( SetPrompt GetPrompt SetPromptLevel GetPromptLevel ClearPromptOrnaments ChangeActivePrompt);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

our $VERSION     = '1.00';
$VERSION = eval $VERSION;



# ----------------------------------------
# Public Methods 
# ----------------------------------------

sub SetPrompt
{
    # This method is for setting the current prompt value.  It is based on the hostname
    # and the prompt level.
    # Required:
    #   string (prompt name/hostname value)
    my $self = shift;
    my $parameter = shift;
    
    # If the hostname is not found in the configuration file, lets set a default
    if (defined $parameter) { $self->{'_sCurrentPrompt'} = "$parameter" . "$self->{'_sCurrentPromptLevel'}"; } 
    else { $self->{'_sCurrentPrompt'} = "Router" . "$self->{'_sCurrentPromptLevel'}"; }
}

sub GetPrompt
{
    # This method will return the current prompt value
    my $self = shift;
    return $self->{'_sCurrentPrompt'};
}

sub SetPromptLevel
{
    # This method will set the prompt level indicator such as "> ", "# ", "(config) " etc
    # Required:
    #   string (prompt level indicator)
    my $self = shift;
    my $parameter = shift;
    
    # If this method is called from a command tree option, then it will have the data structure hashref 
    # as the first argument. So we need to check for that just to be safe. 
    if (ref($parameter) eq 'HASH') { $parameter = $parameter->{'aCommandArguments'}->[0]; }
    
    unless (defined $parameter) { $parameter = "> "; }
    $self->{'_sCurrentPromptLevel'} = $parameter;
}

sub GetPromptLevel
{
    # This method will return the current problem level indicator
    my $self = shift;
    return $self->{'_sCurrentPromptLevel'};
}

sub ClearPromptOrnaments
{
    # This method will turn off the prompt ornamentation aka underlining
    my $self = shift;
    $self->{'_oTerm'}->Attribs->ornaments(0);
}

sub ChangeActivePrompt
{
    # This method will change the active prompt that is currently being displayed.  Normally the prompt will 
    # change after each command is <entered>.  But for things like password prompts and other diaplogs, we 
    # need to do it on the fly.
    # Required:
    #   string (new prompt value)
    my $self = shift;
    my $parameter = shift;
    
    # This line was needed for post tab completion so that it would display the prompt 
    $self->{'_oTerm'}->rl_redisplay();
    $self->{'_oTerm'}->rl_set_prompt($parameter);
    # This is needed so that when we redisplay, we do not show the current line buffer
    $self->{'_oTerm'}->Attribs->{'line_buffer'} = "";
    $self->{'_oTerm'}->rl_on_new_line();
    $self->{'_oTerm'}->rl_redisplay();
}


return 1;
