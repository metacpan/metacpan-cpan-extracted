package Net::DNS::DurableDNS;

use warnings;
use strict;
use Carp;

require SOAP::Lite;

=head1 NAME

Net::DNS::DurableDNS - Wrapper for the DurableDNS API at http://durabledns.com

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

use Net::DNS::DurableDNS;

my $durable = Net::DNS::DurableDNS->new({ apiuser => $user, 
                                            apikey => $key });

my $zones = $durable->listZones();

=head1 FUNCTIONS

=head2  new

new( { apiuser => $user, apikey => $key } )

returns a new object for accessing the DurableDNS API.  The API user and key are from your
DurableDNS.com account.

=cut

sub new {
    my ($S,$att) = @_;    
    bless {
        apiuser => $att->{apiuser},
        apikey => $att->{apikey},
    }, $S;    
}

=head2 listZones

=cut

sub listZones {
    # Returns a reference to an array
    my ($S) = @_;
    
    my $service = SOAP::Lite
        -> uri('https://durabledns.com/services/dns/listZones.php?wsdl')
        -> proxy('https://durabledns.com/services/dns/listZones.php');
    
    my $result = $service->listZones($S->{apiuser},$S->{apikey});
    
    $S->{status} = {};
    unless ($result->fault) {
        $S->{result} = {status=>1,message=>'OK'};
        my @results = $result->valueof('//origin');
        return \@results;
    } else {
        $S->{result} = {status=>1,
                        message=> join ', ', 
                        $result->faultcode, 
                        $result->faultstring};
    }
  
}

=head2 getZone

=cut

sub getZone {
    # Returns a reference to an array
    my ($S,$att) = @_;
    
    my $service = SOAP::Lite
        -> uri('https://durabledns.com/services/dns/getZone.php?wsdl')
        -> proxy('https://durabledns.com/services/dns/getZone.php');
        
    # durable wants a trailing '.'
    $att->{zonename} = ($att->{zonename} =~ /\.$/) ? $att->{zonename} : $att->{zonename} . ".";
    
    my $result = $service->getZone($S->{apiuser},
                                        $S->{apikey},
                                        $att->{zonename},
                                        );
    
    $S->{status} = {};
    unless ($result->fault) {
        $S->{result} = {status=>1,message=>'OK'};
        my @results = $result->valueof('//getZoneResponse');
        return \@results;
    } else {
        $S->{result} = {status=>1,
                        message=> join ', ', 
                        $result->faultcode, 
                        $result->faultstring};
        return '';
    }
  
}

=head2 deleteRecordById

=cut

sub deleteRecordById {
    # Returns a reference to an array
    my ($S,$att) = @_;
    
    my $service = SOAP::Lite
        -> uri('https://durabledns.com/services/dns/deleteRecord.php?wsdl')
        -> proxy('https://durabledns.com/services/dns/deleteRecord.php');
        
    # durable wants a trailing '.'
    $att->{zonename} = ($att->{zonename} =~ /\.$/) ? $att->{zonename} : $att->{zonename} . ".";
    
    my $result = $service->deleteRecord($S->{apiuser},
                                        $S->{apikey},
                                        $att->{zonename},
                                        $att->{recordid},
                                        );
    $S->{status} = {};
    unless ($result->fault) {
        my $response = $result->valueof('//deleteRecordResponse')->{return};        
        if ($response eq 'Success') {
            $S->{result} = {status=>1,message=>'deleteRecordById:OK'};
        } else {
            $S->{result} = {status=>0,message=>$response};
        }
        return $result->valueof('//deleteRecordResponse')->{return};
    } else {
        $S->{result} = {status=>1,
                        message=> join ', ', 
                        $result->faultcode, 
                        $result->faultstring};
    }
  
}

=head2 deleteRecordByName

=cut

sub deleteRecordByName {

    # Returns a reference to an array
    # expects zonename and name
    
    my ($S,$att) = @_;
    my $success = 0;
    # get the list of records for the zone
    my $records = listRecords($S,$att);
    my $return = 0;
    if ($records) {

        # loop through records until we find one;
        foreach my $record (@$records) {
            if ($record->{name} eq $att->{name}) {
                $S->{result} = {status=>0,
                            message=> join ', ', 'deleteRecordByName:OK'};
                deleteRecordById($S,{recordid=>$record->{id},zonename=>$att->{zonename}});
                $return = 1;
                last;
            }
        }
 
        return $return;     
 
    } else {
    
        my $previous_message = ($S->{result}->{message}) ? $S->{result}->{message} . ';' : '';    
        $S->{result} = {status=>0,
                            message=> join ', ', 
                            $previous_message ,
                            'DurableDNS.pm', 
                            'No record named ' . $att->{name} . '.'};
        return $return;    
    
    }
        
}

=head2 getRecordById

=cut

sub getRecordById {
    # Returns a reference to an array
    my ($S,$att) = @_;
    
    my $service = SOAP::Lite
        -> uri('https://durabledns.com/services/dns/getRecord.php?wsdl')
        -> proxy('https://durabledns.com/services/dns/getRecord.php');
        
    # durable wants a trailing '.'
    $att->{zonename} = ($att->{zonename} =~ /\.$/) ? $att->{zonename} : $att->{zonename} . ".";
    
    
    my $result = $service->getRecord($S->{apiuser},
                                        $S->{apikey},
                                        $att->{zonename},
                                        $att->{recordid},
                                        );
    
    $S->{status} = {};
    unless ($result->fault) {
        $S->{result} = {status=>1,message=>'OK'};
        my @results = $result->valueof('//origin');
        return \@results;
    } else {
        $S->{result} = {status=>1,
                        message=> join ', ', 
                        $result->faultcode, 
                        $result->faultstring};
        return '';
    }
  
}

=head2 getRecordByName

=cut

sub getRecordByName {
    # Returns a reference to an array
    # expects zonename, name and type
    
    my ($S,$att) = @_;
    my $success = 0;
    # get the list of records for the zone
    my $records = listRecords($S,$att);

    if ($records) {

        # loop through records until we find one;
        foreach my $record (@$records) {
            if ( ($record->{name} eq $att->{name}) && ($record->{type} eq $att->{type}) ){
                $S->{result} = {status=>0,
                            message=> join ', ', 'getRecordByName:OK'};
                return $record;
                exit;
            }
        }
        
    } else {
    
        my $previous_message = ($S->{result}->{message}) ? $S->{result}->{message} . ';' : '';
    
        $S->{result} = {status=>0,
                            message=> join ', ', 
                            $previous_message ,
                            'DurableDNS.pm', 
                            'No record named ' . $att->{name} . '.'};
        return '';
    
    
    }
        
}

=head2 listRecords

=cut

sub listRecords {
    
    # Returns a reference to an array of hash references
   
    # Each Record Can Contain
    # id Unique numeric ID of record 
    # name Name of record 
    # type DNS record type 
    # data Data for record 
    # ttl Time-to-live for record in seconds 
    # aux
    
    my ($S,$att) = @_;
   
    my $service = SOAP::Lite
        -> uri('https://durabledns.com/services/dns/listRecords.php?wsdl')
        -> proxy('https://durabledns.com/services/dns/listRecords.php');
    
    # durable wants a trailing '.'
    $att->{zonename} = ($att->{zonename} =~ /\.$/) ? $att->{zonename} : $att->{zonename} . ".";
    
    my $result = $service->listRecords($S->{apiuser},$S->{apikey},$att->{zonename});
    
    $S->{result} = {};
    unless ($result->fault) {
        $S->{result} = {status=>1,message=>'listRecords:OK'};
        return $result->valueof('//listRecordsResponse')->{return};
    } else {
        warn Dumper($result);
        $S->{result} = {status=>1,
                        message=> join ', ', 
                        $result->faultcode, 
                        $result->faultstring};
    }
  
}

=head2 createRecord

=cut

sub createRecord {

    my ($S,$att) = @_;
    
    # apiuser Value for authentication 
    # apikey Value for authentication 
    # zonename Name of zone to add record to, followed by a dot (.). 
    # name Name of record to create.  Example: ÒwwwÓ or 
    # type DNS record type Ð A, AAAA, CNAME, HINFO, MX, NS, PTR, RP, SRV, or TXT 
    # aux Preference, priority, or weight of record (optional) 
    # ttl Time-to-live for record in seconds 
       
    my $service = SOAP::Lite
        -> uri('https://durabledns.com/services/dns/createRecords.php?wsdl')
        -> proxy('https://durabledns.com/services/dns/createRecord.php');
    
    # durable wants a trailing '.'
    $att->{zonename} = ($att->{zonename} =~ /\.$/) ? $att->{zonename} : $att->{zonename} . ".";
    
    # first we have to make sure the record does not exist
    # look up by name

    my $record = getRecordByName($S,$att);
    
    if ($record && $att->{type} ne 'MX' && $record && $att->{type} ne 'NS') {
        
        my $previous_message = ($S->{result}->{message}) ? $S->{result}->{message} . ';' : '';
    
        $S->{result} = {status=>0,
                            message=> join ', ', 
                            $previous_message ,
                            'DurableDNS.pm', 
                            'Record named ' . $att->{name} . ' of type ' . $att->{type} . ' already exists'};
 
    } else {
    
        my $result = $service->createRecord($S->{apiuser},
                                            $S->{apikey},
                                            $att->{zonename},
                                            $att->{name},
                                            $att->{type},
                                            $att->{data},
                                            $att->{aux},
                                            $att->{ttl},
                                            );
        
        $S->{result} = {};
        unless ($result->fault) {
            $S->{result} = {status=>1,message=>'createRecord:OK'};
            my $response = $result->valueof('//createRecordResponse')->{return};
            return $result->valueof('//createRecordResponse')->{return};
        } else {
            $S->{result} = {status=>1,
                            message=> join ', ', 
                            $result->faultcode, 
                            $result->faultstring};
        }
    
    }
    

}


=head2 updateRecord

updateRecord( $hostnames, $ip_address, $params )

# if a recordid is provided, we use it
# if recordid is not provide and oldname is provided we use oldname to look up the recordid
# if neither oldname nor recordid is provided, we look it up based on name

# if orcreate is passed in, if no record exists, a new one will be created

# <part name="apiuser" type="xsd:string"/>
# <part name="apikey" type="xsd:string"/>
# <part name="zonename" type="xsd:string"/>
# <part name="id" type="xsd:int"/>
# <part name="name" type="xsd:string"/>
# <part name="aux" type="xsd:int"/>
# <part name="data" type="xsd:string"/>
# <part name="ttl" type="xsd:int"/>
    
Parameter            Default   Values
system               dyndns    dyndns | statdns | custom
wildcard             none      ON | OFF | NOCHG 
mx                   none      any valid fully qualified hostname 
backmx               none      YES | NO
offline              none      YES | NO
protocol             https     http | https

Further information about each of these parameters is available at
http://www.dyndns.org/developers/specs/syntax.html

=cut

sub updateRecord {

    my ($S,$att) = @_;
        
    my $service = SOAP::Lite
        -> uri('https://durabledns.com/services/dns/updateRecord.php?wsdl')
        -> proxy('https://durabledns.com/services/dns/updateRecord.php');
    
    my $error_message;
    my $record;
    
    # durable wants a trailing '.'
    $att->{zonename} = ($att->{zonename} =~ /\.$/) ? $att->{zonename} : $att->{zonename} . ".";
    
    if (!$att->{recordid}) {

      my $name = $att->{name};
      
      $att->{name} = ($att->{oldname}) ? $att->{oldname} : $att->{name};
      $error_message = 'Record named ' . $att->{name} . ' does not exist';
      $record = getRecordByName($S,$att);
      
      # restore the $att->{name}
      $att->{name} = $name;
            
    } else {
    
        $record = getRecordByID($S,$att);
        $error_message = 'Record id ' . $att->{name} . ' does not exist';
        
    }
    
    if ($record) {
            
        my $result = $service->updateRecord($S->{apiuser},
                                            $S->{apikey},
                                            $att->{zonename},
                                            $record->{id},
                                            $att->{name},
                                            $att->{aux} || $record->{aux} || 0,
                                            $att->{data} || $record->{data},
                                            $att->{ttl} || $record->{ttl},
                                            );
        
        $S->{result} = {};
        unless ($result->fault) {
            $S->{result} = {status=>1,message=>'updateRecord:OK'};
            my $response = $result->valueof('//updateRecordResponse')->{return};
            return $result->valueof('//updateRecordResponse')->{return};
        } else {
            $S->{result} = {status=>1,
                            message=> join ', ', 
                            $result->faultcode, 
                            $result->faultstring};
        }
        
 
    } elsif ($att->{orcreate}) {
        
        return createRecord($S,$att);
        
    } else {
    
        my $previous_message = ($S->{result}->{message}) ? $S->{result}->{message} . ';' : '';
    
        $S->{result} = {status=>0,
                            message=> join ', ', 
                            $previous_message ,
                            'DurableDNS.pm', 
                            $error_message};
    
    }
    

}

=head2 info

=cut

sub info {
    my ($S) = @_;
    return $S->{result};
}

=head1 AUTHOR

Richard K Bush, C<< <rbush at 42umbrellas.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-dns-durabledns at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DNS-DurableDNS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DNS::DurableDNS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-DNS-DurableDNS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-DNS-DurableDNS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-DNS-DurableDNS>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-DNS-DurableDNS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2012 Richard K Bush.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::DNS::DurableDNS
