package NewsExtractor::SiteSpecificExtractor::www_allnews_tw;
use utf8;
use Moo;
extends 'NewsExtractor::SiteSpecificExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub dom {
    my ($self) = @_;
    return $self->tx->res->dom;
}

sub headline {
    my ($self) = @_;
    my $el = $self->dom->find('meta[property="og:title"]')->first;
    return $el->attr('content');
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->find('h2.newsTitle ~ div.desc > div:nth-child(1) > span:nth-child(1)')->first;
    return $el->text();
}

sub content_text {
    my ($self) = @_;
    my $el = $self->dom->find('meta[property="og:description"]')->first;
    return normalize_whitespace( $el->attr('content') );
}

sub journalist {
    my ($self) = @_;
    my ($txt) = $self->content_text =~ m/\A【(本報記者.+?報導)】/;
    return $txt;
}

1;
