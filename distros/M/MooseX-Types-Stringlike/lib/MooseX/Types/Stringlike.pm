use 5.008001;
use strict;
use warnings;

package MooseX::Types::Stringlike;
# ABSTRACT: Moose type constraints for strings or string-like objects
our $VERSION = '0.003'; # VERSION

use MooseX::Types -declare => [ qw/Stringable Stringlike ArrayRefOfStringable ArrayRefOfStringlike / ];
use MooseX::Types::Moose qw/Str Object ArrayRef/;
use overload ();

# Thanks ilmari for suggesting something like this
subtype Stringable,
  as Object,
  where { overload::Method($_, '""') };

subtype Stringlike,
  as Str;

coerce Stringlike,
  from Stringable,
  via { "$_" };


subtype ArrayRefOfStringable,
  as ArrayRef[Stringable];

subtype ArrayRefOfStringlike,
  as ArrayRef[Stringlike];

coerce ArrayRefOfStringlike,
  from ArrayRefOfStringable,
  via { [ map { "$_" } @$_ ] };

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Stringlike - Moose type constraints for strings or string-like objects

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  package Foo;
  use Moose;
  use MooseX::Types::Stringlike qw/Stringlike Stringable ArrayRefOfStringlike ArrayRefOfStringable/;

  has path => (
    is => 'ro',
    isa => Stringlike,
    coerce => 1
  );

  has stringable_object => (
    is => 'ro',
    isa => Stringable,
  );

  has paths => (
    is => 'ro',
    isa => ArrayRefOfStringlike,
    coerce => 1
  );

  has stringable_objects => (
    is => 'ro',
    isa => ArrayRefOfStringable,
  );

=head1 DESCRIPTION

This module provides a more general version of the C<Str> type.  If coercions
are enabled, it will accepts objects that overload stringification and coerces
them into strings.

=for Pod::Coverage method_names_here

=head1 SUBTYPES

This module uses L<MooseX::Types> to define the following subtypes.

=head2 Stringlike

C<Stringlike> is a subtype of C<Str>.  It can coerce C<Stringable> objects into
a string.

=head2 Stringable

C<Stringable> is a subtype of C<Object> where the object has overloaded stringification.

=head2 ArrayRefOfStringlike

C<ArrayRefStringlike> is a subtype of C<ArrayRef[Str]>.  It can coerce C<ArrayRefOfStringable> objects into
an arrayref of strings.

=head2 ArrayRefOfStringable

C<ArrayRefOfStringable> is a subtype of C<ArrayRef[Object]> where the objects have overloaded stringification.

=head1 SEE ALSO

=over 4

=item *

L<Moose::Manual::Types>

=item *

L<MooseX::Types>

=item *

L<MooseX::Types::Moose>

=back

=head1 ACKNOWLEDGMENTS

Thank you to Dagfinn Ilmari Mannsåker for the idea on IRC that led to this module.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/MooseX-Types-Stringlike/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/MooseX-Types-Stringlike>

  git clone https://github.com/dagolden/MooseX-Types-Stringlike.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
