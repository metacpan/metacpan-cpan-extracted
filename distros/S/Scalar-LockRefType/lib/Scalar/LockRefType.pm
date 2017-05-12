package Scalar::LockRefType;

use 5.010;
use strict;
use warnings;
use Carp;

our $VERSION = '0.03';

sub TIESCALAR {
    my ($class, $type) = @_;
    return bless {
        value => undef,
        type  => @_ < 2 ? undef
        : ref($type)    ? ref($type)
        : length($type) ? $type
        :                 ''
    };
}

sub FETCH { return $_[0]->{value} }

sub STORE {
    my ($self, $value) = @_;
    my $ref = ref $value // '';
    $self->{type} //= $ref;
    croak 'invalid reference type' if $ref ne $self->{type};
    return $self->{value} = $value;
}

__END__

=head1 NAME

 Scalar::LockRefType - simple scalar type checker

=head1 SYNOPSIS

 use Scalar::LockRefType;

 tie my $h1 => 'Scalar::LockRefType', {};
 tie my $h2 => 'Scalar::LockRefType', 'HASH';
 tie my $h3 => 'Scalar::LockRefType';

 $h1 = [];  # dies, violates the type
 $h2 = [];  # dies, violates the type

 $h3 = {};  # sets the type
 $h3 = [];  # dies

=head1 DESCRIPTION

This little module allows you to tie the type of a scalar to a specified
reference type. If the refererence type of an assignment violates the 
tied type, the assignment throws an exception.

=head1 AUTHOR

Heiko Schlittermann <hs@schlittermann.de>

=cut
