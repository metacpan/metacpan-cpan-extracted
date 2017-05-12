=head1 NAME

Synapse::Monitor::Listener


=head1 About Synapse's Open Telephony Toolkit

L<Synapse::Monitor::Listener> is a part of Synapse's Wholesale Open Telephony Toolkit.

As we are refactoring our codebase, we at Synapse have decided to release a
substantial portion of our code under the GPL. We hope that as a developer, you
will find it as useful as we have found open source and CPAN to be of use to
us.


=head1 What is L<Synapse::Monitor::Listener> all about

In the wholesale telecom business, you need to monitor a lot of stuff. For
example, for each egress and ingress route (and there's hundreds of them and
thousands of dialcodes), you need to permaently check answer seizure ration,
average length of call, MOS, customer credit limit usage, make sure your
systems are up and ping-eable, CPU load, etc. etc.

The idea is that you have a collection of scripts / daemons / cron jobs / etc
which product Ip<event files>. Events have an associated type (e.g. 'ping'),
I<status> (e.g. UNKNOWN, OK, WARNING, DOWN), and indentifier (e.g. ping
example-dot-com).

What L<Synapse::Monitor::Listener> does is that it picks up newly created
events and can be configured to perform a set of predefined actions when it
detects an I<event change>, such as firing an email, suspending a service,
blocking an IP address, etc.


=head1 L<Synapse::Monitor::Listener> overview and installation

The library is split as follows:

=over 4

=item script synapse-monitor-listener-cli, used to create and set configuration objects.

=item script synapse-monitor-listener-service, which is a daemon desgined to be
running in the background

=item L<Synapse::Monitor::Listener>, listener object, which is designed to
choose what action(s) to do with .evt.yml objects / files.

=item L<Synapse::Monitor::Listener::Action>, listener action object, which is
designed to define and execute arbitrary actions.

=back

You install the package as follows:

    perl Makefile.PL
    make
    make test
    make install
    synapse-monitor-listener-cli --create-configdir
    synapse-monitor-listener-service install
    synapse-monitor-listener-service start

synapse-monitor-listener-service should then start on each reboot, runlevels
3-5. You can check that this is the case and that the daemon has been correctly
installed using the excellent chkconfig linux tool.


=head1 L<Synapse::Monitor::Listener> configuration

Note: L<Synapse::Monitor::Listener> does NOT need restarting once you have
changed the configuration.

For the sake of the example - and because this package is designed to be a
telephony package after all - let's say we have a bunch of call detail record
(or "cdr") files on the filesystem. Each file contains a list of calls, wether
they were answered or not, the call duration, etc.

Say we want to check and monitor ASR values, i.e. how many calls were answered
on the last 100 calls. We have written a script, called asrcheck.pl, which runs
in the background, and which produces notification files looking like this:

    ---
    id: asr-myvoipsupplier-moroccomobilemeditel
    state: OK
    listener: asr
    destination: Morocco-Mobile-Meditel
    vendor: myvoipsupplier
    notification-email: customer.service@example.com
    head-wc: 100
    asr: 62

Notification files should be placed in /tmp/ and end with .evt.yml.
synapse-monitor-listener-service will process these files as they appear and
delete them after they have been processed.

The only required fields are "listener", "state", and "id". All the rest is
optional but your underlying "action" scpripts could use the extra information.
A copy of the file will be passed to them as $ENV{YAML_FILE}.

=over 4

=item id - should be unique across all listeners. i.e. there shouldn't be an
"asr" listener called "foo" and an "acd" listener called "foo". Set up your
scripts to call your checks "asr-foo" and "acd-foo" instead.

=item state - can be any string without spaces. The number of states should be
discrete and finite.

=item listener - which listener configuration to use on this type of check.

=back

For the sake of the example, say we have 3 possible states:


=over 4

=item OK : when the ASR is > 30

=item WARNING : when the ASR is < 30 but > 10

=item DOWN : when the ASR is < 10

=back


We need to let L<Synapse::Monitor::Listener> know what to do when there is a
I<state change> on this type of notification.


First, let's configure an "asr" listener:

    # first of all, create our "ASR listener" object
    synapse-monitor-listener-cli type listener create asr "ASR listener"

    # DOWN -> OK, or WARN -> OK : cool...    
    synapse-monitor-listener-cli listener asr action WARN.DOWN OK asr-email-goodjob
    
    # OK -> WARN : send warning email
    synapse-monitor-listener-cli listener asr action OK WARN asr-email-warning
    
    # OK -> DOWN or WARN -> DOWN = send "down" email + suspend route
    synapse-monitor-listener-cli listener asr action OK.WARN DOWN asr-email-down suspend-route


Now that's done, let's configure matching actions:

    # a copy of the YAML notification file will be passed as $ENV{YAML_FILE}, set up your scripts accordingly...
    # format is
    # synapse-monitor-listener-cli type action create useless-action echo I_AM_USELESS >/dev/null
    
    # to delete an action:
    # synapse-monitor-listener-cli action useless-action remove
     
    synapse-monitor-listener-cli type action create asr-email-goodjob synapse-email-notification /etc/synapse-monitor/emails/goodjob.xml
    synapse-monitor-listener-cli type action create asr-email-warning synapse-email-notification /etc/synapse-monitor/emails/warning.xml
    synapse-monitor-listener-cli type action create asr-email-down synapse-email-notification /etc/synapse-monitor/emails/down.xml
    synapse-monitor-listener-cli type action create email-restored synapse-email-notification /etc/synapse-monitor/emails/restored.xml
    synapse-monitor-listener-cli type action create suspend-route synapse-suspend-route


That's it. You don't need to restart the daemon: the configuration changes are
picked up immediately.

=cut
package Synapse::Monitor::Listener;
use base qw /Synapse::CLI::Config::Object/;
use Synapse::Logger;
use YAML::XS;
use warnings;
use strict;


our $VERSION = 0.3;
our $EVTDIR  = '/tmp';
our $EVTEXT  = '.evt.yml';


sub action {
    my $self    = shift;
    my $before  = shift;
    my $after   = shift;
    my @actions = @_;
    if ($before =~ /\./) {
        for my $before (split /\./, $before) {
            $self->action ($before, $after, @actions);
        }
        return $self;
    }
    if ($after =~ /\./) {
        for my $after (split /\./, $after) {
            $self->action ($before, $after, @actions);
        }
        return $self;
    }
    
    $self->{action} ||= {};
    $self->{action}->{$before} ||= {};
    $self->{action}->{$before}->{$after} = \@_;
    return $self;
}


sub process {
    my $self     = shift;
    my $oldState = shift;
    my $newState = shift; 
    my $event    = shift;
    $self->{action}->{$oldState} || do {
        logger ($self->name() . ": no action specified for old state $oldState");
        return;
    };
    $self->{action}->{$oldState}->{$newState} || do {
        logger ($self->name() . ": no action specified for old state $oldState to new state $newState");
        return;
    };

    logger ($self->name() . ": iterating actions for $oldState -> $newState");
    for my $action (@{$self->{action}->{$oldState}->{$newState}}) {
        logger ("action: $action");
        my $action_obj = Synapse::Monitor::Listener::Action->new ($action);
        if ($action_obj) { $action_obj->process ($event) }
        else {
            logger ("$action: cannot instantiate object - skipping");
            next;
        }
    };
}


sub __evtfiles__() {
    opendir EVTDIR, $EVTDIR;
    my @files = readdir (EVTDIR);
    closedir EVTDIR;
    my @res = ();
    for my $file (@files) {
        $file =~ /\Q$EVTEXT\E$/ or next;
        -e "$EVTDIR/$file"      or next;
        -e "$EVTDIR/$file.lock" and next;
        push @res, "$EVTDIR/$file";
    }
    return @res;
}


sub __loadfile__($) {
    my $file = shift;
    open YAMLFILE, $file or return;
    my $data = join '', <YAMLFILE>;
    close YAMLFILE;
    return Load $data;
}


sub runonce {
    my $class = shift;
    for my $file (__evtfiles__) {
        my $event = __loadfile__ $file;
        unlink $file;
        $event || next;

        my $id       = $event->{id}            || next;
        my $newState = $event->{state}         || next;
        my $listener = $event->{listener}      || next;
        
        my $oldState = Synapse::Monitor::Listener::State->new ($id) || Synapse::Monitor::Listener::State->create ($id => 'UNKNOWN');
        $oldState    = $oldState->label();
        
        $oldState eq $newState and next; 
        $listener    = $class->new ($listener) || next;
        eval { $listener->process ($oldState, $newState, $event) };
        Synapse::CLI::Config::execute ("Synapse::Monitor::Listener::State", $id, "set", "label", $newState);
    }
}


1;


__END__


=head1 EXPORTS

none.


=head1 BUGS

Please report them to me. Patches always welcome...


=head1 AUTHOR

Jean-Michel Hiver, jhiver (at) synapse (dash) telecom (dot) com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
