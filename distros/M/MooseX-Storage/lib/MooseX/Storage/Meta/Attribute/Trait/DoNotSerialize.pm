package MooseX::Storage::Meta::Attribute::Trait::DoNotSerialize;
# ABSTRACT: A custom meta-attribute-trait to bypass serialization

our $VERSION = '0.53';

use Moose::Role;
use namespace::autoclean;

# register this alias ...
package # hide from PAUSE
    Moose::Meta::Attribute::Custom::Trait::DoNotSerialize;

sub register_implementation { 'MooseX::Storage::Meta::Attribute::Trait::DoNotSerialize' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Meta::Attribute::Trait::DoNotSerialize - A custom meta-attribute-trait to bypass serialization

=head1 VERSION

version 0.53

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage('format' => 'JSON', 'io' => 'File');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  has 'foo' => (
      traits => [ 'DoNotSerialize' ],
      is     => 'rw',
      isa    => 'CodeRef',
  );

  1;

=head1 DESCRIPTION

=for stopwords culted

Sometimes you don't want a particular attribute to be part of the
serialization, in this case, you want to make sure that attribute
uses this custom meta-attribute-trait. See the SYNOPSIS for a nice
example that can be easily cargo-culted.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Storage>
(or L<bug-MooseX-Storage@rt.cpan.org|mailto:bug-MooseX-Storage@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris.prather@iinteractive.com>

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
