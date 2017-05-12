
package WWW::Scraper::ZIPplus4;


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Scraper(qw(3.03 generic_option addURL trimTags trimLFs trimComments));

use strict;

my $scraperRequest = 
        { 
            'type' => 'GET'
            ,'formNameOrNumber' => '1'
            ,'submitButton' => 'Submit'
            
            # This is the basic URL on which to get the form to build the query.
#            ,'url' => 'http://www.usps.com/ncsc/lookups/lookup_zip+4.html'
            # _OLD ,'url' => 'http://www.usps.com/cgi-bin/zip4/zip4inq2?'
            ,'url' => 'http://www.usps.com/zip4/zip4_response.jsp?'
           # specify defaults, by native field names
#           ,'nativeQuery' => 'Delivery+Address'
           ,'nativeDefaults' => { 
                                    'Selection' => '1'
                                   ,'urbanization' => ''
                                   ,'firm' => ''
                                   ,'address2' => ''
                                   ,'Submit.x' => '1'
                                   ,'Submit.y' => '1'
                                }
            
            # specify translations from canonical fields to native fields
           ,'defaultRequestClass' => 'ZIPplus4'
           ,'fieldTranslations' =>
                   {
                       '*' =>
                           {     
                                 'City' => 'city'
                                ,'State' => 'state'
                                ,'ZipCode' => 'zipcode'
                                ,'DeliveryAddress' => 'address'
                                ,'address1' => 'address' # Weird but true!
                                ,'*' => '*'              # Thanks to Klemens Schmid (klemens.schmid@gmx.de)!
                           }                             # See FormSniffer at http://www.wap2web.de/formsniffer2.aspx
                   }
            # Miscellaneous options for the Scraper operation.
           ,'cookies' => 0
       };


my $scraperFrame =
       [ 'HTML', 
          [ 
             [ 'BODY', '<!--<Address Table>-->', '<!--</Address Table>-->',
               [ 
                  [ 'HIT*' ,
                     [
                        ['REGEX', '(<tr[\s>].*?<!--<Firm Line/>-->.*?</tr>)', \&trimComments, \&trimLFs, 'firm']
                       ,['REGEX', '(<tr[\s>].*?<!--<Address Line/>-->.*?</tr>)', \&trimComments, \&trimLFs, 'address']
                       ,['REGEX', '(<tr[\s>].*?<!--<City-State-ZIP/>-->.*?</tr>)', \&trimComments, \&trimLFs, \&parseCity, 'city']
                       ,['REGEX', '(<tr[\s>].*?<!--<Carrier Route/>-->.*?</tr>)', \&trimComments, \&trimLFs, \&cleanUpUsps, 'carrierRoute']
                       ,['REGEX', '(<tr[\s>].*?<!--<County/>-->.*?</tr>)', \&trimComments, \&trimLFs, 'county']
                       ,['REGEX', '(<tr[\s>].*?<!--<Delivery Point/>-->.*?</tr>)', \&trimComments, \&trimLFs, \&cleanUpUsps, 'deliveryPoint']
                       ,['REGEX', '(<tr[\s>].*?<!--<Check Digit/>-->.*?</tr>)', \&trimComments, \&trimLFs, \&cleanUpUsps, 'checkDigit']
                        # this regex never matches; just lets us declare fields.
                       ,[ 'REGEX', 'neverMatch', 'state', 'zipcode' ]
                     ]
                  ]
               ]
             ]
           ]
       ];


my $scraperFrame_OLD =
       [ 'HTML', 
          [ 
             [ 'BODY', 'The standardized address is:', '<CENTER',
               [ 
                  [ 'HIT*' ,
                     [  
                          [ 'REGEX', '<b>(.*?(<BR>)?.*?)<BR>\s*(.*?)\s(..)\s(\d\d\d\d\d-\d\d\d\d)<BR>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>'
                            ,'address', undef, 'city', 'state', 'zip', 'carrierRoute', 'county', 'deliveryPoint' , 'checkDigit' ]
                     ]
                  ]
                 ,[ 'HIT*' ,
                     [  
                          [ 'REGEX', '<b>(.*?)</b>.*?<b>(.*?)\s(..)\s(\d\d\d\d\d-\d\d\d\d)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>.*?<b>(.*?)</b>'
                            ,'address', 'city', 'state', 'zip', 'carrierRoute', 'county', 'deliveryPoint' , 'checkDigit' ]
                     ]
                  ]
               ]
             ]
           ]
       ];


sub testParameters {
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return {
                 'SKIP' => ''#'ZIPplus4 test parameters have not yet been fixed' 
                ,'testNativeQuery' => '20500'
                ,'testNativeOptions' => {
                                             'address' => '1600 Pennsylvannia Ave'
                                            ,'city' => 'Washington'
                                            ,'state' => 'DC'
                                            ,'zipcode' => ''
                                        }
                ,'expectedOnePage' => 1
                ,'expectedMultiPage' => 1
                ,'expectedBogusPage' => 1
           };
}


# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }


sub cleanUpUsps {
    my ($self, $hit, $dat) = @_;
    $dat = $self->trimLFs($hit, $dat);
    $dat =~ s/^County://gs;
    $dat =~ s/^Carrier Route://gs;
    $dat =~ s/^Delivery Point://gs;
    $dat =~ s/^Check Digit://gs;
    $dat =~ s/\s*-->//gs;
    return $dat;
}

sub parseCity {
    my ($self, $hit, $dat) = @_;
    $dat = $self->cleanUpUsps($hit, $dat);
    $dat =~ s/^(.*)\s+(\w+)\s+(\d\d\d\d\d)\s?(-\d\d\d\d)$/$1/s;
    $hit->plug_elem('state', $2);
    $hit->plug_elem('zipcode', "$3$4");
    return $dat;
}

{ package AddressDedup;
# This package helps ZipPlus4.pl to de-duplicate the address list.
# With minor or no modification, it might be useful to others, too.
use Class::Struct;
    struct ( 'AddressDedup' =>
              [
                  'Address'     => '$'
                 ,'City'        => '$'
                 ,'State'       => '$'
                 ,'Zip'         => '$'
                 ,'Name'        => '$'
                 ,'_allColumns' => '$'
                 ,'_zipColumn'  => '$'
              ]
           );

sub isEqual {
    my ($self, $other) = @_;

    return 0 unless ($self->_isEqualAddress($other->Address));
    return 0 unless ($self->_isEqualCity($other->City));
    return 0 unless ($self->_isEqualState($other->State));
    return 0 unless ($self->_isEqualZip($other->Zip));
#    return 0 unless ($self->_isEqualName($other->Name));
    
    return 1;
}
sub _isEqualAddress {
    my ($self, $str) = @_;
    return ($self->Address eq $str);
}
sub _isEqualCity {
    my ($self, $str) = @_;
    return ($self->City eq $str);
}
sub _isEqualState {
    my ($self, $str) = @_;
    return ($self->State eq $str);
}
sub _isEqualZip {
    my ($self, $str) = @_;
    return ($self->Zip eq $str);
}
sub _isEqualName {
    my ($self, $str) = @_;
    return ($self->Name eq $str);
}


sub setValue {
    my ($self, $colNums, $fullLine) = @_;
    
    chomp $fullLine;
    my @cols = split ',', $fullLine;
    $self->_allColumns(\@cols);

    $self->Address($cols[$colNums->{'colAddress'}]);
    $self->City($cols[$colNums->{'colCity'}]);
    $self->State($cols[$colNums->{'colState'}]);
    $self->Zip($cols[$colNums->{'colZip'}]);

    $self->_zipColumn($colNums->{'colZip'});
}

sub isEmpty {
    my ($self) = @_;
    return 0 if $self->Address;
    return 0 if $self->City;
    return 0 if $self->State;
    return 0 if $self->Zip;
    return 0 if $self->Name;
    return 1;
}

sub asString {
    my ($self) = @_;
    
    my $allColumns = $self->_allColumns();

    $$allColumns[$self->_zipColumn] = $self->Zip;
    
    return join ',', @$allColumns;
}
}
1;

__END__
=pod

=head1 NAME

WWW::Scraper::ZIPplus4 - Get ZIP+4 code, given street address, from www.usps.com. 
Also helps de-duplicate a mailing list.


=head1 SYNOPSIS

=over 1

=item Simple

 use WWW::Scraper(qw(2.25));
 use WWW::Scraper::Request::ZIPplus4;

 my $ZIPplus4 = new WWW::Scraper(
         'ZIPplus4',
        ,{   'address1' => '1600 Pennsylvannia Ave'
            ,'city'     => 'Washington'
            ,'state'    => 'DC'
            ,'zipcode'  => '20500'
         } );

 while ( my $response = $ZIPplus4->next_response() )
 {    
     print $response->zipcode()."\n";
 }

=item Complete

 use WWW::Scraper(qw(2.25));
 use WWW::Scraper::Request::ZIPplus4;

 my $ZIPplus4 = new WWW::Scraper( 'ZIPplus4' );

 my $request = new WWW::Scraper::Request::ZIPplus4;
 
 # Note: Delivery_Address(), and either Zip_Code(), or City() and State(), are required.
 $request->address1('1600 Pennsylvannia Ave');
 $request->city('Washington');
 $request->state('DC');
 $request->zipcode('20500');

 $ZIPplus4->scraperRequest($request);
 while ( my $response = $ZIPplus4->next_response() )
 {    
     for ( qw(address city state zipcode county carrierRoute checkDigit deliveryPoint) ) {
         print "$_: ".${$response->$_()}."\n";
     }
 }

=back

=head1 DESCRIPTION

This class is an ZIPplus4 specialization of WWW::Scraper.
It handles making and interpreting ZIPplus4 searches
F<http://www.ZIPplus4.com>.

=head1 SPECIAL THANKS

=over 8

=item To Klemens Schmid (klemens.schmid@gmx.de), for FormSniffer.

This tool is an excellent compliment to Scraper to almost instantly discover form and CGI parameters for configuring new Scraper modules.
It instantly revealed what I was doing wrong in the new ZIPplus4 format one day (after hours of my own clumsy attempts).
See FormSniffer at http://www.wap2web.de/formsniffer2.aspx (Win32 only).

=back

=head1 AUTHOR and CURRENT VERSION


C<WWW::Scraper::ZIPplus4> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


