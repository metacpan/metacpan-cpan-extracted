package NewsExtractor::SiteSpecificExtractor::ctee_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil'  => qw( normalize_whitespace );

sub journalist {
    my ($self) = @_;
    my $text = $self->tx->result->dom->find("div.single-post-meta a")->map('text')->join(" ") // '';
    return normalize_whitespace("". $text);
}

1;
