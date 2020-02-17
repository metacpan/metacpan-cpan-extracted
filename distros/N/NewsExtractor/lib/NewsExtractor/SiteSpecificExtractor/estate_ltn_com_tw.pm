package NewsExtractor::SiteSpecificExtractor::estate_ltn_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::SiteSpecificExtractor';

use Importer 'NewsExtractor::TextUtil' => qw< normalize_whitespace html2text >;

sub headline {
    my ($self) = @_;
    my $el = $self->dom->at('div.container.page-name > h1');
    return $el->all_text;
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('p.author .time');
    my $txt = $el->all_text;
    return $txt;
}

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at('p.author');
    $el->children("div.share")->map('remove');
    return normalize_whitespace($el->text);
}

sub content_text {
    my ($self) = @_;
    my $el = $self->dom->at("div[itemprop=articleBody]");
    $el->children("p.appE1121")->map('remove');
    return html2text( $el->to_string );
}

1;
