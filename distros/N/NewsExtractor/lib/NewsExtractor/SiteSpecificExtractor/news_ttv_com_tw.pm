package NewsExtractor::SiteSpecificExtractor::news_ttv_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw(u reformat_dateline);

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at("li.date.time") or return;
    my $t = $el->all_text;
    reformat_dateline( $t, '+08:00' );
}

sub journalist {
    my ($self) = @_;

    my $x;
    my $t = $self->content_text;
    my @regexps = (
        qr{（記者\s*([^/]+?)\s*／.+?報導）},
        qr{(責任編輯／\p{Letter}+)\z},
    );

    for my $re (@regexps) {
        ($x) = $t =~ /$re/;
        last if $x;
    }

    return $x;
}

1;
