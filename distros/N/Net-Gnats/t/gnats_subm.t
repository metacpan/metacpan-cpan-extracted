use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth);

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard_wauth() },
                     "211 Ok.\r\n",
                     "351-The added PR number is:\r\n",
                     "350 666\r\n",
                     "211 Ok.\r\n",
                     "351-The added PR number is:\r\n",
                     "350 667\r\n",
                     "351-The added PR number is:\r\n",
                     "350 1000\r\n",
                     "351-The added PR number is:\r\n",
                     "350 1001\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $pr1 = Net::Gnats::PR->deserialize(schema => $g->schema, data => pr1());
my $pr2 = Net::Gnats::PR->deserialize(schema => $g->schema, data => pr2());

my $c1 = Net::Gnats::Command->subm;
my $c2 = Net::Gnats::Command->subm(pr => $pr1);
my $c3 = Net::Gnats::Command->subm(pr => $pr2);

is $g->issue($c1)->is_ok, 0, 'c1 not ok';
is $g->issue($c2)->is_ok, 1, 'c2 OK';
is $g->issue($c3)->is_ok, 1, 'c3 OK - has number field but will be thrown out';

# Submit from PR object - existing - no force does not re-submit

is $pr2->submit->get_field('Number')->value, '50', 'pr still has same Number';

# Submit from PR object - existing

is $pr2->submit(1)->get_field('Number')->value, '1000', 'pr has new number';

# Submit from PR object - new
my $pr3 = Net::Gnats::PR->deserialize(schema => $g->schema, data => pr3());
is $pr3->submit->get_field('Number')->value, '1001', 'new pr has a number';

done_testing();

sub pr1 {
  return ["To: bugs\r\n",
          "Cc: \r\n",
          "Subject: Your product sucks\r\n",
          "From: riche\@cpan.org\r\n",
          "Reply-To: riche\@cpan.org\r\n",
          "X-Send-Pr-Version: Net::Gnats-5\r\n",
          "\r\n",
          ">Synopsis: A great synopsis\r\n",
          ">Priority: high\r\n",
          ".\r\n"];
}

sub pr2 {
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

sub pr3 {
  return ["To: bugs\r\n",
          "Cc: \r\n",
          "Subject: Your product sucks\r\n",
          "From: riche\@cpan.org\r\n",
          "Reply-To: riche\@cpan.org\r\n",
          "X-Send-Pr-Version: Net::Gnats-5\r\n",
          "\r\n",
          ">Synopsis: A great synopsis\r\n",
          ">Priority: high\r\n",
          ".\r\n"];
}
