#!/usr/bin/perl

=head1 NAME

position_report.cgi - Adds position report to tracking database via http

=cut

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
my $query = new CGI;

my $dbname="gis";
my $dbuser=undef; #"apache";
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", $dbuser, "")
           or die($DBI::errstr);
my $sth='';

my $device=$query->param('device');
my $lat=$query->param('lat');
my $lon=$query->param('lon');
my $dtg=$query->param('dtg');
my $speed=$query->param('speed');
my $heading=$query->param('heading');

if ($device and $lat and $lon) {
  if ($dtg) {
    if ($speed and $heading) {
      $sth=$dbh->prepare("
        INSERT INTO tracking (device,lat,lon,dtg,speed,heading)
        VALUES (?,?,?,?,?,?);
      ");
      $sth->execute($device, $lat, $lon, $dtg, $speed, $heading) 
              or die($DBI::errstr);
      print $query->header(q{text/plain}), qq{Success!\n};
    } else {
      $sth=$dbh->prepare("
        INSERT INTO tracking (device,lat,lon,dtg)
        VALUES (?,?,?,?);
      ");
      $sth->execute($device, $lat, $lon, $dtg) or die($DBI::errstr);
      print $query->header(q{text/plain}), qq{Success!\n no velocity.\n};
    }
  } else {
    $sth=$dbh->prepare("
      INSERT INTO tracking (device,lat,lon)
      VALUES (?,?,?);
    ");
    $sth->execute($device, $lat, $lon) or die($DBI::errstr);
    print $query->header(q{text/plain}), qq{Success!\n using current time.\n};
  }
  $sth->finish or die($DBI::errstr);
} else {
  print $query->header(q{text/html}),
        qq{Error: device, lat, lon required.\n\n},
        $query->p("Usage: ",
                  $query->script_name(),
                  '?device=',
                  $query->i("int"),
                  '&lat=',
                  $query->i('dd.ddd'),
                  '&lon=',
                  $query->i('ddd.ddd'),
                  $query->b('['),
                  '&dtg=',
                  $query->i('yyyy-mm-dd 24:mm:ss.sss'),
                  $query->b('['),
                  '&speed=',
                  $query->i('m/s'),
                  '&heading=',
                  $query->i('degrees'),
                  $query->b(']]')
                );
}
$dbh->disconnect() or die($DBI::errstr);

__END__
