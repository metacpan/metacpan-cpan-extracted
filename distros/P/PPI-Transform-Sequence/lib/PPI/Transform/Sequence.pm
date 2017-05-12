package PPI::Transform::Sequence;

use strict;
use warnings;

# ABSTRACT: Tiny binder to combine multiple PPI::Transform objects
our $VERSION = 'v0.0.3'; # VERSION

use parent qw(PPI::Transform);

use Carp;

sub new
{
    my ($self, @args) = @_;
    croak 'Odd number of arguments are specified' if @args % 2 == 1;
    my $class = ref($self) || $self;
    $self = bless [], $class;
    while(@args) {
        my ($name, $arg) = splice @args, 0, 2;
        croak 'The latter of pairs SHOULD be an array reference' if ref($arg) ne 'ARRAY';
        eval "require $name";
        croak "$name can't be loaded: $@" if $@;
        croak 'The former of pairs SHOULD be a name of PPI::Transform subclass: $name' if ! $name->isa('PPI::Transform');
        push @$self, $name->new(@$arg);
    }
    return $self;
}

sub idx
{
    my ($self, $idx) = @_;
    return $self->[$idx];
}

sub document
{
    my ($self, $doc) = @_;
    my $count = 0;
    foreach my $trans (@$self) {
        $count += $trans->document($doc);
    }
    return $count;
}

1;

__END__

=pod

=head1 NAME

PPI::Transform::Sequence - Tiny binder to combine multiple PPI::Transform objects

=head1 VERSION

version v0.0.3

=head1 SYNOPSIS

  use PPI::Transform::Sequence;
  my $trans = PPI::Transform::Sequence->new(
    PPI::Transform::UpdateCopyright => [ name => 'Yasutaka ATARASHI' ],
    PPI::Transform::PackageName => [ -all => sub { s/^Acme\b/ACME/g } ],
  );

  print $trans->idx(0)->name; # access to PPI::Transform subclass object

  # All PPI::Transform methods can be called, and
  # Each transformation is sequentially applied.
  $trans->file('Change.pm'); # Update copyright, then package names are replaced

=head1 DESCRIPTION

This module is a tiny binder to combine multiple L<PPI::Transform> objects into one L<PPI::Transform> object.
You can combine them in-place without writing specific modules.
Combined objects are sequentially applied.

=head1 METHODS

All of L<PPI::Transform> methods are inherited.

=head2 new(I<list>)

I<list> is sequential pairs of a PPI::Transform subclass name and an array reference of constructor arguments.
Even though there is no argument or only one argument, it is necessary to specify an array reference.
The order of I<list> is used as the application order of L<PPI::Transform> objects.

=head2 idx(I<index>)

Accessor of combined objects. I<index> is a 0-based number in I<list>, which are arguments of C<new>.

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
