package NOLookup::Whois::WhoisLookup;

use strict;
use warnings;
use IO::Socket::INET6;

use vars qw(@ISA @EXPORT_OK);
@ISA    = qw( Exporter );
@EXPORT_OK = qw / $WHOIS_LOOKUP_ERR_NO_CONN

                  $WHOIS_LOOKUP_ERR_QUOTA_EXCEEDED 
                  $WHOIS_LOOKUP_ERR_NO_ACCESS
                  $WHOIS_LOOKUP_ERR_REFERRAL_DENIED

                  $WHOIS_LOOKUP_ERR_OTHER

                  $WHOIS_LOOKUP_ERR_NO_MATCH

/;

# Error codes returned from the WhoisLookup module
# Ref. the Norid Whois API definition.

# Connection problems
our $WHOIS_LOOKUP_ERR_NO_CONN         = 100;

# Controlled refuses
our $WHOIS_LOOKUP_ERR_QUOTA_EXCEEDED  = 101;
our $WHOIS_LOOKUP_ERR_NO_ACCESS       = 102;
our $WHOIS_LOOKUP_ERR_REFERRAL_DENIED = 103;

# DB and other problems, all the 'ERROR - xxxx'
# See raw_text for details on the problem.
our $WHOIS_LOOKUP_ERR_OTHER           = 104;

our $WHOIS_LOOKUP_ERR_NO_MATCH        = 105;

use Data::Dumper;
$Data::Dumper::Indent=1;

use vars qw/$AUTOLOAD/;

sub AUTOLOAD {
    my $self=shift;
    $AUTOLOAD =~ s/.*:://;
    return $self->get($AUTOLOAD);
}

sub new {
  my ($proto, $query, $whois_server, $whois_port, $client_ip)=@_;
  my $class=ref $proto||$proto;
  my $self=bless {},$class;

  # $query is required for something to happen
  return $self unless $query;

  # defaults
  $whois_server = 'whois.norid.no' unless ($whois_server);
  $whois_port   = 43 unless ($whois_port);

  return $self->lookup($query, $whois_server, $whois_port, $client_ip);
}

sub get {
    my ($self, $key) = @_;
    $key=lc($key);
    if (exists $self->{"${key}_handle"} ) {
        my @objs=(map { $self->new($_) }
                split (m/\n/,$self->{"${key}_handle"}));
        return ( wantarray ? @objs : $objs[0] );
    }
    return $self->{$key};
}

sub lookup {
    my ($self, $query, $whois_server, $whois_port, $client_ip) = @_;

    my ($line, $text);

    #$client_ip = undef;
    
    my $sock = IO::Socket::INET6->new (
	PeerAddr => $whois_server,
	PeerPort => $whois_port,
	Proto    => 'tcp',
	Timeout => 10,
	);

    unless($sock) {
	$self->{errno} = $WHOIS_LOOKUP_ERR_NO_CONN;
	return $self;
    }

    $query = Encode::encode('UTF-8', $query);
    
    if ($client_ip) {
	# Use the special -V option to identify the client IP
	# for proper rate limiting purposes.
	# Note that the ip address of the proxy itself
	# must be registered by Norid for this to work properly, 
	# if not, a referral error is returned.
	print $sock "-V v0,$client_ip -c utf-8 $query\n";
    } else {
	print $sock "-c utf-8 $query\n";
    }
    
    # Read all answer lines into one long LF separated $text
    while ($line = <$sock>) {
	$text .= $line;
    }	
    close $sock;
    $text = Encode::decode('UTF-8', $text);

    #print STDERR "text: $text\n";
    
    # Parse whois and map values into the self object.
    $self->_parse($text);

    if ($text =~ m/\nDomain Information\n/) {
	
	# If a domain name, or a domain handle, is looked up, the
	# whois server may also return the holder info as a second
	# block. The below code parses the domain and holder info and
	# returns the data in separate objects.
	#
	
	# Domain info is first block. Holder contact info is second
	# block, but only if the full (but limited) registrarwhois
	# service is used. Split the text and make two objects.
	
	my ($dmy, $dtxt, $htxt) = split ('NORID Handle', $text);

	my $holder_whois;
	my $domain_whois = NOLookup::Whois::WhoisLookup->new;

	#print STDERR "\n------\nparse domain text: '$dtxt'\n";
	$domain_whois->_parse("\nNORID Handle" . $dtxt);

	if ($htxt) {
	    $holder_whois = NOLookup::Whois::WhoisLookup->new;
	    #print STDERR "\n------\nparse holder text: '$htxt'\n";
	    $holder_whois->_parse("\nNORID Handle" . $htxt);
	}
	#print STDERR "self  : ", Dumper $self;
	#print STDERR "domain whois: ", Dumper $domain_whois;
	#print STDERR "holder whois: ", Dumper $holder_whois if $holder_whois;

	return $self, $domain_whois, $holder_whois;

    } 

    if ($text =~ m/\nHosts matching the search parameter\n/) {
	# Set a method telling that a name_server_list is found,
	# which is only the case when a host name is looked up.
	$self->{name_server_list} = 1;
    }

    #print STDERR "\n\n====\nself after $query: ", Dumper $self;
    return $self;
}

sub _parse {
    my ($self, $text)=@_;

    foreach my $line (split("\n",$text)) {
	# Map all elements into the object key method and set the value
	my ($key, $ix, $value);

	# Parse DNSSEC stuff, if present
	if (($key,$value) = $line =~ m/^(DNSSEC)\.+:\s*(.+)$/) {
	    $self->{dnssec}->{$key} = $value;

	} elsif (($key, $ix, $value) = $line =~ m/^(DS Key Tag|Algorithm|Digest Type|Digest|Key Flags|Key Protocol|Key Algorithm|Key Public)\s+(\d+)\.+:\s*(.+)$/) {
	    # Translate all DNSSEC stuff to methods
            # replace spaces and - with _ for accessors.

            $key =~ y/ -/_/;
	    # multiple '_' are collapsed to one '_'
	    $key =~ s/_+/_/g;
            $key = lc($key);
            $self->{dnssec}->{$ix}->{$key} = 
                ($self->{dnssec}->{$ix}->{$key} ? $self->{dnssec}->{$ix}->{$key}."\n$value" : $value);

	    #print STDERR "DNSSEC parse self: $key , $ix, $value\n--\n";

	} elsif (($key,$value) = $line =~ m/^(\w+[^.]+)\.{2,}\:\s*(.+)$/) {
            # replace spaces and - with _ for accessors.
            $key =~ y/ -/_/;
            $key = lc($key);
            $self->{$key} = 
                ($self->{$key} ? $self->{$key}."\n$value" : $value);

	} elsif (($key,$value) = $line =~ m/^(Created|Last updated):\s*(.+)$/) {
	    $key =~ y/ -/_/;
	    $key = lc($key);
	    $self->{$key} = 
		($self->{$key} ? $self->{$key}."\n$value" : $value);

	} elsif (($key,$value) = $line =~ m/^(% )(.+)$/) {

	    if ($value =~ m/(No match)$/) {
		$self->{errno} = $WHOIS_LOOKUP_ERR_NO_MATCH;

	    } elsif ($value =~ m/(Quota exceeded)$/) {
		$self->{errno} = $WHOIS_LOOKUP_ERR_QUOTA_EXCEEDED;

	    } elsif ($value =~ m/(Access denied)$/) {
		$self->{errno} = $WHOIS_LOOKUP_ERR_NO_ACCESS;

	    } elsif ($value =~ m/(Referral denied)$/) {
		$self->{errno} = $WHOIS_LOOKUP_ERR_REFERRAL_DENIED;

	    } elsif ($value =~ m/(ERROR - )$/) {
		# Details can be found in the raw_text
		$self->{errno} = $WHOIS_LOOKUP_ERR_OTHER;
		
	    } else {
		$key = 'copyright';
		$self->{$key} =
		    ($self->{$key} ? $self->{$key}."\n$value" : $value);
	    }
	}
    }
    $self->{raw_text} = $text;

    #print STDERR "_parse self: ", Dumper $self, "\n";
    #if (exists($self->{dnssec})) {
    #   print STDERR "_parse self DNSSEC: ", Dumper $self->{dnssec}, "\n";
    #}

    return $self;
}

   
sub TO_JSON {
    my ($whois) = @_;

    my $rh;

    if ($whois) {
	foreach my $k (sort keys(%$whois)) {
	    my $a = $whois->$k;
	    $rh->{$k} = $whois->get($k);
	}
    }

    #use Data::Dumper;
    #$Data::Dumper::Indent=1;
    #print STDERR "rh: ", Dumper $rh;

    $rh;
}

=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::Whois::WhoisLookup - Lookup WHOIS data from Norid.

=head1 SYNOPSIS

    use Encode;
    use NOLookup::Whois::WhoisLookup;
 
    # The $SERVER and $PORT can be set to what you need.
    # The defaults are the below, so in this case they don't
    # change anything.
    my $SERVER = 'whois.norid.no';
    my $PORT   = 43;

    # Example 1: Domain name lookup
    # Decode the query when needed, like for IDNs
    # or names with national characters.
    my $q = decode('UTF-8', 'norid.no');

    my ($wh, $do, $ho) = NOLookup::Whois::WhoisLookup->new($q, $SERVER, $PORT);

    # $wh is always populated.
    # For a domain lookup, the $do and $ho objects should be 
    # used to access the domain and holder information.
    # In all other cases, $wh contains the information.
    if ($wh->errno) {
       print STDERR "Whois error: ", $wh->errno, "\n";
       if ($wh->raw_text) {
          print STDERR "Raw text   : ", $wh->raw_text, "\n";
       }
       exit;
    }
    print $wh->post_address;
    print $wh->domain_name;
    print $wh->name;

    if ($do && $ho) {
       # when a domain name or domain handle is looked up,
       # $do contains the domain information,
       # and $ho contains the holder information
       print "Domain name   : ", encode('UTF-8', $do->domain_name), "\n";
       print "Holder name   : ", encode('UTF-8', $ho->name), "\n";
       print "Holder address: ", encode('UTF-8', $ho->post_address), "\n";
    }

    # Example 2: Registrar lookup
    $q = 'reg2-norid';
    $wh = NOLookup::Whois::WhoisLookup->new($q);
    unless ($wh->errno) {
       print "Registrar name : ", encode('UTF-8', $wh->registrar_name), "\n";
       print "Registrar email: ", $wh->email_address, "\n";
    }



=head1 DESCRIPTION

This module provides an object oriented API for use with the
Norid whois service. It uses the command line based whois interface
internally to fetch information from Norid.

The values in the objects are decoded to internal perl data.

This code is stolen from Cpan package Net::Whois::Norid 
and adapted to suit our needs.
Adaption was needed because create date etc. were not collected.
We could've considered using the module as it was, but it also
dragged in some more modules which seems a bit much for such a simple task.

Also nice to produce some more error codes.

=head2 METHODS

=over 4

=item new

The constructor. Takes an optional lookup argument. Returns a new object.

=item lookup 

Do a whois lookup in the Norid database and populate the object
from the result.

=item get

Use this to access any data parsed. Note that spaces and '-'s will be 
converted to underscores (_). For the special "Handle" entries, 
omitting the _Handle part will return a new NOLookup::Whois::WhoisLookup object. 

The method is case insensitive.

=item TO_JSON

Note: The name of this method is important,
must be upper case and name must not be changed!

Provide a TO_JSON method for JSON usage, ref. TO_JSON discussion in 
https://metacpan.org/pod/JSON

JSON does not handles objects, as the internals are not known,
then we need a method to present the object as a hash structure for 
JSON to use. This method does the conversion from object to a hash 
ready for JSON encoding.

=item AUTOLOAD

This module uses the autoload mechanism to provide accessors for any
available data through the get mechanism above.

=back

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

=head1 SEE ALSO

L<https://www.norid.no/en>
L<https://teknisk.norid.no/en/integrere-mot-norid/whois>

=head1 CAVEATS

Some rows in the whois data, like address lines, might appear more than once.
In that case they are separated with line space. 
For objects, an array is returned.

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
