use strict;
use warnings;
use Test::More;
use Test::LWP::UserAgent;
use HTTP::Response;
use DateTime;

use Net::Songkick;

my $date = DateTime->now->add(days => 7)->ymd('-');

my $artist_json = '{
        "uri":"http://www.songkick.com/artists/29835-wild-flag?utm_source=PARTNER_ID&utm_medium=partner",
        "displayName":"Wild Flag",
        "id":29835,
        "identifier":[ { "mbid": "a74b1b7f-71a5-4011-9441-d0b5e4122711", "href": "http://blah.com"}]
    }';

my $event_json = qq[{
  "id":11129128,
  "type":"Concert",
  "uri":"http://www.songkick.com/concerts/11129128-wild-flag-at-fillmore?utm_source=PARTNER_ID&utm_medium=partner",
  "displayName":"Wild Flag at The Fillmore (April 18, 2012)",
  "start": {
    "time":"20:00:00",
    "date":"$date",
    "datetime":"${date}T20:00:00-0800"
  },
  "performance": [{
    "artist": $artist_json,
    "id":21579303,
    "displayName":"Wild Flag",
    "billingIndex":1,
    "billing":"headline"
  }],
  "location": {
    "city":"San Francisco, CA, US",
    "lng":-122.4332937,
    "lat":37.7842398
  },
  "venue": {
    "id":6239,
    "displayName":"The Fillmore",
    "uri":"http://www.songkick.com/venues/6239-fillmore?utm_source=PARTNER_ID&utm_medium=partner",
    "lng":-122.4332937,
    "lat":37.7842398,
    "metroArea": {
      "uri":"http://www.songkick.com/metro_areas/26330-us-sf-bay-area?utm_source=PARTNER_ID&utm_medium=partner",
      "displayName":"SF Bay Area",
      "country": { "displayName":"US" },
      "id":26330,
      "state": { "displayName":"CA" }
    }
  },
  "status":"ok",
  "popularity":0.012763
}];

my $ua = Test::LWP::UserAgent->new;

$ua->map_response(
  qr{/users} => HTTP::Response->new(
    200, 'OK', ['Content-Type' => 'application/json' ], qq[{
    "resultsPage": {
      "results": {
        "calendarEntry": [
          {
            "reason": {
              "trackedArtist": [ $artist_json ],
              "attendance": "i_might_go|im_going"
            },
            "event": $event_json
          }
        ]
      }
    },
    "status": "ok",
    "page": 1,
    "totalEntries": 1,
    "perPage": 50
  }])
);
$ua->map_response(
  qr{/events} => HTTP::Response->new(
    200, 'OK', ['Content-Type' => 'application/json' ], qq[{
  "resultsPage": {
    "page": 1,
    "totalEntries": 2,
    "perPage": 50,
    "results": {
      "event": [$event_json]
    }
  }
}],
  ),
);

$ua->map_response(
  qr{/users/.+/gigography} => HTTP::Response->new(
    200, 'OK', ['Content-Type' => 'application/json' ], qq[{
  "resultsPage": {
    "status": "ok",
    "results": {
      "event": [
        {
          "type": "Concert",
          "status": "ok",
          "ageRestriction": null,
          "start": {
            "time": null,
            "datetime": null,
            "date": "1976-07-30"
          },
          "performance": [
            {
              "artist": {
                "identifier": [
                  {
                    "href": "http://api.songkick.com/api/3.0/artists/mbid:0561d857-1d15-4ca1-93ec-ff6036c6e1a2.json",
                    "mbid": "0561d857-1d15-4ca1-93ec-ff6036c6e1a2"
                  }
                ],
                "uri": "http://www.songkick.com/artists/120463-showaddywaddy?utm_source=1666&utm_medium=partner",
                "id": 120463,
                "displayName": "Showaddywaddy"
              },
              "id": 3884986,
              "billingIndex": 1,
              "billing": "headline",
              "displayName": "Showaddywaddy"
            }
          ],
          "venue": {
            "metroArea": {
              "uri": "http://www.songkick.com/metro_areas/24495-uk-leeds?utm_source=1666&utm_medium=partner",
              "id": 24495,
              "country": {
                "displayName": "UK"
              },
              "displayName": "Leeds"
            },
            "lat": 54.0022992,
            "lng": -1.5480721,
            "uri": "http://www.songkick.com/venues/33397-royal-hall?utm_source=1666&utm_medium=partner",
            "id": 33397,
            "displayName": "Royal Hall"
          },
          "location": {
            "city": "Harrogate, UK",
            "lat": 54.0022992,
            "lng": -1.5480721
          },
          "uri": "http://www.songkick.com/concerts/2399921-showaddywaddy-at-royal-hall?utm_source=1666&utm_medium=partner",
          "id": 2399921,
          "displayName": "Showaddywaddy at Royal Hall (July 30, 1976)",
          "popularity": 0.00367
        },
        {
          "type": "Concert",
          "popularity": 0.008877,
          "status": "ok",
          "displayName": "After the Fire at St Osyth's College (February 18, 1978)",
          "start": {
            "time": null,
            "date": "1978-02-18",
            "datetime": null
          },
          "ageRestriction": null,
          "location": {
            "city": "Clacton, UK",
            "lat": 51.789534,
            "lng": 1.153035
          },
          "uri": "http://www.songkick.com/concerts/2399836-after-the-fire-at-st-osyths-college?utm_source=1666&utm_medium=partner",
          "id": 2399836,
          "performance": [
            {
              "billingIndex": 1,
              "displayName": "After the Fire",
              "billing": "headline",
              "id": 3884696,
              "artist": {
                "displayName": "After the Fire",
                "identifier": [
                  {
                    "mbid": "3edac1c5-19cd-4cd4-bd7c-bf38d0efdcd8",
                    "href": "http://api.songkick.com/api/3.0/artists/mbid:3edac1c5-19cd-4cd4-bd7c-bf38d0efdcd8.json"
                  }
                ],
                "uri": "http://www.songkick.com/artists/463746-after-the-fire?utm_source=1666&utm_medium=partner",
                "id": 463746
              }
            }
          ],
          "venue": {
            "metroArea": {
              "displayName": "Colchester",
              "country": {
                "displayName": "UK"
              },
              "uri": "http://www.songkick.com/metro_areas/24604-uk-colchester?utm_source=1666&utm_medium=partner",
              "id": 24604
            },
            "displayName": "St Osyth's College",
            "lat": 51.789534,
            "lng": 1.153035,
            "uri": "http://www.songkick.com/venues/493306-st-osyths-college?utm_source=1666&utm_medium=partner",
            "id": 493306
          }
        },
        {
          "id": 2399726,
          "displayName": "Lindisfarne at Odeon (May 31, 1978)",
          "type": "Concert",
          "uri": "https://www.songkick.com/concerts/2399726-lindisfarne-at-odeon?utm_source=1666&utm_medium=partner",
          "status": "ok",
          "popularity": 0.003412,
          "start": {
            "date": "1978-05-31",
            "datetime": null,
            "time": null
          },
          "performance": [
            {
              "id": 75468572,
              "displayName": "Lindisfarne",
              "billing": "headline",
              "billingIndex": 1,
              "artist": {
                "id": 363886,
                "displayName": "Lindisfarne",
                "uri": "https://www.songkick.com/artists/363886-lindisfarne?utm_source=1666&utm_medium=partner",
                "identifier": [
                  {
                    "mbid": "c39c15bd-ed29-4feb-8aa6-22876a7d7bf1",
                    "href": "https://api.songkick.com/api/3.0/artists/mbid:c39c15bd-ed29-4feb-8aa6-22876a7d7bf1.json"
                  },
                  {
                    "mbid": "433931b5-3f1d-428b-bac0-3218627dc57b",
                    "href": "https://api.songkick.com/api/3.0/artists/mbid:433931b5-3f1d-428b-bac0-3218627dc57b.json"
                  }
                ]
              }
            }
          ],
          "ageRestriction": null,
          "flaggedAsEnded": true,
          "venue": {
            "id": 58446,
            "displayName": "Odeon",
            "uri": "https://www.songkick.com/venues/58446-odeon?utm_source=1666&utm_medium=partner",
            "metroArea": {
              "displayName": "Chelmsford",
              "country": {
                "displayName": "UK"
              },
              "id": 24602,
              "uri": "https://www.songkick.com/metro-areas/24602-uk-chelmsford?utm_source=1666&utm_medium=partner"
            },
            "lat": null,
            "lng": null
          },
          "location": {
            "city": "Chelmsford, UK",
            "lat": 51.7333,
            "lng": 0.48333
          }
        }
      ]
    },
    "perPage": 3,
    "page": 1,
    "totalEntries": 527
  }
}],
  )
);

my $ns = Net::Songkick->new({
    api_key => 'dummy',
    ua      => $ua,
});

ok(my $events = $ns->get_events({ venue_id => 6239 }));

isa_ok($events, ref []);
is(@$events, 1, 'Array has one element');
isa_ok($events->[0], 'Net::Songkick::Event');

my $event = $events->[0];

isa_ok($event->location,'Net::Songkick::Location');
isa_ok($event->performance, ref []);
isa_ok($event->performance->[0], 'Net::Songkick::Performance');
isa_ok($event->performance->[0]->artist, 'Net::Songkick::Artist');
isa_ok($event->performance->[0]->artist->identifier->[0], 'Net::Songkick::MusicBrainz');
isa_ok($event->venue, 'Net::Songkick::Venue');
isa_ok($event->venue->metroArea, 'Net::Songkick::MetroArea');

ok($events = $ns->get_upcoming_events({ user => 'foo' }));

ok($events = $ns->get_past_events({ user => 'foo' }));

done_testing;
