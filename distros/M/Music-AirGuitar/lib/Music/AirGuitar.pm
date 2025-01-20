# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Interface for air guitars


package Music::AirGuitar;

use v5.16;
use strict;
use warnings;

use Carp;

our $VERSION = v0.02;

my @_standard_types = qw(string Data::Identifier Data::TagDB::Tag Data::URIID::Base);

my %_valid_attribute_types = (
    displayname => [qw(string)],
    player      => \@_standard_types,
    strings     => [qw(uint)],
    keys        => [qw(uint)],
);

my %_attribute_defaults = (
    strings     => 6,
    keys        => 0,
);

{
    no strict 'refs'; # This is an invalid access, but it is the only one working in perl v5.24.1, the correct one segfaults.
    foreach my $attribute (keys %_valid_attribute_types) {
        *$attribute = sub { my ($self, @args) = @_; return $self->_attribute($attribute, @args); };
    }
}


sub new {
    my ($pkg, %opts) = @_;
    my $self = bless {}, $pkg;

    foreach my $attribute (keys %_valid_attribute_types) {
        if (defined(my $value = delete $opts{$attribute})) {
            my $found;

            foreach my $type (@{$_valid_attribute_types{$attribute}}) {
                if ($type eq 'string') {
                    $found = !ref($value);
                } elsif ($type eq 'uint') {
                    $found = !ref($value) && $value =~ /^[0-9]+$/;
                    $value = int($value) if $found;
                } elsif (eval {$value->isa($type)}) {
                    $found = 1;
                }

                last if $found;
            }

            croak 'Type mismatch for attribute: '.$attribute unless $found;;

            $self->{$attribute} = $value;
        }
    }

    croak 'Invalid options present: '.join(', ', keys %opts) if scalar(keys %opts);

    foreach my $attribute (keys %_attribute_defaults) {
        $self->{$attribute} //= $_attribute_defaults{$attribute};
    }

    unless ($self->{strings} || $self->{keys}) {
        croak 'Your guitar has no strings nor keys. Kinda dull!';
    }

    return $self;
}


sub perform {
    my ($self, %opts) = @_;
    my $duration = $opts{duration} // '5:55';

    if ($duration =~ /:/) {
        my $s = 0;

        foreach my $c (split /:/, $duration) {
            $s *= 60;
            $s += $c;
        }

        $duration = $s;
    } else {
        $duration = int($duration);
    }

    require Music::AirGuitar::Performance;

    return Music::AirGuitar::Performance->_new(guitar => $self, duration => $duration);
}



# ---- Private helpers ----

sub _attribute {
    my ($self, $key, %opts) = @_;
    return $self->{$key} if defined $self->{$key};
    return $opts{default} if exists $opts{default};
    croak 'No data for attribute: '.$key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::AirGuitar - Interface for air guitars

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use Music::AirGuitar;

    my Music::AirGuitar $guitar = Music::AirGuitar->new(...);

=head1 METHODS

=head2 new

    my Music::AirGuitar $guitar = Music::AirGuitar->new(...);

Creates a new instance of an air guitar.

This constructor supports the following options, please see their getters for details:
L</displayname>,
L</player>,
L</strings>,
L</keys>.

=head2 perform

    my Music::AirGuitar::Performance $performance = $guitar->perform(%opts);

Go on a performance with this guitar.

Returns a L<Music::AirGuitar::Performance>.

The following options are supported:

=over

=item C<duration>

The duration of the performance. As a number of seconds or as a string in form C<[HH:]MM:SS>.
The default is C<5:55> (the length of I<Bohemian Rhapsody>).

=back

=head1 GETTERS

All getters return the value as given to the constructor (unless otherwise given).
If no value is available they C<die>.

All getters support setting the option C<default> to a default value that is used if non is available.
This can be set to C<undef> to switch the getter from C<die>ing to returning C<undef>.

=head2 displayname

    my $displayname = $guitar->displayname(%opts);

This returns the displayname of the guitar.

Supported types: string.

Default: none. (Subject to change!)

=head2 player

    my $player = $guitar->player(%opts);

This is the player (or performer) of the guitar.

Supported types: string, L<Data::Identifier>, L<Data::TagDB::Tag>, and L<Data::URIID::Base>.

Default: none. (Subject to change!)

=head2 strings

    my $strings = $guitar->strings(%opts);

The number of strings the guitar has.

Supported types: non-negative integer.

Default: 6.

=head2 keys

    my $keys = $guitar->keys(%opts);

The number of keys the guitar has. If it has keys it is a Keytar. Most don't.

Supported types: non-negative integer.

Default: 0.

=head1 BUGS

Someone might consider this module helpful.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
