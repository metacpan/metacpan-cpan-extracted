use strict;
use warnings;

package Local::Test;
use Test::More;
use Test::Fatal;

use Myriad::Exception::Builder;

is(exception {
    declare_exception Example => category => 'some_category', message => 'this is a message';
}, undef, 'can declare an exception with category and message');

subtest 'can declare exceptions' => sub {
    can_ok('Myriad::Exception::Local::Test::Example', qw(new category message reason throw));
    my $ex = new_ok('Myriad::Exception::Local::Test::Example' => [
    ]);
    is($ex->message, 'this is a message (category=some_category)', 'message is correct');
    is($ex->category, 'some_category', 'category is correct');
    is("$ex", 'this is a message (category=some_category)', 'stringifies too');
};

done_testing;

__END__

subtest 'needs category' => sub {
    like(exception {
        package Exception::Example::MissingCategory;
        Myriad::Exception::Builder->import(qw(:immediate));
    }, qr/missing category/, 'refuses to compile an exception class without a category');
};

subtest 'stringifies okay' => sub {
    is(exception {
        package Exception::Example::Stringification;
        sub category { 'example' }
        sub message { 'example message' }
        Myriad::Exception::Builder->import(qw(:immediate));
    }, undef, 'simple exception class can be defined');
    my $ex = new_ok('Exception::Example::Stringification');
    can_ok($ex, qw(new throw message category));
    is("$ex", 'example message', 'stringifies okay');
};

subtest 'can ->throw' => sub {
    is(exception {
        package Exception::Example::Throwable;
        sub category { 'example' }
        sub message { 'this was thrown' }
        Myriad::Exception::Builder->import(qw(:immediate));
    }, undef, 'simple exception class can be defined');
    isa_ok(my $ex = exception {
        Exception::Example::Throwable->throw;
    }, qw(Exception::Example::Throwable));
    is("$ex", 'this was thrown', 'message survived');
};

done_testing;

