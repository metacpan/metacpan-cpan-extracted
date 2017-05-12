package Net::RULI;

use 5.008003;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use RULI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&RULI::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Net::RULI', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Stub documentation for RULI module.

=head1 NAME

Net::RULI - Perl extension for RULI, 
            a library for easily querying DNS SRV resource records

=head1 SYNOPSIS

use Net::RULI;

my $srv_list_ref = Net::RULI::ruli_sync_query($service, $domain, 
                                              $fallback_port, $options);

my $srv_list_ref = Net::RULI::ruli_sync_smtp_query($domain, $options);

my $srv_list_ref = Net::RULI::ruli_sync_http_query($domain, $force_port, $options);

=head1 DESCRIPTION

RULI performs DNS queries for SRV records. The result is a
ready-to-use list of SRV records. The whole logic demanded by SRV
standards is already performed. It's the application role to try to
contact every address in the given order.

This function performs a query for a generic service:

  my $srv_list_ref = Net::RULI::ruli_sync_query($service, $domain, 
                                                $fallback_port, $options);

This function performs a query for the SMTP service:

  my $srv_list_ref = Net::RULI::ruli_sync_smtp_query($domain, $options);

This function performs a query for the HTTP service:

  my $srv_list_ref = Net::RULI::ruli_sync_http_query($domain, $force_port, $options);

The $options field is currently unused and should be set to 0 (zero).

If the query fails for any reason, undef is returned by those
functions.

=head1 EXAMPLES

=head2 Example 1

This example submits a generic query for FTP over TCP.

  my $srv_list_ref = Net::RULI::ruli_sync_query("_ftp._tcp", "bogus.tld", 
                                                21, 0);

=head2 Example 2 

This example submits a specific query for SMTP.

  my $srv_list_ref = Net::RULI::ruli_sync_smtp_query("bogus.tld", 0);

=head2 Example 3 

This example submits a specific query for HTTP.

  my $srv_list_ref = Net::RULI::ruli_sync_http_query("bogus.tld", -1, 0);

=head2 Example 4

This example scans the list of SRV records returned by successful
calls to RULI functions.

  foreach (@$srv_list_ref) {
    my $target = $_->{target};
    my $priority = $_->{priority};
    my $weight = $_->{weight};
    my $port = $_->{port};
    my $addr_list_ref = $_->{addr_list};

    print "  target=$target priority=$priority weight=$weight port=$port addresses=";

    foreach (@$addr_list_ref) {
      print $_, " ";
    }
    print "\n";
  }

=head1 SEE ALSO

RFC 2782 - A DNS RR for specifying the location of services (DNS SRV)

RULI Web Site: http://www.nongnu.org/ruli/

=head1 AUTHOR

Everton da Silva Marques <everton.marques@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Everton da Silva Marques

RULI is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2, or (at your option) any later
version.

RULI is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with RULI; see the file COPYING.  If not, write to the Free
Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
02111-1307, USA.


=cut
