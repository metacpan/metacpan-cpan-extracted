package Monitoring::Reporter::Web::Plugin::Selftest;
{
  $Monitoring::Reporter::Web::Plugin::Selftest::VERSION = '0.01';
}
BEGIN {
  $Monitoring::Reporter::Web::Plugin::Selftest::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Monitoring Server Selftest

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
extends 'Monitoring::Reporter::Web::Plugin';
# has ...
# with ...
# initializers ...
sub _init_fields { return [qw()]; }

sub _init_alias { return 'healthcheck'; }

# your code here ...
sub execute {
   my $self = shift;
   my $request = shift;

   my ($ok, $msg_ref) = $self->mr()->selftest();
   my $body = join("\n", @{$msg_ref});
   my $status = 100;

   if($ok) {
     $body = join("\n", @{$msg_ref});
     $status = 200;
   } else {
      $status = 503;
   }

    return [ $status, [
      'Content-Type', 'text/plain',
      'Cache-Control', 'no-store, private', # no caching for the selftest
    ], [$body] ];
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Reporter::Web::Plugin::Selftest - Monitoring Server Selftest

=head1 METHODS

=head2 execute

Perform an Monitoring Server Selftest/Healthcheck

=head1 NAME

Monitoring::Reporter::Web::API::Plugin::Selftest - Perform an Monitoring Server Selftest

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
