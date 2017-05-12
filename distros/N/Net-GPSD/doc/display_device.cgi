#!/usr/bin/perl

=head1 NAME

display_device.cgi - Display tracking data from tracking database

=cut

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

#This key is good for all URLs in this directory: http://localhost/
my $googlekey='ABQIAAAAlToaDcu4F2r77c0w1h_ZOhT2yXp_ZAY8_ufC3CFXhHIE1NvwkxRyIIIPjGds4QvqilphZic8BRt33A';

my $query = new CGI;

my $dbname="gis";
my $dbuser=undef; #"apache";
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", $dbuser, "")
           or die($DBI::errstr);
my $sth='';

unless ($query->param('device')) {
  $query->param(-name=>'device', -value=>getlastdevice($dbh) || 1);
}

my $device=int($query->param('device'));
my $limit=int($query->param('limit') || 10);

$sth=$dbh->prepare("SELECT id,device,lat,lon,dtg,speed,heading
                    FROM tracking
                    WHERE device=?
                    ORDER BY dtg
                    DESC LIMIT ?;");
$sth->execute($device, $limit) or die($DBI::errstr);
my $data=$sth->fetchall_arrayref({});#[{},{},...]
my $trackcount=scalar(@$data);

$sth=$dbh->prepare("SELECT AVG(lat) as latavg, AVG(lon) as lonavg, MAX(lat) as latmax, MAX(lon) as lonmax, MIN(lat) as latmin, MIN(lon) as lonmin FROM tracking WHERE device=?;");
$sth->execute($device) or die($DBI::errstr);
my $devicestats=$sth->fetchall_arrayref({});#[{},{},...]
$devicestats=$devicestats->[0]; #{}
#print "latavg: ", $devicestats->{'latavg'}, "\n";
my $latavg=$devicestats->{'latavg'};
my $lonavg=$devicestats->{'lonavg'};
my $latmin=$devicestats->{'latmin'};
my $lonmin=$devicestats->{'lonmin'};
my $latmax=$devicestats->{'latmax'};
my $lonmax=$devicestats->{'lonmax'};

$sth=$dbh->prepare("SELECT device, count(*)
                    FROM tracking
                    GROUP BY device
                    ORDER BY device;");
$sth->execute() or die($DBI::errstr);
my $devicelist=$sth->fetchall_arrayref(); #[[],[],...]
my %devicecount=map {$_->[0]=>$_->[1]} @$devicelist;
$sth->finish;
$dbh->disconnect();

my $layer='';
my $icon='icon0';
my @table=([qw{id device lat lon dtg speed heading}]);

foreach (@$data) {
  my $id=$_->{'id'};
  my $device=$_->{'device'};
  my $lat=$_->{'lat'};
  my $lon=$_->{'lon'};
  my $dtg=$_->{'dtg'};
  my $speed=$_->{'speed'};
  my $heading=$_->{'heading'};

 #//createInfoText($lat,$lon,$device,$dtg,$speed,$heading)
  $layer.=
  qq{
    point = new GPoint($lon, $lat);
    points.push(point);
    html = "<p>ID: $id<br/>Device: $device<br/>Lat: $lat<br/>Lon: $lon<br/>DTG: $dtg</p>";
    marker = createMarker(point, $icon, html);
    map.addOverlay(marker);
  };
  push @table, [$id,$device,$lat,$lon,$dtg,$speed,$heading];
  $icon='icon1';
}
my $lat=$data->[0]->{'lat'};
my $lon=$data->[0]->{'lon'};
my $dtg=$data->[0]->{'dtg'};
my $speed=$data->[0]->{'speed'};
my $heading=$data->[0]->{'heading'};
my $device=$data->[0]->{'device'};
my $form=join "", 
         $query->start_form(-action=>$query->script_name()),
         "Device: ",
         $query->popup_menu(-name=>'device',
	                    -values=>[map {$_->[0]} @$devicelist]),
         $query->submit(-value=>"Go!"),
         $query->end_form();

unless (defined($data)) {
print $query->header(q{text/html}),
      $query->p("Error: database returned bad data.");
} else {
print $query->header(q{text/html}),
q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:v="urn:schemas-microsoft-com:vml">
  <head>},
qq{<script src="http://maps.google.com/maps?file=api&v=1&key=$googlekey" type="text/javascript"></script>
    <style type="text/css">v\:* {behavior:url(#default#VML);}</style>
  </head>
}, #end of q{}
qq{
  <body>
    <table>
      <tr>
        <td colspan="2">
          $form
        </td>
      </tr>
      <tr>
        <td valign="top">
          <div id="map" style="width: 480px; height: 360px"></div>
        </td>
        <td>
          <table>
            <tr>
              <td colspan="2">Current Track Properties</td>
            </tr>
            <tr>
              <td>Device</td><td><div id="track_device"></div></td>
            </tr>
            <tr>
              <td>Lat</td><td><div id="track_lat"></div></td>
            </tr>
            <tr>
              <td>Lon</td><td><div id="track_lon"></div></td>
            </tr>
            <tr>
              <td>DTG</td><td><div id="track_dtg"></div></td>
            </tr>
            <tr>
              <td>Speed</td><td><div id="track_speed"></div></td>
            </tr>
            <tr>
              <td>Heading</td><td><div id="track_heading"></div></td>
            </tr>
            <tr>
              <td>Lat Average</td><td><div id="track_latavg"></div></td>
            </tr>
            <tr>
              <td>Lon Average</td><td><div id="track_lonavg"></div></td>
            </tr>
            <tr>
              <td>Lat Min</td><td><div id="track_latmin"></div></td>
            </tr>
            <tr>
              <td>Lon Min</td><td><div id="track_lonmin"></div></td>
            </tr>
            <tr>
              <td>Lat Max</td><td><div id="track_latmax"></div></td>
            </tr>
            <tr>
              <td>Lon Max</td><td><div id="track_lonmax"></div></td>
            </tr>
          </table>
          <table>
            <tr>
              <td colspan="2">Current Map Properties</td>
            </tr>
            <tr>
              <td>Lat</td><td><div id="lat"></div></td>
            </tr>
            <tr>
              <td>Lon</td><td><div id="lon"></div></td>
            </tr>
            <tr>
              <td>maxX</td><td><div id="maxX"></div></td>
            </tr>
            <tr>
              <td>maxY</td><td><div id="maxY"></div></td>
            </tr>
            <tr>
              <td>minX</td><td><div id="minX"></div></td>
            </tr>
            <tr>
              <td>minY</td><td><div id="minY"></div></td>
            </tr>
          </table>
        </td>
      </tr>
   </table>
    <script type="text/javascript">
    //<![CDATA[
    
    var map = new GMap(document.getElementById("map"));
    GEvent.addListener(map, 'move',
      function() {
        var center = map.getCenterLatLng();
        document.getElementById("lat").innerHTML = center.y;
        document.getElementById("lon").innerHTML = center.x;
      }
    );
    GEvent.addListener(map, 'moveend',
      function(overlay) {
        var bounds = map.getBoundsLatLng();
        var center = map.getCenterLatLng();
        document.getElementById("maxX").innerHTML = bounds.maxX;
        document.getElementById("maxY").innerHTML = bounds.maxY;
        document.getElementById("minX").innerHTML = bounds.minX;
        document.getElementById("minY").innerHTML = bounds.minY;
      }
    );
    map.addControl(new GLargeMapControl());
    map.addControl(new GMapTypeControl());
    map.centerAndZoom(new GPoint($lon, $lat), 2);

    function createMarker(point, icon, html) {
      var marker = new GMarker(point, icon);
      GEvent.addListener(marker, 'click', function() {
        marker.openInfoWindowHtml(html);
      });
      return marker;
    }

    var icon0 = new GIcon();
    icon0.image = "http://www.google.com/mapfiles/marker.png";
    icon0.shadow = "http://www.google.com/mapfiles/shadow50.png";
    icon0.iconSize = new GSize(20, 34);
    icon0.shadowSize = new GSize(37, 34);
    icon0.iconAnchor = new GPoint(9, 34);
    icon0.infoWindowAnchor = new GPoint(9, 2);

    var icon1 = new GIcon();
    icon1.image = "http://maps.davisnetworks.com/google/icons/blue-dot-5.png";
    icon1.iconSize = new GSize(5, 5);
    icon1.iconAnchor = new GPoint(3, 3);
    icon1.infoWindowAnchor = new GPoint(3, 1);

    var points = [];
    var marker;
    var point;
    var html;

    $layer
    map.addOverlay(new GPolyline(points));

    document.getElementById("track_lat").innerHTML = "$lat";
    document.getElementById("track_lon").innerHTML = "$lon";
    document.getElementById("track_device").innerHTML = "$device";
    document.getElementById("track_dtg").innerHTML = "$dtg";
    document.getElementById("track_speed").innerHTML = "$speed";
    document.getElementById("track_heading").innerHTML = "$heading";
    document.getElementById("track_latavg").innerHTML = "$latavg";
    document.getElementById("track_lonavg").innerHTML = "$lonavg";
    document.getElementById("track_latmin").innerHTML = "$latmin";
    document.getElementById("track_lonmin").innerHTML = "$lonmin";
    document.getElementById("track_latmax").innerHTML = "$latmax";
    document.getElementById("track_lonmax").innerHTML = "$lonmax";

    //]]>
    </script>},
    $query->p({-align=>"center"}, "Track history for device $device"),
    $query->p({-align=>"center"}, "(Last $trackcount records of", $devicecount{$device}, "reports)"),
    $query->table({-border=>1, -width=>"100%"},
      $query->Tr([map {$query->td($_)} @table])
    ),
qq{
  </body>
</html>
}; #qq
} #if/unless

sub getlastdevice {
  my $dbh=shift();
  $sth=$dbh->prepare("SELECT device FROM tracking ORDER BY dtg DESC LIMIT 1;");
  $sth->execute() or die($DBI::errstr);
  my $data=$sth->fetchall_arrayref();#[{},{},...]
  #print $data->[0]->[0], " ----------------------\n";
  return $data->[0]->[0];
}
