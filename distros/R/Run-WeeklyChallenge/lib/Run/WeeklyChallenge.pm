use 5.040;

# ABSTRACT: Perl library to facilitate running a solution to https://theweeklychallenge.org using one or more sets of inputs provided as JSON command line arguments

=pod

=head1 NAME

Run::WeeklyChallenge - facilitates running a solution to https://theweeklychallenge.org using one or more sets of inputs provided as JSON command line arguments

=head1 SYNOPSIS

Example usage running a "solution" to sum integers:

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

Example output:

    $ perl example.pl '{"ints":[1,2,3]}' '{"ints":[]}'
    Inputs: {"ints":[1,2,3]}
    Output: 6
    Inputs: {"ints":[]}
    Output: 0

You must provide an example JSON inputs string (used in error messages), a JSON schema for inputs, and a shim function to run the solution given the decoded JSON inputs and reformat the output if desired.

=cut

package Run::WeeklyChallenge {
$Run::WeeklyChallenge::VERSION = '0.001';
use Cpanel::JSON::XS;
    use JSON::Schema::Modern;
    my $json = Cpanel::JSON::XS->new->allow_nonref;
    my $validator = JSON::Schema::Modern->new( 'specification_version' => 'draft2020-12', 'output_format' => 'flag' );

    sub run_weekly_challenge($run_solution, $inputs_example, $inputs_schema_json) {

        my $inputs_schema = $json->decode($inputs_schema_json);

        my $inputs_error;

        for my $inputs_json (@ARGV) {
            say "Inputs: $inputs_json";

            try {
                my $inputs = $json->decode($inputs_json);
                if (! $validator->evaluate($inputs, $inputs_schema)->valid) {
                    $inputs_error = true;
                    say "Error: invalid inputs";
                    next;
                }
                else {
                    try {
                        my $result = $run_solution->($inputs);
                        say "Output: $result";
                    }
                    catch ($e) {
                        chomp $e;
                        say "Exception: $e";
                    }
                }
            }
            catch ($e) {
                $inputs_error = true;
                chomp $e;
                say "Error: invalid inputs JSON: $e";
                next;
            }
        }

        if ($inputs_error) {
            say "Error: Expected inputs arguments like '$inputs_example'";
        }

        return;
    }
}
