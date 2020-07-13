package Path::Dispatcher::Path;
# ABSTRACT: path and some optional metadata

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Types::Standard qw(Str HashRef);
use overload q{""} => sub { shift->path };

has path => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_path',
);

has metadata => (
    is        => 'ro',
    isa       => HashRef,
    predicate => 'has_metadata',
);

# allow Path::Dispatcher::Path->new($path)
around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    if (@_ == 1 && !ref($_[0])) {
        unshift @_, 'path';
    }

    $self->$orig(@_);
};

sub clone_path {
    my $self = shift;
    my $path = shift;

    return $self->new({ %$self, path => $path, @_ });
}

sub get_metadata {
    my $self = shift;
    my $name = shift;

    return $self->metadata->{$name};
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Path - path and some optional metadata

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $path = Path::Dispatcher::Path->new(
        path     => "/REST/Ticket/1",
        metadata => {
            http_method => "DELETE",
        },
    );

    $path->path;                        # /REST/Ticket/1
    $path->get_metadata("http_method"); # DELETE

=head1 ATTRIBUTES

=head2 path

A string representing the path. C<Path::Dispatcher::Path> is basically a boxed
string. :)

=head2 metadata

A hash representing arbitrary metadata. The L<Path::Dispatcher::Rule::Metadata>
rule is designed to match against members of this hash.

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
