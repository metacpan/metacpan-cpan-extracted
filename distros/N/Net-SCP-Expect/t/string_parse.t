use strict;
use Test::More qw(no_plan);

BEGIN{ use_ok('Net::SCP::Expect') }

# expected results;
my $xhost1 = "some.host.net";
my $xhost2 = "111.222.333.444";
my $xuser = "some-user";
my $xfile = "~/some_dir/some-file.txt";

my @x1 = ("some-user", "some.host.net", "~/some_dir/some-file.txt");
my @x2 = ("some-user", "some.host.net", "~/some_dir/some-file.txt");

# Everything included
my $scp = Net::SCP::Expect->new(
   host     => $xhost1,
   user     => $xuser,
   password => "bogus",
);

# No host
my $scp2 = Net::SCP::Expect->new(
   user     => $xuser,
   password => "bogus",
);

# No user
my $scp3 = Net::SCP::Expect->new(
   host     => $xhost1,
   password => "bogus",
);

# No host or user
my $scp4 = Net::SCP::Expect->new(
   password => "bogus",
);

my $string1 = '';
my $string2 = ':';
my $string3 = 'some-user@some.host.net:~/some_dir/some-file.txt';
my $string4 = 'some.host.net:~/some_dir/some-file.txt';
my $string5 = ':~/some_dir/some-file.txt';
my $string6 = 'some-user@some.host.net:';
my $string7 = 'some.host.net:';
my $string8 = 'some-user@111.222.333.444:~/some_dir/some-file.txt';
my $string9 = 'some-user@111.222.333.444:';
my $string10 = '111.222.333.444:';
my $string11 = '111.222.333.444:~/some_dir/some-file.txt';

my(@a1,@a2,@a3,@a4,@a5,@a6,@a7,@a8,@a9,@a10,@a11);

# When everything is provided in the constructor
@a1 = $scp->_parse_scp_string($string1);
@a2 = $scp->_parse_scp_string($string2);
@a3 = $scp->_parse_scp_string($string3);
@a4 = $scp->_parse_scp_string($string4);
@a5 = $scp->_parse_scp_string($string5);
@a6 = $scp->_parse_scp_string($string6);
@a7 = $scp->_parse_scp_string($string7);
@a8 = $scp->_parse_scp_string($string8);
@a9 = $scp->_parse_scp_string($string9);
@a10 = $scp->_parse_scp_string($string10);
@a11 = $scp->_parse_scp_string($string11);

is(@a1,@x1);
is(@a2,@x1);
is(@a3,@x1);
is(@a4,@x1);
is(@a5,@x1);
is(@a6,@x1);
is(@a7,@x1);
is(@a8,@x2);
is(@a9,@x2);
is(@a10,@x2);
is(@a11,@x2);

# No host in constructor
@a1 = $scp2->_parse_scp_string($string3);
@a2 = $scp2->_parse_scp_string($string4);
@a3 = $scp2->_parse_scp_string($string6);
@a4 = $scp2->_parse_scp_string($string7);
@a5 = $scp2->_parse_scp_string($string8);
@a6 = $scp2->_parse_scp_string($string9);
@a7 = $scp2->_parse_scp_string($string10);
@a8 = $scp2->_parse_scp_string($string11);

is(@a1,@x1);
is(@a2,@x1);
is(@a3,@x1);
is(@a4,@x1);
is(@a5,@x1);
is(@a6,@x1);
is(@a7,@x1);
is(@a8,@x2);

# No user in constructor
@a1 = $scp3->_parse_scp_string($string1);
@a2 = $scp3->_parse_scp_string($string2);
@a3 = $scp3->_parse_scp_string($string4);
@a4 = $scp3->_parse_scp_string($string5);
@a5 = $scp3->_parse_scp_string($string7);
@a6 = $scp3->_parse_scp_string($string10);
@a7 = $scp3->_parse_scp_string($string11);

is(@a1,@x1);
is(@a1,@x1);
is(@a1,@x1);
is(@a1,@x1);
is(@a1,@x1);
is(@a1,@x1);
is(@a1,@x2);
is(@a1,@x2);

# Neither host nor user in constructor
@a1 = $scp4->_parse_scp_string($string1);
@a2 = $scp4->_parse_scp_string($string2);
@a3 = $scp4->_parse_scp_string($string5);

is(@a1,@x1);
is(@a2,@x1);
is(@a3,@x1);
