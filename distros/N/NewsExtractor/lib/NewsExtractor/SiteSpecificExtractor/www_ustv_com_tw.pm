package NewsExtractor::SiteSpecificExtractor::www_ustv_com_tw;
use utf8;

use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw(reformat_dateline);

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('#share0') or return;
    $el = $el->next() or return;
    my ($x) = $el->all_text =~ m/發佈日期:\s+(\S+?)\s+觀看次數/sm;
    $x or return;
    return reformat_dateline($x, '+08:00');
}

1;
