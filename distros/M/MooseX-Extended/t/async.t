#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests
  name     => 'async',
  version  => '5.26.0',
  requires => { 'Future::AsyncAwait' => '0.56', 'IO::Async::Loop' => 0 };

package My::Thing {
    use MooseX::Extended
      types    => 'Str',
      includes => 'async';
    use IO::Async::Loop;

    field output => ( is => 'rw', isa => Str );

    async sub doit ( $self, @list ) {
        my $loop = IO::Async::Loop->new;
        $self->output('> ');
        foreach my $item (@list) {
            await $loop->delay_future( after => 0.01 );
            $self->output( $self->output . "$item " );
        }
    }
}

package My::Async::Role {
    use MooseX::Extended::Role
      types    => 'Str',
      includes => 'async';
    use IO::Async::Loop;

    field output => ( is => 'rw', isa => Str );

    async sub doit ( $self, @list ) {
        my $loop = IO::Async::Loop->new;
        $self->output('> ');
        foreach my $item (@list) {
            await $loop->delay_future( after => 0.01 );
            $self->output( $self->output . "$item " );
        }
    }
}

package My::Class::Consuming::The::Role {
    use MooseX::Extended;
    with 'My::Async::Role';
}

my %cases = (
    classes => 'My::Thing',
    roles   => 'My::Class::Consuming::The::Role',
);

while ( my ( $name, $class ) = each %cases ) {
    subtest "async in $name" => sub {
        ok my $async = $class->new, "We should be allowed to load $name with ascync";
        ok !defined $async->output, 'Our output should start empty';

        my $future1 = $async->doit(qw/one two three four/);
        is $async->output, '> ', 'Before we get compute our async result, the initial output should be set';

        $future1->get;
        is $async->output, '> one two three four ', 'After we get compute our async result, the output should be correct';
    };
}

done_testing;
