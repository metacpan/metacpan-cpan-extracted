package Syntax::Operator::Matches 0.000003;

use v5.38;
use warnings;

use Carp;
use match::simple;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

sub import
{
   my $class = shift;
   my $caller = caller;

   $class->import_into( $caller, @_ );
}

sub import_into
{
   my $class = shift;
   my ( $caller, @syms ) = @_;

   @syms or @syms = qw( matches );
   my %syms = map { $_ => 1 } @syms;

   if ( $syms{'-all'} or $syms{':all'} ) {
      $syms{matches} = $syms{mismatches} = 1;
      delete $syms{$_} for qw/ -all :all /;
   }

   if ( $syms{'-default'} or $syms{':default'} ) {
      $syms{matches} = 1;
      delete $syms{$_} for qw/ -default :default /;
   }

   $^H{"Syntax::Operator::Matches/matches"}++    if delete $syms{matches};
   $^H{"Syntax::Operator::Matches/mismatches"}++ if delete $syms{mismatches};

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

1;
__END__

=head1 NAME

C<Syntax::Operator::Matches> - match::simple but as a real infix operator

=head1 SYNOPSIS

On Perl v5.38 or later:

   use v5.38;
   use Syntax::Operator::Matches;

   if ( $x matches $y ) {
      ...;
   }

=head1 DESCRIPTION

This module implements a C<matches> infix operator using L<match::simple>.

There's also a C<mismatches> operator which returns the inverse. This needs
to be requested explicitly.

   use v5.38;
   use Syntax::Operator::Matches qw( matches mismatches );
   
   unless ( $x mismatches $y ) {
      ...;
   }

=head2 What matches what?

As a reminder of what L<match::simple>'s matching rules are:

=over

=item *

If the right hand side is C<undef>, then there is only a match if the left
hand side is also C<undef>.

=item *

If the right hand side is a non-reference, then the match is a simple string
match.

=item *

If the right hand side is a reference to a regexp, then the left hand is
evaluated.

=item *

If the right hand side is a code reference, then it is called in a boolean
context with the left hand side being passed as an argument.

=item *

If the right hand side is an object which provides a C<MATCH> method, then
it this is called as a method, with the left hand side being passed as an
argument.

=item *

If the right hand side is an object which overloads C<< ~~ >>, then this
will be used.

=item *

If the right hand side is an arrayref, then the operator recurses into the
array, with the match succeeding if the left hand side matches any array
element.

=item *

If any other value appears on the right hand side, the operator will croak.

=back

=head2 Use with Type::Tiny

L<Type::Tiny> type constraints overload the C<< ~~ >> operator, so the
following will work:

  use Types::Standard qw( Str ArrayRef );
  use Syntax::Operator::Matches;
  
  if ( $x matches Str ) {
    say $x;
  }
  elsif ( $x matches ArrayRef[Str] ) {
    say $_ for $x->@*;
  }
  else {
    warn "Unexpected input";
  }

=head1 SEE ALSO

L<match::simple>.

=head1 AUTHOR

Toby Inkster <tobyink@cpan.org>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
