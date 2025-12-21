# Copyright (c) 2023-2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX Datecodes


package SIRTX::Datecode;

use v5.16;
use strict;
use warnings;

use Carp;

use Data::Identifier;

use parent qw(Data::Identifier::Interface::Userdata Data::Identifier::Interface::Simple Data::Identifier::Interface::Subobjects);

our $VERSION = v0.06;


sub new {
    my ($pkg, $type, $data, %opts) = @_;
    my $code;
    my $iso;

    croak 'Type or data not given' unless defined($type) && defined($data);

    if ($type eq 'from') {
        if (eval {$data->isa('SIRTX::Datecode')}) {
            $data = $data->datecode;
            $type = 'datecode';
        } elsif (eval {$data->isa('Data::Identifier') && $data->generator->eq('97b7f241-e1c5-4f02-ae3c-8e31e501e1dc')}) {
            $data = $data->request;
            $type = 'iso8601';
        } elsif (eval {$data->isa('DateTime')}) {
            if ($data->time_zone->isa('DateTime::TimeZone::Floating')) {
                $data = $data->ymd;
                $type = 'iso8601';
            } else {
                $data = $data->epoch;
                $type = 'epoch';
            }
        } elsif (eval {$data->can('epoch')}) {
            $data = $data->epoch;
            $type = 'epoch';
        } elsif ($data =~ /^[12][0-9]{3}(?:-[0-9]{2}(?:-[0-9]{2})?)?Z?$/) {
            $type = 'iso8601';
        } elsif ($data eq 'now') {
            $data = time();
            $type = 'epoch';
        } elsif ($data eq 'null') {
            $data = 0;
            $type = 'datecode';
        } else {
            croak 'Invalid data: '.$data;
        }
    }

    if ($type eq 'datecode' && $data =~ /^(0|[1-9][0-9]*)$/) {
        $code = int $data;
    } elsif ($type eq 'epoch' && $data =~ /^-?(0|[1-9][0-9]*)$/) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(int($data));
        $iso = sprintf('%04u-%02u-%02uZ', $year + 1900, $mon, $mday);
    } elsif ($type eq 'iso8601' && $data =~ /^[12][0-9]{3}(?:-[0-9]{2}(?:-[0-9]{2})?)?Z?$/) {
        $iso = $data;
    } else {
        croak 'Invalid type/data: '.$type;
    }

    croak 'Stray options passed' if scalar keys %opts;

    $code //= $pkg->_build_from_iso($iso);

    croak 'Invalid datecode value' if $code == 1;

    return bless({datecode => $code}, $pkg);
}


sub null {
    my ($pkg, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return state $null = __PACKAGE__->new(from => 'null');
}


sub now {
    my ($pkg, @opts) = @_;

    return $pkg->new(from => 'now', @opts);
}


sub datecode {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{datecode};
}


sub iso8601 {
    my ($self, @opts) = @_;
    my $code = $self->{datecode};
    my ($year, $month, $day);
    my $utc;
    my $iso;

    croak 'Stray options passed' if scalar @opts;

    return $self->{iso8601} if defined $self->{iso8601};

    $utc = $code & 1;
    $code >>= 1;

    if ($code == 0) {
        return undef;
    } elsif ($code < 324) {
        $year = 1582 + $code - 1;
    } elsif ($code < 1299) {
        $code -= 324;
        $year  = int($code / 13) + 1905;
        $month =     $code % 13;
    } elsif ($code < 31714) {
        $code -= 1299;
        $year  = int($code / 385) + 1980;
        $code  =     $code % 385;
        if ($code) {
            $code -= 1;
            $month = int($code / 32) + 1;
            $day   =     $code % 32;
        }
    } elsif ($code < 32442) {
        $code -= 31714;
        $year  = int($code / 13) + 2059;
        $month =     $code % 13;
    } else {
        $year = 2114 + $code - 32441;
    }

    if ($year) {
        $self->{year} = $year;
        $iso  = sprintf('%04u', $year);

        if ($month) {
            $self->{month} = $month;
            $iso .= sprintf('-%02u', $month);
            if ($day) {
                $self->{day} = $day;
                $iso .= sprintf('-%02u', $day);
            }
        }

        $iso .= 'Z' if $utc;
    }

    return $self->{iso8601} = $iso;
}


sub as {
    my ($self, $as, %opts) = @_;

    croak 'No as given' unless defined $as;

    return $self if $as eq 'SIRTX::Datecode';

    croak 'Not supported: This is a null value' if     $self->is_null;

    if ($as eq 'DateTime') {
        my $year  = $self->year;
        my $month = $self->month;
        my $day   = $self->day;

        require DateTime;

        return DateTime->new(year => $year, month => $month, day => $day, ($self->is_utc ? (time_zone => 'UTC') : ()));
    }

    croak 'Not supported: This is not in UTC'   unless $self->is_utc;

    unless (defined $self->{'Data::Identifier'}) {
        require Data::Identifier::Generate;
        $self->{'Data::Identifier'} = Data::Identifier::Generate->date($self->iso8601);
    }

    return $self->{'Data::Identifier'} if $as eq 'Data::Identifier' && scalar(keys %opts) == 0;

    return $self->{'Data::Identifier'}->as($as, %opts);
}


sub eq {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    foreach my $dc ($self, $other) {
        if (!defined($dc)) {
            $dc = __PACKAGE__->null;
        } elsif (!eval {$dc->isa(__PACKAGE__)}) {
            $dc = __PACKAGE__->new(from => $dc);
        }
    }

    return $self->datecode == $other->datecode;
}


sub cmp {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    foreach my $dc ($self, $other) {
        if (!defined($dc)) {
            $dc = __PACKAGE__->null;
        } elsif (!eval {$dc->isa(__PACKAGE__)}) {
            $dc = __PACKAGE__->new(from => $dc);
        }
    }

    return $self->datecode <=> $other->datecode;
}


sub is_utc {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{datecode} & 1;
}


sub is_floating {
    my ($self, @opts) = @_;
    return !$self->is_utc(@opts);
}


sub is_null {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{datecode} == 0;
}


sub assert_16bit {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    unless ($self->{datecode} >= 0 && $self->{datecode} <= 0xFFFF) {
        croak 'Datecode is outside of 16 bit range';
    }

    return $self;
}


sub precision {
    my ($self, @opts) = @_;
    my $iso_len = length($self->iso8601 // '');

    croak 'Stray options passed' if scalar @opts;

    if ($iso_len <= 1) {
        return 'null';
    } elsif ($iso_len <= 5) {
        return 'year';
    } elsif ($iso_len <= 8) {
        return 'month';
    } elsif ($iso_len <= 11) {
        return 'day';
    }

    croak 'Invalid object state';
}


sub year {
    my ($self, @args) = @_;
    return $self->_get_part('year', @args);
}

sub month {
    my ($self, @args) = @_;
    return $self->_get_part('month', @args);
}

sub day {
    my ($self, @args) = @_;
    return $self->_get_part('day', @args);
}

# ---- Implementation of Data::Identifier::Interface::Simple ----

sub displayname {
    my ($self, $part, %opts) = @_;

    # compatibility
    delete $opts{default};
    delete $opts{no_defaults};

    croak 'Stray options passed' if scalar keys %opts;

    return $self->iso8601;
}

# ---- Private helpers ----

sub _build_from_iso {
    my ($pkg, $iso) = @_;
    my ($year, $month, $day, $utc) = $iso =~ /^([12][0-9]{3})(?:-([0-9]{2})(?:-([0-9]{2}))?)?(Z?)$/;
    my $code;

    $year   = int $year;
    $month  = defined($month) && length($month) ? int($month) : 0;
    $day    = defined($day)   && length($day)   ? int($day)   : 0;

    $day    = 0 unless $month;

    if ($year < 1582) {
        return undef;
    } elsif ($year >= 1582 && $year <= 1904) {
        $code = $year - 1582 + 1;
    } elsif ($year <= 1979) {
        $code = 324 + ($year - 1905) * 13 + $month;
    } elsif ($year <= 2058) {
        $code = 1299 + ($year - 1980) * 385 + ($month ? 1 : 0) + ($month - 1) * 32 + $day;
    } elsif ($year <= 2114) {
        $code = 31714 + ($year - 2059) * 13 + $month;
    } else {
        $code = 32441 + $year - 2114;
    }

    if (defined $code) {
        $code *= 2;
        $code |= $utc ? 1 : 0;
    }

    return $code;
}

sub _get_part {
    my ($self, $part, %opts) = @_;
    my $has_default = exists $opts{default};
    my $default     = delete $opts{default};

    delete $opts{no_defaults}; # compatibility

    croak 'Stray options passed' if scalar keys %opts;

    $self->iso8601; # fill cache

    return $self->{$part} if defined $self->{$part};

    return $default if $has_default;

    croak 'Value not available: '.$part;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::Datecode - module for interacting with SIRTX Datecodes

=head1 VERSION

version v0.06

=head1 SYNOPSIS

    use SIRTX::Datecode;

    my SIRTX::Datecode $dc = SIRTX::Datecode->new($type => $value [, %opts ]);

    my $iso8601 = $dc->iso8601;
    my $year    = $dc->year;

    if ($dc->eq($other)) {
        # ...
    }

This module provides support to convert between different date formats and SIRTX datecodes.
SIRTX datecodes allow to encode dates in the range of years 1582 to 2440 into just 16 bits
by using a variable precision. They also allow for numeric ordering over their full range.

This package inherits from
L<Data::Identifier::Interface::Userdata> (since v0.04),
L<Data::Identifier::Interface::Subobjects> (since v0.06),
and L<Data::Identifier::Interface::Simple> (experimental since v0.04).

=head1 METHODS

=head2 new

    my SIRTX::Datecode $dc = SIRTX::Datecode->new($type => $value [, %opts ]);

Creates a new datecode object using C<$type> and C<$value>.

The following types are defined:

=over

=item C<iso8601>

An ISO-8601 date string (C<YYYY-MM-DD>, C<YYYY-MM>, or C<YYYY>, all optionally suffixed with C<Z>).

=item C<datecode>

A datecode value (as integer).

=item C<epoch>

An epoch value as returned by L<perlfunc/time>.

=back

The special value C<from> is also supported as C<$type>.
If C<from> is used an object can be passed that is automatically converted.
In addition if the value is not reference (object) it is tried to be parsed as per C<iso8601>.
The special value C<now> can be used to create an object for the current time.
And the special value C<null> to create an null-object (since v0.03).

Currently C<from> supports at least the following types:
L<SIRTX::Datecode> (since v0.03),
some L<Data::Identifier> (since v0.03),
L<DateTime> (since v0.03),
and any type that supports a C<epoch()> method (since v0.03).

Currently no options are defined.

=head2 null

    my SIRTX::Datecode $dc = SIRTX::Datecode->null;

(since v0.03)

Returns a null datecode.

B<Note:>
It is not defined if this method will always return the same object or create a new one each time.

See also: L</is_null>.

=head2 now

    my SIRTX::Datecode $dc = SIRTX::Datecode->now;

(since v0.03)

Returns a new datecode object for the current time.

=head2 datecode

    my $datecode = $dc->datecode;

Returns the datecode as an integer date code.

=head2 iso8601

    my $iso8601 = $dc->iso8601;

Returns the datecode as an ISO-8601 date string.

=head2 as

    my $res = $dc->as($as, %opts);

(experimental since v0.02)

This is a proxy for L<Data::Identifier/as>.

=head2 eq

    my $bool = $dc->eq($other); # $identifier must be non-undef
    # or:
    my $bool = SIRTX::Datecode::eq($dc, $other); # $dc can be undef

(since v0.05)

Compares two datecodes to be equal.

If both datecodes are C<undef> they are considered equal.

If C<$dc> or C<$other> is not an instance of L<SIRTX::Datecode> or C<undef>
it is converted using L</new> with C<from>.

=head2 cmp

    my $val = $dc->cmp($other); # $dc must be non-undef
    # or:
    my $val = SIRTX::Datecode::cmp($dc, $other); # $dc can be undef

(since v0.05)

Compares two datecodes similar to C<E<lt>=E<gt>>. This method can be used to order datecodes.
To check for them to be equal see L</eq>.

The parameters are parsed the same way as L</eq>.

If this method is used for sorting the exact resulting order is not defined. However:

=over

=item *

The order is stable (for any given version of this module)

=item *

For any two datecodes with the same precision the order is chronological

=item *

For any two non-overlapping datecodes the order is chronological

=item *

The order is the same for C<$a-E<gt>cmp($b)> as for C<- $b-E<gt>cmp($a)>.

=back

=head2 is_utc

    my $bool = $dc->is_utc;

(since v0.03)

Returns a true-ish value if the datecode is in UTC or a false-ish value if it is floating.

See also: L</is_floating>.

=head2 is_floating

    my $bool = $dc->is_floating;

(since v0.03)

Returns a true-ish value if the datecode is floating or a false-ish value if it is in UTC.

See also: L</is_utc>.

=head2 is_null

    my $bool = $dc->is_null;

(since v0.03)

Returns a true-ish value if the datecode is the null value and false-ish otherwise.

=head2 assert_16bit

    $dc->assert_16bit;

(since v0.05)

Asserts that the datecode fits into 16 bit.
If it doesn't this method will C<die>.

=head2 precision

    my $precision = $dc->precision;

(since v0.03)

Returns the precision of the datecode.
This is one of: C<null>, C<year>, C<month>, or C<day>.

=head2 year, month, day

    my $year  = $dc->year( [ %opts ] );
    my $month = $dc->month( [ %opts ] );
    my $day   = $dc->day( [ %opts ] );

(since v0.04)

Returns the year, month, or day component individually.

If a value is not available those methods C<die>.

The following options are supported:

=over

=item C<default>

A value that is returned if the value is not available.
This can be set to C<undef> to switch from C<die>ing to returning C<undef>.

=item C<no_defaults>

Ignored. For compatibility with similar methods. May be supported in later releases.

=back

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
