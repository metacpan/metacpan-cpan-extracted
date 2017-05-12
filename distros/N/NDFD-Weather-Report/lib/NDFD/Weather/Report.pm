package NDFD::Weather::Report;
use 5.010000;
use SOAP::Lite;# + trace => 'debug';
use XML::Simple;
use strict;
use warnings;
use version;
our $VERSION=1.00;
require Exporter;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NDFD::Weather::Report ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	NDFDgen  LatLonListCityNames GetCurrentWeather
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

sub new {
    my $class = shift;
    my %params=@_;
    my $self ={
        %params,
        };
    return bless $self, $class;
}
sub _request{
    my $class=shift;
    my ($self)=shift;
    $$self{'uri'}           =   ($$self{'uri'})     ?   $$self{'uri'}   :
                        'http://graphical.weather.gov/xml/SOAP_server/ndfdXMLserver.php?wsdl',
    $$self{'proxy'}         =   ($$self{'proxy'})   ?   $$self{'proxy'} :
                        'http://graphical.weather.gov/xml/SOAP_server/ndfdXMLserver.php',
    $$self{'EndPoint_url'}  =   ($$self{'EndPoint_url'}) ?  $$self{'EndPoint_url'} :
                        'http://graphical.weather.gov/xml/DWMLgen/wsdl/ndfdXML.wsdl',
    my $soap_request = SOAP::Lite
        -> uri($$self{'uri'})
        ->on_action(sub{join '#',@_ })
        -> proxy($$self{'proxy'}
    );
    $soap_request->ns($$self{'EndPoint_url'}, 'ndf');
    $soap_request->envprefix('soapenv');
    $soap_request->readable(1);
}
sub Parse_XML_Data_decode{
    my $class=shift;
    my ($xml)=shift;
        if (SOAP::Deserializer->is_xml($xml)==1){
            return eval{                
                SOAP::Deserializer->decode($xml);
            };    
        }
        
####error message marker no. 1 ###
    print "xml_Data_parse_error","Xml parsing error: $@" if $@;
}
sub Parse_XML_deserialize{
    my $class=shift;
    my ($xml)=shift;
        if (SOAP::Deserializer->is_xml($xml)==1){
            return eval{
                SOAP::Deserializer->deserialize($xml);                
            };    
        }
        
####error message marker no. 2 ###
    print "xml_Data_parse_error","Xml parsing error: $@" if $@;
}
sub Parse_XML_Data{
    my $class=shift;
    my ($xml)=shift;
    return eval{
            XMLin($xml,ForceArray => 1,NormaliseSpace=>2,SuppressEmpty=>undef)
        };
    
####error message marker no. 3 ###
    print "xml_Data_parse_error","Xml parsing error: $@" if $@;
}


package NDFD::Weather::Processer;
use NDFD::Weather::GenerateXML;
use NDFD::Weather::RequestProcess;
our @ISA = qw(NDFD::Weather::Report);
sub CornerPoints{
    my $Process_Return1=
    NDFD::Weather::RequestProcess
        ->_CP(shift)
            ;
            if(!$Process_Return1->valueof('//CornerPointsResponse/listLatLonOut/')){
                if(!$Process_Return1->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return1->valueof('//faultstring');
                    my $error_msg1 =$Process_Return1->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return1
                                ->valueof('//ExceptionText');
                }
            }
        return $Process_Return1->valueof('//CornerPointsResponse/listLatLonOut/');
}
sub LatLonListCityNames{
    my $Process_Return2=
    NDFD::Weather::RequestProcess
        ->_LLLCN(shift)
            ;
            if(!$Process_Return2->valueof('//LatLonListCityNamesResponse/listLatLonOut/')){
                if(!$Process_Return2->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return2->valueof('//faultstring');
                    my $error_msg1 =$Process_Return2->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return2
                                ->valueof('//ExceptionText');
                }
            }
        return $Process_Return2->valueof('//LatLonListCityNamesResponse/listLatLonOut/');
}
sub LatLonListZipCode{
    my $Process_Return3=
    NDFD::Weather::RequestProcess
        ->_LLLZC(shift)
            ;
            if(!$Process_Return3->valueof('//LatLonListZipCodeResponse/listLatLonOut/')){
                if(!$Process_Return3->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return3->valueof('//faultstring');
                    my $error_msg1 =$Process_Return3->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return3
                                ->valueof('//ExceptionText');
                }
            }
        return $Process_Return3->valueof('//LatLonListZipCodeResponse/listLatLonOut/');
}
sub NDFDgenByDay{
    my $Process_Return4=
    NDFD::Weather::RequestProcess
        ->_NDFDGBD(shift);
        if(!$Process_Return4->valueof('//NDFDgenByDayResponse/dwmlByDayOut')){
                if(!$Process_Return4->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return4->valueof('//faultstring');
                    my $error_msg1 =$Process_Return4->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return4
                                ->valueof('//ExceptionText');
                }
            }
        return $Process_Return4->valueof('//NDFDgenByDayResponse/dwmlByDayOut');
}
sub NDFDgenByDayLatLonList{
    my $Process_Return5=
    NDFD::Weather::RequestProcess
        ->_NDFDGBDLLL(shift)
            ;
            if(!$Process_Return5->valueof('//NDFDgenByDayLatLonListResponse/dwmlByDayOut')){
                if(!$Process_Return5->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return5->valueof('//faultstring');
                    my $error_msg1 =$Process_Return5->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return5
                                ->valueof('//ExceptionText');
                }
            }
        return $Process_Return5->valueof('//NDFDgenByDayLatLonListResponse/dwmlByDayOut');
}
sub GmlLatLonList{
    my $Process_Return6 =
    NDFD::Weather::RequestProcess
        ->_GLLL(shift)
            ;
        if(!$Process_Return6->valueof('//GmlLatLonListResponse/dwGmlOut')){
                if(!$Process_Return6->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return6->valueof('//faultstring');
                    my $error_msg1 =$Process_Return6->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return6
                                ->valueof('//ExceptionText');
                }
            }
        #else{return $Process_Return6->valueof('//GmlLatLonListResponse/dwGmlOut')};
        return $Process_Return6->valueof('//GmlLatLonListResponse/dwGmlOut');
}
sub NDFDgen{
    my $Process_Return7 =
    NDFD::Weather::RequestProcess
        ->_NDFDG(shift)
            ;
        if(!$Process_Return7->valueof('//NDFDgenResponse/dwmlOut')){
                if(!$Process_Return7->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return7->valueof('//faultstring');
                    my $error_msg1 =$Process_Return7->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return7
                                ->valueof('//ExceptionText');
                }
            }
        return $Process_Return7->valueof('//NDFDgenResponse/dwmlOut');
}

sub GmlTimeSeries{
    my $Process_Return8 =
    NDFD::Weather::RequestProcess
        ->_GTS(shift)
            ;
        if(!$Process_Return8->valueof('//GmlTimeSeriesResponse/dwGmlOut')){
            #&debug($Process_Return8
            #            ->valueof('//ExceptionText'));
                if(!$Process_Return8->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return8->valueof('//faultstring');
                    my $error_msg1 =$Process_Return8->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return8
                                ->valueof('//ExceptionText');
                }
                
            }
        return $Process_Return8->valueof('//GmlTimeSeriesResponse/dwGmlOut');
}
sub LatLonListLine{
    my $Process_Return9 =
    NDFD::Weather::RequestProcess
        ->_LLLL(shift)
            ;
        if(!$Process_Return9->valueof('//LatLonListLineResponse/listLatLonOut')){            
                if(!$Process_Return9->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return9->valueof('//faultstring');
                    my $error_msg1 =$Process_Return9->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return9
                                ->valueof('//ExceptionText');
                }
                
            }
        return $Process_Return9->valueof('//LatLonListLineResponse/listLatLonOut');
}
sub LatLonListSquare{
    my $Process_Return10 =
    NDFD::Weather::RequestProcess
        ->_LLLS(shift)
            ;
        if(!$Process_Return10->valueof('//LatLonListSquareResponse/listLatLonOut')){            
                if(!$Process_Return10->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return10->valueof('//faultstring');
                    my $error_msg1 =$Process_Return10->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return10
                                ->valueof('//ExceptionText');
                }
                
            }
        return $Process_Return10->valueof('//LatLonListSquareResponse/listLatLonOut');
}
sub LatLonListSubgrid{
    my $Process_Return11 =
    NDFD::Weather::RequestProcess
        ->_LLLSBD(shift)
            ;
        if(!$Process_Return11->valueof('//LatLonListSubgridResponse/listLatLonOut')){            
                if(!$Process_Return11->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return11->valueof('//faultstring');
                    my $error_msg1 =$Process_Return11->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return11
                                ->valueof('//ExceptionText');
                }
                
            }
        return $Process_Return11->valueof('//LatLonListSubgridResponse/listLatLonOut');
}
sub NDFDgenLatLonList{
    my $Process_Return12 =
    NDFD::Weather::RequestProcess
        ->_NDFDLLLT(shift)
            ;
        if(!$Process_Return12->valueof('//NDFDgenLatLonListResponse/dwmlOut')){            
                
                if(!$Process_Return12->valueof('//ExceptionText')){
                    
                    my $error_msg0 =$Process_Return12->valueof('//faultstring');
                    my $error_msg1 =$Process_Return12->valueof('//detail');
                    return "Error :-".$error_msg0.".   Details :- ".$error_msg1;
                }else{
                    return
                        $Process_Return12
                                ->valueof('//ExceptionText');
                }
                
        }
        return $Process_Return12->valueof('//NDFDgenLatLonListResponse/dwmlOut');
}
sub GetCurrentWeather{
    shift;
    my $latitude=shift;
    my $longitude=shift;
    
    
	die "latitude or longitude vlaue is missing !!" unless defined $latitude and $longitude;

     use LWP::Simple;
	my $url = "http://forecast.weather.gov/MapClick.php?lat=$latitude&lon=$longitude&unit=0&lg=english&FcstType=dwml";
	my $content = get $url;
	die "Couldn't get $url" unless defined $content;
	#$q->header('text/xml');
	return $content;
}
#sub debug{
#   my $messsage=shift;
#   print $messsage;
#}
1;
__END__

=head1 NAME

NDFD::Weather::Report - National Weather Service - API

National Digital Forecast Database (NDFD)
Simple Object Access Protocol (SOAP)
Web Service

=head1 VERSION

Version 1.00

=cut

=head2 WSDL

    uri=>'http://graphical.weather.gov/xml/SOAP_server/ndfdXMLserver.php?wsdl'
    proxy=>'http://graphical.weather.gov/xml/SOAP_server/ndfdXMLserver.php'
    EndPoint_url=>'http://graphical.weather.gov/xml/DWMLgen/wsdl/ndfdXML.wsdl'
    
=cut

=head1 SYNOPSIS

    National Digital Forecast Database (NDFD) Extensible Markup Language (XML) is a service providing the public,
    government agencies, and commercial enterprises with data from the National Weather Service’s (NWS) digital forecast database.
    This service, which is defined in a Service Description Document, provides NWS customers and partners the ability to request
    NDFD data over the internet and receive the information back in an XML format.  The request/response process is made possible
    by the NDFD XML Simple Object Access Protocol (SOAP) server.
    
    
    To see the details of the NDFD XML SOAP service, go to the following URL and click on the NDFDgen or NDFDgenByDay link:
    
    If the web service description provided by the SOAP server does not meet your needs, similar information is available in
    the following Web Service Description Language (WSDL) document:.

=over 4

=item * L<http://graphical.weather.gov/xml/SOAP_server/ndfdXMLserver.php>

=item * L<http://graphical.weather.gov/xml/DWMLgen/wsdl/ndfdXML.wsdl>

=back

=head1 DEPENDENCIES

SOAP::Lite, XML::Simple ,LWP::Simple 

=cut

=head1 DESCRIPTION

The first step to using the web service is to create a SOAP client.The client creates and sends the SOAP request to the server.
The request sent by the client then invokes one of the server functions.   There are currently nine functions: NDFDgen(),
NDFDgenLatLonList(), LatLonListSubgrid(), LatLonListLine(), LatLonListZipCode(), LatLonListSquare(), CornerPoints(), NDFDgenByDay(),
and NDFDgenByDayLatLonList().   See the tables below for required following user supplied input:

=cut

=head1 SUBROUTINES / METHODS

=head2 new()
    
    NDFD::Weather::Processer->new();
   
Constructor for the NDFD::Weather::Report class

Valid keys for %params are currently mentioned bellow:
    
=head2 CornerPoints()

    my $result=NDFD::Weather::Processer->new(
        uri=>'http://graphical.weather.gov/xml/SOAP_server/ndfdXMLserver.php?wsdl',
        proxy=>'http://graphical.weather.gov/xml/SOAP_server/ndfdXMLserver.php',
        EndPoint_url=>'http://graphical.weather.gov/xml/DWMLgen/wsdl/ndfdXML.wsdl',
        sector=>'conus',
    );
    my $value= $result->CornerPoints;
    
    OR
    
    my $result=NDFD::Weather::Processer->new(
            sector=>'conus'
            );
    my $value= $result->CornerPoints;

B<Description:>

One of the NDFD grids (conus, alaska, nhemi, guam, hawaii, and puertori).
    
CornerPoints() function: Returns the WGS84 latitude and longitude values for the corners of an NDFD grid as well as the
resolution required to retrieve the entire grid and still stay under the maximum allowed point restriction.

You can view an example of how to invoke CornerPoints() by selecting "Corner Grid Points" on the following web page.

L<http://graphical.weather.gov/xml/SOAP_server/ndfdXML.htm>

You can see a sample SOAP request for the CornerPoints() interface at L<http://graphical.weather.gov/xml/docs/SOAP_Requests/CornerPoints.xml>

=head2 LatLonListCityNames()
    
    my $result=NDFD::Weather::Processer->new(
        displayLevel=>'12', 
    );
    my $value= $result->LatLonListCityNames;
    my $xml_handler=$result->Parse_XML_Data($value);
    print $$xml_handler{'cityNameList'}[0];

B<Description:>

1  = Primary Cities ,2 = Secondary Cities, 3 = Cities that increase data density across the US (cities 1 - 200),
4  = Cities that increase data density across the US (cities 201 - 304), 12 = Combines cities in 1 and 2 above,
34 = Combines cities in 3 and 4 above, 1234 = Combines cities in 1, 2, 3, and 4 above,]        

LatLonListCityNames() function: Returns the WGS84 latitude and longitude values for a predefined list of cities.
The cities are grouped into a number of subsets to facilitate requesting data. You can view the cities in each
group by clicking on the links in the table below. The returned list of pointsis suitable for input into NDFDgenLatLonList(),
NDFDgenByDayLatLonList(), and GmlLatLonList() which will return NDFD data for those points.

You can view an example of how to invoke LatLonListCityNames() by selecting "Grid Points For NDFD Cities" on the following web page.

L<http://graphical.weather.gov/xml/SOAP_server/ndfdXML.htm>

You can see a sample SOAP request for the LatLonListCityNames() interface at
L<http://graphical.weather.gov/xml/docs/SOAP_Requests/LatLonListCityNames.xml>


=head2 LatLonListZipCode()

    my $result=NDFD::Weather::Processer->new(
        zipCodeList=>'20910',
    );
    my $value= $result->LatLonListZipCode;
    my $xml_handler1=$result->Parse_XML_Data($value);
    print $$xml_handler1{'latLonList'}[0];
    print Dumper $xml_handler1;

B<Description:>

The zip code of the area for which you want NDFD grid points.

LatLonListZipCode() function: Returns the WGS84 latitude and longitude values for one or more zip codes
(50 United States and Puerto Rico). The returned list of points is suitable for input into NDFDgenLatLonList(),
NDFDgenByDayLatLonList(), and GmlLatLonList() which will return NDFD data for those points.

You can view an example of how to invoke LatLonListZipCode() by selecting "Grid Points For A Zip Code" on the following web page.

L<http://graphical.weather.gov/xml/SOAP_server/ndfdXML.htm>

You can see a sample SOAP request for the LatLonListZipCode() interface at
L<http://graphical.weather.gov/xml/docs/SOAP_Requests/LatLonListZipCode.xml>


=head2 NDFDgenByDay()

    my $result=NDFD::Weather::Processer->new(
        latitude=>'39.0000',
        longitude=>'-77.0000',
        startDate=>'2012-12-19 ',
        numDays=>'1',
        Unit=>'',
        format=>'12 hourly',
    );
    my $value= $result->NDFDgenByDay;
    my $xml_handler1=$result->Parse_XML_Data($value);
    print Dumper $xml_handler1;

NDFDgenByDay() function: Returns DWML encoded NDFD data for a point. Data for each point is summarized for either a 24- or 12-hour time period

B<Description:>

=over

=item 1. 

The WGS84 latitude of the point for which you want NDFD data.   North latitude is positive.

=item 2. 

The WGS84 longitude of the point for which you want NDFD data.   West longitude is negative.

=item 3. 

The beginning day for which you want NDFD data.   If the string is empty, the start date is assumed
to be the earliest available day in the database. This input is only needed if one wants to shorten the time window
data is to be retrieved for (less than entire 7 days worth), e.g. if user wants data for days 2-5. 

=item 4.

The number of days worth of NDFD data you want. Default will be all available data in the database.
This input is only needed if one wants to shorten the time window data is to be retrieved for
(less than entire 7 days worth), e.g. if user wants data for days 2-5.

=item 5.

The unit data is to be retrieved in. The default value is U.S. Standard, or English units ("e").
A value of "m" will return data in Metric, or SI units (The International System of Units).
If the string is empty, data will be returned in U.S. standard units, thus the input is only needed for metric conversion.

=item 6.

There are two formats.   The “24 hourly” format returns NDFD data summarized for a 24 hour period running from 6:00 AM to 6:00 AM.
The “12 hourly” format summarizes NDFD data into two 12 hour periods per day that run from 6:00 AM to 6:00 PM and 6:00 PM to 6:00 AM


=back

=head2 NDFDgenByDayLatLonList()

    my $result=NDFD::Weather::Processer->new(
        listLatLon=>'38.99,-77.02 39.70,-104.80',
        startDate=>'2012-12-20',
        numDays=>'1',
        Unit=>'',
        format=>'12 hourly',
    );
    my $value= $result->NDFDgenByDayLatLonList;
    my $xml_handler1=$result->Parse_XML_Data($value);
    print Dumper $xml_handler1;


NDFDgenByDayLatLonList() functionReturns DWML encoded NDFD data for a list of points.
Data for each point is summarized for either a 24- or 12-hour time period

B<Description :>

=over

=item 1.

List of WGS84 latitude and longitude pairs for the points for which you want NDFD data.
Each point's latitude and longitude value is seperated by a comma. Each pair (one latitude and longitude value) is separated by a space.
Number of points requested can not exceed 200.

=item 2.

The beginning day for which you want NDFD data.   If the string is empty, the start date is assumed to be
the earliest available day in the database.

=item 3.

The number of days worth of NDFD data you want.

=item 4.

The unit data is to be retrieved in. The default value is U.S. Standard, or English units ("e"). A value of "m" will return data in Metric,
or SI units (The International System of Units). If the string is empty, data will be returned in U.S. standard units, thus the input is
only needed for metric conversion. 

=item 5.

There are two formats.   The “24 hourly” format returns NDFD data summarized for a 24 hour period running from 6:00 AM to 6:00 AM.
The “12 hourly” format summarizes NDFD data into two 12 hour periods per day that run from 6:00 AM to 6:00 PM and 6:00 PM to 6:00 AM 

=back

You can view an example of how to invoke NDFDgenByDayLatLonList() by selecting "NDFD Data For Multiple Points" on the following web page.
NOTE: Number of points requested can not exceed 200.

L<http://graphical.weather.gov/xml/SOAP_server/ndfdSOAPByDay.htm>

You can see a sample SOAP request for the NDFDgenByDayLatLonList() interface at
L<http://graphical.weather.gov/xml/docs/SOAP_Requests/NDFDgenByDayLatLonList.xml>

=head2 GmlLatLonList()

    my $result=NDFD::Weather::Processer->new(
        listLatLon =>'39.0138,-77.0242',
        requestedTime =>'2012-12-22T23:59:59',
        featureType =>'Forecast_Gml2Point',
        
        maxt =>1,
        mint =>1,
        temp =>1,
        dew =>0,
        pop12 =>0,
        qpf =>0,
        sky =>0,
        snow =>0,
        wspd =>0,
        wdir =>0,
        wx =>0,
        waveh =>0,
        icons =>0,
        rh =>0,
        appt =>0,
        incw34 =>0,
        incw50 =>0,
        incw64 =>0,
        cumw34 =>0,
        cumw50 =>0,
        cumw64 =>0,
        conhazo =>0,
        ptornado =>0,
        phail =>0,
        ptstmwinds =>0,
        pxtornado =>0,
        pxhail =>0,
        pxtstmwinds =>0,
        ptotsvrtstm =>0,
        pxtotsvrtstm =>0,
        tmpabv14d =>0,
        tmpblw14d =>0,
        tmpabv30d =>0,
        tmpblw30d =>0,
        tmpabv90d =>0,
        tmpblw90d =>0,
        prcpabv14d =>0,
        prcpblw14d =>0,
        prcpabv30d =>0,
        prcpblw30d =>0,
        prcpabv90d =>0,
        prcpblw90d =>0,
        precipa_r =>0,
        sky_r =>0,
        td_r =>0,
        temp_r =>0,
        wdir_r =>0,
        wspd_r =>0,
        wgust =>0,
    );
    my $value= $result->GmlLatLonList;
    
    my $xml_handler1=$result->Parse_XML_Data($value);
    print Dumper $xml_handler1;
    print $$xml_handler1{'gml:featureMember'}[0]{'app:Forecast_Gml2Point'}[0]{'app:minimumTemperature'}[0];


GmlLatLonList() function: Returns Digital Weather GML encoded NDFD data for a list of points a single valid time.

B<Description:>

=over

=item 1.

List of WGS84 latitude and longitude pairs for the points for which you want NDFD data.
Each point's latitude and longitude value is seperated by a comma. Each pair (one latitude and longitude value) is separated by a space.
Number of points requested can not exceed 200.

=item 2.

The time for which you want NDFD data.

=item 3.

GML 2 Compliant Data Structure: Forecast_Gml2Point
GML 3 Compliant Data Structures: Forecast_GmlsfPoint, Forecast_GmlObs, NdfdMultiPointCoverage
KML 2 Compliant Data Structure: Ndfd_KmlPoint

=item 4.

The NDFD parameters that you are requesting.   For valid inputs see the NDFD Element Names Page
L<http://graphical.weather.gov/xml/docs/elementInputNames.php>.


=back

=head2 NDFDgen()

    my $result=NDFD::Weather::Processer->new(
        latitude =>'38.99',
        longitude =>'-77.02',
        product =>'time-series',
        startTime =>'2012-12-20T12:00',
        endTime =>'2012-12-22T12:00',
        Unit =>'e',
        
        maxt =>1,
        mint =>1,
        temp =>1,
        dew =>0,
        pop12 =>0,
        qpf =>0,
        sky =>0,
        snow =>1,
        wspd =>1,
        wdir =>1,
        wx =>1,
        waveh =>0,
        icons =>1,
        rh =>0,
        appt =>0,
        incw34 =>0,
        incw50 =>0,
        incw64 =>0,
        cumw34 =>0,
        cumw50 =>0,
        cumw64 =>0,
        conhazo =>0,
        ptornado =>0,
        phail =>0,
        ptstmwinds =>0,
        pxtornado =>0,
        pxhail =>0,
        pxtstmwinds =>0,
        ptotsvrtstm =>0,
        pxtotsvrtstm =>0,
        tmpabv14d =>0,
        tmpblw14d =>0,
        tmpabv30d =>0,
        tmpblw30d =>0,
        tmpabv90d =>0,
        tmpblw90d =>0,
        prcpabv14d =>0,
        prcpblw14d =>0,
        prcpabv30d =>0,
        prcpblw30d =>0,
        prcpabv90d =>0,
        prcpblw90d =>0,
        precipa_r =>0,
        sky_r =>0,
        td_r =>0,
        temp_r =>0,
        wdir_r =>0,
        wspd_r =>0,
        wgust =>0,
    );
    my $value= $result->NDFDgen;
    
    my $xml_handler1=$result->Parse_XML_Data($value);
    if ($xml_handler1!~/HASH/){
        print $value;
        exit;
    }
    print Dumper $xml_handler1;
    
NDFDgen() function: Returns DWML encoded NDFD data for a point

B<Description:>

=over

=item 1.

The WGS84 latitude of the point for which you want NDFD data.   North latitude is positive. 

=item 2.

The WGS84 longitude of the point for which you want NDFD data.   West longitude is negative. 

=item 3.

There are two products.The “time-series” product returns all data between the start and end times for the selected weather parameters.
The “glance” product returns all data between the start and end times for the parameters maxt, mint, sky, wx, and icons 

=item 4.

The beginning time for which you want NDFD data.If the string is empty, the start time is assumed to be the earliest
available time in the database. This input is only needed if one wants to shorten the time window data is to be retrieved for
(less than entire 7 days worth), e.g. if user wants data for days 2-5.

=item 5.

The ending time for which you want NDFD data.If the string is empty, the end time is assumed to be the last available
time in the database. This input is only needed if one wants to shorten The time window data is to be retrieved for
(less than entire 7 days worth), e.g. if user wants data for days 2-5.

=item 6.

The unit data is to be retrieved in. The default value is U.S. Standard, or English units ("e").
A value of "m" will return data in Metric, or SI units (The International System of Units).
If the string is empty, data will be returned in U.S. Standard units, thus the input is only needed for metric conversion.

=item 7.

The NDFD parameters that you are requesting.   For valid inputs see the NDFD Element Names Page.
L<http://graphical.weather.gov/xml/docs/elementInputNames.php>.

=back

=head2 GmlTimeSeries()

GmlTimeSeries()function: Returns Digital Weather GML encoded NDFD data for a list of points during a user specified time period.

    my $result=NDFD::Weather::Processer->new(
        listLatLon=>'38.99,-77.02',
        startTime=>'2012-12-25T00:00:00',
        endTime=>'2012-12-27T12:59:59',
        compType=>'Between',
        featureType=>'Forecast_Gml2Point',
        propertyName=>'maxt,mint,wx'
    );
    my $value= $result->GmlTimeSeries;
    my $xml_handler1=$result->Parse_XML_Data_decode($value);
    
    if ( $xml_handler1!~/ARRAY/){
        print $value;
        exit;
    }
    
    print Dumper $xml_handler1;

B<Description:>

=over

=item 1.

List of WGS84 latitude and longitude pairs for the points for which you want NDFD data.
Each point's latitude and longitude value is seperated by a comma. Each pair (one latitude and longitude value)
is separated by a space. Number of points requested can not exceed 200.

=item 2.

The start time for which you want NDFD data.

=item 3.

The end time for which you want NDFD data. 

=item 4.

Comparison type. Can be IsEqual, Between, GreatThan, GreaterThanOrEqual, LessThan, or LessThanOrEqual.

=item 5.

GML 2 Compliant Data Structure: Forecast_Gml2Point
GML 3 Compliant Data Structures: Forecast_GmlsfPoint, Forecast_GmlObs, NdfdMultiPointCoverage
KML 2 Compliant Data Structure: Ndfd_KmlPoint

=item 6.

The NDFD element that you are requesting.   For valid inputs see the NDFD Element Names Page.
L<http://graphical.weather.gov/xml/docs/elementInputNames.php>

=back

=head2 LatLonListLine()

LatLonListLine() function: Returns the WGS84 latitude and longitude values for all points on a line defined by the line's end points.
The returned list of points is suitable for input into NDFDgenLatLonList(), NDFDgenByDayLatLonList(), and GmlLatLonList()
which will return NDFD data for those points. NOTE: The list of locations will only form a straight line when viewed in the NDFD
projection applicable to the grid.


    my $result=NDFD::Weather::Processer->new(
        endPoint1Lat=>'39.0000',
        endPoint1Lon=>'-77.0000',
        endPoint2Lat=>'39.0000',
        endPoint2Lon=>'-77.0000'
    );
    my $value= $result->LatLonListLine;
    my $xml_handler1=$result->Parse_XML_Data_decode($value);
    
    if ( $xml_handler1!~/ARRAY/){
        print $value;
        exit;
    }
    
    print Dumper $xml_handler1;


B<Description:>

=over

=item 1.

The WGS84 latitude of the first end point of the line for which you want NDFD grid points.North latitude is positive.

=item 2.

The WGS84 longitude of the first end point of the line for which you want NDFD grid points.West longitude is negative.

=item 3.

The WGS84 latitude of the second end point of the line for which you want NDFD grid points.North latitude is positive. 

=item 4.

The WGS84 longitude of the second end point of the line for which you want NDFD grid points.West longitude is negative. 

=back

=head2 LatLonListSquare()

LatLonListSquare() function: Returns the WGS84 latitude and longitude values for a rectangle defined by a center point
and distances in the latitudinal and longitudinal directions. The returned list of points is suitable for input into
NDFDgenLatLonList(), NDFDgenByDayLatLonList(), and GmlLatLonList() which will return NDFD data for those points.
NOTE: The subgrid locations will only form a rectangle when viewed in the NDFD projection applicable to the grid.

    my $result=NDFD::Weather::Processer->new(
        centerPointLat=>'39.0000',
        centerPointLon=>'-77.0000',
        distanceLat=>'50.0',
        distanceLon=>'50.0',
        resolution=>'20.0'
    );
    my $value= $result->LatLonListSquare;
    my $xml_handler1=$result->Parse_XML_Data_decode($value);
    
    if ( $xml_handler1!~/ARRAY/){
        print $value;
        exit;
    }
    
    print Dumper $xml_handler1;


B<Description:>

=over

=item 1.

The WGS84 latitude of the center or the rectangle for which you want NDFD grid points.North latitude is positive.

=item 2.

The WGS84 longitude of the center or the rectangle for which you want NDFD grid points.West longitude is negative. 

=item 3.

The distance from the center point in the latitudinal direction to the rectangle's East/West oriented sides.

=item 4.

The distance from the center point in the longitudinal direction to the rectangle's North/South oriented side. 

=item 5.

The default resolution for NDFD data is typically 5km. However, users can request latitude and longitude values
for resolutions greater ( 10km, 15km, 20km, etc.) than the native resolution so as to reduce the number of points returned.

=back

=head2 LatLonListSubgrid()

LatLonListSubgrid() function: Returns the WGS84 latitude and longitude values of all the NDFD grid points
within a rectangular subgrid as defined by points at the lower left and upper right corners of the rectangle.
The returned list of points is suitable for input into NDFDgenLatLonList(), NDFDgenByDayLatLonList(),
and GmlLatLonList() which will return NDFD data for those points. NOTE: The subgrid locations will only form a
rectangle when viewed in the NDFD projection applicable to the grid.

    my $result=NDFD::Weather::Processer->new(
        lowerLeftLatitude=>'33.8835',
        lowerLeftLongitude=>'-80.0679',
        upperRightLatitude=>'33.8835',
        upperRightLongitude=>'-80.0679',
        resolution=>'20.0'
    );
    my $value= $result->LatLonListSubgrid;
    my $xml_handler1=$result->Parse_XML_Data_decode($value);
    
    if ( $xml_handler1!~/ARRAY/){
        print $value;
        exit;
    }
    
    print Dumper $xml_handler1;


B<Description:>

=over

=item 1.

The WGS84 latitude of the lower left point of the rectangular subgrid for which you want NDFD grid points. North latitude is positive. 

=item 2.

The WGS84 longitude of the lower left point of the rectangular subgrid for which you want NDFD grid points. West longitude is negative.

=item 3.

The WGS84 latitude of the upper right point of the rectangular subgrid for which you want NDFD grid points. North latitude is positive. 

=item 4.

The WGS84 longitude of the upper right point of the rectangular subgrid for which you want NDFD grid points. West longitude is negative. 

=item 5.

The default resolution for NDFD data is typically 5km. However, users can request latitude and longitude
values for resolutions greater ( 10km, 15km, 20km, etc.) than the native resolution so as to reduce the number of points returned.

=back

=head2 NDFDgenLatLonList()

NDFDgenLatLonList() function: Returns DWML encoded NDFD data for a list of points

    my $result=NDFD::Weather::Processer->new(
        listLatLon=>'38.99,-77.02',
        product=>'time-series',
        startTime=>'2012-12-26T12:00',
        endTime=>'2012-12-27T12:00',
        Unit=>'e',
        
        maxt =>1,
        mint =>1,
        temp =>1,
        dew =>0,
        pop12 =>0,
        qpf =>0,
        sky =>0,
        snow =>1,
        wspd =>1,
        wdir =>1,
        wx =>1,
        waveh =>0,
        icons =>1,
        rh =>0,
        appt =>0,
        incw34 =>0,
        incw50 =>0,
        incw64 =>0,
        cumw34 =>0,
        cumw50 =>0,
        cumw64 =>0,
        conhazo =>0,
        ptornado =>0,
        phail =>0,
        ptstmwinds =>0,
        pxtornado =>0,
        pxhail =>0,
        pxtstmwinds =>0,
        ptotsvrtstm =>0,
        pxtotsvrtstm =>0,
        tmpabv14d =>0,
        tmpblw14d =>0,
        tmpabv30d =>0,
        tmpblw30d =>0,
        tmpabv90d =>0,
        tmpblw90d =>0,
        prcpabv14d =>0,
        prcpblw14d =>0,
        prcpabv30d =>0,
        prcpblw30d =>0,
        prcpabv90d =>0,
        prcpblw90d =>0,
        precipa_r =>0,
        sky_r =>0,
        td_r =>0,
        temp_r =>0,
        wdir_r =>0,
        wspd_r =>0,
        wgust =>0
            
    );
    my $value= $result->NDFDgenLatLonList;
    my $xml_handler1=$result->Parse_XML_Data_decode($value);
    
    if ( $xml_handler1!~/ARRAY/){
        print $value;
        exit;
    }
    
    print Dumper $xml_handler1;

B<Description:>

=over

=item 1.

List of WGS84 latitude and longitude pairs for the points for which you want NDFD data.
Each point's latitude and longitude value is seperated by a comma. Each pair (one latitude and longitude value) is separated by a space.
Number of points requested can not exceed 200.

=item 2.

There are two products.The “time-series” product returns all data between the start and end times for the selected weather parameters.
The “glance” product returns all data between the start and end times for the parameters maxt, mint, sky, wx, and icons 

=item 3.

The beginning time for which you want NDFD data.If the string is empty, the start time is assumed to be the earliest
available time in the database. This input is only needed if one wants to shorten the time window data is to be retrieved for
(less than entire 7 days worth), e.g. if user wants data for days 2-5. 

=item 4.

The ending time for which you want NDFD data.If the string is empty, the end time is assumed to be the last
available time in the database. This input is only needed if one wants to shorten the time window data is to
be retrieved for (less than entire 7 days worth), e.g. if user wants data for days 2-5.

=item 5.

The unit data is to be retrieved in.The default value is U.S. Standard, or English units ("e").
A value of "m" will return data in Metric, or SI units (The International System of Units). If the string is empty,
data will be returned in U.S. Standard units, thus the input is only needed for metric conversion.

=item 6.

The NDFD parameters that you are requesting.   For valid inputs see the NDFD Element Names Page.
L<http://graphical.weather.gov/xml/docs/elementInputNames.php>

=back

B<For more information about the API see :> L<http://graphical.weather.gov/xml/>

=head2 XML to hash Functions
    
    1. Parse_XML_Data($value);
    2. Parse_XML_deserialize($value);

=head2 XML to Array Function
    
    Parse_XML_Data_decode($value);
    
=head2 Current Weather
    
    my $result=NDFD::Weather::Processer->new();
    my $content=$result->GetCurrentWeather('42.8018','-73.9281');
    my $xml_handler12=$result->Parse_XML_Data($content);             
    print Dumper $xml_handler12;

You will get the current Weather Report

=head2 EXPORT

None.

=head1 AUTHOR

Mahesh Raghunath

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Mahesh Raghunath

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut