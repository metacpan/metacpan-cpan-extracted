use Test::More tests => 21;
use Data::Dumper;

# Does the module even load?
BEGIN {use_ok('Net::Lyskom')}

# Can we connect to Lysator's server?
$kom = Net::Lyskom->new;
ok($kom, 'connected to server');
isa_ok($kom,"Net::Lyskom");

# Can we do some basic calls to the server and get sensible replies?
$time = $kom->get_time;
isa_ok($time,"Net::Lyskom::Time");

cmp_ok(abs(time()-$time->time_t)%3600,'<',10, "server's current time seems reasonable");

# MiscInfo
$mi = Net::Lyskom::MiscInfo->new(type => "recpt", data => 6);
isa_ok($mi,"Net::Lyskom::MiscInfo");
is($mi->type,"recpt", "correct MiscInfo type in object");
is($mi->data,6, "correct MiscInfo data in object");

# Log in
ok($kom->login(pers_no => 12156, password => "password", invisible => 1),"logged in");
is($kom->get_conf_stat(6)->name,"Inlägg }t mig","get_conf_stat works");

# Text-mapping
is($kom->local_to_global(conf => 6,first => 2017, number => 1)->global(2017),4711,"local_to_global works");

# Name lookup
is(($kom->lookup_z_name(name => "i } m", want_pers => 1, want_conf => 1))[0]->name,"Inlägg }t mig", "lookup_z_name works");

# person_stat
is($kom->get_person_stat(437)->no_of_confs,2,"get_person_stat works");

# CC
isa_ok($kom->change_conference(6),"Net::Lyskom",
       "return value from change_conference");
isa_ok($kom->change_what_i_am_doing("Testing"),"Net::Lyskom",
       "return value from change_what_i_am_doing");

# Who is on?
our @session = $kom->who_is_on_dynamic(want_visible => 1, want_invisible => 1, active_last => 0);
cmp_ok(scalar @session,'>', 5,
       "there seems to be a reasonable number of sessions");

# Textstat
our $stat = $kom->get_text_stat(4711);
isa_ok($stat, "Net::Lyskom::TextStat", "return from get_text_stat");
is($stat->creation_time->as_string,
   "Time => { Mon Nov 19 20:41:52 1990 }",
   "text's creation time looks ok");
is($stat->subject, "Stort jubileum!", "correct text subject");

# Who am I?
cmp_ok($kom->who_am_i,'>',1, "our session number is higher than 1");

# Logout
isa_ok($kom->logout,"Net::Lyskom","return value from logout");

#print $kom->get_person_stat(437)->no_of_confs;


