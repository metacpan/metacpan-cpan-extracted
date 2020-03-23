package NewsExtractor::SiteSpecificExtractor::www_setn_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub journalist {
    my ($self) = @_;
    my $content_text = $self->content_text;
    my ($name) = $content_text =~ m{\b記者([\p{Letter}、]+?)／(?:\p{Letter}+?)報導\b};
    unless ($name) {
	($name) = $content_text =~ m{\b(?:娛樂|財經|政治|鄉民|社會|體育|生活|國際)中心／(\p{Letter}+?)報導\n};
    }
    my %exclude = map { $_ => 1 } qw(綜合 台北);
    return '' if $exclude{$name};
    return normalize_whitespace($name);
}

1;
