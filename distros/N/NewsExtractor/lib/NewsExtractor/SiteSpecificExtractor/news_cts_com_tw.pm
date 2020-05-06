package NewsExtractor::SiteSpecificExtractor::news_cts_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::SiteSpecificExtractor';

use Importer 'NewsExtractor::TextUtil' => qw< html2text normalize_whitespace >;

sub headline {
    my ($self) = @_;
    if (my $el = $self->dom->at('h1[itemprop="headline"]')) {
        return $el->all_text;
    }
    return undef;
}

sub content_text {
    my ($self) = @_;
    if (my $el = $self->dom->at('div[itemprop="articleBody"]')) {
        return html2text( $el->to_string );
    }
    return undef;
}

sub dateline {
    my ($self) = @_;
    if (my $el = $self->dom->at('p[itemprop="datePublished"]')) {
        return $el->attr("datetime");
    }
    return undef;
}

sub journalist {
    my ($self) = @_;


    if (my $el = $self->dom->at("div.artical-content")) {
        my $p_first = $el->at("p");
        my $line = $p_first->all_text;
        if ($line =~ m{([\p{Letter}\p{Space}])報導\s*/\s*\p{Letter}{1,5}}) {
            return normalize_whitespace($line);
        }
    }

    my @patterns = (
        qr{^(.+?\s*報導\s*/\s*\S+)\s?\n},
        qr<\A (\p{Letter}+? \s+ 採訪/撰稿 \s+ \p{Letter}+? \s+ 攝影/剪輯) \s+ />x,
    );

    my $content_text = $self->content_text;
    my @matched;
    for my $pat (@patterns) {
        @matched = $content_text =~ m/$pat/;
        last if @matched;
    }

    return $matched[0];
}

1;
