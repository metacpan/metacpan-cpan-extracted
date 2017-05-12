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
                     "300 PRs follow.\r\n",
                     @{ get_pr() },
                     "300 PRs follow.\r\n",
                     @{ get_pr() },
                     "440 CODE_CMD_ERROR\r\n",
                     "400 CODE_NONEXISTENT_PR\r\n",
                     "430 CODE_LOCKED_PR\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

my $c1 = Net::Gnats::Command->lock_pr;
my $c2 = Net::Gnats::Command->lock_pr( pr_number => '5' );
my $c3 = Net::Gnats::Command->lock_pr( pr_number => '5', user => 'rich' );
my $c4 = Net::Gnats::Command->lock_pr( pr_number => '5', user => 'rich', pid => '555' );
my $c5 = Net::Gnats::Command->lock_pr( user => 'rich' );
my $c6 = Net::Gnats::Command->lock_pr( user => 'rich', pid => '555' );
my $c7 = Net::Gnats::Command->lock_pr( pid => '555' );

is $g->issue($c1)->is_ok, 0, 'c1 NOT OK';
is $g->issue($c2)->is_ok, 0, 'c2 NOT OK';
is $g->issue($c3)->is_ok, 1, 'c3 IS OK';
is $g->issue($c4)->is_ok, 1, 'c4 IS OK';
is $g->issue($c5)->is_ok, 0, 'c5 NOT OK';
is $g->issue($c6)->is_ok, 0, 'c6 NOT OK';
is $g->issue($c7)->is_ok, 0, 'c7 NOT OK';

# is $g->lock_pr         , 0, 'need two args, got zero';
# is $g->lock_pr(1)      , 0, 'need two args, got one';
# is $g->lock_pr(1, 'me'), 0, '440 CODE_CMD_ERROR';
# is $g->lock_pr(1, 'me'), 0, '400 CODE_NONEXISTENT_PR';
# is $g->lock_pr(1, 'me'), 0, '430 CODE_LOCKED_PR (someone else got it first)';
# is $g->lock_pr(1, 'me'), 0, '666 THE_EVIL_CODE';
# is $g->lock_pr(1, 'me'), 1, '300 PRs follow.';

done_testing();

sub get_pr {
  return ["To: bugs\r\n",
          "Cc: \r\n",
          "Subject: Your product sucks\r\n",
          "From: riche\@cpan.org\r\n",
          "Reply-To: riche\@cpan.org\r\n",
          "X-Send-Pr-Version: Net::Gnats-5\r\n",
          "\r\n",
          ">Number: 5\r\n",
          ">Synopsis: A great synopsis\r\n",
          ">Priority: high\r\n",
          ".\r\n"];
}

sub get_list {
  return <<END;
foo
bar
baz
END
}
