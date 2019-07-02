#!perl -T

use strict;
use warnings;
use Test::More;

require_ok('Net::SecurityCenter');
require_ok('Net::SecurityCenter::Error');
require_ok('Net::SecurityCenter::REST');
require_ok('Net::SecurityCenter::Utils');

require_ok('Net::SecurityCenter::API::Analysis');
require_ok('Net::SecurityCenter::API::Credential');
require_ok('Net::SecurityCenter::API::Feed');
require_ok('Net::SecurityCenter::API::File');
require_ok('Net::SecurityCenter::API::Plugin');
require_ok('Net::SecurityCenter::API::PluginFamily');
require_ok('Net::SecurityCenter::API::Report');
require_ok('Net::SecurityCenter::API::Repository');
require_ok('Net::SecurityCenter::API::Scan');
require_ok('Net::SecurityCenter::API::ScanResult');
require_ok('Net::SecurityCenter::API::Scanner');
require_ok('Net::SecurityCenter::API::System');
require_ok('Net::SecurityCenter::API::User');
require_ok('Net::SecurityCenter::API::Zone');

done_testing();

diag("Net::SecurityCenter $Net::SecurityCenter::VERSION, Perl $], $^X");
