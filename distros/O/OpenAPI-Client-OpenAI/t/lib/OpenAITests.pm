package OpenAITests;

use lib 'lib';
use Test::Most;
use Test::RequiresInternet;
use mro;
use Import::Into;
use Carp 'croak';
use experimental 'signatures';

BEGIN {
    if ( !$ENV{OPENAI_API_KEY} ) {
        plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
    }
}

sub import {
    my $class   = shift;
    my $target  = caller;
    my @modules = qw(
        Data::Dumper
        JSON
        OpenAPI::Client::OpenAI
        Test::Most
        Test::RequiresInternet
        utf8
    );
    $_->import::into($target) foreach @modules;
    experimental->import::into( $target, 'signatures' );
    no strict 'refs';
    *{"${target}::run_test_cases"} = \&run_test_cases;
}

sub run_test_cases ($test_cases) {
    my $openai = OpenAPI::Client::OpenAI->new();
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    for my $test (@$test_cases) {
        my $method            = _required( $test, 'method' );
        my $params            = _required( $test, 'params' );
        my $expected_response = _required( $test, 'expected_response' );
        my $test_name         = $test->{description} || $test->{method} || "Could not determine test name";

        my $tx = $openai->$method( { body => $params } );

        my $response = $tx->res->json;
        my $actual_response;
        if ( my $against = $test->{against} ) {
            $actual_response = $against->($response);
        } else {
            $actual_response = $response->{choices}[0]{message};
        }

        cmp_deeply( $actual_response, $expected_response, $test_name )
            or explain $response;
    }
}

sub _required ( $case, $key ) {
    unless ( exists $case->{$key} ) {
        explain $case;
        croak("Test case missing required key '$key'");
    }
    return delete $case->{$key};
}


1;

__END__

=head1 NAME

OpenAITests

=head1 DESCRIPTION

Using this modul is equivalent to:

    use Data::Dumper;
    use JSON;
    use OpenAPI::Client::OpenAI;
    use Test::Most;
    use Test::RequiresInternet;
    use utf8;
    use experimental 'signatures';

=head2 C<run_test_cases>

    my @test_cases = (
        {
            method      => 'createCompletion',
            description => 'createCompletion with an instruct model',
            params      => {
                model       => 'gpt-3.5-turbo-instruct',
                prompt      => 'What is the capital of France?',
            },
            expected_response => qr{\bParis\b},
        },
        {
            method      => 'createCompletion',
            description => 'createCompletion with an instruct model, using `stop`',
            params      => {
                model       => 'gpt-3.5-turbo-instruct',
                prompt      => 'What is the capital of France?',
                stop        => 'aris',
            },
            expected_response => qr{P$},
        },
    );

    run_test_cases( \@test_cases );

Runs a set of test cases. The following keys are used for each test case:

=over 4

=item * method

The name of the OpenAI method to call.

=item * description

What are we testing? This will be used as the name of the test. If omitted, we
use the C<method> argument instead, but it's recommended that you not omit
this.

=item * params

The parameters which will be passed to the method.

=item * expected_response

A regular expression that should match the response outout.

=item * against

An optional subreference. It will be passed the OpenAI response as its only
argument. Typically, we test the C<expected_response> against C<<
$response->{choices}[0]{message} >>, but you may want to check something else
in the response. For example, to test C<expected_response> against the entire
response:

    against => sub ($response) {$response},

=back
