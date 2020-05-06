package NewsExtractor::SiteSpecificExtractor::news_ebc_net_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub _build_content_text {
    my ($self) = @_;

    # Remove the in-article ad.
    $self->dom->find("#contentb p > a[href^='https://bit.ly/']")->grep(
        sub {
            ($_->parent->children->size == 1)
            && ($_->text =~ m/^★/)
        })->map('remove');

    return $self->SUPER::_build_content_text();
}

sub journalist {
    my ($self) = @_;
    my $guess = $self->dom->at('.fncnews-content > .info > span.small-gray-text') or return;
    my $text = normalize_whitespace($guess->all_text);
    my ($name) = $text =~ m/(?:東森新聞(?:\s*責任編輯)?)\s+(.+)$/;
    return $name;
}

1;
