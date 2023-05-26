package MooX::Role::REST;
use Moo::Role;

with qw<
    MooX::Role::HTTP::Tiny
    MooX::Params::CompiledValidators
>;

use JSON;
use Types::Standard qw< Enum HashRef InstanceOf Maybe Str >;

our $VERSION = '0.001';
our $DEBUG = 0;

=head1 NAME

MooX::Role::REST - Simple HTTP client for JSON-REST as a Moo::Role

=head1 ATTRIBUTES

These are inherited from L<MooX::Role::HTTP::Tiny>:

=head2 base_uri [Required]

The base URI for the REST-API.

=head2 ua [Lazy]

Instantiated L<HTTP::Tiny> instance. Will be created once needed.

=head2 ua_options [Optional]

The contents of this HashRef will be passed to the constructor for
L<HTTP::Tiny> (in case of I<lazy> construction).

=cut

=head1 SYNOPSIS

    package My::Client;
    use Moo;
    with qw< MooX::Role::REST >;
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
    sub search_release {
        my $self = shift;
        my ($query) = @_;
        $query =~ s{ :: }{-}xg;
        return $self->call(GET => 'release/_search', { q => $query });
    }
    1;

    package main;
    use warnings;
    use v5.14.0; # strict + feature
    use Data::Dumper;

    # Show request/response on STDERR
    { no warnings 'once'; $MooX::Role::REST::DEBUG = 1; }

    my $client = My::Client->new(base_uri => 'https://fastapi.metacpan.org/v1/');
    my $api = My::API->new(client => $client);

    say Dumper($api->search_release('MooX::Params::CompiledValidators'));

=head1 DESCRIPTION

Helper role to implement a simple REST client with JSON.

=head2 call

Mandatory method that implements the actual HTTP stuff.

=cut

sub call {
    my $self = shift;
    $self->validate_positional_parameters(
        [
            $self->parameter(http_method => $self->Required, { store => \my $hmethod }),
            $self->parameter(call_path   => $self->Required, { store => \my $cpath }),
            $self->parameter(call_data   => $self->Optional, { store => \my $cdata }),
        ],
        \@_
    );

    my $endpoint = $self->base_uri->clone;
    (my $path = $endpoint->path) =~ s{/+$}{};
    $path = $cpath =~ m{^ / }x ? $cpath : "$path/$cpath";
    $endpoint->path($path);

    my @body;
    # GET and DELETE have no body
    if ($hmethod =~ m{^ (?: GET | DELETE ) $}x) {
        my $params = $cdata ? $self->www_form_urlencode($cdata) : '';
        $endpoint->query($params) if $params;
    }
    else {
        @body = $cdata ? { content => encode_json($cdata) } : ();
    }

    print STDERR ">>>$hmethod($endpoint)>>>@body<<<\n"
        if $DEBUG;
    my $response = $self->request($hmethod, $endpoint->as_string, @body);

    use Data::Dumper; local($Data::Dumper::Indent, $Data::Dumper::Sortkeys) = (1, 1);
    print STDERR ">>>" . Dumper($response) . "<<<\n" if $DEBUG;

    my ($ct) = split(m{\s*;\s*}, $response->{headers}{'content-type'}, 2);
    if (! $response->{success}) {
        my $error = "$response->{status} ($response->{reason})";
        if ($response->{content}) {
            $error .= " - " . ($ct eq 'application/json'
                ? decode_json($response->{content})
                : $response->{content});
        }
        my (undef, $f, $l) = caller(0); # poor mans Carp
        die "Error $hmethod($endpoint): $error at $f line $l\n";
    }

    return $ct eq 'application/json'
        ? decode_json($response->{content})
        : $response->{content};
}

=head2 ValidationTemplates

Validation templates for the C<call()> method.

=over

=item http_method => Enum< GET POST PUT DELETE PATCH >

=item call_path => Str

=item call_data => Maybe[HashRef]

=back

=cut

sub ValidationTemplates {
    return {
        http_method => { type => Enum [qw< GET POST PUT DELETE PATCH >] },
        call_path   => { type => Str },
        call_data   => { type => Maybe [HashRef] },
    };
}

use namespace::autoclean;
1;

=head1 COPYRIGHT

E<copy> MMXXIII - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
