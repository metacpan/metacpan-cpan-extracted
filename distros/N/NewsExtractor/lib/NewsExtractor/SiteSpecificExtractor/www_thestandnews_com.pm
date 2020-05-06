package NewsExtractor::SiteSpecificExtractor::www_thestandnews_com;
use utf8;
use Moo;
extends 'NewsExtractor::JSONLDExtractor';

use NewsExtractor::GenericExtractor;

sub site_name {
    return '立場新聞'
}

sub content_text {
    my ($self) = @_;

    return $self->NewsExtractor::GenericExtractor::_build_content_text();
}

1;
