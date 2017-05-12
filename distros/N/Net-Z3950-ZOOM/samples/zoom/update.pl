#!/usr/bin/perl -w

use strict;
use warnings;
use ZOOM;

my $options = new ZOOM::Options();
$options->option(user => "admin");
$options->option(password => "fish");
my $conn = create ZOOM::Connection($options);
$conn->connect("test.indexdata.com:2118");
print "connected\n";

my $dbname = "mike$$";
$conn->option(databaseName => $dbname);

send_package($conn, "create", databaseName => $dbname);
print "$0: created database '$dbname'\n";

my $rs = $conn->search_pqf("mineral");
my $n = $rs->size($rs);
print "$0: found $n records\n";

send_package($conn, "update", action => "specialUpdate",
	     recordIdOpaque => 1, record => join("", <DATA>));
print "$0: added record\n";

$rs = $conn->search_pqf("mineral");
$n = $rs->size($rs);
print "$0: found $n records\n";

send_package($conn, "drop", databaseName => $dbname);
print "$0: deleted database\n";

eval {
    $rs = $conn->search_pqf("mineral");
}; if (!$@) {
    print "$0: uh-oh\n";
} elsif ($@->isa("ZOOM::Exception")) {
    print "$0: database no longer there\n";
} else {
    die "@='$@'";
}


sub send_package {
    my($conn, $op, %options) = @_;

    my $p = $conn->package();
    foreach my $key (keys %options) {
	$p->option($key, $options{$key});
    }
    $p->send($op);
    $p->destroy();
}


__DATA__
<gils>
  <Title>
    UTAH EARTHQUAKE EPICENTERS
    <Acronym>UUCCSEIS</Acronym>
  </Title>
  <Originator>UTAH GEOLOGICAL AND MINERAL SURVEY</Originator>
  <Local-Subject-Index>
    APPALACHIAN VALLEY; EARTHQUAKE; EPICENTER; SEISMOLOGY; UTAH
  </Local-Subject-Index>
  <Abstract>
    Five files of epicenter data arranged by date comprise this data
    set.  These files are searchable by magnitude and
    longitude/latitude.  Hardcopy of listing and plot of requested
    area available.  Epicenter location and date, magnitude, and focal
    depth available.
    <Format>DIGITAL DATA SETS</Format>
    <Data-Category>TERRESTRIAL</Data-Category>
    <Comments>
      Data are supplied by the University of Utah Seismograph
      Station. The Utah Geologcial and Mineral Survey (UGMS) is merely
      a clearinghouse of the data.
    </Comments>
  </Abstract>
  <Spatial-Domain>
    <Geographic-Coverage>US STATE</Geographic-Coverage>
    <Coverage-Description>UTAH</Coverage-Description>
    <Bounding-Coordinates>
      <West-Bounding-Coordinate>-114</West-Bounding-Coordinate>
      <East-Bounding-Coordinate>-109</East-Bounding-Coordinate>
      <North-Bounding-Coordinate>42</North-Bounding-Coordinate>
      <South-Bounding-Coordinate>37</South-Bounding-Coordinate>
    </Bounding-Coordinates>
  </Spatial-Domain>
  <Time-Period>
    <Time-Period-Textual>-PRESENT</Time-Period-Textual>
  </Time-Period>
  <Availability>
    <Distributor>
      <Organization>UTAH GEOLOGICAL AND MINERAL SURVEY</Organization>
      <Street-Address>606 BLACK HAWK WAY</Street-Address>
      <City>SALT LAKE CITY</City>
      <State>UT</State>
      <Zip-Code>84108</Zip-Code>
      <Country>USA</Country>
      <Telephone>(801) 581-6831</Telephone>
    </Distributor>
    <Resource-Description>UTAH EARTHQUAKE EPICENTERS</Resource-Description>
    <Technical-Prerequisites>
      <Data-Set-Type>AUTOMATED</Data-Set-Type>
      <Access-Method>BATCH</Access-Method>
      <Number-of-Records>8,700</Number-of-Records>
      <Computer-Type>PC NETWORK</Computer-Type>
      <Computer-Location>SALT LAKE CITY, UT</Computer-Location>
    </Technical-Prerequisites>
  </Availability>
  <Access-Constraints>
    <Documentation>NONE</Documentation>
  </Access-Constraints>
  <Use-Constraints>
    <Status>OPERATIONAL</Status>
  </Use-Constraints>
  <Point-of-Contact>
    <Name>BILL CASE</Name>
    <Organization>UTAH GEOLOGICAL AND MINERAL SURVEY</Organization>
    <Street-Address>606 BLACK HAWK WAY</Street-Address>
    <City>SALT LAKE CITY</City>
    <State>UT</State>
    <Zip-Code>84108</Zip-Code>
    <Country>USA</Country>
    <Telephone>(801) 581-6831</Telephone>
  </Point-of-Contact>
  <Control-Identifier>ESDD0006</Control-Identifier>
  <Record-Source>UTAH GEOLOGICAL AND MINERAL SURVEY</Record-Source>
  <Date-of-Last-Modification>198903</Date-of-Last-Modification>
</gils>
