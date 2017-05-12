use strict;
use warnings;

package POE::Declarative::Mixin;
BEGIN {
  $POE::Declarative::Mixin::VERSION = '0.09';
}

use POE::Declarative ();

=head1 NAME

POE::Declarative::Mixin - use different declarative POE packages together

=head1 VERSION

version 0.09

=head1 SYNOPSIS

This is a really poor producer/consumer example, but it shows how the states of each mixin get pulled into the second class.

  package Producer;
  use base qw/ POE::Declarative::Mixin /;

  use POE;
  use POE::Declarative;

  on produce => run {
      push @{ get(HEAP)->{store} }, get ARG0;
  };

  package Consumer;
  use base qw/ POE::Declarative::Mixin /;

  use POE;
  use POE::Declarative;

  on consume => run {
      print "Consuming ", shift @{ get(HEAP)->{store} }, "\n";

      yield 'consume' if scalar @{ get(HEAP)->{store} };
  };

  package ProducerConsumer;

  use POE;
  use POE::Declarative;

  # Our mixins
  use Consumer;
  use Producer;

  on _start => run {
      for (1 .. 10) {
          yield produce => $_;
      }

      yield 'consume';
  };

=head1 DESCRIPTION

Mixin classes provide a nice abstraction for joining multiple functions together into a single package. This is similar to multiple inheritance, but doesn't modify C<@ISA> for the class.

=head1 METHODS

=head2 import

This provides the basic magic to make this happen. If you are creating a mixin class that needs to further customize C<import>, you'll probably want to see L</export_poe_declarative_to_level>.

=cut

sub import {
    my $class = shift;

    $class->export_poe_declarative_to_level;
}

=head2 export_poe_declarative_to_level LEVEL

This exports the states defined in the mixin to the package specified by level. The most common case for use would be in your mixin:

  sub import {
      my $class = shift;

      # Do other custom import tasks

      $class->export_poe_declarative_to_level(1);
  }

If you do not need to define a custom L</import> method, you probably should ignore this method.

=cut

sub export_poe_declarative_to_level {
    my $class   = shift;
    my $level   = shift || 1;
    my $package = caller($level);

    my $states   = POE::Declarative::_states($class);
    my $handlers = POE::Declarative::_handlers($class);

    for my $state (keys %$states) {
        for my $code (@{ $handlers->{ $state }{ $class } }) {
            POE::Declarative::_declare_method($package, $state, $code);
        }
    }
}

=head1 SEE ALSO

L<POE::Declarative>

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;