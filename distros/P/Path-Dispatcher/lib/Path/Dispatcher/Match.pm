package Path::Dispatcher::Match;
# ABSTRACT: the result of a successful rule match

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Type::Utils qw(class_type);
use Types::Standard qw(Str ArrayRef HashRef Undef);
use Path::Dispatcher::Path;
use Path::Dispatcher::Rule;

has path => (
    is       => 'ro',
    isa      => class_type('Path::Dispatcher::Path'),
    required => 1,
);

has leftover => (
    is  => 'ro',
    isa => Str,
);

has rule => (
    is       => 'ro',
    isa      => class_type('Path::Dispatcher::Rule'),
    required => 1,
    handles  => ['payload'],
);

has positional_captures => (
    is      => 'ro',
    isa     => ArrayRef[Str|Undef],
    default => sub { [] },
);

has named_captures => (
    is      => 'ro',
    isa     => HashRef[Str|Undef],
    default => sub { {} },
);

has parent => (
    is        => 'ro',
    isa      => class_type('Path::Dispatcher::Match'),
    predicate => 'has_parent',
);

sub run {
    my $self = shift;

    local $_ = $self->path;
    return scalar $self->rule->run($self, @_);
}

sub pos {
    my $self  = shift;
    my $index = shift;

    return undef if $index == 0;

    $index-- if $index > 0;

    return $self->positional_captures->[$index];
}

sub named {
    my $self = shift;
    my $key  = shift;
    return $self->named_captures->{$key};
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Match - the result of a successful rule match

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $rule = Path::Dispatcher::Rule::Tokens->new(
        tokens => [ 'attack', qr/^\w+$/ ],
        block  => sub {
            my $match = shift;
            attack($match->pos(2))
        },
    );

    my $match = $rule->match("attack dragon");

    # introspection
    $match->path                # "attack dragon"
    $match->leftover            # empty string (populated with prefix rules)
    $match->rule                # $rule
    $match->positional_captures # ["attack", "dragon"] (decided by the rule)
    $match->pos(1)              # "attack"
    $match->pos(2)              # "dragon"

    $match->run                 # attack("dragon")

=head1 DESCRIPTION

If a L<Path::Dispatcher::Rule> successfully matches a path, it creates one or
more C<Path::Dispatcher::Match> objects.

=head1 ATTRIBUTES

=head2 rule

The L<Path::Dispatcher::Rule> that created this match.

=head2 path

The path that the rule matched.

=head2 leftover

The rest of the path. This is populated when the rule matches a prefix of the
path.

=head2 positional_captures

Any positional captures generated by the rule. For example,
L<Path::Dispatcher::Rule::Regex> populates this with the capture variables.

=head2 named_captures

Any named captures generated by the rule. For example,
L<Path::Dispatcher::Rule::Regex> populates this with named captures.

=head2 parent

The parent match object, if applicable (which may be set if this match is the
child of, for exampl, a L<Path::Dispatcher::Rule::Under> prefix)

=head1 METHODS

=head2 run

Executes the rule's codeblock with the same arguments.

=head2 pos($i)

Returns the C<$i>th positional capture, 1-indexed.

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
