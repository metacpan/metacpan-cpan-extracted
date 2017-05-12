package Monitoring::Spooler::Cmd::Command::phone;
$Monitoring::Spooler::Cmd::Command::phone::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::Command::phone::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: the voice transport

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
has 'iterations' => (
    'is'    => 'rw',
    'isa'   => 'Int',
    'lazy'  => 1,
    'builder' => '_init_iterations',
);
# with ...
# initializers ...
sub _init_iterations {
    my $self = shift;

    return $self->config()->get('Monitoring::Spooler::Phone::Iterations', { Default => 5, });
}

# your code here ...
sub _prepare_message_and_send {
    my $self = shift;
    my $group_id = shift;
    my $msg_ref = shift;

    # get all users that ought to be notified
    my $sql = 'SELECT id, number FROM notify_order WHERE group_id = ? ORDER BY id';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement from SQL: '.$sql.' w/ error: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }
    if(!$sth->execute($group_id)) {
        $self->logger()->log( message => 'Failed to execute statement w/ error: '.$sth->errstr, level => 'warning', );
        return;
    }
    my @numbers = ();
    while(my ($id, $number) = $sth->fetchrow_array()) {
        push(@numbers, { id => $id, number => $number });
    }
    $sth->finish();

    if(!scalar(@numbers)) {
        $self->logger()->log( message => 'Got no numbers to notify!', level => 'error', );
        return;
    }

    # just use the first supplied message
    my $message = $msg_ref->{$group_id}->[0]->{'msg'};

    # five (default) iterations over the whole list should be enough ...
    foreach my $it (1 .. $self->iterations()) {
        $self->logger()->log( message => 'Starting call iteration #'.$it.' for group #'.$group_id, level => 'debug', );
        foreach my $num (@numbers) {
            my $number = $num->{'number'};
            $self->logger()->log( message => 'Trying to send to '.$number, level => 'debug', );
            my $result = $self->_send_with_best_transport($number,$message); # "send" may be misleading here
            # since we subclass "SendingCommand" it should at least make some sense.
            # "SendingCommand" means anything the places a call or sends a text message

            # this call was not successfull, try next one in queue
            # defined coz' the DMTF value may be 0 ...
            next unless defined($result);

            # the callee pressed 3, so calls to this group will be paused for 30 minutes
            if($result == 3) { # TODO should be configurable in config ...
                my $sql = 'INSERT INTO paused_groups (group_id,until) VALUES(?,?)';
                my $sth = $self->dbh()->prepare($sql);
                my $until = time() + (30*60); # TODO LOW should confiurable in db w/ default in config and fallback in code
                $sth->execute($group_id,$until);
                $sth->finish();
                return 3;
            } else {
                # unknown result code, better call the next one
                $self->logger()->log( message => 'Unknown result code. Trying next one.', level => 'debug', );
                next;
            }
        }
    }

    $self->logger()->log( message => 'All iterations failed.', level => 'debug', );

    return;
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
    my $sql = 'DELETE FROM msg_queue WHERE group_id = ? AND type = ?';
    my $sth_del = $self->dbh()->prepare($sql);
    if(!$sth_del) {
        $self->logger()->log( message => 'Could not prepare SQL '.$sql.' due to error: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }

    # if the message was sent successfully we delete all queued messages for this group
    # anything that was inserted after this script has fetched it's initial workload
    # will be deleted, too. Since this code shall only be executed
    # on success don't want any calls during the next 30 (or so) minutes
    if(!$sth_del->execute($group_id,'phone')) {
        $self->logger()->log( message => 'Could not delete queued messages for group '.$group_id.' w/ error: '.$sth_del->errstr, level => 'warning', );
    }
    $sth_del->finish();

    return 1;
}

sub _media_type {
    return 'phone';
}

sub abstract {
    return "Process all messages of media-type phone in the notification queue";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd::Command::phone - the voice transport

=head1 METHODS

=head2 _cleanup

This method removes all queued messages for this group from the queue.

Please note that by design this will also remove any phone message for this
group that was placed in the queue after the call cycle began. This should
prevent a race condition regarding notifications of already paused groups.

It is very important that this method is invoked _after_ the group was
put on the pause list and _never_ before.

=head2 _media_type

Always return 'phone'.

=head2 _prepare_message_and_send

This methods accepts a group id and a HashRef keyed by group id. It will
initiate exactly one call for the given group id using the superclass-defined
_send_with_best_transport method. Since we don't have a useable text-to-speech
engine and I don't expect that will have one available in the forseeable future
it makes no sense to care about the message content. One phonecall should be
enought to direct the attention of at least one person on the monitoring and
from there he should be able to find out what's going on by himself.

=head2 abstract

Returns the usage string shown in the App::Cmd overview screen.

=head1 NAME

Monitoring::Spooler::App::Phone - the voice transport

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
