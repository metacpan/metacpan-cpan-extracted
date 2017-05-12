#!/home/acme/perl-5.10.0/bin/perl
use strict;
use warnings;
use lib 'lib';
use DateTime::Format::ISO8601;
use DateTime::SpanSet;
use JSON::XS::VersionOneAndTwo;
use Lingua::EN::Numbers qw(num2en);
use List::Util qw(first);
use Net::MythWeb;
use Perl6::Say;
use WWW::Mechanize;

my $mythweb = Net::MythWeb->new( hostname => 'owl.local', port => 80 );

my %channels;
foreach my $channel ( $mythweb->channels ) {
    $channels{ $channel->name } = $channel;
}

my $mech = WWW::Mechanize->new;
$mech->default_header( 'Accept-Language' => 'en' );

$mech->get('http://www.mightyv.com/feed/schedule/acme/json');
my $json_response = $mech->response;
die $json_response->status_line unless $json_response->is_success;
my @events = @{ from_json( $json_response->decoded_content ) };
foreach my $event (@events) {
    my $start = DateTime::Format::ISO8601->parse_datetime( $event->{start} )
        ->set_time_zone('Europe/London')->set_time_zone('UTC');
    my $stop
        = DateTime::Format::ISO8601->parse_datetime( $event->{stop} )
        ->set_time_zone('Europe/London')->set_time_zone('UTC')
        ->subtract( seconds => 1 );

    my $start_epoch      = $start->epoch;
    my $channel_name     = $event->{name};
    my $matching_channel = first {
        my $a = lc $channel_name;
        $a =~ s/ //g;
        $a =~ s/(\d+)/num2en($1)/e;
        my $b = lc $_;
        $b =~ s/ //g;
        $b =~ s/(\d+)/num2en($1)/e;
        $a eq $b;
    }
    keys %channels;
    my $channel = $channels{$matching_channel};
    die "No channel found for $channel_name" unless $channel;
    my $programme = $mythweb->programme( $channel, $start );
    $event->{programme} = $programme;
    $event->{start_dt}  = $start;
    $event->{stop_dt}   = $stop;
}

my $spanset = DateTime::SpanSet->from_spans( spans => [] );

foreach my $event (@events) {
    my $url   = $event->{url};
    my $start = $event->{start_dt};
    my $stop  = $event->{stop_dt};
    my $span  = DateTime::Span->from_datetimes(
        start => $start,
        end   => $stop,
    );
    if ( $spanset->intersects($span) ) {
        say "clash!";
        next;
    } else {
        $spanset = $spanset->union($span);
        $event->{span} = $span;
    }
}

foreach my $event (@events) {
    my $url       = $event->{url};
    my $start     = $event->{start_dt};
    my $stop      = $event->{stop_dt};
    my $span      = $event->{span};
    my $title     = $event->{title};
    my $programme = $event->{programme};

    $spanset = $spanset->complement($span);

    my $final_span
        = first { !$spanset->intersects($_) } DateTime::Span->from_datetimes(
        start => $start->clone->subtract( minutes => 5 ),
        end   => $stop->clone->add( minutes       => 5 )
        ),
        DateTime::Span->from_datetimes(
        start => $start->clone->subtract( minutes => 5 ),
        end   => $stop
        ),
        DateTime::Span->from_datetimes(
        start => $start,
        end   => $stop->clone->add( minutes => 5 )
        ), $span;

    $spanset = $spanset->union($final_span);

    my $start_extra = ( $final_span->start - $span->start )->minutes;
    my $stop_extra  = ( $final_span->end - $span->end )->minutes;

    say "$title "
        . $final_span->start . ' -> '
        . $final_span->end
        . " ($start_extra, $stop_extra)";
    $programme->record( "$start_extra", "$stop_extra" );
}
