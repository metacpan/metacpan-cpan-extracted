package NewsExtractor::SiteSpecificExtractor::m_news_cctv_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil'  => qw(normalize_whitespace reformat_dateline);

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('span.info i') or return;
    return reformat_dateline( $el->all_text(), '+08:00' );
}

sub journalist {
    my ($self) = @_;
    my ($txt) = $self->content_text() =~ m/（ (?:总台记者|编辑) (.+?)）\z/xg;
    $txt = normalize_whitespace($txt);
    return $txt;
}

1;
