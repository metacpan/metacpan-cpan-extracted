use strict;
use warnings;
use lib "t/lib";
use TestHelpers;
use Data::Dumper;
use Protobuf::Message;

# Load descriptors
my $pool = TestHelpers->get_generated_pool();
# Note: t/014_message_base.t uses t/data/test_descriptor.bin.
# But wait, in our CitC workspace, where is the descriptor?
# It should be in the same relative path.
# Let's try to load it. If it fails, we will see the error.
eval {
    TestHelpers->load_test_protos($pool, 't/data/test_descriptor.bin');
};
if ($@) {
    die "Failed to load protos: $@";
}

my $msg = Protobuf_perl_test::Test::TestMessage->new();
$msg->set('value', 42);
$msg->set('optional_uint32', 123);

print "--- Original Message ---\n";
print "value: ", $msg->get('value'), "\n";
print "optional_uint32: ", $msg->get('optional_uint32'), "\n";

print "\n--- Data::Dumper Output ---\n";
my $dump = Dumper($msg);
print $dump;

print "\n--- Attempting to Eval Dump ---\n";
my $msg2 = eval $dump;
if ($@) {
    print "Eval failed: $@\n";
} else {
    print "Eval succeeded!\n";
    if (ref($msg2)) {
        print "Reconstructed object type: ", ref($msg2), "\n";
        # Try to access fields
        eval {
            print "value: ", $msg2->get('value'), "\n";
            print "optional_uint32: ", $msg2->get('optional_uint32'), "\n";
        };
        if ($@) {
            print "Accessing fields on reconstructed object failed: $@\n";
        }
    } else {
        print "Reconstructed value is not a reference!\n";
    }
}
