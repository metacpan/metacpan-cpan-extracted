use strict;
use warnings;

use Test::Tester 0.108;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::Deep::Type;

# the first type is an object that implements 'validate', just like
# MooseX::Types and Moose::Meta::TypeConstraint do
{
    package MyType::TypeHi;
    use overload('""' => sub { 'TypeHi' });
    sub validate
    {
        my ($self, $val) = @_;
        return "undef is not a 'hi'" if not defined $val;
        return undef if $val eq 'hi';   # validated: no error
        "'$val' is not a 'hi'";
    }
}

sub TypeHi { bless {}, 'MyType::TypeHi' }

is(TypeHi->validate('hi'), undef, 'validation succeeds (no error)');
is(TypeHi->validate('hello'), "'hello' is not a 'hi'", 'validation fails with error');

# the next type is an object that quacks like a coderef, dying if validation
# failed
sub TypeHiLite
{
    bless sub {
        my $val = shift;
        die((defined $val ? "'" . $val . "'" : '<undef>'), " is not a 'hi'\n")
            unless defined $val and $val eq 'hi';
    }, 'TypeHiLite';
}

is(
    exception { TypeHiLite->('hi') },
    undef,
    'validation succeeds (no error)',
);
like(
    exception { TypeHiLite->('hello') },
    qr/'hello' is not a 'hi'/,
    'validation fails with an exception',
);


# the next type is a plain old unblessed coderef, returning a simple boolean
# "did this validate", with no error message
sub TypeHiTiny
{
    sub {
        my $val = shift;
        return 1 if defined $val and $val eq 'hi';   # validated: no error
        return;
    };
}

ok(TypeHiTiny->('hi'), 'validation succeeds (no error)');
ok(!TypeHiTiny->('hello'), 'validation fails with a simple bool');

check_tests(
    sub {
        cmp_deeply({ greeting => 'hi' }, { greeting => is_type(TypeHi) }, 'hi validates as a TypeHi');
        cmp_deeply({ greeting => 'hi' }, { greeting => is_type(TypeHiLite) }, 'hi validates as a TypeHiLite');
        cmp_deeply({ greeting => 'hi' }, { greeting => is_type(TypeHiTiny) }, 'hi validates as a TypeHiTiny');
    },
    [ map { +{
        actual_ok => 1,
        ok => 1,
        diag => '',
        name => "hi validates as a $_",
        type => '',
    } } qw(TypeHi TypeHiLite TypeHiTiny) ],
    'validation successful',
);


my ($premature, @results) = run_tests(
    sub {
        cmp_deeply({ greeting => 'hello' }, { greeting => is_type(TypeHi) }, 'hello validates as a TypeHi');
        cmp_deeply({ greeting => 'hello' }, { greeting => is_type(TypeHiLite) }, 'hello validates as a TypeHiLite');
        cmp_deeply({ greeting => 'hello' }, { greeting => is_type(TypeHiTiny) }, 'hello validates as a TypeHiTiny');
        cmp_deeply({ greeting => 'hello' }, { greeting => is_type('not a ref!') }, 'hello validates against an arbitrary subref');
    },
);

Test::Tester::cmp_results(
    \@results,
    [
        {
            actual_ok => 0,
            ok => 0,
            name => 'hello validates as a TypeHi',
            type => '',
            diag => <<EOM,
Validating \$data->{"greeting"} as a TypeHi type
   got : 'hello' is not a 'hi'
expect : no error
EOM
        },
        {
            actual_ok => 0,
            ok => 0,
            name => "hello validates as a TypeHiLite",
            type => '',
            diag => <<EOM,
Validating \$data->{"greeting"} as a TypeHiLite type
   got : 'hello' is not a 'hi'
expect : no error
EOM
        },
        {
            actual_ok => 0,
            ok => 0,
            name => "hello validates as a TypeHiTiny",
            type => '',
            diag => <<EOM,
Validating \$data->{"greeting"} as an unknown type
   got : failed
expect : no error
EOM
        },
        {
            actual_ok => 0,
            ok => 0,
            name => 'hello validates against an arbitrary subref',
            type => '',
            # see diag check below
        },
    ],
    'validation fails',
);

like(
    $results[3]->{diag},
    qr/\A^Validating \$data->\{"greeting"\} as an unknown type$
^   got : Can't figure out how to use 'not a ref!' as a type.*$
^expect : no error$/ms,
    'diagnostics are clear that we cannot figure out how to use the type',
);

done_testing;
