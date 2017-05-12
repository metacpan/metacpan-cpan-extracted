package Monitoring::Spooler::Cmd::Command::text;
$Monitoring::Spooler::Cmd::Command::text::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::Command::text::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: the text transport

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
extends 'Monitoring::Spooler::Cmd::SendingCommand';
# has ...
# with ...
# initializers ...

# your code here ...
sub _prepare_message_and_send {
    my $self = shift;
    my $group_id = shift;
    my $msg_ref = shift;

    # the message starts with the number of aggregated text messages
    my $message = scalar(@{$msg_ref->{$group_id}}).' Alarms. ';
    # aggregate messages into one string
    # TODO LOW this could probably be improved, like:
    # - aggregate repetitive messages
    # - aggregate substrings (i.e. xyz is down, wvu is down => xyz, wvu are down)
    # - ...
    # But I admit that the added complexity _could_ very well hurt more
    # than it benefits ;)
    foreach my $msg (@{$msg_ref->{$group_id}}) {
        $message .= $msg->{'msg'}.', ';
    }

    # prepare stmt to fetch callee number from db
    # until further notice we just grab the first one from the apt group
    my $sql = 'SELECT number FROM notify_order WHERE group_id = ? ORDER BY id LIMIT 1';
    my $sth_num = $self->dbh()->prepare($sql);
    if(!$sth_num) {
        $self->logger()->log( message => 'Could not prepare SQL '.$sql.' due to error: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }
    if(!$sth_num->execute($group_id)) {
        $self->logger()->log( message => 'Could not execute statement: '.$sth_num->errstr, level => 'warning', );
        next;
    }
    my $number = $sth_num->fetchrow_array();
    # skip this group if there is nobody we can contact
    # Could very well happen if an update fails or someone messes w/ the DB
    if(!$number) {
        $self->logger()->log( message => 'No contact number for group #'.$group_id, level => 'warning', );
        return;
    }

    if($self->_send_with_best_transport($number,$message)) {
        return 1;
    } else {
        return;
    }
}

sub _cleanup {
    my $self = shift;
    my $success = shift;
    my $group_id = shift;
    my $msg_ref = shift;

    # this method does nothing if the call cycle failed
    return unless $success;

    # prepare stmt to delete processed msg from queue
    # will be executed below once the message has been sent successfully
    my $sql = 'DELETE FROM msg_queue WHERE id = ?';
    my $sth_del = $self->dbh()->prepare($sql);
    if(!$sth_del) {
        $self->logger()->log( message => 'Could not prepare SQL '.$sql.' due to error: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }

    # if the message was sent successfully we delete all sent messages
    # anything that got inserted into the queue after this script fetched
    # its workload from the DB will NOT be deleted and sent in the
    # next run
    foreach my $msg (@{$msg_ref->{$group_id}}) {
        if(!$sth_del->execute($msg->{'id'})) {
            $self->logger()->log( message => "Failed to delete message from DB w/ error: ".$sth_del->errstr, level => 'error', );
        }
    }

    $sth_del->finish();

    return 1;
}

sub _media_type {
    return 'text';
}

sub abstract {
    return "Process all messages of media-type text in the notification queue";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd::Command::text - the text transport

=head1 DESCRIPTION

This class invokes the most suitable text transport to send any queued text
messages.

=head1 METHODS

=head2 _cleanup

This method removes all sent messages from the queue.

=head2 _media_type

Always return 'text'.

=head2 _prepare_message_and_send

This methods accepts a group id and a HashRef keyed by group id. It will
accumulate and send all messages for the given group id using the superclass-defined
_send_with_best_transport method.

=head2 abstract

Returns the usage string shown in the App::Cmd overview screen.

=head1 NAME

Monitoring::Spooler::Cmd::Command::Text - The text transport

=head1 Q&A

=head2 What is a text? I just want to send an SMS!

SMS eq text

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
