use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Eg::Node';

use SPVM 'TestCase::Eg::DOM::Implementation';

use SPVM 'TestCase::Eg::Node::Document';

use SPVM 'TestCase::Eg::Node::Document';

use SPVM 'TestCase::Eg::Node::Document::XML';

use SPVM 'Eg';
use SPVM::Eg;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::Eg::Node->test);

ok(SPVM::TestCase::Eg::Node->node);

ok(SPVM::TestCase::Eg::Node->element);

ok(SPVM::TestCase::Eg::Node::Document->create_text_node);

ok(SPVM::TestCase::Eg::Node::Document->create_element);

ok(SPVM::TestCase::Eg::Node::Document::XML->create_element);

ok(SPVM::TestCase::Eg::DOM::Implementation->create_html_document);

ok(SPVM::TestCase::Eg::DOM::Implementation->create_document);

# Version check
{
  my $version_string = SPVM::Fn->get_version_string("Eg");
  is($SPVM::Eg::VERSION, $version_string);
}

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
