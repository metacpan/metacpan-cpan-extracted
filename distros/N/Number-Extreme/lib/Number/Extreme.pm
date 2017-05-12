package Number::Extreme;

use strict;
use 5.008_001;
our $VERSION = '0.29';

use overload
    '"0+"' => sub { $_[0]{current_value} },
    '""'   => sub { $_[0]{current_value} },
    fallback => 1;

sub new {
    my ($class, %args) = @_;
    bless \%args, __PACKAGE__;
}

sub max {
    my $class     = shift;
    my $extractor = shift;

    return $class->new(
        cmp           => sub { $_[1] > $_[0] },
        extractor     => $extractor,
        current_value => undef,
        current       => undef,
    );
}

sub min {
    my $class     = shift;
    my $extractor = shift;

    return $class->new(
        cmp           => sub { $_[1] < $_[0] },
        extractor     => $extractor,
        current_value => undef,
        current       => undef,
        @_,
    );
}

sub amax {
    my ($class, $array) = @_;
    $class->max(sub { $array->[$_] });
}

sub amin {
    my ($class, $array) = @_;
    $class->min(sub { $array->[$_] });
}

sub test {
    my ($self, $object) = @_;
    local $_ = $object;
    my $value = $self->{extractor} ? $self->{extractor}->() : $_;

    if (!defined $self->{current_value} ||
        $self->{cmp}->($self->{current_value}, $value)) {
        $self->{current} = $_;
        $self->{current_value} = $value;
        return 1;
    }
}

sub current_value { $_[0]->{current_value} }
sub current       { $_[0]->{current} }

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Number::Extreme - Helper for keeping track of extreme values of objects

=head1 SYNOPSIS

  use Number::Extreme;

  # a bunch of objects with the "high" attribute.
  my $id = 0;
  my @objects = map { { id => $id++, high => $_ } } shuffle (1..100);

  # create a highest-high tracker, which extracts "high" from given objects
  my $highest_high = Number::Extreme->max(sub { $_->{high} });

  # test the values
  $highest_high->test($_) for @objects;

  # now you have the highest high
  warn $highest_high;

  # and the object of that high
  warn $highest_high->current->{id};

=head1 DESCRIPTION

Number::Extreme provides simple utility for a common task: tracking
highest or lowest value of an attribute of objects, while keeping
track of which object is of the extreme value.

=head2 METHODS

=over

=item $class->max($extractor)

=item $class->min($extractor)

Helper constructors for creating max/min tracker.  C<$extractor> takes
C<$_> as the object to be tested, and returns the attribute to be
compared.

=item $class->amax($array)

=item $class->amin($array)

Helper constructors for tracking max/min values of an
arrayref. C<test()> should be called with the array index.

=item $obj->test($o)

Update the tracker with new incoming object.

=back

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
