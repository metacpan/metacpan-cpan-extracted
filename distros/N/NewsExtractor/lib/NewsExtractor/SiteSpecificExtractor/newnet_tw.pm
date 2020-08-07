package NewsExtractor::SiteSpecificExtractor::newnet_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw( parse_dateline_ymdhms u );

sub headline {
    my ($self) = @_;
    my $el = $self->dom->at('h4 > b');
    return $el->all_text;
}

sub content_text {
    my ($self) = @_;
    $self->dom->find('label[for="ctl00_ContentPlaceHolder1_RadioButton6"], label[for="ctl00_ContentPlaceHolder1_RadioButton5"], label[for="ctl00_ContentPlaceHolder1_RadioButton4"], label[for="ctl00_ContentPlaceHolder1_RadioButton3"], label[for="ctl00_ContentPlaceHolder1_RadioButton2"], label[for="ctl00_ContentPlaceHolder1_RadioButton1"]')->map('remove');
    return $self->SUPER::content_text();
}

sub dateline {
    my ($self) = @_;

    my ($dateline, $el);
    if ($el = $self->dom->at('b > font[color=darkred]')) {
        # Example: 日期:2020/7/8 下午 08:52:39
        $dateline = parse_dateline_ymdhms( $el->all_text(), '+08:00' );
    }
    return $dateline;
}

sub journalist {
    my ($self) = @_;

    # .col-md-8 > div:nth-child(4) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(2) > b:nth-child(1) > font:nth-child(3)

    my ($txt, $el);

    if ($el = $self->dom->at('b > font[color=darkred]')) {
        ($txt) = $el->all_text =~ m/ (?:專題|採訪): \s* (\S+) \s* 日期/x;
    }
    if ((!$txt) && ($el = $self->dom->at('#ctl00_ContentPlaceHolder1_UpdatePanel2 a[href*="Search.aspx?report="]'))) {
        $txt = $el->text;
    }
    unless ($txt) {
        ($txt) = $self->content_text =~ m<\A〔新網記者 ( \p{Letter}+ (?:報導|特稿))〕\b>x;
    }
    return $txt;
}

1;
