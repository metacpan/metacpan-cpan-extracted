package Path::Dispatcher::Rule::Regex;
# ABSTRACT: predicate is a regular expression

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Types::Standard qw(RegexpRef);

extends 'Path::Dispatcher::Rule';

has regex => (
    is       => 'ro',
    isa      => RegexpRef,
    required => 1,
);

my $named_captures = $] > 5.010 ? eval 'sub { %+ }' : sub { };

sub _match {
    my $self = shift;
    my $path = shift;

    # davem++ http://www.nntp.perl.org/group/perl.perl5.porters/2013/03/msg200156.html
    if ($self->prefix) {
        eval q{$'};
    }

    return unless my @positional = $path->path =~ $self->regex;

    my %named = $named_captures->();

    my %extra;

    # only provide leftover if we need it. $' is slow, and it may be undef
    if ($self->prefix) {
        $extra{leftover} = eval q{$'};
        delete $extra{leftover} if !defined($extra{leftover});
    }

    return {
        positional_captures => \@positional,
        named_captures      => \%named,
        %extra,
    }
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Rule::Regex - predicate is a regular expression

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $rule = Path::Dispatcher::Rule::Regex->new(
        regex => qr{^/comment(s?)/(\d+)$},
        block => sub { display_comment(shift->pos(2)) },
    );

=head1 DESCRIPTION

Rules of this class use a regular expression to match against the path.

=head1 ATTRIBUTES

=head2 regex

The regular expression to match against the path. It works just as you'd expect!

The capture variables (C<$1>, C<$2>, etc) will be available in the match
object as C<< ->pos(1) >> etc. C<$`>, C<$&>, and C<$'> are not restored.

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
