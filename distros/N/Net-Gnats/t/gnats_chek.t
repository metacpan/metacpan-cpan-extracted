use strict;
use warnings;
use File::Basename;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;
use Net::Gnats::Session;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth);

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard_wauth() },
                     "211 CODE_SEND_PR\r\n",
                     "210 CODE_OK\r\n",
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

# hydrate test prs
print "Deserializing PR1\n";
my $pr1 = Net::Gnats::PR->deserialize(data => pr1(), schema => $g->schema);

isa_ok my $a = Net::Gnats::Command::CHEK->new, 'Net::Gnats::Command::CHEK';
isa_ok my $b = Net::Gnats::Command::CHEK->new( type => 'initial', pr => $pr1 ), 'Net::Gnats::Command::CHEK';
isa_ok my $c = Net::Gnats::Command->chek( type => 'initial', pr => $pr1 ), 'Net::Gnats::Command::CHEK';

is $a->as_string, 'CHEK', 'CHEK with no type';
is $b->as_string, 'CHEK initial', 'CHEK with type';

$g->issue($b);

#is $g->check_pr(pr1(), 'initial'), 1,     'initial PR checks';

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

# CHEK fails because state enum value is unknown
# CODE_INVALID_ENUM
sub pr2 {
return ["To: bugs\r\n",
        "Cc:\r\n",
        "Subject: Your product sucks\r\n",
        "From: riche\@cpan.org\r\n",
        "Reply-To: riche\@cpan.org\r\n",
        "X-Send-Pr-Version: Net::Gnats-5\r\n",
        "\r\n",
        ">State: unknown\r\n",
        "."];
}

# This PR, we should get two errors back -
# one for State
# one for Priority
# Result:
# 411-There is a bad value `unknown' for the field `State'.
# 411 There is a bad value `unknown' for the field `Priority'.
# 403 Errors found checking PR text.

sub pr3 {
  return ["To: bugs\r\n",
          "Cc:\r\n",
          "Subject: Your product sucks\r\n",
          "From: rich\@richelberger.com\r\n",
          "Reply-To: rich\@richelberger.com\r\n",
          "X-Send-Pr-Version: Net::Gnats-5\r\n",
          "\r\n",
          ">Number: 1\r\n",
          ">State: unknown\r\n",
          ">Priority: unknown\r\n",
          "."]

}
