package NewsExtractor::SiteSpecificExtractor::www_taipeitimes_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('div#main div#content_left div#date h5');
    my $txt = $el->all_text;
    $txt = normalize_whitespace($txt);
    $txt =~ s/ - Page [0-9]+\z//;
    return $txt;
}

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at("div#main div#content_left div#front_boxd div.reporter");
    my $txt = $el->text;
    return normalize_whitespace($txt);
}

1;
