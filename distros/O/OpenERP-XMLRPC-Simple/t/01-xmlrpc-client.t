# vim: filetype=perl :

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . '/lib'; # use the test lib dir..
use Test::MockOpenERP;
use Test::More;
BEGIN {
    if($^O eq 'MSWin32') {
        plan skip_all => 'Mock tests don\'t work on windows.';
    };

    use_ok('OpenERP::XMLRPC::Client');
}

# CONNECT

#ok ( my $erp = OpenERP::XMLRPC::Client->new( dbname => 'openerp5_test', username => 'admin', password => 'admin', host => '10.42.43.43' ), 'instanciated' );

# start mock server..
my $port = Test::MockOpenERP->start;
note "Running mock server on port $port";

# connect to mock server..
ok ( my $erp = OpenERP::XMLRPC::Client->new( port => $port ), 'created' );

# check the roles..
ok ( $erp->can('object_execute'), 'has the method "object_execute"' );
ok ( $erp->can('object_exec_workflow'), 'has the method "object_exec_workflow"' );
ok ( $erp->can('report_report'), 'has the method "report_report"' );
ok ( $erp->can('report_report_get'), 'has the method "report_report_get"' );

# stop mock server..
Test::MockOpenERP->stop;

done_testing;
