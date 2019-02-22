package MooX::Emulate::Class::Accessor::Fast;
our $VERSION = '0.05';

=head1 NAME

MooX::Emulate::Class::Accessor::Fast - Emulate Class::Accessor::Fast behavior using Moo attributes.

=head1 SYNOPSYS

  package MyClass;
  use Moo;
  
  with 'MooX::Emulate::Class::Accessor::Fast';
  
  # Fields with readers and writers:
  __PACKAGE__->mk_accessors(qw/field1 field2/);
  
  # Fields with readers only:
  __PACKAGE__->mk_ro_accessors(qw/field3 field4/);
  
  # Fields with writers only:
  __PACKAGE__->mk_wo_accessors(qw/field5 field6/);


=head1 DESCRIPTION

This module attempts to emulate the behavior of L<Class::Accessor::Fast> as
accurately as possible using the Moo attribute system. The public API of
Class::Accessor::Fast is wholly supported, but the private methods are not.
If you are only using the public methods (as you should) migration should be a
matter of switching your C<use base> line to a C<with> line.

This module is a straight fork-and-port of L<MooseX::Emulate::Class::Accessor::Fast>
version C<0.00903> for L<Moo>.  All tests from the original Moose module pass or
were, as little as possible, modified to pass.  Much of the documentation, code
concepts, and tests are just straight copied from the original module.  The core
functionality, though, had to be a complete rewrite for Moo.

While we have attempted to emulate the behavior of Class::Accessor::Fast as closely
as possible bugs may still be lurking in edge-cases.

=head1 BEHAVIOR

Simple documentation is provided here for your convenience, but for more thorough
documentation please see L<Class::Accessor::Fast> and L<Class::Accessor>.

=cut

use Package::Stash;
use Class::Method::Modifiers qw( install_modifier );
use Carp qw( croak );

use Moo::Role;

sub BUILD { }

around BUILD => sub {
  my $orig = shift;
  my $self = shift;

  my %args = %{ $_[0] };
  $self->$orig(\%args);

  my @extra = grep { !exists($self->{$_}) } keys %args;
  @{$self}{@extra} = @args{@extra};

  return $self;
};

=head1 METHODS

=head2 mk_accessors

  __PACKAGE__->mk_accessors( @field_names );

See L<Class::Accessor/mk_accessors>.

=cut

sub mk_accessors {
  my ($class, @fields) = @_;

  foreach my $field (@fields) {
    $class->make_accessor( $field );
  }

  return;
}

=head2 mk_ro_accessors

  __PACKAGE__->mk_ro_accessors( @field_names );

See L<Class::Accessor/mk_ro_accessors>.

=cut

sub mk_ro_accessors {
  my ($class, @fields) = @_;

  foreach my $field (@fields) {
    $class->make_ro_accessor( $field );
  }

  return;
}

=head2 mk_wo_accessors

  __PACKAGE__->mk_wo_accessors( @field_names );

See L<Class::Accessor/mk_wo_accessors>.

=cut

sub mk_wo_accessors {
  my ($class, @fields) = @_;

  foreach my $field (@fields) {
    $class->make_wo_accessor( $field );
  }

  return;
}

=head2 follow_best_practice

  __PACKAGE__->follow_best_practice();

See L<Class::Accessor/follow_best_practice>.

=cut

sub follow_best_practice {
  my ($class) = @_;

  my $stash = Package::Stash->new( $class );

  $stash->add_symbol(
    '&mutator_name_for',
    sub{ 'set_' . $_[1] },
  );

  $stash->add_symbol(
    '&accessor_name_for',
    sub{ 'get_' . $_[1] },
  );

  return;
}

=head2 mutator_name_for

  sub mutator_name_for { 'change_' . $_[1] }

See L<Class::Accessor/MAKING ACCESSORS>.

=cut

sub mutator_name_for  { $_[1] }

=head2 accessor_name_for

  sub accessor_name_for { 'retrieve_' . $_[1] }

See L<Class::Accessor/MAKING ACCESSORS>.

=cut

sub accessor_name_for { $_[1] }

=head2 set

  $object->set( $field => $value );

See L<Class::Accessor/set>.

=cut

sub set {
  my $self = shift;
  my $field = shift;

  my $method = "_set_moocaf_$field";
  return $self->$method( @_ );
}

=head2 get

  my $value = $object->get( $field );
  my @values = $object->get( $field1, $field2 );

See L<Class::Accessor/get>.

=cut

sub get {
  my $self = shift;

  my @values;
  foreach my $field (@_) {
    my $method = "_get_moocaf_$field";
    push @values, $self->$method();
  }

  return $values[0] if @values==1;
  return @values;
}

sub _make_moocaf_accessor {
  my ($class, $field, $type) = @_;

  if (! do { no strict 'refs'; defined &{"${class}::has"} } ) {
    require Moo;
    my $ok = eval "package $class; use Moo; 1";
    croak "Failed to import Moo into $class" if !$ok;
  }

  my $private_reader = "_get_moocaf_$field";
  my $private_writer = "_set_moocaf_$field";

  if (!$class->can($private_reader)) {
    $class->can('has')->(
      $field,
      is     => 'rw',
      reader => $private_reader,
      writer => $private_writer,
    );

    install_modifier(
      $class, 'around', $private_writer,
      sub{
        my $orig = shift;
        my $self = shift;
        return $self->$orig() if !@_;
        my $value = (@_>1) ? [@_] : $_[0];
        $self->$orig( $value );
        return $self;
      },
    );
  }

  my $reader = $class->accessor_name_for( $field );
  my $writer = $class->mutator_name_for( $field );

  $reader = undef if $type eq 'wo';
  $writer = undef if $type eq 'ro';

  my $stash = Package::Stash->new( $class );

  if (($reader and $writer) and ($reader eq $writer)) {
    $stash->add_symbol(
      '&' . $reader,
      sub{
        my $self = shift;
        return $self->$private_reader() if !@_;
        return $self->$private_writer( @_ );
      },
    ) if !$stash->has_symbol('&' . $reader);
  }
  else {
    $stash->add_symbol(
      '&' . $reader,
      sub{ shift()->$private_reader( @_ ) },
    ) if $reader and !$stash->has_symbol('&' . $reader);

    $stash->add_symbol(
      '&' . $writer,
      sub{ shift()->$private_writer( @_ ) },
    ) if $writer and !$stash->has_symbol('&' . $writer);
  }

  return sub{
    my $self = shift;
    return $self->$private_reader( @_ ) unless @_ and $type ne 'wo';
    return $self->$private_writer( @_ );
  };
}

=head2 make_accessor

  my $coderef = $class->make_accessor( $field );

See L<Class::Accessor/make_accessor>.

=cut

sub make_accessor {
  my ($class, $field) = @_;
  return $class->_make_moocaf_accessor( $field, 'rw' );
}

=head2 make_ro_accessor

  my $coderef = $class->make_ro_accessor( $field );

See L<Class::Accessor/make_ro_accessor>.

=cut

sub make_ro_accessor {
  my ($class, $field) = @_;
  return $class->_make_moocaf_accessor( $field, 'ro' );
}

=head2 make_wo_accessor

  my $coderef = $class->make_wo_accessor( $field );

See L<Class::Accessor/make_wo_accessor>.

=cut

sub make_wo_accessor {
  my ($class, $field) = @_;
  return $class->_make_moocaf_accessor( $field, 'wo' );
}

1;
__END__

=head1 SEE ALSO

L<Moo>, L<Class::Accessor>, L<Class::Accessor::Fast>,
L<MooseX::Emulate::Class::Accessor::Fast>

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

Original code, tests, and documentation taken from
L<MooseX::Emulate::Class::Accessor::Fast>.  Thanks!

=head1 CONTRIBUTORS

=over

=item *

Graham Knop <haarg@haarg.org>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
