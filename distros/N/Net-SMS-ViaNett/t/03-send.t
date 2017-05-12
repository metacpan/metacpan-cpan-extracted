use strict;
use Net::SMS::ViaNett;
use Test::More tests => 7;
use Test::Deep;

my ( $user, $pass ) = qw/ foo foo /;
my $obj = Net::SMS::ViaNett->new( username => $user, password => $pass );

eval {
  $obj->send;
};

ok( $@, 'no-send-wo-args' );

eval {
  Net::SMS::ViaNett::send( to => 123, msg => 123 );
};

ok( $@, 'no-send-static-call' );

eval {
  $obj->send( to => 123, from => 234 );
};
ok( $@, 'no-send-wo-msg');


my $num = re('^[0-9]+$');
my $msg = re('.*');

cmp_deeply( $obj->_validate( {
  to   => 123,
  from => 123,
  msg  => 'some message'
} ),
{
  destinationaddr => 123,
  sourceaddr      => 123,
  message         => $msg,
  refno           => $num
}, 'validation check 1' );



cmp_deeply( $obj->_validate( {
  to   => 123,
  msg  => 'some message'
} ),
{
  destinationaddr => 123,
  sourceaddr      => $num,
  message         => $msg,
  refno           => $num
}, 'validation check 2' );


cmp_deeply( $obj->_validate( {
  to    => 123,
  msg   => 'some message',
  refno => 321
} ),
{
  destinationaddr => 123,
  sourceaddr      => $num,
  message         => $msg,
  refno           => 321
}, 'validation check 3' );


cmp_deeply( $obj->_validate( {
  to     => 123,
  from   => 123,
  origin => 'AB123',
  msg   => 'some message',
  refno => 321,
  pricegroup => 10,
  operator  => 21,

} ),
{
  destinationaddr => 123,
  sourceaddr      => 123,
  message         => $msg,
  refno           => 321,
  pricegroup      => 10,
  operator        => 21,
  fromalpha       => 'AB123'
}, 'validation check 4' );
























