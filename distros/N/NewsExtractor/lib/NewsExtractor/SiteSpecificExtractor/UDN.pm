package NewsExtractor::SiteSpecificExtractor::UDN;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw( normalize_whitespace reformat_dateline );

sub headline {
    my ($self) = @_;
    my $el = $self->dom->at('#story_art_title, h1.story_art_title') or return;
    my $txt = $el->all_text;
    return normalize_whitespace($txt);
}

sub dateline {
    my ($self) = @_;
    my $el;
    if ($el = $self->dom->at(".shareBar__info--author > span:nth-child(1)")) {
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
    if ($el = $self->dom->at(".shareBar__info--author")) {
        return normalize_whitespace($el->text);
    }

    # opinion.udn.com
    if ($el = $self->dom->at('.story_bady_info')) {
        return $el->find('a.author')->map(sub { normalize_whitespace( $_->text ) })->join(', ') . "";
    }
}

1;
