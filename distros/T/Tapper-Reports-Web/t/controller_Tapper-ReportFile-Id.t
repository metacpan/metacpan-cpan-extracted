use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper::ReportFile::Id' }

#ok( request('/tapper/reportfile/id')->is_success, 'Request should succeed' );
