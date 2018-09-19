use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Types::Standard -types;
use Net::Curl::Parallel;

# These methods take the following signatures (enforced by Types->Request)
# * HTTP::Request object
# * [method, uri, headers, content]
# * (method, uri, headers, content)
# ----> the following added to requests():
#   * [ method, uri, headers, content, die ]

use DDP;
my %interfaces_die = (
  add => 1,
  try => 0,
);
my %request_modalities = (
  'HTTP::Request' => [ HTTP::Request->new( GET => 'http://example.com/' ) ],
  'List' => [ GET => 'http://example.com/' ],
  'Arrayref' => [ [GET => 'http://example.com/'] ],
);

while (my ($method, $die) = each %interfaces_die) {
  subtest $method => sub {
    while (my ($mode, $args) = each %request_modalities) {
      subtest $mode => sub {
        my $f = Net::Curl::Parallel->new;
        my $r = $f->$method( @$args );

        cmp_ok $r, '==', 0, "$method() returns the index in requests()";
        my $req = $f->requests->[$r];
        my $expected_req = array {
          item string 'GET';
          item string 'http://example.com/';
          item array {
            item string 'Connection: keep-alive';
          };
          item U();
          item $die;
        };
        is $req, $expected_req, 'The internals are correct';
      };
    }
  };
}

subtest 'Add many' => sub {
  subtest 'wantarray' => sub {
    my $f = Net::Curl::Parallel->new;

    my @rv = $f->add(
      [ GET => 'http://example.com' ],
      [ GET => 'http://example.com' ],
    );

    is [@rv], [0,1], 'Returns a list properly';
  };

  subtest 'want arrayref' => sub {
    my $f = Net::Curl::Parallel->new;

    my $rv = $f->add(
      [ GET => 'http://example.com' ],
      [ GET => 'http://example.com' ],
    );

    is [$rv], [[0,1]], 'Returns an arrayref properly';
  };
};

subtest 'keep-alive' => sub {
  subtest 'keep-alive true, no header' => sub {
    my $f = Net::Curl::Parallel->new(
      keep_alive => 1,
    );

    my $rv = $f->add(
      [ GET => 'http://example.com' ],
    );
    my $req = $f->requests->[$rv];

    my $expected_headers = array {
      item string 'Connection: keep-alive';
    };

    is $req->[2], $expected_headers, 'NCP adds the keep-alive header';
  };

  subtest 'keep-alive true, with header' => sub {
    my $f = Net::Curl::Parallel->new(
      keep_alive => 1,
    );

    my $rv = $f->add(
      [ GET => 'http://example.com', [ 'Connection: close' ] ],
    );
    my $req = $f->requests->[$rv];

    my $expected_headers = array {
      item string 'Connection: close';
    };

    is $req->[2], $expected_headers, 'NCP preserves the connection header';
  };

  subtest 'keep-alive false, no header' => sub {
    my $f = Net::Curl::Parallel->new(
      keep_alive => 0,
    );

    my $rv = $f->add(
      [ GET => 'http://example.com' ],
    );
    my $req = $f->requests->[$rv];

    my $expected_headers = array {
    };

    is $req->[2], $expected_headers, 'NCP does not add the keep-alive header';
  };

  subtest 'keep-alive false, with header' => sub {
    my $f = Net::Curl::Parallel->new(
      keep_alive => 0,
    );

    my $rv = $f->add(
      [ GET => 'http://example.com', [ 'Connection: close' ] ],
    );
    my $req = $f->requests->[$rv];

    my $expected_headers = array {
      item string 'Connection: close';
    };

    is $req->[2], $expected_headers, 'NCP preserves the connection header';
  };
};

subtest 'POST' => sub {
  subtest 'without expect set' => sub {
    my $f = Net::Curl::Parallel->new(keep_alive => 0);

    my $rv = $f->add(
      [ POST => 'http://example.com' ],
    );
    my $req = $f->requests->[$rv];

    my $expected_headers = array {
      item string 'Expect:';
    };

    is $req->[2], $expected_headers, 'NCP adds the Expect header';
  };

  subtest 'with expect set' => sub {
    my $f = Net::Curl::Parallel->new(keep_alive => 0);

    my $rv = $f->add(
      [ POST => 'http://example.com', [ 'Expect: whatever' ] ],
    );
    my $req = $f->requests->[$rv];

    my $expected_headers = array {
      item string 'Expect: whatever';
    };

    is $req->[2], $expected_headers, 'NCP preserves the Expect header';
  };
};

done_testing;
