package Ryu::Observable;

use strict;
use warnings;

use utf8;

our $VERSION = '2.008'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=encoding utf8

=head1 NAME

Ryu::Observable - plus ça change

=head1 SYNOPSIS

 # Set initial value
 my $observed = Ryu::Observable->new(123)
   # and a callback for any changes
   ->subscribe(sub { print "New value, is now: $_\n" });
 # Basic numeric increment/decrement should trigger a notification
 ++$observed;
 # To assign a new value, use ->set_numeric or ->set_string
 $observed->set_numeric(88);

=head1 DESCRIPTION

Simple monitorable variables.

=cut

use overload
    '""'   => sub { shift->as_string },
    '0+'   => sub { shift->as_number },
    '++'   => sub { my $v = ++$_[0]->{value}; $_[0]->notify_all; $v },
    '--'   => sub { my $v = --$_[0]->{value}; $_[0]->notify_all; $v },
    'bool' => sub { !!shift->{value} },
    fallback => 1;

use Scalar::Util;
use List::UtilsBy;

use Ryu::Source;

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
    my ($self, @code) = @_;
    for my $addr (map Scalar::Util::refaddr($_), @code) {
        List::UtilsBy::extract_by { Scalar::Util::refaddr($_) == $addr } @{$self->{subscriptions}};
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
    my ($self) = @_;
    $self->{source} //= do {
        my $src = Ryu::Source->new;
        Scalar::Util::weaken(my $copy = $self);
        $src->completed->on_ready(sub {
            delete $copy->{source} if $copy
        });
        $src;
    };
}

=head1 METHODS - Internal

Don't use these.

=head2 notify_all

Notifies all currently-subscribed callbacks with the current value.

=cut

sub notify_all {
    my $self = shift;
    my $v = $self->{value};
    $self->{source}->emit($v) if $self->{source};
    for my $sub (@{$self->{subscriptions}}) {
        $sub->($_) for $v;
    }
    $self
}

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    if(my $src = $self->{source}) {
        $src->finish;
    }
    delete $self->{value};
    return;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2021. Licensed under the same terms as Perl itself.

