use strict;
use warnings;
use Test::More;

# Verify that the module can be loaded correctly.
use_ok('OpenAIGPT4');

# Create a new instance.
my $gpt4 = OpenAIGPT4->new('dummy-api-key');

# Confirm that the object has been created correctly.
isa_ok($gpt4, 'OpenAIGPT4');

# Confirm that the generate_text method exists.
can_ok($gpt4, 'generate_text');

# Declare that all tests have been completed.
done_testing();
