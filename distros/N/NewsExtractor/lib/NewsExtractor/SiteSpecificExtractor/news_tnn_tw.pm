package NewsExtractor::SiteSpecificExtractor::news_tnn_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub journalist {
    my ($self) = @_;
    my ($txt) = $self->content_text =~ m{[〔【]記者([ \p{Letter}]+?)(?:[／/]\p{Letter}+)?報導[〕】]};
    return $txt;
}

1;
