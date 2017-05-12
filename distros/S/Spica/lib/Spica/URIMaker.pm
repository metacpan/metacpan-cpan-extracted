package Spica::URIMaker;
use strict;
use warnings;
use utf8;

use Clone qw(clone);
use URI;

use Mouse;

has scheme => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http',
);

has host => (
    is  => 'ro',
    isa => 'Str',
);

has port => (
    is  => 'ro',
    isa => 'Int',
);

has path_base => (
    is  => 'rw',
    isa => 'Str',
);

has path => (
    is  => 'ro',
    isa => 'Str',
);

has requires => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

has param => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
);

has content => (
    is  => 'rw',
    isa => 'Str',
);

has uri => (
    is         => 'ro',
    isa        => 'URI',
    lazy_build => 1,
    handles    => +{
        as_string => 'as_string',
    },
);

no Mouse;

sub create {
    my ($self, %args) = @_;

    if (my @invalid_params = $self->is_invalid_param($args{param}, $args{requires})) {
        Carp::croak(sprintf('Invalid parameters. %s is required.', join(', ' => @invalid_params)));
    }

    $self->create_path($args{path_base}, $args{param});
    $self;
}

sub create_path {
    my ($self, $path_base, $param) = @_;

    if (!$path_base) {
        Carp::croak("Invalid args `path_base`.");
    }
    $param ||= +{};

    if ($path_base =~ /\{(?:[0-9a-zA-Z_]+)\}/) {
        for my $column (keys %$param) {
            my $pattern = qr!\{$column\}!;
            next unless $path_base =~ $pattern;

            # TODO: クエリパラメータには不要なはずなのでdel
            my $value = delete $param->{$column};
            $path_base =~ s/$pattern/$value/;
        }
    }

    $self->{path}  = $path_base;
    $self->{param} = $param;

    $self->uri->path($self->path);

    return $self;
}

sub create_query {
    my $self = shift;

    $self->uri->query_form($self->param);

    return $self;
}

sub is_invalid_param {
    my ($self, $param, $requires) = @_;
    return grep { !exists $param->{$_} || !defined $param->{$_} } @{ $requires || [] };
}

sub new_uri {
    my $self = shift;
    return clone $self;
}

sub _build_uri {
    my $self = shift;
    my $uri = ($self->scheme && $self->host)
        ? URI->new(sprintf '%s://%s', $self->scheme, $self->host)
        : URI->new
        ;

    $uri->port($self->port) if $self->port && $uri->scheme ne 'https';

    return $uri;
}

1;
__END__

=encoding utf-8

=head1 NAME

Spica::URIMaker

=head1 SYNOPSIS

    my $builder = Spica::URIMaker->new(
        scheme => 'http',
        host   => 'example.com',
    );

    $builder->create(
        path_base => '/user/{user_id}',
        requires  => [qw(user_id)],
        param     => +{user_id => 1},
    );

    $builder->as_string; # http://example.com/user/1

=head1 DESCRIPTION

=head1 METHODS

=head2 Spica::URIMaker->new(%args)

arguments be:

=over

=item scheme

=item host

=item port

=back

=head2 $maker->create(%args)

arguments be:

=over

=item path_base

=item requires

=item param

=back

=head2 $maker->create_path($path_base, \%param)

=head2 $maker->create_query

=head2 $maker->is_invalid_param(\%param, \@requires)

=head2 $maker->new_uri

=head2 $maker->param

=head2 $maker->path

=head2 $maker->content

=head2 $maker->uri

=head2 $maker->as_string

=cut
