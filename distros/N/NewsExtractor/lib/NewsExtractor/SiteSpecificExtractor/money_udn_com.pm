package NewsExtractor::SiteSpecificExtractor::money_udn_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub headline {
    my ($self) = @_;
    my $el = $self->dom->at('#story_art_title');
    my $txt = $el->all_text;
    return normalize_whitespace($txt);
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at(".shareBar__info--author > span:nth-child(1)");
    my $txt = $el->all_text;
    return normalize_whitespace($txt);
}

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at(".shareBar__info--author");
    my $txt = $el->text;
    return normalize_whitespace($txt);
}

1;
