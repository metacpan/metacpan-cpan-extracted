use Test::Most;

use Server::Module::Comparison;
ok my $comparer = Server::Module::Comparison->new({
        modules => []
    });

my $status1 = {
        'OpenERP::XMLRPC::Simple' => 'undef',
        'Moose' => 'missing',
		'OpusVL::AppKit' => '2.26',
		'OpusVL::CMS' => '0.82',
		'OpusVL::AppKitX::CMSView' => '0.75',
		'OpusVL::AuditTrail' => '0.20',
		'OpusVL::TokenProcessor::API' => '0.11',
		'Some::Schema' => '0.37',
	};
my $report_no_diff = $comparer->difference_report($status1, $status1);
eq_or_diff $report_no_diff, {
    downgraded => {},
    updated => {},
    removed => {},
    installed => {},
};
is $comparer->human_readable_report($report_no_diff), "No differences\n";

my $report = $comparer->difference_report(
	$status1,
	{
		'OpusVL::AppKit' => '2.25',
		'OpusVL::CMS' => '0.102',
		'OpusVL::CMSExport' => '0.1',
		'OpusVL::AppKitX::CMSView' => '0.76',
		'OpusVL::AuditTrail' => '0.20',
		'OpusVL::TokenProcessor::API' => '0.11',
	},
);
eq_or_diff $report, 
{
	downgraded => {
		'OpusVL::AppKit' => [
			'2.26',
			'2.25'
		]
	},
	installed => {
		'OpusVL::CMSExport' => '0.1'
	},
	removed => {
		'Some::Schema' => '0.37',
        'OpenERP::XMLRPC::Simple' => 'undef',
        'Moose' => 'missing',
	},
	updated => {
		'OpusVL::AppKitX::CMSView' => [
			'0.75',
			'0.76'
		],
		'OpusVL::CMS' => ['0.82', '0.102'],
	}
};

print $comparer->human_readable_report($report);
eq_or_diff $comparer->human_readable_report($report), <<"EOF";
DOWNGRADED Modules

OpusVL::AppKit                          	2.26 -> 2.25

REMOVED Modules

Moose                                   	missing
OpenERP::XMLRPC::Simple                 	undef
Some::Schema                            	0.37

Installed Modules

OpusVL::CMSExport                       	0.1

Updated Modules

OpusVL::AppKitX::CMSView                	0.75 -> 0.76
OpusVL::CMS                             	0.82 -> 0.102
EOF

done_testing;
