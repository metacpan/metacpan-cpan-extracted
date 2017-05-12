package Net::MDNS::Server;

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

# This allows declaration	use Net::MDNS::Server ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
service
claim_hostname
process_network_events
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Net::MDNS::Server::constant not defined" if $constname eq 'constant';
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

sub service
	{
		my ( $hostname, $ip, $service, $port, $proto) = @_;
		my $rev_ip = join('.', reverse(split(/\./, $ip)));
		add_service($hostname, $rev_ip, $port, $service, $proto);
	}
sub claim_hostname
	{
		my ( $hostname, $ip) = @_;
		my $rev_ip = join('.', reverse(split(/\./, $ip)));
		add_hostname($hostname, $rev_ip);
	}

require XSLoader;
XSLoader::load('Net::MDNS::Server', $VERSION);

# Preloaded methods go here.

start();

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::MDNS::Server - Perl extension for a multicast DNS server

=head1 SYNOPSIS

	use Net::MDNS::Server ':all';
	service("myhost", "10.0.0.1", 444, "perl", "tcp");
	while (1) {process_network_events}


=head1 ABSTRACT

  Advertises network services using the multicast DNS protocol, allows clients to find servers.
  May work with Apple's Rendevous software.

=head1 DESCRIPTION

Multicast DNS is a lightweight protocol designed to allow easy configuration of computers on a network.  You can advertise services (like http, or ftp, or anything you make up).  It also allows for dynamic port numbers since part of the response to a query is the port number the service is running on.  

Multicast DNS is a UDP service that runs on port 5353.

This module monitors the network for queries and responds if it has an answer.  If it doesn't, it keeps quiet.  In this way multiple computers can form a sort of 'DNS cluster' without even knowing about each other.

In addition, multiple servers can run on the same machine, and they will keep out of each others way, thanks to the magic of UDP.

The upshot of this is that each application can advertise its own services to the network, reusing this module, without having to worry about colliding with other servers on the same machine.

The module Net::MDNS::Client can be used to query these services.

=head1 FUNCTIONS

=over 1

=item Net::MDNS::Server::start()

Initialises the MDNS system.  This is called automatically for you when you load the module.  You don't need to call this unless you stop MDNS first.

=item Net::MDNS::Server::stop()

Stops the MDNS system.  Right now it's the only way of removing services.

=back

=head2 EXPORT

=over 1

=item claim_hostname(hostname, ip)

Claim the hostname.  The server will start answering requests for this hostname.  Any other server that tries to get this hostname will fail.  Naturally, if you get in second, you will fail to get the hostname.

The IP is in dotted decimal format.

e.g. claim_hostname("my_computer", "10.0.0.1");

=item service(hostname, ip, port number, service name, protocol)

Start advertising a service.  The service name should be a commonly recognised one like "http" or "ssh", but you are free to make up your own.  The protocol should be "tcp" or "udp".

You can use any hostname, ip address and port number that you feel like, but there aren't many good reasons to advertise services for another machine.

You may advertise as many services as you like.

e.g. service("myhostname", "1.0.0.10", "25", "smtp", "tcp")

=item process_network_events()

You have to call this as often as possible.  If you don't call it enough, you'll start missing requests.

=head1 BUGS

Some aspects of mDNS, like adding data to the service records, are not yet supported, but are planned.

The biggie is that service() and claim_hostname() do not return pointers to the records created, so the created services cannot be deleted.  I tried returning the pointers as integers but that didn't work.  Any patches would be very much appreciated.

Also, the service call should probably be spilt into multiple calls that create individual records.

=head1 SEE ALSO

The multicast DNS system is still in RFC draft stage, so search the web for "multicast DNS" for more details.

=head1 AUTHOR

Jepri, E<lt>jepri@perlmonk.org<gt>

Jer, E<lt>jer@jabber.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jepri  (Perl and C wrappers)

Copyright 2003 by Jer  (C library)



This library is free software; you can redistribute it and/or modify
it under the same terms as the GPL. 

=cut
