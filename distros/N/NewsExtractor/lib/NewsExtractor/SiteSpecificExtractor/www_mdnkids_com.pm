package NewsExtractor::SiteSpecificExtractor::www_mdnkids_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw(parse_dateline_ymdhms);

sub dateline {
    my ($self) = @_;
    return parse_dateline_ymdhms( $self->dom->at('td.newsbox_content_txt')->all_text(), '+08:00' );
}

sub journalist {
    my ($self) = @_;
    my $txt = $self->content_text;
    my ($x) = $txt =~ m{\A(\S+)／\S+報導\n};
    unless ($x) {
        ($x) = $txt =~ m{\A\S*(文／\S+\s+圖／\S+)\n};
    }
    unless ($x) {
        ($x) = $txt =~ m/ \A\S*(\S{3})\n /x;
    }
    return $x;
}

1;
