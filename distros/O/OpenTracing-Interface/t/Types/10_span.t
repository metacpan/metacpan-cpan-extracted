use Test::Most;

=head1 DESCRIPTION

This test merely checks that the OpenTracing::Types has been defined
correctly and not accidently added required subroutines that this test is not
aware off.

=cut

use strict;
use warnings;

# Dear developer, for the sake of testing, please DO NOT just copy paste the
# methods from the `OpenTracing::Types` file. If I wanted to just
# check that the `duck_type` utility from `Type::Tiny` would work, I would have
# not needed this test.
#
# This test is to ensure that what is written in the POD files is indeed what
# the Types library is doing.
#
# The OpenTracing::Interface::*.pod files are leading, not the code.
#
use constant {
    CLASS_NAME       => 'Span',
    REQUIRED_METHODS => [ qw(
        get_context
        overwrite_operation_name
        finish
        set_tag
        log_data
        set_baggage_item
        get_baggage_item
    ) ],
};

use lib 't/lib';

use TestUtils qw/is_Type/;
use MockUtils;


use OpenTracing::Types '+' . CLASS_NAME;

my $ok;



subtest 'All Methods defined in Duck Type are present in Mocked Object' => sub {
    
    my $correct_object = MockUtils::build_mock_object(
        class_name    => CLASS_NAME,
        class_methods => REQUIRED_METHODS,
    );
    
    no strict qw/refs/;
    
    $ok = is_Type( CLASS_NAME, $correct_object );
    
    ok $ok, "Mocked Object has minimal Required Methods from Duck Type";
    
};



SKIP: {
    
skip "Mocked Object already missing Required Methods", 1 unless $ok;

subtest 'All Methods mentioned in test are required by the Duck Type' => sub {
    
    foreach my $missing_method ( sort @{; REQUIRED_METHODS } ) {
        
        my $missing_object = MockUtils::build_mock_missing_object(
                class_name     => CLASS_NAME,
                class_methods  => REQUIRED_METHODS,
                missing_method => $missing_method,
        );
        
        no strict qw/refs/;
        
        ok ! is_Type( CLASS_NAME, $missing_object ),
            "Duck Type does check method: $missing_method"
        ;
    };
    
};

} # END_OF_SKIPP



done_testing();



1;
