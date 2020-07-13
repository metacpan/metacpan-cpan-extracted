package Path::Dispatcher::Rule::Empty;
# ABSTRACT: matches only the empty path

our $VERSION = '1.08';

use Moo;
extends 'Path::Dispatcher::Rule';

sub _match {
    my $self = shift;
    my $path = shift;
    return if length $path->path;
    return { leftover => $path->path };
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Rule::Empty - matches only the empty path

=head1 VERSION

version 1.08

=head1 DESCRIPTION

Rules of this class match only the empty path.

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
