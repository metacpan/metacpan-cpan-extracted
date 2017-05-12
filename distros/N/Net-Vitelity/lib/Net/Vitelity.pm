package Net::Vitelity;

use warnings;
use strict;
use LWP::UserAgent;

=head1 NAME

Net::Vitelity - Interface to Vitelity API

=cut

our $VERSION = '0.03';

our $AUTOLOAD;

=head1 SYNOPSIS

    use Net::Vitelity;

    my $vitelity = Net::Vitelity->new(
                                       'login' => $your_login,
                                       'pass'  => $your_pass,
                                     );

=head1 METHODS

=cut

=head2 new

Create a new Net::Vitelity object.  login and pass are required.

=cut

sub new {
    my ($class,%data) = @_;
    die "missing user and/or password" unless defined $data{'login'} && defined $data{'pass'};
    my $self = { 'login' => $data{'login'}, 'pass' => $data{'pass'} };
    $self->{apitype} = $data{'apitype'} ? $data{'apitype'} : 'api';
    bless $self, $class;
    return $self;
}

sub AUTOLOAD {
  my $self = shift;

  $AUTOLOAD =~ /(^|::)(\w+)$/ or die "unparsable AUTOLOAD: $AUTOLOAD";
  my $cmd = $2;
  return if $cmd eq 'DESTROY';

  my $ua = LWP::UserAgent->new;

  #XXX md5 encrypt pass

  my $URL_API = 'http://64.74.178.105/api.php';
  my $URL_FAX = 'http://64.74.178.105/fax.php';

  my $url = $URL_API;
  $url = $URL_FAX if $self->{apitype} eq 'fax';

  my $response = $ua->post($url, {
                    login => $self->{login}, 
                    pass  => $self->{pass},
                    cmd   => $cmd,
                    @_,
                  }
           );

  die $response->status_line unless $response->is_success;

  my $content = $response->decoded_content;

  $content =~ /x\[\[(.*)\[\[x/s;
  $content = $1;

  wantarray ? split("\n", $content) : $content;

}

=head2 listtollfree

List ALL available toll free numbers

Possible Results: none OR [list of tf numbers]

=head2 callfromclick

Sends someone a phone call that then connects them to customer service/another number.

Options: number=number AND servicenumber=number

Possible Results:OK or INVALID

=head2 listlocal

Lists ALL available local numbers in a specific state and ratecenter

Requires: state=STATE

Options: type=unlimited OR type=pri OR withrates=yes
               ratecenter=RATECENTER

Possible Results: unavailable or missing or [list of dids]

=head2 gettollfree

Orders a specific toll free number in our available list (SLOW)
Requires: did=TOLL-FREE-NUMBER
Options: routesip=route_to_this_subaccount
Possible Results: success or unavailable or missingdid

=head2 getlocaldid

Orders a specific local number from our available list

Requires: did=AVAILABLE-LOCAL-NUMBER

Options: type=perminute OR type=unlimited OR type=your-pri OR
               routesip=route_to_this_subaccount

Possible Results: invalid or success or missingdid

=head2 removedid

Remove Local or Toll Free DID from account

Requires: did=AVAILABLE-LOCAL-NUMBER

Possible Results: success OR unavailable OR missingdid

=head2 listratecenters

Lists all of the available rate centers for a specific state line by line

Requires: state=STATE (ie, state=CO)

Options: type=perminute OR type=unlimited OR type=pri

Possible Results: unavailable OR missingdata OR [list of ratecenters]

=head2 listavailratecenters

Lists all available rate centers DIDs are currently in stock for a specific state line by line

Requires: state=STATE (ie, state=CO)

Options: type=unlimited OR type=pri

Possible Results: missingdata OR unavailable or [list of ratecenters]

=head2 requestvanity

Orders a specific available toll free number from the SMS database.

Requires: did=8009879891 (number can be any available number)

Possible Results: missingdata OR exists OR success

=head2 searchtoll

Searches the SMS/800 database for an available number matching the specific data you provide

Requires: did=8**333****

Possible Results: none OR missingdata OR [list of avail numbers]

=head2 listavailstates

Lists all states that have DIDs which are currently in stock

Options: type=perminute OR type=unlimited OR type=pri

Possible Results: unavailable OR [list of states]

=head2 liststates

Lists all available DID states line by line

Options: type=perminute OR type=unlimited OR type=pri

Possible Results: unavailable OR [list of states]

=head2 cnam

Lookup a specific caller id number for the name

Requires: did=3037855015 (number)

Possible Results: missingdata OR [cnam value]

=head2 searchtoll

Searches the SMS/800 database for an available number matching the specific data you provide

Requires: did=8**333****

Possible Results: none OR missingdata OR [list of avail numbers]

=head2 localbackorder

Orders a specific local number from our available list

Requires: ratecenter=RATECENTER and state=STATE

Options: type=perminute OR type=unlimited

Possible Results: invalid OR ok OR missing

=head2 reroute

Changes the sub account a DID rings to.

Requires: did=DID_NUMBER & routesip=SIP_SUB_ACCOUNT

Possible Results: missingdata OR ok OR invalid

=head2 balance

Reports back your current account balance

=head2 listdids

Lists all current Local and Toll free DIDs

Options: extra=yes

Results: number,ratecenter,price_per_minute,subaccount

extra=yes adds STATE,MONTHLY_DID_RATE

=head2 routeall

Changes the routing on all dids to a specific sip account

Requires: routesip=sub_account OR routesip=login (routes to main)

Possible Results: ok OR invalid

=head2 getrate

Gets a rate on a specific domestic or International call

Requires: number=[countrycode_thenumber] ex: 01144.. or 1303..

Results: invalid OR the_rate_per_minute

=head2 subaccounts

Lists sub accounts

Requires: do=list

Possible Results: subaccount list separated by return OR invalid

=head1 All Possible Result Return Codes

=over 4

=item success

The request you made was successful

=item missingdata

You are missing login= or pass= or cmd= or other in your URL string

=item invalidauth

You have submitted an invalid login or password

=item missingrc

You are missing the ratecenter or state for a specific local did order

=item unavailable

The number you requested is not available

=item none

There are no numbers available

=item missingdid

you are missing &did=number

=item list of data

If you asked for a list of numbers and we had some available, they will be listed.

In a list contect, all entries will be returned in a list.  In a scalar
scalar context, entries will be separated by newlines.

=back

=head1 AUTHOR

Ivan Kohler, C<< <ivan-vitelity at freeside.biz> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-vitelity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Vitelity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Vitelity

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Vitelity>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Vitelity>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Vitelity>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Vitelity>

=back

=head1 ADVERTISEMENTS

This module was developed by Freeside Internet Services, Inc.
Need a complete, open-source back-office and customer self-service solution?
The Freeside software includes Vitelity integration, CDR rating,
invoicing, credit card and electronic check processing, integrated trouble
ticketing and customer signup and self-service web interfaces.

http://freeside.biz/

Development sponsored by Voice Carrier LLC.  If you need a hosted or on-site
PBX, please visit http://www.voicecarrier.com/

=head1 COPYRIGHT & LICENSE

Copyright 2009-2012 Freeside Internet Services, Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

