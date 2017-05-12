use 5.006;
use strict;
use warnings;

package Set::Associate::NewKey::HashSHA1;

# ABSTRACT: Pick a value from the pool based on the SHA1 value of the key

our $VERSION = '0.004001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( around extends );
use Digest::SHA1;
use bigint 0.22 qw( hex );
extends 'Set::Associate::NewKey::PickOffset';







sub name { 'hash_sha1' }

around get_assoc => sub {
  my ( $orig, $self, $sa, $key ) = @_;
  return $self->$orig( $sa, hex Digest::SHA1::sha1_hex($key) );
};

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Associate::NewKey::HashSHA1 - Pick a value from the pool based on the SHA1 value of the key

=head1 VERSION

version 0.004001

=head1 METHODS

=head2 name

The name of this key assignment method ( C<hash_sha1> )

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
