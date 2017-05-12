# $Id: SAXHandler.pm 1783 2005-01-09 05:44:52Z btrott $

package POE::Component::BlogCloud::SAXHandler;
use strict;
use base qw( XML::SAX::Base );

use DateTime;

sub start_element {
    my $h = shift;
    my($ref) = @_;
    my $key = $ref->{LocalName};
    if ($key eq 'weblogUpdates') {
        die "Unknown version number"
            unless $ref->{Attributes}{'{}version'}{Value} == 1;
    } elsif ($key eq 'weblog') {
        my %rec = map { $_ => $ref->{Attributes}{'{}' . $_}{Value} }
                  qw( name url rss ts service );
        my $update = POE::Component::BlogCloud::Update->new;
        $update->uri($rec{url});
        $update->name($rec{name});
        $update->feed_uri($rec{rss});
        $update->service($rec{service});
        if ($rec{ts}) {
            my($y, $mo, $d, $h, $m, $s) = $rec{ts} =~
                /^(\d{4})(\d{2})(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/;
            my $dt = DateTime->new(
                    year      => $y,
                    month     => $mo,
                    day       => $d,
                    hour      => $h,
                    minute    => $m,
                    second    => $s,
                    time_zone => 'UTC',
                );
            $update->updated_at($dt);
        }
        $h->{kernel}->yield(got_update => $update);
    }
}

1;
