package NewsExtractor::SiteSpecificExtractor::www_fountmedia_io;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub dateline {
    my ($self) = @_;
    my $dom = $self->dom;
    my $el_date = $dom->at("div.detitle2 > div.cell > div");
    my $el_time = $dom->at("div.detitle2 > div.cell.time");
    my $dateline = ($el_date->text =~ s/\./-/gr) . "T" . ($el_time->text =~ s/[ap]m/:00+08:00/r);
    return $dateline;
}

1;
