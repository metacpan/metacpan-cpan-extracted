package NewsExtractor::SiteSpecificExtractor::www_hkcnews_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at('.article-info');
    my ($n) = $el->all_text =~ m{^撰文: (?:(?:特約)?記者)?(\p{Letter}+?) \|};
    return $n;
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('.article-info');
    my ($dd,$mm,$yy) = $el->all_text =~ m{發佈日期: ([0-9]{2})\.([0-9]{2})\.([0-9]{2})$};
    return "20${yy}/${mm}/${dd}";
}


1;
