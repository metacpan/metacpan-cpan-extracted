use strictures 2;

use Test::More;
use JSON ();

use Net::Blossom::BlobDescriptor;
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

my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';
my $JSON = JSON->new->utf8->canonical;

sub nip94_tags {
    return [
        ['url', "https://cdn.example.com/$HASH.pdf"],
        ['m', 'application/pdf'],
        ['x', $HASH],
        ['size', '184292'],
        ['magnet', 'magnet:?xt=urn:btih:9804c5286a3fb07b2244c968b39bc3cc814313bc&dn=bitcoin.pdf'],
        ['i', '9804c5286a3fb07b2244c968b39bc3cc814313bc'],
    ];
}

sub descriptor {
    return {
        url      => "https://cdn.example.com/$HASH.pdf",
        sha256   => $HASH,
        size     => 184292,
        type     => 'application/pdf',
        uploaded => 1725909682,
        nip94    => nip94_tags(),
    };
}

subtest 'BUD-08 blob descriptor exposes nip94 tags' => sub {
    my $blob = Net::Blossom::BlobDescriptor->from_hash(descriptor());

    is_deeply($blob->nip94, nip94_tags(), 'nip94 accessor returns tag array');
    is_deeply($blob->get('nip94'), nip94_tags(), 'generic accessor returns tag array');
    is_deeply($blob->to_hash->{nip94}, nip94_tags(), 'to_hash preserves tag array');
    ok(!exists $blob->extra->{nip94}, 'nip94 is a first-class descriptor field');
};

subtest 'BUD-08 PUT /upload descriptor preserves nip94 tags' => sub {
    my $ua = Local::UA->new({
        status  => 201,
        reason  => 'Created',
        headers => { 'content-type' => 'application/json' },
        content => $JSON->encode(descriptor()),
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $blob = $client->upload_blob('pdf bytes', type => 'application/pdf');

    is_deeply($blob->nip94, nip94_tags(), 'upload descriptor exposes nip94 tags');
};

subtest 'BUD-08 PUT /mirror descriptor preserves nip94 tags' => sub {
    my $source = "https://cdn.satellite.earth/$HASH.pdf";
    my $ua = Local::UA->new({
        status  => 201,
        reason  => 'Created',
        headers => { 'content-type' => 'application/json' },
        content => $JSON->encode(descriptor()),
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $blob = $client->mirror_blob($source);

    is_deeply($blob->nip94, nip94_tags(), 'mirror descriptor exposes nip94 tags');
};

subtest 'BUD-08 malformed nip94 tag data is rejected' => sub {
    my $descriptor = descriptor();

    my %not_array = %$descriptor;
    $not_array{nip94} = {};
    like(dies { Net::Blossom::BlobDescriptor->from_hash(\%not_array) },
        qr/nip94 must be an array reference/, 'nip94 object rejected');

    my %not_tags = %$descriptor;
    $not_tags{nip94} = ['x'];
    like(dies { Net::Blossom::BlobDescriptor->from_hash(\%not_tags) },
        qr/nip94 tags must be array references/, 'non-array tag rejected');

    my %empty_tag = %$descriptor;
    $empty_tag{nip94} = [[]];
    like(dies { Net::Blossom::BlobDescriptor->from_hash(\%empty_tag) },
        qr/nip94 tags must contain at least a name and value/, 'empty tag rejected');

    my %nested_value = %$descriptor;
    $nested_value{nip94} = [['url', ['https://cdn.example.com/blob']]];
    like(dies { Net::Blossom::BlobDescriptor->from_hash(\%nested_value) },
        qr/nip94 tag values must be scalars/, 'nested tag value rejected');
};

done_testing;
