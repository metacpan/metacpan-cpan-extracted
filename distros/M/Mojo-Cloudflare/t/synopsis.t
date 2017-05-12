use Mojo::Base -base;
use Test::More;
use Test::Mojo;
use Mojo::Cloudflare;

my @res = expected();
my($json, $req, $t);

{
  use Mojolicious::Lite;

  post '/api' => sub {
    my $self = shift;
    $req = $self->req->body_params;
    $self->render(json => shift @res);
  };

  $t = Test::Mojo->new;
}

{
  my $cf = Mojo::Cloudflare->new(
             email => 'sample@example.com',
             key => '8afbe6dea02407989af4dd4c97bb6e25',
             zone => 'example.com',
             api_url => '/api',
             _ua => $t->ua,
           );

  $req = undef;
  $json = $cf->records("all");

  is $req->param('z'), 'example.com', 'records: z';
  is $req->param('tkn'), '8afbe6dea02407989af4dd4c97bb6e25', 'records: tkn';
  is $req->param('email'), 'sample@example.com', 'records: email';
  is $req->param('a'), 'rec_load_all', 'records: a';
  is $req->param('o'), 0, 'records: o';
  is $json->get('/count'), 7, 'records: /count';

  $req = undef;
  $json = $cf->edit_record({
    id => $json->get('/objs/0/rec_id'),
    service_mode => 0,
    type => "A",
    name => "direct",
  });

  is $req->param('z'), 'example.com', 'edit_record: z';
  is $req->param('tkn'), '8afbe6dea02407989af4dd4c97bb6e25', 'edit_record: tkn';
  is $req->param('email'), 'sample@example.com', 'edit_record: email';
  is $req->param('a'), 'rec_edit', 'edit_record: a';
  is $req->param('id'), '16606009', 'edit_record: id';
  is $req->param('service_mode'), 0, 'edit_record: service_mode';
  is $req->param('type'), "A", 'edit_record: type';
  is $req->param('name'), "direct", 'edit_record: name';
  is $json->get("/obj/name"), "direct.example.com", 'edit_record: /obj/name';

  $req = undef;
  $json = $cf->delete_record("16606009");
  is $req->param('z'), 'example.com', 'delete_record: z';
  is $req->param('tkn'), '8afbe6dea02407989af4dd4c97bb6e25', 'delete_record: tkn';
  is $req->param('email'), 'sample@example.com', 'delete_record: email';
  is $req->param('a'), 'rec_delete', 'delete_record: a';
  is $req->param('id'), '16606009', 'delete_record: id';
  is_deeply $json->data, {}, 'delete_record: data()';
}

done_testing;

sub expected {
  return(
    # START records()
    {
      "request" => { "act" => "rec_load_all", "a" => "rec_load_all", "email" => "sample\@example.com", "tkn" => "8afbe6dea02407989af4dd4c97bb6e25", "z" => "example.com" },
      "response" => {
        "recs" => {
          "has_more" => undef,
          "count" => 7,
          "objs" => [
            {
              "rec_id" => "16606009",
              "rec_tag" => "7f8e77bac02ba65d34e20c4b994a202c",
              "zone_name" => "example.com",
              "name" => "direct.example.com",
              "display_name" => "direct",
              "type" => "A",
              "prio" => undef,
              "content" => "[server IP]",
              "display_content" => "[server IP]",
              "ttl" => "1",
              "ttl_ceil" => 86400,
              "ssl_id" => undef,
              "ssl_status" => undef,
              "ssl_expires_on" => undef,
              "auto_ttl" => 1,
              "service_mode" => "0",
              "props" => { "proxiable" => 1, "cloud_on" => 0, "cf_open" => 1, "ssl" => 0, "expired_ssl" => 0, "expiring_ssl" => 0, "pending_ssl" => 0 }
            },
            {
              "rec_id" => "16606003",
              "rec_tag" => "d5315634e9f5660d3670e62fa176e5de",
              "zone_name" => "example.com",
              "name" => "home.example.com",
              "display_name" => "home",
              "type" => "A",
              "prio" => undef,
              "content" => "[server IP]",
              "display_content" => "[server IP]",
              "ttl" => "1",
              "ttl_ceil" => 86400,
              "ssl_id" => undef,
              "ssl_status" => undef,
              "ssl_expires_on" => undef,
              "auto_ttl" => 1,
              "service_mode" => "0",
              "props" => { "proxiable" => 1, "cloud_on" => 0, "cf_open" => 1, "ssl" => 0, "expired_ssl" => 0, "expiring_ssl" => 0, "pending_ssl" => 0 }
            },
          ],
        },
      },
      "result" => "success",
      "msg" => undef
    },
    # START edit_record()
    {
      "request" => { "act" => "rec_edit", "a" => "rec_edit", "tkn" => "8afbe6dea02407989af4dd4c97bb6e25", "id" => "23734516", "email" => "sample\@example.com", "type" => "A", "z" => "example.com", "name" => "direct", "service_mode" => 0 },
      "response" => {
        "rec" => {
          "obj" => {
            "rec_id" => "23734516",
            "rec_tag" => "b3db8b8ad50389eb4abae7522b22852f",
            "zone_name" => "example.com",
            "name" => "direct.example.com",
            "display_name" => "sub",
            "type" => "A",
            "prio" => undef,
            "content" => "96.126.126.36",
            "display_content" => "96.126.126.36",
            "ttl" => "1",
            "ttl_ceil" => 86400,
            "ssl_id" => "12805",
            "ssl_status" => "V",
            "ssl_expires_on" => undef,
            "auto_ttl" => 1,
            "service_mode" => "1",
            "props" => { "proxiable" => 1, "cloud_on" => 1, "cf_open" => 0, "ssl" => 1, "expired_ssl" => 0, "expiring_ssl" => 0, "pending_ssl" => 0, "vanity_lock" => 0 }
          }
        }
      },
      "result" => "success",
      "msg" => undef
    },
    # START delete_record()
    {
      "request" => { "act" => "rec_delete", "a" => "rec_delete", "tkn" => "1296c62233d48a6cf0585b0c1dddc3512e4b2", "id" => "23735515", "email" => "sample\@example.com", "z" => "example.com" },
      "result" => "success",
      "msg" => undef,
    },
  );
}
