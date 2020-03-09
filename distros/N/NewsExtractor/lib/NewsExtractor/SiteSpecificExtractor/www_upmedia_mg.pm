package NewsExtractor::SiteSpecificExtractor::www_upmedia_mg;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at("div.author > a");
    my $txt = $el->text;
    return normalize_whitespace($txt);
}

1;
