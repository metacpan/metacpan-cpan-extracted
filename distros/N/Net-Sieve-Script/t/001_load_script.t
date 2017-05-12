# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 14;
use strict;

use lib qw(lib);

BEGIN { use_ok( 'Net::Sieve::Script' ); }

my $test_script='require "fileinto";
# Place all these in the "Test" folder
if header :contains "Subject" "[Test] test" {
       fileinto "Test";
}';

my $object = Net::Sieve::Script->new ();
isa_ok ($object, 'Net::Sieve::Script');

use_ok( 'Net::Sieve::Script::Rule' );
use_ok( 'Net::Sieve::Script::Condition' );
use_ok( 'Net::Sieve::Script::Action' );

$object = Net::Sieve::Script->new ($test_script);
isa_ok ($object, 'Net::Sieve::Script');

is ($object->raw, $test_script, "set in raw for simple script");
#print length($object->raw);

is( $object->require,'"fileinto"',"match require in simple script");
my $test_script2='#require ["fileinto","reject","vacation","imapflags","relational","comparator-i;ascii-numeric","regex","notify"];
require ["fileinto","regex"];
if header :contains "Received" "compilerlist@example.com"
{
  fileinto "mlists.compiler";
#  stop;
}
if header :regex :comparator "i;ascii-casemap" "Subject" "^Release notice:"
{
  fileinto "releases";
  stop;
}
if allof (header :regex :comparator "i;ascii-casemap" "Subject" "^Output file listing from [a-z]*backup$",
          header :regex :comparator "i;ascii-casemap" "From" "^BackupUser")
{
  fileinto "Backup listings";
  stop;
}
if Header :is "Subject" "Daily virus scan reminder"
{
  discard;
  stop;
}
if not exists ["From","Date"] {
  discard;
}';

my $test_script3 = '
    # Example Sieve Filter
    require ["fileinto", "reject"];

    #
    if size :over 1M
            {
            reject text:
    Please do not send me large attachments.
    Put your file on a server and send me the URL.
    Thank you.
    .... Fred
    .
    ;
            stop;
            }
    #

    # Handle messages from known mailing lists
    # Move messages from IETF filter discussion list to filter folder
    #
    if header :is "Sender" "owner-ietf-mta-filters@imc.org"
            {
            fileinto "filter";  # move to "filter" folder
            }
    #
    # Keep all messages to or from people in my company
    #
    elsif address :domain :is ["From", "To"] "example.com"
            {
            keep;               # keep in "In" folder
            }

    #
    # Try and catch unsolicited email.  If a message is not to me,
    # or it contains a subject known to be spam, file it away.
    #
    elsif anyof (not address :all :contains
                   ["To", "Cc", "Bcc"] "me@example.com",
                 header :matches "subject"
                   ["*make*money*fast*", "*university*dipl*mas*"])
            {
            # If message header does not contain my address,
            # it s from a list.
            fileinto "spam";   # move to "spam" folder
            }
    else
            {
            # Move all other (non-company) mail to "personal"
            # folder.
            fileinto "personal";
            }
';


$object->raw($test_script3);
is ($object->raw, $test_script3, "set raw script3");

#read rules from raw
$object->read_rules();
is( $object->require,'["fileinto", "reject"]',"match require in script3");
is ($object->_strip,$object->_strip($object->write_script), "parse raw script3");

#set new rules without raw
$object->read_rules($test_script2);

is( $object->require,'["fileinto","reject","vacation","imapflags","relational","comparator-i;ascii-numeric","regex","notify"]',"match original require for script2");

my $res_script = $object->write_script;
is ( $object->require, '["fileinto", "regex"]', "new require for script2");
is (lc($object->_strip($test_script2)),lc($object->_strip($res_script)), "parse script2 ( no raw, test case in keywords )");

#open F, "t/loud.txt";
#my @test_loud = <F>;
#close F;

#print @test_loud;

#$object->raw(join "\n",@test_loud);
#$object->read_rules();
#print $object->write_script;
#is ($object->_strip,$object->_strip($object->write_script), "parse raw script3");

#print $object->write_script;

#TODO test $object->swap_rules(1,5);
#TODO test $object->remove_rule(3);
#TODO test $object->del_rule(3);
