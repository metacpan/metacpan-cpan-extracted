package Robotics::Tecan::Server;
# vim:set ai expandtab shiftwidth=4 tabstop=4:

use warnings;
use strict;

use Moose::Role;
# use Net::EasyTCP 

#extends 'Robotics::Tecan', 'Robotics::Tecan::Genesis';

# This module is not meant for direct inclusion.
# Use it "with" Tecan::Genesis.

has 'EXPECT_RECV' => ( is => 'rw', isa => 'Maybe[HashRef]' );

my $Debug = 1;

=head1 NAME

Robotics::Tecan::Server - (Internal module)
Software-to-Software interface for Tecan Gemini, network server.
Application for controlling robotics hardware

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';


# Consider re-writing to use Net::EasyTCP
sub server {
    my ($self, %params) = @_;
    use IO::Socket;
    use Net::hostent;

    die "must supply password with server()\n" 
        unless $params{password};

    my $port = $params{port} || 8088;

    my $socket = IO::Socket::INET->new( Proto     => 'tcp',
                                  LocalPort => $port,
                                  Listen    => SOMAXCONN,
                                  Reuse     => 1);
    die "cant open network on port $port" unless $socket;

    my $client;
    my $hostinfo;
    my $cdata;
    print STDERR "Robotics::Tecan network server is ready on port $port.\n";
    while ($client = $socket->accept()) {
        $client->autoflush(1);
        print $client "Welcome to $0\n";
        $hostinfo = gethostbyaddr($client->peeraddr);
        printf STDERR "\tConnect from %s on port $port\n",
            $hostinfo ? $hostinfo->name : $client->peerhost;

        # Cheap authentication
        print $client "login:\n";
        while ($cdata = <$client>) {
            $cdata =~ s/\n\r\t\s//g;
            last if ($cdata =~ /^$params{password}\b/);
            print $client "login:\n";
            print STDOUT "\t\t$cdata\n";
        }
        print $client "Authentication OK\n";
        printf STDERR "\tAuthenticated %s on port $port\n",
            $hostinfo ? $hostinfo->name : $client->peerhost;

        # Run commands
        my $result;
        while (<$client>) {
            next unless /\S/;       # blank line
            last if /end/oi;
            s/[\r\n\t\0]//g;
            s/^[\s\>]*//g;
            print STDERR "\t\t$_\n";
            $self->DATAPATH()->write($_);
            $result = $self->DATAPATH()->read();
            print STDERR "\t\t\t$result\n";
            print $client "\n$_\n<$result" . "\n";
        }
        printf STDERR "\tDisconnect %s\n",
            $hostinfo ? $hostinfo->name : $client->peerhost;
        close $client;
        print STDERR "Robotics::Tecan network server is ready on port $port.\n";
    }
    close $socket;

	return 1;
}


=head1 SYNOPSIS

Network server software interface support for Robotics::Tecan. 
This software provides connections to a network clients created with 
Robotics::Tecan::Client.

=head1 EXPORT


=head1 FUNCTIONS


=head2 server

Start network server.  The server provides network access to the
locally-attached robotics.

=cut


=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-robotics at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Tecan::Server


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Robotics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Robotics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Robotics>

=item * Search CPAN

L<http://search.cpan.org/dist/Robotics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jonathan Cline.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Robotics::Tecan::Server


__END__

