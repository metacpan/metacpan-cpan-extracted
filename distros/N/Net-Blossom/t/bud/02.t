use strictures 2;

use Test::More;
use Digest::SHA qw(sha256_hex);
use JSON ();

use Net::Blossom::BlobDescriptor;
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
my $JSON = JSON->new->utf8->canonical;

sub descriptor {
    return {
        url => "https://cdn.example.com/$HASH.pdf",
        sha256 => $HASH,
        size => 184292,
        type => 'application/pdf',
        uploaded => 1725105921,
    };
}

subtest 'BUD-02 blob descriptor contains required fields' => sub {
    my $blob = Net::Blossom::BlobDescriptor->from_hash(descriptor());
    is($blob->url, "https://cdn.example.com/$HASH.pdf", 'url');
    is($blob->sha256, $HASH, 'sha256');
    is($blob->size, 184292, 'size');
    is($blob->type, 'application/pdf', 'type');
    is($blob->uploaded, 1725105921, 'uploaded');
};

subtest 'BUD-02 PUT /upload sends binary body and advisory sha header' => sub {
    my $data = 'abc';
    my $ua = Local::UA->new({ status => 200, reason => 'OK', headers => {}, content => $JSON->encode(descriptor()) });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);
    $client->upload_blob($data, type => 'application/octet-stream');
    my $request = ($ua->requests)[0];
    my ($method, $url, $opts) = @$request;
    is($method, 'PUT', 'PUT');
    is($url, 'https://cdn.example.com/upload', 'upload endpoint');
    is($opts->{content}, $data, 'exact bytes sent');
    is($opts->{headers}{'X-SHA-256'}, sha256_hex($data), 'sha header');
};

done_testing;
