package Physics::Terrain::Snapshot;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__

=encoding utf8

=head1 NAME

Physics::Terrain::Snapshot - everything a turn changes, kept to replay from

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $snap = $field->snapshot;
    my $out  = $field->run_turn(0, \@inputs, $shot);
    $field->restore($snap);
    my $again = $field->run_turn(0, \@inputs, $shot);

=head1 DESCRIPTION

An opaque copy of a field's mask, bodies, craters, graves, clock and random
state at one moment, made by L<Physics::Terrain/snapshot> and handed back to
L<Physics::Terrain/restore>. It is only good for the field it came from and
it goes away with its last reference.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
