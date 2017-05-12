use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard_wauth() },
                     "210 CODE_OK\r\n",
                     # No response, should not be sent
                     # No response, should not be sent
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

# EDIT requires a PR, so hydrate.
my $pr1 = Net::Gnats::PR->deserialize(data => pr1(), schema => $g->schema);

my $c1 = Net::Gnats::Command->edit(pr_number => 50, pr => $pr1); # ok
my $c2 = Net::Gnats::Command->edit(pr_number => 50);             # not ok
my $c3 = Net::Gnats::Command->edit();                            # not ok

is $g->issue($c1)->is_ok, 1, 'c1 is OK';
is $g->issue($c2)->is_ok, 0, 'c2 is NOT OK';
is $g->issue($c3)->is_ok, 0, 'c3 is NOT OK';


done_testing();

sub pr1 {
  return ["To: bugs\r\n",
          "Cc: \r\n",
          "Subject: Your product sucks\r\n",
          "From: riche\@cpan.org\r\n",
          "Reply-To: riche\@cpan.org\r\n",
          "X-Send-Pr-Version: Net::Gnats-5\r\n",
          "\r\n",
          ">Number: 50\r\n",
          ">Synopsis: A great synopsis\r\n",
          ">Priority: high\r\n",
          ".\r\n"];
}
