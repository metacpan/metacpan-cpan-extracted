use strict;
use warnings;
use Test::More;

# LIVE TESTS ONLY, MAINTAINER MODE ONLY
unless ( $ENV{'GNATS_MAINTAINER'} ) {
  plan skip_all => "Live tests by default are skipped, maintainer only.";
}
else {
  plan tests => 5;
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

print "new server\n";
my $g = Net::Gnats->new($conn1->{server},
                        $conn1->{port});

is($g->gnatsd_connect, 1, "Connect is OK");

print "logging in\n";
$g->login($conn1->{db},
          $conn1->{username},
          $conn1->{password});

print "resetting server\n";
is($g->reset_server, 1, 'Reset is OK');

# check if we can create a PR with this
my $desc = "This is a multiline\nthat later\n> has an identifier";
my $pr1 = $g->new_pr;

isa_ok($pr1, 'Net::Gnats::PR');
$pr1->setField('Submitter-Id', 'developer');
$pr1->setField('Originator', 'Doctor Wifflechumps');
$pr1->setField('Description', $desc);
$pr1->setField('Synopsis', 'Some bug from perlgnats');

my $pr1_result = join "\n", @{ $g->submit_pr($pr1) };

my $pr2 = $g->get_pr_by_number($pr1_result);

is($pr2->getField('Description'), $desc, 'multi works ok');

ok($g->disconnect, 'Logout of gnats');

# then verify that we can consume gnatsd with it

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

