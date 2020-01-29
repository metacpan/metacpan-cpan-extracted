package NewsExtractor::Extractor;
use Moo;
extends 'NewsExtractor::TXExtractor';

use Mojo::Transaction::HTTP;
use Mojo::URL;
use Types::Standard qw(InstanceOf);
use NewsExtractor::CSSRuleSet;
use NewsExtractor::CSSExtractor;
use NewsExtractor::JSONLDExtractor;
use NewsExtractor::GenericExtractor;
use NewsExtractor::SiteSpecificExtractor::www_rvn_com_tw;
use NewsExtractor::SiteSpecificExtractor::www_allnews_tw;
use NewsExtractor::SiteSpecificExtractor::www_peopo_org;
use NewsExtractor::SiteSpecificExtractor::www_ntdtv_com;
use NewsExtractor::SiteSpecificExtractor::www_ksnews_com_tw;
use NewsExtractor::SiteSpecificExtractor::news_tvbs_com_tw;

has extractor => (
    required => 0,
    is => 'lazy',
    isa => InstanceOf["NewsExtractor::CSSExtractor",
                      "NewsExtractor::JSONLDExtractor",
                      "NewsExtractor::SiteSpecificExtractor",
                      "NewsExtractor::GenericExtractor"],
    builder => 1,
    handles => [qw( headline dateline journalist content_text )],
);

use constant {
    SiteSpecificExtractorByHost => {
        'www.allnews.tw' => 'NewsExtractor::SiteSpecificExtractor::www_allnews_tw',
        'www.rvn.com.tw' => 'NewsExtractor::SiteSpecificExtractor::www_rvn_com_tw',
        'www.chinatimes.com' => 'NewsExtractor::JSONLDExtractor',
        'video.udn.com' => 'NewsExtractor::JSONLDExtractor',
        'www.ctwant.com' => 'NewsExtractor::JSONLDExtractor',
        'www.peopo.org' => 'NewsExtractor::SiteSpecificExtractor::www_peopo_org',
        'www.ntdtv.com' => 'NewsExtractor::SiteSpecificExtractor::www_ntdtv_com',
        'www.ksnews.com.tw' => 'NewsExtractor::SiteSpecificExtractor::www_ksnews_com_tw',
        'news.tvbs.com.tw' => 'NewsExtractor::SiteSpecificExtractor::news_tvbs_com_tw',
    },
    CSSRuleSetByHost => {
        'www.nownews.com' => {
            headline   => 'h1.entry-title',
            dateline   => 'span.td-post-date:nth-child(2) > time:nth-child(1)',
            journalist => '.td-post-author-name',
            content_text => '.td-post-content > span[itemprop=articleBody]',
        },
        'www.epochtimes.com' => {
            headline     => 'h1.title',
            dateline     => 'header[role=heading] time[datetime]',
            journalist   => '#artbody > p:nth-last-child(4)',
            content_text => '#artbody p',
        },
        'www.enewstw.com' =>  {
            headline     => 'td.blog_title > strong',
            dateline     => 'td.blog_title tr:nth-child(2) > td.blog',
            journalist   => 'td.blog_title tr:nth-child(1) > td.blog',
            content_text => 'td.new_t p',
        }
    }
};

sub _build_extractor {
    my ($self) = @_;
    my $url = $self->tx->req->url;
    my $host = $url->host;
    my $extractor;
    if (my $sel = CSSRuleSetByHost->{$host}) {
        $extractor = NewsExtractor::CSSExtractor->new(
            css_selector => NewsExtractor::CSSRuleSet->new(%$sel),
            tx => $self->tx
        );
    } elsif (my $extractor_class = SiteSpecificExtractorByHost->{$host}) {
        $extractor = $extractor_class->new( tx => $self->tx );
    } else {
        $extractor = NewsExtractor::GenericExtractor->new( tx => $self->tx );
    }
    return $extractor;
}

1;
