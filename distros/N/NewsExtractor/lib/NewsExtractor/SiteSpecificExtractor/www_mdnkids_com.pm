package NewsExtractor::SiteSpecificExtractor::www_mdnkids_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw(parse_dateline_ymdhms);

sub dateline {
    my ($self) = @_;
    return parse_dateline_ymdhms( $self->dom->at('td.newsbox_content_txt'), '+08:00' );
}

sub journalist {
    my ($self) = @_;
    my ($x) = $self->content_text =~ m{\A(\S+)／\S+報導\n};
    return $x;
}

1;
