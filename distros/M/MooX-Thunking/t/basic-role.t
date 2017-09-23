use Test::More;

BEGIN {
$INC{'ThunkingRole.pm'} = 1;
package ThunkingRole;
use Moo::Role;
use Test::More; BEGIN { use_ok('MooX::Thunking') }
use Types::Standard -all;
use Types::TypeTiny -all;
has children => (
  is => 'thunked',
  isa => ArrayRef[InstanceOf['Thunking']],
  required => 1,
);
}

package Thunking;
use Moo;
with 'ThunkingRole';

package main;
my $obj;
$obj = Thunking->new(children => sub { [$obj] });
is_deeply $obj->children, [ $obj ];

done_testing;
