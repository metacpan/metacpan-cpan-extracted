use strictures 2;

use Test::More;

use Net::Blossom::Client;

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

my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';

subtest 'BUD-01 GET /<sha256> supports optional file extension' => sub {
    my $ua = Local::UA->new({ status => 200, reason => 'OK', headers => {}, content => 'blob' });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);
    $client->get_blob($HASH, extension => 'pdf');
    my $request = ($ua->requests)[0];
    my ($method, $url) = @$request;
    is($method, 'GET', 'GET');
    is($url, "https://cdn.example.com/$HASH.pdf", 'extension URL');
};

subtest 'BUD-01 HEAD /<sha256> sends HEAD and returns no response body requirement to caller' => sub {
    my $ua = Local::UA->new({ status => 200, reason => 'OK', headers => { 'content-length' => 4 }, content => '' });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);
    my $response = $client->head_blob($HASH);
    my $request = ($ua->requests)[0];
    my ($method, $url) = @$request;
    is($method, 'HEAD', 'HEAD');
    is($url, "https://cdn.example.com/$HASH", 'hash URL');
    is($response->content, '', 'empty body');
};

subtest 'BUD-01 clients treat X-Reason as diagnostic only' => sub {
    my $ua = Local::UA->new({
        status => 404, reason => 'Not Found',
        headers => { 'x-reason' => 'blob missing' },
        content => '',
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);
    my $error = eval { $client->get_blob($HASH); undef } || $@;
    is($error->status, 404, 'status drives failure');
    is($error->x_reason, 'blob missing', 'reason retained as diagnostic');
};

done_testing;
