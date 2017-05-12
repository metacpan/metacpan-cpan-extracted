use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

my $class  = 'Pod::POM::View::HTML::Filter';
my $object = $class->new();
my @PPVHF  = ( [ $object, 'instance' ], [ $class, 'class' ] );
my $foo    = {
    code => sub { my $s = shift; $s =~ s/foo/bar/g; $s }
};

plan tests => 12 * @PPVHF;

my $has_test_warn = eval "use Test::Warn; 1";

# try to add a filter without some prereq
SKIP: {
    skip "Test::Warn not available", 2 unless $has_test_warn;

    for my $PPVHF (@PPVHF) {
        warning_like(sub {
                $PPVHF->[0]->add(
                    FOOMP => {
                        code     => sub { },
                        requires => ['SHIKA::SHIKA::SHIKA::SHIKA'],
                    }
                );
            },
            qr/^FOOMP: pre-requisite (?:SHIKA::){3}SHIKA could not be loaded /,
            "Missing prereq ($PPVHF->[1])"
        );
    }
}

# no foo built-in
for my $PPVHF (@PPVHF) {
    my @foo_filters = grep {/^foo$/} $PPVHF->[0]->filters();
    is( @foo_filters, 0, "No foo filter ($PPVHF->[1])" );
    ok( !$PPVHF->[0]->know('foo'), "Don't know foo ($PPVHF->[1])" );
}

for my $PPVHF (@PPVHF) {

    # add a filter
    $PPVHF->[0]->add( foo => $foo );
    my @foo_filters = grep {/^foo$/} $PPVHF->[0]->filters();
    is( @foo_filters, 1, "There's a foo filter now ($PPVHF->[1])" );
    ok( $PPVHF->[0]->know('foo'), "Hey, I know foo now ($PPVHF->[1])" );
    ok( !$PPVHF->[0]->know('bar'), "Don't know bar ($PPVHF->[1])" );

    # add one more
    $PPVHF->[0]->add( foo2 => { code => sub {"foo"} } );
    @foo_filters = grep {/^foo/} $PPVHF->[0]->filters();
    is( @foo_filters, 2, "There are two foo filters ($PPVHF->[1])" );
    ok( $PPVHF->[0]->know('foo2'), "Hey, I know foo2 now ($PPVHF->[1])" );
    ok( !$PPVHF->[0]->know('bar'), "Still don't know bar ($PPVHF->[1])" );

    # test delete()
    is( $PPVHF->[0]->delete('foo'), $foo, "Removed foo ($PPVHF->[1])" );
    ok( !$PPVHF->[0]->know('foo'), "Don't know foo any more ($PPVHF->[1])" );

    # test errors
    eval { $PPVHF->[0]->add( klonk => { verbatim => 1 } ) };
    like(
        $@,
        qr/^klonk: no code parameter given/,
        "code is required for add() ($PPVHF->[1])"
    );
}

