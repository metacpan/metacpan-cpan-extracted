package NewsExtractor::SiteSpecificExtractor::turnnewsapp_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub journalist {
    my ($self) = @_;
    my $text = $self->content_text;
    my @patterns = (
        qr{（記者／?(\p{Letter}+)）\z},
        qr{\n（(中國時報／.+)）(?:\n|\z)},
        qr{（(記者／.+?)）\z},
        qr{（(特派員.+?)）\z},
    );

    my $name;
    for my $pat (@patterns) {
        ($name) = $text =~ $pat;
        last if $name;
    }
    return $name;
}

1;
