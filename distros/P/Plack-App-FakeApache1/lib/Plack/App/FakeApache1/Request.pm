package Plack::App::FakeApache1::Request;

{
  $Plack::App::FakeApache1::Request::DIST = 'Plack-App-FakeApache1';
}
$Plack::App::FakeApache1::Request::VERSION = '0.0.6';
# ABSTRACT: Mimic Apache1 requests
use Moose;

use HTTP::Status qw(:is :constants);
use Plack::Request;
use Plack::Response;
use Plack::App::FakeModPerl1::Dispatcher;

my $NS = "plack.app.fakeapache";

# Plack related attributes:
has env => (
    is       => 'ro',
    isa      => 'HashRef[Any]',
    required => 1,
);

has plack_request => (
    is         => 'ro',
    isa        => 'Plack::Request',
    lazy_build => 1,
    handles    => {
        method       => 'method',
        unparsed_uri => 'request_uri',
        uri          => 'path',
        user         => 'user',
    },
);

has plack_response => (
    is         => 'ro',
    isa        => 'Plack::Response',
    lazy_build => 1,
    handles    => {
        set_content_length  => 'content_length',
        content_type        => 'content_type',
        content_encoding    => 'content_encoding',
        status              => 'status',
    },
);

has dispatcher => (
    is          => 'ro',
    lazy_build  => 1,
);

# Apache related attributes
has dir_config => (
    isa     => 'HashRef[Any]',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        dir_config => 'accessor'
    }
);

has location => (
    is      => 'rw',
    isa     => "Str",
    default => '/',
);

has headers_out => (
    isa         => 'Moose::APR::Table',
    is          => 'ro',
    lazy_build  => 1,
);

has err_headers_out => (
    isa         => 'Moose::APR::Table',
    is          => 'ro',
    lazy_build  => 1,
);

has _subprocess_env => (
    isa         => 'Moose::APR::Table',
    is          => 'ro',
    lazy_build  => 1,
);

no Moose;

# builders
sub _build_plack_request  { return Plack::Request->new( shift->env ) }
sub _build_plack_response { return Plack::Response->new( HTTP_OK, {}, [] ) }
#sub _build__apr_pool      { return APR::Pool->new() }
sub _build_headers_out     { return Moose::APR::Table->new; }
sub _build_err_headers_out { return Moose::APR::Table->new; }
sub _build__subprocess_env { return Moose::APR::Table->new; }
sub _build_dispatcher      { return Plack::App::FakeModPerl1::Dispatcher->new; }

# Plack methods
sub finalize {
    my $self     = shift;
    my $response = $self->plack_response;

    $self->    headers_out->do( sub { $response->header( @_ ); 1 } ) if is_success( $self->status() );
    $self->err_headers_out->do( sub { $response->header( @_ ); 1 } );

    return $response->finalize;
};

# Apache methods
sub subprocess_env {
    my $self = shift;

    return $self->_subprocess_env->get( @_ )
        if (@_ == 1);

    return $self->_subprocess_env->set( @_ )
        if (@_ == 2);

    return $self->_subprocess_env
        if (defined wantarray);

    $self->_subprocess_env->do( sub { $ENV{ $_[0] } = $_[1]; 1 } );
    return;
}

sub print {
    my $self = shift;

    my $length = 0;
    for (@_) {
        $self->_add_content($_);
        $length += length;
    }

    return $length;
}

sub _add_content {
    my $self = shift;

    push @{ $self->plack_response->body }, @_;
}

sub rflush { 1; }

__PACKAGE__->meta->make_immutable;
1;


package Moose::APR::Table;

{
  $Moose::APR::Table::DIST = 'Plack-App-FakeApache1';
}
$Moose::APR::Table::VERSION = '0.0.6';
use Moose;
no Moose;

sub set { 1; };
sub get { 2; };
sub  do { 3; };

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::FakeApache1::Request - Mimic Apache1 requests

=head1 VERSION

version 0.0.6

=head2 finalize

=head2 subprocess_env

=head2 print

=head2 rflush

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
