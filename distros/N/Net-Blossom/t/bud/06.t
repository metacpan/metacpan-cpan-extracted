use strictures 2;

use Test::More;
use Digest::SHA qw(sha256_hex);

use Net::Blossom::Client;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::UA;
    use strictures 2;
    sub new { bless { requests => [], responses => [@_[1 .. $#_]] }, $_[0] }
    sub request {
        my ($self, $method, $url, $opts) = @_;
        push @{$self->{requests}}, [$method, $url, $opts || {}];
        return shift @{$self->{responses}};
    }
    sub requests { @{$_[0]->{requests}} }
}

subtest 'BUD-06 HEAD /upload sends upload metadata and no body' => sub {
    my $body = pack('C*', 0, 255, 80, 68, 70, 10);
    my $ua = Local::UA->new({
        status  => 200,
        reason  => 'OK',
        headers => { 'x-reason' => 'upload accepted' },
        content => '',
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $response = $client->head_upload($body, type => 'application/pdf');
    is($response->status, 200, 'preflight accepted');
    is($response->header('x-reason'), 'upload accepted', 'diagnostic header available');

    my ($method, $url, $opts) = @{($ua->requests)[0]};
    is($method, 'HEAD', 'HEAD method');
    is($url, 'https://cdn.example.com/upload', 'upload endpoint');
    ok(!exists $opts->{content}, 'HEAD request has no body');
    is($opts->{headers}{'X-SHA-256'}, sha256_hex($body), 'body hash preflight header');
    is($opts->{headers}{'X-Content-Type'}, 'application/pdf', 'content type preflight header');
    is($opts->{headers}{'X-Content-Length'}, length($body), 'content length preflight header');
};

subtest 'BUD-06 HEAD /upload defaults type and permits empty blobs' => sub {
    my $body = '';
    my $ua = Local::UA->new({
        status  => 200,
        reason  => 'OK',
        headers => {},
        content => '',
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    is($client->head_upload($body)->status, 200, 'empty blob preflight accepted');

    my ($method, $url, $opts) = @{($ua->requests)[0]};
    is($method, 'HEAD', 'HEAD method');
    is($url, 'https://cdn.example.com/upload', 'upload endpoint');
    is($opts->{headers}{'X-SHA-256'}, sha256_hex($body), 'empty body hash header');
    is($opts->{headers}{'X-Content-Type'}, 'application/octet-stream', 'default content type');
    is($opts->{headers}{'X-Content-Length'}, 0, 'empty content length header');
};

subtest 'BUD-06 HEAD /upload uses upload authorization context' => sub {
    my @seen;
    my $body = 'authorized upload';
    my $ua = Local::UA->new({
        status  => 200,
        reason  => 'OK',
        headers => {},
        content => '',
    });
    my $client = Net::Blossom::Client->new(
        server => 'https://cdn.example.com',
        ua     => $ua,
        auth   => sub {
            push @seen, { @_ };
            return 'Nostr upload-token';
        },
    );

    $client->head_upload($body);

    is(scalar @seen, 1, 'auth callback called once');
    is($seen[0]{method}, 'HEAD', 'method context');
    is($seen[0]{url}, 'https://cdn.example.com/upload', 'url context');
    is($seen[0]{action}, 'upload', 'action context');
    is($seen[0]{sha256}, sha256_hex($body), 'sha256 context');

    my ($method, $url, $opts) = @{($ua->requests)[0]};
    is($opts->{headers}{Authorization}, 'Nostr upload-token', 'authorization header sent');
};

subtest 'BUD-06 rejection statuses preserve X-Reason diagnostics' => sub {
    my $ua = Local::UA->new({
        status  => 413,
        reason  => 'Content Too Large',
        headers => { 'x-reason' => 'file too large' },
        content => '',
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $error = dies { $client->head_upload('large file') };
    isa_ok($error, 'Net::Blossom::Error');
    is($error->status, 413, 'status');
    is($error->x_reason, 'file too large', 'x-reason diagnostic');
};

subtest 'BUD-06 upload content is required' => sub {
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => Local::UA->new);

    like(dies { $client->head_upload() },
        qr/content is required/, 'HEAD upload requires content');
};

done_testing;
