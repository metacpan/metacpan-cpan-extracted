package Net::SSH::Perl::Proxy;
use strict;
use warnings;
use base 'Net::SSH::Perl';

=head1 NAME

Net::SSH::Perl::Proxy - Use TCP proxy to connect to a host via SSH

=head1 SYNOPSIS

    my $ssh = Net::SSH::Perl::Proxy->new('myhost',
        proxy => {
            host => 'proxyhost',
            port => 1080,
        }
    );

    $ssh->login();

=head1 DESCRIPTION

This class extends C<Net::SSH::Perl> to allow connections through
a SOCKS proxy.

=cut

use Carp;
use IO::Socket::Socks;

sub _init {
	my $self = shift;
	my %parm = @_;
	if ($parm{proxy}) {
		$self->{Proxy} = {
			ProxyAddr => $parm{proxy}{host},
			ProxyPort => $parm{proxy}{port},
		};
	}
	$self->SUPER::_init(%parm);
}

sub _connect {
	my $ssh = shift;
	return $ssh->SUPER::_connect(@_) unless $ssh->{Proxy};

	my $rport = $ssh->{config}->get('port') || 22;
	$ssh->debug("Connecting to $ssh->{host}:$rport");
	my $sock = IO::Socket::Socks->new(
		ConnectAddr => $ssh->{host},
		ConnectPort => $rport,
		%{$ssh->{Proxy}},
		Timeout => 5,
	) or die "Can't connect to $ssh->{host}:$rport : $!";

	select((select($sock), $|=1)[0]);

	$ssh->{session}{sock} = $sock;
	$ssh->_exchange_identification;

	defined( $sock->blocking(0) ) or die "Can't set non-blocking: $!";
	$ssh->debug("Connection established.");
}

1;

__END__

=head1 SEE ALSO

L<Net::SSH::Perl>

=head1 AUTHOR

Lance Kinley E<lkinley@loyaltymethods.com>

=head1 COPYRIGHT

Copyright (c) 2015 Loyalty Methods, Inc.  All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
