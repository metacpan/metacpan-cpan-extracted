package NewsExtractor::SiteSpecificExtractor::news_cts_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub journalist {
    my ($self) = @_;
    my ($txt) = $self->content_text =~ m{^(.+?\s*報導\s*/\s*\S+)\s?\n};
    return $txt;
}

1;
