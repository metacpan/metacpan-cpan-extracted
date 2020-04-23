use strict;
use warnings;

use Test::More;

{
    package Example;
    use Test::More;
    use Test::Fatal;
    use Scalar::Util qw(refaddr);
    require OpenTracing::Any;
    no warnings 'once';

    sub shadowed { }

    is(exception {
        OpenTracing::Any->import
    }, undef, 'can run ::Any->import with default parameters');

    like(exception {
        OpenTracing::Any->import('$x', '$y', '$z');
    }, qr/too many parameters/, 'detects excessive parameters on import');
    like(exception {
        OpenTracing::Any->import('xyz');
    }, qr/invalid injected/, 'detects invalid variable format');

    is(exception {
        OpenTracing::Any->import('$renamed')
    }, undef, 'can run ::Any->import and override the variable name');
    is(refaddr($Example::tracer), refaddr($Example::renamed), 'tracers match in both cases');


    TODO: {
        local $TODO = 'variable overwrite detection only really works at compiletime';
        like(exception {
            OpenTracing::Any->import;
        }, qr/already has a variable/, 'attempting to overwrite an existing variable fails');

        is(exception {
            OpenTracing::Any->import('$shadowed')
        }, undef, 'can run ::Any->import with a variable name that shares a glob with an existing coderef');
    }
}
done_testing;

