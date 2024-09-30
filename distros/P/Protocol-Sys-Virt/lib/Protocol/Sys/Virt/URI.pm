####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1,
#        XDR::Gen version 0.0.5 and LibVirt version v10.3.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.14;
use warnings;

package Protocol::Sys::Virt::URI v10.3.12;

use parent qw(Exporter);

use Carp qw(croak);
use Log::Any qw($log);
use URI::Encode qw(uri_encode uri_decode);

our @EXPORT = qw( parse_url );

sub parse_url {
    my $url = shift;
    my ($base, $query) = split( /\?/, $url, 2 );
    $query //= '';
    my %args = map {
        uri_decode($_)
    }
    map {
        my ($key, $val) = split( /=/, $_, 2 );
        $val //= '';
        ($key, $val);
    }
    split( /&/, $query );

    if ($base =~ m#^
                (?<hypervisor>[a-z0-9_]+)
                (?:\+(?<transport>[a-z0-9_]+))?
                ://
                (?:(?<username>[^@]+)@)?
                ((?<host>[a-z0-9_\-\.]+)
                 (?:\:(?<port>\d+))?
                )?
                /
                (?<type>system|session)
                $
                #xi) {
        my $bare = "$+{hypervisor}:///$+{type}";
        $bare .= '?' if ($args{mode} or $args{socket});
        $bare .= 'mode=' . uri_encode($args{mode},
                                      { encode_reserved => 1 })
            if $args{mode};
        $bare .= '&' if ($args{mode} and $args{socket});
        $bare .= 'socket=' . uri_encode($args{socket},
                                        { encode_reserved => 1 })
            if $args{socket};
        return (base => $base,
                proxy => $bare,
                name => "$+{hypervisor}:///$+{type}",
                %+,
                query => \%args);
    }

    die "Malformed hypervisor URI $url";
}

1;


__END__

=head1 NAME

Protocol::Sys::Virt::URI - Helper routines for parsing LibVirt URIs

=head1 VERSION

v10.3.12

=head1 SYNOPSIS

  use Protocol::Sys::Virt::URI;

  my %components = parse_url( 'qemu+ssh://user@password:host/system?param=value' );

=head1 DESCRIPTION

Helper functions operating on LibVirt hypervisor URLs.

=head1 FUNCTIONS

=head2 parse_url

  my %components = parse_url( 'qemu+ssh://user@hostname:port/system?param=value&mode=legacy&socket=/path/socket' );
  # { base => 'qemu+ssh://user@password:host/system',
  #   proxy => 'qemu:///system?mode=legacy&socket=/path/socket',
  #   name  => 'qemu:///system',
  #   query => { param => 'value', mode => 'legacy', socket => '/path/socket' },
  #   transport => 'ssh',
  #   hypervisor => 'qemu',
  #   username => 'user,
  #   host => 'hostname',
  #   port => 'port',
  # }

Splits the URL into the components necessary for use with the LibVirt API.

=over 8

=item base

This is the URL without the query string and fragment.

=item proxy

This is the URL to be passed through to a proxy: it strips all but
the parameters applicable to the end point (currently the C<socket>
and C<mode> parameters are passed through).

=item name

This is the URL as it should be passed to the C<name> parameter in
the protocol's C<REMOTE_PROC_CONNECT_OPEN> message.

=item query

Contains a hashref with the (URI-decoded) name/value pairs from
the query string.

=item transport

The fraction of the protocol following the C<+>; eg., C<ssh> in C<qemu+ssh>.

=item hypervisor

The fraction of the protocol before the C<+>, or lacking a plus-sign, the
protocol; eg., C<qemu> in C<qemu+ssh>.

=item username

The user name embedded in the URL, preceeding the host name, if any.

=item host

The name (or IP address) of the host with the hypervisor.

=item port

The port on the host with the hypervisor to connect to.

=back

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT

See the LICENSE file in this distribution.

