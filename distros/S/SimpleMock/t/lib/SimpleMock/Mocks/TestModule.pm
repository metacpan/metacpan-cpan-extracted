package SimpleMock::Mocks::TestModule;
use strict;
use warnings;
use SimpleMock qw(register_mocks);

# You can globally set a mock for a subroutine
sub sub_two {
  return "mocked";
}

# You can also set global default mocks for a subroutine in the package
register_mocks(
    'SUBS' => {
        'TestModule' => {
            sub_five => [
                { returns => "mocked sub_five" },
                { args => [1,2], returns => "mocked sub_five with args" },
            ],
        }
    },
);

1;
