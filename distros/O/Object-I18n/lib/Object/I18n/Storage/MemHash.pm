
package Object::I18n::Storage::MemHash;
use strict;
use warnings;

my $memhash = {};

sub new {
    my $class = shift;
    my ($obj, $method) = @_;
    bless {
        object      => $obj,
        memstore    => $memhash,
        method      => $method,
    }, $class;
}

sub fetch {
    my $self = shift;
    my $i18n = $self->{object}->i18n;

    my $class   = $i18n->{class};
    my $oid     = $i18n->oid;
    my $method  = $self->{method};
    my $language= $i18n->language;
    return $memhash->{$class}{$oid}{$method}{$language};
}

sub store {
    my $self = shift;
    my ($data) = @_;
    my $i18n = $self->{object}->i18n;

    my $class   = $i18n->{class};
    my $oid     = $i18n->oid;
    my $method  = $self->{method};
    my $language= $i18n->language;
    $memhash->{$class}{$oid}{$method}{$language} = $data;
}

1;

