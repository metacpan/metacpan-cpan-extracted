package Monitoring::Spooler::Cmd::SendingCommand;
$Monitoring::Spooler::Cmd::SendingCommand::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::SendingCommand::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: base class for any sending command

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
use Try::Tiny;
use Module::Pluggable::Object;
use Proc::ProcessTable;
use LWP::UserAgent;
use URI::Escape;

# extends ...
extends 'Monitoring::Spooler::Cmd::Command';
# has ...
has '_finder' => (
    'is'        => 'rw',
    'isa'       => 'Module::Pluggable::Object',
    'lazy'      => 1,
    'builder'   => '_init_finder',
    'accessor'  => 'finder',
);

has '_transports' => (
    'is'    => 'rw',
    'isa'   => 'ArrayRef[Monitoring::Spooler::Transport]',
    'lazy'  => 1,
    'builder' => '_init_transports',
    'accessor'  => 'transports',
);

has '_pid' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'lazy'  => 1,
    'builder' => '_init_pid',
    'reader'  => 'pid',
);

has '_fallback_url' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'lazy'  => 1,
    'builder' => '_init_fallback_url',
    'accessor' => 'fallback_url',
);

has '_ua' => (
    'is'      => 'rw',
    'isa'     => 'LWP::UserAgent',
    'lazy'    => 1,
    'builder' => '_init_ua',
);
# with ...
# initializers ...
sub _init_pid {
    my $self = shift;

    # Why is _init_pid here and not in our superclass (Command)?
    # Well, because the 'other' commands may very well run in parallel.
    # Since they only interact w/ the DB and SQLite should handle
    # concurrent accesses there is no harm. But any SendingCommand
    # interacts w/ the 'outside' where we don't have the benefit
    # of a single point of access (like, say sqlite) or ACID
    # transactions we need to make sur only one proc of a given type runs at
    # a time.

    # first we clean up any pids which aren't valid anymore ...
    $self->_clean_procs();

    # bail out if there is another one of our type running
    my $sql = 'SELECT COUNT(*) FROM running_procs WHERE type = ? AND name = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($self->_media_type(),$0);
    my $count = $sth->fetchrow_array();

    die("Already running!") if $count > 0;

    my $pid = $$;

    $sql = 'INSERT INTO running_procs (pid,type,name) VALUES(?,?,?)';
    $sth = $self->dbh()->prepare($sql);
    $sth->execute($pid,$self->_media_type(),$0);

    return $pid;
}

sub _init_finder {
    my $self = shift;

    # The finder is the class that finds our available Transports (pronounce: Plugins)
    my $Finder = Module::Pluggable::Object::->new('search_path' => 'Monitoring::Spooler::Transport');

    return $Finder;
}

sub _init_fallback_url {
    my $self = shift;

    return $self->config()->get('Monitoring::Spooler::FallbackUrl', { Default => '' });
}

sub _init_ua {
    my $self = shift;

    my $UA = LWP::UserAgent::->new();
    $UA->agent('Monitoring::Spooler/0.11');

    return $UA;
}

sub _init_transports {
    my $self = shift;

    # Allow the transports to be sorted by prio in the config with the Priority
    # key in each transport section. Why priorities? They allow us to load
    # multiple transports for each media type and try each one in a well defined
    # (as long as you don't use any single priority twice) order.
    # If one fails mysteriously we can just go on to the next. Nice, eh'?
    my $order_ref = {};

    foreach my $plugin_name ($self->finder()->plugins()) {
        ## no critic (ProhibitStringyEval)
        my $eval_status = eval "require $plugin_name;";
        ## use critic
        if(!$eval_status) {
            $self->logger()->log( message => 'Failed to require '.$plugin_name.': '.$@, level => 'warning', );
            next;
        }
        my $arg_ref = $self->config()->get($plugin_name);
        $arg_ref->{'logger'} = $self->logger();
        $arg_ref->{'config'} = $self->config();
        $arg_ref->{'dbh'}    = $self->dbh();
        if($arg_ref->{'disabled'}) {
            $self->logger()->log( message => 'Skipping disabled transport: '.$plugin_name, level => 'debug', );
            next;
        }
        try {
            my $Transport = $plugin_name->new($arg_ref);
            # skip any transport plugin that does not provide the media type
            # we want/need. Since this uses an instance method we have to
            # instantiate the class first. Well ... we _could_ use a global
            # variable which we could access right after the require but that
            # would mean we had to use a global variable. Not on my lawn ...
            die("Media-Type not supported by $plugin_name\n")
                unless $Transport->provides($self->_media_type());
            # use a default prio of 10
            my $prio = $arg_ref->{'priority'} || 10;
            push(@{$order_ref->{$prio}},$Transport);
        } catch {
            $self->logger()->log( message => 'Failed to initialize plugin '.$plugin_name.' w/ error: '.$_, level => 'warning', );
        };
    }

    my @transports = ();

    # this basically merges the pre-sorted sub-arrays (which, if you follow
    # my advice, should each contain only one element ... but we must
    # plan for the unexptected, of course)
    foreach my $prio (sort keys %$order_ref) {
        push(@transports,@{$order_ref->{$prio}});
    }

    # call fallback url if there aren't any working transports
    if(scalar(@transports) < 1 && $self->fallback_url()) {
        $self->_fallback_notify('Failed to initialize at least one transport');
    }

    return \@transports;
}

sub BUILD {
    my $self = shift;

    # just make sure our pid is in the pid list
    # a build is nice and handy by itself
    # but only BUILD will be called ALL THE WAY UP by Moose
    # on instantiation. This is usually not what you want but
    # here it should be perfect.
    $self->pid();

    return 1;
}

sub DEMOLISH {
    my $self = shift;

    # this should remove this procs pid from the pid list
    my $sql = 'DELETE FROM running_procs WHERE pid = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($self->pid());

    return;
}

# your code here ...
sub _fallback_notify {
    my $self = shift;
    my $message = shift;

    $message = 'Internal Monitoring::Spooler error' unless $message;

    if(!$self->fallback_url()) {
        $self->logger()->log( message => 'No fallback url defined. Can not send message: '.$message, level => 'error', );
        return;
    }

    my $req = HTTP::Request::->new( GET => $self->fallback_url().uri_escape($message), );
    my $res = $self->_ua()->request($req);

    if($res->is_success()) {
        $self->logger()->log( message => 'Sent '.$message, level => 'debug', );
        return 1;
    } else {
        my $errstr = $res->content();
        if($self->responses()->{$errstr}) {
            $errstr .= ' - '.$self->responses()->{$errstr};
        }
        $self->logger()->log( message => 'Failed to send '.$message.'. Error: '.$errstr, level => 'debug', );
        return;
    }
}

sub _clean_procs {
    my $self = shift;

    # this is an ugly method that removes any orphaned pids from the
    # pid list. this is annoying and expensive but we just can not rely
    # on DEMOLISH above to work properly always. Experience show
    # that it _will_ fail (at least if we don't use a method like this one).

    my $PT = Proc::ProcessTable::->new();
    my $procs = {};
    foreach my $proc (@{$PT->table()}) {
        $procs->{$proc->pid()} = $proc->cmndline();
    }
    $PT = undef;

    my $sql = 'SELECT pid,name FROM running_procs WHERE type = ?';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute($self->_media_type());
    $sql = 'DELETE FROM running_procs WHERE pid = ?';
    my $sth_del = $self->dbh()->prepare($sql);
    while(my ($pid, $name) = $sth->fetchrow_array()) {
        if(!$procs->{$pid} || $procs->{$pid} !~ m/\Q$name\E/i) {
            $sth_del->execute($pid);
        }
    }
    $sth_del->finish();
    $sth->finish();

    return 1;
}

sub _fetch_waiting_messages {
    my $self = shift;

    # get messages waiting in queue
    my $sql = 'SELECT id,group_id,message,ts,event,trigger_id FROM msg_queue WHERE type = ?';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Could not prepare SQL '.$sql.' due to error: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }
    if(!$sth->execute($self->_media_type())) {
        $self->logger()->log( message => 'Could not execute SQL '.$sql.' due to error: '.$sth->errstr, level => 'warning', );
        return;
    }
    # keep one message queue per group
    my $msg_ref = {};
    while(my ($id, $group_id, $message, $ts, $event, $trigger_id) = $sth->fetchrow_array()) {
        # don't even think about handling negating triggers here.
        # where do you think the negated one will get deleted?
        push(@{$msg_ref->{$group_id}}, {
            'id'    => $id,
            'msg'   => $message,
            'ts'    => $ts,
            'event' => $event,
            'trigger_id' => $trigger_id,
        });
    }
    $sth->finish();

    return $msg_ref;
}

sub execute {
    my $self = shift;

    # get messages waiting in queue
    my $msg_ref = $self->_fetch_waiting_messages();

    # prepare stmt to fetch notifcation interval for this group from db
    my $sql = "SELECT notify_from,notify_to FROM notify_interval WHERE group_id = ? AND type = ?";
    my $sth_ni = $self->dbh()->prepare($sql);
    if(!$sth_ni) {
        $self->logger()->log( message => 'Could not prepare SQL '.$sql.' due to error: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }

    my $msgs_sent = 0;

    # process each group
    foreach my $group_id (keys %$msg_ref) {

        # skip this group if there are no messages waiting for it,
        # shouldn't happen but what does Postel's law teach us? Right:
        # Be conservative in what you send but liberal in what you accept!
        next unless scalar(@{$msg_ref->{$group_id}});

        # skip this group if we're not inside the valid notification interval
        if(!$sth_ni->execute($group_id,$self->_media_type())) {
            $self->logger()->log( message => 'Could not execute statement: '.$sth_ni->errstr, level => 'warning', );
            next;
        }
        # since SQLite has no dedicated time datatype we use the rather ugly
        # but nonetheless working string notation of HHMM (w/ leading zeros if applicable)
        my ($notify_from, $notify_to) = $sth_ni->fetchrow_array();
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        my $nowstr = sprintf("%02d%02d", $hour, $min);
        if(
           $notify_from && $notify_to # if the group has no interval set we will notify 24/7
           && $notify_from ne $notify_to # if start and end of interval are the same we will notfiy 24/7
           && ($nowstr lt $notify_from || $nowstr gt $notify_to ) # if it's too early or too late we will skip this group for now
           ) {
            $self->logger()->log( message => 'Not within valid notification interval for group '.$group_id.' - from: '.$notify_from.' - to: '.$notify_to.' - now: '.$nowstr, level => 'notice', );
            next;
        }

        # send the message
        if($self->_prepare_message_and_send($group_id, $msg_ref)) {
            # if everything went fine we'll clean up
            $self->_cleanup(1,$group_id,$msg_ref);
        } else {
            # the current implementation of _cleanup does nothing
            # on failure, but maybe future media-types will need to, so
            # we'll call it with the apt. flag anyway
            $self->_cleanup(0,$group_id,$msg_ref);
            $self->logger()->log( message => 'Failed to process messages for group #'.$group_id, level => 'error', );
            if($self->fallback_url()) {
                $self->_fallback_notify('Failed to send messages to group: '.$group_id);
            }
        }
    }

    # delete expired pause entries
    $sql = 'DELETE FROM paused_groups WHERE until < ?';
    my $sth = $self->dbh()->prepexec($sql,time()); # no error handling, this is not essential
    $sth->finish();

    return 1;
}

sub _send_with_best_transport {
    my $self = shift;
    my $number = shift;
    my $message = shift;

    # try each defined transport until one suceeds
    foreach my $transport (@{$self->transports()}) {
        $self->logger()->log( message => 'Trying to send using transport '.ref($transport), level => 'debug', );
        my $result;
        try {
            $result = $transport->run($number,$message);
        } catch {
            $self->logger()->log( message => 'Failed to send using transport '.ref($transport).' w/ error: '.$_, level => 'notice', );
        };
        # defined is important, DTMF may return 0 (which is a successful call
        # but false in perl anyway).
        # Novice-Wannabe-Coder: "But PHP handles this better, it has TRUE and FALSE!"
        # Me: "Fu fu fu. Don't get me started about PHP ...
        # just read http://me.veekun.com/blog/2012/04/09/php-a-fractal-of-bad-design/"
        if(defined($result)) {
            return $result;
        } else {
            $self->logger()->log( message => 'Failed to send w/ transport '.ref($transport).', trying next one ...', level => 'notice', );
        }
    }

    return;
}

sub _media_type {
    # this superclass doesn't support any kind of media-type
    # this also makes sure this class won't load an transport plugins by itself
    # (i.e. w/o being subclassed)
    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd::SendingCommand - base class for any sending command

=head1 DESCRIPTION

This class is the baseclass for any command which sends messages to the outside.

It fetches any pending message from the DB and tries to send each message using the best
transport available. In order to minimize code duplication the control flow is a bit like
ping-pong.

execute fetch all waiting message from the DB using _fetch_waiting_messages which orders
them by group_id. For each group _prepare_message_and_send is called with all available
messages. This method is not implemented by SendingCommand but rather by it's
subclasses. Insnide _prepare_message_and_send the messages may be aggreated, filtered
or otherwise altered. Also this method does the escalation handling, see
...::Command::phone for an example. Inside those subclasses _send_with_best_transport
SHOULD be called. This method puts the control flow back to this class which tries
each transport by order of preference and tries to dispatch the message.

If all goes well the method cleanup is called with a true value, the group_id and
message ref. It SHOULD remove all sent messages from the queue. This method
MUST be implemented by the subclasses. See ...::Command::phone for an example.

=head1 METHODS

=head2 _clean_procs

Utility method. Removes all stale entries from the PID table.

=head2 _fallback_notify

Issue a HTTP GET request in case of severe failures as a measure of last resort.

=head2 _fetch_waiting_messages

Retrieve a HashRef containing all queued messages for the appropriate media-type.

This method calls the method _media_type which subclasses _MUST_ override.

=head2 _media_type

Subclasses of this class _MUST_ override this method and return a SCALAR string
containing the media-type they can handle.

=head2 _send_with_best_transport

This method actually send a message. It tries all successfully initialized
transports. This message should be called by the method _prepare_message_and_send
which _MUST_ be implemented by subclasses.

=head2 BUILD

This method is essential in this implementation since it places this process'
PID in the PID table and ensures concurrency control.

=head2 DEMOLISH

This method is essential in this implementatino since it removes our PID from
the PID table.

=head2 execute

This mandatory method is called by App::Cmd. It is automatically called
when the appropriate command is invoked.

=head1 NAME

Monitoring::Spooler::Cmd::SendingCommand - base class for any command which sends messages.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
