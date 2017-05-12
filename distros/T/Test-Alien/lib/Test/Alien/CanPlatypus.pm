package Test::Alien::CanPlatypus;

use strict;
use warnings;
use base 'Test2::Require';

# ABSTRACT: Skip a test file unless FFI::Platypus is available
our $VERSION = '0.14'; # VERSION


sub skip
{
  eval { require FFI::Platypus; 1 } ? undef : 'This test requires FFI::Platypus.';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Alien::CanPlatypus - Skip a test file unless FFI::Platypus is available

=head1 VERSION

version 0.14

=head1 SYNOPSIS

 use Test::Alien::CanPlatypus;

=head1 DESCRIPTION

This is just a L<Test2> plugin that requires that L<FFI::Platypus>
be available.  Otherwise the test will be skipped.

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=item L<FFI::Platypus>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
