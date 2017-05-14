#!perl

use Test::More tests => 18;

BEGIN
{
	use_ok('ProgressMonitor');
	use_ok('ProgressMonitor::AbstractConfiguration');
	use_ok('ProgressMonitor::AbstractStatefulMonitor');
	use_ok('ProgressMonitor::Exceptions');
	use_ok('ProgressMonitor::Null');
	use_ok('ProgressMonitor::State');
	use_ok('ProgressMonitor::Stringify::AbstractMonitor');
	use_ok('ProgressMonitor::Stringify::Fields::AbstractDynamicField');
	use_ok('ProgressMonitor::Stringify::Fields::AbstractField');
	use_ok('ProgressMonitor::Stringify::Fields::Bar');
	use_ok('ProgressMonitor::Stringify::Fields::Counter');
	use_ok('ProgressMonitor::Stringify::Fields::ETA');
	use_ok('ProgressMonitor::Stringify::Fields::Fixed');
	use_ok('ProgressMonitor::Stringify::Fields::Percentage');
	use_ok('ProgressMonitor::Stringify::Fields::Spinner');
	use_ok('ProgressMonitor::Stringify::ToStream');
	use_ok('ProgressMonitor::Stringify::ToCallback');
	use_ok('ProgressMonitor::SubTask');
}

diag("Testing ProgressMonitor $ProgressMonitor::VERSION");
