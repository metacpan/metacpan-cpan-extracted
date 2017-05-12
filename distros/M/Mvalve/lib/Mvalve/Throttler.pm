# $Id: /mirror/coderepos/lang/perl/Mvalve/trunk/lib/Mvalve/Throttler.pm 65640 2008-07-14T02:23:54.737244Z daisuke  $

package Mvalve::Throttler;
use Moose::Role;

requires qw(try_push interval max_items);

no Moose;

1;

__END__

=head1 NAME

Mvalve::Throttler - Throttler Role

=head1 SYNOPSIS

  package MyThrottler;
  use Moose;

  with 'Mvalve::Throttler';

  no Moose;

  sub try_push  {}
  sub interval  {}
  sub max_items {}

=cut