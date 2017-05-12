package MooseX::Storage::IO::StorableFile;
# ABSTRACT: An Storable File I/O role

our $VERSION = '0.52';

use Moose::Role;
use Storable ();
use namespace::autoclean;

requires 'pack';
requires 'unpack';

sub load {
    my ( $class, $filename, @args ) = @_;
    # try thawing
    return $class->thaw( Storable::retrieve($filename), @args )
        if $class->can('thaw');
    # otherwise just unpack
    $class->unpack( Storable::retrieve($filename), @args );
}

sub store {
    my ( $self, $filename, @args ) = @_;
    Storable::nstore(
        # try freezing, otherwise just pack
        ($self->can('freeze') ? $self->freeze(@args) : $self->pack(@args)),
        $filename
    );
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::IO::StorableFile - An Storable File I/O role

=head1 VERSION

version 0.52

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage('io' => 'StorableFile');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  my $p = Point->new(x => 10, y => 10);

  ## methods to load/store a class
  ## on the file system

  $p->store('my_point');

  my $p2 = Point->load('my_point');

=head1 DESCRIPTION

This module will C<load> and C<store> Moose classes using Storable. It
uses C<Storable::nstore> by default so that it can be easily used
across machines or just locally.

One important thing to note is that this module does not mix well
with the other Format modules. Since Storable serialized perl data
structures in it's own format, those roles are largely unnecessary.

However, there is always the possibility that having a set of
C<freeze/thaw> hooks can be useful, so because of that this module
will attempt to use C<freeze> or C<thaw> if that method is available.
Of course, you should be careful when doing this as it could lead to
all sorts of hairy issues. But you have been warned.

=head1 METHODS

=over 4

=item B<load ($filename)>

=item B<store ($filename)>

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
