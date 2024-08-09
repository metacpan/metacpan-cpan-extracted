use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  plugin ical => {properties => {x_wr_caldesc => "My awesome calendar"}};
  get '/calendar' => sub {
    my $c = shift;
    $c->reply->ical({
      events => [
        {
          created     => Mojo::Date->new(1428247000),
          description => 'Cool description',
          dtend       => Mojo::Date->new(1428247000 + 86400),
          dtstart     => Mojo::Date->new(1428247000 + 600),
          location    => "Oslo",
          sequence    => 42,
          summary     => 'Cool event',
        },
      ],
    });
  };
}

my $t = Test::Mojo->new;

$t->get_ok('/calendar')->status_is(200)->header_is('Content-Type', 'text/calendar');

$t->content_like(qr{^BEGIN:VCALENDAR.*END:VCALENDAR$}s);
$t->content_like(qr{^CALSCALE:GREGORIAN}m);

{
  local $TODO = 'Not sure why, but this test fail with a long hostname';
  $t->content_like(qr{^PRODID:-//\w[^\/]+//NONSGML synopsis//EN}m);
}

$t->content_like(qr{^METHOD:PUBLISH}m);
$t->content_like(qr{^VERSION:2\.0}m);
$t->content_like(qr{^X-WR-CALDESC:My awesome calendar}m);
$t->content_like(qr{^X-WR-CALNAME:synopsis}m);
$t->content_like(qr{^X-WR-TIMEZONE:\w}m);

$t->content_like(qr{BEGIN:VEVENT.*END:VEVENT}s);
$t->content_like(qr{^CREATED:20150405T151640Z}m);
$t->content_like(qr{^DESCRIPTION:Cool description}m);
$t->content_like(qr{^DTEND:20150406T151640Z}m);
$t->content_like(qr{^DTSTAMP:\w+Z}m);
$t->content_like(qr{^DTSTART:20150405T152640Z}m);
$t->content_like(qr{^LOCATION:Oslo}m);
$t->content_like(qr{^SEQUENCE:42}m);
$t->content_like(qr{^STATUS:CONFIRMED}m);
$t->content_like(qr{^SUMMARY:Cool event}m);
$t->content_like(qr{^TRANSP:OPAQUE}m);
$t->content_like(qr{^UID:78bab94a3c04bc713b86914ac8acaeb8\@.}m);

done_testing;
