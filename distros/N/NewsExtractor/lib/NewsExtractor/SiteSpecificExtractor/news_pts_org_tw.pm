package NewsExtractor::SiteSpecificExtractor::news_pts_org_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub dateline {
    my ($self) = @_;
    my $dom = $self->dom;
    my $el_date = $dom->at(".mid-news > .m-left-side > .maintype-wapper > h2");
    return undef unless $el_date;

    my $dateline = ($el_date->text =~ s/[年月]/-/gr =~ s/日//r);
    $dateline =~ s/\b([0-9])\b/0$1/g;
    $dateline .= 'T23:59:59+0800';
    return $dateline;
}

1;
