package Sweet::Now;
use Moose;
use namespace::autoclean;

use Time::Piece;

has _localtime => (
    default => sub { localtime() },
    handles  => [ qw(
        hour
        hms
        min
        mdy
        mon
        mday
        sec
        tzoffset
        year
        ymd
        ) ],
    isa      => 'Time::Piece',
    is       => 'ro',
    required => 1,
);

sub dd { sprintf "%02d", shift->mday }

sub hh { sprintf "%02d", shift->hour }

sub mi { sprintf "%02d", shift->min }

sub mm { sprintf "%02d", shift->mon }

sub ss { sprintf "%02d", shift->sec }

sub yyyy { sprintf "%04d", shift->year }

sub hhmiss { shift->hms('') }

sub yyyymmddhhmiss {
    my $self = shift;

    my $yyyymmdd = $self->yyyymmdd;
    my $hhmiss   = $self->hhmiss;

    return "$yyyymmdd$hhmiss";
}

sub yyyymmdd { shift->ymd('') }

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Sweet::File

=head1 SYNOPSIS

    use Sweet::Now;

    my $now = Sweet::Now->new;

=head1 ATTRIBUTES

=head2 _localtime

Instance of L<Time::Piece>.

=head1 METHODS

=head2 dd

=head2 hh

=head2 hour

Delegated to L</_localtime>.

=head2 mi

=head2 min

Delegated to L</_localtime>.

=head2 mm

=head2 ss

=head2 hhmiss

=head2 tzoffset

Delegated to L</_localtime>.

=head2 year

Delegated to L</_localtime>.

=head2 yyyy

=head2 yyyymmdd

=head2 yyyymmddhhmiss

=cut

