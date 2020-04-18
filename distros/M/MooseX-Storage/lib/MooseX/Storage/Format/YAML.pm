package MooseX::Storage::Format::YAML;
# ABSTRACT: A YAML serialization role

our $VERSION = '0.53';

use Moose::Role;

# When I add YAML::LibYAML
# Tests break because tye YAML is invalid...?
# -dcp

use YAML::Any qw(Load Dump);
use namespace::autoclean;

requires 'pack';
requires 'unpack';

sub thaw {
    my ( $class, $yaml, @args ) = @_;
    $class->unpack( Load($yaml), @args );
}

sub freeze {
    my ( $self, @args ) = @_;
    Dump( $self->pack(@args) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Format::YAML - A YAML serialization role

=head1 VERSION

version 0.53

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage('format' => 'YAML');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  my $p = Point->new(x => 10, y => 10);

  ## methods to freeze/thaw into
  ## a specified serialization format
  ## (in this case YAML)

  # pack the class into a YAML string
  $p->freeze();

  # ----
  # __CLASS__: "Point"
  # x: 10
  # y: 10

  # unpack the JSON string into a class
  my $p2 = Point->thaw(<<YAML);
  ----
  __CLASS__: "Point"
  x: 10
  y: 10
  YAML

=head1 METHODS

=over 4

=item B<freeze>

=item B<thaw ($yaml)>

=back

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
