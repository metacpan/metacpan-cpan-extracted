package NewsExtractor::SiteSpecificExtractor::www_bcc_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::SiteSpecificExtractor';

use Importer 'NewsExtractor::TextUtil' => 'html2text';

sub headline {
    my ($self) = @_;
    my $el = $self->dom->at('head > title');
    return $el->all_text;
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('div.tt27');
    my $txt = $el->all_text;
    $txt =~ s/\s+報導\z//;
    return $txt;
}

sub journalist {
    my ($self) = @_;
    my $content = $self->content_text;
    my ($o) = $content =~ m{。 [（\(] (\p{Letter}+?) 報導 [）\)] \n\n}x;
    unless ($o) {
        ($o) = $content =~ m{。 [（\(] 中廣記者 (\p{Letter}+?) [）\)] \z}x;
    }
    return $o;
}

sub content_text {
    my ($self) = @_;
    my $el;

    for $el ($self->dom->find('script, div.ft')->each) {
        $el->remove();
    }

    $el = $self->dom->at('#some-class-name');
    return html2text( $el->to_string );
}

1;
