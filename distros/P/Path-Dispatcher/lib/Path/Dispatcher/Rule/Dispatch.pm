package Path::Dispatcher::Rule::Dispatch;
# ABSTRACT: redispatch

our $VERSION = '1.08';

use Moo;
use MooX::TypeTiny;
use Type::Utils qw(class_type);

extends 'Path::Dispatcher::Rule';

has dispatcher => (
    is       => 'ro',
    isa      => class_type("Path::Dispatcher"),
    required => 1,
    handles  => ['rules', 'complete'],
);

sub match {
    my $self = shift;
    my $path = shift;

    my $dispatch = $self->dispatcher->dispatch($path);
    return $dispatch->matches;
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Rule::Dispatch - redispatch

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $dispatcher = Path::Dispatcher->new(
        rules => [
            Path::Dispatcher::Rule::Tokens->new(
                tokens => [ 'help' ],
                block  => sub { show_help },
            ),
            Path::Dispatcher::Rule::Tokens->new(
                tokens => [ 'quit' ],
                block  => sub { exit },
            ),
        ],
    );

    my $rule = Path::Dispatcher::Rule::Dispatch->new(
        dispatcher => $dispatcher,
    );

    $rule->run("help");

=head1 DESCRIPTION

Rules of this class use another dispatcher to match the path.

=head1 ATTRIBUTES

=head2 dispatcher

A L<Path::Dispatcher> object. Its matches will be returned by matching this
rule.

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
