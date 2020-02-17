package NewsExtractor::SiteSpecificExtractor::turnnewsapp_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub journalist {
    my ($self) = @_;
    my $content_text = $self->content_text;
    my ($txt) = $content_text =~ m{（記者／(\p{Letter}+)）\z};
    unless ($txt) {
        ($txt) = $content_text =~ m{\n（(中國時報／.+)）\z};
    }
    return $txt;
}

1;
