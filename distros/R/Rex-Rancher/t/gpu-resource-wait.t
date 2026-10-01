use strict;
use warnings;
use Test::More;

# k61: _wait_for_gpu_resource swallowed every API error for two minutes and
# then only warned "check device plugin": a 403 or a dead API read the same
# as a plugin that had not reported yet. The warning now names the last
# attempt's error; nothing else changes (no die, same 24 polls). The API and
# sleep are faked: that a real 403 reads like this is only shown live.

my $slept = 0;
BEGIN { *CORE::GLOBAL::sleep = sub { $slept++ } }

use IO::K8s;
use Rex::Rancher::K8s;

my ( @info, @warn );
{
  no warnings 'redefine';
  *Rex::Logger::info = sub { push @{ ( $_[1] // '' ) eq 'warn' ? \@warn : \@info }, $_[0] };
}

# @answers: one per list call; a string dies with it, a number is the GPU
# capacity of the one node (0: none yet). The last answer repeats.
our @answers;
{
  package FakeAPI;
  sub new  { bless {}, shift }
  sub list {
    my $a = @main::answers > 1 ? shift @main::answers : $main::answers[0];
    die $a if $a =~ /\D/;
    my %status = ( status => { capacity => $a ? { 'nvidia.com/gpu' => $a } : {} } );
    return FakeList->new( IO::K8s->new->new_object( 'Node', metadata => { name => 'gpu1' }, %status ) );
  }
  package FakeList;
  sub new   { my ( $c, @i ) = @_; bless { items => \@i }, $c }
  sub items { $_[0]{items} }
}

sub wait_with {
  local @answers = @_;
  ( @info, @warn ) = ();
  $slept = 0;
  return Rex::Rancher::K8s::_wait_for_gpu_resource( FakeAPI->new );
}

is( wait_with( "403 Forbidden: nodes is forbidden\n" ), 0, 'API error throughout: 0, no die' );
is( $slept, 24, 'still 24 polls' );
is_deeply( \@warn,
  [ "  nvidia.com/gpu resource did not appear \x{e2}\x{80}\x{94} check device plugin "
    . "(last API error: 403 Forbidden: nodes is forbidden)" ],
  'the warning names the last error' );

is( wait_with( 0 ), 0, 'API answers, no GPU: 0' );
is_deeply( \@warn,
  [ "  nvidia.com/gpu resource did not appear \x{e2}\x{80}\x{94} check device plugin" ],
  'no error: the warning as before' );

is( wait_with( ( "500 boom\n" ) x 3, 0 ), 0, 'errors, then answers without GPU' );
unlike( $warn[0], qr/last API error/, 'an error of an earlier attempt is not named' );

is( wait_with( "503 unavailable\n", 2 ), 1, 'error, then GPU capacity: 1' );
is_deeply( \@warn, [], 'no warning' );
like( $info[-1], qr/\[ok\] nvidia\.com\/gpu: 2 on gpu1/, 'reports the node' );

done_testing;
