package ShardedKV::Continuum;
$ShardedKV::Continuum::VERSION = '0.20';
use Moose::Role;
# ABSTRACT: The continuum role

with 'ShardedKV::HasLogger';


requires qw(
  choose
  clone
  extend
  serialize
  deserialize
  get_bucket_names
);

no Moose;

1;

__END__

=pod

=head1 NAME

ShardedKV::Continuum - The continuum role

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  package ShardedKV::Continuum::MyAlgorithm;
  use Moose;
  with 'ShardedKV::Continuum';
  ... implement necessary methods here ...
  1;

=head1 DESCRIPTION

A class that consumes this role and implements all required
methods correctly can be used as a sharding algorithm for a L<ShardedKV>.

See L<ShardedKV::Continuum::Ketama> for an example.

=head1 ROLE REQUIRES

=head2 choose

Given a key name, must return the name of the shard that
the key lives on.

=head2 clone

Returns a deep copy of the object.

=head2 extend

Given one or multiple shard specifications, adds these to
the continuum.

=head2 serialize

Returns a string that could be used to recreate the continuum.

=head2 deserialize

Given such a string, recreates the exact same continuum.

=head2 get_bucket_names

Returns a list of all shard/bucket names in the continuum.

=head1 SEE ALSO

=over 4

=item *

L<ShardedKV>

=item *

L<ShardedKV::Continuum::Ketama>

=item *

L<ShardedKV::Continuum::StaticMapping>

=back

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Nick Perez <nperez@cpan.org>

=item *

Damian Gryski <dgryski@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
