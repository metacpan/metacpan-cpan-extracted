# vim: filetype=perl :

use strict;
use warnings;

use Test::More;
BEGIN {
    if($^O eq 'MSWin32') {
        plan skip_all => 'Mock tests don\'t work on windows.
#################################################################
#                                                               #
# The MockOpenERP tests unfortunately don\'t work on Windows.    #
#                                                               #
# To run the tests against a real OpenERP please specify the    #
# following $ENV variables                                      #
#                                                               #
#     OPENERP_SIMPLE_HOST - required!                           #
#     OPENERP_SIMPLE_PORT - default = 8069                      #
#     OPENERP_SIMPLE_NAME - default = terp                      #
#     OPENERP_SIMPLE_USER - default = admin                     #
#     OPENERP_SIMPLE_PASS - default = admin                     #
#                                                               #
#################################################################
' unless $ENV{OPENERP_SIMPLE_HOST};
}
plan tests => 18;
}


use FindBin;
use lib $FindBin::Bin . '/lib'; # use the test lib dir..
use Test::MockOpenERP;

BEGIN {
   use_ok('OpenERP::XMLRPC::Client');
}

# CONNECT

diag('
#################################################################
#                                                               #
# The following tests are built to run against a Mock OpenERP.  #
# (and will do, by default)                                     #
# To run the tests against a real OpenERP please specify the    #
# following $ENV variables                                      #
#                                                               #
#     OPENERP_SIMPLE_HOST - required!                           #
#     OPENERP_SIMPLE_PORT - default = 8069                      #
#     OPENERP_SIMPLE_NAME - default = terp                      #
#     OPENERP_SIMPLE_USER - default = admin                     #
#     OPENERP_SIMPLE_PASS - default = admin                     #
#                                                               #
#################################################################
');

my $using_mock_server = 1;
my $erp;

# CONNECT - to mock or external OpenERP

if ( ( exists $ENV{OPENERP_SIMPLE_HOST} ) )
{
	diag("Testing against external OpenERP server");

	my $host 		= $ENV{OPENERP_SIMPLE_HOST} || '127.0.0.1';
	my $dbname 		= $ENV{OPENERP_SIMPLE_NAME} || 'terp';
	my $username 	= $ENV{OPENERP_SIMPLE_USER} || 'admin';
	my $password 	= $ENV{OPENERP_SIMPLE_PASS} || 'admin' ;
	my $port 		= $ENV{OPENERP_SIMPLE_PORT} || '8069';

	ok ( $erp = OpenERP::XMLRPC::Client->new( dbname => $dbname, username => $username, password => $password, host => $host, port => $port ), 'instanciated' );

	$using_mock_server = 0;
}
else
{
	diag("Testing against mock OpenERP server");

	# start mock server..
	my $port = Test::MockOpenERP->start;
    note "Running mock server on port $port";

	# connect to mock server..
	ok ( $erp = OpenERP::XMLRPC::Client->new( port => $port ), 'instanciated' );
}


# CREATE - a partner

my $new_partner_details = 
{
	name	=> 'Test Partner'
};

ok ( my $new_partner_id = $erp->create('res.partner', $new_partner_details ), "create - partner using details" );
cmp_ok ( $new_partner_id, '>=',  1, "create - result is ID more than 1");


# UPDATE - the partner

my $update_partner_details = 
{
	name => 'Test Partner - updated'
};

ok ( my $success_flag = $erp->update('res.partner', $new_partner_id, $update_partner_details ), "update - partner using details" );
cmp_ok ( $success_flag, '==',  1, "update - result is ok");

# SEARCH - ids

ok ( my $search_results_all_ids = $erp->search('res.partner'), 'search - all - returns id only' );
cmp_ok ( ref $search_results_all_ids, 'eq', 'ARRAY', "search - all - result is array ref");
cmp_ok ( $search_results_all_ids->[0], '>=', 1, "search - all - result index 1 is and int");

# SEARCH - detail

ok ( my $search_results_all_details = $erp->search_detail('res.partner'), 'search - all - returns array of data' );
cmp_ok ( ref $search_results_all_details, 'eq', 'ARRAY', "search - all - result is array ref");
cmp_ok ( ref $search_results_all_details->[0], 'eq', 'HASH', "search - all - result index 1 is a hash ref");

# SEARCH - using args

ok ( my $search_results_some = $erp->search_detail('res.partner', [ [ 'name', 'ilike', 'A'] ] ), 'search - with args' );
my $partner_id1 = $search_results_some->[0]->{id};
my $partner_id2 = $search_results_some->[1]->{id};

# READ - multi

ok ( my $read_result_multi = $erp->read('res.partner', [ $partner_id2, $partner_id1 ] ), "read - get 2 results" );
cmp_ok ( ref $read_result_multi, 'eq', 'ARRAY', "read - multi - result is array ref");

# READ - single

ok ( my $read_result_single = $erp->read_single('res.partner', $partner_id1 ), "read - get 1 result" );
cmp_ok ( ref $read_result_single, 'eq', 'HASH', "read - single - result is hash ref");

# DELETE - the partner

ok ( my $deleted_ids = $erp->delete('res.partner', $new_partner_id ), "delete - partner using id" );



if ( $using_mock_server )
{
	# stop mock server..
	Test::MockOpenERP->stop;
}


