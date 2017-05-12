#!/usr/bin/perl -w

=head1 NAME

example-googleearth.cgi - Net::GPSD plus Geo::GoogleEarth::Document Example

=cut

use strict;
use CGI;
use Net::GPSD;
use Geo::GoogleEarth::Document;

my $cgi=CGI->new();
my $gpsd=Net::GPSD->new(host=>'127.0.0.1');
my $document=Geo::GoogleEarth::Document->new(name=>"Net::GPSD Version: ". $gpsd->VERSION);

my @host=$cgi->param('host');
push @host, '127.0.0.1' unless scalar(@host); #e.g. gpsd.mainframe.cx
foreach my $host (@host) {
  $gpsd->{'host'} = $host;
  my $point=$gpsd->get();
  my $html=$cgi->html(
             $cgi->table(
               $cgi->Tr([
                 $cgi->td([tag      =>$point->tag       ]),
                 $cgi->td([fix      =>$point->fix       ]),
                 $cgi->td([status   =>$point->status    ]),
                 $cgi->td([lat      =>$point->lat       ]),
                 $cgi->td([lon      =>$point->lon       ]),
                 $cgi->td([alt      =>$point->alt       ]),
                 $cgi->td([datetime =>$point->datetime  ]),
                 $cgi->td([time     =>$point->time      ]),
                 $cgi->td([mode     =>$point->mode      ]),
                 $cgi->td([speed    =>$point->speed     ]),
                 $cgi->td([heading  =>$point->heading   ]),
               ])
             ),
           );

  $document->Placemark(name        => "Host: $host",
                       description => $html,
                       lat         => $point->lat,
                       lon         => $point->lon,
                       alt         => $point->alt);
}

print $cgi->header('text/xml'),
      $document->render;
