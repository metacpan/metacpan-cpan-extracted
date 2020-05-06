package NewsExtractor::SiteSpecificExtractor::www_taipeitimes_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at("meta[property='article:published_time']");
    return "". $el->attr('content');
}

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at(".name");
    my $txt = $el->text;
    return normalize_whitespace($txt);
}

1;
