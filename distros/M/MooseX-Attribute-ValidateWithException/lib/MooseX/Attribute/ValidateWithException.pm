## no critic (Moose::RequireMakeImmutable)
use 5.006;    # warnings
use strict;
use warnings;

package MooseX::Attribute::ValidateWithException;

our $VERSION = 'v0.4.0';

# ABSTRACT: Cause validation failures to throw exception objects.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

require Moose;
use Moose::Exporter;
require MooseX::Attribute::ValidateWithException::AttributeRole;

Moose::Exporter->setup_import_methods(
  class_metaroles => { attribute => ['MooseX::Attribute::ValidateWithException::AttributeRole'], }, );






























































1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Attribute::ValidateWithException - Cause validation failures to throw exception objects.

=head1 VERSION

version v0.4.0

=head1 SYNOPSIS

  {
    package Foo;
    use Moose;
    use MooseX::Attribute::ValidateWithException;

    has foo => (
      isa => 'Str',
      is  => 'rw',
      required => 1,
    );
    __PACKAGE__->meta->make_immutable;
    no Moose;
  }

  use Try::Tiny;

  try {
    Foo->new( foo => { this_is => [qw( not what we were wanting )] } );
  } catch {
    say $_->name if blessed( $_ ) && $_->isa('Thingy');
  };

=head1 DESCRIPTION

B<ALPHA QUALITY SOFTWARE>.

At present, when an attribute fails validation, Moose internally die()'s with a
string. There is also no way to throw an exception object as part of the
validation message, ( in order to give more context on the problem ), without
also breaking how much of the validation works.

This module is an experiment in providing that feature, which really should be
done in Moose itself, and done better, which is why it has been given such an
obtuse name.

This module makes no promises of forwards compatibility with a future Moose
release, in order to permit Moose to do whatever they want and not worry about
"breaking code" that uses this module. ( So that they can easily replace this
module in incompatible ways )

B<< If your code breaking is unacceptable, do I<not> use this module >>.

Use of this module assumes several things.

=over 4

=item 1. You are o.k. with your code breaking in a future Moose release.

=item 2. You are o.k. with re-writing any and all code that depends on this
functionality, if a future Moose release is incompatible with this module.

=back

I'm not saying I won't do my best to provide forwards compatibility, but it is
highly unlikely it will be possible, due to differences in package naming
which may be essential for handling exceptions.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
