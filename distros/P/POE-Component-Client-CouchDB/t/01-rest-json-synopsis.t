BEGIN {push(@INC, 't/lib')}
use Test::More tests => 1;
use POE::Component::Client::REST::Test::HTTP qw(json_responder);

my $tester = POE::Component::Client::REST::Test::HTTP->new(
  responses => [
    qr{^/_all_dbs$} => json_responder([qw(foo bar baz)]),
  ],
);

    use POE::Component::Client::REST::JSON;
    use POE;

    # simple CouchDB example

    POE::Session->create(inline_states => {
      _start => sub {
        $poe_kernel->alias_set('foo');

        my $rest = $_[HEAP]->{rest} = POE::Component::Client::REST::JSON->new;

$tester->replace($rest);

        $rest->call(GET => 'http://localhost:5984/_all_dbs', callback =>
          [$_[SESSION], 'response']);
      },

      response => sub {
        my ($data, $response) = @_[ARG0, ARG1];
        die $response->status_line unless $response->code == 200;

#       print 'Databases: ' . join(', ', @$data) . "\n";
        $poe_kernel->alias_remove('foo');
        $_[HEAP]->{rest}->shutdown();
ok($data->[0] eq 'foo' && $data->[1] eq 'bar' && $data->[2] eq 'baz',
  "Correct output");
      },
    });

    $poe_kernel->run();

