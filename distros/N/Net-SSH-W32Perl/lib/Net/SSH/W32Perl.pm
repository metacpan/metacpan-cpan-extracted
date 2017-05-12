package Net::SSH::W32Perl;

use strict;
use Carp;

use IO::Socket;

use Net::SSH::Perl;
use Net::SSH::Perl::Constants qw( :protocol );
use constant DEFAULT_SSH_PORT => '22';
use constant IS_WIN32 => ($^O =~ /MSWin32/i);

use vars qw/ $VERSION @ISA/;
$VERSION = '0.05';

@ISA = qw/Net::SSH::Perl/;

sub _init {
	my $ssh = shift;
	my %arg = @_;

   $arg{protocol} = 2 unless exists $arg{protocol};

    $ssh->SUPER::_init(%arg);
}

sub _connect {
    my $ssh = shift;
    return $ssh->SUPER::_connect(@_) unless IS_WIN32;

    my $rport = $ssh->{config}->get('port') || DEFAULT_SSH_PORT;
    my $rhost = $ssh->{host};

    $ssh->debug("Connecting to $ssh->{host}, port $rport.");
    my $sock = IO::Socket::INET->new(
    	PeerAddr => $rhost,
        PeerPort => $rport,
        Proto    => 'tcp'
    ) || die "Can't connect to $rhost: $!\n";
	
    $ssh->{session}{sock} = $sock;

	my $t = $|;
	$| = 0;
    $ssh->debug("Socket created, turning on blocking...");
    $sock->blocking(1);
    $ssh->_exchange_identification;
    $sock->blocking(0);
	$| = $t;

    $ssh->debug("Connection established.");
}

sub protocol_class {
    return shift->SUPER::protocol_class(@_) unless IS_WIN32;
    
    die "SSH2 is the only supported protocol under MSWin32!"
        unless (PROTOCOL_SSH2 == $_[1]);
        
	return 'Net::SSH::W32Perl::SSH2';
}

sub Close {}

1;
__END__

=head1 NAME

Net::SSH::W32Perl - MSWin32 compatibility layer for Net::SSH::Perl

=head1 SYNOPSIS

 use Net::SSH::W32Perl;

 my $host = 'foo.bar.com';
 my $ssh = new Net::SSH::W32Perl($host, [options]);
 $ssh->login('user', 'password');
 my ($out, $err, $exit) = $ssh->cmd('cat', 'Hello Net::SSH::W32Perl User!');

=head1 DESCRIPTION

This module provides limited Net::SSH::Perl functionality 
under MSWin32 (ActivePerl).  See L<Net::SSH::Perl> for a
functional description.

When used on non-MSWin32 systems, Net::SSH::W32Perl 
reverts to traditional Net::SSH::Perl functionality.

SSH2 is the default protocol under MSWin32. Specifying a 
protocol other than SSH2 will cause SSH2 to die() - see below.

=head1 LIMITATIONS

=over 4

=item *

SSH2 is the only supported protocol due to Net::SSH::Perl's 
reliance on Math::GMP.

=item *

The C<shell()> interface is not supported due to MSWin32's 
lack of support for C<select()> on non-socket filehandles.

=item *

The I<privileged> option is not supported - I hope to fix 
this in a future release.

=item *

Anything else that doesn't work :)

=back

=head1 TO DO

Integrate the Net::SSH::Perl tests, fix C<privileged>, etc...

=head1 AUTHOR & COPYRIGHT

Scott Scecina, E<lt>scotts@inmind.comE<gt>

Except where otherwise noted, Net::SSH::W32Perl is Copyright
2001 Scott Scecina. All rights reserved. Net::SSH::W32Perl is
free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

Code taken from Net::SSH::Perl is Copyright 2001 Benjamin Trott. 
Please see L<Net::SSH::Perl> for more information.

=head1 SEE ALSO

L<Net::SSH::Perl>

=cut
