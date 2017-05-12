use strict;
use warnings;

use lib 'xt/lib';
use RT::Extension::AddAttachmentsFromTransactions::Test nodb => 1, tests => undef;

require_ok("RT::Extension::AddAttachmentsFromTransactions");
require_ok("RT::Extension::AddAttachmentsFromTransactions::Test");

done_testing;
