#!/usr/bin/perl

use lib 't/lib';

use Test::Mite;

tests "trigger" => sub {
    mite_load <<'CODE';
package MyTest;
use Mite::Shim;
has attr =>
  is => 'rw',
  trigger => 1;
has log =>
  is => 'ro',
  default => sub { [] },
  lazy => 1;
sub _trigger_attr {
  my $self = shift;
  push @{ $self->log }, [ @_ ];
}
1;
CODE

    my $o = MyTest->new( attr => 'constructor' );
    $o->attr( 'accessor1' );
    $o->attr( 'accessor2' );

    is_deeply(
        $o->log,
        [
            [ 'constructor' ],
            [ 'accessor1', 'constructor' ],
            [ 'accessor2', 'accessor1' ],
        ],
        'expected results',
    );
};

done_testing;
