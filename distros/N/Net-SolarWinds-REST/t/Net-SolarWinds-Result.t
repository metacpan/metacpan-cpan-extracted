use strict;
use warnings;

use Test::More;

use_ok('Net::SolarWinds::Result');



isa_ok(new Net::SolarWinds::Result,'Net::SolarWinds::Result');


{
  my $res=new_false Net::SolarWinds::Result('some error','extra data');
  isa_ok($res,'Net::SolarWinds::Result');
  ok(!$res->is_ok,'is_ok check');
  ok(!$res,'is_ok check');

  cmp_ok($res->get_msg,'eq','some error');
  cmp_ok($res->get_extra,'eq','extra data');
  $res->set_true('some data','more extra');
  ok($res);
  cmp_ok($res->get_data,'eq','some data');
  cmp_ok($res->get_extra,'eq','more extra');

}

{
  my $res=new_true Net::SolarWinds::Result('some data','extra data');
  isa_ok($res,'Net::SolarWinds::Result');
  ok($res->is_ok,'is_ok check');
  ok($res,'is_ok check');
  cmp_ok($res->get_data,'eq','some data');
  cmp_ok($res->get_extra,'eq','extra data');
  $res->set_false('some error','more extra');
  ok(!$res);
  cmp_ok($res->get_msg,'eq','some error');
  cmp_ok($res->get_extra,'eq','more extra');

}







###############
#
# End of the script
done_testing;
