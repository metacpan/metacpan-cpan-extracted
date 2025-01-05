package Test::Alien::CanCompileCpp;

use strict;
use warnings;
use base 'Test2::Require';
use ExtUtils::CBuilder 0.27;

# ABSTRACT: Skip a test file unless a C++ compiler is available
our $VERSION = '1.04'; # VERSION


sub skip
{
  ExtUtils::CBuilder->new->have_cplusplus ? undef : 'This test requires a compiler.';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Alien::CanCompileCpp - Skip a test file unless a C++ compiler is available

=head1 VERSION

version 1.04

=head1 SYNOPSIS

 use Test::Alien::CanCompileCpp;

=head1 DESCRIPTION

This is just a L<Test2> plugin that requires that a compiler
be available.  Otherwise the test will be skipped.

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Roy Storey (KIWIROY)

Diab Jerius (DJERIUS)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
