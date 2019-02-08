package Ryu::Observable;

use strict;
use warnings;

our $VERSION = '0.036'; # VERSION

=encoding utf8

=head1 NAME

Ryu::Observable - plus ça change

=head1 DESCRIPTION

This is by way of being a thing that lets you set up subscriptions on things
so that you can be notified when said things are in some way not the same as
the things they used to be, but are indeed now possessed of some detectable
difference which may be of relevance to the thing that makes use of this thing
which notifies as per the aforementioned conditions.

=cut

use overload
    '""'   => sub { shift->as_string },
    '0+'   => sub { shift->as_number },
    '++'   => sub { my $v = ++$_[0]->{value}; $_[0]->notify_all; $v },
    '--'   => sub { my $v = --$_[0]->{value}; $_[0]->notify_all; $v },
    'bool' => sub { shift->as_number },
    fallback => 1;

=head1 METHODS

Public API, such as it is.

=head2 as_string

Returns the string representation of this value.

=cut

sub as_string { '' . shift->{value} }

=head2 as_number

Returns the numeric representation of this value.

=cut

sub as_number { 0 + shift->{value} }

=head2 new

Instantiates with the given value.

 my $observed = Ryu::Observable->new('whatever');

=cut

sub new { bless { value => $_[1] }, $_[0] }

=head2 subscribe

Requests notifications when the value changes.

 my $observed = Ryu::Observable->new('whatever')
   ->subscribe(sub { print "New value - $_\n" });

=cut

sub subscribe { my $self = shift; push @{$self->{subscriptions}}, @_; $self }

=head2 unsubscribe

Removes an existing callback.

 my $code;
 my $observed = Ryu::Observable->new('whatever')
   ->subscribe($code = sub { print "New value - $_\n" })
   ->set_string('test')
   ->unsubscribe($code);

=cut

sub unsubscribe {
    use Scalar::Util qw(refaddr);
    use List::UtilsBy qw(extract_by);
    use namespace::clean qw(refaddr extract_by);
    my ($self, @code) = @_;
    for my $addr (map refaddr($_), @code) {
        extract_by { refaddr($_) == $addr } @{$self->{subscriptions}};
    }
    $self
}

=head2 set

Sets the value to the given scalar, then notifies all subscribers (regardless
of whether the value has changed or not).

=cut

sub set { my ($self, $v) = @_; $self->{value} = $v; $self->notify_all }

=head2 value

Returns the raw value.

=cut

sub value { shift->{value} }

=head2 set_numeric

Applies a new numeric value, and notifies subscribers if the value is numerically
different to the previous one (or if we had no previous value).

Returns C<$self>.

=cut

sub set_numeric {
    my ($self, $v) = @_;
    my $prev = $self->{value};
    return $self if defined($prev) && $prev == $v;
    $self->{value} = $v;
    $self->notify_all
}

=head2 set_string

Applies a new string value, and notifies subscribers if the value stringifies to a
different value than the previous one (or if we had no previous value).

Returns C<$self>.

=cut

sub set_string {
    my ($self, $v) = @_;
    my $prev = $self->{value};
    return $self if defined($prev) && $prev eq $v;
    $self->{value} = $v;
    $self->notify_all
}

=head2 source

Returns a L<Ryu::Source>, which will emit each new value
until the observable is destroyed.

=cut

sub source {
    use Scalar::Util qw(weaken);
    use namespace::clean qw(weaken);
    my ($self) = @_;
    my $src = Ryu::Source->new;
    weaken(my $copy = $self);
    $self->subscribe(my $code = sub {
        return unless my $self = $copy;
        $src->emit($self->value)
    });
    $src->completed->on_ready(sub {
        $copy->unsubscribe($code) if $copy;
        undef $code;
    });
    $src
}

=head1 METHODS - Internal

Don't use these.

=head2 notify_all

Notifies all currently-subscribed callbacks with the current value.

=cut

sub notify_all {
    my $self = shift;
    for my $sub (@{$self->{subscriptions}}) {
        $sub->($_) for $self->{value}
    }
    $self
}

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    $_->finish for splice @{$self->{sources} || []};
    delete $self->{value};
    return;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2019. Licensed under the same terms as Perl itself.

