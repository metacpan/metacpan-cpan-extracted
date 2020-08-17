package NewsExtractor::SiteSpecificExtractor::www_penghutimes_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'reformat_dateline';

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at('h1.main-title')->next();
    my ($t) = $el->all_text() =~ m/記者:\s*(\S+)\s*/;
    return $t;
}

sub dateline {
    my ($self) = @_;
    my $node = $self->dom->at('h1.main-title')->next()->child_nodes->first;
    my $t = reformat_dateline("$node", '+08:00');
    return $t;
}

1;
