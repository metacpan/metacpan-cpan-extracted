# ABSTRACT: request class
package PONAPI::Client::Request;

use Moose::Role;

use JSON::MaybeXS qw< encode_json >;

use PONAPI::Utils::URI qw< to_uri >;

requires 'method';
requires 'path';

has 'uri_base' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => sub { '' },
);

sub BUILDARGS {
    my ( $class, %args ) = @_;
    $args{uri_base} =~ s|/$||
        if exists $args{uri_base} and defined $args{uri_base};
    return \%args;
}

sub request_params {
    my $self = shift;

    my $method = $self->method;

    my $template  = $self->uri_template;
    my $path_args = $self->path;
    (my $path     = $template) =~ s/
        \{
            ( [^}]+ )
        \}
    /
        my $placeholder = $1;
        if ( !exists $path_args->{$placeholder} ) {
            die "uri_template($template) has placeholder $placeholder, but that is not one of the request params for this class";
        }
        $path_args->{$placeholder}
    /xeg;

    return (
        method => $method,
        path   => $self->uri_base . $path,
        ( $method eq 'GET'
            ? ( query_string => $self->_build_query_string )
            : ( $self->can('data')
                  ? ( body => encode_json( { data => $self->data } ) )
                  : ()
              )
        )
    );
}

sub _build_query_string {
    my $self = shift;

    my %u;

    $u{filter} = $self->filter
        if $self->does('PONAPI::Client::Request::Role::HasFilter') and $self->has_filter;

    $u{fields} = $self->fields
        if $self->does('PONAPI::Client::Request::Role::HasFields') and $self->has_fields;

    $u{page} = $self->page
        if $self->does('PONAPI::Client::Request::Role::HasPage') and $self->has_page;

    $u{include} = $self->include
        if $self->does('PONAPI::Client::Request::Role::HasInclude') and $self->has_include;

    $u{sort} = $self->sort
        if $self->does('PONAPI::Client::Request::Role::HasSort') and $self->has_sort;

    return to_uri( \%u );
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Client::Request - request class

=head1 VERSION

version 0.002008

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
