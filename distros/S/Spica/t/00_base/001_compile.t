use Test::More;

use_ok $_ for qw(
    Spica
    Spica::Event
    Spica::Client
    Spica::Filter
    Spica::Parser
    Spica::Parser::JSON
    Spica::Receiver::Iterator
    Spica::Receiver::Row
    Spica::Spec
    Spica::Spec::Declare
    Spica::Trigger
    Spica::Types
    Spica::URIMaker
);

done_testing;

