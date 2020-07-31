package NewsExtractor::SiteSpecificExtractor::news_ebc_net_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'parse_dateline_ymdhms';

sub _build_content_text {
    my ($self) = @_;

    # Remove the in-article ad.
    $self->dom->find("#contentb p > a[href^='https://bit.ly/']")->grep(
        sub {
            ($_->parent->children->size == 1)
            && ($_->text =~ m/^★/)
        })->map('remove');

    # Remove recommendations at the end of the article body.
    $self->dom->at("#contentb div.raw-style > span:nth-child(1)")->following_nodes()->map('remove');

    return $self->SUPER::_build_content_text();
}

sub journalist {
    my ($self) = @_;
    my $guess = $self->dom->at('.fncnews-content > .info > span.small-gray-text') or return;
    my $text = $guess->all_text;
    my ($name) = $text =~ m/(?:東森新聞(?:\s*責任編輯)?)\s+(.+)$/;
    return $name;
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at(".fncnews-content > .info > span.small-gray-text") or return;
    return parse_dateline_ymdhms($el->all_text(), '+08:00');
}

1;
