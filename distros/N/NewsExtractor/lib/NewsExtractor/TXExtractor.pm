package NewsExtractor::TXExtractor;
use Moo;
use Types::Standard qw( InstanceOf );
use Encode 'find_encoding';

has tx => (
    required => 0,
    is => 'ro',
    isa => InstanceOf['Mojo::Transaction::HTTP']
);

has dom => (
    required => 0,
    isa => InstanceOf['Mojo::DOM'],
    is => 'lazy',
    builder => 1,
);

sub _build_dom {
    my $tx = $_[0]->tx;
    my $dom = $tx->result->dom;

    my $charset;
    if ($tx->result->headers->content_type =~ /charset=(\S+)/) {
        $charset = $1;
    } elsif (my $el = $dom->at('meta[http-equiv="content-type" i]')) {
        if ($el->attr("content") =~ /\;\s*charset=(\S+)/i) {
            $charset = $1;
        }
    }

    if ($charset) {
        my $enc = find_encoding( $charset );
        if ($enc) {
            my $body = $enc->decode($tx->result->body);
            $dom = Mojo::DOM->new($body);
        }
    }

    return $dom;
}

1;
