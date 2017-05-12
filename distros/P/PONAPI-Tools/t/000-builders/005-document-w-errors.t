#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Document::Builder::Document');
}

subtest '... creating a document with errors' => sub {

    my $doc = PONAPI::Document::Builder::Document->new( version => '1.0' );
    isa_ok( $doc, 'PONAPI::Document::Builder::Document');

    # raise first error --> 400
    my $error1 = { status => 400, detail => "an error has occured" };
    $doc->raise_error( 400, $error1 );
    is($doc->status, 400, '... got the correct status');
    my $errors = $doc->build->{errors};
    is(scalar(@{$errors}), 1, 'we have one error');
    my $ret_err1 = $doc->build->{errors}[0];
    is_deeply(
        $ret_err1,
        $error1,
        "... and it is the correct one",
    );

    # raise a second error --> 409
    my $error2 = { status => 409, detail => "another error has occured" };
    $doc->raise_error( 409, $error2 );
    is($doc->status, 400, '... got the correct status (400 for multiple 4xx)');
    $errors = $doc->build->{errors};
    is(scalar(@{$errors}), 2, 'we have two errors');
    my $ret_err2 = $doc->build->{errors}[1];
    is_deeply(
        $ret_err2,
        $error2,
        "... and the one we added is the second",
    );

    # raise a third error --> 500
    my $error3 = { status => 500, detail => "a system error has occured" };
    $doc->raise_error( 500, $error3 );
    is($doc->status, 500, '... got the correct status (500 now)');
    $errors = $doc->build->{errors};
    is(scalar(@{$errors}), 3, 'we have three errors');
    my $ret_err3 = $doc->build->{errors}[2];
    is_deeply(
        $ret_err3,
        $error3,
        "... and the one we added is the third",
    );

    # raise a fourth error --> 401
    my $error4 = { status => 401, detail => "a fourth error has occured" };
    $doc->raise_error( 401, $error4 );
    is($doc->status, 500, '... got the correct status (500 for multiple errors with a system error)');
    $errors = $doc->build->{errors};
    is(scalar(@{$errors}), 4, 'we have four errors');
    my $ret_err4 = $doc->build->{errors}[3];
    is_deeply(
        $ret_err4,
        $error4,
        "... and the one we added is the fourth",
    );

};

subtest '... creating a document with errors (< 400)' => sub {

    my $doc = PONAPI::Document::Builder::Document->new( version => '1.0' );
    isa_ok( $doc, 'PONAPI::Document::Builder::Document');

    # raise first "error" --> 301
    my $error1 = { status => 301, detail => "not really an error" };
    $doc->raise_error( 301, $error1 );
    is($doc->status, 301, '... got the correct status');
    my $errors = $doc->build->{errors};
    is(scalar(@{$errors}), 1, 'we have one error');
    my $ret_err1 = $doc->build->{errors}[0];
    is_deeply(
        $ret_err1,
        $error1,
        "... and it is the correct one",
    );

    # raise a second "error" --> 303
    my $error2 = { status => 303, detail => "also not really an error" };
    $doc->raise_error( 303, $error2 );
    is($doc->status, 303, '... got the correct status');
    $errors = $doc->build->{errors};
    is(scalar(@{$errors}), 2, 'we have two error');
    my $ret_err2 = $doc->build->{errors}[1];
    is_deeply(
        $ret_err2,
        $error2,
        "... and it is the correct one",
    );

    # raise a third error --> 401
    my $error3 = { status => 401, detail => "an error has occured" };
    $doc->raise_error( 401, $error3 );
    is($doc->status, 400, '... got the correct status (400 because we have multiple-errors)');
    $errors = $doc->build->{errors};
    is(scalar(@{$errors}), 3, 'we have three errors');
    my $ret_err3 = $doc->build->{errors}[2];
    is_deeply(
        $ret_err3,
        $error3,
        "... and the one we added is the third",
    );

};

done_testing;
