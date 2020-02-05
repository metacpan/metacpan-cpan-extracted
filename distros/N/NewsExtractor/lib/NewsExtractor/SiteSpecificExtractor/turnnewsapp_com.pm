package NewsExtractor::SiteSpecificExtractor::turnnewsapp_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub journalist {
    my ($self) = @_;
    my ($txt) = $self->content_text =~ m{（記者／(\p{Letter}+)）\z};
    return $txt;
}

1;
