package POE::Filter::SSL::PreFilter;

use strict;
use warnings;
use POE qw (Filter::HTTPD Filter::Stackable Wheel::ReadWrite);
use POE;

our $globalinfos = {};

BEGIN {
   our $PATCH = 18;
   no warnings 'redefine';
   my $old_set_input_filter = \&POE::Wheel::ReadWrite::set_input_filter;
   *POE::Wheel::ReadWrite::set_input_filter = sub {
      my $self = shift;
      my $new_filter = shift;
      my $unique_id = $self->[POE::Wheel::ReadWrite::UNIQUE_ID()];
      my $ret = $old_set_input_filter->($self, $new_filter, @_);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "input" => $self);
      return $ret;
   };
   my $old_set_output_filter = \&POE::Wheel::ReadWrite::set_output_filter;
   *POE::Wheel::ReadWrite::set_output_filter = sub {
      my $self = shift;
      my $new_filter = shift;
      my $unique_id = $self->[POE::Wheel::ReadWrite::UNIQUE_ID()];
      my $ret = $old_set_output_filter->($self, $new_filter, @_);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "output" => $self);
      return $ret;
   };
   my $old_new = \&POE::Wheel::ReadWrite::new;
   *POE::Wheel::ReadWrite::new = sub {
      my $class = shift;
      my %arg = @_;
      my $self = $old_new->($class,%arg);
      my $unique_id = $self->[POE::Wheel::ReadWrite::UNIQUE_ID];
      $poe_kernel->state(
         $self->[$PATCH] = ref($self) . "($unique_id) -> ssl patch",
         sub {
            my $type = $_[ARG0];
            my $self = $_[ARG1];
            if ($_[HEAP]->{self}->{PreFilter}) {
               $_[HEAP]->{self}->{"PreFilter".ref($self).$self->[POE::Wheel::ReadWrite::UNIQUE_ID()]} = $_[HEAP]->{self}->{PreFilter}->clone()
                  unless ($_[HEAP]->{self}->{"PreFilter".ref($self).$self->[POE::Wheel::ReadWrite::UNIQUE_ID()]});
               if ($type eq "input") {
                  $old_set_input_filter->($self, POE::Filter::Stackable->new(
                     Filters => [
                        $_[HEAP]->{self}->{"PreFilter".ref($self).$self->[POE::Wheel::ReadWrite::UNIQUE_ID()]},
                        $self->get_input_filter()
                     ]
                  ));
               } else {
                  $old_set_output_filter->($self, POE::Filter::Stackable->new(
                     Filters => [
                        $_[HEAP]->{self}->{"PreFilter".ref($self).$self->[POE::Wheel::ReadWrite::UNIQUE_ID()]},
                        $self->get_output_filter()
                     ]
                  ));
               }
            }
         }
      );
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "input" => $self);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "output" => $self);
      return $self;
   };
   my $old_set_filter = \&POE::Wheel::ReadWrite::set_filter;
   *POE::Wheel::ReadWrite::set_filter = sub {
      my $self = shift;
      my $new_filter = shift;
      my $unique_id = $self->[POE::Wheel::ReadWrite::UNIQUE_ID()];
      my $ret = $old_set_filter->($self, $new_filter, @_);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "input" => $self);
      $poe_kernel->yield(ref($self) . "($unique_id) -> ssl patch" => "output" => $self);
      return $ret;
   };
   my $old_destroy = \&POE::Wheel::ReadWrite::DESTROY;
   *POE::Wheel::ReadWrite::DESTROY = sub {
      my $self = shift;
      if ($self->[$PATCH]) {
         $poe_kernel->state($self->[$PATCH]);
         $self->[$PATCH] = undef;
      }
      return $old_destroy->($self, @_);
   };
   *POE::Filter::HTTPD::get_pending = sub {
      return undef;
   };
   use warnings 'redefine';
}


=head1 NAME

POE::Filter::SSL::Prefilter - Allow to add a PreFilter on Compontents using Wheels

=head1 VERSION

Version 0.39

=head1 DESCRIPTION

This is an extension for some POE::Component::Server modules to use POE::Filters in front of their own used Filters

=back

=head1 SYNOPSIS

By default filters like I<POE::Filter::SSL> can only be used if you specify the filters by
manualy creating the POE::Wheel by our own. This allows this to be done if a compontent is doing this.

=over 2

=item HTTPS-Server

  use POE::Filter::SSL;
  use POE::Component::Server::HTTP;
  use HTTP::Status;
  my $aliases = POE::Component::Server::HTTP->new(
    Port => 443,
    ContentHandler => {
      '/' => \&handler,
      '/dir/' => sub { return; },
      '/file' => sub { return; }
    },
    Headers => { Server => 'My Server' },
    PreFilter => POE::Filter::SSL->new(
      crt    => 'server.crt',
      key    => 'server.key',
      cacrt  => 'ca.crt'
    )
  );

  sub handler {
    my ($request, $response) = @_;
    $response->code(RC_OK);
    $response->content("Hi, you fetched ". $request->uri);
    return RC_OK;
  }

  POE::Kernel->run();
  POE::Kernel->call($aliases->{httpd}, "shutdown");
  # next line isn't really needed
  POE::Kernel->call($aliases->{tcp}, "shutdown");

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010-2017 Markus Schraeder, CryptoMagic GmbH, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of POE::Filter::SSL::PreFilter
