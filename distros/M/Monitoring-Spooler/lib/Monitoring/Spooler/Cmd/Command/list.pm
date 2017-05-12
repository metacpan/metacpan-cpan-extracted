package Monitoring::Spooler::Cmd::Command::list;
$Monitoring::Spooler::Cmd::Command::list::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::Command::list::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: list all queued notifications

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
has 'all' => (
    'is'    => 'ro',
    'isa'   => 'Bool',
    'default' => 0,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'a',
    'documentation' => 'When set prints all tables/queues',
);

has 'group_id' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'g',
    'documentation' => 'Restrict output to this Group ID',
);
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;

    # just print the queue content if invoked w/o options
    # we may also print all tables if the user asks for them
    my $sql = 'SELECT id, group_id, type, message, ts FROM msg_queue';
    my @args = ();
    if($self->group_id()) {
        $sql .= ' WHERE group_id = ?';
        push(@args, $self->group_id());
    }
    $sql .= ' ORDER BY id';
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute(@args);

    my $msg_ref = {};
    while(my ($id, $group_id, $type, $message) = $sth->fetchrow_array()) {
        push(@{$msg_ref->{$group_id}}, {
            'id'    => $id,
            'group_id' => $group_id,
            'type'  => $type,
            'message' => $message,
        });
    }
    $sth->finish();

    if(scalar(keys %$msg_ref)) {
        foreach my $group_id (sort keys %$msg_ref) {
            print "Messages waiting in Queue for Group ".$group_id."\n";
            foreach my $msg (@{$msg_ref->{$group_id}}) {
                printf("[%4d] %s %s\n", $msg->{'id'}, $msg->{'type'}, $msg->{'message'});
            }
        }
    } else {
        print "Queue is empty\n";
    }

    if($self->all()) {
        my $sql = 'SELECT id, name FROM groups ORDER BY name';
        my $sth = $self->dbh()->prepare($sql);
        $sth->execute();
        while(my ($id, $name) = $sth->fetchrow_array()) {
            printf("%s (%i)\n", $name, $id);
        }
        $sth->finish();

        $sql = 'SELECT group_id, until FROM paused_groups ORDER BY group_id';
        $sth = $self->dbh()->prepare($sql);
        $sth->execute();
        while(my ($id, $until) = $sth->fetchrow_array()) {
            printf("%i => %s\n", $id, localtime($until));
        }
        $sth->finish();

        $sql = 'SELECT group_id,type,notify_from,notify_to FROM notify_interval ORDER BY group_id';
        $sth = $self->dbh()->prepare($sql);
        $sth->execute();
        while(my ($group_id, $type, $notify_from, $notify_to) = $sth->fetchrow_array()) {
            printf("%i %s %s - %s\n", $group_id, $type, $notify_from, $notify_to);
        }
        $sth->finish();
    }

    return 1;
}

sub abstract {
    return "List the notification queue";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd::Command::list - list all queued notifications

=head1 DESCRIPTION

This class implements the command to list all messages currently in the queue.

=head1 METHODS

=head2 excute

Lists the current queue content.

=head1 NAME

Monitoring::Spooler::Cmd::Command::List - List the current queue content.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
