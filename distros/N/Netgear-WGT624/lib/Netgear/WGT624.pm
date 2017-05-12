package Netgear::WGT624;

use 5.008;

use strict;
use warnings;

our $VERSION = '0.04';

use LWP::UserAgent;

sub new {
    my $self = {};

    # Credentials necessary for connecting to router web interface.
    $self->{USERNAME} = undef;
    $self->{PASSWORD} = undef;
    $self->{ADDRESS}  = undef;
    $self->{STATS}     = undef;
    
    bless($self);
    return $self;
}


###### BEGIN Private methods.

# _query_device - Wraps another function that uses LWP to query
# router.  This method just sorts the results into an internal 
# associative array.
sub _query_device {
    my $self = shift;

    my $resref = $self->_fetch_html;

    my @vals = grep( /<span class="ttext">/, @$resref );

    my @retvals = ();

    foreach my $val (@vals) {
	if ($val =~ m/span class="ttext">(.*?)<\/span>/) {
	    push (@retvals, $1); 
	}
    }

    # Put array elements into hash based on position.
    $self->{STATS} = {
	WAN_Status      => $retvals[0],
	WAN_TxPkts      => $retvals[1],
	WAN_RxPkts      => $retvals[2],
	WAN_Collisions  => $retvals[3],
	WAN_TxRate      => $retvals[4],
	WAN_RxRate      => $retvals[5],
	WAN_UpTime      => $retvals[6],

	LAN_Status      => $retvals[7],
	LAN_TxPkts      => $retvals[8],
	LAN_RxPkts      => $retvals[9],
	LAN_Collisions  => $retvals[10],
	LAN_TxRate      => $retvals[11],
	LAN_RxRate      => $retvals[12],
	LAN_UpTime      => $retvals[13],

	WLAN_Status     => $retvals[14],
	WLAN_TxPkts     => $retvals[15],
	WLAN_RxPkts     => $retvals[16],
	WLAN_Collisions => $retvals[17],
	WLAN_TxRate     => $retvals[18],
	WLAN_RxRate     => $retvals[19],
	WLAN_UpTime     => $retvals[20],
    };

}

# _get_server_address - Make sure that address is really a 
# server address, i.e., chop off prepending http:// and 
# slashes if found.  Return the default port of 80
# for the netgear device.
sub _get_server_address {
    my $self = shift;
    
    my $address = $self->{ADDRESS};
    $address =~ s/^http:\/\///;
    $address =~ s/\/$//;

    $address .= ':80';

    return $address;
}

# _fetch_html - gets the HTML from Netgear router using LWP.
sub _fetch_html {
    my $self = shift;

    my $username = $self->{USERNAME};
    my $password = $self->{PASSWORD};
    my $address  = $self->{ADDRESS};

    my $url = $self->_make_url;

    # Use the LWP library to download the HTML page into array @html.
    my $ua = LWP::UserAgent->new();

    $ua->timeout(10);

    $ua->env_proxy;  # Use proxy environment vars, if defined.

    $ua->credentials($self->_get_server_address,
		     'WGT624',
		     $username,
		     $password);

    my $response = $ua->get($url);
    
    my @html = ();

    if ($response->is_success) {
	@html = split(/\n/, $response->content);
    } else {
	die "Error: Server returned error message: " . $response->status_line;
    }
    
    return \@html;
}

# _make_url - generates the URL from input address.
sub _make_url {
    my $self = shift;

    my $url = $self->{ADDRESS};

    # If the address doesn't have http:// prepended, add it.
    if (!($url =~ m/^http:\/\//)) {
	$url = 'http://' . $url;
    }

    # If the address ends in a slash, chop it off because it 
    # won't be necessary after next op.
    $url =~ s/\/$//;

    $url = $url . "/RST_stattbl.htm";

    return $url;
}

###### END Private methods

sub username($) {
    my $self = shift;

    if (@_) { $self->{USERNAME} = shift; }
    return $self->{USERNAME};
}

sub password($) {
    my $self = shift;

    if (@_) { $self->{PASSWORD} = shift; }
    return $self->{PASSWORD};
}

sub address($) {
    my $self = shift;

    if (@_) { $self->{ADDRESS} = shift; }
    return $self->{ADDRESS};
}

sub getStatus($$) {
    my $self = shift;
    my $param = shift;

    # Refresh our data structure containing the TxRate.
    $self->_query_device;

    return $self->{STATS}->{$param};
}

# getStatistic - this method is deprecated, and only 
# included to maintain compatibility with the now-removed
# get-wgt624-statistics test script.  It will be removed
# in future versions.
sub getStatistic($$) {
    my $self = shift;
    my $param = shift;

    return $self->getStatus($param);
}

1;

__END__

=head1 NAME

Netgear::WGT624 - Queries a Netgear WGT624 (108 Mbps Firewall Router) 
for state information.

=head1 SYNOPSIS

use Netgear::WGT624;

my $wgt624 = Netgear::WGT624->new();

$wgt624->username('myusername');

$wgt624->password('mypassword');

$wgt624->address('router-address');

my $retval = $wgt624->getStatus($element);

See the script distributed with this program, L<get-wgt624-status>,
for another example.

=head1 DESCRIPTION

Netgear::WGT624 is the library that supports programs that query the
Netgear WGT624 for state information over HTTP.

=head1 METHODS

=over 

=item $wgt624->username($username)

=item $wgt624->username()

Returns the username of the active user if called with no parameters,
or sets it if a value is passed to this method.

=item $wgt624->password($password)

=item $wgt624->password()

Returns the password of the active user if called with no parameters,
or sets it if a value is passed to this method.

=item $wgt624->address($address)

=item $wgt624->address()

Returns the address of the router if called with no parameters, or
sets it if a value is passed to this method.  The value that is stored
can be an IP address in dotted-octet format, or it can be a hostname.

=item $wgt624->getStatus($element)

Returns the value of the element passed to this method as the only
parameter, provided that WGT624 is able to contact the router with the
credentials and address specified above.

=back

=head1 LISTABLE ELEMENTS FROM WGT624

The following may be listed in the element field for output to the console:

=over

WAN_Status, WAN_TxPkts, WAN_RxPkts, WAN_Collisions, WAN_TxRate, WAN_RxRate,
WAN_UpTime, LAN_Status, LAN_TxPkts, LAN_RxPkts, LAN_Collisions, LAN_TxRate,
LAN_RxRate, LAN_UpTime, WLAN_Status, WLAN_TxPkts, WLAN_RxPkts, WLAN_Collisions,
WLAN_TxRate, WLAN_RxRate, WLAN_UpTime

=back

=head1 EXPORT

None by default.

=head1 SEE ALSO

The perldoc for L<get-wgt624-status>, and the source code of
get-wgt624-status, which uses this library.

The home page for this software at http://justin.phq.org/netgear/.

=head1 AUTHOR

Justin S. Leitgeb, E<lt>justin@phq.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This program is made available under the Artistic license, see the
README file in the package with which it was distributed for more
information.

Copyright (C) 2006 by Justin S. Leitgeb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
