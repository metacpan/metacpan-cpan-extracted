package NewsExtractor::SiteSpecificExtractor::www_epochtimes_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub journalist {
    my ($self) = @_;
    my $text = $self->content_text;
    my ($name) = $text =~ m{（(?:大紀元記者|大纪元记者) (\p{Letter}+?) (?:综合|綜合|编译|編譯)?(?:报导|報導)）}x;
    return $name;
}

1;
