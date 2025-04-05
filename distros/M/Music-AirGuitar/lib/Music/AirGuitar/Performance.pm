# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Interface for air guitars performances


package Music::AirGuitar::Performance;

use v5.16;
use strict;
use warnings;

use Carp;

use Music::AirGuitar;

our $VERSION = v0.03;

{
    no strict 'refs'; # This is an invalid access, but it is the only one working in perl v5.24.1, the correct one segfaults.
    foreach my $attribute (qw(guitar duration)) {
        *$attribute = sub { my ($self, @args) = @_; return $self->Music::AirGuitar::_attribute($attribute, @args); };
    }

    # proxy methods
    foreach my $attribute (qw(player)) {
        *$attribute = sub { my ($self, @args) = @_; return $self->guitar->_attribute($attribute, @args); };
    }
}


sub record {
    my ($self, $fn) = @_;
    my $filelen = ($self->duration * 48000 * 1 * (16/8)) + 44;
    my $fh;

    if (ref $fn) {
        $fh = $fn;
    } else {
        open($fh, '>', $fn) or croak 'Cannot open file: '.$fn.': '.$!;
    }

    $fh->binmode;
    $fh->print(pack('a4Va4', 'RIFF', $filelen - 8, 'WAVE'));
    $fh->print(pack('a4VvvVVvv', 'fmt ', 16, 1, 1, 48000, 48000 * 1 * 16/8, 1 * 16/8, 16));
    $fh->print(pack('a4V', 'data', $filelen - 44));
    $fh->truncate($filelen);

    return undef;
}


# ---- special getters ----


sub rating {
    my ($self, %opts) = @_;
    my $scale = $opts{scale} // 'of10';
    my $rating = $self->{rating};

    if ($scale eq 'of10') {
        return sprintf('%2.1f', $rating * 10);
    }

    croak 'Unknown/unsupported scale: '.$scale;
}

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;

    # Find a rating, be a bit more on the positive side.
    $opts{rating} = rand(1.2);
    $opts{rating} = 1 if $opts{rating} > 1;

    my $self = bless \%opts, $pkg;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::AirGuitar::Performance - Interface for air guitars performances

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use Music::AirGuitar;

    my Music::AirGuitar $guitar = Music::AirGuitar->new(...);

    my Music::AirGuitar::Performance $performance = $guitar->perform(%opts);

=head1 METHODS

=head2 record

    $performance->record($filename_or_handle);

Records the performance as a RIFF/WAVE file.

B<Note:>
If a handle is passed, it needs to support L<perlfunc/seek> and L<perlfunc/truncate>.

=head1 GETTERS

All getters return the value as given to the constructor (unless otherwise given).
If no value is available they C<die>.

All getters support setting the option C<default> to a default value that is used if non is available.
This can be set to C<undef> to switch the getter from C<die>ing to returning C<undef>.

=head2 guitar

    my Music::AirGuitar $guitar = $performance->guitar;

The L<Music::AirGuitar> that was used in this performance.

=head2 duration

    my $duration = $performance->duration;

The duration of the performance (in seconds).

=head2 player

    my $player = $performance->player;

This is a proxy for L<Music::AirGuitar/player>.

=head2 rating

    my $rating = $performance->rating(%opts);

Returns the rating for the performance by the jury.
It is not clear how the jury makes their opinion.
But it seems there is an element of random involved.

The following options are supported:

=over

=item C<default>

This option is ignored.

=item C<scale>

The scale to use.
Currently only the value C<of10> is supported, witch will return a value
in the range 0.0 .. 10.0 (inclusive).

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
