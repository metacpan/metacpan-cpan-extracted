package Net::RADSWrappers;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( getHostName getCountry grabConnections
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# This is just a convieniet wrapper around gethostbyaddr() to take away some of
# the more obnoxious issues with that function

sub getHostName ($) {
    use Socket;
    my $ip_in = shift;
    my $ip = inet_aton($ip_in);
    my $name = gethostbyaddr($ip, AF_INET);
    
    if (!$name) {
        $name = "NXDOMAIN";
    }
    
    return $name;
}

# This is just provides a bit of error checking around Geo::IPfree::LookUp

sub getCountry ($) {
    use Geo::IPfree;
    my $ip = shift;
    my ($country) = Geo::IPfree::LookUp($ip);

    if (!$country) {
        $country = "Unknown";
    }
    return $country;
}

sub grabConnections {
    my ($pipe,$port) = @_;
    my %hosts;
    while(<$pipe>) {
        if (/:$port/) {
            my @connection = split (/\s+/, $_);
                if($connection[4] =~ /((\d+\.){3}\d+)/g) {
                    $hosts{$1}++ unless $1 eq '0.0.0.0';
            }
        }
    }
    close $pipe;
    return %hosts;
}


1;
__END__


=head1 NAME

Net::RADSWrappers - Perl extension for making various network-related code less
obnoxious

=head1 SYNOPSIS

  use Net::RADSWrappers;
  
  my $hostname = getHostName($some_ip);
  my $country  = getCountry($some_ip)
    or...
  my $country = getCountry($hostname);
  
  open (NETSTAT, "netstat -plan|") or die "$!\n";
  my %hosts = &grabConnections(\*NETSTAT,$ports{$service});

  

=head1 DESCRIPTION

This module exists solely to stash re-usable code snippets that I found myself
copy-and-pasting over and over again throughou the course of re-writing a large
number of BASH/sed/awk scripts for resource abuse detection (hence, RADS) at
work.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Geo::IPfree

Also, I will make available some scripts that use these and other functions that
will be added in later updates.

=head1 AUTHOR

William Freeman, E<lt>deanf@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by W. Dean Freeman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
