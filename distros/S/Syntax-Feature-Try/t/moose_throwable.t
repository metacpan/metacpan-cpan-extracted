use Test::Spec;
require Test::NoWarnings;
use syntax 'try';

package My::Throwable {
    use Moose;
    with 'Throwable';
}

it "captures the previous_exception" => sub {
    my $caught;
    try {
        try {
            die 'previous_exception';
        }
        catch {
            like($@, qr/previous_exception/);
            My::Throwable->throw;
        }
    }
    catch (My::Throwable $e) {
        $caught = $e;
    }

    isa_ok($caught, 'My::Throwable');
    like $caught->previous_exception, qr/previous_exception/,
        'Caught the previous_exception';
};

runtests;
