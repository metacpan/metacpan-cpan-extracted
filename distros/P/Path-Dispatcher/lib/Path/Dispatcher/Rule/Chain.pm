package Path::Dispatcher::Rule::Chain;
# ABSTRACT: Chain rules for Path::Dispatcher

our $VERSION = '1.08';

use Moo;
extends 'Path::Dispatcher::Rule::Always';

around payload => sub {
    my $orig    = shift;
    my $self    = shift;
    my $payload = $self->$orig(@_);

    if (!@_) {
        return sub {
            $payload->(@_);
            die "Path::Dispatcher next rule\n"; # FIXME From Path::Dispatcher::Declarative... maybe this should go in a common place?
        };
    }

    return $payload;
};

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Dispatcher::Rule::Chain - Chain rules for Path::Dispatcher

=head1 VERSION

version 1.08

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
