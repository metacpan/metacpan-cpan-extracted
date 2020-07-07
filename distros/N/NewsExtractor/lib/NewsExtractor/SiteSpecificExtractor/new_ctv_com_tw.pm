package NewsExtractor::SiteSpecificExtractor::new_ctv_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil'  => qw(u);

sub headline {
    my ($self) = @_;
    my $headline = $self->dom->at('meta[property="og:title"][content]')->attr('content');
    $headline =~ s/│中視新聞 [0-9]{8}\z//;
    return $headline;
};

sub dateline {
    my ($self) = @_;
    my $dateline = $self->dom->at("div.author")->text =~ s /\A中視新聞 \| //r;
    my @t = split /[^0-9]+/, $dateline;
    return u( sprintf('%04d-%02d-%02dT%02d:%02d:%02d+08:00', $t[0], $t[1], $t[2], $t[3], $t[4], $t[5]) );
}

1;
