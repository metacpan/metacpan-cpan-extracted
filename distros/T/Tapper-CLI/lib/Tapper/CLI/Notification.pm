package Tapper::CLI::Notification;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Notification::VERSION = '5.0.5';
use 5.010;
use warnings;
use strict;


sub notificationnew
{
        my ($c) = @_;
        $c->getopt( 'file|f=s', 'user|u=s','quiet|q', 'help|?', 'verbose|v' );

        if (not %{$c->options} or $c->options->{help} ) {
                say STDERR "Usage: $0 notification-add --file=filename [ --user=login ] [ --quiet ]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "        --file             name of file containing the notification subscriptions in YAML (required)";
                say STDERR "\n  Optional arguments:";
                say STDERR "        --user             set this user for all notification subscriptions (even if a different one is set in YAML)";
                say STDERR "        --verbose          Be chatty";
                say STDERR "        --quiet            Stay silent when notification was added";
                say STDERR "        --help             print this help message and exit";
                return;
        }

        require Tapper::Cmd::Notification;
        my $cmd = Tapper::Cmd::Notification->new();
        my $user = $c->options->{user};

        my @ids;
        require YAML::XS;
        my @subscriptions =  YAML::XS::LoadFile($c->options->{file});
        foreach my $subscription (@subscriptions) {
                if ($user) {
                        $subscription->{owner_login} = $user;
                        delete $subscription->{owner_id};
                }
                push @ids, $cmd->add($subscription);
        }
        my $msg;
        if (not $c->options->{quiet}) {
                $msg  = "The notification subscriptions were registered with the following ids:" if $c->options->{verbose};
                $msg .= join ",", @ids;
        }
        return $msg;
}


sub notificationlist
{
        my ($c) = @_;

        require YAML::XS;
        require Tapper::Cmd::Notification;

        my $cmd = Tapper::Cmd::Notification->new();
        my $subscription_result = $cmd->list();
        while (my $this_subscription = $subscription_result->next) {
                delete $this_subscription->{created_at};
                delete $this_subscription->{updated_at};
                print YAML::XS::Dump($this_subscription);
        }
        return;
}


sub notificationupdate
{
        my ($c) = @_;
        $c->getopt( 'file|f=s', 'id|i=i','quiet|q', 'help|?' );

        if (not %{$c->options} or $c->options->{help} ) {
                say STDERR "Usage: $0 notification-update --file=filename --id=id [ --quiet ]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "        --file             name of file containing the notification subscriptions in YAML";
                say STDERR "        --id               id of the notification subscriptions";
                say STDERR "\n  Optional arguments:";
                say STDERR "        --quiet            stay silent when notification was updated";
                say STDERR "        --help             print this help message and exit";
                return;
        }

        require Tapper::Cmd::Notification;
        my $cmd = Tapper::Cmd::Notification->new();

        require YAML::XS;
        my $subscription =  YAML::XS::LoadFile($c->options->{file});
        my $id = $cmd->update($c->options->{id}, $subscription);

        if ( not $c->options->{quiet}) {
                return $id;
        }
        return;
}


sub notificationdel
{
        my ($c) = @_;
        $c->getopt( 'id|i=i','quiet|q', 'help|?' );

        if (not %{$c->options} or $c->options->{help} ) {
                say STDERR "Usage: $0 notification-del --id=id";
                say STDERR "\n\  Required Arguments:";
                say STDERR "        --id               Database ID of the notification subscription";
                say STDERR "\n  Optional arguments:";
                say STDERR "        --quiet            Stay silent when deleting succeeded";
                say STDERR "        --help             print this help message and exit";
                return;
        }

        require Tapper::Cmd::Notification;
        my $cmd = Tapper::Cmd::Notification->new();

        my $id = $cmd->del($c->options->{id});

        return "The notification subscription was deleted." unless $c->options->{quiet};
        return;
}




sub setup
{
        my ($c) = @_;
        $c->register('notification-add', \&notificationnew, 'Register a new notification subscription');
        $c->register('notification-new', \&notificationnew, 'Alias for notification-add');
        $c->register('notification-list', \&notificationlist, 'Show all notification subscriptions');
        $c->register('notification-update', \&notificationupdate, 'Update an existing notification subscription');
        $c->register('notification-del', \&notificationdel, 'Delete an existing notification subscription');
        if ($c->can('group_commands')) {
                $c->group_commands(
                    'Notification commands',
                        'notification-add',
                        'notification-new',
                        'notification-list',
                        'notification-update',
                        'notification-del',
                );
        }
        return;
}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Notification

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Notification;
    Tapper::CLI::Notification::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Notification - Tapper - notification commands for the tapper CLI

=head1 FUNCTIONS

=head2 notificationnew

Register new notification subscriptions.

@param file     - contains the new subscription in YAML, multiple can be given
@optparam user  - overwrite user information given in the file or set if none
@optparam quiet - only return notification ids
@optparam help  - print out help message and die

=head2 notificationlist

Show all or a subset of notification subscriptions

@optparam

=head2 notificationupdate

Update an existing notification subscription.

@param file - name of the file containing the new data for subscription notification in YAML
@param id   - id of the notification subscription to update
@optparam quiet - only return ids of updated notification subscriptions
@optparam help  - print out help message and die

=head2 notificationdel

Delete an existing notification subscription.

@param id       - id of the notification subscription to delete
@optparam quiet - stay silent when deleting succeeded
@optparam help  - print out help message and die

=head2 setup

Initialize the notification functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
