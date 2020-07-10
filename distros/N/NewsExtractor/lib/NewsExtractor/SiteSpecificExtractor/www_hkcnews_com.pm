package NewsExtractor::SiteSpecificExtractor::www_hkcnews_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

around headline => sub {
    my $orig = shift;
    my $self = $_[0];
    my $headline = $orig->(@_);
    my $journalist = $self->journalist();
    $headline =~ s/\s\|\s${journalist}$//;
    return $headline;
};

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at('.article-info');
    my ($n) = $el->all_text =~ m{^撰文: (?:(?:特約)?記者)?(\p{Letter}+?) \|};
    return $n;
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('.article-info');
    my ($dd,$mm,$yy) = $el->all_text =~ m{發佈日期:\s([0-9]{2})\.([0-9]{2})\.([0-9]{2})\b};
    return undef unless ($dd && $mm && $yy);
    return "20${yy}-${mm}-${dd}T23:59:59+08:00";
}


1;
