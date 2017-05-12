#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use Protocol::Notifo;

my $n;
lives_ok
  sub { $n = Protocol::Notifo->new(user => 'me', api_key => 'my_key') },
  'new() survived with a prodigal object';
ok(defined($n), '... which, by the way, looks defined');

my %common = (
  method => "POST",
  url => all(isa('URI'), str('https://api.notifo.com/v1/send_notification')),
);


### send_notification
my @test_cases = (
  [ 'just msg',
    [msg => 'hello friend'],
    { headers => bag(
        Authorization    => "Basic bWU6bXlfa2V5",
        'Content-Type'   => 'application/x-www-form-urlencoded',
        'Content-Length' => 16,
      ),
      body => 'msg=hello+friend',
    },
  ],

  [ 'msg and to',
    [msg => 'hello', to => 'to'],
    { headers => bag(
        Authorization    => "Basic bWU6bXlfa2V5",
        'Content-Type'   => 'application/x-www-form-urlencoded',
        'Content-Length' => 15,
      ),
      body => all(re(qr/msg=hello/), re(qr/to=to/)),
    },
  ],

  [ 'msg, to, and label',
    [msg => 'hello', to => 'to', label => 'l'],
    { headers => bag(
        Authorization    => "Basic bWU6bXlfa2V5",
        'Content-Type'   => 'application/x-www-form-urlencoded',
        'Content-Length' => 23,
      ),
      body => all(re(qr/msg=hello/), re(qr/to=to/), re(qr/label=l/)),
    },
  ],

  [ 'msg, to, label, and title',
    [msg => 'hello', to => 'to', label => 'l', title => 't'],
    { headers => bag(
        Authorization    => "Basic bWU6bXlfa2V5",
        'Content-Type'   => 'application/x-www-form-urlencoded',
        'Content-Length' => 31,
      ),
      body => all(
        re(qr/msg=hello/), re(qr/to=to/), re(qr/label=l/), re(qr/title=t/)
      ),
    },
  ],

  [ 'all arguments',
    [msg => 'hello', to => 'to', label => 'l', title => 't', uri => 'u'],
    { headers => bag(
        Authorization    => "Basic bWU6bXlfa2V5",
        'Content-Type'   => 'application/x-www-form-urlencoded',
        'Content-Length' => 37,
      ),
      body => all(
        re(qr/msg=hello/), re(qr/to=to/),
        re(qr/label=l/),   re(qr/title=t/),
        re(qr/uri=u/)
      ),
    },
  ],

  [ 'undef arg',
    [msg => 'hello friend', to => undef],
    { headers => bag(
        Authorization    => "Basic bWU6bXlfa2V5",
        'Content-Type'   => 'application/x-www-form-urlencoded',
        'Content-Length' => 16,
      ),
      body => 'msg=hello+friend',
    },
    [msg => 'hello friend'],
  ],
);

my $sn;
for my $tc (@test_cases) {
  my ($name, $in, $info, $out) = @$tc;
  $out = $in unless $out;

  lives_ok sub { $sn = $n->send_notification(@$in) },
    "send_notification() survived ($name)";
  cmp_deeply(
    $sn,
    {%common, %$info, args => {@$out}},
    '... with the expected result'
  );
}


### bad boys
throws_ok sub { $n->send_notification() }, qr//, "Missing 'msg' parameter";


### thats all folks
done_testing();
