package NewsExtractor::SiteSpecificExtractor::www_rvn_com_tw;
use utf8;

use Moo;
extends 'NewsExtractor::SiteSpecificExtractor';
use Types::Standard qw(InstanceOf);

has extractor => (
    required => 0,
    is => 'lazy',
    isa => InstanceOf["NewsExtractor::CSSExtractor"],
    builder => 1,
    handles => [qw( headline dateline journalist content_text )],
);

use NewsExtractor::CSSRuleSet;
use NewsExtractor::CSSExtractor;

sub _build_extractor {
    my ($self) = @_;
    return NewsExtractor::CSSExtractor->new(
        css_selector => NewsExtractor::CSSRuleSet->new(
            headline     => 'td[height=30][align=CENTER] b font',
            dateline     => 'tr > td[align=left] > b > font[style="font-size:11pt;"]',
            journalist   => 'tr > td[align=left] > b > font[style="font-size:11pt;"]',
            content_text => 'td[colspan=2] > p > span[style="font-size:16px"]',
        ),
        tx => $self->tx,
    )
}

around 'dateline' => sub {
    my $orig = shift;
    my $ret = $orig->(@_);
    $ret =~ s/^(.+\S)\s+(記者:.+)$/$1/;
    return $ret;
};

around 'journalist' => sub {
    my $orig = shift;
    my $ret = $orig->(@_);
    $ret =~ s/^(.+\S)\s+(記者:.+)$/$2/;
    return $ret;
};

1;
