use 5.006;    # pragmas, qr
use warnings;
use strict;

package MooseX::Has::Sugar;

our $VERSION = '1.000006';

# ABSTRACT: Sugar Syntax for moose 'has' fields

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp ();
use Sub::Exporter::Progressive (
  -setup => {
    exports => [ 'ro', 'rw', 'required', 'lazy', 'lazy_build', 'coerce', 'weak_ref', 'auto_deref', 'bare', ],
    groups  => {
      isattrs => [ 'ro',       'rw',   'bare', ],
      attrs   => [ 'required', 'lazy', 'lazy_build', 'coerce', 'weak_ref', 'auto_deref', ],
      default => [ 'ro',       'rw',   'bare', 'required', 'lazy', 'lazy_build', 'coerce', 'weak_ref', 'auto_deref', ],
    },
  },
);







sub bare() {
  return ( 'is', 'bare' );
}







sub ro() {
  return ( 'is', 'ro' );
}







sub rw() {
  return ( 'is', 'rw' );
}







sub required() {
  return ( 'required', 1 );
}







sub lazy() {
  return ( 'lazy', 1 );
}







sub lazy_build() {
  return ( 'lazy_build', 1 );
}







sub weak_ref() {
  return ( 'weak_ref', 1 );
}









sub coerce() {
  return ( 'coerce', 1 );
}







sub auto_deref() {
  return ( 'auto_deref', 1 );
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Has::Sugar - Sugar Syntax for moose 'has' fields

=head1 VERSION

version 1.000006

=head1 SYNOPSIS

  use Moose;
  use MooseX::Types::Moose;
  use MooseX::Has::Sugar;

  has attrname      => ( isa => Str, ro, required   );
  has otherattrname => ( isa => Str, rw, lazy_build );

=head1 DESCRIPTION

C<MooseX::Has::Sugar> and its related modules provide simple, short-hand, bare-word functions that
act as declarative macros for greatly compacting L<< C<Moose>|Moose >> C<has> declarations, in a similar
way to those provided by the declarative subroutines provided by L<< C<MooseX::Types>|MooseX::Types >>

This provides:

=over 4

=item * Less typing when defining C<has> constraints

=item * Faster, more skim-readable blocks of C<has> constraints

=item * Perl Language Level syntax validation at compile time

=back

=head1 BENEFITS

=head2 Reduced Typing in C<has> declarations.

The constant need to type C<=E<gt>> and C<''> is fine for one-off cases, but
the instant you have more than about 4 attributes it starts to get annoying.

=head2 More compact declarations.

Reduces much of the redundant typing in most cases, which makes your life easier,
and makes it take up less visual space, which makes it faster to read.

=head2 No String Worries

Strings are often problematic, due to white-space etc. Noted that if you do
happen to mess them up, Moose should at I<least> warn you that you've done
something daft. Using this alleviates that worry.

=head1 COMPARISONS

=head2 Classical Moose

    has foo => (
            isa => 'Str',
            is  => 'ro',
            required => 1,
    );

    has bar => (
            isa => 'Str',
            is => 'rw'
            lazy_build => 1,
    );

=head2 Lazy Evil way to do it:

B<PLEASE DO NOT DO THIS>

    has qw( foo isa Str is ro required 1 );
    has qw( bar isa Str is rw lazy_build 1 );

=head2 With this module

( and with MooseX::Types )

    use MooseX::Types::Moose qw( Str );
    use MooseX::Has::Sugar;

    has foo => (
            isa => Str,
            ro,
            required,
    );
    has bar => (
            isa => Str,
            rw,
            lazy_build,
    );

Or even

    use MooseX::Types::Moose qw( Str );
    use MooseX::Has::Sugar;

    has foo => ( isa => Str, ro,  required, );
    has bar => ( isa => Str, rw,  lazy_build, );

=head1 ALTERNATIVE FORMS

=head2 Basic C<is> Expansion Only

( using L<::Sugar::Minimal|MooseX::Has::Sugar::Minimal> instead )

    use MooseX::Types::Moose qw( Str );
    use MooseX::Has::Sugar::Minimal;

    has foo => (
            isa => Str,
            is  => ro,
            required => 1,
    );
    has bar => (
            isa => Str,
            is => rw,
            lazy_build => 1,
    );

=head2 Attribute Expansions with Basic Expansions

( Combining parts of this and L<::Sugar::Minimal|MooseX::Has::Sugar::Minimal> )

    use MooseX::Types::Moose qw( Str );
    use MooseX::Has::Sugar::Minimal;
    use MooseX::Has::Sugar qw( :attrs );

    has foo => (
            isa => Str,
            is  => ro,
            required,
    );
    has bar => (
            isa => Str,
            is => rw,
            lazy_build,
    );

=head1 EXPORT GROUPS

=head2 C<:default>

Since 0.0300, this exports all our syntax, the same as C<:attrs> C<:isattrs>.
Primarily because I found you generally want all the sugar, not just part of it.
This also gets rid of that nasty exclusion logic.

=head2 C<:isattrs>

This exports C<ro>, C<rw> and C<bare> as lists, so they behave as stand-alone attributes like
L</lazy> does.

    has foo => (
            required,
            isa => 'Str',
            ro,
    );

B<NOTE: This option is incompatible with L<::Sugar::Minimal|MooseX::Has::Sugar::Minimal>> : L</CONFLICTS>

=head2 C<:attrs>

This exports L</lazy> , L</lazy_build> and L</required>, L</coerce>, L</weak_ref>
and L</auto_deref> as subs that assume positive.

    has foo => (
            required,
            isa => 'Str',
    );

B<NOTE: This option is incompatible with L<MooseX::Types|MooseX::Types> and L<Moose's Type Constraints Module|Moose::Util::TypeConstraints>> : L</CONFLICTS>

=head2 C<:is>

B<DEPRECATED>. See L<::Sugar::Minimal|MooseX::Has::Sugar::Minimal> for the same functionality

=head2 C<:allattrs>

B<DEPRECATED>, just use L</:default> or do

    use MooseX::Has::Sugar;

=head1 EXPORTED FUNCTIONS

=head2 C<bare>

returns C<('is','bare')>

=head2 C<ro>

returns C<('is','ro')>

=head2 C<rw>

returns C<('is','rw')>

=head2 C<required>

returns C<('required',1)>

=head2 C<lazy>

returns C<('lazy',1)>

=head2 C<lazy_build>

returns C<('lazy_build',1)>

=head2 C<weak_ref>

returns C<('weak_ref',1)>

=head2 C<coerce>

returns C<('coerce',1)>

B<WARNING:> Conflict with L<MooseX::Types|MooseX::Types> and L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>, see L</CONFLICTS>.

=head2 C<auto_deref>

returns C<('auto_deref',1)>

=head1 CONFLICTS

=head2 MooseX::Has::Sugar::Minimal

=head2 MooseX::Has::Sugar::Saccharin

This module is not intended to be used in conjunction with
 L<::Sugar::Minimal|MooseX::Has::Sugar::Minimal> or L<::Sugar::Saccharin|MooseX::Has::Sugar::Saccharin>

We export many of the same symbols and its just not very sensible.

=head2 MooseX::Types

=head2 Moose::Util::TypeConstraints

due to exporting the L</coerce> symbol, using us in the same scope as a call to

    use MooseX::Types ....

or
    use Moose::Util::TypeConstraints

will result in a symbol collision.

We recommend using and creating proper type libraries instead, ( which will absolve you entirely of the need to use MooseX::Types and MooseX::Has::Sugar(::*)? in the same scope )

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
