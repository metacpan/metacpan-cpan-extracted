use 5.014;
use Test::Most;
use Mojo::URL;
use Mojo::Message::Request;
use Mojo::Transaction::HTTP;
use Mojo::UserAgent::Mockable;

sub tx {
    return Mojo::Transaction::HTTP->new(
        req => Mojo::Message::Request->new( @_ ),
    );
}

subtest 'no sub' => sub {

    my $ua = Mojo::UserAgent::Mockable->new();

    my $tx          = tx( method => 'GET', url => Mojo::URL->new('/integers/3432') );
    my $recorded_tx = tx( method => 'GET', url => Mojo::URL->new('/integers/6345') );
    my ($this_req, $recorded_req) = $ua->_normalized_req( $tx, $recorded_tx );

    is(
        $this_req,
        $tx->req,
        "No normalizer, just pass through the requests"
    );
    is(
        $recorded_req,
        $recorded_tx->req,
        "No normalizer, just pass through the requests"
    );

};

subtest 'with sub, cloned request objects are modified' => sub {

    my $floats_url = "/floats/3.14";
    my $fractions_url = "/fractions/3fifths";

    my $ua = Mojo::UserAgent::Mockable->new(
        request_normalizer => sub {
            my ($req, $recorded_req) = @_;
            $req->url->path($floats_url);
            $recorded_req->url->path($fractions_url);
        },
    );

    my $tx          = tx( method => 'GET', url => Mojo::URL->new('/integers/3432') );
    my $recorded_tx = tx( method => 'GET', url => Mojo::URL->new('/integers/6345') );
    my ($this_req, $recorded_req) = $ua->_normalized_req( $tx, $recorded_tx );

    isnt($this_req, $tx->req, "Normalizer, cloned objects");
    isnt($recorded_req, $recorded_tx->req, "Normalizer, cloned objects");

    is($this_req->url->path, $floats_url, "First req modified");
    is($recorded_req->url->path, $fractions_url, "Second req modified");
};

done_testing;
