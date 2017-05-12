package MooseX::MultiMethods;
our $VERSION = '0.10';
# ABSTRACT: Multi Method Dispatch based on Moose type constraints

use Moose;
use Devel::Declare ();
use MooseX::Method::Signatures;
use Sub::Install qw/install_sub/;
use MooseX::Types::Moose qw/HashRef ClassName/;
use aliased 'Devel::Declare::Context::Simple' => 'DDContext';
use aliased 'MooseX::MultiMethods::Meta::Method' => 'MetaMethod';

use namespace::autoclean;


has _dd_context => (
    is      => 'ro',
    isa     => DDContext,
    lazy    => 1,
    builder => '_build_dd_context',
    handles => qr/.*/,
);

has _dd_init_args => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

has class => (
    is       => 'ro',
    isa      => ClassName,
    required => 1,
);

method BUILD ($args) {
    $self->_dd_init_args($args);
}

method _build_dd_context {
    return DDContext->new(%{ $self->_dd_init_args });
}

method import (ClassName $class:) {
    my $setup_class = caller;
    $class->setup_for($setup_class);
}

method setup_for (ClassName $class: ClassName $setup_class, HashRef $args = {}) {
    Devel::Declare->setup_for($setup_class, {
        'multi' => {
            const => sub {
                my $self = $class->new({ class => $setup_class, %{ $args } });
                $self->init(@_);
                return $self->parse;
            },
        },
    });

    install_sub({
        code => sub {},
        into => $setup_class,
        as   => 'multi',
    });

    MooseX::Method::Signatures->setup_for($setup_class)
        unless $setup_class->can('method');
}

method parse {
    $self->skip_declarator;
    $self->skipspace;

    my $thing = $self->strip_name;
    confess "expected 'method', got '${thing}'"
        unless $thing eq 'method';

    $self->skipspace;

    my $name = $self->strip_name;
    confess "anonymous multi methods not allowed"
        unless defined $name && length $name;

    my $proto = $self->strip_proto || '';
    my $proto_variant = MooseX::Method::Signatures::Meta::Method->wrap(
        signature    => "(${proto})",
        package_name => $self->get_curstash_name,
        name         => $name,
    );

    $self->inject_if_block($self->scope_injector_call . $proto_variant->injectable_code, 'sub');

    my $meta = Class::MOP::class_of($self->class);
    my $meta_method = $meta->get_method($name);
    unless ($meta_method) {
        $meta_method = MetaMethod->new(
            name         => $name,
            package_name => $self->class,
        );
        $meta->add_method($name => $meta_method);
    }

    confess "method '${name}' is already defined"
        unless $meta_method->isa(MetaMethod);

    $self->shadow(sub {
        my $variant = $proto_variant->reify(actual_body => $_[0]);
        $meta_method->add_variant($variant->type_constraint => $variant);
    });
}

1;

__END__
=pod

=head1 NAME

MooseX::MultiMethods - Multi Method Dispatch based on Moose type constraints

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    package Paper;    use Moose;
    package Scissors; use Moose;
    package Rock;     use Moose;
    package Lizard;   use Moose;
    package Spock;    use Moose;

    package Game;
    use Moose;
    use MooseX::MultiMethods;

    multi method play (Paper    $x, Rock     $y) { 1 }
    multi method play (Paper    $x, Spock    $y) { 1 }
    multi method play (Scissors $x, Paper    $y) { 1 }
    multi method play (Scissors $x, Lizard   $y) { 1 }
    multi method play (Rock     $x, Scissors $y) { 1 }
    multi method play (Rock     $x, Lizard   $y) { 1 }
    multi method play (Lizard   $x, Paper    $y) { 1 }
    multi method play (Lizard   $x, Spock    $y) { 1 }
    multi method play (Spock    $x, Rock     $y) { 1 }
    multi method play (Spock    $x, Scissors $y) { 1 }
    multi method play (Any      $x, Any      $y) { 0 }

    my $game = Game->new;
    $game->play(Paper->new, Rock->new);     # 1, Paper covers Rock
    $game->play(Spock->new, Paper->new);    # 0, Paper disproves Spock
    $game->play(Spock->new, Scissors->new); # 1, Spock smashes Scissors

=head1 DESCRIPTION

This module provides multi method dispatch based on Moose type constraints. It
does so by providing a C<multi> keyword that extends the C<method> keyword
provided by L<MooseX::Method::Signatures|MooseX::Method::Signatures>.

When invoking a method declared as C<multi> a matching variant is being
searched in all the declared multi variants based on the passed parameters and
the declared type constraints. If a variant has been found, it will be invoked.
If no variant could be found, an exception will be thrown.

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

