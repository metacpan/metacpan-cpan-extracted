package Path::Dispatcher::Rule::Metadata;
# ABSTRACT: match path's metadata

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Type::Utils qw(class_type);
use Types::Standard qw(Str);
extends 'Path::Dispatcher::Rule';

has field => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has matcher => (
    is       => 'ro',
    isa      => class_type("Path::Dispatcher::Rule"),
    required => 1,
);

sub _match {
    my $self = shift;
    my $path = shift;
    my $got = $path->get_metadata($self->field);

    # wow, offensive.. but powerful
    my $metadata_path = $path->clone_path($got);
    return unless $self->matcher->match($metadata_path);

    return {
        leftover => $path->path,
    };
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Rule::Metadata - match path's metadata

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $path = Path::Dispatcher::Path->new(
        path => '/REST/Ticket'
        metadata => {
            http_method => 'POST',
        },
    );

    my $rule = Path::Dispatcher::Rule::Metadata->new(
        field   => 'http_method',
        matcher => Path::Dispatcher::Rule::Eq->new(string => 'POST'),
    );

    $rule->run($path);

=head1 DESCRIPTION

Rules of this class match the metadata portion of a path.

=head1 ATTRIBUTES

=head2 field

The metadata field/key name.

=head2 matcher

A L<Path::Dispatcher::Rule> object for matching against the value of the field.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Path-Dispatcher>
(or L<bug-Path-Dispatcher@rt.cpan.org|mailto:bug-Path-Dispatcher@rt.cpan.org>).

=head1 AUTHOR

Shawn M Moore, C<< <sartak at bestpractical.com> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
