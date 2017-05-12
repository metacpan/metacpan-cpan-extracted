use strict;
use warnings;
package Search::GIN::Driver::Pack::UUID;
# ABSTRACT: UUID key packing

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

with qw(Search::GIN::Driver);

sub unpack_ids {
    my ( $self, $str ) = @_;
    unpack("(a16)*", $str);
}

sub pack_ids {
    my ( $self, @ids ) = @_;
    pack("(a16)*", @ids); # FIXME enforce size
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::GIN::Driver::Pack::UUID - UUID key packing

=head1 VERSION

version 0.11

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman), Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
