package Monitoring::Spooler::Cmd::Command::create;
$Monitoring::Spooler::Cmd::Command::create::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::Command::create::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: enqueue a new notification

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
extends 'Monitoring::Spooler::Cmd::Command';
# has ...
has 'group_id' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'required' => 1,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'g',
    'documentation' => 'Message for this Group ID',
);

has 'type' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 't',
    'documentation' => 'Message is of this type (text or phone)',
);

has 'message' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'm',
    'documentation' => 'the Message',
);
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;

    my $message = $self->message();

    my $trigger_id = 0;
    my $event = '';

    return 0 unless $self->type() =~ m/^(?:text|phone)$/i;

    # Handle negating triggers
    if($self->type() eq 'text'
       && $self->config()->get('Monitoring::Spooler::NegatingTrigger')
       && $message =~ m/^\s*(\d+)\s+(OK|UP|DOWN|PROBLEM)\s/) {
        $trigger_id = $1;
        $event = $2;
        # remove the leading trigger id
        $message =~ s/^\s*\d+\s+//g;
        # remove any trailing spaces
        $message =~ s/\s+$//;

        # if we got an trigger id and this is a recovery message
        # we look for any related down trigger and delete it
        if($event =~ m/^(?:OK|UP)$/ && $trigger_id) {
            my $sql = 'DELETE FROM msg_queue WHERE event = ? AND trigger_id = ? AND type = ? AND group_id = ?';
            my $sth = $self->dbh()->prepare($sql);
            if($sth->execute('DOWN',$trigger_id,'text',$self->group_id()) && $sth->rows() > 0) {
                $self->logger()->log( message => 'Deleted negated trigger(s) from DB - trigger_id: '.$trigger_id.' - event: '.$event.' - group_id: '.$self->group_id(), level => 'debug', );
                return 1;
            }
        }
    }

    # Do not insert new messages into queue for paused groups
    if($self->type() eq 'phone') {
        my $sql = 'SELECT COUNT(*) FROM paused_groups WHERE until > ? AND group_id = ?';
        my $sth = $self->dbh()->prepexec($sql,time(),$self->group_id());
        my $count = $sth->fetchrow_array();

        if($count > 0) {
            $self->logger()->log( message => 'Rejected new message "'.$self->message().'" to paused group', level => 'debug', );
            return 1;
        }
    }

    # create new message in queue
    my $sql = 'INSERT INTO msg_queue (group_id,type,message,ts,event,trigger_id) VALUES(?,?,?,?,?,?)';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement ('.$sql.'): '.$self->dbh()->errstr, level => 'error', );
        return;
    }
    if($sth->execute($self->group_id(),$self->type(),$message,time(),$event,$trigger_id)) {
        $self->logger()->log( message => 'Successfully enqueued new message (group/type/message): '.$self->group_id().'/'.$self->type().'/'.$self->message(), level => 'debug', );
        $sth->finish();
        return 1;
    } else {
        $self->logger()->log( message => 'Failed to execute statement: '.$sth->errstr, level => 'error', );
        $sth->finish();
        return;
    }
}

sub abstract {
    return "Place a new message in the notification queue";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd::Command::create - enqueue a new notification

=head1 DESCRIPTION

This class implements a command to add a new message to the queue.

This command is usually invoked by your Monitoring (as a media transport) or some
other noficiation script. All the boilerplate work is done by
MooseX::App::Cmd.

=head1 NAME

Monitoring::Spooler::Cmd::Command::Create - Command to create new messages

=head1 SETUP

In order for negating triggers to work you need to use a certain message
template: {TRIGGER.ID} {TRIGGER.STATUS} {TRIGGER.NAME}

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
