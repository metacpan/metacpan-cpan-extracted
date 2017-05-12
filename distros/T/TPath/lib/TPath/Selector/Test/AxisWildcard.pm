package TPath::Selector::Test::AxisWildcard;
$TPath::Selector::Test::AxisWildcard::VERSION = '1.007';
# ABSTRACT: handles C</ancestor::*> or C</preceding::*> where this is not the first step in the path, or C<ancestor::*>, etc.

use v5.10;

use Moose;
use TPath::Test::Node::True;
use namespace::autoclean;


with 'TPath::Selector::Test';

sub BUILD {
    my $self = shift;
    state $nt = TPath::Test::Node::True->new;
    $self->_node_test($nt);
}

sub to_string {
    my ( $self, $first ) = @_;
    my $s = $first ? '' : '/';
    $s .= $self->axis . '::';
    $s .= '*';
    return $s;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Test::AxisWildcard - handles C</ancestor::*> or C</preceding::*> where this is not the first step in the path, or C<ancestor::*>, etc.

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
