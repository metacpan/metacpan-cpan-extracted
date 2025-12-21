# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Compactor for superstrings

package String::Super;

use v5.20;
use strict;
use warnings;

use Carp;

our $VERSION = v0.02;



sub new {
    my ($pkg, %opts) = @_;
    my $self = bless {
        strings => [],
        result => undef,
        keep_first => undef,
    }, $pkg;

    if (defined(my $prefix_blob = delete $opts{prefix_blob})) {
        $self->add_blob($prefix_blob);
        $self->{keep_first} = 1;
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub add_blob {
    my ($self, @blobs) = @_;
    my $res = scalar(@{$self->{strings}});

    croak 'Already compacted' if defined $self->{result};

    foreach my $blob (@blobs) {
        croak 'Provided blob is a reference' if ref $blob;
    }

    push(@{$self->{strings}}, @blobs);

    return $res;
}


sub add_utf8 {
    require Encode;

    my ($self, @strings) = @_;
    state $UTF_8 = Encode::find_encoding('UTF-8');

    foreach my $string (@strings) {
        croak 'Provided string is a reference' if ref $string;
    }

    return $self->add_blob(map {$UTF_8->encode($_)} @strings);
}


sub compact {
    my ($self, %opts) = @_;

    croak 'Stray options passed' if scalar keys %opts;

    return if defined $self->{result};

    {
        my @data = @{$self->{strings}};
        my $j_start = $self->{keep_first} ? 1 : 0;

        # eliminate all strings first that are already part of other strings
        outer:
        for (my $i = 0; $i < scalar(@data); $i++) {
            for (my $j = $j_start; $j < scalar(@data); $j++) {
                next if $i == $j;

                if (index($data[$i], $data[$j]) >= 0) {
                    splice(@data, $j, 1);
                    $i--;
                    next outer;
                }
            }
        }

        for (my $n = 8; $n > 0; $n--) {
            $self->_compact_n(\@data, $n);
        }

        $self->{result} = join('', @data);
    }
}


sub result {
    my ($self, %opts) = @_;

    croak 'Stray options passed' if scalar keys %opts;

    $self->compact;

    return $self->{result};
}


sub offset {
    my ($self, @args) = @_;
    my @res;

    while (scalar(@args) >= 2) {
        my ($key, $value) = (shift(@args), shift(@args));
        my $d;

        if ($key eq 'index') {
            $d = $self->{strings}[$value];
        } else {
            croak 'Invalid type: '.$key;
        }

        if (!defined($d)) {
            croak 'Undefined value';
        } elsif (ref($d)) {
            croak 'Not a valid value (reference passed as blob?)';
        }

        $d = index($self->{result}, $d);
        if ($d < 0) {
            croak 'Substring not found (this is most likely a bug in the callers code)';
        }

        push(@res, $d);
    }

    croak 'Stray options passed' if scalar @args;

    if (wantarray) {
        return @res;
    } else {
        croak 'Not exactly one result' unless scalar(@res) == 1;
        return $res[0];
    }
}

# ---- Private helpers ----

sub _compact_n {
    my ($self, $data, $n) = @_;
    my $j_start = $self->{keep_first} ? 1 : 0;

    outer:
    for (my $i = 0; $i < scalar(@{$data}); $i++) {
        my $suffix = substr($data->[$i], -$n);

        next if length($suffix) != $n;

        for (my $j = $j_start; $j < scalar(@{$data}); $j++) {
            next if $i == $j;

            #warn sprintf('%u, %u, -> %s, %s', $i, $j, defined($data->[$i]) ? 't' : 'f', defined($data->[$j]) ? 't' : 'f') unless defined($data->[$i]) && defined($data->[$j]);
            if ($suffix eq substr($data->[$j], 0, $n)) {
                substr($data->[$i], -$n, $n, $data->[$j]);
                splice(@{$data}, $j, 1);
                $i--;
                next outer;
            }
        }
    }
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Super - Compactor for superstrings

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use String::Super;

    my String::Super $super = String::Super->new;

    my $idx = $super->add_blob('Hello World!');
    my $idx = $super->add_utf8('Hello World!');
    my $res = $super->result;
    my $off = $super->offset(index => $idx);

This module tries to find the smallest superstring of a set of strings.
That is the smallest string that contains all the given strings.
As this is not a easy problem to solve this module tries to balance calculation complexity with result size.

Finding the smallest superstring is a common problem that has many applications.
It can be used as part of optimising executable sizes, as part of compression algorithms, string matching and analysis.

The general workflow is to prepare the input data and serialise them into blobs (the substrings),
adding them to an object of this module, asking the module to do it's magic, and then collecting both the result and the offset
for each blob into the result.

Data such as unicode strings, or other objects need to be encoded. This module works on raw 8 bit blobs (unless otherwise noted).
It is also totally 8 bit/binary safe.

=head1 METHODS

=head2 new

    my String::Super $super = String::Super->new( [ %opts ] );

Creates a new instance. Currently no options are supported.

This constructor C<die>s on any error.

The following options (all optional) are supported:

=over

=item C<prefix_blob>

(experimental since v0.02)

Adds a blob (as per L</add_blob>) which is included and will alaways have an offset of C<0> (even if this means inefficient packing).
This can be used to include data to which the offsets neet to be kept constant.

B<Note:>
Using this option may result in inefficient packing and/or some packing algorithms being disabled.

=back

=head2 add_blob

    my $first_index = $super->add_blob(@blobs);

Adds a number of blobs. A blob is any binary (8-bit) byte-string.

Objects (reference etc.) must not be passed.
Perl (unicode) strings must be encoded to the target character set before used with this method.
Use L</add_utf8> for strings.

The index of the first inserted blob is returned. If more than one blob is inserted the index is incremented by one for each blob.

This method C<die>s on any error.

=head2 add_utf8

    my $first_index = $super->add_utf8(@strings);

Adds a number of strings, encoding them as UTF-8.
The method is otherwise identical to L</add_blob>.

=head2 compact

    $super->compact;

This method compacts the string (calculates the resulting superstring).
If the string is already compacted this method does nothing.
Nothing is returned.

This method C<die>s on any error.

=head2 result

    my $res = $super->result;

This method returns the resulting superstring as a blob.
It takes no options.

If the string is not yet compacted L</compact> is automatically called.
This method C<die>s on any error.

=head2 offset

    my $off = $super->offset(index => $idx);
    # or:
    my @off = $super->offset(index => $idx0, index => $idx1);

This method returns the offset into the result (see L</result>) for the given type-value pairs.

Each pair consists of the type and a value for that type to ask for.

Currently the following types are defined:

=over

=item C<index>

The value is an index as returned by L</add_blob>.

=back

If the string is not yet compacted L</compact> is automatically called.
This method C<die>s on any error.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
