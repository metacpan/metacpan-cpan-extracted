package Regru::API::Role::Client;

# ABSTRACT: something that makes requests to API

use strict;
use warnings;
use Moo::Role;
use Regru::API::Response;
use namespace::autoclean;
use Carp;

our $VERSION = '0.051'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

with qw(
    Regru::API::Role::Namespace
    Regru::API::Role::Serializer
    Regru::API::Role::UserAgent
    Regru::API::Role::Loggable
);

has username => (
    is          => 'rw',
    required    => 1,
    predicate   => 'has_username',
);
has password => (
    is          => 'rw',
    required    => 1,
    predicate   => 'has_password',
);
has io_encoding => (
    is          => 'rw',
    isa         => sub {
        my %valid = map { ($_ => 1) } qw(utf8 cp1251 cp866 koi8-r koi8-u);
        croak "Empty encoding value"            unless $_[0];
        croak "Unsupported encoding: $_[0]"     unless exists $valid{$_[0]};
    },
    predicate   => 'has_io_encoding',
);
has lang => (
    is          => 'rw',
    isa         => sub {
        my %valid = map { ($_ => 1) } qw(en ru th);
        croak "Empty language value"            unless $_[0];
        croak "Unsupported language: $_[0]"     unless exists $valid{$_[0]};
    },
    predicate   => 'has_lang',
);
has debug => (
    is        => 'rw',
    predicate => 'has_debug',
);

has namespace   => (
    is      => 'ro',
    default => sub { '' },
);

has endpoint => (
    is      => 'ro',
    default => sub { $ENV{REGRU_API_ENDPOINT} || 'https://api.reg.ru/api/regru2' },
);

sub namespace_methods {
    my $class = shift;

    my $meta = $class->meta;

    foreach my $method ( @{ $class->available_methods } ) {
        $method = lc $method;
        $method =~ s/\s/_/g;

        my $handler = sub {
            my ($self, @args) = @_;
            $self->api_request($method => @args);
        };

        $meta->add_method($method => $handler);
    }
}

sub api_request {
    my ($self, $method, %params) = @_;

    my $url = join '' => $self->endpoint,
                         $self->to_namespace(delete $params{namespace}), # compose namespace part
                        ($method ? '/' . $method : '');

    # protect I/O formats against modifying
    delete $params{output_format};
    delete $params{input_format};

    my %post_params = (
        username      => $self->username,
        password      => $self->password,
        output_format => 'json',
        input_format  => 'json',
    );

    $post_params{lang}          = $self->lang           if $self->has_lang;
    $post_params{io_encoding}   = $self->io_encoding    if $self->has_io_encoding;

    $self->debug_warn('API request:', $url, "\n", 'with params:', \%params) if $self->debug;

    my $json = $self->serializer->encode( \%params );

    my $response = $self->useragent->post(
        $url,
        [ %post_params, input_data => $json ]
    );

    return Regru::API::Response->new( response => $response, debug => $self->debug );
}

sub to_namespace {
    my ($self, $namespace) = @_;

    $namespace = $namespace || $self->namespace || undef;

    return $namespace ? '/' . $namespace : '';
}

1; # End of Regru::API::Role::Client

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Role::Client - something that makes requests to API

=head1 VERSION

version 0.051

=head1 SYNOPSIS

    # in some namespace package
    package Regru::API::Dummy;

    use strict;
    use warnings;
    use Moo;

    with 'Regru::API::Role::Client';

    has '+namespace' => (
        default => sub { 'dummy' },
    );

    sub available_methods {[qw(foo bar baz)]}

    __PACKAGE__->namespace_methods;
    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Any class or role that consumes this role will able to execute requests to REG.API v2.

=head1 ATTRIBUTES

=head2 username

Account name of the user to access to L<reg.com|https://www.reg.com> website. Required. Should be passed at instance
create time. Although it might be changed at runtime.

=head2 password

Account password of the user to access to L<reg.com|https://www.reg.com> website or an alternative password for API
defined at L<Reseller settings|https://www.reg.com/reseller/details> page. Required. Should be passed at instance create time.
Although it might be changed at runtime.

=head2 io_encoding

Defines encoding that will be used for data exchange between the Service and the Client. At the moment REG.API v2
supports the following encodings: C<utf8>, C<cp1251>, C<koi8-r>, C<koi8-u>, C<cp866>. Optional. Default value is B<utf8>.

=head2 lang

Defines the language which will be used in error messages. At the moment REG.API v2 supports the following languages:
C<en> (English), C<ru> (Russian) and C<th> (Thai). Optional. Default value is B<en>.

=head2 debug

A few messages will be printed to STDERR. Default value is B<0> (suppressed debug activity).

=head2 namespace

Used internally.

=head2 endpoint

REG.API v2 endpoint url. There's no needs to change it. Although it might be overridden by setting environment variable:

    export REGRU_API_ENDPOINT=https://api.example.com

Default value is

    https://api.reg.ru/api/regru2

=head1 METHODS

=head2 namespace_methods

Dynamically creates methods-shortcuts in in namespaces (categories) for requests to appropriate REG.API v2 functions.

=head2 api_request

Performs an API request to REG.API service. Returns a L<Regru::API::Response> object.

=head2 to_namespace

Used internally.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Namespace>

L<Regru::API::Role::Serializer>

L<Regru::API::Role::UserAgent>

L<Regru::API::Role::Loggable>

L<Regru::API::Response>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/regru/regru-api-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Polina Shubina <shubina@reg.ru>

=item *

Anton Gerasimov <a.gerasimov@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
