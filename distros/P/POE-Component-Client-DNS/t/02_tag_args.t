#!/usr/bin/perl -w
# tag@cpan.org

use strict;
use POE qw(Component::Client::DNS);
use Data::Dumper;

use Test::More tests => 5;
use Test::NoWarnings;

my $reverse = "127.0.0.1";

POE::Component::Client::DNS->spawn(
  Alias   => 'named',
  Timeout => 5,
);

POE::Session->create(
  inline_states  => {
    _start => sub {
      for (1..4) {
        $_[KERNEL]->post(
          named => resolve =>
          [ reverse => "TEST WORKED" ] =>
          $reverse, 'PTR'
        );
      }
    },

    _stop => sub { }, # for asserts

    reverse => sub {
			is( $_[ARG0][3], "TEST WORKED", "test worked" );
    },
  }
);

POE::Kernel->run;

exit 0;
