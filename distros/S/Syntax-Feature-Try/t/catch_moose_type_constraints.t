use Test::Spec;
require Test::NoWarnings;

use syntax 'try';
use Moose::Util::TypeConstraints;

{
    package MyMock::Error;
    use Moose;
    has 'category' => (is => 'ro');
}

class_type 'Error' => { class => 'MyMock::Error' };
subtype 'BillingError', as 'Error', where { $_->category eq 'billing' };

sub test_catch {
    my ($err, $expected_result) = @_;

    my $result;
    try { die $err }
    catch (BillingError $e) { $result='BillingError' }
    catch (Error $e) { $result='Error' }
    catch (MyMock::Error $e) { $result='MyMock::Error' }
    catch ($others) { $result='others' }

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is($result, $expected_result);
}

describe "catch using Moose::Util::TypeConstraint" => sub {
    it "handles Moose subtype BillingError" => sub {
        test_catch(MyMock::Error->new(category => 'billing'), 'BillingError');
    };

    it "handles Moose type Error" => sub {
        test_catch(MyMock::Error->new(category => 'abc'), 'Error');
    };

    it "handles other errors" => sub {
        test_catch('xyz', 'others');
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
