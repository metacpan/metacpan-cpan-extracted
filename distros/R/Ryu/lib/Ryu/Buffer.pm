package Ryu::Buffer;

use strict;
use warnings;

our $VERSION = '4.001'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(Ryu::Node);

=encoding utf8

=head1 NAME

Ryu::Buffer - accumulate data

=head1 DESCRIPTION

Provides a simple way to push bytes or characters into a buffer,
and get them back out again.

Typically of use for delimiter-based or fixed-size protocols.

See also L<Future::Buffer>, if you're dealing exclusively with L<Future>
instances and don't need the L<Ryu::Source> functionality then that's
likely to be a better option.

=cut

use curry;
use List::Util qw(min max);

=head1 METHODS

=cut

=head2 new

Instantiates a new, empty L<Ryu::Buffer>.

=cut

sub new {
    my ($class, %args) = @_;
    $args{data} //= '';
    $args{ops} //= [];
    my $self = $class->next::method(%args);
    return $self;
}

=head1 METHODS - Reading data

These methods provide ways of accessing the buffer either
destructively (C<read*>) or non-destructively (C<peek*>).

=cut

=head2 read_exactly

Reads exactly the given number of bytes or characters.

Takes the following parameters:

=over 4

=item * C<$size> - number of characters or bytes to return

=back

Returns a L<Future> which will resolve to a scalar containing the requested data.

=cut

sub read_exactly {
    my ($self, $size) = @_;
    my $f = $self->new_future;
    push @{$self->{ops}}, $self->$curry::weak(sub {
        my ($self) = @_;
        return $f if $f->is_ready;
        return $f unless $size <= length($self->{data});
        my $data = substr($self->{data}, 0, $size, '');
        $f->done($data);
        $self->on_change;
        return $f;
    });
    $self->process_pending;
    $f;
}

=head2 read_atmost

Reads up to the given number of bytes or characters - if
we have at least one byte or character in the buffer, we'll
return that even if it's shorter than the requested C<$size>.
This method is guaranteed not to return B<more> than the
C<$size>.

Takes the following parameters:

=over 4

=item * C<$size> - maximum number of characters or bytes to return

=back

Returns a L<Future> which will resolve to a scalar containing the requested data.

=cut

sub read_atmost {
    my ($self, $size) = @_;
    my $f = $self->new_future;
    push @{$self->{ops}}, $self->$curry::weak(sub {
        my ($self) = @_;
        return $f if $f->is_ready;
        return $f unless length($self->{data});
        my $data = substr($self->{data}, 0, min($size, length($self->{data})), '');
        $f->done($data);
        $self->on_change;
        return $f;
    });
    $self->process_pending;
    $f;
}

=head2 read_atleast

Reads at least the given number of bytes or characters - if
we have a buffer that's the given size or larger, we'll
return everything available, even if it's larger than the
requested C<$size>.

Takes the following parameters:

=over 4

=item * C<$size> - minimum number of characters or bytes to return

=back

Returns a L<Future> which will resolve to a scalar containing the requested data.

=cut

sub read_atleast {
    my ($self, $size) = @_;
    my $f = $self->new_future;
    push @{$self->{ops}}, $self->$curry::weak(sub {
        my ($self) = @_;
        return $f if $f->is_ready;
        return $f unless length($self->{data}) >= $size;
        my $data = substr($self->{data}, 0, max($size, length($self->{data})), '');
        $f->done($data);
        $self->on_change;
        return $f;
    });
    $self->process_pending;
    $f;
}

=head2 read_until

Reads up to the given string or regex match.

Pass a C<< qr// >> instance if you want to use a regular expression to match,
or a plain string if you want exact-string matching behaviour.

The data returned will B<include> the match.

Takes the following parameters:

=over 4

=item * C<$match> - the string or regex to match against

=back

Returns a L<Future> which will resolve to the requested bytes or characters.

=cut

sub read_until {
    my ($self, $match) = @_;
    $match = qr/\Q$match/ unless ref($match) eq 'Regexp';
    my $f = $self->new_future;
    push @{$self->{ops}}, $self->$curry::weak(sub {
        my ($self) = @_;
        return $f if $f->is_ready;
        return $f unless length($self->{data});
        return $f unless $self->{data} =~ /$match/g;
        my $data = substr($self->{data}, 0, pos($self->{data}), '');
        $f->done($data);
        $self->on_change;
        return $f;
    });
    $self->process_pending;
    $f;
}

my $pack_characters = q{aAZbBhHcCWsSlLqQiInNvVjJfdFpPUwx};
my %character_sizes = map {
    $_ => length(pack("x[$_]", ""))
} split //, $pack_characters;

=head2 read_packed

Uses L<pack> template notation to define a pattern to extract.
Will attempt to accumulate enough bytes to fulfill the request,
then unpack and extract from the buffer.

This method only supports a B<very limited> subset of the
full L<pack> functionality - currently, this includes
sequences such as C<A4> or C<N1n1>, but does B<not> handle
multi-stage templates such as C<N/a*>.

These would need to parse the initial C<N1> bytes to
determine the full extent of the data to be processed, and
the logic for handling this is not yet implemented.

Takes the following parameters:

=over 4

=item * C<$format> - a L<pack>-style format string

=back

Returns a L<Future> which will resolve to the requested items,
of which there can be more than one depending on the format string.

=cut

sub read_packed {
    my ($self, $format) = @_;
    my $f = $self->new_future;
    my @handler;
    my $simple_format = $format;

    # Might as well avoid too much complexity
    # in the parser
    $simple_format =~ s{\[([0-9]+)\]}{$1}g;
    $simple_format =~ s{\s+}{}g;
    PARSER:
    while(1) {
        for($simple_format) {
            if(my ($char, $count) = /\G([$pack_characters])[!><]?([0-9]*)/gc) {
                $count *= $character_sizes{$char};
                push @handler, {
                    regex => qr/(.{$count})/,
                }
            }
            last PARSER unless pos($_) < length($_);
        }
    }
    my $re = join '', map { $_->{regex} } @handler;
    push @{$self->{ops}}, $self->$curry::weak(sub {
        my ($self) = @_;
        return $f if $f->is_ready;
        return $f unless length($self->{data});

        return $f unless $self->{data} =~ m{^$re};
        my @items = unpack $format, $self->{data};
        $self->{data} =~ s{^$re}{};
        $f->done(@items);
        $self->on_change;
        return $f;
    });
    $self->process_pending;
    $f;
}

=head2 write

Add more data to the buffer.

Call this with a single scalar, and the results will be appended
to the internal buffer, triggering any callbacks for read activity
as required.

=cut

sub write {
    my ($self, $data) = @_;
    $self->{data} .= $data;
    $self->process_pending if @{$self->{ops}};
    return $self;
}

=head2 size

Returns the current buffer size.

=cut

sub size { length(shift->{data}) }

=head2 is_empty

Returns true if the buffer is currently empty (size = 0), false otherwise.

=cut

sub is_empty { !length(shift->{data}) }

=head1 METHODS - Internal

These are documented for convenience, but generally not recommended
to call any of these directly.

=head2 data

Accessor for the internal buffer. Not recommended to use this,
but if you break it you get to keep all the pieces.

=cut

sub data { shift->{data} }

=head2 process_pending

Used internally to trigger callbacks once L</write> has been called.

=cut

sub process_pending {
    my ($self) = @_;
    while(1) {
        my ($op) = @{$self->{ops}} or return;
        my $f = $op->();
        return unless $f->is_ready;
        shift @{$self->{ops}};
    }
}

sub on_change {
    my ($self) = @_;
    $self->{on_change}->($self) if $self->{on_change};
    return;
}

=head2 new_future

Instantiates a new L<Future>, used to ensure we get something awaitable.

Can be overridden using C<$Ryu::FUTURE_FACTORY>.

=cut

sub new_future {
    my $self = shift;
    require Ryu;
    (
        $self->{new_future} //= $Ryu::FUTURE_FACTORY
    )->($self, @_)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2024. Licensed under the same terms as Perl itself.

