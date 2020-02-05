package NewsExtractor::SiteSpecificExtractor::www_setn_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub journalist {
    my ($self) = @_;
    my ($txt) = $self->content_text =~ m{\b記者([\p{Letter}、]+?)／(?:\p{Letter}+?)報導\b};
    return normalize_whitespace($txt);
}

1;
