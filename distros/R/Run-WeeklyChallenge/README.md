# NAME

Run::WeeklyChallenge - facilitates running a solution to https://theweeklychallenge.org using one or more sets of inputs provided as JSON command line arguments

# SYNOPSIS

Example usage running a "solution" to sum integers:

```perl
use Run::WeeklyChallenge;

sub sum_of_ints {
    my ($int_array) = @_;
    my $sum = 0;
    $sum += $_ for @$int_array;
    return $sum;
}

# run_solution runs the solution for a single set of inputs; it may reformat
# the output if desired
my $run_solution = sub { sum_of_ints($_[0]{'ints'}) };

# inputs example for use in error message if incorrectly formatted inputs
# are given
my $inputs_example = '{"ints":[1,2,3]}';

# jsonschema (draft2020-12) for a set of inputs
my $inputs_schema_json = '{
    "type": "object",
    "properties": {
        "ints": {
            "type": "array",
            "items": { "type": "integer" }
        }
    },
    "required": ["ints"],
    "additionalProperties": false
}';

Run::WeeklyChallenge::run_weekly_challenge($run_solution, $inputs_example, $inputs_schema_json);
```

Example output:

```
$ perl example.pl '{"ints":[1,2,3]}' '{"ints":[]}'
Inputs: {"ints":[1,2,3]}
Output: 6
Inputs: {"ints":[]}
Output: 0
```

You must provide an example JSON inputs string (used in error messages), a JSON schema for inputs, and a shim function to run the solution given the decoded JSON inputs and reformat the output if desired.
