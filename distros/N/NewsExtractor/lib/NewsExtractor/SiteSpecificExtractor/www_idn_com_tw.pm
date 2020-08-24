package NewsExtractor::SiteSpecificExtractor::www_idn_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw< reformat_dateline >;

sub dateline {
    my ($self) = @_;
    my $text = $self->content_text;
    my ($ymd) = $text =~ m{ ( [0-9]{4}/[0-9]{1,2}/[0-9]{1,2} ) [\)）]?\z}x;
    return $ymd ? reformat_dateline( $ymd, '+08:00' ) : undef;
}

1;
