package NewsExtractor::SiteSpecificExtractor::news_tvbs_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at("div.title h4.font_color5");
    my $txt = $el->all_text;
    return normalize_whitespace($txt);
}

1;
