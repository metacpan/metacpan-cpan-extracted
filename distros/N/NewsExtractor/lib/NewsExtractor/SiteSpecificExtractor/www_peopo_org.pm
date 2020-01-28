package NewsExtractor::SiteSpecificExtractor::www_peopo_org;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

sub headline {
    my ($self) = @_;
    my $el = $self->dom->at("h1.page-title");
    return $el->text;
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at("div.submitted > span");
    return $el->text;
}

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at("div.user-infos > h3 > a");
    return $el->text;
}

1;
