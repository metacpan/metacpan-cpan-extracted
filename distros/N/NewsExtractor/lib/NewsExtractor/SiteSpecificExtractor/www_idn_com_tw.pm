package NewsExtractor::SiteSpecificExtractor::www_idn_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw<u normalize_whitespace >;

sub dateline {
    my ($self) = @_;
    my $text = $self->content_text;
    my ($yyyy, $mm, $dd) = $text =~ m{([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})$};
    return defined($yyyy) ? u(sprintf('%04d/%02d/%02d', $yyyy, $mm, $dd)) : undef;
}

1;
