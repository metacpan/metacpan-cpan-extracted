#!perl

use strict;

use Perl::Critic ();
use Perl::Critic::Utils qw{ :severities };
use Test::More;

use constant POLICY => 'Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport';

{
    my $pc = Perl::Critic->new( -only => 1 );
    $pc->add_policy(
        -policy => POLICY,
        -params => { moose_type_modules => 'My::Types::Moose' },
    );

    my $code = q~
        use strict;
        use MooseX::Types::Moose qw( Int );
        use My::Types::Moose qw( ArrayRef Bool );

        has => (
            is  => 'ro',
            isa => Bool,
        );

        my $foo = undef;
        if ( is_Int( $foo ) ) {
           ...;
        }

        my $bar = to_ArrayRef('thing');

    ~;
    my @violations = $pc->critique( \$code );
    ok(!@violations, 'no violations');
}

done_testing();
