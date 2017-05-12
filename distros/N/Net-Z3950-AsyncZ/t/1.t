# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'


#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 27;

BEGIN {
use_ok('Net::Z3950::AsyncZ', qw(:header :errors :record asyncZOptions)); 
use_ok("Net::Z3950::AsyncZ::Errors", qw(suppressErrors));
use_ok('Net::Z3950::AsyncZ::Report');
use_ok('Net::Z3950::AsyncZ::ZSend');
use_ok('Net::Z3950::AsyncZ::ZLoop');
}


$options = asyncZOptions();
isa_ok(suppressErrors(),'Net::Z3950::AsyncZ::SuppressErr');
isa_ok($options,'Net::Z3950::AsyncZ::Options::_params');

$options->set_raw_on();
is($options->get_raw(), 1);
$options->set_raw_off();
is($options->get_raw(), 0);


is($options->get_marc_fields(), $Net::Z3950::AsyncZ::Report::std, "MARC Fields: std -- default");
$options->set_marc_xtra();
is($options->get_marc_fields(), $Net::Z3950::AsyncZ::Report::xtra, "MARC Fields: xtra");
$options->set_marc_all();
is($options->get_marc_fields(), $Net::Z3950::AsyncZ::Report::all, "MARC Fields: all");
$options->set_marc_std();
is($options->get_marc_fields(), $Net::Z3950::AsyncZ::Report::std, "MARC Fields: std");

is($options->get_HTML(), 0, "plaintext on--default");
$options->set_HTML();
is($options->get_HTML(), 1, "HTML on");
$options->set_plaintext();
is($options->get_HTML(),,0, "HTML off/plaintext on");

is($options->get_querytype(), undef);
$options->set_ccl();
is($options->get_querytype(), 'ccl', "ccl on");
$options->set_prefix();
is($options->get_querytype(), 'prefix', "prefix on");

is($options->get_preferredRecordSyntax(), Net::Z3950::RecordSyntax::USMARC, "MARC -default");
$options->set_GRS1();
is($options->get_preferredRecordSyntax(), Net::Z3950::RecordSyntax::GRS1, "GRS-1 on");
$options->set_USMARC();
is($options->get_preferredRecordSyntax(), Net::Z3950::RecordSyntax::USMARC, "MARC on");

$options->set_HTML(0);
is($options->get_HTML(), 1, "set_HTML(0)");

is($options->get_render(), 1);
$options->set_render(0);
is($options->get_render(), 0, "ccl on");

$options->set_Z3950_options({elementSetName =>'f'});
$z3950 = $options->get_Z3950_options({elementSetName =>'f'});
is($z3950->{elementSetName}, 'f', "Setting elementSetName in Manager");


$options->set_utf8(1);
is($options->get_utf8(), 1, "utf8 support on");

print STDERR "Unable to implement utf8/unicode support--check to see that you have MARC::Charset\n"
           if !$options->get_utf8();
