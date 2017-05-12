package NDFD::Weather::XML;
our $VERSION=1.00;
sub __new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}
sub CornerPointsXML{
    my $refs1=shift;
    return
      SOAP::Data->name('sector')->value($$refs1{sector})
            ->prefix('')->type('');
    
}
sub LatLonListCityNamesXML{
    my $refs1=shift;
    return
      SOAP::Data->name('displayLevel')->value($$refs1{displayLevel})
            ->prefix('')->type('');
}
sub LatLonListZipCodeXML{
    my $refs1=shift;
    return
      SOAP::Data->name('zipCodeList')->value($$refs1{zipCodeList})
            ->prefix('')->type('');
}
sub NDFDgenByDayXML{
    my $refs1=shift;
    $$refs1{Unit}=$$refs1{Unit}?$$refs1{Unit}:"";
    return
        SOAP::Data->name('latitude')->value($$refs1{latitude})
            ->prefix('')->type(''),
        SOAP::Data->name('longitude')->value($$refs1{longitude})
            ->prefix('')->type(''),
        SOAP::Data->name('startDate')->value($$refs1{startDate})
            ->prefix('')->type(''),
        SOAP::Data->name('numDays')->value($$refs1{numDays})
            ->prefix('')->type(''),
        SOAP::Data->name('Unit')->value($$refs1{Unit})
            ->prefix('')->type(''),
        SOAP::Data->name('format')->value($$refs1{format})
            ->prefix('')->type(''),
        ;
}
sub NDFDgenByDayLatLonListXML{
    my $refs1=shift;
    $$refs1{Unit}=$$refs1{Unit}?$$refs1{Unit}:"";
    return
        SOAP::Data->name('listLatLon')->value($$refs1{listLatLon})
            ->prefix('')->type(''),
        SOAP::Data->name('startDate')->value($$refs1{startDate})
            ->prefix('')->type(''),
        SOAP::Data->name('numDays')->value($$refs1{numDays})
            ->prefix('')->type(''),
        SOAP::Data->name('Unit')->value($$refs1{Unit})
            ->prefix('')->type(''),
        SOAP::Data->name('format')->value($$refs1{format})
            ->prefix('')->type(''),
        ;
}
sub GmlLatLonListXML{
    my $refs1=shift;
    return
        SOAP::Data->name('listLatLon')->value($$refs1{listLatLon})
            ->prefix('')->type(''),
        SOAP::Data->name('requestedTime')->value($$refs1{requestedTime})
            ->prefix('')->type(''),
        SOAP::Data->name('featureType')->value($$refs1{featureType})
            ->prefix('')->type('');
}
sub WeatherParameters{
    my $refs1=shift;
    my $XMl=SOAP::Data->name('weatherParameters'=>
                        \SOAP::Data->value(
                            SOAP::Data->name('maxt')->value($$refs1{'maxt'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('mint')->value($$refs1{'mint'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('temp')->value($$refs1{'temp'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('dew')->value($$refs1{'dew'})
                                ->prefix('')->type(''),
                            
                            SOAP::Data->name('pop12')->value($$refs1{'pop12'})
                                ->prefix('')->type(''),
                                
                            SOAP::Data->name('qpf')->value($$refs1{'qpf'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('sky')->value($$refs1{'sky'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('snow')->value($$refs1{'snow'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('wspd')->value($$refs1{'wspd'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('wdir')->value($$refs1{'wdir'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('wx')->value($$refs1{'wx'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('waveh')->value($$refs1{'waveh'})
                                ->prefix('')->type(''),
                                
                            SOAP::Data->name('icons')->value($$refs1{'icons'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('rh')->value($$refs1{'rh'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('appt')->value($$refs1{'appt'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('incw34')->value($$refs1{'incw34'})
                                ->prefix('')->type(''),
                            
                            SOAP::Data->name('incw50')->value($$refs1{'incw50'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('incw64')->value($$refs1{'incw64'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('cumw34')->value($$refs1{'cumw34'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('cumw50')->value($$refs1{'cumw50'})
                                ->prefix('')->type(''),
                            
                            SOAP::Data->name('cumw64')->value($$refs1{'cumw64'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('conhazo')->value($$refs1{'conhazo'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('ptornado')->value($$refs1{'ptornado'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('phail')->value($$refs1{'phail'})
                                ->prefix('')->type(''),
                            
                            SOAP::Data->name('ptstmwinds')->value($$refs1{'ptstmwinds'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('pxtornado')->value($$refs1{'pxtornado'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('pxhail')->value($$refs1{'pxhail'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('pxtstmwinds')->value($$refs1{'pxtstmwinds'})
                                ->prefix('')->type(''),
                                
                            SOAP::Data->name('ptotsvrtstm')->value($$refs1{'ptotsvrtstm'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('pxtotsvrtstm')->value($$refs1{'pxtotsvrtstm'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('tmpabv14d')->value($$refs1{'tmpabv14d'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('tmpblw14d')->value($$refs1{'tmpblw14d'})
                                ->prefix('')->type(''),
                                
                            SOAP::Data->name('tmpabv30d')->value($$refs1{'tmpabv30d'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('tmpblw30d')->value($$refs1{'tmpblw30d'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('tmpabv90d')->value($$refs1{'tmpabv90d'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('tmpblw90d')->value($$refs1{'tmpblw90d'})
                                ->prefix('')->type(''),
                                
                            SOAP::Data->name('prcpabv14d')->value($$refs1{'prcpabv14d'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('prcpblw14d')->value($$refs1{'prcpblw14d'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('prcpabv30d')->value($$refs1{'prcpabv30d'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('prcpblw30d')->value($$refs1{'prcpblw30d'})
                                ->prefix('')->type(''),
                                
                            SOAP::Data->name('prcpabv90d')->value($$refs1{'prcpabv90d'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('prcpblw90d')->value($$refs1{'prcpblw90d'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('precipa_r')->value($$refs1{'precipa_r'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('sky_r')->value($$refs1{'sky_r'})
                                ->prefix('')->type(''),
                                
                            SOAP::Data->name('temp_r')->value($$refs1{'temp_r'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('wdir_r')->value($$refs1{'wdir_r'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('wspd_r')->value($$refs1{'wspd_r'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('wgust')->value($$refs1{'wgust'})
                                ->prefix('')->type(''),
                            
                            SOAP::Data->name('critfireo')->value($$refs1{'critfireo'})
                                ->prefix('')->type(''),
                            SOAP::Data->name('dryfireo')->value($$refs1{'dryfireo'})
                                ->prefix('')->type(''),    
                            SOAP::Data->name('wwa')->value($$refs1{'wwa'})
                                ->prefix('')->type(''),        
                            SOAP::Data->name('wgust')->value($$refs1{'wgust'})
                                ->prefix('')->type(''),      
                            SOAP::Data->name('iceaccum')->value($$refs1{'iceaccum'})
                                ->prefix('')->type('')
                        )
                    );
    return $XMl->prefix('ndf');
}
sub NDFDgenXML{
    my $ref2=shift;
    $$ref2{Unit}=$$ref2{Unit}?$$ref2{Unit}:"";
    return
        SOAP::Data->name('latitude')->value($$ref2{latitude})
            ->prefix('')->type(''),
        SOAP::Data->name('longitude')->value($$ref2{longitude})
            ->prefix('')->type(''),
        SOAP::Data->name('product')->value($$ref2{product})
            ->prefix('')->type(''),
        SOAP::Data->name('startTime')->value($$ref2{startTime})
            ->prefix('')->type(''),
        SOAP::Data->name('endTime')->value($$ref2{endTime})
            ->prefix('')->type(''),
        SOAP::Data->name('Unit')->value($$ref2{Unit})
            ->prefix('')->type('');
}
sub GmlTimeSeriesXML{
    my $ref3=shift;
    return
        SOAP::Data->name('listLatLon')->value($$ref3{listLatLon})
            ->prefix('')->type(''),
        SOAP::Data->name('startTime')->value($$ref3{startTime})
            ->prefix('')->type(''),
        SOAP::Data->name('endTime')->value($$ref3{endTime})
            ->prefix('')->type(''),
        SOAP::Data->name('compType')->value($$ref3{compType})
            ->prefix('')->type(''),
        SOAP::Data->name('featureType')->value($$ref3{featureType})
            ->prefix('')->type(''),
        SOAP::Data->name('propertyName')->value($$ref3{propertyName})
            ->prefix('')->type('');
}
sub LatLonListLineXML{
    my $ref4=shift;
    return
        SOAP::Data->name('endPoint1Lat')->value($$ref4{endPoint1Lat})
            ->prefix('')->type(''),
        SOAP::Data->name('endPoint1Lon')->value($$ref4{endPoint1Lon})
            ->prefix('')->type(''),
        SOAP::Data->name('endPoint2Lat')->value($$ref4{endPoint2Lat})
            ->prefix('')->type(''),
        SOAP::Data->name('endPoint2Lon')->value($$ref4{endPoint2Lon})
            ->prefix('')->type('');
}
sub LatLonListSquareXML{
    my $ref5=shift;
    return
        SOAP::Data->name('centerPointLat')->value($$ref5{centerPointLat})
            ->prefix('')->type(''),
        SOAP::Data->name('centerPointLon')->value($$ref5{centerPointLon})
            ->prefix('')->type(''),
        SOAP::Data->name('distanceLat')->value($$ref5{distanceLat})
            ->prefix('')->type(''),
        SOAP::Data->name('distanceLon')->value($$ref5{distanceLon})
            ->prefix('')->type(''),
        SOAP::Data->name('resolution')->value($$ref5{resolution})
            ->prefix('')->type('');
}
sub LatLonListSubgridXML{
    my $ref6=shift;
    return
        SOAP::Data->name('lowerLeftLatitude')->value($$ref6{lowerLeftLatitude})
            ->prefix('')->type(''),
        SOAP::Data->name('lowerLeftLongitude')->value($$ref6{lowerLeftLongitude})
            ->prefix('')->type(''),
        SOAP::Data->name('upperRightLatitude')->value($$ref6{upperRightLatitude})
            ->prefix('')->type(''),
        SOAP::Data->name('upperRightLongitude')->value($$ref6{upperRightLongitude})
            ->prefix('')->type(''),
        SOAP::Data->name('resolution')->value($$ref6{resolution})
            ->prefix('')->type('');
}
sub NDFDgenLatLonListXML{
    my $ref7=shift;
    return
        SOAP::Data->name('listLatLon')->value($$ref7{listLatLon})
            ->prefix('')->type(''),
        SOAP::Data->name('product')->value($$ref7{product})
            ->prefix('')->type(''),
        SOAP::Data->name('startTime')->value($$ref7{startTime})
            ->prefix('')->type(''),
        SOAP::Data->name('endTime')->value($$ref7{endTime})
            ->prefix('')->type(''),
        SOAP::Data->name('Unit')->value($$ref7{Unit})
            ->prefix('')->type('');
}
1;
__END__