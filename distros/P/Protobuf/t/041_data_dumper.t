use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Protobuf;

# We do NOT use 'use lib "t/lib"' as per SOP.
# Instead, we rely on -It/lib being passed to the 'prove' command.
use TestHelpers;

subtest 'Data::Dumper export and import' => sub {
    local $Data::Dumper::Freezer = 'FREEZE';
    local $Data::Dumper::Toaster = 'THAW';

    # Load descriptors into global generated pool for parse/THAW
    my $pool = Protobuf::DescriptorPool->generated_pool;
    TestHelpers->load_test_protos($pool, 't/data/test_descriptor.bin');

    my $dump;
    my $class = 'Protobuf_perl_test::Test::TestMessage';

    # 1. Export (Dump) inside a restricted scope
    {
        my $msg = $class->new();
        $msg->set('value', 42);
        $msg->set('optional_uint32', 123);
        $msg->set('test_string', 'hello dumper');

        # Configure Data::Dumper to use FREEZE/THAW hooks
        local $Data::Dumper::Freezer = 'FREEZE';
        local $Data::Dumper::Toaster = 'THAW';

        $dump = Dumper($msg);
        ok($dump, "Serialized message to Data::Dumper format");
        like($dump, qr/hello dumper/, "Dump contains the string field value");
    } # $msg goes out of scope and is destroyed here!

    # 2. Import (Eval) in a new scope
    local $Data::Dumper::Toaster = 'THAW';
    our $VAR1;
    eval "our \$VAR1;\n$dump";
    my $err = $@;
    my $msg2 = $VAR1;

    ok(defined $msg2, "Deserialized message from Data::Dumper format") 
        or diag("Eval failed: $err\nDump was:\n$dump");

    # 3. Validate reconstructed object
    if (defined $msg2) {
        isa_ok($msg2, $class, "Reconstructed object");
        is($msg2->get('value'), 42, "Restored value (int32)");
        is($msg2->get('optional_uint32'), 123, "Restored optional_uint32");
        is($msg2->get('test_string'), 'hello dumper', "Restored test_string");
    }

    done_testing();
};

done_testing();
