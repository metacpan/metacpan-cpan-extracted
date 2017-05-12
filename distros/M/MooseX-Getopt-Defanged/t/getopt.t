#!/usr/bin/env perl

package MooseX::Getopt::Defanged::Test;

# All kinds of regex testing going on here, so we can't use the standard
# stuff.
## no critic (RequireDotMatchAnything, RequireExtendedFormatting, RequireLineBoundaryMatching)

use 5.010;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.18.0');


use English qw< $EVAL_ERROR -no_match_vars >;
use Readonly;


use parent 'Test::Class';


use File::Spec::Functions qw< catdir >;


use MooseX::Getopt::Defanged qw< :all >;


use Test::Deep;
use Test::Moose;
use Test::More;
use Test::Exception; # Has to be after use of Test::More.


use lib catdir( qw< t getopt.d lib > );


Readonly::Scalar my $ROLE_NAME => 'MooseX::Getopt::Defanged';

Readonly::Scalar my $TEST_STRING    => 'blah';
Readonly::Scalar my $TEST_INTEGER   => 123;
Readonly::Scalar my $TEST_NUMBER    => 1.23;
Readonly::Scalar my $TEST_REGEX     => 'x.x';
Readonly::Scalar my $TEST_KEY       => 'key';

# Boolean attribute will be handled separately.
Readonly my @TEST_5_PARAMETERS => (
    {
        name            => 'str',
        command_line    => $TEST_STRING,
        expected        => $TEST_STRING,
    },
    {
        name            => 'int',
        command_line    => $TEST_INTEGER,
        expected        => $TEST_INTEGER,
    },
    {
        name            => 'num',
        command_line    => $TEST_NUMBER,
        expected        => $TEST_NUMBER,
    },
    {
        name            => 'regexpref',
        command_line    => $TEST_REGEX,
        expected        => qr/(?ms:$TEST_REGEX)/,
    },
    {
        name            => 'arrayref',
        command_line    => [ $TEST_STRING, $TEST_STRING ],
        expected        => [ $TEST_STRING, $TEST_STRING ],
    },
    {
        name            => 'arrayref_str',
        command_line    => [ $TEST_STRING, $TEST_STRING ],
        expected        => [ $TEST_STRING, $TEST_STRING ],
    },
    {
        name            => 'arrayref_int',
        command_line    => [ $TEST_INTEGER, $TEST_INTEGER ],
        expected        => [ $TEST_INTEGER, $TEST_INTEGER ],
    },
    {
        name            => 'arrayref_num',
        command_line    => [ $TEST_NUMBER, $TEST_NUMBER ],
        expected        => [ $TEST_NUMBER, $TEST_NUMBER ],
    },
    {
        name            => 'hashref',
        command_line    => "$TEST_KEY=$TEST_STRING",
        expected        => { $TEST_KEY => $TEST_STRING },
    },
    {
        name            => 'hashref_str',
        command_line    => "$TEST_KEY=$TEST_STRING",
        expected        => { $TEST_KEY => $TEST_STRING },
    },
    {
        name            => 'hashref_int',
        command_line    => "$TEST_KEY=$TEST_INTEGER",
        expected        => { $TEST_KEY => $TEST_INTEGER },
    },
    {
        name            => 'hashref_num',
        command_line    => "$TEST_KEY=$TEST_NUMBER",
        expected        => { $TEST_KEY => $TEST_NUMBER },
    },
);


__PACKAGE__->runtests();


sub test_1_mooseness : Tests(1) {
    meta_ok($ROLE_NAME, "$ROLE_NAME has a meta class.");

    return;
} # end test_1_mooseness()


sub test_2_can_construct_minimal_consumer : Tests(7) {
    my $class_name = "${ROLE_NAME}::MinimalConsumer";
    use_ok($class_name);
    my $minimal_consumer = new_ok($class_name);

    meta_ok($minimal_consumer, 'Minimal consumer has a meta class.');
    does_ok(
        $minimal_consumer,
        $ROLE_NAME,
        "Minimal consumer does $ROLE_NAME.",
    );

    can_ok($minimal_consumer, 'parse_command_line');
    can_ok($minimal_consumer, 'get_remaining_argv');
    can_ok($minimal_consumer, 'get_option_type_metadata');

    return;
} # end test_2_can_construct_minimal_consumer()


sub test_3_can_parse_command_line_for_minimal_consumer : Tests(3) {
    my $minimal_consumer = new_ok("${ROLE_NAME}::MinimalConsumer");

    my @argv = qw< foo bar >;
    my $argv_ref = [ @argv ];

    $minimal_consumer->parse_command_line($argv_ref);

    cmp_deeply(
        $argv_ref,
        \@argv,
        'Command line parsing for minimal consumer did not change the argv reference.',
    );
    cmp_deeply(
        [ $minimal_consumer->get_remaining_argv() ],
        \@argv,
        'Command line parsing for minimal consumer left the remaining argv with the same contents as the original.',
    );

    return;
} # end test_3_can_parse_command_line_for_minimal_consumer()


sub test_5_can_parse_command_line_for_consumer_of_all_types : Tests(32) {
    my $class_name = "${ROLE_NAME}::ConsumerOfAllTypes";
    use_ok($class_name);
    my $consumer = new_ok($class_name);

    meta_ok($consumer, 'Consumer of all types has a meta class.');
    does_ok(
        $consumer,
        $ROLE_NAME,
        "Consumer of all types does $ROLE_NAME.",
    );

    my @extra_command_line_parameters = qw< foo bar >;
    my @argv = (
        @extra_command_line_parameters,
        qw< --bool --maybe-bool >,
    );
    foreach my $parameter (@TEST_5_PARAMETERS) {
        (my $name = $parameter->{name}) =~ s/ _ /-/xmsg;
        my $values = $parameter->{command_line};
        my @values = ref $values ? @{$values} : ($values);

        push @argv, "--$name", @values, "--maybe-$name", @values;
    } # end foreach

    my $argv_ref = [ @argv ]; # Needs to be a copy so that change can be detected.

    $consumer->parse_command_line($argv_ref);

    cmp_deeply(
        $argv_ref,
        \@argv,
        'Command line parsing for consumer of all types did not change the argv reference.',
    );
    cmp_deeply(
        [ $consumer->get_remaining_argv() ],
        \@extra_command_line_parameters,
        'Command line parsing for consumer of all types left the correct remaining argv.',
    );

    ok($consumer->bool(), 'The --bool option got set.');
    ok($consumer->maybe_bool(), 'The --maybe-bool option got set.');

    foreach my $parameter (@TEST_5_PARAMETERS) {
        my $name = $parameter->{name};
        (my $option_name = $name) =~ s/ _ /-/xmsg;
        my $expected = $parameter->{expected};

        my $accessor_name = "get_$name";
        cmp_deeply(
            $consumer->$accessor_name(),
            $expected,
            "Got correct value for the --$option_name option.",
        );

        $accessor_name = "get_maybe_$name";
        cmp_deeply(
            $consumer->$accessor_name(),
            $expected,
            "Got correct value for the --maybe-$option_name option.",
        );
    } # end foreach

    return;
} # end test_5_can_parse_command_line_for_consumer_of_all_types()


sub test_6_complains_about_input_problems : Tests(5) {
    my $consumer = new_ok("${ROLE_NAME}::ConsumerOfAllTypes");

    throws_ok
        { $consumer->parse_command_line( [ qw< --num not-a-number > ] ) }
        'MooseX::Getopt::Defanged::Exception::User',
        'Got an exception when passing a non-numeric value to --num.';
    my $error = $EVAL_ERROR;
    is(
        $error,
        qq<Value "not-a-number" invalid for option num (real number expected)\n>,
        'Got expected message for invalid --num value.'
    );

    throws_ok
        { $consumer->parse_command_line( [ qw< --num > ] ) }
        'MooseX::Getopt::Defanged::Exception::User',
        'Got an exception when passing a non-numeric value to --num.';
    $error = $EVAL_ERROR;
    is(
        $error,
        qq<Option num requires an argument\n>,
        'Got expected message for invalid --num value.'
    );

    return;
} # end test_6_complains_about_input_problems()


sub test_7_complains_about_missing_getopt_required_values : Tests(7) {
    my $class_name = "${ROLE_NAME}::ConsumerWithGetoptRequiredAttributes";
    use_ok($class_name);
    my $consumer = new_ok($class_name);

    meta_ok($consumer, 'Consumer with getopt_required attributes has a meta class.');
    does_ok(
        $consumer,
        $ROLE_NAME,
        "Consumer with getopt_required attributes does $ROLE_NAME.",
    );


    throws_ok
        { $consumer->parse_command_line( [] ) }
        'MooseX::Getopt::Defanged::Exception::User',
        'Got an exception when attempting to specify an empty command line with a consumer with getopt_required attributes.';
    my $error = $EVAL_ERROR;
    ok(
        0 <= index ( $error, qq<The --without-default argument must be specified.\n> ),
        'Exception message contained a complaint for the --without-default argument.',
    )
        or  diag("Exception message: $error");
    ok(
        0 <= index ( $error, qq<The --with-default argument must be specified.\n> ),
        'Exception message contained a complaint for the --with-default argument.',
    )
        or  diag("Exception message: $error");

    return;
} # end test_7_complains_about_missing_getopt_required_values()


sub test_8_regexpref_applies_modifiers : Tests(11) {
    my $class_name = "${ROLE_NAME}::ConsumerWithRegexpRefAttributes";
    use_ok($class_name);
    my $consumer = new_ok($class_name);

    meta_ok($consumer, 'Consumer with RegexpRef attributes has a meta class.');
    does_ok(
        $consumer,
        $ROLE_NAME,
        "Consumer with RegexpRef attributes does $ROLE_NAME.",
    );

    $consumer->parse_command_line(
        [
            map { ( "--regex-$_" => 'x' ) } qw< default m s i x p no-modifiers >
        ]
    );

    cmp_deeply(
        $consumer->get_regex_default(),
        qr<(?ms:x)>,
        'Got expected compiled regex for --regex-default.',
    );
    cmp_deeply(
        $consumer->get_regex_m(),
        qr<(?m:x)>,
        'Got expected compiled regex for --regex-m.',
    );
    cmp_deeply(
        $consumer->get_regex_s(),
        qr<(?s:x)>,
        'Got expected compiled regex for --regex-s.',
    );
    cmp_deeply(
        $consumer->get_regex_i(),
        qr<(?i:x)>,
        'Got expected compiled regex for --regex-i.',
    );
    cmp_deeply(
        $consumer->get_regex_x(),
        qr<(?x:x)>,
        'Got expected compiled regex for --regex-x.',
    );
    cmp_deeply(
        $consumer->get_regex_p(),
        qr<(?p:x)>,
        'Got expected compiled regex for --regex-p.',
    );
    cmp_deeply(
        $consumer->get_regex_no_modifiers(),
        qr<(?:x)>,
        'Got expected compiled regex for --regex-no-modifiers.',
    );

    return;
} # end test_8_regexpref_applies_modifiers()


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :
