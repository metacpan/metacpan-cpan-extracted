
# Test all documentation examples.

use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard schema1 conn user);

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);


my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ conn() },
                     @{ user() },
                     # get_dbnames
                     "301 List follows.\r\n",
                     "default\r\n",
                     "default2\r\n",
                     ".\r\n",
                     # login
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() },
                     # get_pr_by_number(2)
                     "210 Reset state.\r\n", # RSET
                     "210 Ok.\r\n",          # QFMT
                     "300 PRs follow.\r\n",  # QUER (1)
                     @{ pr2() },             # QUER (2)
                     # replaceField(Synopsis)
                     "212 Ok.\r\n",            # REPL (1) - no change reason
                     "210 Ok.\r\n",            # REPL (2)
                     # replaceField(Responsible)
                     "212 Ok.\r\n",            # REPL - change reason (1)
                     "213 Ok, now send the field change reason.\r\n", # REPL - change reason (2)
                     "210 Ok.\r\n",            # REPL (3)
                     # get_pr_by_number(3)
                     "210 Reset state.\r\n", # RSET
                     "210 Ok.\r\n",          # QFMT
                     "300 PRs follow.\r\n",  # QUER (1)
                     @{ pr3() },             # QUER (2)
                     # updatePR($PRthree)
                     "210 CODE_OK\r\n",      # EDITADDR
                     "300 PRs follow.\r\n",  # LOCK (1)
                     @{ pr3() },             # LOCK (2)
                     "210 CODE_OK\r\n",      # EDIT
                     "210 PR 3 unlocked.\r\n", # UNLK
                     # submit pr
                     "211 Ok.\r\n",
                     "351-The added PR number is:\r\n",
                     "350 667\r\n",
                     "201 CODE_CLOSING\r\n",
                     # new gnats object
                     @{ conn() },
                     @{ user() },

                     # view databases
                     "301 List follows.\r\n",
                     "default\r\n",
                     "default2\r\n",
                     ".\r\n",
                     # new gnats object
                     @{ conn() },
                     @{ user() },
                     #login
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() },
                     # submit pr
                     "211 Ok.\r\n",
                     "351-The added PR number is:\r\n",
                     "350 667\r\n",
#                     "201 CODE_CLOSING\r\n",
                     # query() -> uses $g
                     "210 Ok.\r\n", # rset
                     "210 Ok.\r\n", # qfmt
                     "210 Ok.\r\n", # expr
                     "300 PRs follow.\r\n",     # quer
                     ">Number:         14\r\n",
                     ">Number:         15\r\n",
                     ">Number:         16\r\n",
                     ".\r\n",
                     # get_pr_by_number(23)
                     "210 Reset state.\r\n", # RSET
                     "210 Ok.\r\n",          # QFMT
                     "300 PRs follow.\r\n",  # QUER (1)
                     @{ pr23() },             # QUER (2)
                     # get_pr_by_number(23)
                     "210 Reset state.\r\n", # RSET
                     "210 Ok.\r\n",          # QFMT
                     "300 PRs follow.\r\n",  # QUER (1)
                     @{ pr23() },             # QUER (2)
                     # replaceField(Synopsis)
                     "212 Ok.\r\n",            # REPL (1) - no change reason
                     "210 Ok.\r\n",            # REPL (2)
                     # replaceField(Responsible)
                     "212 Ok.\r\n",            # REPL - change reason (1)
                     "213 Ok, now send the field change reason.\r\n", # REPL - change reason (2)
                     "210 Ok.\r\n",            # REPL (3)
                     # get_pr_by_number(23)
                     "210 Reset state.\r\n", # RSET
                     "210 Ok.\r\n",          # QFMT
                     "300 PRs follow.\r\n",  # QUER (1)
                     @{ pr23() },             # QUER (2)
                     # updatePR($PRthree)
                     "210 PR 23 locked.\r\n",      # EDITADDR
                     "300 PRs follow.\r\n",  # LOCK (1)
                     @{ pr3() },             # LOCK (2)
                     "210 CODE_OK\r\n",      # EDIT
                     "210 PR 23 unlocked.\r\n", # UNLK
                   );

my ($g, $pr);

# Net::Gnats - Synopsis
use Net::Gnats;
use 5.10.00;
isa_ok $g = Net::Gnats->new, 'Net::Gnats';
say 'Connected.' if $g->gnatsd_connect;

is_deeply my $db_names = $g->get_dbnames, ['default','default2'], 'synopsis - get_dbnames';

is $g->login("default","somedeveloper","password"), 1, 'login ok';

isa_ok my $PRtwo = $g->get_pr_by_number(2), 'Net::Gnats::PR';

# Change the synopsis
is $PRtwo->replaceField("Synopsis","The New Synopsis String"), 1, 'synopsis - replaceField 1';

# Change the responsible, which requires a change reason.
is $PRtwo->replaceField("Responsible","joe","Because It's Joe's"), 1, 'synopsis - replaceField 2';

# Or we can change them this way.
isa_ok my $PRthree = $g->get_pr_by_number(3), 'Net::Gnats::PR';

# Change the synopsis
is $PRthree->setField("Synopsis","The New Synopsis String"), 1, 'setField Synopsis Field';

# Change the responsible, which requires a change reason.
is $PRthree->get_field('Responsible')->schema->requires_change_reason, 1, 'Responsible requires a change reason';
is $PRthree->setField("Responsible","joe","Because It's Joe's"), 1, 'setField Responsible Field';
is $PRthree->setField("Responsible", "joe"), 0, 'setField Responsible Field - fail no change reason';

# And change the PR in the database
is $g->updatePR($PRthree), 1, 'updatePR returns 1 on success';

isa_ok my $new_pr = $g->new_pr(), 'Net::Gnats::PR';
is $new_pr->setField("Submitter-Id","developer"), 1, 'setField returns 1 on success';
is $g->submitPR($new_pr), 1, 'submit_pr returns 1 on success';
is $g->disconnect(), 1, 'disconnect returns 1 on success';

# Net::Gnats - View Databases

isa_ok $g = Net::Gnats->new, 'Net::Gnats';
is $g->gnatsd_connect, 1, 'view databases - connected';
is ref (my $dbNames = $g->getDBNames), 'ARRAY', 'db list is an array reference';

# Net::Gnats - Logging in to a database

isa_ok $g = Net::Gnats->new, 'Net::Gnats';
is $g->gnatsd_connect, 1, 'logging in - connected';
is $g->login("default","riche\@cpan.org","mypassword"), 1, 'logging in - is authenticated';

# Net::Gnats - Submitting

isa_ok $pr = $g->new_pr, 'Net::Gnats::PR';
SKIP: {
  skip 'PR not initialized successfully', 13 unless defined $pr;
  is $pr->setField("Submitter-Id","developer"), 1, 'Set submitter';
  is $pr->setField("Originator","Doctor Wifflechumps"), 1, 'set Originator';
  is $pr->setField("Organization","GNU"), 1, 'set Organization';
  is $pr->setField("Synopsis","Some bug from perlgnats"), 1, 'set Synopsis';
  is $pr->setField("Confidential","no"), 1, 'set Confidential';
  is $pr->setField("Severity","serious"), 1, 'set Severity';
  is $pr->setField("Priority","low"), 1, 'set Priority';
  is $pr->setField("Category","gnatsperl"), 1, 'set Category';
  is $pr->setField("Class","sw-bug"), 1, 'set Class';
  is $pr->setField("Description","Something terrible happened"), 1, 'set Description';
  is $pr->setField("How-To-Repeat","Like this.  Like this."), 1, 'set How-To-Repeat';
  is $pr->setField("Fix","Who knows"), 1, 'set Fix';
  is $g->submit_pr($pr), 1, 'submitted pr';
}

# Net::Gnats - Querying

my $thisCat = 'Transactions';
my $prNums = $g->query('Number>"12"', "Category=\"$thisCat\"");
is_deeply $prNums, [14,15,16], 'return 3 PRs numbers 14,15,16';
#print "Found " . join(":", @$prNums ) . " matching PRs \n";

# Net::Gnats - Fetching a PR

my $prnum = 23;
isa_ok my $PR = $g->get_pr_by_number($prnum), 'Net::Gnats::PR';
SKIP: {
  skip 'PR not initialized successfully', 3 unless defined $PR;
  is $PR->getField('Synopsis'), 'A great synopsis', 'reset synopsis';
  is $PR->asString(), pr23_text(), 'compare serialization';
  isa_ok $pr->setFromString($PR->asString()), 'Net::Gnats::PR', 'got a rehydrated pr';
}

# Net::Gnats - Modifying a PR

$prnum = 23;
isa_ok $PR = $g->get_pr_by_number($prnum), 'Net::Gnats::PR';
SKIP: {
  skip 'PR not initialized successfully', 2 unless defined $PR;
  is $PR->replaceField('Synopsis','New Synopsis'),1, 'directly replace synopsis';
  is $PR->replaceField('Responsible','joe',"It's joe's problem"), 1, 'directly replace responsible';
  # if (! $PR->replaceField('Synopsis','New Synopsis')) {
  #   warn "Error replacing field (" . $g->get_error_message . ")\n";
  # }
}

$prnum = 23;
$PR = $g->get_pr_by_number($prnum);
SKIP: {
  skip 'PR not initialized successfully', 3 unless defined $PR;
  $PR->setField('Synopsis','New Synopsis'),1;
  $PR->setField('Responsible','joe',"It's joe's problem"),1;
  is  $g->updatePR($PR), 1, 'edit pr 23';
  # if (! $g->updatePR($PR) ) {
  #   warn "Error updating $prnum: " . $g->get_error_message . "\n";
  # }
}

done_testing;

sub pr2 {
  return ["To: bugs\r\n",
          "Cc: \r\n",
          "Subject: Your product sucks\r\n",
          "From: riche\@cpan.org\r\n",
          "Reply-To: riche\@cpan.org\r\n",
          "X-Send-Pr-Version: Net::Gnats-5\r\n",
          "\r\n",
          ">Number: 2\r\n",
          ">Synopsis: A great synopsis\r\n",
          ">Responsible: Ben\r\n",
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
          ">Number: 3\r\n",
          ">Synopsis: A great synopsis\r\n",
          ">Responsible: Ben\r\n",
          ">Priority: high\r\n",
          ".\r\n"];
}

sub pr23 {
  return ["From: riche\@cpan.org\r\n",
          "Reply-To: riche\@cpan.org\r\n",
          "To: bugs\r\n",
          "Cc: \r\n",
          "Subject: Your product sucks\r\n",
          "X-Send-Pr-Version: Net::Gnats " . $Net::Gnats::VERSION . "\r\n",
          "\r\n",
          ">Number:         23\r\n",
          ">Synopsis:       A great synopsis\r\n",
          ">Responsible:    Ben\r\n",
          ">Priority:       high\r\n",
          ".\r\n"];
}

sub pr23_post {
  return ["From: riche\@cpan.org\r\n",
          "Reply-To: riche\@cpan.org\r\n",
          "To: bugs\r\n",
          "Cc: \r\n",
          "Subject: A great synopsis\r\n",
          "X-Send-Pr-Version: Net::Gnats " . $Net::Gnats::VERSION . "\r\n",
          "\r\n",
          ">Number:         23\r\n",
          ">Synopsis:       A great synopsis\r\n",
          ">Responsible:    Ben\r\n",
          ">Priority:       high\r\n",
          ".\r\n"];
}

sub pr23_text {
  my @working = @{ pr23_post() };
  pop @working;
  my $result = join '', @working;
  $result =~ s/\r//g;
  return $result;
}
