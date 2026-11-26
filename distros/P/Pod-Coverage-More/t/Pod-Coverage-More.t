#!perl

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Pod::Coverage::More;

# The fixtures, whose POD disagrees with their subs.
require Mistyped;
require Documented;

# The messages of a result, one per line, in a stable order: they come out in hash order.
sub messages_of {
    my ($result) = @_;
    return [ sort split m/^/m, $result->{message} // '' ];
}

subtest coverage => sub {
    ok( !exists $INC{'FullyDocumented.pm'}, 'nothing loaded the fixture yet' ) or return;
    my $pc = Pod::Coverage::More->new( package => 'FullyDocumented' );
    is( $pc->coverage,                           1,          "the subs of a module that the caller did not load count as documented by its POD" );
    is( [ sort keys %{ $pc->coverage_report } ], ['double'], "and get a report" );

    my $missing = Pod::Coverage::More->new( package => 'No::Such::Bogus' );
    is( $missing->coverage,    undef,               "a module that is not installed is not rated" );
    is( $missing->why_unrated, "couldn't find pod", "because it has no POD" );
};

subtest a_package_loaded_from_outside_inc => sub {
    my $script = "$FindBin::Bin/script/scripted";
    local $INC{'Scripted/Program.pm'} = $script;
    require $script;
    my $pc = Pod::Coverage::More->new( package => 'Scripted::Program' );
    ok( defined $pc->coverage, "a package that no file on \@INC holds is rated, from the POD of the file that %INC names" ) or diag $pc->why_unrated;
};

subtest coverage_arguments => sub {
    my $result = Pod::Coverage::More->new( package => 'Mistyped' )->coverage_arguments;
    is( $result->{status}, 0, "an argument that the sub does not take fails" );
    is(
        messages_of($result),
        ["Var Mismatch for function wrong_name: colour not in color\n"],
        "the message names the function, the argument and the parameters"
    );
};

subtest coverage_argument_types => sub {
    my $result = Pod::Coverage::More->new( package => 'Mistyped' )->coverage_argument_types;
    is( $result->{status}, 0, "arguments with wrong or missing types fail" );
    is(
        messages_of($result),
        [
            "No type declared for arg size of untyped\n",
            "Type mismatch for arg count of wrong_type: got hash, expected scalar\n",
            "Var Type Mismatch for function wrong_sigil: \@items not in \$items\n",
            "Var colour not documented whatsoever for wrong_name!\n",
            "Var second not documented whatsoever for missing_item!\n",
        ],
        "one message for each kind of mistake"
    );
};

subtest coverage_report => sub {
    my $report = Pod::Coverage::More->new( package => 'Documented' )->coverage_report;
    my %failures;
    foreach my $name ( keys %$report ) {
        foreach my $check ( sort grep { $_ ne q{examples} } keys %{ $report->{$name}{failures} } ) {
            push @{ $failures{$name} }, map { "[$check] $_" } @{ $report->{$name}{failures}{$check} };
        }
    }
    is( $failures{good},                                       [],                                                                                                                                                                         "POD that says everything passes every check" );
    is( $failures{narrower},                                   [],                                                                                                                                                                         "a documented type narrower than the declared one passes" );
    is( $failures{maybe_return},                               [],                                                                                                                                                                         "documented return types that cover every returned type pass" );
    is( $failures{first_of},                                   [],                                                                                                                                                                         "an item whose name starts with another argument documents its own argument" );
    is( $failures{woven},                                      [],                                                                                                                                                                         "a section under =method passes, and a deeper heading stays part of it" );
    is( $failures{overloaded_double},                          [],                                                                                                                                                                         "a documented object passes against the result of an operator, which overloading can make an object" );
    is( $failures{weak_contradicted},                          ['[returns] Return type mismatch for weak_contradicted: returns Num (line 217), documented as HashRef'],                                                                    "but the result of an operator still fails against a type of another kind" );
    is( $failures{shouty},                                     [],                                                                                                                                                                         "a list of arguments with sigils matches in any case" );
    is( $failures{flag},                                       [],                                                                                                                                                                         "a literal satisfies a documented type by its value, as 1 and 0 are Bool" );
    is( $failures{not_flag},                                   ['[returns] Return type mismatch for not_flag: returns Int (line 255), documented as Bool'],                                                                                "and a literal that does not satisfy it fails" );
    is( $failures{field_reader},                               ['[arguments] Var Mismatch for function field_reader: colour not in self'],                                                                                                 "a key of the object is a field, and no named argument" );
    is( $failures{stub},                                       [],                                                                                                                                                                         "the POD names the arguments of a stub, whose code shows none, on the author's word" );
    is( $failures{empty_signature},                            [ '[argument_types] Var thing not documented whatsoever for empty_signature!', '[arguments] Var Mismatch for function empty_signature: thing not in ' ],                    "but an empty signature declares that the sub takes nothing" );
    is( $failures{broader},                                    ['[argument_types] Type mismatch for arg count of broader: documented Num, but Type::Tiny declares Int'],                                                                   "a documented type broader than the declared one fails" );
    is( $failures{contradicted},                               ['[argument_types] Type mismatch for arg list of contradicted: documented HashRef, but the code uses it as ArrayRef'],                                                      "a documented type of another kind than the code uses fails" );
    is( $failures{undocumented_return},                        ['[returns] No return value documented for undocumented_return'],                                                                                                           "a sub that returns a value must say so" );
    is( $failures{wrong_return},                               ['[returns] Return type mismatch for wrong_return: returns ArrayRef (line 101), documented as HashRef'],                                                                    "a returned type that the documented ones do not cover fails" );
    is( $failures{says_nothing},                               ['[returns] says_nothing is documented to return nothing, but it returns a value'],                                                                                         "POD that says it returns nothing must be right" );
    is( $failures{dies_quietly},                               ['[termination] dies_quietly can terminate (die at line 138), but its POD does not say so'],                                                                                "a sub that dies must say so" );
    is( $failures{second_of},                                  ['[argument_types] No type declared for arg dog of second_of'],                                                                                                             "an item whose type is not a type has no type, and documents only its own argument" );
    is( $failures{placeholder_method},                         [],                                                                                                                                                                         "any name documents a placeholder parameter, which has none, at its position" );
    is( $failures{placeholders},                               [],                                                                                                                                                                         "and so for a sub that takes only placeholders" );
    is( $failures{placeholder_sigils},                         [],                                                                                                                                                                         "and for an argument with a sigil" );
    is( $failures{placeholder_extra},                          ['[arguments] Var Mismatch for function placeholder_extra: extra not in self'],                                                                                             "but an argument beyond the parameters still fails" );
    is( $failures{relay_function},                             [],                                                                                                                                                                         "the value of a call, which may be nothing, does not contradict a POD that says it returns nothing" );
    is( $failures{relay_method},                               [],                                                                                                                                                                         "nor does the value of a method call" );
    is( $failures{relay_or_variable},                          ['[returns] relay_or_variable is documented to return nothing, but it returns a value'],                                                                                    "but a variable that it returns besides still does" );
    is( $failures{list_elements},                              [],                                                                                                                                                                         "an item with the sigil of a list parameter documents the type of each element" );
    is( $failures{scalar_as_list},                             ['[argument_types] Type mismatch for arg path of scalar_as_list: documented the elements of @path, expected scalar'],                                                       "but the sigil of a list does not document a scalar" );
    is( $failures{records},                                    [],                                                                                                                                                                         "a documented parameterization of the type that the code returns, as ArrayRef[HashRef] of ArrayRef, passes" );
    is( $failures{records_as_hash},                            ['[returns] Return type mismatch for records_as_hash: returns ArrayRef (line 486), documented as HashRef[HashRef]'],                                                        "but a parameterization of another kind still fails" );
    is( $failures{anonymous_slurpy},                           [],                                                                                                                                                                         "a slurpy with no name takes any name in the POD at its position or after it" );
    is( $failures{named_before_anonymous_slurpy},              [],                                                                                                                                                                         "and so after a named parameter, which still has its name" );
    is( $failures{anonymous_slurpy_misnamed},                  ['[arguments] Var Mismatch for function anonymous_slurpy_misnamed: total not in self count'],                                                                               "but a name at the position of a named parameter still fails" );
    is( $failures{undef_placeholder},                          [],                                                                                                                                                                         "any name documents an undef in a list assignment from \@_, at its position" );
    is( $failures{abstract_merge},                             [],                                                                                                                                                                         "a sub that takes only its invocant and never returns documents the interface of its subclasses" );
    is( $failures{abstract_ports},                             [],                                                                                                                                                                         "and so when it dies itself" );
    is( $failures{invocant_only},                              [ '[argument_types] Var Type Mismatch for function invocant_only: %opts not in $self', '[arguments] Var Mismatch for function invocant_only: opts not in self' ],           "but a sub that takes only its invocant and returns still takes no other argument" );
    is( $failures{assigned_heading},                           [],                                                                                                                                                                         "a heading that assigns its call still names its sub, and the other checks read its section" );
    is( $report->{assigned_heading}{failures}{examples},       ['The heading of assigned_heading is an example: move `$sum = Documented->assigned_heading($x, $y)` into a verbatim block, and head the section assigned_heading($x, $y)'], "but it is an example, which belongs in a verbatim block" );
    is( $report->{assigned_heading_alone}{failures}{examples}, [ 'The heading of assigned_heading_alone is an example: move `@pairs = Documented->assigned_heading_alone(%opts)` into a verbatim block, and head the section assigned_heading_alone(%opts)', 'No example of assigned_heading_alone in its POD' ], "and it is no example of the sub" );
    is( $report->{called_heading}{failures}{examples},         [],                                                                                                                                                                                                                                                "a heading that is a call of a method on a class, with no assignment, is no failure" );
    is( $failures{named_in_heading},                           [],                                                                                                                                                                                                                                                "a key => value pair in the heading documents a key of the named arguments" );
    is( $failures{wrongly_named_in_heading},                   [ '[argument_types] Var Type Mismatch for function wrongly_named_in_heading: stay_down not in $self $domain %opts', '[arguments] Var Mismatch for function wrongly_named_in_heading: stay_down not in self domain opts leave_down' ],              "but a key that the sub does not read still fails" );
    is( $report->{good}{failures}{examples},                   [],                                                                                                                                                                                                                                                "a verbatim call is an example" );
    is( $report->{narrower}{failures}{examples},               ['No example of narrower in its POD'],                                                                                                                                                                                                             "a section with no verbatim call has no example" );
};

subtest inherited_documentation => sub {
    require Descendant;
    my $pc = Pod::Coverage::More->new( package => 'Descendant' );
    is( $pc->coverage, 1, "a sub that a parent class documents counts as documented" );
    my $hook = $pc->coverage_report->{hook};
    is( $hook->{section}{heading},                                               'hook(record)', "and the checks read the section of the parent" );
    is( [ map { @{ $hook->{failures}{$_} } } sort keys %{ $hook->{failures} } ], [],             "against the code of the override" );
    my $templates = $pc->coverage_report->{template_files};
    is( [ map { @{ $templates->{failures}{$_} } } sort keys %{ $templates->{failures} } ], [], "an override need not take every argument that the section of its parent documents" );
    ok( $templates->{inherited}, "and the report says that the section is inherited" );
};

subtest trusted_by_pod => sub {
    require Trusted;
    my $pc = Pod::Coverage::More->new( package => 'Trusted' );
    is( $pc->coverage,        1,          "a sub that =for Pod::Coverage or =begin Pod::Coverage names counts as documented" ) or diag( join q{ }, $pc->naked );
    is( [ $pc->public_subs ], ['double'], "and is not public, so the checks skip it" );
};

subtest coverage_methods => sub {
    my $pc = Pod::Coverage::More->new( package => 'Documented' );
    is( $pc->coverage_termination->{status},                                                      0,                                                                             "coverage_termination fails when one sub fails it" );
    is( $pc->coverage_termination->{message},                                                     "dies_quietly can terminate (die at line 138), but its POD does not say so\n", "and gives each message on a line" );
    is( $pc->coverage_return_types->{status},                                                     0,                                                                             "coverage_return_types reports the returns check" );
    is( $pc->coverage_examples->{status},                                                         0,                                                                             "coverage_examples reports the examples check" );
    is( Pod::Coverage::More->new( package => 'No::Such::Package' )->coverage_arguments->{status}, 0,                                                                             "a package with no POD fails" );
};

done_testing;
