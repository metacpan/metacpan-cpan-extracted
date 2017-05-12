package Physics::Lorentz::Vector;

use 5.006;
use strict;
use warnings;
use PDL;
use Params::Util qw/_INSTANCE _ARRAY/;
use Carp qw/croak/;

our $VERSION = '0.01';

use overload
    '""' => \&stringify,
    '+' => \&_overload_add,
    ;

=head1 NAME

Physics::Lorentz::Vector - Representation of 4-vectors

=head1 SYNOPSIS

  use Physics::Lorentz;
  my $rotation = Physics::Lorentz::Transformation->rotation_euler(
    $alpha, $beta, $gamma
  );
  my $vector = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
  my $rotated = $rotation->apply($vector);
  # or: $rotated = $rotation * $vector;
  
  ...

=head1 DESCRIPTION

This class is a representation of 4-vectors (such as 4-space
C<[time, x, y, z]> or 4-momentum C<E, kx, ky, kz>).

=head2 EXPORT

None.

=head2 OVERLOADED INTERFACE

Addition (+) does the expected thing as does the assignment form (+=)
of it.

Stringification is overloaded with the C<stringify> method.

See also: L<Physics::Lorentz::Transformation>.

=head1 METHODS

=cut

=head2 new

Creates a new Physics::Lorentz::Vector object. Defaults to C<[0,0,0,0]>
or cloning if no arguments are specified.

If one argument is present, this argument may either be a PDL which will
be used internally as the PDL representation of the vector or an
array reference to an array of four elements.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    if (_INSTANCE($proto, 'Physics::Lorentz::Vector')) {
        $self = $proto->clone();
    }

    my $in = shift;
    if (ref(_INSTANCE($in, 'PDL'))) {
        my ($x, $y) = $in->dims;
        if ($x == 4 and $y == 1) {
            $in = $in->transpose;
        }
        elsif ($x == 1 and $y == 4) {
            $in = $in->new();
        }
        else {
            croak("${class}->new() needs a 4-vector as PDL or list");
        }
        $self->{pdl} = $in;
    }
    elsif (_ARRAY($in) and @$in == 4) {
        $self->{pdl} = pdl([$in])->transpose;
    }
    elsif (not defined $in) {
        $self->{pdl} = zeroes(1,4) if not defined $self->{pdl};
    }
    else {
        croak("${class}->new() needs a 4-vector as PDL or list");
    }
   
    return bless($self => $class);
}

=head2 clone

Returns a copy of the object.

=cut

sub clone {
    my $self = shift;
    my $new = {};
    $new->{pdl} = $self->{pdl}->new();
    return bless($new, ref($self));
}

=head2 stringify

Returns a string representation of the object. Currently, this is
the string representation of the internal PDL vector/matrix.

=cut

sub stringify {
    my $self = shift;
    return "".$self->{pdl};
}


=head2 add

Adds two vectors. Syntax:

  $v3 = $v1->add($v2);

(This leaves C<$v1> and C<$v2> unchanged!)

=cut

sub add {
    my $self = shift;
    my $v2 = shift;
    return $self->new($self->{pdl}+$v2->{pdl});
}


=head2 get_pdl

Returns the PDL representation of the object.
This is the actual PDL object used inside. Beware of action
at a distance.

=cut

sub get_pdl { $_[0]->{pdl} }



# Overloaded interface:

sub _overload_add {
    my ($self, $o2, $reverse) = @_;
    my $res = $self->add($o2);
    if (not defined $reverse) {
        $self->{pdl} = $res->{pdl};
        return $self;
    }
    return $res;
}

1;
__END__


=head1 SEE ALSO

L<PDL>, L<Physics::Lorentz>, L<Physics::Lorentz::Transformation>

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
