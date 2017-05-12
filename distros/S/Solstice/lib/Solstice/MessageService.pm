package Solstice::MessageService;

# $Id: MessageService.pm 2528 2005-12-08 21:37:45Z jdr99 $

=head1 NAME

Solstice::MessageService - A service for sending all types of messages up a controller chain.

=head1 SYNOPSIS

  use Solstice::MessageService;

  my $message_service = Solstice::MessageService->new();
  $message_service->addErrorMessage('Message text');
  # You can also add messages directly from the language file
  $message_service->addErrorKey('lang_service_key');

=head1 DESCRIPTION

This is a service for putting a user notification at the top of a screen.  This enables screens with multiple active controllers to display pertinent messages from each controller without a trickle up chain, and it makes it so parent controllers don't need to check for error objects in child controllers.  This service has a priority chain, so only one type of message will be displayed at a time.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use constant INFO          => 'information';
use constant WARNING      => 'warning';
use constant ERROR          => 'error';
use constant SUCCESS      => 'success';
use constant SYSTEM          => 'system';
use constant PURGE          => 'purge';
use constant MESSAGE_TYPE => 'message_type';

use constant TRUE    => 1;
use constant FALSE    => 0;

our ($VERSION) = ('$Revision: 2528 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::MessageService, tied to an Apache thread wide base of messages.

=cut

sub new {
    my $obj = shift;
    return $obj->SUPER::new(@_);
}

=item addInfoMessage()

=cut

sub addInfoMessage {
    my $self = shift;
    my $message = shift;
    $self->_addMessage($message, INFO);

}

=item addInfoKey()

=cut

sub addInfoKey {
    my $self = shift;
    my $lang_key = shift;
    my $namespace = shift;
    my $params    = shift;
    unless ($namespace) {
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }
    my $lang_service = $self->getLangService($namespace);

    $self->addInfoMessage($lang_service->getMessage($lang_key, $params));

}

=item clearInfoMessages()

=cut

sub clearInfoMessages {
    my $self = shift;
    $self->_clear(INFO);
}

=item addErrorMessage()

=cut

sub addErrorMessage {
    my $self = shift;
    my $message = shift;
    $self->_addMessage($message, ERROR);
}

=item addErroKey()

=cut

sub addErrorKey {
    my $self = shift;
    my $lang_key = shift;
    my $namespace = shift;
    my $params    = shift;
    unless ($namespace) {
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }
    my $lang_service = $self->getLangService($namespace);

    $self->addErrorMessage($lang_service->getError($lang_key, $params));

}

=item clearErrorMessages()

=cut

sub clearErrorMessages {
    my $self = shift;
    $self->_clear(ERROR);
}

=item addSuccessMessage()

=cut

sub addSuccessMessage {
    my $self = shift;
    my $message = shift;
    $self->_addMessage($message, SUCCESS);
}

=item addSuccessKey()

=cut

sub addSuccessKey {
    my $self = shift;
    my $lang_key = shift;
    my $namespace = shift;
    my $params    = shift;
    unless ($namespace) {
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }
    my $lang_service = $self->getLangService($namespace);
    
    $self->addSuccessMessage($lang_service->getMessage($lang_key, $params));
    
}

=item clearSuccessMessages()

=cut

sub clearSuccessMessages {
    my $self = shift;
    $self->_clear(SUCCESS);
}

=item addWarningMessage()

=cut

sub addWarningMessage {
    my $self = shift;
    my $message = shift;
    $self->_addMessage($message, WARNING);
}

=item addWarningKey()

=cut

sub addWarningKey {
    my $self = shift;
    my $lang_key = shift;
    my $namespace = shift;
    my $params    = shift;
    unless ($namespace) {
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }
    my $lang_service = $self->getLangService($namespace);

    $self->addWarningMessage($lang_service->getMessage($lang_key, $params));

}

=item clearWarningMessages()

=cut

sub clearWarningMessages {
    my $self = shift;
    $self->_clear(WARNING);
}

=item addSystemMessage()

=cut

sub addSystemMessage {
    my $self = shift;
    my $message = shift;
    $self->_addMessage($message, SYSTEM);
}

=item addSystemKey()

=cut

sub addSystemKey {
    my $self = shift;
    my $lang_key = shift;
    my $namespace = shift;
    unless ($namespace) {
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }
    my $lang_service = $self->getLangService($namespace);

    $self->addSystemMessage($lang_service->getMessage($lang_key));

}

=item clearSystemMessages()

=cut

sub clearSystemMessages {
    my $self = shift;
    $self->_clear(SYSTEM);
}

=item getMessageType()

Gets the current message type.

=cut

sub getMessageType {
    my $self = shift;
    return $self->get(MESSAGE_TYPE);
}


=item getMessages()

Returns an array of all messages.  Returns () if no messages have been set.

=cut

sub getMessages {
    my $self = shift;

    my $message_type = $self->getMessageType();
    return () if $message_type && $message_type eq PURGE;
    my $queue = $self->get($message_type);
    if (defined $queue) {
        return @{$queue};
    }
    return ();
}

=item clearAll

Clears out all message queues, leaving message service empty.

=cut

sub clearAll {
    my $self = shift;
    $self->_clear(ERROR);
    $self->_clear(SUCCESS);
    $self->_clear(WARNING);
    $self->_clear(SYSTEM);
    $self->_clear(INFO);
}

sub clearScreen {
    my $self = shift;
    $self->_addMessage(' ', PURGE);
}

sub isScreenClear {
    my $self = shift;
    my $message_type = $self->getMessageType();
    return ($message_type && $message_type eq PURGE) ? TRUE: FALSE;
}

=back

=head2 Private Methods

=over 4

=cut

=item addMessage($message_text)

Adds message text to the queue of messages in memory.  Checks for duplicates and ignores them.

=cut

sub _addMessage {
    my $self = shift;
    my $message = shift;
    my $message_type = shift;

    $self->_setMessageType($message_type);
    my $existing = $self->_getExistingName();

    unless($message) {
        $self->warn("Cannot set an undefined $message_type message");
        return FALSE;
    }

    my $existing_messages = $self->get($existing);
    if (defined $existing_messages->{$message}) {
        return 1;
    }

    my $message_queue = $self->get($message_type);
    push @{$message_queue}, $message;
    $existing_messages->{$message} = 1;

    $self->set($message_type, $message_queue);
    $self->set($existing, $existing_messages); 
    return 1;
}

=item _setMessageType($message_type)

Sets the message type, if there is a higher priority message, then message type won't be set.

=cut

sub _setMessageType {
    my $self = shift;
    my $message_type = shift;

    #create an array in order of priority
    my @message_types = (ERROR, SUCCESS, WARNING, SYSTEM, INFO, PURGE);

    #if it hasn't already been set, goahead and blindly set it
    if(!defined $self->getMessageType()){
        $self->set(MESSAGE_TYPE ,$message_type);
        return;
    }

    foreach (@message_types){
        my $current_type = $_;

        # no point in setting message type ($current_type takes highest priority)
        return if $self->getMessageType() eq $current_type;

        #if this is the highest priority, set it
        if($message_type eq $current_type){
            $self->set(MESSAGE_TYPE, $message_type);
            return;
        }
    }
}

=item _clear($message_type)

clears out the given queue.

=cut

sub _clear {
    my $self = shift;
    my $type = shift;
    my $existing = $self->_getExistingName();

    $self->set($type,undef);
    $self->set($existing, undef);

    # now we need to decide if we need to change the current
    # message type (ie error messages have been cleared, but there is a success msg
    # in the queue)

    my @message_types = (ERROR, SUCCESS, WARNING, SYSTEM, INFO, PURGE);

    #we need to check for other messages and set the message type
    if($self->getMessageType() && $type eq $self->getMessageType()){
        $self->set(MESSAGE_TYPE, undef);
        foreach my $message_type (@message_types){
            #grab any messages of that type
            my $queue = $self->get($message_type);
            if(defined $queue){
                #if there are messages, this must be the current type, set it and return
                $self->_setMessageType($message_type);
                return;
            }
        }
    }
    return;
}

=item _getExistingName()

Returns the name to use to get the hash of existing messages.

=cut

sub _getExistingName {
    my $self = shift;
    return $self->getMessageType() ? "existing_message_".$self->getMessageType() : undef;
}

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::MessageService';
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2528 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
