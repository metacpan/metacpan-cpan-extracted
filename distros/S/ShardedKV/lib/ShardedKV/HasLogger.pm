package ShardedKV::HasLogger;
$ShardedKV::HasLogger::VERSION = '0.20';
use strict;
use Moose::Role;
# ABSTRACT: The logging role for ShardedKV objects


has 'logger' => (
  is => 'rw',
  isa => 'Object',
);

no Moose;
1;

__END__

=pod

=head1 NAME

ShardedKV::HasLogger - The logging role for ShardedKV objects

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  use ShardedKV;
  my $skv = ShardedKV->new(
    logger => $logger_obj,
    ...
  );

=head1 DESCRIPTION

This role adds a C<logger> attribute to the consumer. See the main
C<ShardedKV> documentation for details.

This role is consumed by at least the following classes or roles:
C<ShardedKV>, C<ShardedKV::Storage>, C<ShardedKV::Continuum>.

=head1 PUBLIC ATTRIBUTES

=head2 logger

If set, this must be a user-supplied object that implements
a certain number of methods which are called throughout ShardedKV
for logging/debugging purposes. See the main documentation for
the ShardedKV module for details.

=head1 SEE ALSO

=over 4

=item *

L<ShardedKV>

=item *

L<ShardedKV::Storage>

=item *

L<ShardedKV::Continuum>

=item *

L<Log::Log4perl>

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
