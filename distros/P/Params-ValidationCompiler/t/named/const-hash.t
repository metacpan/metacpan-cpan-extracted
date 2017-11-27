use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;
use Test2::Require::Module 'Const::Fast';

use Const::Fast;
use Params::ValidationCompiler qw( validation_for );
use Specio::Library::Builtins;

skip_all(
    q{Const::Fast doesn't work on dev/blead perl. Also the tests fail on Perl 5.18 but not others for no reason I can understand}
);

{
    # Trying to use const my %spec gives a "Can't store CODE items at
    # /home/autarch/.perlbrew/libs/perl-5.24.0@dev/lib/perl5/Const/Fast.pm
    # line 29." Presumably this is because the Specio type ultimately contains
    # a code ref deep inside. Is Const::Fast iterating through the object and
    # trying to make it readonly as well?!
    todo(
        'cannot pass a hash with a CODE ref nested in it',
        sub {
            is(
                dies {
                    const my %spec => (
                        foo => 1,
                        bar => {
                            type     => t('Int'),
                            optional => 1,
                        },
                    );
                },
                undef,
            );
        }
    );

    # But somehow this works.
    const my $spec => {
        foo => 1,
        bar => {
            type     => t('Int'),
            optional => 1,
        },
    };

    my $sub = validation_for( params => $spec );

    const my %params1 => ( foo => 42 );
    is(
        dies { $sub->(%params1) },
        undef,
        'lives when given foo param but no bar'
    );

    const my %params2 => ( foo => 42, bar => 42 );
    is(
        dies { $sub->(%params2) },
        undef,
        'lives when given foo and bar params'
    );
}

{
    const my $spec => {
        foo => 1,
        bar => {
            optional => 1,
        },
    };

    is(
        dies { validation_for( params => $spec ) },
        undef,
        'can pass constant hashref as spec to validation_for'
    );
}

{
    const my %spec => (
        foo => {},
        bar => {
            optional => 1,
        },
    );

    is(
        dies { validation_for( params => \%spec ) },
        undef,
        'can pass constant hash as spec to validation_for'
    );
}

done_testing();
