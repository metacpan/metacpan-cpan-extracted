package Perlbal::Plugin::TrustHeader;

use warnings;
use strict;

use Net::Netmask;

our $VERSION = '0.02';
my %trust_headers;

sub register {
    my ($class, $svc) = @_;

    $svc->register_hook(
        'TrustHeader',
        'backend_client_assigned',
        sub {
            my Perlbal::BackendHTTP $obj    = shift;
            my Perlbal::HTTPHeaders $hds    = $obj->{req_headers};
            my Perlbal::Service $svc        = $obj->{service};
            my Perlbal::ClientProxy $client = $obj->{client};

            return 0 unless defined($hds) and defined($svc) and defined($client);

            my $svc_name = $svc->{name}        or return 0;
            my $rules    = $trust_headers{$svc_name} or return 0;

            my $client_ip = $client->peer_ip_string;

            keys %$rules;    # reset iter
            while (my ($header, $netmasks) = each %$rules) {
                next unless defined $hds->header($header);
                my $trusted;
                foreach my $mask (@$netmasks) {
                    ++$trusted, last if $mask->match($client_ip);
                }

                # Remove header as it is not trusted
                $hds->header($header, undef) unless $trusted;
            }

            return 0;
        }
    );

    return 1;
}


sub unregister {
    my ($class, $svc) = @_;
    $svc->unregister_hooks('TrustHeader');
    return 1;
}


sub load {
    Perlbal::register_global_hook(
        'manage_command.trustheader',
        sub {
            my $command_regexp = qr/^TrustHeader\s+(\S+)\s+(\S+)\s+(.*?)$/i;
            my $mc             = shift->parse($command_regexp,
                "usage: TrustHeader <SERVICE> <HEADER_NAME> <NETMASK-LIST>");

            # Get the original line, since perlbal puts everything to lower case before parsing
            my ($service, $header_name, $netmasks) = ($mc->orig =~ /$command_regexp/);

            my @masks = split(/\s+/, $netmasks)
              or return $mc->error("No netmasks");

            my $rules = $trust_headers{$service}{lc $header_name} ||= [];

            foreach my $mask (@masks) {
                my $m = eval { Net::Netmask->new2($mask) }
                  or return $mc->error("Invalid netmask '$mask'");

                push @{$rules}, $m;
            }

            return 1;
        }
    );

    return 1;
}

sub unload { return 1; }

1; # End of Perlbal::Plugin::TrustHeader

__END__

=head1 NAME

Perlbal::Plugin::TrustHeader - Remove untrusted headers 



=head1 Description

This module allows you to remove headers unless the client is trusted

You can configure headers to be checked based on each service
declared, although the service role has to be set to web_server

For each header you want to check,  you have to specify the header
name and a list of netmasks to trust. Multiple netmasks are separated
by white space

=head1 SYNOPSIS

This module provides a Perlbal plugin wich can be loaded and used as follows

    Load TrustHeader

    #TrustHeader <service_name> <header_name> <netmask_list>
    TrustHeader static X-SSL 10.0.0.0/8
    
    CREATE SERVICE static
        SET ROLE = web_server
        SET plugins = TrustHeader
    ENABLE static

In this case for each response served by the C<Service static>, the
header C<X-SSL> will be removed before the request is proxied to the backend
unless the client is on the local private network


=head1 AUTHOR

Graham Barr, C<< <gbarr@pobox.com> >>



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perlbal::Plugin::TrustHeader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perlbal-Plugin-TrustHeader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perlbal-Plugin-TrustHeader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perlbal-Plugin-TrustHeader>

=item * Search CPAN

L<http://search.cpan.org/dist/Perlbal-Plugin-TrustHeader/>

=back



=head1 COPYRIGHT & LICENSE

Copyright 2009 Graham Barr

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
