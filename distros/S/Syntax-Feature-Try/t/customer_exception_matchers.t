use Test::Spec;
use Test::Exception;
require Test::NoWarnings;

use syntax 'try';

{
    package id::test1;
    sub new { bless {}, shift };

    package name::test2;
    sub new { bless {}, shift };
}

sub id_matcher {
    my ($exception, $className) = @_;
    my ($id) = $className =~ /^id::(.+)/;
    return if not $id;
    return 0 if ref($exception);
    return $exception =~ /id="$id"/ ? 1 : 0;
}
sub name_matcher {
    my ($exception, $className) = @_;
    my ($name) = $className =~ /^name::(.+)/;
    return if not $name;
    return 0 if ref($exception);
    return $exception =~ /name="$name"/ ? 1 : 0;
}

sub test_catch_block {
    my ($exception) = @_;

    try                 { die $exception; }
    catch (id::test1)   { return "block id::test1"; }
    catch (name::test2) { return "block name::test2"; }
    catch               { return "block others";      }
    return "test error";
}

describe "register_customer_exception_matcher" => sub {
    it "throws error if parameter is invalid" => sub {
        throws_ok {
            Syntax::Feature::Try::register_exception_matcher('abc');
        } qr/Invalid parameter: expected CODE reference/;

        throws_ok {
            Syntax::Feature::Try::register_exception_matcher([]);
        } qr/Invalid parameter: expected CODE reference/;

        throws_ok {
            Syntax::Feature::Try::register_exception_matcher(undef);
        } qr/Invalid parameter: expected CODE reference/;
    };

    it "registers custom handler that will be called for testing exceptions" => sub {
        is(
            test_catch_block(id::test1->new()),
            'block id::test1',
            "Handle id::test1 instance in block id::test1 before register custom matcher"
        );
        is(
            test_catch_block(' id="test1" name="test2" '),
            'block others',
            "Handle any text exception in block others before register custom matcher"
        );

        is_deeply(
            [ Syntax::Feature::Try::_custom_exception_matchers() ],
            [],
            "Initially no exception matchers are registered"
        );

        Syntax::Feature::Try::register_exception_matcher(\&id_matcher);
        Syntax::Feature::Try::register_exception_matcher(\&name_matcher);

        is_deeply(
            [ Syntax::Feature::Try::_custom_exception_matchers() ],
            [ \&id_matcher, \&name_matcher ],
            "Both custom matchers are registered"
        );

        Syntax::Feature::Try::register_exception_matcher(\&name_matcher);
        Syntax::Feature::Try::register_exception_matcher(\&id_matcher);

        is_deeply(
            [ Syntax::Feature::Try::_custom_exception_matchers() ],
            [ \&id_matcher, \&name_matcher ],
            "There are no duplicates in array of matchers"
        );

        is(
            test_catch_block(id::test1->new()),
            'block others',
            "Handle id::test1 instance in block others,"
            ." because it does not match registered custom_handler"
        );
        is(
            test_catch_block(' id="test1" name="test2" '),
            'block id::test1',
            'Handle text containing id="test1" using custom handler id::test1'
        );
        is(
            test_catch_block(' id="abc" name="test2" '),
            'block name::test2',
            'Handle text containing name="test2" using custom handler name::test2'
        );
        is(
            test_catch_block(' id="abc" name="xyz" '),
            'block others',
            'Handle other text exceptions in block others'
        );
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
