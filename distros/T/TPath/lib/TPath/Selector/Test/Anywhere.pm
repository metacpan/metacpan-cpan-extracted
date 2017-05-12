package TPath::Selector::Test::Anywhere;
$TPath::Selector::Test::Anywhere::VERSION = '1.007';
# ABSTRACT: handles C<//*> expression

use v5.10;

use Moose;
use TPath::Test::Node::True;
use namespace::autoclean;


with 'TPath::Selector::Test';

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;
    state $nt = TPath::Test::Node::True->new;
    $class->$orig(
        %args,
        first_sensitive => 1,
        axis            => 'descendant',
        node_test       => $nt
    );
};

sub to_string { '//*' }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Test::Anywhere - handles C<//*> expression

=head1 VERSION

version 1.007

=head1 ROLES

L<TPath::Selector::Test>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
