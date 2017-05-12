package MooX::SetOnce;
use strictures 1;

our $VERSION = '0.001003';
$VERSION = eval $VERSION;

use Carp;
use Class::Method::Modifiers qw(install_modifier);

sub import {
  my ($class) = @_;
  my $target = caller;

  install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attr, %opts) = @_;
    return $orig->($attr, %opts)
      unless delete $opts{once};

    my $is = $opts{is};
    my $writer = $opts{writer};
    if ($is eq 'rw') {
      $writer ||= $attr;
    }
    elsif ($is eq 'rwp') {
      $writer ||= "_set_$attr";
    }
    else {
      croak "SetOnce can't be used on read-only accessors";
    }
    my $predicate = $opts{predicate} ||= '_has_' . $attr;

    $opts{moosify} ||= [];
    push @{$opts{moosify}}, sub {
      my ($spec) = @_;
      require # hide from CPANTS
        MooseX::SetOnce;
      $spec->{traits} ||= [];
      push @{$spec->{traits}}, 'SetOnce';
    };

    $orig->($attr, %opts);

    $target->can('before')->($writer, sub {
      my ($self) = @_;
      if (@_ > 1 && $self->$predicate) {
        croak "cannot change value of SetOnce attribute $attr";
      }
    });
  }
}

1;

__END__

=head1 NAME

MooX::SetOnce - write-once attributes for Moo

=head1 SYNOPSIS

  package MyClass;
  use Moo;
  use MooX::SetOnce;

  has attr => ( is => 'rw', once => 1 );

=head1 DESCRIPTION

MooX::SetOnce creates attributes that are not lazy and not set, but
that cannot be altered once set.

The logic is very simple: if you try to alter the value of an
attribute with the SetOnce trait, either by accessor or writer, and
the attribute has a value, it will throw an exception.

If the attribute has a clearer, you may clear the attribute and set
it again.

If a Moose module extends or composes a module using MooX::SetOnce,
MooseX::SetOnce will be loaded to provide the Moose implementation.

=head1 SEE ALSO

=over 4

=item L<MooseX::SetOnce>

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2013 the MooX::SetOnce L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
