package NewsExtractor::SiteSpecificExtractor::www_rti_org_tw;
use utf8;
use Moo;
extends 'NewsExtractor::SiteSpecificExtractor';

use Importer 'NewsExtractor::TextUtil' => 'html2text';

sub headline {
    my ($self) = @_;
    my $el = $self->dom->at('.news-detail-box > hgroup:nth-child(1) > h1:nth-child(1)');
    return $el->all_text;
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('.date');
    my $txt = $el->all_text;
    $txt =~ s/^時間：//;
    return $txt;
}

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at('li.source:nth-child(3)');
    return $el->all_text;
}

sub content_text {
    my ($self) = @_;
    my $el = $self->dom->at('.news-detail-box > article:nth-child(4)');
    return html2text( $el->to_string );
}

1;
