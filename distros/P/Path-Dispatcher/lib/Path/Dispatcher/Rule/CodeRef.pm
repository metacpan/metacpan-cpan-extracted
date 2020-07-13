package Path::Dispatcher::Rule::CodeRef;
# ABSTRACT: predicate is any subroutine

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Types::Standard qw(CodeRef);
extends 'Path::Dispatcher::Rule';

has matcher => (
    is       => 'ro',
    isa      => CodeRef,
    required => 1,
);

sub _match {
    my $self = shift;
    my $path = shift;

    local $_ = $path;
    return $self->matcher->($path);
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Rule::CodeRef - predicate is any subroutine

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $rule = Path::Dispatcher::Rule::CodeRef->new(
        matcher => sub { time % 2 },
        block => sub { warn "Odd time!" },
    );

    my $undef = $rule->match("foo"); # even time; no match :)

    my $match = $rule->match("foo"); # odd time; creates a Path::Dispatcher::Match

    $rule->run; # warns "Odd time!"

=head1 DESCRIPTION

Rules of this class can match arbitrarily complex values. This should be used
only when there is no other recourse, because there's no way we can inspect
how things match.

You're much better off creating a custom subclass of L<Path::Dispatcher::Rule>
if at all possible.

=head1 ATTRIBUTES

=head2 matcher

A coderef that returns C<undef> if there's no match, otherwise a list of
strings (the results).

The coderef receives the path object as its argument, and the path string as
C<$_>.

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
