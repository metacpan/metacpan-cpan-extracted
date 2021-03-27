# -*- perl -*-
use strict;
use warnings;
use Test::More;
use Nice::Try;
# Test units provided by Tilmann Haeberle

package Sample::Exception {
    sub message { shift->{message} }

    sub throw {
        my ( $class, $message ) = @_;
        die $class->new($message);
    }

    sub new {
        my ( $class, $message ) = @_;
        return bless { message => $message }, $class;
    }
}

package Sample::Exception::A {
    use parent -norequire, 'Sample::Exception';
}

package Sample::Exception::B {
    use parent -norequire, 'Sample::Exception';
}

subtest 'nested try' => sub {
    my $caught_B;
    my $outer_caught;
    my $outer_entered;
    my $inner_entered;
    my $outer_continued;
    try {
        $outer_entered++;
        try {
            $inner_entered++;
            Sample::Exception::A->throw('inner');
        }
        catch ( Sample::Exception::B $e ) {
            $caught_B = $e;

            # some retry mechanism; let's assume it's failed
            die $e;    # rethrow
        }
        catch ( AnotherClass $e) {
            # never happens
        }
        # workaround: catch ($e) { die $e } # this is a little bit stupid
        $outer_continued++;    # shouldn't never reach
    }
    catch ($e) {
        $outer_caught = $e;
    }
    ok $outer_entered, 'outer entered';
    is $caught_B, undef, 'didn\'t catch exception in inner catch';
    ok !$outer_continued, 'outer_continued should never be reached';    # >fails with original Nice::Try

    isnt $outer_caught, undef, 'caught inner exception in outer catch'; # >fails with original Nice::Try
    if ($outer_caught) {
        isa_ok $outer_caught, 'Sample::Exception::A';
    }
};

done_testing;

