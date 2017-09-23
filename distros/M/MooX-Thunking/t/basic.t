use Test::More;

package Thunking;
use Moo;
use Test::More; BEGIN { use_ok('MooX::Thunking') }
use Types::Standard -all;
use Types::TypeTiny -all;
has children => (
  is => 'thunked',
  isa => ArrayRef[InstanceOf['Thunking']],
  required => 1,
);

package main;
my $obj;
$obj = Thunking->new(children => sub { [$obj] });
is_deeply $obj->children, [ $obj ];

$obj = Thunking->new(children => [$obj]);
is_deeply $obj->children, [ $obj ];

$obj = Thunking->new(children => sub { { key => 'delayed wrong type' } });
eval { $obj->children };
isnt $@, '', 'exception on wrong type from thunk';

eval { Thunking->new(children => { key => 'wrong type' }) };
isnt $@, '', 'exception on wrong type';

done_testing;
