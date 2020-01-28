package NewsExtractor::SiteSpecificExtractor::www_ksnews_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil'  => qw( normalize_whitespace );

sub headline {
    my ($self) = @_;
    my $el = $self->dom->at("div.contents_page h1.title_");
    return $el->text;
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at(".date");
    return $el->text;
}

sub journalist {
    my ($self) = @_;
    my $text = $self->content_text;
    my ($name) = $text =~ m{\b (?:\V+[╱／])? 記者(.+?) [/／]? 報導\b}x;
    return $name;
}

sub content_text {
    my ($self) = @_;
    my $el = $self->dom->at(".edit > section");
    my $text = $el->all_text;

    my $headline = $self->headline;
    $text =~ s/\A\s+$headline\s+//s;
    $text = normalize_whitespace($text);
    return $text;
}

1;
