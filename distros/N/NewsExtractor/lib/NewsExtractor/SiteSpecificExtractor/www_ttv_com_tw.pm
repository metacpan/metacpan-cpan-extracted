package NewsExtractor::SiteSpecificExtractor::www_ttv_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'u';

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at(".ReportDate > a:nth-child(1)") or return;
    my ($yyyy, $mm, $dd) = split /-/, $el->all_text;
    return u(sprintf('%04d/%02d/%02d', $yyyy, $mm, $dd));
}

sub journalist {
    my ($self) = @_;
    my ($name) = $self->content_text =~ m{（記者\s*([^/]+?)\s*／.+?報導）};
    return $name;
}

1;
