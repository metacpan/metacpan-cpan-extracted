use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  plugin ical => {properties => {x_wr_caldesc => "My awesome calendar"}};
  get '/calendar' => sub {
    my $c    = shift;
    my $ical = {
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
      ]
    };
    $c->respond_to(ical => {handler => 'ical', ical => $ical}, json => {json => $ical});
  };
}

my $t = Test::Mojo->new;

$t->get_ok('/calendar.json')->status_is(200)->header_like('Content-Type', qr{^application/json})
  ->json_is('/events/0/description', 'Cool description');

$t->get_ok('/calendar.ical')->status_is(200)->header_is('Content-Type', 'text/calendar');
$t->content_like(qr{^BEGIN:VCALENDAR.*END:VCALENDAR$}s);
$t->content_like(qr{BEGIN:VEVENT.*END:VEVENT}s);
$t->content_like(qr{^UID:78bab94a3c04bc713b86914ac8acaeb8\@.}m);

done_testing;
