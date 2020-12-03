package NOLookup::DAS::DASLookup;

use strict;
use warnings;
use IO::Socket::INET6;
use Encode;

use vars qw(@ISA @EXPORT_OK);
@ISA    = qw( Exporter );
@EXPORT_OK = qw / $DAS_LOOKUP_ERR_NO_CONN

                  $DAS_LOOKUP_ERR_QUOTA_EXCEEDED 
                  $DAS_LOOKUP_ERR_NO_ACCESS
                  $DAS_LOOKUP_ERR_REFERRAL_DENIED

                  $DAS_LOOKUP_ERR_OTHER
/;

# Error codes returned fom the DASLookup module
# Ref. the Norid API definition at
#  https://www.norid.no/en/registrar/system/dokumentasjon/whoisdas-grensesnitt/
    
# Connection problems
our $DAS_LOOKUP_ERR_NO_CONN         = 100;

# Controlled refuses
our $DAS_LOOKUP_ERR_QUOTA_EXCEEDED  = 101;
our $DAS_LOOKUP_ERR_NO_ACCESS       = 102;
our $DAS_LOOKUP_ERR_REFERRAL_DENIED = 103;

# DB and other problems, all the 'ERROR - xxxx'
# See raw_text for details on the problem.
our $DAS_LOOKUP_ERR_OTHER           = 104;

use Data::Dumper;
$Data::Dumper::Indent=1;

use vars qw/$AUTOLOAD/;

sub AUTOLOAD {
    my $self=shift;
    $AUTOLOAD =~ s/.*:://;
    
    if (@_) {
	# set operation
        return $self->{$AUTOLOAD} = shift;
    } else {
	# get operation
	return $self->{$AUTOLOAD};
    }
}

sub new {
  my ($proto, $query, $das_server, $das_port, $client_ip)=@_;
  my $class=ref $proto||$proto;
  my $self=bless {},$class;

  # $query is required for something to happen
  return $self unless $query;

  # defaults
  $das_server = 'finger.norid.no' unless ($das_server);
  $das_port   = 79 unless ($das_port);

  return $self->lookup($query, $das_server, $das_port, $client_ip);
}

sub lookup {
    my ($self, $query, $das_server, $das_port, $client_ip) = @_;

    my ($line, $text);

    my $sock = IO::Socket::INET6->new (
	PeerAddr => $das_server,
	PeerPort => $das_port,
	Proto    => 'tcp',
	Timeout  => 10,
	);

    unless($sock) {
	$self->{errno} = $DAS_LOOKUP_ERR_NO_CONN;
	#print STDERR "SOCK ERR: $!\n";
	return $self;
    }

    $query = Encode::encode('UTF-8', $query);

    # Always code query as utf-8
    if ($client_ip) {
	# Use the special -V option to identify the client IP
	# for proper rate limiting purposes.
	# Note that the ip address must be registered by Norid
	# to work properly, if not, a referral error is returned.
	print $sock "-V v0,$client_ip -c utf-8 $query\n";
    } else {
	print $sock "-c utf-8 $query\n";
    }
    
    # Read all answer lines into one long LF separated $text
    while ($line = <$sock>) {
	$text .= $line;
    }	
    close $sock;
    chomp $text;
    
    $text = Encode::decode('UTF-8', $text);

    # Parse DAS response and map values into object methods.
    $self->{raw_text} = $text;

    # Detect any of the error situations
    if ($text =~ m/Quota exceeded/) {
	$self->{errno} = $DAS_LOOKUP_ERR_QUOTA_EXCEEDED;

    } elsif ($text =~ m/Access denied/) {
	$self->{errno} = $DAS_LOOKUP_ERR_NO_ACCESS;
	
    } elsif ($text =~ m/Referral denied/) {
	$self->{errno} = $DAS_LOOKUP_ERR_REFERRAL_DENIED;

    } elsif ($text =~ m/ERROR - /) {
	$self->{errno} = $DAS_LOOKUP_ERR_OTHER;

    } elsif ($text =~ m/ is available /) {
	$self->{available} = 1;

    } elsif ($text =~ m/ is delegated /) {
	$self->{delegated} = 1;

    } elsif ($text =~ m/This domain can currently not be registered/) {
	$self->{prohibited} = 1;

    } elsif ($text =~ m/Domain is not valid /) {
	$self->{invalid} = 1;
    }

    #print STDERR "\n\n====\nDAS self after $query: ", Dumper $self;
    return $self;
}

=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::DAS::DASLookup - Lookup DAS data from Norid.

=head1 SYNOPSIS

  my $das = NOLookup::DAS::DASLookup->new('norid.no');

  One of the below accessor methods will return something:
  
   $das->errno()        Set to an error code if some error has occured.
   $das->available()    True if domain is available, thus registration can be attempted.
   $das->delegated()    True if domain is delegated, and thus not available.
   $das->prohibited()   True if domain is prohibited by policy, and thus not allowed.
   $das->invalid()      True if domain or zone is invalid, like a .com domain,
                        or if the zone is not administered by Norid, like 
                        some 'test.mil.no' domain.
   $das->raw_text()     Contains the raw DAS response.

=head1 DESCRIPTION

This module provides an object oriented API for use with the
Norid DAS service. It uses the command line based DAS interface
internally to fetch information from Norid.

=head2 METHODS

=over 5

=item new

The constructor. Takes a lookup argument. Returns a new object.

=item lookup 

Do a DAS lookup in the Norid database and populate the object
from the result.


=item AUTOLOAD

This module uses the autoload mechanism to provide accessors for any
available data through the get mechanism above.

=item errno, available, delegated, prohibited, invalid

See SYNOPSIS.

=back

=head1 SEE ALSO

L<http://www.norid.no/en>
L<https://www.norid.no/en/registrar/system/tjenester/whois-das-service>

=head1 AUTHOR

Trond Haugen, E<lt>(nospam)info(at)norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Trond Haugen <(nospam)info(at)norid.no>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
