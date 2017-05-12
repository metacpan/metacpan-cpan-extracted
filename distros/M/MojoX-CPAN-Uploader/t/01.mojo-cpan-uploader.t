use Test::More tests => 17;
use MIME::Base64;
use Mojolicious::Lite;
use Test::Mojo;
use File::Temp qw/ tempfile /;

plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop::Server->new->generate_port;

app->log->path(undef);
app->log->level('error');

BEGIN {
    use_ok('MojoX::CPAN::Uploader');
}

any '/' => sub {
    shift->render(text => "OK");
};

post '/auth' => sub {
    my $self = shift;
    my $auth = $self->req->headers->header('Authorization');
    ok($auth =~ qr/^Basic (.*)/);
    is($1, MIME::Base64::encode('user:pass', ''));

    is($self->param('HIDDENNAME'),    'user');
    is($self->param('CAN_MULTIPART'), 1);
    ok($self->param('pause99_add_uri_upload'));
    is($self->param('SUBMIT_pause99_add_uri_httpupload'),
        " Upload this file from my disk ");

    ok(!defined $self->param('pause99_add_uri_subdirtext'));

    if (ok(1)) {
        $self->render_text("OK");
    }
    else {
        $self->render_text("Fail");
    }
};

post '/auth/subdir' => sub {
    my $self = shift;
    my $auth = $self->req->headers->header('Authorization');
    ok($auth =~ qr/^Basic (.*)/);
    is($1, MIME::Base64::encode('user:pass', ''));

    is($self->param('pause99_add_uri_subdirtext'), 'someDir');

    $self->render_text("OK");
};

note "Building transaction with basic auth";
my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200);

my $up = MojoX::CPAN::Uploader->new;

isa_ok($up, 'MojoX::CPAN::Uploader');

my $url = $t->tx->req->url->clone;
$url->path('/auth');
$up->url($url);

$up->client($t->ua);
$up->auth('user', 'pass');

my ($fh, $filename) = tempfile();

note "Uploading single file";
my $result = $up->upload($filename);

ok($result);

note "Uploading single file to subdir";
$up->url->path($up->url->path . '/subdir');

$result = $up->upload($filename, 'someDir');

ok($result);
