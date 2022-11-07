use 5.008001;
use strict;
use warnings;

package Sub::Boolean;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '1.000000';

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

use Exporter::Shiny qw( make_true make_false make_undef make_empty );

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::Boolean - make XS true/false subs

=head1 SYNOPSIS

  use Test::More;
  use Sub::Boolean qw( make_true );
  
  make_true( __PACKAGE__ . "::foobar" );
  
  ok( foobar(),    'returns true' );
  ok( foobar(123), 'returns true' );

=head1 DESCRIPTION

A good way to create fast true/false constants is:

  use constant { true => !!1, false => !!0 };

Or on newer Perls:

  use builtin qw( true false );

However these constants will throw a compile-time error if you call them
as a sub:

  if ( true(123) ) {
    ...;
  }

Sub::Boolean allows you to create subs which return true or false fast
as they're implemented in XS.

As a bonus, it can also generate subs which return undef or the empty list.

Each function created by this module will have a different refaddr, which 
means that using things like C<set_prototype> or C<set_subname> on one will
not affect others.

Boolean functions are really unlikely to be a bottleneck in most
applications, so the use cases for this module are very limited.

=head1 FUNCTIONS

Nothing is exported unless requested.

=head2 C<< make_true( $qualified_name ) >>

Given a fully qualified sub name, installs a sub something like:

  sub $qualified_name {
    return !!1;
  }

If called as C<< make_true() >> with no name, returns an anonymous coderef.

=head2 C<< make_false( $qualified_name ) >>

Given a fully qualified sub name, installs a sub something like:

  sub $qualified_name {
    return !!0;
  }

If called as C<< make_false() >> with no name, returns an anonymous coderef.

=head2 C<< make_undef( $qualified_name ) >>

Given a fully qualified sub name, installs a sub something like:

  sub $qualified_name {
    return undef;
  }

If called as C<< make_undef() >> with no name, returns an anonymous coderef.

=head2 C<< make_empty( $qualified_name ) >>

Given a fully qualified sub name, installs a sub something like:

  sub $qualified_name {
    return ();
  }

If called as C<< make_empty() >> with no name, returns an anonymous coderef.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-boolean/issues>.

=head1 SEE ALSO

L<builtin>, L<constant>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
