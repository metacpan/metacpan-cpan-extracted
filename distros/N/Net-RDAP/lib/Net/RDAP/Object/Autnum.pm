package Net::RDAP::Object::Autnum;
use base qw(Net::RDAP::Object);
use strict;
use warnings;

=head1 NAME

L<Net::RDAP::Object::Autnum> - a module representing an autonymous system.

=head1 DESCRIPTION

L<Net::RDAP::Object::Autnum> represents one or more autonymous system
numbers.

L<Net::RDAP::Object::Autnum> inherits from L<Net::RDAP::Object> so has
access to all that module's methods.

Other methods include:

    $start = $network->start;

Returns an integer representing the starting number in the block of
Autonomous System numbers.

    $end = $network->end;

Returns an integer representing the ending number in the block of
Autonomous System numbers.

    $name = $network->name;

Returns a string containing the identifier assigned to the autnum
registration by the registration holder.

    $type = $network->type;

Returns a string containing an RIR-specific classification of the
autnum.

    $country = $network->country;

Returns a string containing the two-character country code of the
autnum.

=cut

sub start       { $_[0]->{'startAutnum'}}
sub end         { $_[0]->{'endAutnum'}  }
sub name        { $_[0]->{'name'}       }
sub type        { $_[0]->{'type'}       }
sub country     { $_[0]->{'country'}    }

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
