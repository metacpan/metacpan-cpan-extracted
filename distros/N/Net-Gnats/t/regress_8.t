use strict;
use warnings;
use Test::More;

# LIVE TESTS ONLY, MAINTAINER MODE ONLY
unless ( $ENV{'GNATS_MAINTAINER'} ) {
  plan skip_all => "Live tests by default are skipped, maintainer only.";
}
else {
  plan tests => 4;
}

use Net::Gnats;

my $conn1 = {
             server   => 'localhost',
             port     => '1529',
             username => '',
             password => '',
             db       => 'default'
            };

$conn1 = ovr_def($conn1);

my $g = Net::Gnats->new($conn1->{server},
                        $conn1->{port});

is($g->gnatsd_connect, 1, "Connect is OK");

$g->login($conn1->{db},
          $conn1->{username},
          $conn1->{password});

is($g->reset_server, 1, 'Reset is OK');


my $pr1 = $g->new_pr;

isa_ok($pr1, 'Net::Gnats::PR');
$pr1->setField('Submitter-Id', 'developer');
$pr1->setField('Originator', 'Unit Tester');
$pr1->setField('Description', 'A one-liner worthless description');
$pr1->setField('Synopsis', 'Regression test bug 5');
$pr1->setField('Severity', 'critical');
my $pr1_result = join "\n", @{ $g->submit_pr($pr1) };

my $pr2 = $g->get_pr_by_number($pr1_result);

ok($pr2->setField('Severity', 'serious', "not so severe\n\n\n"), 'set reason');

$g->update_pr($pr2);

done_testing();

sub ovr_def {
  my ($settings) = @_;

  return $settings if not defined $ENV{GNATSDB};

  my ($server, $port, $db, $username, $password) = split /:/, $ENV{GNATSDB};
  $settings->{server}   = length $server   ? $server   : $settings->{server};
  $settings->{port}     = length $port     ? $port     : $settings->{port};
  $settings->{db}       = length $db       ? $db       : $settings->{db};
  $settings->{username} = length $username ? $username : $settings->{username};
  $settings->{password} = length $password ? $password : $settings->{password};
  return $settings;
}
