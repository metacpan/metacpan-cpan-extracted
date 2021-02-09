package NewsExtractor::SiteSpecificExtractor::UDN;
use utf8;
use Moo;
extends 'NewsExtractor::SiteSpecificExtractor';

use Importer 'NewsExtractor::TextUtil' => qw( html2text normalize_whitespace reformat_dateline );

sub headline {
    my ($self) = @_;
    my $el = $self->dom->at('#story_art_title, h1.story_art_title, h1.article-content__title') or return;
    my $txt = $el->all_text;
    return normalize_whitespace($txt);
}

sub dateline {
    my ($self) = @_;
    my $el;
    if ($el = $self->dom->at(".shareBar__info--author > span:nth-child(1), .authors time.article-content__time")) {
        my $txt = $el->all_text;
        return normalize_whitespace($txt);
    }

    # opinion.udn.com
    if ($el = $self->dom->at('.story_bady_info > time[datetime]')) {
        return reformat_dateline($el->all_text, '+08:00');
    }
}

sub journalist {
    my ($self) = @_;
    my $el;
    if ($el = $self->dom->at(".shareBar__info--author, .authors span.article-content__author")) {
        my $txt = $el->all_text;
        $txt =~ s/\s+/ /g; # Sometimes there are newlines
        return normalize_whitespace($txt);
    }

    # opinion.udn.com
    if ($el = $self->dom->at('.story_bady_info')) {
        return $el->find('a.author')->map(sub { normalize_whitespace( $_->text ) })->join(', ') . "";
    }
}

sub content_text {
    my ($self) = @_;
    my $el = $self->dom->at("section.article-content__editor");
    $el->find("script, style")->map("remove");
    return html2text("$el");
}

1;
