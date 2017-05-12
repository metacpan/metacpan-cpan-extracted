use strict;
use warnings;
use Test::More tests => 7;

our $QUERY;
our $REPLY;

{
  package Test::Fingerd;
  use base 'Net::Finger::Server';
  sub _read_input_line { return $QUERY };
  sub _reply { $REPLY = $_[1] };
  sub forward_reply {
    my ($self, $arg) = @_;
    return "$arg->{username} at " . join(q{, }, @{ $arg->{hosts} }) . "\n";
  }
}

sub finger {
  $QUERY = shift;
  Test::Fingerd->process_request;
  my $reply = $REPLY;
  undef $QUERY;
  undef $REPLY;
  return $reply;
}

like(
  finger("\n"),
  qr{listing},
  "finger for user listing",
);

like(
  finger("rjbs\n"),
  qr{alleged user <rjbs>},
  "finger for local user rjbs",
);

my $u_regex = Test::Fingerd->username_regex;
my $h_regex = Test::Fingerd->hostname_regex;

like(
  'example.com',
  $h_regex,
  'our host regex is not totally fail',
);

like(
  'rjbs',
  $u_regex,
  'our user regex is not totally fail',
);

like(
  "rjbs\@example.org\@example.com",
  qr/\A($u_regex)?((?:\@$h_regex)+)\z/,
  "our {Q2} regex is also sane-ish",
);

is(
  finger("rjbs\@example.org\@example.com\n"),
  "rjbs at example.org, example.com\n",
  'finger rjbs@example.org@example.com',
);

like(
  finger("this is garbage"),
  qr{could not understand},
  'unknown request rejected',
);
