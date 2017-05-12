use v5.14.0;
use warnings;

package OS::Package::System;

# ABSTRACT: Determine OS version and type.
our $VERSION = '0.2.7'; # VERSION

use Moo;
use Types::Standard qw( Str Enum );
use Config;
use POSIX qw( uname );

has 'os' => (
    is       => 'rw',
    isa      => Str,
    default  => sub { return $Config{osname} },
    required => 1
);

has 'version' => (
    is       => 'rw',
    isa      => Str,
    default  => sub { my @uname = uname(); return $uname[2] },
    required => 1
);

has 'type' => (
    is       => 'rw',
    isa      => Str,
    default  => sub { my @uname = uname(); return $uname[4] },
    required => 1
);

#has 'bits' => ( is => 'rw', isa => Enum[qw[ 32 64 ]], required => 1 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::System - Determine OS version and type.

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 os

Host operating system.

=head2 type

Host type.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
