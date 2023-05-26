package MooX::Role::HTTP::Tiny;
use Moo::Role;
use Types::Standard qw< InstanceOf Maybe HashRef >;

our $VERSION = '0.94';

use URI;
use HTTP::Tiny;

=head1 NAME

MooX::Role::HTTP::Tiny - L<HTTP::Tiny> as a role for clients that use HTTP

=head1 SYNOPSIS

    package My::Client;
    use Moo;
    with qw< MooX::Role::HTTP::Tiny >;
    use JSON qw< encode_json >;

    # implent a call to the API of a webservice
    sub call {
        my $self = shift;
        my ($method, $path, $args) = @_;

        my $uri = $self->base_uri->clone;
        $uri->path($uri->path =~ m{ / $}x ? $uri->path . $path : $path)
            if $path;

        my @params = $args ? ({ content => encode_json($args) }) : ();
        if (uc($method) eq 'GET') {
            my $query = $self->www_form_urlencode($args);
            $uri->query($query);
            shift(@params);
        }

        printf STDERR ">>>>> %s => %s (%s) <<<<<\n", uc($method), $uri, "@params";
        my $response = $self->request(uc($method), $uri, @params);
        if (not $response->{success}) {
            die sprintf "ERROR: %s: %s\n", $response->{reason}, $response->{content};
        }
        return $response;
    }
    1;

    package My::API;
    use Moo;
    use Types::Standard qw< InstanceOf >;
    has client => (
        is       => 'ro',
        isa      => InstanceOf(['My::Client']),
        handles  => [qw< call >],
        required => 1,
    );
    sub fetch_stuff {
        my $self = shift;
        return $self->call(@_);
    }
    1;

    package main;
    use My::Client;
    use My::API;

    my $client = My::Client->new(
        base_uri => ' https://fastapi.metacpan.org/v1/release/_search'
    );
    my $api = My::API->new(client => $client);
    my $response = $api->fetch_stuff(get => '', {q => 'MooX-Role-HTTP-Tiny'});
    print $response->{content};

=head1 ATTRIBUTES

=over

=item B<base_uri> [REQUIRED] The base-uri to the webservice

The provided uri will be I<coerced> into a L<URI> instance.

=item B<ua> A (lazy build) instance of L<HTTP::Tiny>

When none is provided, L<Moo> will instantiate a L<HTTP::Tiny> with the extra
options provided in the C<ua_options> attribute whenever it is first needed.

The C<request> and C<www_form_urlencode> methods will be handled for the role.

=item B<ua_options> passed through to the constructor of L<HTTP::Tiny> on lazy-build

These options can only be passed to constructor of L<HTTP::Tiny>, so won't have
impact when an already instantiated C<ua> attribute is provided.

=back

=cut

has base_uri => (
    is       => 'ro',
    isa      => InstanceOf([ 'URI::http', 'URI::https' ]),
    coerce   => sub { return URI->new($_[0]); },
    required => 1,
);
has ua => (
    is      => 'lazy',
    isa     => InstanceOf(['HTTP::Tiny']),
    handles => [qw< request www_form_urlencode >],
);
has ua_options => (
    is      => 'ro',
    isa     => Maybe([HashRef]),
    default => undef
);

=head1 REQUIRES

The class that consumes this role needs to implement the method C<call()> as a
wrapper around C<HTTP::Tiny::request> to suit the remote API one is writing the
client for.

=cut

requires 'call';

=head1 DESCRIPTION

This role provides a basic HTTP useragent (based on L<HTTP::Tiny>) for classes
that want to implement a client to any webservice that uses the HTTP(S)
transport protocol.

Some best known protocols are I<XMLRPC>, I<JSONRPC> and I<REST>, and can be
implemented through the required C<call()> method.

=cut

sub _build_ua {
    my $self = shift;
    return HTTP::Tiny->new(
        agent => join('/', __PACKAGE__, $VERSION),
        (defined($self->ua_options) ? (%{ $self->ua_options }) : ()),
    );
}

use namespace::autoclean;
1;

=head1 COPYRIGHT

E<copy> MMXXI - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
