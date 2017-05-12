package Mock::Net::Ping;

use strict;
use warnings;
use 5.006;
no warnings 'redefine';
use vars qw( $VERSION );

use Socket qw( inet_aton );
use Carp;

$VERSION = '0.09';

# Override Net::Ping::ping
# Any private IP address, localhost and any IP from 127.0.0.0/8 will always pass.
# Other hosts and IPs will fail.
*Net::Ping::ping = sub
{
    my ($self,
        $host,              # Name or IP number of host to ping
        $timeout,           # Seconds after which ping times out
    ) = @_;
    my ($ip,                # Packed IP number of $host
        $ret,               # The return value
        $ping_time,         # When ping began
        $address            # address of $host
    );

    croak("Usage: \$p->ping(\$host [, \$timeout])") unless @_ == 2 || @_ == 3;
    $timeout = $self->{"timeout"} unless defined $timeout;
    croak("Timeout must be greater than 0 seconds") if $timeout <= 0;

    return unless defined $host;

    # Dispatch to the appropriate routine.
    $ping_time = &Net::Ping::time();
    if ( $host eq 'localhost' )
    {
        $address = '127.0.0.1';
        $ret = 1;
    }
    elsif ( $host =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ )
    {
        my $packed = inet_aton( $host );
        # modified version of regex from http://www.perlmonks.org/?node_id=791164
        # ret = 1 if local or private and 0 otherwise
        ( $ret ) = 0 + ( $packed =~ m{^(?:\x0a|\x7F|\xAC[\x10-\x1F]|\xC0\xA8)} ); 
        $address = $host;
    }
    else
    {
        $address = $host;
        $ret = 0;
    }

    return wantarray ? ($ret, &Net::Ping::time() - $ping_time, $address) : $ret;
};

1;
__END__

=head1 NAME

Mock::Net::Ping - Mock Net::Ping's ping method

=for HTML 
    <a href="https://travis-ci.org/mrmuskrat/Mock-Net-Ping"><img src="https://travis-ci.org/mrmuskrat/Mock-Net-Ping.svg?branch=master"></a>
    <a href='https://coveralls.io/r/mrmuskrat/Mock-Net-Ping?branch=master'><img src='https://coveralls.io/repos/mrmuskrat/Mock-Net-Ping/badge.png?branch=master' alt='Coverage Status' /></a> 

=head1 SYNOPSIS

    use Net::Ping;
    require Mock::Net::Ping;

    my $p = Net::Ping->new();
    my $host = '127.0.0.1';
    my ( $ok, $elapsed ) = $p->ping( $host );
    printf "%s is %s reachable\n", $host, $ok ? '' : 'NOT';
    $host = '8.8.8.8';
    my ( $ok, $elapsed ) = $p->ping( $host );
    printf "%s is %s reachable\n", $host, $ok ? '' : 'NOT';

=head1 DESCRIPTION

This module mocks Net::Ping by overriding the methods. Currently 
ping is the only method supported.

=head2 Functions

=over 4

=item $p->ping($host [, $timeout]);

Pretend to ping the remote host and wait for a response. $host can 
be either the hostname or the IP number of the remote host. The 
optional timeout must be greater than 0 seconds and defaults to
whatever was specified when the ping object was created. Returns a
success flag. If the host is localhost, any address in 127.0.0.0/8
or any private IP address, the success flag will be 1. For all 
other hosts, the success flag willbe 0. In array context, the 
elapsed time as well as the host that was passed (except localhost 
will be converted to 127.0.0.1). The elapsed time value will depend
on which version of L<Net::Ping> you have installed as well as
whether or not you have called its hires method; it will either
be an integer (as returned by CORE::time()) or a float (as returned
by Time::HiRes::time()).

=back

=head1 ACKNOWLEDGEMENTS

This module would not exist without L<Net::Ping> and this 
documentation is based heavily on that.

=head1 AUTHOR

    Matthew Musgrove <mr.muskrat@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014, Matthew Musgrove. All rights reserved.

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=cut



