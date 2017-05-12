use strict;
use warnings;

package Task::Deprecations::5_14;
BEGIN {
  $Task::Deprecations::5_14::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $Task::Deprecations::5_14::VERSION = '1.01';
}
# ABSTRACT: libraries deprecated from the core in 5.14.0


1;

__END__
=pod

=head1 NAME

Task::Deprecations::5_14 - libraries deprecated from the core in 5.14.0

=head1 VERSION

version 1.01

=head1 TASK CONTENTS

=head2 Perl 5.14.0 Deprecations

Perl 5.14.0 is the first non-development release in which the following core
modules have been marked as deprecated from the core in a way that will cause
them to warn if used from the core distribution. Libraries deprecated in 5.14
may no longer appear in future releases of perl 5.

Installing this set of libraries (by installing Task::Deprecations::5_14 itself)
will stop the "will be removed from the Perl core distribution" warnings.

=head3 L<Devel::DProf> 20110225.01

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

