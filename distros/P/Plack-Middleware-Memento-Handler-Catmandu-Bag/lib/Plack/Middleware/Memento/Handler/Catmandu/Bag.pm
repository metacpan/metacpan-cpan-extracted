package Plack::Middleware::Memento::Handler::Catmandu::Bag;

use Catmandu::Sane;

our $VERSION = '0.01';

use Catmandu;
use Catmandu::Util qw(is_string is_instance);
use DateTime::Format::ISO8601;
use Moo;
use namespace::clean;

with 'Plack::Middleware::Memento::Handler';

has store => (is => 'ro');
has bag   => (is => 'ro'); # TODO type check
has _bag  => (is => 'lazy');
has _iso8601_date => (is => 'lazy');

sub _build__bag {
    my ($self) = @_;
    Catmandu->store($self->store)->bag($self->bag);
}

sub _build__iso8601_date {
    DateTime::Format::ISO8601->new;
}

sub get_all_mementos {
    my ($self, $uri_r, $req) = @_;

    my ($id) = $uri_r =~ m|([^/]+)$|;
    is_string($id) || return;

    my $bag = $self->_bag;
    my $versions = $bag->get_history($id) || return;

    [ map {
        my $version = $_;
        my $dt = $self->_iso8601_date->parse_datetime($version->{$bag->datestamp_updated_key});
        my $id = $version->{$bag->id_key};
        my $version_id = $version->{$bag->version_key};
        my $uri_m = $req->base;
        $uri_m->path("$id/versions/$version_id");
        [$uri_m->canonical->as_string, $dt];
    } @$versions ];
}

sub wrap_memento_request {
    my ($self, $req) = @_;

    my ($id, $version_id) = $req->path =~ m|^/([^/]+)/versions/([^/]+)$|;
    is_string($id) || return;
    is_string($version_id) || return;

    my $bag = $self->_bag;
    my $version = $bag->get_version($id, $version_id) || return;
    my $dt = $self->_iso8601_date->parse_datetime($version->{$bag->datestamp_updated_key});
    my $uri_r = $req->base;
    $uri_r->path($id);
    return $uri_r->canonical->as_string, $dt;
}

sub wrap_original_resource_request {
    my ($self, $req) = @_;

    my ($id) = $req->path =~ m|^/([^/]+)$|;
    is_string($id);
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Memento::Handler::Catmandu::Bag - Connect Plack::App::Catmandu::Bag to Plack::Middleware::Memento

=head1 SYNOPSIS

    builder {
      enable 'Memento', handler => 'Catmandu::Bag', store => 'mystore', bag => 'mybag';
      $app
    };

=head1 AUTHOR

Nicolas Steenlant E<lt>nicolas.steenlant@ugent.beE<gt>

=cut
