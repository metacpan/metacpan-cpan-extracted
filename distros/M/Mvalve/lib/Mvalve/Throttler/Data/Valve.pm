# $Id: /mirror/coderepos/lang/perl/Mvalve/trunk/lib/Mvalve/Throttler/Data/Valve.pm 65640 2008-07-14T02:23:54.737244Z daisuke  $

package Mvalve::Throttler::Data::Valve;
use Moose;
extends 'Data::Valve';

override 'interval' => sub { super() };
override 'max_items' => sub { super() };
override 'new' => sub { super() };

with 'Mvalve::Throttler';

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 NAME 

Mvalve::Throttler::Data::Valve - Data::Valve Throttler

=cut