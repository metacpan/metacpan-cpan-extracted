
# Mojo::Sendgrid

  An implementation of the Sendgrid Web API v2 for the Mojolicious framework.

```perl
use 5.010;

use Mojo::Sendgrid;

my $sendgrid = Mojo::Sendgrid->new;
my $send = $sendgrid->mail(to=>q(x@y.com),from=>q(x@y.com),subject=>time,text=>time)->send;

$sendgrid->on(mail_send => sub {
  my ($sendgrid, $ua, $tx) = @_;
  say $tx->res->body;
});

Mojo::IOLoop->recurring(0.25 => sub {print'.'});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
```

## Installation

  All you need is a one-liner, it takes less than a minute.

    $ curl -L http://cpanmin.us | perl - https://github.com/s1037989/Mojo-Sendgrid/archive/master.tar.gz

  We recommend the use of a [Perlbrew](http://perlbrew.pl) environment.

## Want to know more?

  Take a look at our excellent [documentation](http://mojolicious.org/perldoc>)!
