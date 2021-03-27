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

package Sample::Exception::Refined {
    use parent -norequire, 'Sample::Exception';
}

subtest 'catch class > all' => sub {
    my $exception;
    try {
        Sample::Exception->throw('example');
    }
    catch ($e) {
        $exception = $e;
    }
    if ($exception) {

        isnt $exception, undef, 'unspecified catches class';
        isa_ok $exception, 'Sample::Exception';
        is $exception->message, 'example', 'message';
    }
};

subtest 'catch class' => sub {
    my $exception;
    try {
        Sample::Exception->throw('refined');
    }
    catch ( Sample::Exception $e) {
        $exception = $e;
    }

    isnt $exception, undef, 'class catches class';
    if ($exception) {
        isa_ok $exception, 'Sample::Exception';
        is $exception->message, 'refined', 'message';
    }
};

subtest 'catch subclass > all' => sub {
    my $exception;
    try {
        Sample::Exception::Refined->throw('refined')
    }
    catch ($e) {
        $exception = $e;
    }
    isnt $exception, undef, 'unspecified catches subclass';
    if ($exception) {
        isa_ok $exception, 'Sample::Exception';
        isa_ok $exception, 'Sample::Exception::Refined';
        is $exception->message, 'refined', 'message';
    }
};

subtest 'catch subclass' => sub {
    my $exception;
    try {
        Sample::Exception::Refined->throw('refined');
    }
    catch ( Sample::Exception::Refined $e) {
        $exception = $e;
    }

    isnt $exception, undef, 'subclass catches subclass';
    if ($exception) {
        isa_ok $exception, 'Sample::Exception';
        isa_ok $exception, 'Sample::Exception::Refined';
        is $exception->message, 'refined', 'message';
    }
};

subtest 'don\'t catch child unexpected' => sub {
    plan skip_all => 'this doesn\'t work as expected, neither with fixed Nice::Try nor with TryCatch';
    my $exception;
    try {
        Sample::Exception->throw('refined');
    }
    catch ( Sample::Exception::Refined $e) {
        $exception = $e;
    }

    # with TryCatch we even leave the sub
    # and don't reach the code here.
    # That is a bug of TryCatch IMHO
    is $exception, undef, 'subclass doesn\'t catch parent';
};

subtest 'don\'t catch child' => sub {

    my $exception;
    my $sub = sub {
        try {
            Sample::Exception->throw('refined');
        }
        catch ( Sample::Exception::Refined $e) {
            $exception = $e;
            return 'in_catch';
        }
        return 'after_catch';    # never reached
    };

    my $r = eval { &$sub };
    my $e = $@;

    is $exception, undef, 'subclass doesn\'t catch parent';
    is $r,         undef, 'no return value';
    isnt $e,       undef, 'exception caught outside';
    isa_ok $e,     'Sample::Exception';

    # with TryCatch we even leave the sub
    # and don't reach the code here.
    # That is a bug of TryCatch IMHO

};

subtest 'catch parent' => sub {
    my $exception;
    try {
        Sample::Exception::Refined->throw('refined');
    }
    catch ( Sample::Exception $e) {
        $exception = $e;
    }

    isnt $exception, undef, 'parent catches subclass';    # >fails with original Nice::Try
    if ($exception) {
        isa_ok $exception, 'Sample::Exception';
        isa_ok $exception, 'Sample::Exception::Refined';
        is $exception->message, 'refined', 'message';
    }
};

done_testing;
