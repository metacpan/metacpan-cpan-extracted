package NDFD::Weather::RequestProcess;
#use strict;
#use warnings;
our $VERSION=1.00;
#sub __new {
#    my $class = shift;
#    my $self = bless {}, $class;
#    return $self;
#}
 
sub _CP{
    my $class=shift;
    my $self=shift;
    #print $$self{0};
    my $request=NDFD::Weather::Report->_request($self);
    $request->CornerPoints(
                NDFD::Weather::XML::CornerPointsXML($self)
    );
}
sub _LLLCN{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->LatLonListCityNames(
                NDFD::Weather::XML::LatLonListCityNamesXML($self)
    );
}
sub _LLLZC{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->LatLonListZipCode(
                 NDFD::Weather::XML::LatLonListZipCodeXML($self)
    );
}
sub _NDFDGBD{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->NDFDgenByDay(
                 NDFD::Weather::XML::NDFDgenByDayXML($self)
    );
}
sub _NDFDGBDLLL{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->NDFDgenByDayLatLonList(
                 NDFD::Weather::XML::NDFDgenByDayLatLonListXML($self)
    );
}
sub _GLLL{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->GmlLatLonList(
                NDFD::Weather::XML::GmlLatLonListXML($self),
                NDFD::Weather::XML::WeatherParameters($self)
    );
    
}
sub _NDFDG{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->NDFDgen(
                NDFD::Weather::XML::NDFDgenXML($self),
                NDFD::Weather::XML::WeatherParameters($self)
    );
}
sub _GTS{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->GmlTimeSeries(
                NDFD::Weather::XML::GmlTimeSeriesXML($self)
    );
}
sub _LLLL{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->LatLonListLine(
                NDFD::Weather::XML::LatLonListLineXML($self)
    );
}
sub _LLLS{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->LatLonListSquare(
                NDFD::Weather::XML::LatLonListSquareXML($self)
    );
}
sub _LLLSBD{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->LatLonListSubgrid(
                NDFD::Weather::XML::LatLonListSubgridXML($self)
    );
}
sub _NDFDLLLT{
    my $class=shift;
    my $self=shift;
    my $request=NDFD::Weather::Report->_request($self);
    $request->NDFDgenLatLonList(
                NDFD::Weather::XML::NDFDgenLatLonListXML($self),
                NDFD::Weather::XML::WeatherParameters($self)
    );
}
1;
__END__