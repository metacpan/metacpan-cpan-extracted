package NewsExtractor::SiteSpecificExtractor::ETtoday;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub journalist {
    my ($self) = @_;
    my $text = $self->content_text;
    my @patterns = (
        qr{(?:\n|\A)(?:實習)? 記者 ([\p{Letter}、]+?) ／ (?:[\p{Letter}—]+)? (?:報導|編譯) \n}x,
        qr{(?:\n|\A)網搜小組／([\p{Letter}、]+)報導\n},
        qr{\b((?:圖、)?文／[\p{Letter}\p{Digit}]+)\n},
    );

    my $name;
    for my $pat (@patterns) {
        ($name) = $text =~ $pat;
        last if $name;
    }
    return $name;
}

1;
