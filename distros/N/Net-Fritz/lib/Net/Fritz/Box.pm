use strict;
use warnings;
# Copyright (C) 2015  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v2 or later.

package Net::Fritz::Box;
# ABSTRACT: main configuration and entry point for L<Net::Fritz> distribution
$Net::Fritz::Box::VERSION = 'v0.0.5';

# We need LWP::UserAgent 6.00 because of ssl_opts.  We could work with
# an older version as seen in # https://github.com/rhuss/jmx4perl/issues/28
# but SOAP::Lite might then have the same problem...  For now just
# stick with the versioned dependency.
use LWP::UserAgent 6.00;
use XML::Simple qw(:strict);

use Net::Fritz::Error;
use Net::Fritz::Device;

use Moo;

with 'Net::Fritz::IsNoError';


has upnp_url      => ( is => 'ro', default => 'http://fritz.box:49000' );


has trdesc_path   => ( is => 'ro', default => '/tr64desc.xml' );


has username      => ( is => 'ro' );


has password      => ( is => 'ro' );

# internal XML::Simple instance (lazy)
has _xs           => ( is => 'lazy', init_arg => undef );

sub _build__xs {
    return XML::Simple->new(ForceArray => 1, KeyAttr => []);
}

# internal LWP::UserAgent instance (lazy)
# overwriting the default might be handy for setting proxy variables or the like
has _ua           => ( is => 'lazy' );

sub _build__ua {
    # Depending on your SSL setup (propably which SSL modules LWP::UserAgent uses
    # for transport), this is also needed to disable certificate checks.
    # I have one machine that needs it and another that doesn't.
    $ENV{HTTPS_DEBUG} = 1;
    
    my $ua = LWP::UserAgent->new(keep_alive => 1);
    $ua->conn_cache({total_capacity => 4});
    # disable SSL certificate checks, Fritz!Box has no verifiable SSL certificate
    $ua->ssl_opts(verify_hostname => 0 ,SSL_verify_mode => 0x00);
    
    return $ua;
}

# internal SSL attributes for SOAP::Lite instances (lazy)
has _sslopts      => ( is => 'lazy' );

sub _build__sslopts {
    my $self = shift;

    # use the SSL options from the LWP::UserAgent instance
    # copy ALL keys including undefined values
    return [ map { $_ => $self->_ua->ssl_opts($_) } $self->_ua->ssl_opts ];
}


sub discover {
    my $self = shift;

    my $url = $self->upnp_url . $self->trdesc_path;
    
    my $response = $self->_ua->get($url);
    
    if ($response->is_success) {
	return Net::Fritz::Device->new(
	    xmltree => $self->_xs->parse_string($response->decoded_content)->{device}->[0],
	    fritz   => $self
	    );
    }
    else {
	return Net::Fritz::Error->new($response->status_line)
    }
}


sub dump {
    my $self = shift;
    my $indent = shift;
    $indent = '' unless defined $indent;

    my $text = "${indent}Net::Fritz::Box:\n";
    $indent .= '  ';
    $text .= "${indent}upnp_url    = " . $self->upnp_url    . "\n";
    $text .= "${indent}trdesc_path = " . $self->trdesc_path . "\n";

    return $text;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Fritz::Box - main configuration and entry point for L<Net::Fritz> distribution

=head1 VERSION

version v0.0.5

=head1 SYNOPSIS

    my $fritz = Net::Fritz::Box->new();
    $fritz->dump();

    my $fritz_ssl = Net::Fritz::Box->new(
        upnp_url => 'https://fritz.box:49000'
    );

    my $fritz_auth = Net::Fritz::Box->new(
        username => 'admin',
        password => 's3cr3t'
    );

=head1 DESCRIPTION

This class the global configuration state and provides discovery of
L<Net::Fritz::Device>s.

=head1 ATTRIBUTES (read-only, defaults can be changed)

=head2 upnp_url

Default value: C<http://fritz.box:49000>

Base URL for all operations.  This must point to your device. The
default value expects a standard Fritz!Box installation with working
local DNS.

If you can't do DNS lookups for your router, use an IP address
instead.

If you have a Fritz!Box and don't know its IP, you can try
C<192.168.179.1> or C<169.254.1.1>, these adresses seem to be
hardcoded for "emergency use" after a misconfiguration.

An address starting with C<https://> enables secure communication over
SSL, but see L<Net::Fritz/SSL> for bugs and limitations.

=head2 trdesc_path

Default value: C</tr64desc.xml>

The path below L</upnp_url> from where the TR064 service description
is fetched.  There should be no need to change the default.

=head2 username

Default value: none

Sets the username to use for authentication against a device.

=head2 password

Default value: none

Sets the password to use for authentication against a device.

=head2 error

See L<Net::Fritz::IsNoError/error>.

=head1 METHODS

=head2 new

Creates a new L<Net::Fritz::Box> object.  This is propably the first
thing to do when using L<Net::Fritz>.  Expects parameters in C<key
=E<gt> value> form with the following keys to overwrite the default
values:

=over

=item L</upnp_url>

=item L</trdesc_path>

=item L</username>

=item L</password>

=back

=head2 discover

Tries to discover the TR064 device at the current L</upnp_url>.
Returns a L<Net::Fritz::Device> on success.  Accepts no parameters.

=head2 dump(I<indent>)

Returns some preformatted multiline information about the object.
Useful for debugging purposes, printing or logging.  The optional
parameter I<indent> is used for indentation of the output by
prepending it to every line.

=head2 errorcheck

See L<Net::Fritz::IsNoError/errorcheck>.

=head1 SEE ALSO

See L<Net::Fritz> for general information about this package,
especially L<Net::Fritz/INTERFACE> for links to the other classes.

=head1 AUTHOR

Christian Garbs <mitch@cgarbs.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Christian Garbs

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
