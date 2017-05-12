#
# $Id: Conversation.pm,v 0.16 2003/08/07 00:01:59 lawrence Exp $
#

package Net::Msmgr::Conversation;
use strict;
use warnings;
use Net::Msmgr::Object;
our @ISA = qw (Net::Msmgr::Object);

sub _fields
{
    return shift->SUPER::_fields,(
				  session => undef,
				  switchboard => undef,
				  email => {},
				  _state => 0,
				  );
}

use constant Disconnected => 0;
use constant Connected => 1;

=pod

=head1 NAME

Net::Msmgr::Conversation -- A user-friendly manager for the myriad ways we can talk to other users

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTION OPTIONS

=head1 PUBLIC METHODS

=over

=item $conversation->shutdown();

Terminate the session, close off switchboard connection

=cut

sub invite( $$ )
{
    my ($self, $email ) = @_;
    {
	my $command = new Net::Msmgr::Command
	    (type => Net::Msmgr::Command::Normal,
	     cmd => 'CAL',
	     params => [ $email ] );
	$command->send($self->switchboard);
    }
}


sub send_message( $$;$ )
{
    my ($self, $text) = splice(@_,0,2);
    my $ack = shift || 'N';
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Payload,
		      cmd => 'MSG',
		      params => [ $ack ] ,
		      body => $text)->send($self->switchboard);
}

sub shutdown( $ )
{
    my ($self) = @_;
    $self->{switchboard}->shutdown if $self->{switchboard};
    $self->{email} = {};
    $self->{_state} = Disconnected;
}

=pod

=item $conversation->roster();

Return a list of email addresses for people connected to this
conversation

=cut

sub roster( $ )
{
    my ($self) = @_;

    return(keys(%{$self->{email}}));
}

=pod

=back

=cut

sub _handle_ans
{
    my ($self, $command) = @_;
    $self->_state(Connected);
}

sub _handle_usr
{
    my ($self, $command) = @_;
    $self->_state(Connected);
}

sub _handle_iro
{
    my ($self, $command) = @_;
    $self->{email}->{$command->params->[3]} = Connected;
}

sub _handle_joi
{
    my ($self, $command) = @_;
    $self->{email}->{$command->params->[0]} = 1;
    
}

sub _handle_bye
{
    my ($self, $command) = @_;
    delete $self->{email}->{$command->params->[0]};
}



#
# $Log: Conversation.pm,v $
# Revision 0.16  2003/08/07 00:01:59  lawrence
# Initial Release
#
#
