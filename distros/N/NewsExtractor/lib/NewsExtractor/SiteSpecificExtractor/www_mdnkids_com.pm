package NewsExtractor::SiteSpecificExtractor::www_mdnkids_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw(reformat_dateline);

sub dateline {
    my ($self) = @_;
    return reformat_dateline( $self->dom->at('td.newsbox_content_txt')->all_text(), '+08:00' );
}

sub journalist {
    my ($self) = @_;
    my $txt = $self->content_text;

    my @regexps = (
        qr{\A(\S+)／\S+報導\n},
        qr{\A\S*(報導／\S+\s+攝影／\S+)\n},
        qr{\A\S*(文／\S+\s+圖／\S+)\n},
        qr{ \A\S*(\S{3})\n }x,
    );

    my ($x);
    for my $re (@regexps) {
        ($x) = $txt =~ $re;
        last if $x;
    }

    return $x;
}

1;
