use Test::Spec;
require Test::NoWarnings;
use Exception::Class qw/ MyErr /;
use Test::Warn;

use syntax 'try';

our @done;

sub test_for_loop {
    my $mode = shift;
    foreach (qw/ 0 3 X /) {
        try {
            push @done, "try-$_";
            MyErr->throw if $mode =~ /err/;
            last if $_ and $mode =~ /last/;
        }
        catch (MyErr $e) {
            push @done, "catch-$_";
            last if $_ and $mode =~ /last/;
        }
        finally {
            push @done, "finally-$_";
        }
        push @done, "after-$_";
    }
    push @done, 'end';
    return @done;
}

describe "foreach loop" => sub {
    before each => sub {
        @done = ();
    };

    it "works with try block" => sub {
        is_deeply(
            [ test_for_loop('') ],
            [qw/
                try-0   finally-0   after-0
                try-3   finally-3   after-3
                try-X   finally-X   after-X
                end
            /]
        );
    };

    # TODO allow this test if it will have been working
    xit "works with last called inside try block" => sub {
        is_deeply(
            [ test_for_loop('last') ],
            [qw/
                try-0   finally-0   after-0
                try-3   finally-3
                xend
            /]
        );
    };

    it "works with catch block" => sub {
        is_deeply(
            [ test_for_loop('err') ],
            [qw/
                try-0   catch-0     finally-0   after-0
                try-3   catch-3     finally-3   after-3
                try-X   catch-X     finally-X   after-X
                end
            /]
        );
    };

    # TODO allow this test if it will have been working
    xit "works with last called inside catch block" => sub {
        is_deeply(
            [ test_for_loop('err-last') ],
            [qw/
                try-0   catch-0 finally-0   after-0
                try-3   catch-3 finally-3
                xend
            /]
        );
    };

};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
