package Sub::Assert::Nothing;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	&assert
);
use vars qw/$VERSION/;
$VERSION = '1.23';

use Carp qw/croak carp/;


sub assert {
}

1;
__END__

=head1 NAME

Sub::Assert::Nothing - Design-by-contract like pre- and postconditions, etc.

=head1 SYNOPSIS

  use Sub::Assert::Nothing;
  
  assert
         yada yada yada;
  

=head1 ABSTRACT

  Design-by-contract like subroutine pre- and postconditions.

=head1 DESCRIPTION

This module is part of the Sub::Assert distribution. Please read
the documentation on Sub::Assert. For your convenience, a portion
of the docs is reproduced below, but do not expect it to be
updated whenever Sub::Assert is updated.

The Sub::Assert module aims at providing design-by-contract like
subroutine pre- and postconditions. Furthermore, it allows restricting
the subroutine's calling context.

There's one big gotcha with this: It's slow. For every call to
subroutines you use assert() with, you pay for the error checking
with an extra subroutine call, some memory and some additional code
that's executed.

Fortunately, there's a workaround for mature software
which does not require you to edit a lot of your code. Instead of
use()ing Sub::Assert, you simply use Sub::Assert::Nothing and leave
the assertions intact. While you still suffer the calls to assert()
once, you won't pay the run-time penalty usually associated with
subroutine pre- and postconditions. Of course, you lose the benefits,
too, but as stated previously, this is a workaround in case you
want the verification at development time, but prefer speed in
production without refactoring your code.

=head2 EXPORT

Exports the 'assert' subroutine to the caller's namespace.

=head2 assert

The implementation of the assert subroutine exported by this
package is a no-op.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2009 Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
=head1 SEE ALSO

L<Sub::Assert>

L<perl>.

Look for new versions of this module on CPAN or at
http://steffen-mueller.net

=cut
