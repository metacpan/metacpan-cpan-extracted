use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard user conn schema1);

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ conn() },
                     @{ user() },
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() },
                     # rset, qfmt, expr
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     #"210 CODE_OK\r\n",
                     "220 No PRs Matched\r\n",
                     # rset, qfmt, expr
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     #"210 CODE_OK\r\n",
                     "418 Invalid query format\r\n",
                     # rset, qfmt, expr
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     #"210 CODE_OK\r\n",
                     "300 PRs follow.\r\n",
                     ">Number:         45\r\n",
                     ".\r\n",
                     # rset, qfmt, expr
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     #"210 CODE_OK\r\n",
                     "300 PRs follow.\r\n",
                     ">Number:         45\r\n",
                     ">Number:         46\r\n",
                     ".\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;
$g->login('default', 'madmin','madmin');
is_deeply $g->query, [], 'No PRs Matched';
is_deeply $g->query, [], 'Invalid query format';
is_deeply $g->query, [45], 'One PR';
is_deeply $g->query, [45,46], 'Two PRs';

my $c1 = Net::Gnats::Command->quer;
my $c2 = Net::Gnats::Command->quer(pr_numbers => [1]);
my $c3 = Net::Gnats::Command->quer(pr_numbers => [1,2]);

is $c1->as_string, 'QUER', 'QUER no arguments';
is $c2->as_string, 'QUER 1', 'QUER one argument';
is $c3->as_string, 'QUER 1 2', 'QUER two arguments';

done_testing();
