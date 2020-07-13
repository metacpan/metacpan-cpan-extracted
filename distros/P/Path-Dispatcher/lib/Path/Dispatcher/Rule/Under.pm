package Path::Dispatcher::Rule::Under;
# ABSTRACT: rules under a predicate

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Type::Tiny;
use Type::Utils qw(class_type);

extends 'Path::Dispatcher::Rule';
with 'Path::Dispatcher::Role::Rules';

my $PREFIX_RULE_TYPE = "Type::Tiny"->new(
    name       => "PrefixRule",
    parent     => class_type("Path::Dispatcher::Rule"),
    constraint => sub { return ( shift()->prefix ) ? 1 : 0 },
    message    => sub { "This rule ($_) does not match just prefixes!" },
);

has predicate => (
    is  => 'ro',
    isa => $PREFIX_RULE_TYPE
);

sub match {
    my $self = shift;
    my $path = shift;

    my $prefix_match = $self->predicate->match($path)
        or return;

    my $leftover = $prefix_match->leftover;
    $leftover = '' if !defined($leftover);

    my $new_path = $path->clone_path($leftover);

    # Pop off @matches until we have a last rule that is not ::Chain
    #
    # A better technique than isa might be to use the concept of 'endpoint', 'midpoint', or 'anypoint' rules and
    # add a method to ::Rule that lets evaluate whether any rule is of the right kind (i.e. ->is_endpoint)
    #
    # Because the checking for ::Chain endpointedness is here, this means that outside of an ::Under, ::Chain behaves like
    # an ::Always (one that will always trigger next_rule if it's block is ran)
    #
    my @matches = map {
        $_->match(
            $new_path,
            extra_constructor_args => {
                parent => $prefix_match,
            },
        )
    } $self->rules;
    pop @matches while @matches && $matches[-1]->rule->isa('Path::Dispatcher::Rule::Chain');
    return @matches;
}

sub complete {
    my $self = shift;
    my $path = shift;

    my $predicate = $self->predicate;

    my $prefix_match = $predicate->match($path)
        or return $predicate->complete($path);

    my $new_path = $path->clone_path($prefix_match->leftover);

    my $prefix = substr($path->path, 0, length($path->path) - length($new_path->path));

    my @completions = map { $_->complete($new_path) } $self->rules;

    if ($predicate->can('untokenize')) {
        return map { $predicate->untokenize($prefix, $_) } @completions;
    }
    else {
        return map { "$prefix$_" } @completions;
    }
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Rule::Under - rules under a predicate

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $ticket = Path::Dispatcher::Rule::Tokens->new(
        tokens => [ 'ticket' ],
        prefix => 1,
    );

    my $create = Path::Dispatcher::Rule::Tokens->new(
        tokens => [ 'create' ],
        block  => sub { create_ticket() },
    );

    my $delete = Path::Dispatcher::Rule::Tokens->new(
        tokens => [ 'delete', qr/^\d+$/ ],
        block  => sub { delete_ticket(shift->pos(2)) },
    );

    my $rule = Path::Dispatcher::Rule::Under->new(
        predicate => $ticket,
        rules     => [ $create, $delete ],
    );

    $rule->match("ticket create");
    $rule->match("ticket delete 3");

=head1 DESCRIPTION

Rules of this class have two-phase matching: if the predicate is matched, then
the contained rules are matched. The benefit of this is less repetition of the
predicate, both in terms of code and in matching it.

=head1 ATTRIBUTES

=head2 predicate

A rule (which I<must> match prefixes) whose match determines whether the
contained rules are considered. The leftover path of the predicate is used
as the path for the contained rules.

=head2 rules

A list of rules that will be try to be matched only if the predicate is
matched.

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
