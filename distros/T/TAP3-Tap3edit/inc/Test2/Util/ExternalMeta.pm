#line 1
package Test2::Util::ExternalMeta;
use strict;
use warnings;

our $VERSION = '1.302175';


use Carp qw/croak/;

sub META_KEY() { '_meta' }

our @EXPORT = qw/meta set_meta get_meta delete_meta/;
BEGIN { require Exporter; our @ISA = qw(Exporter) }

sub set_meta {
    my $self = shift;
    my ($key, $value) = @_;

    validate_key($key);

    $self->{+META_KEY} ||= {};
    $self->{+META_KEY}->{$key} = $value;
}

sub get_meta {
    my $self = shift;
    my ($key) = @_;

    validate_key($key);

    my $meta = $self->{+META_KEY} or return undef;
    return $meta->{$key};
}

sub delete_meta {
    my $self = shift;
    my ($key) = @_;

    validate_key($key);

    my $meta = $self->{+META_KEY} or return undef;
    delete $meta->{$key};
}

sub meta {
    my $self = shift;
    my ($key, $default) = @_;

    validate_key($key);

    my $meta = $self->{+META_KEY};
    return undef unless $meta || defined($default);

    unless($meta) {
        $meta = {};
        $self->{+META_KEY} = $meta;
    }

    $meta->{$key} = $default
        if defined($default) && !defined($meta->{$key});

    return $meta->{$key};
}

sub validate_key {
    my $key = shift;

    return if $key && !ref($key);

    my $render_key = defined($key) ? "'$key'" : 'undef';
    croak "Invalid META key: $render_key, keys must be true, and may not be references";
}

1;

__END__

#line 182
