use MySQL::Admin::Actions;
use strict;
use vars qw($m_hrActions);
*m_hrActions = \$MySQL::Admin::Actions::m_hrActions;
$m_hrActions = {
                actions => "???actions.pl",
                Actions => "./actions.pl"
               };
saveActions("./actions.pl");
loadActions("./actions.pl");
my $t1 = $m_hrActions->{actions};
my $t2 = $m_hrActions->{Actions};
use Test::More tests => 2;
ok($t1 eq "???actions.pl");
ok($t2 eq "./actions.pl");
unlink 'actions.pl' or warn "Could not unlink actions.pl $!";

