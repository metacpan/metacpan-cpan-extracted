package Net::Dynect::REST::info;
# $Id: info.pm 177 2010-09-28 00:50:02Z james $

1;

__END__

=head1 NAME

Net::Dynect::REST::info - Information about the Net::Dynect::REST modules

=head1 DESCRIPTION

The Net::Dynect::REST, Net::Dynect::REST::Request and Net::Dynect::REST::Response implemnt a basic framework for the sending and recieving of queries to Dynect. While you're free to use that, a more polished API exists to permit you to deal with objects. This more polished API is an implementation of the (majority of) the Dynect REST API.

The modules that can be used correspond to the documentation of the REST API:

=over 4

=item * L<Net::Dynect::REST::AAAARecord> - for IPv6 address resource records

=item * L<Net::Dynect::REST::ARecord> - for IPv4 address records

=item * L<Net::Dynect::REST::CNAMERecord> - for CNAME (alias) records

=item * L<Net::Dynect::REST::DNSKEYRecord> - for public key that resolvers can use to verify DNSSEC

=item * L<Net::Dynect::REST::DSRecord> - for the delegation signer for the zone

=item * L<Net::Dynect::REST::KEYRecord> - the older record for public keys for DNSSEC

=item * L<Net::Dynect::REST::LOCRecord> - The location of the recource - latitude, longditure, altitude (sometimes called the ICMB resource record)

=item * L<Net::Dynect::REST::MXRecord> - The Mail Exchanger record

=item * L<Net::Dynect::REST::NSRecord> - the Name Server record

=item * L<Net::Dynect::REST::SRVRecord> - the Service record

=item * L<Net::Dynect::REST::TXTRecord> - for TXT (text) records

=back

In addition, the following classes exist:

=over 4

=item * L<Net::Dynect::REST::ANYRecord> - to retrieve all the objects that exist for a FQDN - eg, ARecords, AAAARecords, TXTRecords... in one hit

=item * L<Net::Dynect::REST::Job> - get the status message for a specific Job ID. See L</Jobs> below.

=item * L<Net::Dynect::REST::Node> - delete all types of records under a node (eg, wipe out everything for an FQDN)

=item * L<Net::Dynect::REST::NodeList> - get all FQDN records in a zone

=item * L<Net::Dynect::REST::Password> - change passwords for users

=item * L<Net::Dynect::REST::QPSReport> - get the Queries per second report, with various breakdowns

=item * L<Net::Dynect::REST::ZoneChanges> - find pending changes in a zone that have yet to be published.

=back

=head1 IMPLEMENTATION OVERVIEW

The basic idea to interact is:

=over 4

=item 1. Get an Auth Token by establishing a Session object. This happens when you call Net::Dynect::REST with sufficient authentication parameters. You can expore the session by looking at your object's session() method. See L<Net::Dynect::REST::Session>.

=item 2. Perform any other requests you want, using this Auth Token (handled transparently by this Perl implementation). Eachof the abstractions need to be passed the L<Net::Dynect::REST> object which should have your session established.

=item 3. Save any changes in your objects so they are ready to publish. Generally this is the save() method on each object.

=item 4. Commit those changes by B<publishing> the corresponding B<Zone>. This will increment the zone serial according to the update style chosen automatically.

=item 5. Logout using the logout() method on the L<Net::Dynect::REST> object.

=back

For example:

 my $dynect = Net::Dynect::REST->new(user_name => 'me', customer_name => 'myco', password => 'mysecret');
 my $zone = Net::Dynect::REST::Zone->new(connection => $dynect, zone => 'example.com');
 my $new_address = Net::Dynect::REST::ARecord->new(connection => $dynect, zone => 'example.com', fqdn => 'www.example.com', rdata => { address => '1.2.3.4' } );
 $new_address->save;
 $zone->publish;
 $dynect->logout;

=head1 JOBS

Every Request that is submitted (except one type, see later) is assigned a unique Job ID. You can fetch that by looking at the Request Objects job_id() method. If you wish to get the resquest's response again, you can call the Net::Dynect::REST::Job function with the relevant Job ID - it is thi call to /REST/Job/ that will not have a unique JobID, but the Job ID of the original request. This is useful for long running jobs - the client can disconnect (with its Job ID) and check back later for the eventual return data.

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::Request>, L<Net::Dynect::Response>.


=head1 AUTHOR

James Bromberger, james@rcpt.to.

=cut
