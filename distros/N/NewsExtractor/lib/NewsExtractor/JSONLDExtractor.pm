package NewsExtractor::JSONLDExtractor;
use Moo;
extends 'NewsExtractor::TXExtractor';

use Mojo::Transaction::HTTP;
use Types::Standard qw( InstanceOf HashRef ArrayRef );
use Mojo::JSON qw(from_json);
use Importer 'NewsExtractor::TextUtil' => qw(u);

has tx => (
    required => 1, is => 'ro',
    isa => InstanceOf['Mojo::Transaction::HTTP'] );

has schema_ld => (
    required => 0,
    is => 'lazy',
    isa => HashRef,
    builder => 1,
);

sub _build_schema_ld {
    my ($self) = @_;
    my $el = $self->dom->at('script[type="application/ld+json"]') or return {};
    my $x = from_json( $el->text );
    if (HashRef->check($x)) {
        return $x;
    }
    if (ArrayRef->check($x)) {
        return $x->[0];
    }
    return {};
}

sub journalist {
    my ($self) = @_;
    return u($self->schema_ld->{author}{name});
}

sub headline {
    my ($self) = @_;
    return u($self->schema_ld->{headline});
}

sub dateline {
    my ($self) = @_;
    return u($self->schema_ld->{datePublished});
}

sub content_text {
    my ($self) = @_;
    my $text = $self->schema_ld->{articleBody} // $self->schema_ld->{description} // '';
    return u($text);
}

1;
