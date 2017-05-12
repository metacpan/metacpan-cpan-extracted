
package Object::I18n::Storage::CDBI;
use strict;
use warnings;
use Carp;

sub new {
    my $class = shift;
    my ($obj, $method) = @_;
    my $self = bless {
        object      => $obj,
        method      => $method,
    }, $class;
    $self->init;
}

sub init {
    shift;
}

sub fetch {
    my $self = shift;
    my $i18n = $self->{object}->i18n;

    my $class   = $i18n->{class};
    my $oid     = $i18n->oid;
    my $method  = $self->{method};
    my $language= $i18n->language;

    my $cdbi_class = $self->{cdbi_class} or croak "cdbi_class undefined";
    my ($obj) = $cdbi_class->search(
        class       => $class,
        instance    => $oid,
        attr        => $method,
        language    => $language,
    ) or return;
    return $obj->data;
}

sub store {
    my $self = shift;
    my ($data) = @_;
    my $i18n = $self->{object}->i18n;

    my $class   = $i18n->{class};
    my $oid     = $i18n->oid;
    my $method  = $self->{method};
    my $language= $i18n->language;

    my $cdbi_class = $self->{cdbi_class} or croak "cdbi_class undefined";
    my ($obj) = $cdbi_class->find_or_create({
        class       => $class,
        instance    => $oid,
        attr        => $method,
        language    => $language,
    });
    die "could not get a '$cdbi_class' object to store into" unless $obj;
    $obj->data($data);
    $obj->update;
    return $obj->data if defined wantarray;
}

1;

