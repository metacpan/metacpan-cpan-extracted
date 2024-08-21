package Syntax::Keyword::Junction;
use strict;
use warnings;
use 5.006;

our $VERSION = '0.003009';

require Syntax::Keyword::Junction::All;
require Syntax::Keyword::Junction::Any;
require Syntax::Keyword::Junction::None;
require Syntax::Keyword::Junction::One;

use Sub::Exporter::Progressive -setup => {
  exports => [qw( all any none one )],
  groups => {
    default => [qw( all any none one )],
    # for the switch from Exporter
    ALL     => [qw( all any none one )],
  },
};

sub all  { Syntax::Keyword::Junction::All->new(@_)  }
sub any  { Syntax::Keyword::Junction::Any->new(@_)  }
sub none { Syntax::Keyword::Junction::None->new(@_) }
sub one  { Syntax::Keyword::Junction::One->new(@_)  }

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Arthur Axel "fREW" Schmidt Carl Franks

=head1 NAME

Syntax::Keyword::Junction - Comparisons against multiple values

=head1 SYNOPSIS

  use Syntax::Keyword::Junction qw/ all any none one /;

  if (any(@grant) eq 'su') {
    ...
  }

  if (all($foo, $bar) >= 10) {
    ...
  }

  if (qr/^\d+$/ == all(@answers)) {
    ...
  }

  if (all(@input) <= scalar @limits) {
    ...
  }

  if (none(@pass) eq 'password') {
    ...
  }

  if (one(@answer) == 42) {
    ...
  }

or if you want to rename an export, use L<Sub::Exporter> options:

  use Syntax::Keyword::Junction any => { -as => 'robot_any' };

  if (robot_any(@grant) eq 'su') {
    ...
  }

=head1 DESCRIPTION

This is a lightweight module which provides 'Junction' operators, the most
commonly used being C<any> and C<all>.

Inspired by the Perl 6 design docs,
L<https://web.archive.org/web/20230922160729/https://raku.org/archive/doc/design/exe/E06.html#The%20Wonderful%20World%20of%20Junctions>.

Provides a limited subset of the functionality of L<Quantum::Superpositions>,
see L</"SEE ALSO"> for comment.

Notice in the L</SYNOPSIS> above, that if you want to match against a
regular expression, you must use C<==> or C<!=>. B<Not> C<=~> or C<!~>. You
must also use a regex object, such as C<qr/\d/>, not a plain regex such as
C</\d/>.

=head1 SUBROUTINES

=head2 all()

Returns an object which overloads the following operators:

  '<',  '<=', '>',  '>=', '==', '!=',
  'lt', 'le', 'gt', 'ge', 'eq', 'ne',
  '~~'

Returns true only if B<all> arguments test true according to the operator
used.

=head2 any()

Returns an object which overloads the following operators:

  '<',  '<=', '>',  '>=', '==', '!=',
  'lt', 'le', 'gt', 'ge', 'eq', 'ne',
  '~~'

Returns true if B<any> argument tests true according to the operator used.

=head2 none()

Returns an object which overloads the following operators:

  '<',  '<=', '>',  '>=', '==', '!=',
  'lt', 'le', 'gt', 'ge', 'eq', 'ne',
  '~~'

Returns true only if B<no> argument tests true according to the operator
used.

=head2 one()

Returns an object which overloads the following operators:

  '<',  '<=', '>',  '>=', '==', '!=',
  'lt', 'le', 'gt', 'ge', 'eq', 'ne',
  '~~'

Returns true only if B<one and only one> argument tests true according to
the operator used.

=head1 ALTERING JUNCTIONS

You cannot alter junctions.  Instead, you can create new junctions out of old
junctions.  You can do this by calling the C<values> method on a junction.

  my $numbers = any(qw/1 2 3 4 5/);
  print $numbers == 3 ? 'Yes' : 'No';   # Yes

  $numbers = any( grep { $_ != 3 } $numbers->values );
  print $numbers == 3 ? 'Yes' : 'No';   # No

You can also use the C<map> method:

  my $numbers = any(qw/1 2 3 4 5/);
  my $prime   = $numbers->map( \&is_prime );

  say for $prime->values; # prints 0, 1, 1, 0, 1

=head1 EXPORT

'all', 'any', 'none', 'one', as requested.

All subroutines can be called by its fully qualified name, if you don't
want to export them.

  use Syntax::Keyword::Junction;

  if (Syntax::Keyword::Junction::any( @questions )) {
    ...
  }

=head1 WARNING

When comparing against a regular expression, you must remember to use a
regular expression object: C<qr/\d/> B<Not> C</d/>. You must also use either
C<==> or C<!=>. This is because C<=~> and C<!~> cannot be overridden.

=head1 TO DO

Add overloading for arithmetic operators, such that this works:

  $result = any(2,3,4) * 2;

  if ($result == 8) {...}

=head1 SEE ALSO

This module is actually a fork of L<Perl6::Junction> with very few
(initial) changes.  The reason being that we want to avoid the
incendiary name containing Perl 6.

L<Quantum::Superpositions> provides the same functionality as this, and
more. However, this module provides this limited functionality at a much
greater runtime speed, with my benchmarks showing between 500% and 6000%
improvement.

L<https://web.archive.org/web/20230922160729/https://raku.org/archive/doc/design/exe/E06.html#The%20Wonderful%20World%20of%20Junctions> - "The Wonderful World of Junctions".

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Syntax-Keyword-Junction/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CONTRIBUTORS

=for stopwords Arthur Axel 'fREW' Schmidt Carl Franks David Steinbrunner Graham Knop Maxime Soulé Michael Schout Olivier Mengué Paul Cochrane Ricardo Signes Rob Hoelz

=over 4

=item *

Arthur Axel 'fREW' Schmidt <frioux@gmail.com>

=item *

Carl Franks <cpan@fireartist.com>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Maxime Soulé <btik-cpan@scoubidou.com>

=item *

Michael Schout <schoutm@gmail.com>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Paul Cochrane <paul.cochrane@posteo.de>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=back

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Carl Franks

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
