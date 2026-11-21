#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin;
use Path::Tiny qw( path );
use Skilletor::Process qw( run_command );

# Skilletor::Error and every subclass under lib/Skilletor/Error/, found on disk so a new one is
# held to the same interface.
my @classes = (
  'Skilletor::Error',
  map { 'Skilletor::Error::'.( $_->basename =~ s/\.pm\z//r ) }
    sort { $a cmp $b } path( $FindBin::Bin, '..', 'lib', 'Skilletor', 'Error' )->children(qr/\.pm\z/),
);
ok( @classes > 1, 'the subclasses are found' );

sub caught {
  my ( $code ) = @_;
  local $@;
  return eval { $code->(); 1 } ? undef : $@;
}

for my $class (@classes) {
  subtest $class => sub {
    require_ok($class) or return;
    my $err = caught( sub { $class->throw('boom') } );
    isa_ok( $err, $class );
    is( $err->message, 'boom', 'message, no file and line appended' );
    is( "$err", 'boom', 'stringifies to its message' );
    is( 'x: '.$err, 'x: boom', 'concatenated' );
    ok( $err eq 'boom', 'compares as its message' );
    is( "".caught( sub { $class->throw( message => 'named' ) } ), 'named', 'throw( message => ... ) too' );
  };
}

subtest 'an error is true, whatever its message' => sub {
  # bool is its own overload: fallback would derive it from the message, and `if ($@)` would miss
  # an error whose message is '' or '0'.
  for my $message ( '', '0' ) {
    my $err = caught( sub { Skilletor::Error::Config->throw($message) } );
    ok( $err, 'message '.( length $message ? $message : 'empty' ) );
  }
};

subtest 'an error no one catches prints its message' => sub {
  # Perl prints an uncaught exception object as it stringifies: the message, nothing appended.
  my $r = run_command(
    cmd => [ $^X, ( map { "-I$_" } grep { !ref } @INC ), '-e', 'use Skilletor::Error::Config; Skilletor::Error::Config->throw("boom")' ],
  );
  is( $r->{stderr}, 'boom', 'stderr' );
  isnt( $r->{code}, 0, 'fails' );
};

done_testing;
