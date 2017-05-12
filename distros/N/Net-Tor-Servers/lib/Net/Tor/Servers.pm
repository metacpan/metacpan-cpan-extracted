package Net::Tor::Servers;

use 5.008008;
use strict;
use warnings;
use LWP::Simple;

require Exporter;
require LWP::Simple;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Tor::Servers ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


sub new {
  my $package = shift;
  return bless({}, $package);
}

sub getservers {
    my ($junk,$torserver,$port) =@_;
    my @torarray=();
    my @arrayrecord=();
    my $router;
    my @rarray;
    if (!$torserver) {
        $torserver = "128.31.0.34";   
    }
    
    if (!$port) {
        $port = 9031;
    }
    my $content = get("http://$torserver:$port/tor/status/all") or die("Error getting Tor Directory Listing.\n");
    my @lines = split(/\n/,$content);
    foreach $router (@lines) {
        @rarray = split(/\ /,$router);
        if($rarray[0] =~ /^r$/) {
            my $ip=$rarray[6];
            my $hostname=$rarray[1];
            my $orport = $rarray[7];
            my $dirrepport = $rarray[8];
            @torarray = (@torarray,[$ip,$hostname,$orport,$dirrepport]);   
        }
    }
   
    return @torarray;    
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::Tor::Servers - Perl extension to query a Tor Directory and collect information on servers

=head1 SYNOPSIS

  use Net::Tor::Servers;
  
  my $torsrv = new Net::Tor::Servers;
  my @servers = $torsrv->getservers;
    
  for my $i (0..$#servers) {
    print "IP: $servers[$i][0], Name: $servers[$i][1], ORPort: $servers[$i][2], DirPort: $servers[$i][3]\n";
  }

=head1 DESCRIPTION

This module was written to make life a little easier for me when I have been developing a dymanic blocklist for educational
institutions to prevent students from being able to circumvent legally required content filtering systems.

Its nothing special, just a quick and easy way to get the data together in an array.

An alternative server and port can be specified:

  my @servers = $torsrv->getservers($server,$port);
  
  where $server is the IP / hostname of a Tor Directory Server, and $port is the port number.

=head1 SEE ALSO

N/A

=head1 AUTHOR

Andy Dixon, E<lt>ajdixon@cpan.orgE<gt> www.andydixon.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Andy Dixon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
