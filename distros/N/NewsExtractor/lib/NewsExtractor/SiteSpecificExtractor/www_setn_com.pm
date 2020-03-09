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
	($name) = $content_text =~ m{\b生活中心／(\p{Letter}+?)報導\n};
    }
    return normalize_whitespace($name);
}

1;
