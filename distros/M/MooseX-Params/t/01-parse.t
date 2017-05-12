use strict;
use warnings;

use Test::Most;
use MooseX::Params::Util;

my @specs = MooseX::Params::Util::parse_attribute(q{
    self:
    Str *test,
    &ArrayRef[Int] number?,
    :simple,
    count = _build_count(),
    string = 'hdfdd\n!!llo',
    Int :outcome(result) = 5,
    :(calc)=
});

is(@specs, 8, "number of parameters");

my @expected = (
    # self:
    {
        name     => 'self',
        init_arg => 'self',
        required => 1,
        type     => 'positional',
    },
    # Str *test
    {
        name     => "test",
        init_arg => "test",
        required => 1,
        type     => "positional",
        slurpy   => 1,
        isa      => "Str",
        coerce   => 0,
        default  => undef,
        builder  => undef,
        lazy     => 0,
    },
    # &ArrayRef[Int] number?
    {
        name     => "number",
        init_arg => "number",
        required => 0,
        type     => "positional",
        slurpy   => 0,
        isa      => "ArrayRef[Int]",
        coerce   => 1,
        default  => undef,
        builder  => undef,
        lazy     => 0,
    },
    # :simple
    {
        name     => "simple",
        init_arg => "simple",
        required => 1,
        type     => "named",
        slurpy   => 0,
        isa      => undef,
        coerce   => 0,
        default  => undef,
        builder  => undef,
        lazy     => 0,
    },
    # count = _build_count()
    {
        name     => "count",
        init_arg => "count",
        required => 1,
        type     => "positional",
        slurpy   => 0,
        isa      => undef,
        coerce   => 0,
        default  => undef,
        builder  => "_build_count",
        lazy     => 1,
    },
    # string = 'hdfdd\n!!llo'
    {
        name     => "string",
        init_arg => "string",
        required => 1,
        type     => "positional",
        slurpy   => 0,
        isa      => undef,
        coerce   => 0,
        default  => "hdfdd\\n!!llo",
        builder  => undef,
        lazy     => 0,
    },
    # Int :outcome(result) = 5
    {
        name     => "result",
        init_arg => "outcome",
        required => 1,
        type     => "named",
        slurpy   => 0,
        isa      => "Int",
        coerce   => 0,
        default  => 5,
        builder  => undef,
        lazy     => 0,
    },
    # :(calc)=
    {
        name     => "calc",
        init_arg => undef,
        required => 1,
        type     => "named",
        slurpy   => 0,
        isa      => undef,
        coerce   => 0,
        default  => undef,
        builder  => "_build_param_calc",
        lazy     => 1,
    },
);

is_deeply(\@specs, \@expected, "parameter specifications");

done_testing;
