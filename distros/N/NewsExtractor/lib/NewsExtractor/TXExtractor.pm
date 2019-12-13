package NewsExtractor::TXExtractor;
use Moo;
use Types::Standard qw( InstanceOf );
use Encode 'decode';

has tx => (
    required => 1, is => 'ro',
    isa => InstanceOf['Mojo::Transaction::HTTP'] );

sub dom {
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
        my $body = decode($charset, $tx->result->body);
        $dom = Mojo::DOM->new($body);
    }

    return $dom;
}

1;
