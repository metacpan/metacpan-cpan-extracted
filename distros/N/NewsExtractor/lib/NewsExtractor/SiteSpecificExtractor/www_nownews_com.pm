package NewsExtractor::SiteSpecificExtractor::www_nownews_com;
use utf8;
use Moo;
extends 'NewsExtractor::SiteSpecificExtractor';

use Importer 'NewsExtractor::TextUtil' => qw( parse_dateline_ymdhms html2text );

sub headline {
    my ($self) = @_;
    return $self->dom->at('h3.newsTitle')->text;
}

sub content_text {
    my ($self) = @_;
    my $el = $self->dom->at('div.newsMsg') or return;
    return html2text( $el->to_string );
}

sub dateline {
    my ($self) = @_;
    return parse_dateline_ymdhms( $self->dom->at('div.newsInfo')->all_text(), '+08:00' );
}

sub journalist {
    my ($self) = @_;
    my ($x) = $self->dom->at('div.newsInfo')->all_text =~ m{^記者(.+)／\S+報導-};
    return $x;
}

1;
