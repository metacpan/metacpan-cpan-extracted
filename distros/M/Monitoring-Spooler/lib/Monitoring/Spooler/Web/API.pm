package Monitoring::Spooler::Web::API;
$Monitoring::Spooler::Web::API::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Web::API::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: the API endpoint for the spooler

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
use URI::Escape;
use Try::Tiny;
use JSON;

# extends ...
extends 'Monitoring::Spooler::Web';
# has ...
has 'json' => (
    'is'    => 'ro',
    'isa'   => 'JSON',
    'lazy'  => 1,
    'builder' => '_init_json',
);
# with ...
# initializers ...
sub _init_json {
    my $self = shift;

    my $JSON = JSON::->new()->utf8();

    return $JSON;
}

sub _init_fields {
    return [qw(mode group_id queue message)];
}

# your code here ...
sub _handle_request {
    my $self = shift;
    my $request = shift;

    my $mode = $request->{'mode'} || 'update_queue';

    if($mode eq 'update_queue') {
        # set the new notification/escalation queue
        if($self->_handle_update_queue($request)) {
            return [ 200, ['Content-Type', 'text/plain'], ['OK']];
        } else {
            return [ 400, ['Content-Type', 'text/plain'], ['Bad Request']];
        }
    } elsif($mode eq 'send_text') {
        # enqueue a single text message
        if($self->_handle_send_text($request)) {
            return [ 202, ['Content-Type', 'text/plain'], ['Your messages has been queued for deliery.']];
        } else {
            return [ 400, ['Content-Type', 'text/plain'], ['Bad Request']];
        }
    } else {
        return [ 400, ['Content-Type', 'text/plain'], ['Bad Request']];
    }

    return 1;
}

sub _handle_send_text {
    my $self = shift;
    my $request = shift;

    # This is just an convenience method for sending text messages
    # through the spooler. Uncommon but you should never stop
    # people from doing it the wrong way ... 'uhm wait, did I get that right? ;)

    my $group_id = $request->{'group_id'};
    my $message = $request->{'message'};

    return unless $group_id && $message;

    $message = URI::Escape::uri_unescape($message);

    my $sql = "INSERT INTO msg_queue (group_id,type,message) VALUES(?,'text',?)";
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }
    if(!$sth->execute($group_id,$message)) {
        $self->logger()->log( message => 'Failed to execute statement: '.$sth->errstr, level => 'warning', );
        return;
    }
    $sth->finish();

    return 1;
}

sub _handle_update_queue {
    my $self = shift;
    my $request = shift;

    # This method is the primary purpose of this class:
    # Update the notification queue for a given group

    my $group_id = $request->{'group_id'};
    my $queue = $request->{'queue'};
    my $message = $request->{'message'} || 'You are now the primary contact for Monitoring Notifications';

    if(!$queue || !$group_id) {
        $self->logger()->log( message => 'Missing queue or group_id. Aborting.', level => 'error', );
        return;
    }

    $queue = URI::Escape::uri_unescape($queue);
    my $queue_ref = undef;
    try {
        $queue_ref = $self->json()->decode($queue);
    } catch {
        $self->logger()->log( message => 'Failed to decode JSON: '.$_, level => 'warning', );
    };
    $queue = undef;

    # if json decoding above failed we must exit here, since we've got
    # nothing to write in the DB.
    if(!$queue_ref) {
        $self->logger()->log( message => 'Queue is empty after decoding JSON. Aborting.', level => 'error', );
        return;
    }

    my $sql = 'SELECT COUNT(*) FROM groups WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($group_id);
    my $has_group = $sth->fetchrow_array();
    $sth->finish();

    if(!$has_group) {
        # the requested group doesn't exist
        $self->logger()->log( message => 'The requested group does not exist. Aborting.', level => 'error', );
        return;
    }

    # before we start to modify the DB, we start a TX so we can
    # rollback later
    $self->dbh()->do('BEGIN TRANSACTION');

    # remove the old notification queue for this group
    $sql = 'DELETE FROM notify_order WHERE group_id = ?';
    $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement: '.$self->dbh()->errstr, level => 'warning', );
        $self->dbh()->do('ROLLBACK');
        return;
    }
    if(!$sth->execute($group_id)) {
        $self->logger()->log( message => 'Failed to execute statement: '.$sth->errstr, level => 'warning', );
        $self->dbh()->do('ROLLBACK');
        return;
    }
    $sth->finish();

    # insert each user of the new notification queue into the DB in the order
    # that they were sent to us.
    $sql = 'INSERT INTO notify_order (group_id,name,number) VALUES(?,?,?)';
    $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement: '.$self->dbh()->errstr, level => 'warning', );
        $self->dbh()->do('ROLLBACK');
        return;
    }

    foreach my $user (@$queue_ref) {
        if(!$sth->execute($group_id,$user->{'name'},$user->{'cellphone'})) {
            $self->logger()->log( message => 'Failed to execute statement: '.$sth->errstr, level => 'warning', );
            $self->dbh()->do('ROLLBACK');
            return;
        }
        # if this user has an alternated number defined insert it, too
        if($user->{'phone_alt'}) {
            if(!$sth->execute($group_id,$user->{'name'}.' (Fallback)',$user->{'phone_alt'})) {
                $self->logger()->log( message => 'Failed to execute statement: '.$sth->errstr.'. Ignoring!', level => 'warning', );
            }
        }
    }
    $sth->finish();

    # send a welcome message to our new primary contact.
    # this should be configurable on a per-group base in the db
    $sql = "INSERT INTO msg_queue (group_id,type,message) VALUES(?,'text',?)";
    $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }
    if(!$sth->execute($group_id,$message)) {
        $self->logger()->log( message => 'Failed to execute statement: '.$sth->errstr, level => 'warning', );
        return;
    }
    $sth->finish();

    # everything ok, make changes durable
    if($self->dbh()->do('COMMIT')) {
        $self->logger()->log( message => 'Successfully update queue for group '.$group_id, level => 'debug', );
    }

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Web::API - the API endpoint for the spooler

=head1 ATTRIBUTES

=head2 json

The JSON parser. Must be an instance of JSON.

=head1 NAME

Monitoring::Spooler::Web::API - the API endpoint implementation

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
