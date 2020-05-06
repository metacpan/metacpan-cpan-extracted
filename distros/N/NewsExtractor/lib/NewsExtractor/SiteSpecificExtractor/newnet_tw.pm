package NewsExtractor::SiteSpecificExtractor::newnet_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub content_text {
    my ($self) = @_;
    $self->dom->find('label[for="ctl00_ContentPlaceHolder1_RadioButton6"], label[for="ctl00_ContentPlaceHolder1_RadioButton5"], label[for="ctl00_ContentPlaceHolder1_RadioButton4"], label[for="ctl00_ContentPlaceHolder1_RadioButton3"], label[for="ctl00_ContentPlaceHolder1_RadioButton2"], label[for="ctl00_ContentPlaceHolder1_RadioButton1"]')->map('remove');
    return $self->SUPER::content_text();
}

sub journalist {
    my ($self) = @_;

    my $txt;
    my $el = $self->dom->at('#ctl00_ContentPlaceHolder1_UpdatePanel2 a[href*="Search.aspx?report="]');
    if ($el) {
        $txt = $el->text;
    }
    unless ($txt) {
        ($txt) = $self->content_text =~ m<\A〔新網記者 ( \p{Letter}+ (?:報導|特稿))〕\b>x;
    }
    return $txt;
}

1;
