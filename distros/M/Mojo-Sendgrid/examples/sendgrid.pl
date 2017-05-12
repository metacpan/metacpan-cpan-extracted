use 5.010;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Mojo::Sendgrid;

my $sendgrid = Mojo::Sendgrid->new(
  config => {
    #apikey => 'get your key from api.sendgrid.com',
  },
);

$sendgrid->on(mail_send => sub {
  my ($sendgrid, $ua, $tx) = @_;
  say $tx->res->body;
});

say $sendgrid->mail(
  to      => $ARGV[0],
  from    => $ARGV[1],
  subject => time,
  text    => time
)->send;

Mojo::IOLoop->start;
