Net-Radiator-Monitor

NAME

Net::Radiator::Monitor - Perl interface to Radiator Monitor command language

SYNOPSIS

This module provides a Perl interface to Radiator Monitor command language.

         use strict;
         use warnings;

         use Net::Radiator::Monitor;
         use Carp qw(croak);

         my $monitor = Net::Radiator::Monitor->new(
                                                       user    => $user,
                                                       passwd  => $passwd,
                                                       server  => $server,
                                                       port    => 9084,
                                                       timeout => 5
                                               ) or croak "Unable to create monitor: $!\n";

         print $monitor->id;

         $monitor->quit;

METHODS

   new
         my $monitor = Net::Radiator::Monitor->new(
                                               user    => $user,
                                               passwd  => $passwd,
                                               server  => $server,
                                               );

       Constructor - creates a new Net::Radiator::Monitor object using the specified parameters.  This method
       takes three mandatory and two optional parameters.

       user
           The username to use to connect to the monitor interface.  This username must have the required access
           to connect to the monitor.

       passwd
           The password for the username use to connect to the monitor interface.

       server
           The server to connect to - this should be either a resolvable hostname or an IP address.

       port
           The port on which to connect to the monitor interface - this parameter is optional and if not
           specified will default to the Radiator default port of 9084.

       timeout
           The connection timeout value and recieve timeout value for the connection to the Radiator server -
           this parameter is optional and if not specified will default to five seconds.

   quit
         $monitor->quit;

       Closes the monitor connection.

   id
         my $id = $monitor->id;

       Returns the Radiator server ID string.  the string has the following format:

         ID <local_timestamp> Radiator <version> on <servername>

       Where:

       <local_timestamp>
           Is the current local time on the server given in seconds since epoch.

       <version>
           Is the Radiator server version.

       <servername>
           Is the configured server name.

   server_stats
         my %server_stats = $monitor->server_stats;

         foreach my $stats (sort keys %server_stats) {
           print "$stats : $server_stats{$stats}\n"
         }

       Returns a hash containing name,value pairs of collected server statistics.  Server statistics are
       culminative values of access and accounting across all configured objects.

       The measured statistics (and the keys of the hash) are:

         Access challenges
         Access rejects
         Access requests
         Accounting requests
         Accounting responses
         Average response time
         Bad authenticators in accounting requests
         Bad authenticators in authentication requests
         Dropped access requests
         Dropped accounting requests
         Duplicate access requests
         Duplicate accounting requests
         Malformed access requests
         Malformed accounting requests
         Total Bad authenticators in requests
         Total dropped requests
         Total duplicate requests
         Total proxied requests
         Total proxied requests with no reply
         Total requests

   client_stats ($client_id)
         my %client_stats = $monitor->client_stats($client_id);

       Returns a hash containing name,value pairs of collected statistics for client specified by the value of
       the client id.  The available statistics are the same as those listed for the server_stats method.

       The list_clients method can be sed to retrieve valid client IDs.

   list_clients
         while (($id, $name) = each $monitor->list-clients) {
           print "Client : $name - ID : $id\n"
         }

       Returns a hash containing all configured clients where the key is the numerical identifier for the realm
       and the value is the client name or IP address (dependent on configuration).

   list_realms
       Returns a hash containing all configured realms where the key is the numerical identifier for the realm
       and the value is the realm name.

   list_handlers
       Returns a hash containing all configured handlers where the key is the numerical identifier for the
       handler and the value is the handler name.

AUTHOR

Luke Poskitt, "<ltp at cpan.org>"

INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Net::Radiator::Monitor

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Radiator-Monitor

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Net-Radiator-Monitor

    CPAN Ratings
        http://cpanratings.perl.org/d/Net-Radiator-Monitor

    Search CPAN
        http://search.cpan.org/dist/Net-Radiator-Monitor/


LICENSE AND COPYRIGHT

Copyright (C) 2012 Luke Poskitt

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

