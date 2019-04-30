package OpenStack::MetaAPI::API::Service;

use strict;
use warnings;

use Moo;
use OpenStack::MetaAPI::API::Specs::Default ();

has 'auth'   => (is => 'ro', required => 1);
has 'name'   => (is => 'ro', required => 1);
has 'region' => (is => 'ro', required => 1);

has 'interface' => (is => 'ro', default => 'public'); # admin internal or public

has 'client' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;

        return $self->auth->service(
            $self->name,
            region    => $self->region,
            interface => $self->interface);
    },
    handles => [qw/endpoint get put post delete/]

);

has 'api' => (is => 'ro', required => 1)
  ;    # this is backreference to the mainapi so we can call other services

has 'api_specs' => (is => 'ro', lazy => 1, default => \&BUILD_api_specs);

## FIXME: this needs a refactor...
#   idea always strip the version from endpoint so we can add it to the uri later..
#   this would make uri consistent... and improve root_uri
has 'version' => ('is' => 'ro', lazy => 1, default => \&BUILD_version);
has 'version_prefix' => ('is' => 'ro');    # added to very routes [optional]

has 'methods' => (is => 'ro', default => sub { return {} });

sub BUILD {
    my ($self, $args) = @_;

    $self->api_specs->setup_api_methods_for_service($self);

    return;
}

sub BUILD_version {
    my ($self) = @_;

    my $url = $self->client->endpoint;
    if ($url =~ m{/(v[0-9\.]+)}) {
        return $1;
    }
    return 'default';
}

sub BUILD_api_specs {    # load specs
    my ($self) = @_;

    my $v = $self->version;
    $v =~ s{\.}{_};
    my $pkg =
      'OpenStack::MetaAPI::API::Specs::' . ucfirst($self->name) . '::' . $v;

    my $load = eval qq{ require $pkg; 1 };
    if ($load) {
        return $pkg->new();
    }

    # default void specs [ undefined ]
    #   we do not have to define all specs for now
    return OpenStack::MetaAPI::API::Specs::Default->new();
}

sub root_uri {
    my ($self, $uri) = @_;

    return unless defined $uri;

    return $uri if $uri =~ m{^v};    # already contains a version

    # endpoint already contains a version
    return if $self->endpoint && $self->endpoint =~ m{:[\d]/v}a;

    # append our prefix to the endpoint
    if ($self->version_prefix) {
        my $base = $self->version_prefix;
        $base .= '/' unless $uri =~ m{^/};
        $base .= $uri;
        return $base;
    }

    return $uri;
}

sub setup_method {
    my ($self, $name, $sub) = @_;

    die                unless ref $self;
    die "missing name" unless $name;
    die                unless ref $sub eq 'CODE';

    my $methods = $self->methods();
    die "Method '$name' already exists" if defined $methods->{$name};
    die "Function '$name' already exists for " . ref($self)
      if $self->can($name);

    $methods->{$name} = $sub;

    return 1;
}

### not sure how to overwrite 'can' method to let Moo/Class::XSAccessor see the methods
sub can_method {
    my ($self, $method) = @_;    # Not shift, using goto.

    #my $sub = UNIVERSAL::can($self, $method);
    my $sub = $self->can($method);

    if (not defined $sub && ref $self) {
        $sub = $self->methods()->{$method};
    }

    return $sub;                 # May be undefined.
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::API::Service

=head1 VERSION

version 0.003

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
