# If we post a doc with an attachment and try to get the attachment back,
# it should be decoded from what we sent in and not JSON.  There's a test for
# this because it wasn't doing that in 0.04.  Test as you go?

BEGIN {push(@INC, 't/lib')}
use POE qw(
  Component::Client::CouchDB
  Component::Client::REST::Test::HTTP
);
use MIME::Base64;
use HTTP::Response;
use JSON;
use Test::More tests => 1;

my $attachment = <<'ATTACH';
Lorem ipsum dolor sit amet.

Lots of newlines and such.

eoaru239p874 (#($*&@(#&$(*@!&$(*&@$(*#&$(@!$(!*@$&(#&$&$(!$@&

That is SUPPOSED to look like gibberish.
ATTACH

my $doc = {
  foo => "bar",
  baz => 1,
  _id => 'gobba',
  _attachments => {
    body => {
      type => 'base64',
      data => encode_base64($attachment, q()),
    }
  },
};

my $body = q();
my $fake = POE::Component::Client::REST::Test::HTTP->new(
  responses => [
    qr{^/foobar/gobba$} => sub {
      my $request = $_[0];
      if ($request->method eq 'PUT') {
        my $foo = decode_json($request->content);
        $body = decode_base64($foo->{_attachments}->{body}->{data});

        my $answer = encode_json({
          ok => JSON::true, 
          id => 'gobba', 
          rev => '946B7D1C'
        });

        my $res = HTTP::Response->new(200);
        $res->content($answer);
        $res->content_length(bytes::length($answer));
        $res->header('Content-Type' => 'application/json');
        return $res;
      }
      else {
        die "Unhandled.";
      }
    },
    qr{^/foobar/gobba/body$} => sub {
      my $res = HTTP::Response->new(200);
      $res->content($body);
      $res->content_length(bytes::length($body));
      return $res;
    },
  ],
);

sub _start {
  $couch = POE::Component::Client::CouchDB->new;
  $fake->replace($couch->rest);

  $db = $couch->db('foobar');
  $db->create_named('gobba', $doc, callback => sub {
    my $data = $_[0];
    $db->attachment($data->{id}, 'body', callback => sub {
      my $res = $_[0];
      is($res->content, $attachment);
      $couch->shutdown();
    });
  });
}

POE::Session->create(package_states => [main => [qw(_start)]]);

$poe_kernel->run();
