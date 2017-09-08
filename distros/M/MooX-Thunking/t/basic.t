use Test::More;

package Thunking;
use Moo;
use Test::More; BEGIN { use_ok('MooX::Thunking') }
use Types::Standard -all;
use Types::TypeTiny -all;
has children => (
  is => 'thunked',
  isa => CodeLike | ArrayRef[InstanceOf['Thunking']],
  required => 1,
);

package main;
my $obj;
$obj = Thunking->new(children => sub { [$obj] });
is_deeply $obj->children, [ $obj ];

done_testing;
