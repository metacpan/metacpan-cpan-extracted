package Net::MDNS::Client;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::MDNS::Client ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	cancel_query
	get_a_result
	make_query
	process_network_events
	query
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	MAX_STRING
);

our $VERSION = '0.04';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Net::MDNS::Client::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Net::MDNS::Client', $VERSION);

# Preloaded methods go here.

start();

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::MDNS::Client - Perl extension for the multicast DNS client.

=head1 SYNOPSIS

  use Net::MDNS::Client ':all';
  my $q = make_query("host by service", "", "local.", "perl", "tcp");
  query( "host by service", $q);
  while (1) {
   if (process_network_events()) {
    while (1) {
    my $res = get_a_result("host by service", $q);
     print "Found host: ", $res, "\n";
      sleep 1;
   } } }


=head1 ABSTRACT

  Multicast DNS allows all computers on the network to answer DNS queries.  There is no central DNS, every computer answers questions regarding itself, and keeps quite if the query concerns another machine.  Multicast queries tend to be things like "all http servers, please announce yourself", and you get a list of all nearby https servers, or printers, or whatever you asked for.
  This client allows you to query the multicast DNS servers on your network.  It may even work with Apple's rendevous software.
  The companion module, Net::DNS::Server, allows your computer to become a multicast DNS server.

=head1 DESCRIPTION

This module monitors the network for traffic, and builds an internal cache of answers.  To do this, you should call process_network_events quite a few times per second (as many as possible).  To send a query, you have to build a query string with "make_query" (or you can do it yourself if you know how).  Call query with the query string and the type of query, call process_network_events for a second and then start calling get_a_result with exactly the same parameters as the query.  You can run multiple queries at the same time, and the get relevent answers by calling get_a_result with the correct query string.

It is slightly naughty to only call process_network_events when you are looking for an answer, but it does work.


=head1 FUNCTIONS

=over 1

=item Net::MDNS::Client::start()

	This is called for you when you load the module.  You only need this if you stop and start MDNS.

=item Net::MDNS::Client::stop()

	Stops MDNS and frees the memory.  You probably don't need to do this.

=back 

=head1 EXPORTED FUNCTIONS

=over 1

=item $query_string = make_query(query_type, hostname, service, domain, protocol);

make_query builds a query string to be used by the 'query' and 'cancel_query' functions.  If you are familiar with multicast DNS queries you can skip this step and build your own.  For everyone else, use this one. 
	You may omit either the hostname or the service name.  The domain should always be "local." (other may be used, but local is the local network).  The protocol should be "tcp" or "udp".

e.g. make_query("host by service", "", "local.", "smtp", "tcp");

=item query(query_type, $query_string);

query sends a query to the network.  It returns control immediately, and you should start calling 'process_network_events' to deal with the responses to your query.

=item cancel_query(query_type, $query_string);
	
Supply exactly the same parameters as you did to query.

=item get_a_result(query_type, $query_string);

Supply exactly the same parameters as you did to query.  mdnsd keeps a list of responses, and will give you one response from the list each time you call it until it gets to the end of the list, where it returns undef.  The next call to get_a_response will start from the beginning of the list again.

The return values differ by the query type that you use, and the context that you call it in.

	"host by service"
	Scalar: A hostname, without domain name.
	Array : A hash containing the response details (including hostname)

	"ip by hostname"
	Scalar: An IP address in dotted quad form (e.g. 10.0.0.1)
	Array : A hash containing the response details (including IP address)

	"data by hostname"
	Scalar: the port number for the service you requested
	Array : A hash containing the response details.
	For "data by hostname", the rdata hashkey may hold interesting information about the server you just contacted.

=item process_network_events()

This does all the work of receiving answers from the network and processing them.  You should call this function lots of times per second.  You should also be calling it even if you don't have any queries currently active, because it listens to other peoples' queries and builds a cache of known hosts.


=back

=head1 BUGS

Calling cancel_query current crashes perl.  So don't cancel queries for the moment.  In practise, this isn't a big problem since the query system was designed to be very efficient, and also if you do a query once, you'll probably want to do it again.  The overhead for storing queries isn't very large.

=head1 SEE ALSO

The RFC is still in draft form, so do a web search for "multicst DNS"

There is a program called relay.pl included in this distribution.  It will relay ordinary DNS queries to multicast DNS queries.  Read its pod for more information.

=head1 AUTHOR

Jepri, jepri@perlmonk.org (Perl and C wrappers)

Jer, jer@jabber.org	(C library)

=head1 THANKS

Michael Bauer


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jepri (wrappers)
Copyright 2003 by Jer (library)

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL. 

=cut
