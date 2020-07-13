package Path::Dispatcher::Role::Rules;
# ABSTRACT: "has a list of rules"

our $VERSION = '1.08';

use Moo::Role;
use Carp qw(confess);
use Types::Standard qw(ArrayRef);

has _rules => (
    is       => 'ro',
    isa      => ArrayRef,
    init_arg => 'rules',
    default  => sub { [] },
);

sub add_rule {
    my $self = shift;

    $_->isa('Path::Dispatcher::Rule')
        or confess "$_ is not a Path::Dispatcher::Rule"
            for @_;

    push @{ $self->{_rules} }, @_;
}

sub unshift_rule {
    my $self = shift;

    $_->isa('Path::Dispatcher::Rule')
        or confess "$_ is not a Path::Dispatcher::Rule"
            for @_;

    unshift @{ $self->{_rules} }, @_;
}

sub rules { @{ shift->{_rules} } }

no Moo::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Role::Rules - "has a list of rules"

=head1 VERSION

version 1.08

=head1 DESCRIPTION

Classes that compose this role get the following things:

=head1 ATTRIBUTES

=head2 _rules

=head1 METHODS

=head2 rules

=head2 add_rule

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
