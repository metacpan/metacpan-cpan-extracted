use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;
use Net::Gnats::PR qw(deserialize parse_line);

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth conn user schema1);
my $p = Net::Gnats::PR->new;

isa_ok($p, 'Net::Gnats::PR');

my @known = qw(Field Severity);

# header types
is_deeply parse_line('From: Doctor Wifflechumps', \@known), ['From','Doctor Wifflechumps'];
is_deeply parse_line('Reply-To: Doctor Wifflechumps', \@known), ['Reply-To','Doctor Wifflechumps'];
is_deeply parse_line('To: bugs', \@known), ['To', 'bugs'];
is_deeply parse_line('Cc:', \@known), ['Cc',''];
is_deeply parse_line('Subject: Some bug from perlgnats', \@known), ['Subject','Some bug from perlgnats'];
is_deeply parse_line('X-Send-Pr-Version: Net::Gnats-0.07 ($Id: PR.pm,v 1.3 2014/08/14 13:32:27 thacker Exp $)', \@known),
  ['X-Send-Pr-Version', 'Net::Gnats-0.07 ($Id: PR.pm,v 1.3 2014/08/14 13:32:27 thacker Exp $)'];

# main pr types
is_deeply parse_line('>Field: value', \@known), ['Field','value'];
is_deeply parse_line('>Field:    value', \@known), ['Field', 'value'];
is_deeply parse_line(">Field: 123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!" , \@known), ['Field', "123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!"];

is_deeply parse_line('>Field:    value        ', \@known), ['Field',  'value'];
is_deeply parse_line('a multiline line', \@known), [ undef, 'a multiline line' ];
is_deeply parse_line('', \@known), [ undef, ''];
is_deeply parse_line('>Unknown: value'      , \@known), [undef, '>Unknown: value'];
is_deeply parse_line('     multiline with initial spaces', \@known), [undef, '     multiline with initial spaces'];


my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ conn() },
                     @{ user() },
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() },
                     @{ querprep() },
                     @{ pr1() },
                     @{ querprep() },
                     @{ pr2() },
                     "212 Ok.",  # send text
                     "213 Ok.",  # send change reason                     
                     "210 Ok.",  # accept text
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;
$g->login('default', 'madmin', 'madmin');
isa_ok my $pr = $g->get_pr_by_number('45'), 'Net::Gnats::PR';
is $pr->getNumber, '45';
is $pr->getField('Confidential'), 'yes';

isa_ok my $pr2 = $g->get_pr_by_number('46'), 'Net::Gnats::PR';
is $pr2->get_field('Responsible{1}')->value, '';
is $pr2->replaceField('Responsible{1}', 'someone', 'reqchange'), 1;

done_testing;

# quer runs rset, qfmt, expr
# assume expr not set here.
sub querprep {
  return ["210 CODE_OK\r\n",
          "210 CODE_OK\r\n",];
}

sub pr1 {
  return ["300 PRs follow.\r\n",
          "From: Doctor Wifflechumps\r\n",
          "Reply-To: Doctor Wifflechumps\r\n",
          "To: bugs\r\n",
          "Cc:\r\n",
          "Subject: Some bug from perlgnats\r\n",
          "X-Send-Pr-Version: Net::Gnats-0.07 (\$Id: PR.pm,v 1.3 2014/08/14 13:32:27 thacker Exp \$)\r\n",
          "\r\n",
          ">Number:         45\r\n",
          ">Category:       pending\r\n",
          ">Synopsis:       changing you\r\n",
          ">Confidential:   yes\r\n",
          ">Severity:       serious\r\n",
          ">Priority:       medium\r\n",
          ">Responsible:    gnats-admin\r\n",
          ">State:          open\r\n",
          ">Class:          sw-bug\r\n",
          ">Submitter-Id:   unknown\r\n",
          ">Arrival-Date:   Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Last-Modified:  Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Originator:     Doctor Wifflechumps\r\n",
          ">Release:        \r\n",
          ">Fix:\r\n",
          ">Unformatted:\r\n",
          "\r\n",
          ".\r\n",];
}


sub pr2 {
  return ["300 PRs follow.\r\n",
          "From: Doctor Wifflechumps\r\n",
          "Reply-To: Doctor Wifflechumps\r\n",
          "To: bugs\r\n",
          "Cc:\r\n",
          "Subject: Some bug from perlgnats\r\n",
          "X-Send-Pr-Version: Net::Gnats-0.07 (\$Id: PR.pm,v 1.3 2014/08/14 13:32:27 thacker Exp \$)\r\n",
          "\r\n",
          ">Number:         46\r\n",
          ">Category:       pending\r\n",
          ">Synopsis:       changing you\r\n",
          ">Confidential:   yes\r\n",
          ">Severity:       serious\r\n",
          ">Priority:       medium\r\n",
          ">Responsible{0}: gnats-admin\r\n",
          ">Responsible{1}: \r\n",
          ">State:          open\r\n",
          ">Class:          sw-bug\r\n",
          ">Submitter-Id:   unknown\r\n",
          ">Arrival-Date:   Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Last-Modified:  Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Originator:     Doctor Wifflechumps\r\n",
          ">Release:        \r\n",
          ">Fix:\r\n",
          ">Unformatted:\r\n",
          "\r\n",
          ".\r\n",];
}



#Number Notify-List Category Synopsis Confidential Severity Priority Responsible State Class Submitter-Id Arrival-Date Closed-Date Last-Modified Originator Release Organization Environment Description How-To-Repeat Fix Release-Note Audit-Trail Unformatted
