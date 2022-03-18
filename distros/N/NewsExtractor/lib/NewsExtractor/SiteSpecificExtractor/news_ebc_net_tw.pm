package NewsExtractor::SiteSpecificExtractor::news_ebc_net_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'reformat_dateline';

sub _build_content_text {
    my ($self) = @_;

    # Remove the in-article ad.
    $self->dom->find("div.raw-style > content-ad > p")->grep(
        sub {
            ($_->child_nodes->size > 2)
                && ($_->children("a")->size >= 2)
        }
    )->map('remove');

    my $text = $self->SUPER::_build_content_text();

    $text =~ s/\n\n【往下看更多】.+\z//s;

    return $text;
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
    return reformat_dateline($el->all_text(), '+08:00');
}

1;
