package Monitoring::Spooler;
$Monitoring::Spooler::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Notification queue for Zabbix, Nagios, et.al.
use strict;
use warnings;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler - Notification queue for Zabbix, Nagios, et.al.

=head1 NAME

Monitoring::Spooler - a notification queue for Zabbix, Nagios and other montioring systems

=head1 SETUP

=head2 GET A TEXT AND/OR VOICE PROVIDER

First you need to sign up at a suitable text and/or voice provider, e.g. sipgate.

You'll need the credentials for this provider later.

=head2 CONFIGURATION

See below for an example configuration. Place it at /etc/mon-spooler/spooler.conf.

Adjust DBFile (path to SQLite database, needs to be writeable by cronjob and webapp),
TemplatePath, StaticPath and the list of transports. Set the credentials from the
previous step here. Remove any transport you don't have credentials for.

=head2 RUN BOOTSTRAP

Run the bootstrap command:

   mon-spooler.pl bootstrap --name=<newgrp>

This will create an initial group and set things up.

WARNING: Make sure the database file is owned by the user service the webinterface
and also accessible by the user execution your cronjobs, e.g. www-data.

    chown -R www-data:www-data /var/lib/mon-spooler/

=head2 CREATE CRONJOBS

Create at least one cronjob here. If you have set-up an provider which supports
both text and phone messages you should set up two cronjobs here, otherwise
create only one for either phone or test messages.

=head2 CREATE NOTIFICATION QUEUE

At the moment there is no easy built-in interface to populate the notification
queue with a set of contacts. The recommended way is to use App::Standby for
that. If you opt not to, then I'd recommend using bare SQL:

  sqlite3 /var/lib/mon-spooler/db.sqlite3

=head2 SETUP MONITORING

Set up your monitoring to send notifications the this external command:

   mon-spooler.pl create -g<group_id> -t<{text|phone}> -m<message>

If you've created only one group and only want to send text messages this could
look like this:

   mon-spooler.pl create -g1 -ttext -m<MSG>

How you pass MSG depends on your monitoring solution. Take a look at the next
subsection on setup with Zabbix.

=head3 ZABBIX SETUP

To allow Zabbix to trigger external notifications you'll need some kind of wrapper
script since Zabbix is very strict on how and where it'll place it's notifications.

First you'll need to set AlertScriptsPath in you zabbix_server.conf to some
exisiting path. If it is already set remember this path.

Next you'll need to place a simple wrapper script (e.g. a shell script) into this
directory. The script, named e.g. ms_wrapper.sh, could look like this:

   #!/bin/bash
   mon-spooler.pl create -g$1 -ttext -m"$2"

Next you'll need to add a new Media Type in Zabbix with the type Script and the Script
name set to ms_wrapper.sh.

Zabbix will always pass the media property (e.g. number) first, and then the message.

Since this distribution does it's own contact/escalation handling we don't care about
the destination number and will use the destination field to multiplex between the
different groups. Each of which will have it's own contact list and escalation handling.

For each group you need to create an new use in Zabbix. Name it like <group>.queue, e.g.
admins.queue and developers.queue. For each of these "queue-users" you need to add a
new media w/ the newly defined type and an "Send To" value which matches the group id
within Monitoring::Spooler.

Afterwards you'll need to create a new action with an appropriate name, an event source of triggers,
no escalations, a subject and concise message as well as recovery messages. The "operation" should
send a message to new appropriate "queue user".

=head3 NAGIOS SETUP

To setup nagios, or any nagios compatible product like icinga, shinken or naemon, is pretty
straight forward. Just call "mon-spooler.pl create -g<Group-Id> -t<text|phone> -m<MSG>"
like you'd call any other external notification script.

More examples on nagios will follow shortly.

=head2 SETUP WEBINTERFACE

In this optional step you can set up the included webinterface and http API.

CGI and PSGI endpoints are provided. Give the usual usage scenario of this App an
CGI employment should be fine, but if you run into any performance issues
w/ the web app you should first try to run it under any PSGI wrapper,
e.g. Starman.

=head1 CONFIGURATION

<Monitoring>
    <Spooler>
        NegatingTrigger = 1
        DBFile          = /var/lib/mon-spooler/db.sqlite3
        <Frontend>
            TemplatePath = /var/lib/mon-spooler/tpl
            StaticPath   = /var/lib/mon-spooler/res
        </Frontend>
        <Transport>
            <Sipgate>
                Username = Test
                Password = Test
                Priority = 1
            </Sipgate>
            <Smstrade>
                Apikey = xyz
                Route = basic
                Priority = 99
            </Smstrade>
            <FreeSwitch>
                hostname = localhost
                port = 8021
                password = pass
                priority = 1
                url = sofia/gateway/provider.tld
                # url = freetdm/1/
                defaultaudio = /var/lib/mon-spooler/audio/default_alarm_multi.wav
            </FreeSwitch>
            <Pjsua>
                sipid = sip:user@sipgate.de
                registrar = sip:sipgate.de
                realm = *
                username = user
                password = pass
                outbound = sip:sipgate.de
                stunsrv = stun.sipgate.net:10000
                Priority = 99
            </Pjsua>
        </Transport>
    </Spooler>
</Monitoring>

=head1 SEE ALSO

This distribution is much like the commerical PagerDuty service. Only that it's free,
self-hosted and fully customizable.

=head1 DEBUGGING

If anything goes wrong have a look at the logfile at /var/log/mon-spooler-web.log or
/tmp/mon-spooler-weg.log.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
