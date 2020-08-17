package NewsExtractor::SiteSpecificExtractor::news_tnn_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'reformat_dateline';

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at("span.f12_15a_g2");
    return reformat_dateline( $el->text(), '+08:00' );
}

sub journalist {
    my ($self) = @_;
    my $txt = $self->content_text;

    my ($x) = $txt =~ m{[〔﹝【]記者 \s* ([ \p{Letter}]+?) \s* (?:[／/]\p{Letter}+)?報導[﹞〕】]}x;
    return $x;
}

1;
