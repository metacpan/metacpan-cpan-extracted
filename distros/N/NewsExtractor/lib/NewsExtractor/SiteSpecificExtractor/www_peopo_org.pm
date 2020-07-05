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
    my $dateline = $el->text;
    $dateline =~ s{\A ([0-9]{4})\.([0-9]{2})\.([0-9]{2}) \s+ ([0-9]{2}):([0-9]{2}) \z}{$1-$2-$3T$4:$5:00+08:00}x;
    return $dateline;
}

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at("div.user-infos > h3 > a");
    return $el->text;
}

1;
