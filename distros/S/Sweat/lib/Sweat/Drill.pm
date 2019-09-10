package Sweat::Drill;

use warnings;
use strict;
use Types::Standard qw(Bool Str);

use List::Util qw(shuffle);

use Moo;
use namespace::clean;

has 'requires_a_chair' => (
    is => 'ro',
    default => 0,
    isa => Bool,
);

has 'name' => (
    is => 'ro',
    required => 1,
    isa => Str,
);

has 'requires_jumping' => (
    is => 'ro',
    default => 0,
    isa => Bool,
);

has 'requires_side_switching' => (
    is => 'ro',
    default => 0,
    isa => Bool,
);

has 'is_used' => (
    is => 'rw',
    default => 0,
    isa => Bool,
);

1;

=head1 Sweat::Drill - Library for the `sweat` command-line program

=head1 DESCRIPTION

This library is intended for internal use by the L<sweat> command-line program,
and as such offers no publicly documented methods.

=head1 SEE ALSO

L<sweat>

=head1 AUTHOR

Jason McIntosh <jmac@jmac.org>
