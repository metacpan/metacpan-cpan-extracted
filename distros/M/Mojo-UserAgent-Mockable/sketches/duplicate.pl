use 5.014;
use Test::Most;
use Mojo::UserAgent;
use DDP;
my $ua = Mojo::UserAgent->new;


my $tx = $ua->post(
    'http://requestb.in/t87607t8' => {
        'X-Zaphod-Last-Name'                => 'Beeblebrox',
        'X-Benedict-Cumberbatch-Silly-Name' => 'Bumbershoot Crinklypants'
        } => form =>
        { foo => 'bar', quux => 'quuy', thefile => { file => q{/Users/kipeters/Documents/sample.txt} } }
);

my $req2 = Mojo::Message::Request->new;
$req2->parse($tx->req->to_string);

my $res2 = Mojo::Message::Response->new;
$res2->parse($tx->res->to_string);

for my $key (keys %{$tx->req->headers->to_hash}) {
    my $expected_header = $tx->req->headers->header($key);
    my $got_header = $req2->headers->header($key);
    is ($got_header, $expected_header, qq{Header '$key' OK});
}

is( $req2->url->path, $tx->req->url->path, 'path match' );
for ( 0 .. $#{ $req2->content->parts } ) {
    my $got = $req2->content->parts->[$_]->asset->slurp;
    my $expected = $tx->req->content->parts->[$_]->asset->slurp;
    is $got, $expected, qq{Chunk $_ matches};
}
done_testing;
