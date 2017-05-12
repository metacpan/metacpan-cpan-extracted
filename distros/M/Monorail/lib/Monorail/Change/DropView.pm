package Monorail::Change::DropView;
$Monorail::Change::DropView::VERSION = '0.4';
use Moose;
use SQL::Translator::Schema::View;

with 'Monorail::Role::Change::StandardSQL';

has name   => (is => 'ro', isa => 'Str',           required => 1);

__PACKAGE__->meta->make_immutable;

sub as_hashref_keys {
    return qw/name/;
}

sub as_sql {
    my ($self) = @_;

    my $view = $self->as_sql_translator_view;

    return $self->producer->drop_view($view);
}

sub as_sql_translator_view {
    my ($self) = @_;

    return SQL::Translator::Schema::View->new(
        name   => $self->name,
    );
}

sub transform_schema {
    my ($self, $schema) = @_;

    $schema->drop_view($self->as_sql_translator_view);
}

1;
